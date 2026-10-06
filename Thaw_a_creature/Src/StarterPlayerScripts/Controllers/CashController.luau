local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashController = {}

local HUD_NAME = "CashHud"
local started = false

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

    local cashLabel = Instance.new("TextLabel")
    cashLabel.Name = "CashLabel"
    cashLabel.Position = UDim2.fromOffset(24, 174)
    cashLabel.Size = UDim2.fromOffset(180, 60)
    cashLabel.BackgroundColor3 = Color3.fromRGB(20, 25, 32)
    cashLabel.BackgroundTransparency = 0.2
    cashLabel.BorderSizePixel = 0
    cashLabel.Font = Enum.Font.GothamBold
    cashLabel.Text = "CASH\n$--"
    cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cashLabel.TextSize = 22
    cashLabel.TextStrokeTransparency = 0.75
    cashLabel.Parent = screenGui

    return cashLabel
end

local function updateHud(cashLabel: TextLabel, data: any): ()
    if type(data) ~= "table" then
        return
    end

    local cash = data.Cash
    if type(cash) ~= "number"
        or cash < 0
        or cash >= math.huge
        or cash % 1 ~= 0
    then
        return
    end

    cashLabel.Text = string.format("CASH\n$%d", cash)
end

function CashController.Start(): ()
    if started then
        return
    end
    started = true

    local cashLabel = createHud()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")

    assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "CashUpdated" then
            updateHud(cashLabel, data)
        end
    end)
end

return CashController
