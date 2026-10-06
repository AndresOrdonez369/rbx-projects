local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WarmthController = {}

local HUD_NAME = "WarmthHud"
local NORMAL_BACKGROUND_COLOR = Color3.fromRGB(20, 25, 32)
local HIT_BACKGROUND_COLOR = Color3.fromRGB(150, 55, 65)

local started = false
local hitFlashRevision = 0

local function createHud(): TextLabel
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local existingHud = playerGui:FindFirstChild(HUD_NAME)
    if existingHud then
        existingHud:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = HUD_NAME
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.Parent = playerGui

    local warmthLabel = Instance.new("TextLabel")
    warmthLabel.Name = "WarmthLabel"
    warmthLabel.Position = UDim2.fromOffset(24, 24)
    warmthLabel.Size = UDim2.fromOffset(180, 72)
    warmthLabel.BackgroundColor3 = NORMAL_BACKGROUND_COLOR
    warmthLabel.BackgroundTransparency = 0.2
    warmthLabel.BorderSizePixel = 0
    warmthLabel.Font = Enum.Font.GothamBold
    warmthLabel.Text = "WARMTH\n-- / --"
    warmthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    warmthLabel.TextSize = 24
    warmthLabel.TextStrokeTransparency = 0.75
    warmthLabel.Parent = screenGui

    return warmthLabel
end

local function flashEnemyHit(warmthLabel: TextLabel): ()
    hitFlashRevision += 1
    local revision = hitFlashRevision
    warmthLabel.BackgroundColor3 = HIT_BACKGROUND_COLOR
    warmthLabel.BackgroundTransparency = 0
    warmthLabel.TextColor3 = Color3.fromRGB(190, 235, 255)

    task.delay(0.12, function()
        if revision ~= hitFlashRevision or not warmthLabel.Parent then
            return
        end

        TweenService:Create(
            warmthLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundColor3 = NORMAL_BACKGROUND_COLOR,
                BackgroundTransparency = 0.2,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            }
        ):Play()
    end)
end

local function updateHud(warmthLabel: TextLabel, data: any)
    if type(data) ~= "table" then
        return
    end

    local currentWarmth = data.CurrentWarmth
    local maxWarmth = data.MaxWarmth
    if type(currentWarmth) ~= "number" or type(maxWarmth) ~= "number" then
        return
    end

    warmthLabel.Text = string.format(
        "WARMTH\n%d / %d",
        math.round(currentWarmth),
        math.round(maxWarmth)
    )
end

function WarmthController.Start()
    if started then
        return
    end
    started = true

    local warmthLabel = createHud()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "WarmthUpdated" then
            updateHud(warmthLabel, data)
        elseif eventName == "SurvivalFeedback"
            and type(data) == "table"
            and data.Kind == "PlayerHit"
        then
            flashEnemyHit(warmthLabel)
        end
    end)
end

return WarmthController
