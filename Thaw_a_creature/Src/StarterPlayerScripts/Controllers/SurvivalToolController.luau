local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SurvivalToolController = {}

local TOOL_NAME = "SurvivalTool"
local TOOL_ATTRIBUTE = "IsSurvivalTool"
local SWING_OUT_TIME = 0.09
local SWING_RETURN_TIME = 0.14
local FORWARD_SWING_ANGLE = math.rad(75)

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")

local started = false
local connectedTools: { [Tool]: boolean } = setmetatable({}, { __mode = "k" })
local presentingSwingByTool: { [Tool]: boolean } = setmetatable({}, { __mode = "k" })

local function isSurvivalTool(instance: Instance): boolean
    return instance:IsA("Tool")
        and instance.Name == TOOL_NAME
        and instance:GetAttribute(TOOL_ATTRIBUTE) == true
end

local function presentSwing(tool: Tool): ()
    if presentingSwingByTool[tool] then
        return
    end
    presentingSwingByTool[tool] = true

    local readyGrip = tool.Grip
    local forwardGrip = readyGrip * CFrame.Angles(FORWARD_SWING_ANGLE, 0, 0)
    local swingOut = TweenService:Create(
        tool,
        TweenInfo.new(SWING_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Grip = forwardGrip }
    )
    local swingReturn = TweenService:Create(
        tool,
        TweenInfo.new(SWING_RETURN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Grip = readyGrip }
    )

    swingOut:Play()
    swingOut.Completed:Wait()

    if tool.Parent then
        swingReturn:Play()
        swingReturn.Completed:Wait()
        if tool.Parent then
            tool.Grip = readyGrip
        end
    end

    presentingSwingByTool[tool] = nil
end

local function connectTool(instance: Instance): ()
    if not isSurvivalTool(instance) then
        return
    end

    local tool = instance :: Tool
    if connectedTools[tool] then
        return
    end
    connectedTools[tool] = true

    tool.Activated:Connect(function()
        task.spawn(presentSwing, tool)
        gameplayRequest:FireServer("SwingSurvivalTool")
    end)
end

local function connectCharacter(character: Model): ()
    for _, child in character:GetChildren() do
        connectTool(child)
    end

    character.ChildAdded:Connect(connectTool)
end

function SurvivalToolController.Start(): ()
    if started then
        return
    end
    started = true

    local backpack = localPlayer:WaitForChild("Backpack")
    for _, child in backpack:GetChildren() do
        connectTool(child)
    end
    backpack.ChildAdded:Connect(connectTool)

    localPlayer.CharacterAdded:Connect(connectCharacter)
    if localPlayer.Character then
        connectCharacter(localPlayer.Character)
    end
end

return SurvivalToolController
