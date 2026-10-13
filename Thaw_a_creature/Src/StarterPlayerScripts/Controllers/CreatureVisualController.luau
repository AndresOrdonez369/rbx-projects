local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureStatPresentation = require(shared:WaitForChild("CreatureStatPresentation"))
local CreatureSurvivalConfig = require(shared:WaitForChild("CreatureSurvivalConfig"))

-- Presents every player's Equipped creature: following behind them, or under them while Riding.
-- Driven by the mount attributes the server replicates on each Player; purely cosmetic.
local CreatureVisualController = {}

local FOLLOW_SMOOTHING_RATE = 8
local SNAP_DISTANCE = 30
local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local FOLLOWER_NAME = "EquippedFollower"
local RIDER_ANCHOR_ATTRIBUTE = "RiderAnchorOffset"
local MOUNT_CREATURE_ID_ATTRIBUTE = "MountCreatureID"
local MOUNT_SCALE_ATTRIBUTE = "MountScale"
local MOUNT_STATE_ATTRIBUTE = "MountState"
local MOUNT_FROSTED_ATTRIBUTE = "MountFrosted"
local RIDING_STATE = "Riding"

type Presentation = {
    Model: Model,
    Character: Model,
    RootPart: BasePart,
    RiderAnchor: Vector3,
}

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")
local creatureVisuals = ReplicatedStorage:WaitForChild(CREATURE_VISUALS_FOLDER_NAME)

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")
assert(creatureVisuals:IsA("Folder"), "ReplicatedStorage.CreatureVisuals must be a Folder")

local started = false
local presentationsByPlayer: { [Player]: Presentation } = {}
local rebuildRevisionByPlayer: { [Player]: number } = {}
local localStats: CreatureStatPresentation.DisplayStats? = nil

local function destroyPresentation(player: Player): ()
    local presentation = presentationsByPlayer[player]
    presentationsByPlayer[player] = nil
    if presentation then
        presentation.Model:Destroy()
    end
end

local function makeFollowerSafe(model: Model): ()
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
        end
    end
end

local function getTargetCFrame(player: Player, presentation: Presentation): CFrame
    local rootPart = presentation.RootPart
    local isRiding = player:GetAttribute(MOUNT_STATE_ATTRIBUTE) == RIDING_STATE
    local riderAnchor = presentation.RiderAnchor
    local anchorPosition = if isRiding
        then rootPart.Position
        else rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, CreatureSurvivalConfig.LogicalTargetFollowDistance))

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { presentation.Character, presentation.Model }

    local rayOrigin = anchorPosition + Vector3.new(0, CreatureSurvivalConfig.LogicalTargetGroundRayHeight, 0)
    local rayDepth = CreatureSurvivalConfig.LogicalTargetGroundRayDepth + if isRiding then math.max(riderAnchor.Y, 0) else 0
    local groundResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -rayDepth, 0), raycastParams)
    local targetPosition = if groundResult then groundResult.Position else anchorPosition
    local lookVector = rootPart.CFrame.LookVector
    local horizontalLook = Vector3.new(lookVector.X, 0, lookVector.Z)

    if horizontalLook.Magnitude < 0.001 then
        horizontalLook = Vector3.new(0, 0, -1)
    else
        horizontalLook = horizontalLook.Unit
    end

    local groundCFrame = CFrame.lookAt(targetPosition, targetPosition + horizontalLook)
    if not isRiding then
        return groundCFrame
    end

    -- Match the server's logical mount pivot: the scaled rider anchor sits beneath the rider.
    return groundCFrame * CFrame.new(-riderAnchor.X, 0, -riderAnchor.Z)
end

local function rebuildPresentation(player: Player): ()
    local revision = (rebuildRevisionByPlayer[player] or 0) + 1
    rebuildRevisionByPlayer[player] = revision
    destroyPresentation(player)

    local creatureID = player:GetAttribute(MOUNT_CREATURE_ID_ATTRIBUTE)
    local scale = player:GetAttribute(MOUNT_SCALE_ATTRIBUTE)
    local character = player.Character
    if type(creatureID) ~= "string"
        or type(scale) ~= "number"
        or scale <= 0
        or player:GetAttribute(MOUNT_FROSTED_ATTRIBUTE) == true
        or not character
    then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 10)
    if rebuildRevisionByPlayer[player] ~= revision
        or player.Character ~= character
        or not rootPart
        or not rootPart:IsA("BasePart")
    then
        return
    end

    local creature = CreatureConfig[creatureID]
    local source = creature and creatureVisuals:FindFirstChild(creature.ModelName)
    if not source or not source:IsA("Model") then
        return
    end

    local templateAnchor = source:GetAttribute(RIDER_ANCHOR_ATTRIBUTE)
    local model = source:Clone()
    makeFollowerSafe(model)
    model:ScaleTo(model:GetScale() * scale)
    model.Name = FOLLOWER_NAME
    model:SetAttribute("CreatureID", creatureID)
    model:SetAttribute("SizeScale", scale)

    -- Only the local player sees their own copy's stat card.
    local stats = localStats
    if player == localPlayer and stats and stats.Scale == scale then
        CreatureStatPresentation.Attach(model, stats)
    end

    local presentation: Presentation = {
        Model = model,
        Character = character,
        RootPart = rootPart,
        RiderAnchor = (if typeof(templateAnchor) == "Vector3" then templateAnchor else Vector3.zero) * scale,
    }
    model:PivotTo(getTargetCFrame(player, presentation))
    model.Parent = Workspace
    presentationsByPlayer[player] = presentation
end

local function updatePresentations(deltaTime: number): ()
    local interpolationAlpha = 1 - math.exp(-FOLLOW_SMOOTHING_RATE * deltaTime)

    for player, presentation in presentationsByPlayer do
        if player.Character ~= presentation.Character or not presentation.RootPart:IsDescendantOf(presentation.Character) then
            continue
        end

        local targetCFrame = getTargetCFrame(player, presentation)
        local currentCFrame = presentation.Model:GetPivot()

        -- A mount stays locked under its rider; a follower trails smoothly and snaps when far behind.
        if player:GetAttribute(MOUNT_STATE_ATTRIBUTE) == RIDING_STATE
            or (currentCFrame.Position - targetCFrame.Position).Magnitude > SNAP_DISTANCE
        then
            presentation.Model:PivotTo(targetCFrame)
        else
            presentation.Model:PivotTo(currentCFrame:Lerp(targetCFrame, interpolationAlpha))
        end
    end
end

local function watchPlayer(player: Player): ()
    for _, attributeName in { MOUNT_CREATURE_ID_ATTRIBUTE, MOUNT_SCALE_ATTRIBUTE, MOUNT_FROSTED_ATTRIBUTE } do
        player:GetAttributeChangedSignal(attributeName):Connect(function()
            rebuildPresentation(player)
        end)
    end

    player.CharacterAdded:Connect(function()
        rebuildPresentation(player)
    end)

    player.CharacterRemoving:Connect(function(character)
        local presentation = presentationsByPlayer[player]
        if presentation and presentation.Character == character then
            destroyPresentation(player)
        end
    end)

    task.spawn(rebuildPresentation, player)
end

function CreatureVisualController.Start(): ()
    if started then
        return
    end
    started = true

    -- The server's private equip update carries the local copy's display stats.
    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName ~= "EquippedCreatureChanged" or type(data) ~= "table" then
            return
        end

        local stats = {
            Scale = data.Scale,
            FinalIncome = data.FinalIncome,
            FinalWalkSpeed = data.FinalWalkSpeed,
        }
        local nextStats = if CreatureStatPresentation.IsValidDisplayStats(stats) then stats else nil
        local previousStats = localStats
        local statsChanged = (nextStats == nil) ~= (previousStats == nil)
            or (nextStats ~= nil and previousStats ~= nil and (
                nextStats.Scale ~= previousStats.Scale
                or nextStats.FinalIncome ~= previousStats.FinalIncome
                or nextStats.FinalWalkSpeed ~= previousStats.FinalWalkSpeed
            ))
        localStats = nextStats

        -- Vitality and mount-state updates reuse this event; only new copy stats need a new card.
        if statsChanged then
            rebuildPresentation(localPlayer)
        end
    end)

    for _, player in Players:GetPlayers() do
        watchPlayer(player)
    end
    Players.PlayerAdded:Connect(watchPlayer)
    Players.PlayerRemoving:Connect(function(player)
        destroyPresentation(player)
        rebuildRevisionByPlayer[player] = nil
    end)

    RunService.Heartbeat:Connect(updatePresentations)
end

return CreatureVisualController
