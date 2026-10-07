local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WarmthConfig = require(shared:WaitForChild("WarmthConfig"))

local WarmthController = {}

local HUD_NAME = "WarmthHud"
local SAFE_STATE = "Safe"
local LOW_STATE = "Low"
local CRITICAL_STATE = "Critical"
local NORMAL_BACKGROUND_COLOR = Color3.fromRGB(20, 25, 32)
local HIT_BACKGROUND_COLOR = Color3.fromRGB(150, 55, 65)
local LOW_BACKGROUND_COLOR = Color3.fromRGB(18, 52, 70)
local CRITICAL_BACKGROUND_COLOR = Color3.fromRGB(72, 28, 48)
local LOW_ACCENT_COLOR = Color3.fromRGB(135, 225, 255)
local CRITICAL_ACCENT_COLOR = Color3.fromRGB(225, 245, 255)
local FROST_EDGE_COLOR = Color3.fromRGB(145, 220, 255)
local LOW_EDGE_TRANSPARENCY = 0.72
local CRITICAL_EDGE_TRANSPARENCY = 0.42
local LOW_PULSE_INFO = TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local CRITICAL_PULSE_INFO = TweenInfo.new(0.48, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

type Hud = {
    Panel: Frame,
    PanelStroke: UIStroke,
    ValueLabel: TextLabel,
    StatusLabel: TextLabel,
    PulseOverlay: Frame,
    HitOverlay: Frame,
    FrostEdges: { Frame },
}

local started = false
local hitFlashRevision = 0
local presentationState = SAFE_STATE
local pulseTween: Tween? = nil

local function createFrostEdge(
    parent: Instance,
    name: string,
    position: UDim2,
    size: UDim2,
    rotation: number
): Frame
    local edge = Instance.new("Frame")
    edge.Name = name
    edge.Position = position
    edge.Size = size
    edge.BackgroundColor3 = FROST_EDGE_COLOR
    edge.BackgroundTransparency = 1
    edge.BorderSizePixel = 0
    edge.ZIndex = 1
    edge.Visible = false
    edge.Parent = parent

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = rotation
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.55, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    gradient.Parent = edge

    return edge
end

local function createHud(): Hud
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

    local frostEdges = {
        createFrostEdge(screenGui, "TopFrost", UDim2.fromScale(0, 0), UDim2.new(1, 0, 0.18, 0), 90),
        createFrostEdge(screenGui, "BottomFrost", UDim2.fromScale(0, 0.82), UDim2.new(1, 0, 0.18, 0), -90),
        createFrostEdge(screenGui, "LeftFrost", UDim2.fromScale(0, 0), UDim2.new(0.14, 0, 1, 0), 0),
        createFrostEdge(screenGui, "RightFrost", UDim2.fromScale(0.86, 0), UDim2.new(0.14, 0, 1, 0), 180),
    }

    local panel = Instance.new("Frame")
    panel.Name = "WarmthPanel"
    panel.Position = UDim2.fromOffset(24, 24)
    panel.Size = UDim2.fromOffset(260, 72)
    panel.BackgroundColor3 = NORMAL_BACKGROUND_COLOR
    panel.BackgroundTransparency = 0.2
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.ZIndex = 2
    panel.Parent = screenGui

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Name = "WarningStroke"
    panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    panelStroke.Enabled = false
    panelStroke.Thickness = 2
    panelStroke.Parent = panel

    local pulseOverlay = Instance.new("Frame")
    pulseOverlay.Name = "PulseOverlay"
    pulseOverlay.Size = UDim2.fromScale(1, 1)
    pulseOverlay.BackgroundTransparency = 1
    pulseOverlay.BorderSizePixel = 0
    pulseOverlay.Visible = false
    pulseOverlay.ZIndex = 2
    pulseOverlay.Parent = panel

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Position = UDim2.fromOffset(10, 4)
    titleLabel.Size = UDim2.new(1, -20, 0, 17)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "WARMTH"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.TextStrokeTransparency = 0.75
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 3
    titleLabel.Parent = panel

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Position = UDim2.fromOffset(10, 21)
    valueLabel.Size = UDim2.new(1, -20, 0, 28)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = "-- / --"
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextScaled = true
    valueLabel.TextStrokeTransparency = 0.75
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.ZIndex = 3
    valueLabel.Parent = panel

    local valueTextConstraint = Instance.new("UITextSizeConstraint")
    valueTextConstraint.MinTextSize = 12
    valueTextConstraint.MaxTextSize = 24
    valueTextConstraint.Parent = valueLabel

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Position = UDim2.fromOffset(10, 50)
    statusLabel.Size = UDim2.new(1, -20, 0, 16)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamBlack
    statusLabel.Text = ""
    statusLabel.TextSize = 14
    statusLabel.TextStrokeTransparency = 0.55
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Visible = false
    statusLabel.ZIndex = 3
    statusLabel.Parent = panel

    local hitOverlay = Instance.new("Frame")
    hitOverlay.Name = "HitOverlay"
    hitOverlay.Size = UDim2.fromScale(1, 1)
    hitOverlay.BackgroundColor3 = HIT_BACKGROUND_COLOR
    hitOverlay.BackgroundTransparency = 1
    hitOverlay.BorderSizePixel = 0
    hitOverlay.ZIndex = 2
    hitOverlay.Parent = panel

    return {
        Panel = panel,
        PanelStroke = panelStroke,
        ValueLabel = valueLabel,
        StatusLabel = statusLabel,
        PulseOverlay = pulseOverlay,
        HitOverlay = hitOverlay,
        FrostEdges = frostEdges,
    }
end

local function formatWholeNumber(value: number): string
    local wholeNumber = math.round(value)
    local sign = if wholeNumber < 0 then "-" else ""
    local digits = tostring(math.abs(wholeNumber))
    local reversedDigits = digits:reverse()
    local groupedReversedDigits = reversedDigits:gsub("(%d%d%d)", "%1,")
    local separatedDigits = groupedReversedDigits:reverse():gsub("^,", "")

    return sign .. separatedDigits
end

local function classifyWarmth(currentWarmth: number, maxWarmth: number): (string, number)
    local ratio = if maxWarmth > 0 then math.clamp(currentWarmth / maxWarmth, 0, 1) else 0

    if ratio <= WarmthConfig.CriticalThreshold then
        return CRITICAL_STATE, ratio
    elseif ratio <= WarmthConfig.LowThreshold then
        return LOW_STATE, ratio
    end

    return SAFE_STATE, ratio
end

local function setFrostEdges(frostEdges: { Frame }, visible: boolean, transparency: number): ()
    for _, edge in frostEdges do
        edge.BackgroundTransparency = transparency
        edge.Visible = visible
    end
end

local function stopPulse(hud: Hud): ()
    if pulseTween then
        pulseTween:Cancel()
        pulseTween = nil
    end

    hud.PulseOverlay.Visible = false
    hud.PulseOverlay.BackgroundTransparency = 1
end

local function startPulse(
    hud: Hud,
    color: Color3,
    startingTransparency: number,
    targetTransparency: number,
    tweenInfo: TweenInfo
): ()
    stopPulse(hud)
    hud.PulseOverlay.BackgroundColor3 = color
    hud.PulseOverlay.BackgroundTransparency = startingTransparency
    hud.PulseOverlay.Visible = true
    pulseTween = TweenService:Create(hud.PulseOverlay, tweenInfo, {
        BackgroundTransparency = targetTransparency,
    })
    pulseTween:Play()
end

local function applyPresentationState(hud: Hud, nextState: string, ratio: number): ()
    if nextState == presentationState then
        return
    end

    local previousState = presentationState
    presentationState = nextState

    -- TODO(D7-R12 cleanup): remove after Studio runtime verification.
    if RunService:IsStudio() then
        print(string.format("[D7-R12] %s -> %s ratio=%.3f", previousState, nextState, ratio))
    end

    if nextState == SAFE_STATE then
        stopPulse(hud)
        hud.Panel.BackgroundColor3 = NORMAL_BACKGROUND_COLOR
        hud.Panel.BackgroundTransparency = 0.2
        hud.PanelStroke.Enabled = false
        hud.StatusLabel.Text = ""
        hud.StatusLabel.Visible = false
        setFrostEdges(hud.FrostEdges, false, 1)
        return
    end

    hud.PanelStroke.Enabled = true
    hud.StatusLabel.Visible = true

    if nextState == LOW_STATE then
        hud.Panel.BackgroundColor3 = LOW_BACKGROUND_COLOR
        hud.Panel.BackgroundTransparency = 0.12
        hud.PanelStroke.Color = LOW_ACCENT_COLOR
        hud.PanelStroke.Transparency = 0.18
        hud.StatusLabel.Text = "LOW WARMTH"
        hud.StatusLabel.TextColor3 = LOW_ACCENT_COLOR
        setFrostEdges(hud.FrostEdges, true, LOW_EDGE_TRANSPARENCY)
        startPulse(hud, LOW_ACCENT_COLOR, 0.9, 0.72, LOW_PULSE_INFO)
        return
    end

    hud.Panel.BackgroundColor3 = CRITICAL_BACKGROUND_COLOR
    hud.Panel.BackgroundTransparency = 0.05
    hud.PanelStroke.Color = CRITICAL_ACCENT_COLOR
    hud.PanelStroke.Transparency = 0
    hud.StatusLabel.Text = "CRITICAL WARMTH"
    hud.StatusLabel.TextColor3 = CRITICAL_ACCENT_COLOR
    setFrostEdges(hud.FrostEdges, true, CRITICAL_EDGE_TRANSPARENCY)
    startPulse(hud, CRITICAL_ACCENT_COLOR, 0.8, 0.48, CRITICAL_PULSE_INFO)
end

local function flashEnemyHit(hitOverlay: Frame): ()
    hitFlashRevision += 1
    local revision = hitFlashRevision
    hitOverlay.BackgroundTransparency = 0.08

    task.delay(0.12, function()
        if revision ~= hitFlashRevision or not hitOverlay.Parent then
            return
        end

        TweenService:Create(
            hitOverlay,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundTransparency = 1,
            }
        ):Play()
    end)
end

local function updateHud(hud: Hud, data: any): ()
    if type(data) ~= "table" then
        return
    end

    local currentWarmth = data.CurrentWarmth
    local maxWarmth = data.MaxWarmth
    if type(currentWarmth) ~= "number"
        or type(maxWarmth) ~= "number"
        or currentWarmth ~= currentWarmth
        or maxWarmth ~= maxWarmth
        or math.abs(currentWarmth) == math.huge
        or math.abs(maxWarmth) == math.huge
    then
        return
    end

    hud.ValueLabel.Text = string.format(
        "%s / %s",
        formatWholeNumber(currentWarmth),
        formatWholeNumber(maxWarmth)
    )
    local nextState, ratio = classifyWarmth(currentWarmth, maxWarmth)
    applyPresentationState(hud, nextState, ratio)
end

function WarmthController.Start(): ()
    if started then
        return
    end
    started = true

    local hud = createHud()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")

    assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "WarmthUpdated" then
            updateHud(hud, data)
        elseif eventName == "SurvivalFeedback"
            and type(data) == "table"
            and data.Kind == "PlayerHit"
        then
            flashEnemyHit(hud.HitOverlay)
        end
    end)
end

return WarmthController
