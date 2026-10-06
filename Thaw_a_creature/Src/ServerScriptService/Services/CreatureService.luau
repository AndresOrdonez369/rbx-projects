local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureSurvivalConfig = require(shared:WaitForChild("CreatureSurvivalConfig"))
local CreatureStatCalculator = require(shared:WaitForChild("CreatureStatCalculator"))
local GameConfig = require(shared:WaitForChild("GameConfig"))
local SizeConfig = require(shared:WaitForChild("SizeConfig"))

local CreatureRevealService = require(script.Parent.CreatureRevealService)
local PlayerStateService = require(script.Parent.PlayerStateService)

local CreatureService = {}

type LogicalTargetBounds = {
    RelativeCFrame: CFrame,
    Size: Vector3,
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")
assert(
    CreatureSurvivalConfig.CreatureVitalityMax > CreatureSurvivalConfig.FrostedAtVitality,
    "Creature Vitality max must exceed the Frosted threshold"
)
assert(
    CreatureSurvivalConfig.HearthRecovery == "FullRestoreOnEntry",
    "Unsupported Equipped-creature Hearth recovery rule"
)

local PEN_POSITION_FOLDER_NAME = "CreaturePositions"
local PEN_VISUALS_FOLDER_NAME = "CreatureVisuals"
local REPLICATED_CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local PLAYER_FOLDER_PREFIX = "Player_"

local hasStarted = false
local equipBaseAnchor: BasePart? = nil
local penCreaturePositions: { [number]: BasePart } = {}
local penVisualsFolder: Folder? = nil
local lastEquipRequestAtByPlayer: { [Player]: number } = {}
local lastPenManagementRequestAtByPlayer: { [Player]: number } = {}
local logicalTargetBoundsByCreatureID: { [string]: LogicalTargetBounds } = {}
local issuedCreatureGUIDs: { [string]: boolean } = {}

local function getCreatureIDForGUID(
    playerState: PlayerStateService.PlayerState,
    creatureGUID: string?
): string?
    local copy = if type(creatureGUID) == "string" then playerState.CreatureCopies[creatureGUID] else nil
    return if copy then copy.CreatureID else nil
end

local function assertOwnershipInvariants(playerState: PlayerStateService.PlayerState): ()
    local allocatedGUIDs = {}
    local occupiedPenCount = 0

    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        local creatureGUID = playerState.PenSlots[slotIndex]
        if creatureGUID ~= nil then
            assert(type(creatureGUID) == "string", string.format("Pen slot %d must contain a CreatureGUID or nil", slotIndex))
            assert(playerState.CreatureCopies[creatureGUID], string.format("Pen slot %d references missing CreatureGUID %s", slotIndex, creatureGUID))
            assert(not allocatedGUIDs[creatureGUID], string.format("CreatureGUID %s occupies multiple Pen slots", creatureGUID))
            allocatedGUIDs[creatureGUID] = true
            occupiedPenCount += 1
        end
    end

    local equippedCreatureGUID = playerState.EquippedCreatureGUID
    local equippedCount = 0
    if equippedCreatureGUID ~= nil then
        assert(playerState.CreatureCopies[equippedCreatureGUID], string.format("Equipped CreatureGUID %s is not owned", equippedCreatureGUID))
        assert(not allocatedGUIDs[equippedCreatureGUID], string.format("Equipped CreatureGUID %s is also in the Pen", equippedCreatureGUID))
        allocatedGUIDs[equippedCreatureGUID] = true
        equippedCount = 1
    end

    local ownedCount = 0
    local inventoryCount = 0
    for creatureGUID, copy in playerState.CreatureCopies do
        ownedCount += 1
        assert(type(creatureGUID) == "string" and creatureGUID ~= "", "Creature copy keys must be non-empty GUID strings")
        assert(type(copy) == "table" and CreatureConfig[copy.CreatureID], string.format("CreatureGUID %s has an invalid CreatureID", creatureGUID))
        local hasValidSize = pcall(SizeConfig.GetVisualScale, copy.WeightMultiplier)
        assert(
            hasValidSize,
            string.format("CreatureGUID %s has an invalid WeightMultiplier", creatureGUID)
        )
        if not allocatedGUIDs[creatureGUID] then
            inventoryCount += 1
        end
    end

    assert(
        ownedCount == inventoryCount + occupiedPenCount + equippedCount,
        string.format(
            "Creature allocation count mismatch: owned=%d, inventory=%d, pen=%d, equipped=%d",
            ownedCount,
            inventoryCount,
            occupiedPenCount,
            equippedCount
        )
    )
end

local function getPenIncome(playerState: PlayerStateService.PlayerState): number
    local totalIncome = 0
    local contributingGUIDs = {}

    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        local creatureGUID = playerState.PenSlots[slotIndex]
        if type(creatureGUID) == "string" then
            if contributingGUIDs[creatureGUID] then
                warn(string.format(
                    "[CreatureService] Skipped duplicate CreatureGUID %s in Pen slot %d",
                    creatureGUID,
                    slotIndex
                ))
            else
                contributingGUIDs[creatureGUID] = true

                local stats = CreatureService.GetCreatureCopyStats(playerState, creatureGUID)
                if stats then
                    totalIncome += stats.FinalIncome
                end
            end
        elseif creatureGUID ~= nil then
            warn(string.format("[CreatureService] Skipped invalid value in Pen slot %d", slotIndex))
        end
    end

    return totalIncome
end

local function runPenIncomeLoop(): ()
    while true do
        task.wait(GameConfig.PenIncomeIntervalSeconds)

        for _, player in Players:GetPlayers() do
            local playerState = PlayerStateService.GetState(player)
            if playerState then
                local totalIncome = getPenIncome(playerState)
                if totalIncome > 0 then
                    PlayerStateService.AddCash(player, totalIncome)
                end
            end
        end
    end
end

local function getCreatureLogicalTargetLocalBounds(creatureID: string): LogicalTargetBounds?
    local cachedBounds = logicalTargetBoundsByCreatureID[creatureID]
    if cachedBounds then
        return cachedBounds
    end

    local creatureVisuals = ReplicatedStorage:FindFirstChild(REPLICATED_CREATURE_VISUALS_FOLDER_NAME)
    local visual = creatureVisuals and creatureVisuals:FindFirstChild(creatureID)
    if not visual or not visual:IsA("Model") then
        return nil
    end

    local boundsCFrame, boundsSize = visual:GetBoundingBox()
    local bounds = {
        RelativeCFrame = visual:GetPivot():ToObjectSpace(boundsCFrame),
        Size = boundsSize,
    }
    logicalTargetBoundsByCreatureID[creatureID] = bounds

    return bounds
end

local function isEquipRateLimited(player: Player): boolean
    local now = os.clock()
    local lastRequestAt = lastEquipRequestAtByPlayer[player]
    lastEquipRequestAtByPlayer[player] = now

    return lastRequestAt ~= nil and now - lastRequestAt < GameConfig.EquipRequestMinInterval
end

local function isPenManagementRateLimited(player: Player): boolean
    local now = os.clock()
    local lastRequestAt = lastPenManagementRequestAtByPlayer[player]
    lastPenManagementRequestAtByPlayer[player] = now

    return lastRequestAt ~= nil and now - lastRequestAt < GameConfig.PenManagementRequestMinInterval
end

function CreatureService.CreateCreatureCopy(
    player: Player,
    creatureID: string,
    weightMultiplier: number
): string?
    local playerState = PlayerStateService.GetState(player)
    local hasValidSize = pcall(SizeConfig.GetVisualScale, weightMultiplier)
    if not playerState
        or not CreatureConfig[creatureID]
        or not hasValidSize
    then
        return nil
    end

    local creatureGUID = HttpService:GenerateGUID(false)
    while issuedCreatureGUIDs[creatureGUID] or playerState.CreatureCopies[creatureGUID] do
        creatureGUID = HttpService:GenerateGUID(false)
    end

    issuedCreatureGUIDs[creatureGUID] = true
    playerState.CreatureCopies[creatureGUID] = {
        CreatureID = creatureID,
        WeightMultiplier = weightMultiplier,
    }
    assertOwnershipInvariants(playerState)

    return creatureGUID
end

function CreatureService.GetCreatureCopy(
    playerState: PlayerStateService.PlayerState,
    creatureGUID: string
): PlayerStateService.CreatureCopy?
    return playerState.CreatureCopies[creatureGUID]
end

function CreatureService.GetCreatureIDForGUID(
    playerState: PlayerStateService.PlayerState,
    creatureGUID: string?
): string?
    return getCreatureIDForGUID(playerState, creatureGUID)
end

function CreatureService.GetCreatureCopyStats(
    playerState: PlayerStateService.PlayerState,
    creatureGUID: string
): CreatureStatCalculator.CreatureCopyStats?
    if type(creatureGUID) ~= "string" or creatureGUID == "" then
        warn("[CreatureService] Cannot derive creature-copy stats without a valid CreatureGUID")
        return nil
    end

    local copy = playerState.CreatureCopies[creatureGUID]
    if type(copy) ~= "table" then
        warn(string.format(
            "[CreatureService] Cannot derive creature-copy stats for missing or malformed CreatureGUID %s",
            creatureGUID
        ))
        return nil
    end

    local derived, statsOrError = pcall(
        CreatureStatCalculator.Derive,
        copy.CreatureID,
        copy.WeightMultiplier
    )
    if not derived then
        warn(string.format(
            "[CreatureService] Rejected invalid authoritative data for CreatureGUID %s: %s",
            creatureGUID,
            tostring(statsOrError)
        ))
        return nil
    end

    return statsOrError
end

function CreatureService.SendCreatureStateUpdate(player: Player): ()
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return
    end

    assertOwnershipInvariants(playerState)

    local penSlotByGUID = {}
    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        local creatureGUID = playerState.PenSlots[slotIndex]
        if type(creatureGUID) == "string" then
            penSlotByGUID[creatureGUID] = slotIndex
        end
    end

    local creatureRecords = {}
    for creatureGUID, copy in playerState.CreatureCopies do
        local penSlotIndex = penSlotByGUID[creatureGUID]
        local allocationState = "Inventory"
        local allocationOrder = 3
        if playerState.EquippedCreatureGUID == creatureGUID then
            allocationState = "Equipped"
            allocationOrder = 1
        elseif penSlotIndex then
            allocationState = "Pen"
            allocationOrder = 2
        end

        local stats = CreatureService.GetCreatureCopyStats(playerState, creatureGUID)
        assert(stats, string.format("CreatureGUID %s must have valid derived stats", creatureGUID))

        table.insert(creatureRecords, {
            CreatureGUID = creatureGUID,
            CreatureID = copy.CreatureID,
            Scale = stats.Scale,
            FinalIncome = stats.FinalIncome,
            FinalWalkSpeed = stats.FinalWalkSpeed,
            AllocationState = allocationState,
            PenSlotIndex = penSlotIndex,
            AllocationOrder = allocationOrder,
        })
    end

    table.sort(creatureRecords, function(left, right)
        if left.AllocationOrder ~= right.AllocationOrder then
            return left.AllocationOrder < right.AllocationOrder
        end
        if left.AllocationState == "Pen" and left.PenSlotIndex ~= right.PenSlotIndex then
            return left.PenSlotIndex < right.PenSlotIndex
        end
        if left.CreatureID ~= right.CreatureID then
            return left.CreatureID < right.CreatureID
        end

        return left.CreatureGUID < right.CreatureGUID
    end)

    for _, record in creatureRecords do
        record.AllocationOrder = nil
    end

    gameplayEvent:FireClient(player, "CreatureStateUpdated", {
        Creatures = creatureRecords,
    })
end

local function getPlayerPenVisualFolder(player: Player): Folder
    local container = penVisualsFolder
    assert(container, "CreatureService must be started before creating Pen creature visuals")

    local folderName = PLAYER_FOLDER_PREFIX .. player.UserId
    local existingFolder = container:FindFirstChild(folderName)
    if existingFolder then
        assert(existingFolder:IsA("Folder"), string.format("%s must be a Folder", existingFolder:GetFullName()))
        return existingFolder
    end

    local folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = container

    return folder
end

local function refreshPenSlotVisual(player: Player, slotIndex: number): ()
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return
    end

    local slotName = "Slot" .. slotIndex
    local playerFolder = getPlayerPenVisualFolder(player)
    local existingVisual = playerFolder:FindFirstChild(slotName)
    if existingVisual then
        existingVisual:Destroy()
    end

    local creatureGUID = playerState.PenSlots[slotIndex]
    if type(creatureGUID) ~= "string" then
        return
    end
    local creatureID = getCreatureIDForGUID(playerState, creatureGUID)
    assert(creatureID, string.format("Pen slot %d references missing CreatureGUID %s", slotIndex, creatureGUID))
    local stats = CreatureService.GetCreatureCopyStats(playerState, creatureGUID)
    assert(stats, string.format("Pen slot %d references CreatureGUID %s with invalid stats", slotIndex, creatureGUID))

    local position = penCreaturePositions[slotIndex]
    local baseAnchor = equipBaseAnchor
    assert(position and baseAnchor, "CreatureService Pen positions must be initialized before presentation")

    local model = CreatureRevealService.Present(
        creatureGUID,
        creatureID,
        stats,
        position.CFrame,
        baseAnchor.Position,
        playerFolder
    )
    if model then
        model.Name = slotName
    end
end

local function removePlayerPenVisuals(player: Player): ()
    local container = penVisualsFolder
    local playerFolder = container and container:FindFirstChild(PLAYER_FOLDER_PREFIX .. player.UserId)
    if playerFolder then
        playerFolder:Destroy()
    end
end

function CreatureService.AssignRevealedCreatureToFirstEmptyPenSlot(player: Player, creatureGUID: string): number?
    local playerState = PlayerStateService.GetState(player)
    if not playerState or not playerState.CreatureCopies[creatureGUID] then
        return nil
    end

    if playerState.EquippedCreatureGUID == creatureGUID then
        return nil
    end
    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        if playerState.PenSlots[slotIndex] == creatureGUID then
            return nil
        end
    end

    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        if playerState.PenSlots[slotIndex] == nil then
            playerState.PenSlots[slotIndex] = creatureGUID
            assertOwnershipInvariants(playerState)

            local presented, presentationError = pcall(refreshPenSlotVisual, player, slotIndex)
            local creatureID = getCreatureIDForGUID(playerState, creatureGUID) or "Unknown"
            if not presented then
                warn(string.format(
                    "[CreatureService] Pen slot %d retained creature %s (%s) but presentation failed: %s",
                    slotIndex,
                    creatureID,
                    creatureGUID,
                    tostring(presentationError)
                ))
            end

            return slotIndex
        end
    end

    return nil
end

function CreatureService.GetEquippedWalkSpeed(playerState: PlayerStateService.PlayerState): number
    local creatureGUID = playerState.EquippedCreatureGUID
    if type(creatureGUID) ~= "string" then
        return GameConfig.BaseWalkSpeed
    end

    local stats = CreatureService.GetCreatureCopyStats(playerState, creatureGUID)
    if not stats then
        return GameConfig.BaseWalkSpeed
    end

    if playerState.CreatureFrosted == true and not CreatureSurvivalConfig.FrostedSpeedBonusEnabled then
        return GameConfig.BaseWalkSpeed
    end

    return stats.FinalWalkSpeed
end

function CreatureService.ApplyEquippedWalkSpeed(player: Player): boolean
    local playerState = PlayerStateService.GetState(player)
    local character = player.Character
    if not playerState or not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
    if player.Character ~= character or not humanoid or not humanoid:IsA("Humanoid") then
        return false
    end

    local walkSpeed = CreatureService.GetEquippedWalkSpeed(playerState)
    humanoid.WalkSpeed = walkSpeed

    return true
end

function CreatureService.SendEquippedCreatureUpdate(player: Player): ()
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return
    end

    local equippedCreatureID = getCreatureIDForGUID(playerState, playerState.EquippedCreatureGUID)
    local equippedCreatureGUID = playerState.EquippedCreatureGUID
    local equippedStats = if equippedCreatureGUID
        then CreatureService.GetCreatureCopyStats(playerState, equippedCreatureGUID)
        else nil
    assert(equippedCreatureGUID == nil or equippedStats, "Equipped creature copy must have valid derived stats")
    gameplayEvent:FireClient(player, "EquippedCreatureChanged", {
        EquippedCreature = equippedCreatureID,
        EquippedCreatureGUID = equippedCreatureGUID,
        Scale = if equippedStats then equippedStats.Scale else nil,
        FinalIncome = if equippedStats then equippedStats.FinalIncome else nil,
        FinalWalkSpeed = if equippedStats then equippedStats.FinalWalkSpeed else nil,
        CreatureVitality = playerState.CreatureVitality,
        CreatureVitalityMax = CreatureSurvivalConfig.CreatureVitalityMax,
        CreatureFrosted = playerState.CreatureFrosted == true,
    })
end

function CreatureService.GetLogicalEquippedCreatureTargetCFrame(
    player: Player,
    expectedCreatureGUID: string
): CFrame?
    local playerState = PlayerStateService.GetState(player)
    if player.Parent ~= Players
        or not playerState
        or playerState.IsFrozen
        or playerState.EquippedCreatureGUID ~= expectedCreatureGUID
        or type(playerState.CreatureVitality) ~= "number"
        or playerState.CreatureVitality <= CreatureSurvivalConfig.FrostedAtVitality
        or playerState.CreatureFrosted ~= false
    then
        return nil
    end

    local character = player.Character
    if not character or not character:IsDescendantOf(Workspace) then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return nil
    end

    local behindPosition = rootPart.CFrame:PointToWorldSpace(
        Vector3.new(0, 0, CreatureSurvivalConfig.LogicalTargetFollowDistance)
    )
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { character }

    local rayOrigin = behindPosition + Vector3.new(0, CreatureSurvivalConfig.LogicalTargetGroundRayHeight, 0)
    local groundResult = Workspace:Raycast(
        rayOrigin,
        Vector3.new(0, -CreatureSurvivalConfig.LogicalTargetGroundRayDepth, 0),
        raycastParams
    )

    local targetPosition = if groundResult then groundResult.Position else behindPosition
    local lookVector = rootPart.CFrame.LookVector
    local horizontalLook = Vector3.new(lookVector.X, 0, lookVector.Z)

    if horizontalLook.Magnitude < 0.001 then
        horizontalLook = Vector3.new(0, 0, -1)
    else
        horizontalLook = horizontalLook.Unit
    end

    return CFrame.lookAt(targetPosition, targetPosition + horizontalLook)
end

function CreatureService.GetLogicalEquippedCreatureTargetPosition(
    player: Player,
    expectedCreatureGUID: string
): Vector3?
    local targetCFrame = CreatureService.GetLogicalEquippedCreatureTargetCFrame(player, expectedCreatureGUID)
    return if targetCFrame then targetCFrame.Position else nil
end

function CreatureService.GetLogicalEquippedCreatureTargetBounds(
    player: Player,
    expectedCreatureGUID: string
): (CFrame?, Vector3?)
    local playerState = PlayerStateService.GetState(player)
    local creatureID = if playerState then getCreatureIDForGUID(playerState, expectedCreatureGUID) else nil
    local copy = if playerState then playerState.CreatureCopies[expectedCreatureGUID] else nil
    local targetCFrame = CreatureService.GetLogicalEquippedCreatureTargetCFrame(player, expectedCreatureGUID)
    local localBounds = if creatureID then getCreatureLogicalTargetLocalBounds(creatureID) else nil
    if not targetCFrame or not localBounds or not copy then
        return nil, nil
    end

    local copySizeScale = SizeConfig.GetVisualScale(copy.WeightMultiplier)
    local scaledRelativeCFrame = CFrame.new(localBounds.RelativeCFrame.Position * copySizeScale)
        * localBounds.RelativeCFrame.Rotation

    return targetCFrame * scaledRelativeCFrame, localBounds.Size * copySizeScale
end

function CreatureService.ApplyEquippedCreatureDamage(
    player: Player,
    expectedCreatureGUID: string,
    amount: number
): boolean
    if type(amount) ~= "number" or amount <= 0 then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState
        or playerState.EquippedCreatureGUID ~= expectedCreatureGUID
        or type(playerState.CreatureVitality) ~= "number"
        or playerState.CreatureVitality <= CreatureSurvivalConfig.FrostedAtVitality
        or playerState.CreatureFrosted ~= false
    then
        return false
    end

    playerState.CreatureVitality = math.clamp(
        playerState.CreatureVitality - amount,
        CreatureSurvivalConfig.FrostedAtVitality,
        CreatureSurvivalConfig.CreatureVitalityMax
    )

    if playerState.CreatureVitality <= CreatureSurvivalConfig.FrostedAtVitality then
        playerState.CreatureFrosted = true

        if not CreatureSurvivalConfig.FrostedSpeedBonusEnabled then
            CreatureService.ApplyEquippedWalkSpeed(player)
        end
    end

    CreatureService.SendEquippedCreatureUpdate(player)
    return true
end

function CreatureService.RecoverEquippedCreatureAtHearth(player: Player): boolean
    local playerState = PlayerStateService.GetState(player)
    if not playerState or type(playerState.EquippedCreatureGUID) ~= "string" then
        return false
    end

    if playerState.CreatureVitality == CreatureSurvivalConfig.CreatureVitalityMax
        and playerState.CreatureFrosted == false
    then
        return false
    end

    playerState.CreatureVitality = CreatureSurvivalConfig.CreatureVitalityMax
    playerState.CreatureFrosted = false

    CreatureService.ApplyEquippedWalkSpeed(player)
    CreatureService.SendEquippedCreatureUpdate(player)

    return true
end

function CreatureService.TryEquipCreature(player: Player, creatureGUID: any, ...): boolean
    if type(creatureGUID) ~= "string" or creatureGUID == "" or select("#", ...) ~= 0 then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return false
    end

    local copy = playerState.CreatureCopies[creatureGUID]
    if not copy then
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

    local baseAnchor = equipBaseAnchor
    if not baseAnchor
        or not baseAnchor:IsDescendantOf(Workspace)
        or (rootPart.Position - baseAnchor.Position).Magnitude > GameConfig.EquipMaxDistance
    then
        return false
    end

    if isEquipRateLimited(player) then
        return false
    end

    local previouslyEquippedCreatureGUID = playerState.EquippedCreatureGUID
    local sourcePenSlotIndex: number? = nil
    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        if playerState.PenSlots[slotIndex] == creatureGUID then
            if sourcePenSlotIndex then
                return false
            end
            sourcePenSlotIndex = slotIndex
        end
    end

    if previouslyEquippedCreatureGUID == creatureGUID then
        if sourcePenSlotIndex then
            return false
        end
        CreatureService.SendEquippedCreatureUpdate(player)
        CreatureService.SendCreatureStateUpdate(player)
        return true
    end

    if not CreatureService.GetCreatureCopyStats(playerState, creatureGUID) then
        return false
    end

    if sourcePenSlotIndex then
        playerState.PenSlots[sourcePenSlotIndex] = nil
    end

    local previousCreatureVitality = playerState.CreatureVitality
    local previousCreatureFrosted = playerState.CreatureFrosted
    playerState.EquippedCreatureGUID = creatureGUID
    playerState.CreatureVitality = CreatureSurvivalConfig.CreatureVitalityMax
    playerState.CreatureFrosted = false
    assertOwnershipInvariants(playerState)

    if not CreatureService.ApplyEquippedWalkSpeed(player) then
        playerState.EquippedCreatureGUID = previouslyEquippedCreatureGUID
        playerState.CreatureVitality = previousCreatureVitality
        playerState.CreatureFrosted = previousCreatureFrosted
        if sourcePenSlotIndex then
            playerState.PenSlots[sourcePenSlotIndex] = creatureGUID
        end
        assertOwnershipInvariants(playerState)
        return false
    end

    if sourcePenSlotIndex then
        local refreshed, refreshError = pcall(refreshPenSlotVisual, player, sourcePenSlotIndex)
        if not refreshed then
            playerState.EquippedCreatureGUID = previouslyEquippedCreatureGUID
            playerState.CreatureVitality = previousCreatureVitality
            playerState.CreatureFrosted = previousCreatureFrosted
            playerState.PenSlots[sourcePenSlotIndex] = creatureGUID
            assertOwnershipInvariants(playerState)
            CreatureService.ApplyEquippedWalkSpeed(player)
            warn(string.format(
                "[CreatureService] Equip from Pen slot %d rolled back because its visual could not be cleared: %s",
                sourcePenSlotIndex,
                tostring(refreshError)
            ))
            return false
        end
    end

    CreatureService.SendEquippedCreatureUpdate(player)
    CreatureService.SendCreatureStateUpdate(player)
    return true
end

function CreatureService.TryUnequipCreature(player: Player, expectedCreatureGUID: any, ...): boolean
    if type(expectedCreatureGUID) ~= "string" or expectedCreatureGUID == "" or select("#", ...) ~= 0 then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState
        or playerState.EquippedCreatureGUID ~= expectedCreatureGUID
        or not playerState.CreatureCopies[expectedCreatureGUID]
    then
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

    local baseAnchor = equipBaseAnchor
    if not baseAnchor
        or not baseAnchor:IsDescendantOf(Workspace)
        or (rootPart.Position - baseAnchor.Position).Magnitude > GameConfig.EquipMaxDistance
    then
        return false
    end

    if isEquipRateLimited(player) then
        return false
    end

    local previousCreatureVitality = playerState.CreatureVitality
    local previousCreatureFrosted = playerState.CreatureFrosted
    playerState.EquippedCreatureGUID = nil
    playerState.CreatureVitality = nil
    playerState.CreatureFrosted = nil
    assertOwnershipInvariants(playerState)

    if not CreatureService.ApplyEquippedWalkSpeed(player) then
        playerState.EquippedCreatureGUID = expectedCreatureGUID
        playerState.CreatureVitality = previousCreatureVitality
        playerState.CreatureFrosted = previousCreatureFrosted
        assertOwnershipInvariants(playerState)
        return false
    end

    CreatureService.SendEquippedCreatureUpdate(player)
    CreatureService.SendCreatureStateUpdate(player)
    return true
end

local function getValidPenManagementState(
    player: Player,
    creatureGUID: any,
    extraArgumentCount: number
): PlayerStateService.PlayerState?
    if type(creatureGUID) ~= "string" or creatureGUID == "" or extraArgumentCount ~= 0 then
        return nil
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState or not playerState.CreatureCopies[creatureGUID] then
        return nil
    end

    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return nil
    end

    local baseAnchor = equipBaseAnchor
    if not baseAnchor
        or not baseAnchor:IsDescendantOf(Workspace)
        or (rootPart.Position - baseAnchor.Position).Magnitude > GameConfig.PenManagementMaxDistance
    then
        return nil
    end

    if isPenManagementRateLimited(player) then
        return nil
    end

    return playerState
end

function CreatureService.TryPlaceInPen(player: Player, creatureGUID: any, ...): boolean
    local playerState = getValidPenManagementState(player, creatureGUID, select("#", ...))
    if not playerState or playerState.EquippedCreatureGUID == creatureGUID then
        return false
    end

    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        if playerState.PenSlots[slotIndex] == creatureGUID then
            return false
        end
    end

    local emptySlotIndex: number? = nil
    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        if playerState.PenSlots[slotIndex] == nil then
            emptySlotIndex = slotIndex
            break
        end
    end

    if not emptySlotIndex then
        return false
    end

    local copy = playerState.CreatureCopies[creatureGUID]
    playerState.PenSlots[emptySlotIndex] = creatureGUID
    assertOwnershipInvariants(playerState)

    local refreshed, refreshError = pcall(refreshPenSlotVisual, player, emptySlotIndex)
    if not refreshed then
        warn(string.format(
            "[CreatureService] Placed %s (%s) in Pen slot %d but presentation failed: %s",
            copy.CreatureID,
            creatureGUID,
            emptySlotIndex,
            tostring(refreshError)
        ))
    end

    CreatureService.SendCreatureStateUpdate(player)
    return true
end

function CreatureService.TryRemoveFromPen(player: Player, creatureGUID: any, ...): boolean
    local playerState = getValidPenManagementState(player, creatureGUID, select("#", ...))
    if not playerState then
        return false
    end

    local matchingSlotIndex: number? = nil
    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        if playerState.PenSlots[slotIndex] == creatureGUID then
            if matchingSlotIndex then
                return false
            end
            matchingSlotIndex = slotIndex
        end
    end

    if not matchingSlotIndex then
        return false
    end

    playerState.PenSlots[matchingSlotIndex] = nil
    assertOwnershipInvariants(playerState)

    local refreshed, refreshError = pcall(refreshPenSlotVisual, player, matchingSlotIndex)
    if not refreshed then
        warn(string.format(
            "[CreatureService] Removed %s from Pen slot %d but presentation failed: %s",
            creatureGUID,
            matchingSlotIndex,
            tostring(refreshError)
        ))
    end

    CreatureService.SendCreatureStateUpdate(player)
    return true
end

function CreatureService.Start(): ()
    if hasStarted then
        return
    end

    hasStarted = true

    assert(
        type(GameConfig.PenIncomeIntervalSeconds) == "number" and GameConfig.PenIncomeIntervalSeconds == 1,
        "Prototype Pen income interval must be exactly one second"
    )

    local prototypeBase = Workspace:WaitForChild("PrototypeBase")
    local pen = prototypeBase:WaitForChild("Pen")
    local penFloor = pen:WaitForChild("PenFloor")
    local positionFolder = pen:WaitForChild(PEN_POSITION_FOLDER_NAME)

    assert(prototypeBase:IsA("Folder"), "Workspace.PrototypeBase must be a Folder")
    assert(pen:IsA("Model"), "Workspace.PrototypeBase.Pen must be a Model")
    assert(penFloor:IsA("BasePart"), "Workspace.PrototypeBase.Pen.PenFloor must be a BasePart")
    assert(positionFolder:IsA("Folder"), "Workspace.PrototypeBase.Pen.CreaturePositions must be a Folder")
    assert(
        #positionFolder:GetChildren() == GameConfig.ActivePenCreatureSlots,
        "Workspace.PrototypeBase.Pen must have exactly four creature positions"
    )

    equipBaseAnchor = penFloor

    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        local position = positionFolder:WaitForChild("Slot" .. slotIndex)
        assert(position:IsA("BasePart"), string.format("Pen creature position Slot%d must be a BasePart", slotIndex))
        penCreaturePositions[slotIndex] = position
    end

    local existingVisuals = pen:FindFirstChild(PEN_VISUALS_FOLDER_NAME)
    if existingVisuals then
        assert(existingVisuals:IsA("Folder"), "Workspace.PrototypeBase.Pen.CreatureVisuals must be a Folder")
        existingVisuals:ClearAllChildren()
        penVisualsFolder = existingVisuals
    else
        local folder = Instance.new("Folder")
        folder.Name = PEN_VISUALS_FOLDER_NAME
        folder.Parent = pen
        penVisualsFolder = folder
    end

    local function connectPlayer(player: Player)
        player.CharacterAdded:Connect(function()
            CreatureService.ApplyEquippedWalkSpeed(player)
        end)

        if player.Character then
            task.spawn(CreatureService.ApplyEquippedWalkSpeed, player)
        end

        for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
            local presented, presentationError = pcall(refreshPenSlotVisual, player, slotIndex)
            if not presented then
                warn(string.format(
                    "[CreatureService] Failed to refresh Pen slot %d for %s: %s",
                    slotIndex,
                    player.Name,
                    tostring(presentationError)
                ))
            end
        end
    end

    Players.PlayerAdded:Connect(connectPlayer)

    Players.PlayerRemoving:Connect(function(player)
        lastEquipRequestAtByPlayer[player] = nil
        lastPenManagementRequestAtByPlayer[player] = nil
        removePlayerPenVisuals(player)
    end)

    for _, player in Players:GetPlayers() do
        connectPlayer(player)
    end

    task.spawn(runPenIncomeLoop)
end

return CreatureService
