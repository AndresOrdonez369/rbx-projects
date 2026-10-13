local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureRosterConfig = require(shared:WaitForChild("CreatureRosterConfig"))
local GameConfig = require(shared:WaitForChild("GameConfig"))
local IceConfig = require(shared:WaitForChild("IceConfig"))
local RarityConfig = require(shared:WaitForChild("RarityConfig"))
local RegionConfig = require(shared:WaitForChild("RegionConfig"))
local SizeConfig = require(shared:WaitForChild("SizeConfig"))
local SpecialIceConfig = require(shared:WaitForChild("SpecialIceConfig"))
local WorldCycleConfig = require(shared:WaitForChild("WorldCycleConfig"))
local StudioTestConfig = require(script.Parent.Parent:WaitForChild("StudioTestConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local BaseService = require(script.Parent.BaseService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local ThawService = require(script.Parent.ThawService)
local IceVisualFactory = require(script.Parent.IceVisualFactory)
local WorldCycleService = require(script.Parent.WorldCycleService)

export type IceRecord = {
    IceInstanceID: string,
    IceType: string,
    SpawnPointID: string,

    CreatureID: string,
    Rarity: string,
    SilhouetteProfile: string,
    WeightMultiplier: number,

    -- Special metadata; SpawnPointID doubles as the OriginSpawnPointID and never changes on release.
    IsSpecial: boolean,
    OriginCycleIndex: number?,

    State: string,
    OwnerUserID: number?,
}

local IceService = {}

local ACTIVE_ICE_FOLDER_NAME = "ActiveIce"
local AVAILABLE_STATE = "Available"
local CARRIED_STATE = "Carried"
local DEPOSITED_STATE = "Deposited"
local CARRY_BOTTOM_OFFSET_FROM_ROOT = -2
local CARRY_MIN_CENTER_DISTANCE_FROM_ROOT = 5
local CARRY_MIN_CLEARANCE_FROM_ROOT = 2
local CARRY_WELD_NAME = "CarryWeld"
-- While Riding, carried Ice sits above the rider so it never covers the mount's head or the forward view.
local CARRY_RIDING_CLEARANCE_ABOVE_ROOT = 4
local MOUNT_STATE_ATTRIBUTE = "MountState"
local RIDING_MOUNT_STATE = "Riding"
local GRAB_PROMPT_NAME = "GrabPrompt"
local PRESENTATION_WELD_NAME = "PresentationWeld"
local ICE_TYPE_ORDER = { "Regular", "Thick", "Ancient", "Black", "Meteor" }
local JACKPOT_ICE_TYPE = "Thick"
local JACKPOT_CREATURE_ID = "Nidhogg"
local JACKPOT_WEIGHT_MULTIPLIER = 125
local SAFE_GROUND_RAYCAST_DISTANCE = 50

local recordsByID: { [string]: IceRecord } = {}
local visualIceByID: { [string]: BasePart } = {}
-- Ground point under each Ice's authored spawn marker; final fallback for carrier-failure release.
local originCFrameByID: { [string]: CFrame } = {}
-- Owned here rather than read from PlayerState so release still works after state removal on leave.
local carriedIceIDByPlayer: { [Player]: string } = {}
-- The character that grabbed the Ice; on respawn Player.Character already points at the new one.
local carrierCharacterByPlayer: { [Player]: Model } = {}
local lastSafeRootPositionByPlayer: { [Player]: Vector3 } = {}
local lastGrabRequestAtByPlayer: { [Player]: number } = {}
local lastDepositRequestAtByPlayer: { [Player]: number } = {}
local random = Random.new()
local hasStarted = false
local grabLockedDuringGreatFrost = false
local lastResetCycleIndex: number? = nil
local hasPopulatedField = false
local jackpotHarnessConsumed = false

local function isJackpotHarnessEnabled(): boolean
    return RunService:IsStudio() and StudioTestConfig.EnableJackpotHarness == true
end

local function isFiniteNumber(value: any): boolean
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

local function rollWeightMultiplier(randomSource: Random): number
    local bandRoll = randomSource:NextNumber()
    local cumulativeChance = 0
    local selectedBand = nil

    for _, band in SizeConfig.SizeBands do
        cumulativeChance += band.Chance
        if bandRoll < cumulativeChance then
            selectedBand = band
            break
        end
    end

    assert(selectedBand, "SizeConfig failed to select a size band")

    local t = randomSource:NextNumber() ^ SizeConfig.WithinBandBiasExponent
    local weightMultiplier = selectedBand.MinWeightMultiplier
        + (selectedBand.MaxWeightMultiplier - selectedBand.MinWeightMultiplier) * t

    SizeConfig.GetVisualScale(weightMultiplier)

    return weightMultiplier
end

local function isGrabRateLimited(player: Player): boolean
    local now = os.clock()
    local lastRequestAt = lastGrabRequestAtByPlayer[player]
    lastGrabRequestAtByPlayer[player] = now

    return lastRequestAt ~= nil and now - lastRequestAt < GameConfig.GrabIceRequestMinInterval
end

local function isDepositRateLimited(player: Player): boolean
    local now = os.clock()
    local lastRequestAt = lastDepositRequestAtByPlayer[player]
    lastDepositRequestAtByPlayer[player] = now

    return lastRequestAt ~= nil and now - lastRequestAt < GameConfig.DepositIceRequestMinInterval
end

local function rollRarity(config, randomSource: Random): string
    local totalWeight = 0

    for _, rarity in CreatureRosterConfig.RarityOrder do
        local weight = config.RarityWeights[rarity]
        assert(RarityConfig[rarity], string.format("Unknown rarity %s in %s Ice config", rarity, config.IceType))
        assert(isFiniteNumber(weight) and weight >= 0, string.format(
            "%s Ice rarity %s must have a finite non-negative weight",
            config.IceType,
            rarity
        ))
        totalWeight += weight
    end

    assert(totalWeight > 0, string.format("%s Ice must have a positive total rarity weight", config.IceType))

    local result = randomSource:NextNumber(0, totalWeight)
    local cumulativeWeight = 0

    for _, rarity in CreatureRosterConfig.RarityOrder do
        local weight = config.RarityWeights[rarity]
        cumulativeWeight += weight
        if result <= cumulativeWeight and weight > 0 then
            return rarity
        end
    end

    error(string.format("Failed to roll a rarity for %s Ice", config.IceType))
end

local function rollReward(config, randomSource: Random): (string, string, string)
    local rarity = rollRarity(config, randomSource)
    local creaturePool = config.CreaturePoolsByRarity[rarity]

    assert(creaturePool, string.format("%s Ice has no creature pool for rarity %s", config.IceType, rarity))
    assert(#creaturePool > 0, string.format("%s Ice has an empty creature pool for rarity %s", config.IceType, rarity))

    local creatureID = creaturePool[randomSource:NextInteger(1, #creaturePool)]
    local creature = CreatureConfig[creatureID]

    assert(creature, string.format("Unknown creature %s in %s Ice %s pool", creatureID, config.IceType, rarity))
    assert(creature.CreatureID == creatureID, string.format("CreatureConfig.%s.CreatureID must match its key", creatureID))
    assert(creature.Rarity == rarity, string.format("Creature %s must match its %s Ice pool rarity %s", creatureID, config.IceType, rarity))
    assert(
        type(creature.SilhouetteProfile) == "string" and creature.SilhouetteProfile ~= "",
        string.format("Creature %s must have a SilhouetteProfile", creatureID)
    )

    return creatureID, rarity, creature.SilhouetteProfile
end

local function validateRewardConfiguration(config): ()
    local totalWeight = 0

    for rarity in config.RarityWeights do
        assert(RarityConfig[rarity], string.format("Unknown rarity %s in %s Ice weights", rarity, config.IceType))
    end

    for rarity in config.CreaturePoolsByRarity do
        assert(RarityConfig[rarity], string.format("Unknown rarity %s in %s Ice pools", rarity, config.IceType))
    end

    for _, rarity in CreatureRosterConfig.RarityOrder do
        local weight = config.RarityWeights[rarity]
        assert(isFiniteNumber(weight) and weight >= 0, string.format(
            "%s Ice must define a finite non-negative %s weight",
            config.IceType,
            rarity
        ))
        totalWeight += weight

        local creaturePool = config.CreaturePoolsByRarity[rarity]
        assert(type(creaturePool) == "table", string.format(
            "%s Ice must define a %s creature pool",
            config.IceType,
            rarity
        ))
        assert(weight == 0 or #creaturePool > 0, string.format(
            "%s Ice must define eligible species for positive-weight rarity %s",
            config.IceType,
            rarity
        ))

        for _, creatureID in creaturePool do
            local creature = CreatureConfig[creatureID]
            assert(creature, string.format("Unknown creature %s in %s Ice %s pool", creatureID, config.IceType, rarity))
            assert(creature.Rarity == rarity, string.format(
                "Creature %s must match its %s Ice pool rarity %s",
                creatureID,
                config.IceType,
                rarity
            ))
        end
    end

    assert(totalWeight == 100, string.format(
        "%s Ice rarity weights must total 100, got %s",
        config.IceType,
        tostring(totalWeight)
    ))
end

local function getSpawnFolder(iceType: string): Folder
    local spawnPoints = Workspace:WaitForChild("IceSpawnPoints")
    local spawnFolder = spawnPoints:WaitForChild(iceType)

    assert(spawnFolder:IsA("Folder"), string.format("Workspace.IceSpawnPoints.%s must be a Folder", iceType))

    return spawnFolder
end

local function getSortedMarkers(spawnFolder: Folder): { BasePart }
    local markers = {}
    local markerNames = {}

    for _, child in spawnFolder:GetChildren() do
        if child:IsA("BasePart") then
            assert(not markerNames[child.Name], string.format(
                "%s contains duplicate marker name %s",
                spawnFolder:GetFullName(),
                child.Name
            ))
            markerNames[child.Name] = true
            table.insert(markers, child)
        end
    end

    table.sort(markers, function(left, right)
        return left.Name < right.Name
    end)

    return markers
end

local function isPointInsideBounds(worldPosition: Vector3, bounds: BasePart): boolean
    local localPosition = bounds.CFrame:PointToObjectSpace(worldPosition)
    local halfSize = bounds.Size * 0.5

    return math.abs(localPosition.X) <= halfSize.X
        and math.abs(localPosition.Y) <= halfSize.Y
        and math.abs(localPosition.Z) <= halfSize.Z
end

local function validateConfiguredMarkerRegion(config, markers: { BasePart }): ()
    local regionID = config.RegionID
    if regionID == nil then
        return
    end

    assert(
        type(regionID) == "string" and RegionConfig[regionID],
        string.format("IceConfig.%s.RegionID must name a configured region", config.IceType)
    )

    local progressionRegions = Workspace:WaitForChild("ProgressionRegions")
    local regionFolder = progressionRegions:WaitForChild(regionID)
    local bounds = regionFolder:WaitForChild("RegionBounds")
    assert(bounds:IsA("BasePart"), string.format(
        "Workspace.ProgressionRegions.%s.RegionBounds must be a BasePart",
        regionID
    ))

    for _, marker in markers do
        assert(isPointInsideBounds(marker.Position, bounds), string.format(
            "%s marker %s must be inside configured region %s",
            config.IceType,
            marker:GetFullName(),
            regionID
        ))
    end
end

local function getOrCreateActiveIceFolder(): Folder
    local existingFolder = Workspace:FindFirstChild(ACTIVE_ICE_FOLDER_NAME)
    if existingFolder then
        assert(existingFolder:IsA("Folder"), string.format("Workspace.%s must be a Folder", ACTIVE_ICE_FOLDER_NAME))
        return existingFolder
    end

    local folder = Instance.new("Folder")
    folder.Name = ACTIVE_ICE_FOLDER_NAME
    folder.Parent = Workspace

    return folder
end

local function createVisualIce(
    record: IceRecord,
    groundCFrame: CFrame,
    activeIceFolder: Folder
): BasePart
    local visualSize = IceVisualFactory.GetScaledSize(record.IceType, record.WeightMultiplier)
    local cframe = groundCFrame * CFrame.new(0, visualSize.Y * 0.5, 0)
    local visualIce = IceVisualFactory.Create(
        record.IceType,
        record.SilhouetteProfile,
        record.WeightMultiplier,
        cframe,
        activeIceFolder
    )
    visualIce:SetAttribute("IceInstanceID", record.IceInstanceID)
    local interactionPart = IceVisualFactory.GetInteractionPart(visualIce)
    interactionPart:SetAttribute("IceInstanceID", record.IceInstanceID)
    if record.IsSpecial then
        IceVisualFactory.ApplySpecialPresentation(visualIce)
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = GRAB_PROMPT_NAME
    prompt.ActionText = "Grab Ice"
    prompt.ObjectText = "Ice"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = GameConfig.GrabIceMaxDistance
    prompt.RequiresLineOfSight = false
    prompt.Enabled = not grabLockedDuringGreatFrost
    prompt.Parent = interactionPart

    return visualIce
end

local function makeCarriedPartPhysicsSafe(part: BasePart)
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
end

local function getCarryOffsetFromRoot(visualIce: BasePart, isRiding: boolean): CFrame
    if isRiding then
        return CFrame.new(0, CARRY_RIDING_CLEARANCE_ABOVE_ROOT + visualIce.Size.Y * 0.5, 0)
    end

    local centerDistance = math.max(
        CARRY_MIN_CENTER_DISTANCE_FROM_ROOT,
        visualIce.Size.Z * 0.5 + CARRY_MIN_CLEARANCE_FROM_ROOT
    )

    local verticalOffset = visualIce.Size.Y * 0.5 + CARRY_BOTTOM_OFFSET_FROM_ROOT
    return CFrame.new(0, verticalOffset, -centerDistance)
end

local function isPlayerRiding(player: Player): boolean
    return player:GetAttribute(MOUNT_STATE_ATTRIBUTE) == RIDING_MOUNT_STATE
end

local function attachVisualIceToCharacter(
    visualIce: BasePart,
    rootPart: BasePart,
    character: Model,
    isRiding: boolean
)
    makeCarriedPartPhysicsSafe(visualIce)

    for _, descendant in visualIce:GetDescendants() do
        if descendant:IsA("BasePart") then
            makeCarriedPartPhysicsSafe(descendant)

            local presentationWeld = Instance.new("WeldConstraint")
            presentationWeld.Name = PRESENTATION_WELD_NAME
            presentationWeld.Part0 = visualIce
            presentationWeld.Part1 = descendant
            presentationWeld.Parent = visualIce

            descendant.Anchored = false
        end
    end

    visualIce.CFrame = rootPart.CFrame * getCarryOffsetFromRoot(visualIce, isRiding)
    visualIce.Parent = character

    local carryWeld = Instance.new("WeldConstraint")
    carryWeld.Name = CARRY_WELD_NAME
    carryWeld.Part0 = rootPart
    carryWeld.Part1 = visualIce
    carryWeld.Parent = visualIce

    visualIce.Anchored = false
end

local function discardIceByID(iceInstanceID: string)
    recordsByID[iceInstanceID] = nil
    originCFrameByID[iceInstanceID] = nil

    local visualIce = visualIceByID[iceInstanceID]
    visualIceByID[iceInstanceID] = nil

    if visualIce then
        visualIce:Destroy()
    end
end

local function clearCarry(player: Player)
    carriedIceIDByPlayer[player] = nil
    carrierCharacterByPlayer[player] = nil
    lastSafeRootPositionByPlayer[player] = nil

    local playerState = PlayerStateService.GetState(player)
    if playerState then
        playerState.CurrentlyCarryingIceID = nil
    end
end

local function findGroundCFrame(rootPosition: Vector3): CFrame?
    if not (isFiniteNumber(rootPosition.X) and isFiniteNumber(rootPosition.Y) and isFiniteNumber(rootPosition.Z)) then
        return nil
    end

    local excludedCharacters = {}
    for _, otherPlayer in Players:GetPlayers() do
        if otherPlayer.Character then
            table.insert(excludedCharacters, otherPlayer.Character)
        end
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = excludedCharacters
    -- Ignore trigger volumes such as WarmZones and RegionBounds; only walkable geometry counts.
    raycastParams.RespectCanCollide = true

    local result = Workspace:Raycast(
        rootPosition,
        Vector3.new(0, -SAFE_GROUND_RAYCAST_DISTANCE, 0),
        raycastParams
    )

    return if result then CFrame.new(result.Position) else nil
end

-- Grounded means standing on something solid this frame; airborne or void positions are not safe.
local function getGroundedRootPosition(character: Model?): Vector3?
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or not rootPart:IsA("BasePart") then
        return nil
    end

    if humanoid.FloorMaterial == Enum.Material.Air then
        return nil
    end

    return rootPart.Position
end

local function getReleaseGroundCFrame(player: Player, iceInstanceID: string): CFrame
    local groundedRootPosition = getGroundedRootPosition(carrierCharacterByPlayer[player])
    local groundCFrame = groundedRootPosition and findGroundCFrame(groundedRootPosition)
    if groundCFrame then
        return groundCFrame
    end

    local lastSafeRootPosition = lastSafeRootPositionByPlayer[player]
    groundCFrame = lastSafeRootPosition and findGroundCFrame(lastSafeRootPosition)
    if groundCFrame then
        return groundCFrame
    end

    local originCFrame = originCFrameByID[iceInstanceID]
    assert(originCFrame, string.format("Ice %s has no authored origin", iceInstanceID))

    return originCFrame
end

local function trackSafeCarrierPositions()
    for player, character in carrierCharacterByPlayer do
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local groundedRootPosition = getGroundedRootPosition(character)

        if humanoid and humanoid.Health > 0 and groundedRootPosition then
            lastSafeRootPositionByPlayer[player] = groundedRootPosition
        end
    end
end

local function connectCharacterFailure(player: Player, character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
    assert(humanoid:IsA("Humanoid"), "Player character Humanoid must be a Humanoid")

    humanoid.Died:Connect(function()
        IceService.ReleaseCarriedIce(player)
    end)
end

-- Special Ice keeps its type's creature pool but rolls rarity from the dedicated Special profile.
local function getSpecialRewardProfile(iceType: string)
    local config = IceConfig[iceType]
    local rarityWeights = SpecialIceConfig.RarityWeightsByIceType[iceType]
    assert(config and rarityWeights, string.format("Special Ice is not configured for %s", iceType))

    return {
        IceType = iceType,
        RarityWeights = rarityWeights,
        CreaturePoolsByRarity = config.CreaturePoolsByRarity,
    }
end

-- Every reward a Special Ice can hold must show the same pre-reveal silhouette.
local function validateSpecialSilhouettes(iceType: string): ()
    local rewardProfile = getSpecialRewardProfile(iceType)
    local sharedSilhouette: string? = nil

    for _, rarity in CreatureRosterConfig.RarityOrder do
        if rewardProfile.RarityWeights[rarity] > 0 then
            for _, creatureID in rewardProfile.CreaturePoolsByRarity[rarity] do
                local silhouette = IceVisualFactory.GetPreRevealSilhouetteProfile(creatureID, iceType, true)
                sharedSilhouette = sharedSilhouette or silhouette
                assert(silhouette == sharedSilhouette, string.format(
                    "Special %s Ice silhouettes must not identify the reward (%s vs %s)",
                    iceType,
                    tostring(sharedSilhouette),
                    silhouette
                ))
            end
        end
    end
end

local function spawnAtMarker(
    iceType: string,
    marker: BasePart,
    activeIceFolder: Folder,
    specialCycleIndex: number?
)
    local config = IceConfig[iceType]
    assert(config, string.format("Missing IceConfig for %s", iceType))

    local isSpecial = specialCycleIndex ~= nil
    local iceInstanceID = HttpService:GenerateGUID(false)
    local spawnPointID = string.format("%s/%s", iceType, marker.Name)
    local weightMultiplier = rollWeightMultiplier(random)
    local rewardProfile = if isSpecial then getSpecialRewardProfile(iceType) else config
    local creatureID, rarity = rollReward(rewardProfile, random)
    local isJackpotIce = false

    if isJackpotHarnessEnabled()
        and not isSpecial
        and not jackpotHarnessConsumed
        and iceType == JACKPOT_ICE_TYPE
    then
        local jackpotCreature = CreatureConfig[JACKPOT_CREATURE_ID]
        assert(jackpotCreature, string.format("Missing jackpot CreatureConfig for %s", JACKPOT_CREATURE_ID))

        weightMultiplier = JACKPOT_WEIGHT_MULTIPLIER
        creatureID = jackpotCreature.CreatureID
        rarity = jackpotCreature.Rarity
        jackpotHarnessConsumed = true
        isJackpotIce = true
    end

    local record: IceRecord = {
        IceInstanceID = iceInstanceID,
        IceType = iceType,
        SpawnPointID = spawnPointID,

        CreatureID = creatureID,
        Rarity = rarity,
        SilhouetteProfile = IceVisualFactory.GetPreRevealSilhouetteProfile(creatureID, iceType, isSpecial),
        WeightMultiplier = weightMultiplier,

        IsSpecial = isSpecial,
        OriginCycleIndex = specialCycleIndex,

        State = AVAILABLE_STATE,
        OwnerUserID = nil,
    }

    assert(recordsByID[iceInstanceID] == nil, string.format("Duplicate IceInstanceID %s", iceInstanceID))

    local originCFrame = marker.CFrame * CFrame.new(0, marker.Size.Y * 0.5, 0)
    recordsByID[iceInstanceID] = record
    originCFrameByID[iceInstanceID] = originCFrame
    visualIceByID[iceInstanceID] = createVisualIce(record, originCFrame, activeIceFolder)

    if isJackpotIce then
        local scale = SizeConfig.GetVisualScale(record.WeightMultiplier)
        print(string.format(
            "[D6-R10] jackpot-created ice=%s weight=%d scale=%.3f reward=%s",
            record.IceInstanceID,
            record.WeightMultiplier,
            scale,
            record.CreatureID
        ))
    end

end

local function selectSpawnMarkers(markers: { BasePart }, activeSpawnCount: number): { BasePart }
    assert(
        #markers >= activeSpawnCount,
        string.format("Expected at least %d candidate spawn points, got %d", activeSpawnCount, #markers)
    )

    local shuffledMarkers = table.clone(markers)
    for index = #shuffledMarkers, 2, -1 do
        local swapIndex = random:NextInteger(1, index)
        shuffledMarkers[index], shuffledMarkers[swapIndex] = shuffledMarkers[swapIndex], shuffledMarkers[index]
    end

    local selectedMarkers = table.create(activeSpawnCount)
    for index = 1, activeSpawnCount do
        selectedMarkers[index] = shuffledMarkers[index]
    end

    return selectedMarkers
end

local function populateField(): { [string]: number }
    local activeIceFolder = getOrCreateActiveIceFolder()
    local spawnedByType = {}

    for _, iceType in ICE_TYPE_ORDER do
        local config = IceConfig[iceType]
        assert(config, string.format("Missing IceConfig for %s", iceType))

        local activeSpawnCount = config.ActiveSpawnCount
        assert(
            type(activeSpawnCount) == "number" and activeSpawnCount > 0 and activeSpawnCount % 1 == 0,
            string.format("IceConfig.%s.ActiveSpawnCount must be a positive integer", iceType)
        )

        local markers = getSortedMarkers(getSpawnFolder(iceType))
        if config.CandidateSpawnCount ~= nil then
            assert(
                #markers == config.CandidateSpawnCount,
                string.format(
                    "IceConfig.%s expects exactly %d candidate spawn points, got %d",
                    iceType,
                    config.CandidateSpawnCount,
                    #markers
                )
            )
        end
        validateConfiguredMarkerRegion(config, markers)
        for _, marker in markers do
            marker.Transparency = 1
        end

        for _, marker in selectSpawnMarkers(markers, activeSpawnCount) do
            spawnAtMarker(iceType, marker, activeIceFolder)
        end

        spawnedByType[iceType] = activeSpawnCount
    end

    return spawnedByType
end

local function rollSpecialIceType(): string
    local totalWeight = 0
    for _, entry in SpecialIceConfig.TypeWeights do
        totalWeight += entry.Weight
    end

    local result = random:NextNumber(0, totalWeight)
    local cumulativeWeight = 0
    for _, entry in SpecialIceConfig.TypeWeights do
        cumulativeWeight += entry.Weight
        if result <= cumulativeWeight and entry.Weight > 0 then
            return entry.IceType
        end
    end

    error("Failed to roll a Special Ice type")
end

-- Adds one Special Ice on an authored marker the new field left free. Returns its type, or nil if none fit.
local function spawnSpecialIce(cycleIndex: number): string?
    local iceType = rollSpecialIceType()
    local occupiedSpawnPointIDs = IceService.GetActiveAvailableSpawnPointIDs()
    local freeMarkers = {}

    for _, marker in getSortedMarkers(getSpawnFolder(iceType)) do
        if not occupiedSpawnPointIDs[string.format("%s/%s", iceType, marker.Name)] then
            table.insert(freeMarkers, marker)
        end
    end

    if #freeMarkers == 0 then
        warn(string.format("[IceService] No free %s spawn point for cycle %d Special Ice", iceType, cycleIndex))
        return nil
    end

    local marker = freeMarkers[random:NextInteger(1, #freeMarkers)]
    spawnAtMarker(iceType, marker, getOrCreateActiveIceFolder(), cycleIndex)

    return iceType
end

local function setAvailablePromptsEnabled(enabled: boolean): ()
    for iceInstanceID, record in recordsByID do
        if record.State == AVAILABLE_STATE and record.OwnerUserID == nil then
            local visualIce = visualIceByID[iceInstanceID]
            local prompt = visualIce and visualIce:FindFirstChild(GRAB_PROMPT_NAME, true)
            if prompt and prompt:IsA("ProximityPrompt") then
                prompt.Enabled = enabled
            end
        end
    end
end

local function resetAvailableField(): number
    local eligibleIceIDs = {}

    for iceInstanceID, record in recordsByID do
        if record.State == AVAILABLE_STATE and record.OwnerUserID == nil then
            table.insert(eligibleIceIDs, iceInstanceID)
        end
    end

    for _, iceInstanceID in eligibleIceIDs do
        discardIceByID(iceInstanceID)
    end

    return #eligibleIceIDs
end


function IceService.GetByID(iceInstanceID: string): IceRecord?
    return recordsByID[iceInstanceID]
end

function IceService.GetActiveAvailableSpawnPointIDs(): { [string]: boolean }
    local activeSpawnPointIDs = {}

    for _, record in recordsByID do
        if record.State == AVAILABLE_STATE and record.OwnerUserID == nil then
            activeSpawnPointIDs[record.SpawnPointID] = true
        end
    end

    return activeSpawnPointIDs
end

-- Returns true when a new shared field was populated, so field-bound guardians can be rebuilt.
function IceService.HandleWorldCyclePhaseChanged(currentPhase: string, cycleIndex: number): boolean
    if currentPhase == "GreatFrost" then
        grabLockedDuringGreatFrost = WorldCycleConfig.GrabLockedDuringGreatFrost
        setAvailablePromptsEnabled(false)

        if lastResetCycleIndex == cycleIndex then
            return false
        end
        lastResetCycleIndex = cycleIndex

        resetAvailableField()
        populateField()
        hasPopulatedField = true

        if cycleIndex % WorldCycleConfig.SpecialIceEveryNCycles == 0 then
            local specialIceType = spawnSpecialIce(cycleIndex)
            if specialIceType then
                -- Server-wide attention only; the reward stays hidden.
                gameplayEvent:FireAllClients("SpecialIceAwakened", {
                    IceType = specialIceType,
                })
            end
        end

        return true
    end

    if currentPhase == "Day" then
        grabLockedDuringGreatFrost = false
        setAvailablePromptsEnabled(true)

        -- A server that booted mid-Frost has no field yet; it populates at its first Day.
        if not hasPopulatedField then
            populateField()
            hasPopulatedField = true
            return true
        end
    end

    return false
end

-- Carrier failure (Freeze, death, reset/respawn, disconnect): the exact same Ice returns to the
-- shared world as Available with its reward and WeightMultiplier untouched, so anyone can rescue it.
function IceService.ReleaseCarriedIce(player: Player): boolean
    local carriedIceID = carriedIceIDByPlayer[player]
    if carriedIceID == nil then
        return false
    end

    local groundCFrame = getReleaseGroundCFrame(player, carriedIceID)
    clearCarry(player)

    local record = recordsByID[carriedIceID]
    if not record or record.State ~= CARRIED_STATE or record.OwnerUserID ~= player.UserId then
        return false
    end

    local carriedVisualIce = visualIceByID[carriedIceID]
    if carriedVisualIce then
        carriedVisualIce:Destroy()
    end

    record.State = AVAILABLE_STATE
    record.OwnerUserID = nil
    visualIceByID[carriedIceID] = createVisualIce(record, groundCFrame, getOrCreateActiveIceFolder())

    return true
end

function IceService.TryGrabIce(player: Player, iceInstanceID: any): boolean
    if type(iceInstanceID) ~= "string" or iceInstanceID == "" then
        return false
    end

    if grabLockedDuringGreatFrost then
        return false
    end

    if isGrabRateLimited(player) then
        return false
    end

    local record = recordsByID[iceInstanceID]
    if not record then
        return false
    end

    if record.State ~= AVAILABLE_STATE then
        return false
    end

    if record.OwnerUserID ~= nil then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return false
    end

    if playerState.IsFrozen then
        return false
    end

    if playerState.CurrentlyCarryingIceID ~= nil or carriedIceIDByPlayer[player] ~= nil then
        return false
    end

    local visualIce = visualIceByID[iceInstanceID]
    if not visualIce or not visualIce:IsDescendantOf(Workspace) then
        return false
    end

    local interactionPart = IceVisualFactory.GetInteractionPart(visualIce)
    local distance = (rootPart.Position - interactionPart.Position).Magnitude
    if distance > GameConfig.GrabIceMaxDistance then
        return false
    end

    record.State = CARRIED_STATE
    record.OwnerUserID = player.UserId
    playerState.CurrentlyCarryingIceID = iceInstanceID
    carriedIceIDByPlayer[player] = iceInstanceID
    carrierCharacterByPlayer[player] = character
    lastSafeRootPositionByPlayer[player] = getGroundedRootPosition(character)

    local prompt = visualIce:FindFirstChild(GRAB_PROMPT_NAME, true)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.Enabled = false
    end

    attachVisualIceToCharacter(visualIce, rootPart, character, isPlayerRiding(player))

    return true
end

function IceService.TryDepositCarriedIce(player: Player, requestedPen: any): boolean
    if isDepositRateLimited(player) then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return false
    end

    if playerState.IsFrozen then
        return false
    end

    local carriedIceID = playerState.CurrentlyCarryingIceID
    if carriedIceID == nil then
        return false
    end

    local record = recordsByID[carriedIceID]
    if not record then
        return false
    end

    if record.State ~= CARRIED_STATE then
        return false
    end

    if record.OwnerUserID ~= player.UserId then
        return false
    end

    -- Deposits are only accepted at the player's own Pen.
    local base = BaseService.GetBase(player)
    if not base or (rootPart.Position - base.PenFloor.Position).Magnitude > GameConfig.DepositIceMaxDistance then
        return false
    end

    if requestedPen ~= base.Pen or not base.Pen:IsDescendantOf(Workspace) then
        return false
    end

    local thawItem = ThawService.CreateFromDepositedIce(player, {
        IceType = record.IceType,
        IsSpecial = record.IsSpecial,
        CreatureID = record.CreatureID,
        Rarity = record.Rarity,
        WeightMultiplier = record.WeightMultiplier,
    })
    if not thawItem then
        return false
    end
    assert(
        thawItem.WeightMultiplier == record.WeightMultiplier,
        string.format("ThawItem %s changed Ice %s WeightMultiplier during deposit", thawItem.ThawID, carriedIceID)
    )

    record.State = DEPOSITED_STATE
    clearCarry(player)
    discardIceByID(carriedIceID)

    return true
end

function IceService.Start()
    if hasStarted then
        return
    end

    hasStarted = true

    -- Ride/Unride while carrying moves the same welded Ice between the walking and riding offsets.
    local function refreshCarryOffset(player: Player)
        local iceInstanceID = carriedIceIDByPlayer[player]
        local visualIce = if iceInstanceID then visualIceByID[iceInstanceID] else nil
        local character = carrierCharacterByPlayer[player]
        local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
        local carryWeld = if visualIce then visualIce:FindFirstChild(CARRY_WELD_NAME) else nil
        if not visualIce or not rootPart or not rootPart:IsA("BasePart") or not carryWeld then
            return
        end

        carryWeld.Enabled = false
        visualIce.CFrame = rootPart.CFrame * getCarryOffsetFromRoot(visualIce, isPlayerRiding(player))
        carryWeld.Enabled = true
    end

    local function connectPlayer(player: Player)
        player:GetAttributeChangedSignal(MOUNT_STATE_ATTRIBUTE):Connect(function()
            refreshCarryOffset(player)
        end)

        player.CharacterAdded:Connect(function(character)
            connectCharacterFailure(player, character)
        end)

        player.CharacterRemoving:Connect(function()
            IceService.ReleaseCarriedIce(player)
        end)

        if player.Character then
            connectCharacterFailure(player, player.Character)
        end
    end

    Players.PlayerAdded:Connect(connectPlayer)

    Players.PlayerRemoving:Connect(function(player)
        IceService.ReleaseCarriedIce(player)
        lastGrabRequestAtByPlayer[player] = nil
        lastDepositRequestAtByPlayer[player] = nil
    end)

    RunService.Heartbeat:Connect(trackSafeCarrierPositions)

    for _, player in Players:GetPlayers() do
        connectPlayer(player)
    end

    getOrCreateActiveIceFolder()

    for _, iceType in ICE_TYPE_ORDER do
        local config = IceConfig[iceType]
        assert(config, string.format("Missing IceConfig for %s", iceType))
        assert(config.IceType == iceType, string.format("IceConfig.%s.IceType must match its key", iceType))
        validateRewardConfiguration(config)
    end

    assert(
        type(WorldCycleConfig.SpecialIceEveryNCycles) == "number"
            and WorldCycleConfig.SpecialIceEveryNCycles >= 1
            and WorldCycleConfig.SpecialIceEveryNCycles % 1 == 0,
        "WorldCycleConfig.SpecialIceEveryNCycles must be a positive integer"
    )
    for _, entry in SpecialIceConfig.TypeWeights do
        assert(isFiniteNumber(entry.Weight) and entry.Weight >= 0, "Special Ice type weights must be non-negative")
        validateRewardConfiguration(getSpecialRewardProfile(entry.IceType))
        validateSpecialSilhouettes(entry.IceType)
    end

    -- Boot during Day populates the current field; boot during Great Frost waits for the next Day.
    if WorldCycleService.GetState().CurrentPhase == "GreatFrost" then
        grabLockedDuringGreatFrost = WorldCycleConfig.GrabLockedDuringGreatFrost
    else
        populateField()
        hasPopulatedField = true
    end
end

return IceService
