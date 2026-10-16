local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local IceConfig = require(shared:WaitForChild("IceConfig"))

local OwnBaseController = require(script.Parent.OwnBaseController)

local ThawTimerController = {}

local THAW_VISUALS_FOLDER_NAME = "ThawVisuals"
local TIMER_GUI_NAME = "ThawTimerBillboard" -- template: ReplicatedStorage.UITemplates.ThawTimerBillboard
local THAW_ID_ATTRIBUTE = "ThawID"
local ICE_TYPE_ATTRIBUTE = "IceType"
local THAW_READY_AT_ATTRIBUTE = "ThawReadyAt"
local THAW_VISUAL_STAGE_ATTRIBUTE = "ThawVisualStage"
local READY_STAGE = "Ready"
local NEARLY_READY_STAGE = "NearlyReady"
local CRACK_PART_NAME = "ThawCrack"
local ICE_INSTANCE_ID_ATTRIBUTE = "IceInstanceID"
-- Carrier Commitment: Ice cannot be cracked while carrying Ice, so the Ready card says so instead of inviting a press.
local CARRYING_READY_TEXT = "PLACE YOUR ICE FIRST"
local DISPLAY_UPDATE_INTERVAL_SECONDS = 0.1
local TIMER_GUI_VERTICAL_PADDING = 1.5
local BAR_JUMP_TWEEN_THRESHOLD = 0.03
local BAR_JUMP_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local READY_PULSE_INFO = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- Thawing palette (cold, calm) and Ready palette (warm amber on bright neutral).
-- Ready deliberately avoids the Legendary gold: the creature rarity is still hidden.
local THAWING_STROKE_COLOR = Color3.fromRGB(127, 219, 255)
local EARLY_BAR_COLOR = Color3.fromRGB(110, 170, 255)
local MID_BAR_COLOR = Color3.fromRGB(90, 225, 255)
local NEARLY_READY_BAR_COLOR = Color3.fromRGB(255, 176, 96)
local READY_ACCENT_COLOR = Color3.fromRGB(255, 112, 40)

type TimerUi = {
    Billboard: BillboardGui,
    Stroke: UIStroke,
    Title: TextLabel,
    TimeLabel: TextLabel,
    ReadyFace: GuiObject,
    ReadyLabel: TextLabel,
    ReadyText: string,
    ThawIcon: GuiObject,
    ReadyIcon: GuiObject,
    BarBackground: Frame,
    Fill: Frame,
    Mode: string,
    FillRatio: number,
    FillTween: Tween?,
    PulseTween: Tween?,
}

local started = false
local updateElapsed = 0
local uiByVisual: { [BasePart]: TimerUi } = {}
local watchedVisuals: { [BasePart]: boolean } = {}
local timerTemplate: BillboardGui? = nil

local function formatDuration(seconds: number): string
    local wholeSeconds = math.max(1, math.ceil(seconds))
    local minutes = math.floor(wholeSeconds / 60)
    local remainingSeconds = wholeSeconds % 60

    return string.format("%d:%02d", minutes, remainingSeconds)
end

local function isLocalPlayerCarryingIce(): boolean
    local character = Players.LocalPlayer.Character
    if not character then
        return false
    end
    for _, child in character:GetChildren() do
        if child:IsA("BasePart") and child:GetAttribute(ICE_INSTANCE_ID_ATTRIBUTE) ~= nil then
            return true
        end
    end
    return false
end

local function createTimerUi(visualIce: BasePart): TimerUi?
    local template = timerTemplate
    if not template then
        return nil
    end

    local billboard = template:Clone()
    billboard.Name = TIMER_GUI_NAME
    billboard.Adornee = visualIce
    billboard.StudsOffsetWorldSpace = Vector3.new(
        0,
        visualIce.Size.Y * 0.5 + TIMER_GUI_VERTICAL_PADDING,
        0
    )
    billboard.Enabled = false

    local panel = billboard:WaitForChild("Panel")
    local barBackground = panel:WaitForChild("BarBackground") :: Frame
    local fill = barBackground:WaitForChild("Fill") :: Frame
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = EARLY_BAR_COLOR

    billboard.Parent = visualIce
    local readyLabel = panel:WaitForChild("ReadyLabel") :: TextLabel

    return {
        Billboard = billboard,
        Stroke = panel:WaitForChild("Stroke") :: UIStroke,
        Title = panel:WaitForChild("Title") :: TextLabel,
        TimeLabel = panel:WaitForChild("TimeLabel") :: TextLabel,
        ReadyFace = panel:WaitForChild("ReadyFace") :: GuiObject,
        ReadyLabel = readyLabel,
        ReadyText = readyLabel.Text,
        ThawIcon = panel:WaitForChild("ThawIcon") :: GuiObject,
        ReadyIcon = panel:WaitForChild("ReadyIcon") :: GuiObject,
        BarBackground = barBackground,
        Fill = fill,
        Mode = "Thawing",
        FillRatio = 0,
        FillTween = nil,
        PulseTween = nil,
    }
end

local function destroyTimerUi(ui: TimerUi)
    if ui.FillTween then
        ui.FillTween:Cancel()
        ui.FillTween = nil
    end
    if ui.PulseTween then
        ui.PulseTween:Cancel()
        ui.PulseTween = nil
    end
    if ui.Billboard.Parent then
        ui.Billboard:Destroy()
    end
end

local function setFillRatio(ui: TimerUi, ratio: number)
    ratio = math.clamp(ratio, 0, 1)
    local delta = math.abs(ratio - ui.FillRatio)
    ui.FillRatio = ratio

    -- Only one fill tween at a time; small continuous steps are applied directly.
    if ui.FillTween then
        ui.FillTween:Cancel()
        ui.FillTween = nil
    end

    local target = UDim2.fromScale(ratio, 1)
    if delta > BAR_JUMP_TWEEN_THRESHOLD then
        ui.FillTween = TweenService:Create(ui.Fill, BAR_JUMP_TWEEN_INFO, { Size = target })
        ui.FillTween:Play()
    else
        ui.Fill.Size = target
    end
end

local function applyMode(ui: TimerUi, mode: string)
    if ui.Mode == mode then
        return
    end
    ui.Mode = mode

    if ui.PulseTween then
        ui.PulseTween:Cancel()
        ui.PulseTween = nil
    end

    local ready = mode == READY_STAGE
    ui.ReadyFace.Visible = ready
    ui.ReadyLabel.Visible = ready
    ui.ReadyIcon.Visible = ready
    ui.ThawIcon.Visible = not ready
    ui.Title.Visible = not ready
    ui.TimeLabel.Visible = not ready

    if ready then
        ui.Stroke.Color = READY_ACCENT_COLOR
        ui.Stroke.Thickness = 3
        ui.Stroke.Transparency = 0.05
        ui.BarBackground.Visible = true
        ui.Fill.BackgroundColor3 = READY_ACCENT_COLOR
        setFillRatio(ui, 1)

        ui.PulseTween = TweenService:Create(ui.Stroke, READY_PULSE_INFO, { Transparency = 0.6 })
        ui.PulseTween:Play()
    else
        ui.Stroke.Color = THAWING_STROKE_COLOR
        ui.Stroke.Thickness = 2
        ui.Stroke.Transparency = 0.45
    end
end

-- Reveal has begun when the server shows the first crack lines on this Ice.
local function isRevealInProgress(visualIce: BasePart): boolean
    for _, child in visualIce:GetChildren() do
        if child.Name == CRACK_PART_NAME and child:IsA("BasePart") and child.Transparency < 1 then
            return true
        end
    end

    return false
end

local function getBaseThawDuration(visualIce: BasePart): number?
    local iceType = visualIce:GetAttribute(ICE_TYPE_ATTRIBUTE)
    if type(iceType) ~= "string" then
        return nil
    end

    local iceTypeConfig = IceConfig[iceType]
    local duration = if type(iceTypeConfig) == "table" then iceTypeConfig.BaseThawDuration else nil
    if type(duration) == "number" and duration > 0 then
        return duration
    end

    return nil
end

local function updateTimer(visualIce: BasePart, ui: TimerUi)
    local billboard = ui.Billboard
    if not billboard.Parent then
        uiByVisual[visualIce] = nil
        return
    end

    if isRevealInProgress(visualIce) then
        billboard.Enabled = false
        return
    end

    if visualIce:GetAttribute(THAW_VISUAL_STAGE_ATTRIBUTE) == READY_STAGE then
        applyMode(ui, READY_STAGE)
        ui.ReadyLabel.Text = if isLocalPlayerCarryingIce() then CARRYING_READY_TEXT else ui.ReadyText
        billboard.Enabled = true
        return
    end

    local readyAt = visualIce:GetAttribute(THAW_READY_AT_ATTRIBUTE)
    if type(readyAt) ~= "number" then
        billboard.Enabled = false
        return
    end

    applyMode(ui, "Thawing")

    local remaining = readyAt - Workspace:GetServerTimeNow()
    ui.TimeLabel.Text = formatDuration(remaining)

    local duration = getBaseThawDuration(visualIce)
    ui.BarBackground.Visible = duration ~= nil
    if duration then
        local ratio = math.clamp(1 - remaining / duration, 0, 1)
        setFillRatio(ui, ratio)

        if visualIce:GetAttribute(THAW_VISUAL_STAGE_ATTRIBUTE) == NEARLY_READY_STAGE then
            ui.Fill.BackgroundColor3 = NEARLY_READY_BAR_COLOR
        elseif ratio >= 0.35 then
            ui.Fill.BackgroundColor3 = MID_BAR_COLOR
        else
            ui.Fill.BackgroundColor3 = EARLY_BAR_COLOR
        end
    end

    billboard.Enabled = true
end

local function attachTimer(visualIce: BasePart)
    if uiByVisual[visualIce] then
        return
    end

    local thawID = visualIce:GetAttribute(THAW_ID_ATTRIBUTE)
    if type(thawID) ~= "string" or thawID == "" then
        return
    end

    local existingBillboard = visualIce:FindFirstChild(TIMER_GUI_NAME)
    if existingBillboard then
        existingBillboard:Destroy()
    end

    local ui = createTimerUi(visualIce)
    if not ui then
        return
    end
    uiByVisual[visualIce] = ui
    updateTimer(visualIce, ui)
end

local function watchPossibleVisual(descendant: Instance, thawVisuals: Folder)
    if not descendant:IsA("BasePart") or not descendant:IsDescendantOf(thawVisuals) then
        return
    end

    local parent = descendant.Parent
    if not parent or not parent:IsA("Folder") then
        return
    end

    if watchedVisuals[descendant] then
        attachTimer(descendant)
        return
    end

    watchedVisuals[descendant] = true
    descendant:GetAttributeChangedSignal(THAW_ID_ATTRIBUTE):Connect(function()
        attachTimer(descendant)
    end)
    attachTimer(descendant)
end

local function updateTimers()
    for visualIce, ui in uiByVisual do
        if not visualIce:IsDescendantOf(Workspace) or not ui.Billboard:IsDescendantOf(visualIce) then
            destroyTimerUi(ui)
            uiByVisual[visualIce] = nil
            watchedVisuals[visualIce] = nil
        else
            updateTimer(visualIce, ui)
        end
    end
end

function ThawTimerController.Start(): ()
    if started then
        return
    end
    started = true
    timerTemplate = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild(TIMER_GUI_NAME) :: BillboardGui

    task.spawn(function()
        local thawVisuals = OwnBaseController.WaitForOwnBase():WaitForChild(THAW_VISUALS_FOLDER_NAME)
        assert(thawVisuals:IsA("Folder"), string.format("%s must be a Folder", thawVisuals:GetFullName()))

        for _, descendant in thawVisuals:GetDescendants() do
            watchPossibleVisual(descendant, thawVisuals)
        end

        thawVisuals.DescendantAdded:Connect(function(descendant)
            watchPossibleVisual(descendant, thawVisuals)
        end)
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        updateElapsed += deltaTime
        if updateElapsed < DISPLAY_UPDATE_INTERVAL_SECONDS then
            return
        end

        updateElapsed = 0
        updateTimers()
    end)
end

return ThawTimerController
