local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CreatureVitalityController = {}

local HUD_NAME = "CreatureVitalityHud"
local HIT_FLASH_COLOR = Color3.fromRGB(210, 105, 80)
local NORMAL_BACKGROUND_COLOR = Color3.fromRGB(28, 36, 45)
local NORMAL_FILL_COLOR = Color3.fromRGB(105, 205, 225)
local FROSTED_FILL_COLOR = Color3.fromRGB(175, 225, 255)

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local started = false
local flashRevision = 0

type Hud = {
    ScreenGui: ScreenGui,
    Panel: Frame,
    Fill: Frame,
    ValueLabel: TextLabel,
    StateLabel: TextLabel,
}

local function createHud(): Hud
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local existingHud = playerGui:FindFirstChild(HUD_NAME)
    if existingHud then
        existingHud:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = HUD_NAME
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Position = UDim2.fromOffset(24, 104)
    panel.Size = UDim2.fromOffset(180, 62)
    panel.BackgroundColor3 = NORMAL_BACKGROUND_COLOR
    panel.BackgroundTransparency = 0.25
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.fromOffset(10, 5)
    title.Size = UDim2.new(1, -20, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "CREATURE"
    title.TextColor3 = Color3.fromRGB(215, 230, 238)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    local barBackground = Instance.new("Frame")
    barBackground.Name = "BarBackground"
    barBackground.Position = UDim2.fromOffset(10, 28)
    barBackground.Size = UDim2.new(1, -20, 0, 17)
    barBackground.BackgroundColor3 = Color3.fromRGB(11, 16, 22)
    barBackground.BorderSizePixel = 0
    barBackground.ClipsDescendants = true
    barBackground.Parent = panel

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = NORMAL_FILL_COLOR
    fill.BorderSizePixel = 0
    fill.Parent = barBackground

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.fromScale(1, 1)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = "-- / --"
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextSize = 13
    valueLabel.TextStrokeTransparency = 0.6
    valueLabel.ZIndex = 2
    valueLabel.Parent = barBackground

    local stateLabel = Instance.new("TextLabel")
    stateLabel.Name = "State"
    stateLabel.Position = UDim2.fromOffset(10, 45)
    stateLabel.Size = UDim2.new(1, -20, 0, 15)
    stateLabel.BackgroundTransparency = 1
    stateLabel.Font = Enum.Font.GothamBold
    stateLabel.Text = "FROSTED"
    stateLabel.TextColor3 = Color3.fromRGB(180, 235, 255)
    stateLabel.TextSize = 13
    stateLabel.TextXAlignment = Enum.TextXAlignment.Left
    stateLabel.Visible = false
    stateLabel.Parent = panel

    return {
        ScreenGui = screenGui,
        Panel = panel,
        Fill = fill,
        ValueLabel = valueLabel,
        StateLabel = stateLabel,
    }
end

local function updateHud(hud: Hud, data: any): ()
    if type(data) ~= "table" then
        return
    end

    local creatureID = data.EquippedCreature
    if creatureID == nil then
        hud.ScreenGui.Enabled = false
        return
    end
    if type(creatureID) ~= "string" then
        return
    end

    local vitality = data.CreatureVitality
    local vitalityMax = data.CreatureVitalityMax
    local frosted = data.CreatureFrosted
    if type(vitality) ~= "number" or type(vitalityMax) ~= "number" or vitalityMax <= 0
        or type(frosted) ~= "boolean"
    then
        return
    end

    hud.ScreenGui.Enabled = true
    hud.Fill.Size = UDim2.fromScale(math.clamp(vitality / vitalityMax, 0, 1), 1)
    hud.Fill.BackgroundColor3 = if frosted then FROSTED_FILL_COLOR else NORMAL_FILL_COLOR
    hud.ValueLabel.Text = string.format("%d / %d", math.round(vitality), math.round(vitalityMax))
    hud.StateLabel.Visible = frosted
end

local function flashCreatureHit(panel: Frame): ()
    flashRevision += 1
    local revision = flashRevision
    panel.BackgroundColor3 = HIT_FLASH_COLOR
    panel.BackgroundTransparency = 0.05

    task.delay(0.12, function()
        if revision ~= flashRevision or not panel.Parent then
            return
        end

        TweenService:Create(
            panel,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundColor3 = NORMAL_BACKGROUND_COLOR,
                BackgroundTransparency = 0.25,
            }
        ):Play()
    end)
end

function CreatureVitalityController.Start(): ()
    if started then
        return
    end
    started = true

    local hud = createHud()

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "EquippedCreatureChanged" then
            updateHud(hud, data)
        elseif eventName == "SurvivalFeedback"
            and type(data) == "table"
            and data.Kind == "CreatureHit"
            and hud.ScreenGui.Enabled
        then
            flashCreatureHit(hud.Panel)
        end
    end)
end

return CreatureVitalityController
