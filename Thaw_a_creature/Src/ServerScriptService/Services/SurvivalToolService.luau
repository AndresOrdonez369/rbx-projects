local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SurvivalToolConfig = require(shared:WaitForChild("SurvivalToolConfig"))

local PlayerStateService = require(script.Parent.PlayerStateService)

local SurvivalToolService = {}

local TOOL_NAME = "SurvivalTool"
local TOOL_ATTRIBUTE = "IsSurvivalTool"

type ApprovedTargetRecord = {
    OnHit: (Player, number) -> boolean,
}

local toolByPlayer: { [Player]: Tool } = {}
local lastSwingAtByPlayer: { [Player]: number } = {}
local approvedTargets: { [Instance]: ApprovedTargetRecord } = {}
local hasStarted = false

local function createTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = TOOL_NAME
    tool.ToolTip = "Universal survival tool"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool:SetAttribute(TOOL_ATTRIBUTE, true)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.45, 3.5, 0.45)
    handle.Color = Color3.fromRGB(120, 174, 186)
    handle.Material = Enum.Material.Metal
    handle.CanCollide = false
    handle.CanQuery = false
    handle.CanTouch = false
    handle.Massless = true
    handle.Parent = tool

    tool.Grip = CFrame.new(0, -1.1, 0)

    return tool
end

local function isSurvivalTool(instance: Instance): boolean
    return instance:IsA("Tool")
        and instance.Name == TOOL_NAME
        and instance:GetAttribute(TOOL_ATTRIBUTE) == true
end

local function ensureSingleTool(player: Player): ()
    local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 10)
    if not backpack or not backpack:IsA("Backpack") then
        return
    end

    local character = player.Character
    local retainedTool: Tool? = nil
    local trackedTool = toolByPlayer[player]

    local function inspectContainer(container: Instance?): ()
        if not container then
            return
        end

        for _, child in container:GetChildren() do
            if not isSurvivalTool(child) then
                continue
            end

            local tool = child :: Tool
            if retainedTool == nil and (trackedTool == nil or tool == trackedTool) then
                retainedTool = tool
            else
                tool:Destroy()
            end
        end
    end

    inspectContainer(backpack)
    inspectContainer(character)

    if retainedTool == nil then
        retainedTool = createTool()
        retainedTool.Parent = backpack
    end

    toolByPlayer[player] = retainedTool
end

local function resolveApprovedTarget(part: BasePart): Instance?
    local current: Instance? = part

    while current and current ~= Workspace do
        if approvedTargets[current] ~= nil then
            return current
        end
        current = current.Parent
    end

    return nil
end

local function getTargetPosition(target: Instance): Vector3?
    if target:IsA("BasePart") then
        return target.Position
    end

    if target:IsA("Model") then
        return target:GetPivot().Position
    end

    return nil
end

local function isTargetHittable(target: Instance): boolean
    return approvedTargets[target] ~= nil
        and target:IsDescendantOf(Workspace)
end

local function findNearestApprovedTarget(rootPart: BasePart, character: Model, tool: Tool): Instance?
    local hitboxDepth = SurvivalToolConfig.HitboxDepth
    local hitboxCFrame = rootPart.CFrame * CFrame.new(0, 0, -hitboxDepth * 0.5)
    local hitboxSize = Vector3.new(
        SurvivalToolConfig.HitboxWidth,
        SurvivalToolConfig.HitboxHeight,
        hitboxDepth
    )
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { character, tool }

    local nearestTarget: Instance? = nil
    local nearestDistance = math.huge
    local inspectedTargets: { [Instance]: boolean } = {}

    for _, part in Workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams) do
        local target = resolveApprovedTarget(part)
        if not target or inspectedTargets[target] then
            continue
        end
        inspectedTargets[target] = true

        local targetPosition = getTargetPosition(target)
        if not targetPosition or not isTargetHittable(target) then
            continue
        end

        local targetLocalPosition = rootPart.CFrame:PointToObjectSpace(targetPosition)
        if targetLocalPosition.Z >= 0 then
            continue
        end

        local distance = (rootPart.Position - targetPosition).Magnitude
        if distance <= SurvivalToolConfig.ToolServerHitRange and distance < nearestDistance then
            nearestTarget = target
            nearestDistance = distance
        end
    end

    return nearestTarget
end

function SurvivalToolService.TrySwing(player: Player): boolean
    if not PlayerStateService.GetState(player) then
        return false
    end

    local character = player.Character
    if not character or not character:IsDescendantOf(Workspace) then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return false
    end

    local tool = toolByPlayer[player]
    if not tool or tool.Parent ~= character or not isSurvivalTool(tool) then
        return false
    end

    local now = os.clock()
    local lastSwingAt = lastSwingAtByPlayer[player]
    if lastSwingAt and now - lastSwingAt < SurvivalToolConfig.ToolSwingCooldown then
        return false
    end
    lastSwingAtByPlayer[player] = now

    local target = findNearestApprovedTarget(rootPart, character, tool)
    if not target then
        return false
    end

    local targetPosition = getTargetPosition(target)
    if not targetPosition or not isTargetHittable(target) then
        return false
    end

    if (rootPart.Position - targetPosition).Magnitude > SurvivalToolConfig.ToolServerHitRange then
        return false
    end

    local targetRecord = approvedTargets[target]
    if not targetRecord then
        return false
    end

    local succeeded, hitApplied = pcall(
        targetRecord.OnHit,
        player,
        SurvivalToolConfig.ToolDamageToFrostSprite
    )
    if not succeeded then
        warn(string.format("[SurvivalToolService] Approved target hit failed: %s", tostring(hitApplied)))
        return false
    end

    return hitApplied == true
end

function SurvivalToolService.RegisterApprovedTarget(
    target: Instance,
    onHit: (Player, number) -> boolean
): ()
    assert(target ~= Workspace, "Workspace cannot be registered as a survival-tool target")
    assert(type(onHit) == "function", "Approved survival-tool targets require an OnHit callback")

    approvedTargets[target] = {
        OnHit = onHit,
    }
end

function SurvivalToolService.UnregisterApprovedTarget(target: Instance): ()
    approvedTargets[target] = nil
end

function SurvivalToolService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    local function connectPlayer(player: Player): ()
        player.CharacterAdded:Connect(function()
            task.defer(ensureSingleTool, player)
        end)

        task.defer(ensureSingleTool, player)
    end

    Players.PlayerAdded:Connect(connectPlayer)
    Players.PlayerRemoving:Connect(function(player)
        toolByPlayer[player] = nil
        lastSwingAtByPlayer[player] = nil
    end)

    for _, player in Players:GetPlayers() do
        connectPlayer(player)
    end

end

return SurvivalToolService
