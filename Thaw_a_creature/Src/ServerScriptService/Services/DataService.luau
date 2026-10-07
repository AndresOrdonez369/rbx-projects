local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local DataConfig = require(shared:WaitForChild("DataConfig"))
local GameConfig = require(shared:WaitForChild("GameConfig"))
local HearthConfig = require(shared:WaitForChild("HearthConfig"))
local IceConfig = require(shared:WaitForChild("IceConfig"))
local RarityConfig = require(shared:WaitForChild("RarityConfig"))
local SizeConfig = require(shared:WaitForChild("SizeConfig"))
local WarmthConfig = require(shared:WaitForChild("WarmthConfig"))

local PlayerStateService = require(script.Parent.PlayerStateService)
local ThawService = require(script.Parent.ThawService)

type PersistentData = PlayerStateService.PersistentData
type PersistentThawRecord = PlayerStateService.PersistentThawRecord

type SessionLock = {
    SessionID: string,
    JobId: string,
    UpdatedAtUnix: number,
}

type Profile = {
    Player: Player,
    Key: string,
    SessionID: string,
    IsPersistent: boolean,
    IsReleased: boolean,
    IsSaving: boolean,
}

local DataService = {}

local LOAD_FAILURE_KICK_MESSAGE = "Your saved data could not be loaded safely. Please rejoin in a moment."

-- DataVersion 2 is the first persisted schema (per-copy CreatureGUID ownership).
-- Add an entry keyed by source version whenever DataConfig.DataVersion is raised.
local MIGRATIONS: { [number]: (any) -> any } = {}

local hasStarted = false
local isShuttingDown = false
local dataStore: DataStore? = nil
local profilesByPlayer: { [Player]: Profile } = {}
local pendingSaveCount = 0

assert(
    #DataConfig.RetryBackoffSeconds == DataConfig.SaveRetryAttempts,
    "DataConfig.RetryBackoffSeconds must define one delay per retry attempt"
)
assert(
    DataConfig.SessionLockStaleSeconds > DataConfig.AutosaveIntervalSeconds,
    "DataConfig.SessionLockStaleSeconds must exceed the autosave interval that refreshes the lock"
)

local function isFiniteNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function isNonEmptyString(value: any): boolean
    return type(value) == "string" and value ~= ""
end

local function getUnixTime(): number
    return Workspace:GetServerTimeNow()
end

local function getDataStore(): DataStore
    local store = dataStore
    if not store then
        store = DataStoreService:GetDataStore(DataConfig.DataStoreName)
        dataStore = store
    end

    return store
end

local function createDefaultData(): PersistentData
    return {
        DataVersion = DataConfig.DataVersion,
        Cash = 0,
        MaxWarmth = WarmthConfig.StartingMaxWarmth,
        HearthLevel = HearthConfig[1].Level,
        CreatureCopies = {},
        PenSlots = table.create(GameConfig.ActivePenCreatureSlots),
        EquippedCreatureGUID = nil,
        DiscoveredCreatures = {},
        ThawingIce = {},
    }
end

local function isValidWeightMultiplier(weightMultiplier: any): boolean
    return isFiniteNumber(weightMultiplier) and (pcall(SizeConfig.GetVisualScale, weightMultiplier))
end

local function isValidCreature(creatureID: any, weightMultiplier: any): boolean
    return type(creatureID) == "string"
        and CreatureConfig[creatureID] ~= nil
        and isValidWeightMultiplier(weightMultiplier)
end

local function decodeThawRecord(record: any): (PersistentThawRecord?, string?)
    if type(record) ~= "table" then
        return nil, "record is not a table"
    end

    if not isNonEmptyString(record.ThawID) then
        return nil, "missing ThawID"
    end

    if type(record.IceType) ~= "string" or IceConfig[record.IceType] == nil then
        return nil, string.format("unknown IceType %s", tostring(record.IceType))
    end

    if type(record.IsSpecial) ~= "boolean" then
        return nil, "IsSpecial is not a boolean"
    end

    if not isValidCreature(record.CreatureID, record.WeightMultiplier) then
        return nil, string.format("invalid CreatureID/WeightMultiplier %s", tostring(record.CreatureID))
    end

    local creature = CreatureConfig[record.CreatureID]
    if record.Rarity ~= creature.Rarity or RarityConfig[record.Rarity] == nil then
        return nil, string.format("Rarity %s does not match %s", tostring(record.Rarity), record.CreatureID)
    end

    if not isFiniteNumber(record.DepositedAtUnix) or record.DepositedAtUnix <= 0 then
        return nil, "invalid DepositedAtUnix"
    end

    if not isFiniteNumber(record.BaseDurationSeconds) or record.BaseDurationSeconds <= 0 then
        return nil, "invalid BaseDurationSeconds"
    end

    if not isFiniteNumber(record.BonusProgressSeconds) or record.BonusProgressSeconds < 0 then
        return nil, "invalid BonusProgressSeconds"
    end

    return {
        ThawID = record.ThawID,
        IceType = record.IceType,
        IsSpecial = record.IsSpecial,
        CreatureID = record.CreatureID,
        Rarity = record.Rarity,
        WeightMultiplier = record.WeightMultiplier,
        DepositedAtUnix = record.DepositedAtUnix,
        BaseDurationSeconds = record.BaseDurationSeconds,
        BonusProgressSeconds = record.BonusProgressSeconds,
    }, nil
end

-- Validates/migrates a stored record. Scalar corruption fails the load so the stored
-- record is never replaced; individual invalid collection entries are dropped.
local function decode(stored: { [string]: any }, logPrefix: string): (PersistentData?, string?)
    local version = stored.DataVersion
    if type(version) ~= "number" or version % 1 ~= 0 then
        return nil, "missing DataVersion"
    end

    if version > DataConfig.DataVersion then
        return nil, string.format("DataVersion %d is newer than this server (%d)", version, DataConfig.DataVersion)
    end

    while version < DataConfig.DataVersion do
        local migrate = MIGRATIONS[version]
        if not migrate then
            return nil, string.format("no migration from DataVersion %d", version)
        end

        stored = migrate(stored)
        version += 1
        stored.DataVersion = version
    end

    local data = createDefaultData()

    if stored.Cash ~= nil then
        if not isFiniteNumber(stored.Cash) or stored.Cash < 0 or stored.Cash % 1 ~= 0 then
            return nil, "invalid Cash"
        end
        data.Cash = stored.Cash
    end

    if stored.MaxWarmth ~= nil then
        if not isFiniteNumber(stored.MaxWarmth) or stored.MaxWarmth <= 0 then
            return nil, "invalid MaxWarmth"
        end
        data.MaxWarmth = stored.MaxWarmth
    end

    if stored.HearthLevel ~= nil then
        local levelConfig = if type(stored.HearthLevel) == "number" then HearthConfig[stored.HearthLevel] else nil
        if not levelConfig or levelConfig.Level ~= stored.HearthLevel then
            return nil, "invalid HearthLevel"
        end
        data.HearthLevel = stored.HearthLevel
    end

    if type(stored.CreatureCopies) == "table" then
        for creatureGUID, copy in stored.CreatureCopies do
            if isNonEmptyString(creatureGUID)
                and type(copy) == "table"
                and isValidCreature(copy.CreatureID, copy.WeightMultiplier)
            then
                data.CreatureCopies[creatureGUID] = {
                    CreatureID = copy.CreatureID,
                    WeightMultiplier = copy.WeightMultiplier,
                }
            else
                warn(string.format("%s dropped invalid creature copy %s", logPrefix, tostring(creatureGUID)))
            end
        end
    end

    local allocatedGUIDs = {}
    if type(stored.PenSlots) == "table" then
        for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
            local creatureGUID = stored.PenSlots[tostring(slotIndex)]
            if creatureGUID ~= nil then
                if type(creatureGUID) == "string"
                    and data.CreatureCopies[creatureGUID]
                    and not allocatedGUIDs[creatureGUID]
                then
                    data.PenSlots[slotIndex] = creatureGUID
                    allocatedGUIDs[creatureGUID] = true
                else
                    warn(string.format("%s cleared invalid Pen slot %d", logPrefix, slotIndex))
                end
            end
        end
    end

    local equippedCreatureGUID = stored.EquippedCreatureGUID
    if equippedCreatureGUID ~= nil then
        if type(equippedCreatureGUID) == "string"
            and data.CreatureCopies[equippedCreatureGUID]
            and not allocatedGUIDs[equippedCreatureGUID]
        then
            data.EquippedCreatureGUID = equippedCreatureGUID
        else
            warn(string.format("%s cleared invalid Equipped creature %s", logPrefix, tostring(equippedCreatureGUID)))
        end
    end

    if type(stored.DiscoveredCreatures) == "table" then
        for creatureID, isDiscovered in stored.DiscoveredCreatures do
            if isDiscovered == true and type(creatureID) == "string" and CreatureConfig[creatureID] then
                data.DiscoveredCreatures[creatureID] = true
            end
        end
    end

    for _, copy in data.CreatureCopies do
        data.DiscoveredCreatures[copy.CreatureID] = true
    end

    if type(stored.ThawingIce) == "table" then
        local seenThawIDs = {}
        for _, storedRecord in stored.ThawingIce do
            local record, reason = decodeThawRecord(storedRecord)
            if record and not seenThawIDs[record.ThawID] then
                seenThawIDs[record.ThawID] = true
                table.insert(data.ThawingIce, record)
            else
                warn(string.format("%s dropped invalid thawing Ice: %s", logPrefix, reason or "duplicate ThawID"))
            end
        end
    end

    return data, nil
end

-- DataStore values are JSON: Pen slots are written with string keys so empty slots never create array holes.
local function encode(data: PersistentData, sessionLock: SessionLock?): { [string]: any }
    local penSlots = {}
    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        local creatureGUID = data.PenSlots[slotIndex]
        if creatureGUID then
            penSlots[tostring(slotIndex)] = creatureGUID
        end
    end

    return {
        DataVersion = data.DataVersion,
        Cash = data.Cash,
        MaxWarmth = data.MaxWarmth,
        HearthLevel = data.HearthLevel,
        CreatureCopies = data.CreatureCopies,
        PenSlots = penSlots,
        EquippedCreatureGUID = data.EquippedCreatureGUID,
        DiscoveredCreatures = data.DiscoveredCreatures,
        ThawingIce = data.ThawingIce,
        SessionLock = sessionLock,
    }
end

-- Copies the live state synchronously so later gameplay mutations cannot leak into an in-flight save.
local function createSnapshot(state: PlayerStateService.PlayerState): PersistentData
    local data = createDefaultData()
    data.Cash = state.Cash
    data.MaxWarmth = state.MaxWarmth
    data.HearthLevel = state.HearthLevel
    data.EquippedCreatureGUID = state.EquippedCreatureGUID
    data.DiscoveredCreatures = table.clone(state.DiscoveredCreatures)

    for creatureGUID, copy in state.CreatureCopies do
        data.CreatureCopies[creatureGUID] = {
            CreatureID = copy.CreatureID,
            WeightMultiplier = copy.WeightMultiplier,
        }
    end

    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        data.PenSlots[slotIndex] = state.PenSlots[slotIndex]
    end

    for _, thawItem in state.ActiveThawItems do
        table.insert(data.ThawingIce, {
            ThawID = thawItem.ThawID,
            IceType = thawItem.IceType,
            IsSpecial = thawItem.IsSpecial,
            CreatureID = thawItem.CreatureID,
            Rarity = thawItem.Rarity,
            WeightMultiplier = thawItem.WeightMultiplier,
            DepositedAtUnix = thawItem.DepositedAtTime,
            BaseDurationSeconds = thawItem.BaseDurationSeconds,
            BonusProgressSeconds = ThawService.GetPersistentBonusProgressSeconds(thawItem),
        })
    end

    table.sort(data.ThawingIce, function(left, right)
        if left.DepositedAtUnix == right.DepositedAtUnix then
            return left.ThawID < right.ThawID
        end

        return left.DepositedAtUnix < right.DepositedAtUnix
    end)

    return data
end

local function createSessionLock(profile: Profile): SessionLock
    return {
        SessionID = profile.SessionID,
        JobId = game.JobId,
        UpdatedAtUnix = getUnixTime(),
    }
end

local function isLockedByAnotherSession(storedLock: any, sessionID: string): boolean
    if type(storedLock) ~= "table" or storedLock.SessionID == sessionID then
        return false
    end

    local updatedAt = storedLock.UpdatedAtUnix
    return isFiniteNumber(updatedAt) and getUnixTime() - updatedAt < DataConfig.SessionLockStaleSeconds
end

-- Runs one UpdateAsync with the canonical retry policy. The transform reports
-- non-retryable outcomes through its own upvalues and cancels by returning nil.
local function updateWithRetries(
    key: string,
    transform: (any) -> (any, { number }?),
    shouldRetryCancelled: () -> boolean,
    logPrefix: string
): boolean
    local attempt = 0

    while true do
        local succeeded, errorMessage = pcall(function()
            getDataStore():UpdateAsync(key, transform)
        end)

        if succeeded and not shouldRetryCancelled() then
            return true
        end

        attempt += 1
        if attempt > DataConfig.SaveRetryAttempts then
            warn(string.format(
                "%s gave up after %d attempts: %s",
                logPrefix,
                attempt,
                if succeeded then "session is locked by another server" else tostring(errorMessage)
            ))
            return false
        end

        warn(string.format(
            "%s attempt %d failed (%s); retrying in %ds",
            logPrefix,
            attempt,
            if succeeded then "session is locked by another server" else tostring(errorMessage),
            DataConfig.RetryBackoffSeconds[attempt]
        ))
        task.wait(DataConfig.RetryBackoffSeconds[attempt])
    end
end

-- Without data, a releasing save only clears the lock and leaves the stored record unchanged.
local function saveAsync(profile: Profile, data: PersistentData?, releaseLock: boolean): boolean
    pendingSaveCount += 1

    while profile.IsSaving do
        task.wait()
    end

    -- The releasing save must be the last write; a queued autosave would re-acquire the lock.
    if profile.IsReleased and not releaseLock then
        pendingSaveCount -= 1
        return false
    end
    profile.IsSaving = true

    local userId = profile.Player.UserId
    local logPrefix = string.format("[DataService] Save for %d", userId)
    local lostSession = false

    local saved = updateWithRetries(profile.Key, function(stored)
        lostSession = false

        -- Never overwrite a record this session no longer owns (taken over, erased, or re-locked elsewhere).
        if type(stored) ~= "table"
            or type(stored.SessionLock) ~= "table"
            or stored.SessionLock.SessionID ~= profile.SessionID
        then
            lostSession = true
            return nil
        end

        local sessionLock = if releaseLock then nil else createSessionLock(profile)
        if not data then
            local record = table.clone(stored)
            record.SessionLock = sessionLock
            return record, { userId }
        end

        return encode(data, sessionLock), { userId }
    end, function()
        return false
    end, logPrefix)

    if saved and lostSession then
        warn(string.format("%s skipped: this server no longer owns the session lock", logPrefix))
        saved = false
    end

    profile.IsSaving = false
    pendingSaveCount -= 1

    return saved
end

local function releaseProfile(profile: Profile, data: PersistentData?): ()
    if profile.IsReleased then
        return
    end
    profile.IsReleased = true

    if profilesByPlayer[profile.Player] == profile then
        profilesByPlayer[profile.Player] = nil
    end

    if not profile.IsPersistent then
        return
    end

    task.spawn(saveAsync, profile, data, true)
end

local function runAutosaveLoop(): ()
    while true do
        task.wait(DataConfig.AutosaveIntervalSeconds)

        if isShuttingDown then
            return
        end

        for player, profile in profilesByPlayer do
            local state = PlayerStateService.GetState(player)
            if profile.IsPersistent and not profile.IsReleased and state then
                task.spawn(saveAsync, profile, createSnapshot(state), false)
            end
        end
    end
end

-- Yields until the player's profile is loaded and session-locked. Returns nil when the
-- player must not enter writable gameplay; live servers kick instead of using a blank profile.
function DataService.LoadAsync(player: Player): PersistentData?
    assert(hasStarted, "DataService must be started before loading profiles")

    if profilesByPlayer[player] then
        error(string.format("[DataService] Profile for %d is already loaded", player.UserId))
    end

    local profile: Profile = {
        Player = player,
        Key = DataConfig.KeyPrefix .. player.UserId,
        SessionID = HttpService:GenerateGUID(false),
        IsPersistent = true,
        IsReleased = false,
        IsSaving = false,
    }

    local userId = player.UserId
    local logPrefix = string.format("[DataService] Load for %d", userId)
    local lockedByAnotherSession = false
    local failureReason: string? = nil
    local loadedData: PersistentData? = nil

    local loaded = updateWithRetries(profile.Key, function(stored)
        lockedByAnotherSession = false
        failureReason = nil
        loadedData = nil

        local data: PersistentData
        if stored == nil then
            data = createDefaultData()
        else
            if type(stored) ~= "table" then
                failureReason = "stored value is not a table"
                return nil
            end

            if isLockedByAnotherSession(stored.SessionLock, profile.SessionID) then
                lockedByAnotherSession = true
                return nil
            end

            local decoded, reason = decode(stored, logPrefix)
            if not decoded then
                failureReason = reason
                return nil
            end
            data = decoded
        end

        loadedData = data
        return encode(data, createSessionLock(profile)), { userId }
    end, function()
        return lockedByAnotherSession
    end, logPrefix)

    local data = loadedData
    if loaded and failureReason then
        warn(string.format("%s rejected stored data: %s", logPrefix, failureReason))
    end

    if not loaded or not data or failureReason then
        if RunService:IsStudio() then
            -- Studio-only fallback: play with defaults but never write them back.
            warn(string.format(
                "%s failed; Studio session continues with NON-PERSISTENT default data (saving disabled)",
                logPrefix
            ))
            profile.IsPersistent = false
            data = createDefaultData()
        else
            if player.Parent == Players then
                player:Kick(LOAD_FAILURE_KICK_MESSAGE)
            end
            return nil
        end
    end

    assert(data, "Profile data must exist after a successful load")

    if player.Parent ~= Players or isShuttingDown then
        -- The player left while loading: release the lock without changing the stored data.
        releaseProfile(profile, data)
        return nil
    end

    profilesByPlayer[player] = profile

    local creatureCount = 0
    for _ in data.CreatureCopies do
        creatureCount += 1
    end
    print(string.format(
        "[DataService] Loaded %d (persistent=%s, copies=%d, thawing=%d)",
        userId,
        tostring(profile.IsPersistent),
        creatureCount,
        #data.ThawingIce
    ))

    return data
end

-- Takes the final snapshot synchronously; call before the player's runtime state is removed.
function DataService.Release(player: Player): ()
    local profile = profilesByPlayer[player]
    if not profile then
        return
    end

    local state = PlayerStateService.GetState(player)
    releaseProfile(profile, if state then createSnapshot(state) else nil)
end

function DataService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    game:BindToClose(function()
        isShuttingDown = true

        for player in profilesByPlayer do
            DataService.Release(player)
        end

        while pendingSaveCount > 0 do
            task.wait()
        end
    end)

    task.spawn(runAutosaveLoop)
end

return DataService
