local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureStatPresentation = require(shared:WaitForChild("CreatureStatPresentation"))
local CreatureSurvivalConfig = require(shared:WaitForChild("CreatureSurvivalConfig"))

local CreatureVisualController = {}

local FOLLOW_SMOOTHING_RATE = 8
local SNAP_DISTANCE = 30
local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local FOLLOWER_NAME = "EquippedFollower"

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")
local creatureVisuals = ReplicatedStorage:WaitForChild(CREATURE_VISUALS_FOLDER_NAME)

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")
assert(creatureVisuals:IsA("Folder"), "ReplicatedStorage.CreatureVisuals must be a Folder")

local started = false
local equippedCreatureID: string? = nil
local equippedCreatureGUID: string? = nil
local equippedStats: CreatureStatPresentation.DisplayStats? = nil
local creatureFrosted = false
local follower: Model? = nil
local activeCharacter: Model? = nil
local activeRootPart: BasePart? = nil
local rebuildRevision = 0

local function destroyFollower(): ()
    if follower then
        follower:Destroy()
        follower = nil
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

local function getTargetCFrame(rootPart: BasePart, model: Model): CFrame
    local behindPosition = rootPart.CFrame:PointToWorldSpace(
        Vector3.new(0, 0, CreatureSurvivalConfig.LogicalTargetFollowDistance)
    )
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { activeCharacter :: Model, model }

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

local function rebuildFollower(character: Model?): ()
    rebuildRevision += 1
    local revision = rebuildRevision

    destroyFollower()
    activeCharacter = character
    activeRootPart = nil

    local creatureID = equippedCreatureID
    local creatureGUID = equippedCreatureGUID
    local stats = equippedStats
    if not character
        or type(creatureID) ~= "string"
        or type(creatureGUID) ~= "string"
        or not stats
        or creatureFrosted
    then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 10)
    if revision ~= rebuildRevision
        or localPlayer.Character ~= character
        or not rootPart
        or not rootPart:IsA("BasePart")
    then
        return
    end

    local creature = CreatureConfig[creatureID]
    if not creature or type(creature.ModelName) ~= "string" then
        return
    end

    local source = creatureVisuals:FindFirstChild(creature.ModelName)
    if not source or not source:IsA("Model") then
        return
    end

    local model = source:Clone()
    makeFollowerSafe(model)
    local authoredTemplateScale = model:GetScale()
    model:ScaleTo(authoredTemplateScale * stats.Scale)
    model.Name = FOLLOWER_NAME
    model:SetAttribute("CreatureID", creatureID)
    model:SetAttribute("CreatureGUID", creatureGUID)
    model:SetAttribute("SizeScale", stats.Scale)
    CreatureStatPresentation.Attach(model, stats)

    activeCharacter = character
    activeRootPart = rootPart
    model:PivotTo(getTargetCFrame(rootPart, model))
    model.Parent = Workspace
    follower = model
end

local function updateFollower(deltaTime: number): ()
    local model = follower
    local character = activeCharacter
    local rootPart = activeRootPart
    if not model or not character or not rootPart
        or localPlayer.Character ~= character
        or not rootPart:IsDescendantOf(character)
    then
        return
    end

    local targetCFrame = getTargetCFrame(rootPart, model)
    local currentCFrame = model:GetPivot()

    if (currentCFrame.Position - targetCFrame.Position).Magnitude > SNAP_DISTANCE then
        model:PivotTo(targetCFrame)
        return
    end

    local interpolationAlpha = 1 - math.exp(-FOLLOW_SMOOTHING_RATE * deltaTime)
    model:PivotTo(currentCFrame:Lerp(targetCFrame, interpolationAlpha))
end

function CreatureVisualController.Start(): ()
    if started then
        return
    end
    started = true

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName ~= "EquippedCreatureChanged" then
            return
        end

        if type(data) ~= "table" then
            return
        end

        local creatureID = data.EquippedCreature
        if creatureID ~= nil and type(creatureID) ~= "string" then
            return
        end
        local creatureGUID = data.EquippedCreatureGUID
        local stats = {
            Scale = data.Scale,
            FinalIncome = data.FinalIncome,
            FinalWalkSpeed = data.FinalWalkSpeed,
        }
        if creatureID == nil then
            if creatureGUID ~= nil
                or data.Scale ~= nil
                or data.FinalIncome ~= nil
                or data.FinalWalkSpeed ~= nil
            then
                return
            end
        elseif type(creatureGUID) ~= "string"
            or not CreatureStatPresentation.IsValidDisplayStats(stats)
        then
            return
        end
        if type(data.CreatureFrosted) ~= "boolean" then
            return
        end

        equippedCreatureID = creatureID
        equippedCreatureGUID = creatureGUID
        equippedStats = if creatureID then stats else nil
        creatureFrosted = data.CreatureFrosted
        rebuildFollower(localPlayer.Character)
    end)

    localPlayer.CharacterAdded:Connect(function(character)
        rebuildFollower(character)
    end)

    localPlayer.CharacterRemoving:Connect(function(character)
        if character == activeCharacter then
            rebuildFollower(nil)
        end
    end)

    RunService.Heartbeat:Connect(updateFollower)
end

return CreatureVisualController
