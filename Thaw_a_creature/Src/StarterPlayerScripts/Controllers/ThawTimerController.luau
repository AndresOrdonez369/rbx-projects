local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local OwnBaseController = require(script.Parent.OwnBaseController)

local ThawTimerController = {}

local THAW_VISUALS_FOLDER_NAME = "ThawVisuals"
local TIMER_GUI_NAME = "ThawTimerBillboard"
local THAW_ID_ATTRIBUTE = "ThawID"
local THAW_READY_AT_ATTRIBUTE = "ThawReadyAt"
local THAW_VISUAL_STAGE_ATTRIBUTE = "ThawVisualStage"
local READY_STAGE = "Ready"
local DISPLAY_UPDATE_INTERVAL_SECONDS = 0.1
local TIMER_GUI_SIZE = UDim2.fromOffset(150, 64)
local TIMER_GUI_MAX_DISTANCE = 100
local TIMER_GUI_VERTICAL_PADDING = 1.5
local THAWING_TEXT_COLOR = Color3.fromRGB(235, 249, 255)
local READY_TEXT_COLOR = Color3.fromRGB(255, 240, 125)

local started = false
local updateElapsed = 0
local labelsByVisual: { [BasePart]: TextLabel } = {}
local watchedVisuals: { [BasePart]: boolean } = {}

local function formatDuration(seconds: number): string
    local wholeSeconds = math.max(1, math.ceil(seconds))
    local minutes = math.floor(wholeSeconds / 60)
    local remainingSeconds = wholeSeconds % 60

    return string.format("%d:%02d", minutes, remainingSeconds)
end

local function createTimerLabel(visualIce: BasePart): TextLabel
    local billboard = Instance.new("BillboardGui")
    billboard.Name = TIMER_GUI_NAME
    billboard.Adornee = visualIce
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = TIMER_GUI_MAX_DISTANCE
    billboard.Size = TIMER_GUI_SIZE
    billboard.StudsOffsetWorldSpace = Vector3.new(
        0,
        visualIce.Size.Y * 0.5 + TIMER_GUI_VERTICAL_PADDING,
        0
    )
    billboard.Enabled = false

    local label = Instance.new("TextLabel")
    label.Name = "TimerLabel"
    label.BackgroundColor3 = Color3.fromRGB(24, 39, 50)
    label.BackgroundTransparency = 0.2
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = THAWING_TEXT_COLOR
    label.TextScaled = true
    label.TextStrokeColor3 = Color3.fromRGB(8, 16, 22)
    label.TextStrokeTransparency = 0.2
    label.TextWrapped = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    billboard.Parent = visualIce

    return label
end

local function updateTimer(visualIce: BasePart, label: TextLabel)
    local billboard = label.Parent
    if not billboard or not billboard:IsA("BillboardGui") then
        labelsByVisual[visualIce] = nil
        return
    end

    if visualIce:GetAttribute(THAW_VISUAL_STAGE_ATTRIBUTE) == READY_STAGE then
        label.Text = "READY!"
        label.TextColor3 = READY_TEXT_COLOR
        billboard.Enabled = true
        return
    end

    local readyAt = visualIce:GetAttribute(THAW_READY_AT_ATTRIBUTE)
    if type(readyAt) ~= "number" then
        billboard.Enabled = false
        return
    end

    label.Text = "THAWING\n" .. formatDuration(readyAt - Workspace:GetServerTimeNow())
    label.TextColor3 = THAWING_TEXT_COLOR
    billboard.Enabled = true
end

local function attachTimer(visualIce: BasePart)
    if labelsByVisual[visualIce] then
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

    local label = createTimerLabel(visualIce)
    labelsByVisual[visualIce] = label
    updateTimer(visualIce, label)
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
    for visualIce, label in labelsByVisual do
        if not visualIce:IsDescendantOf(Workspace) or not label:IsDescendantOf(visualIce) then
            labelsByVisual[visualIce] = nil
            watchedVisuals[visualIce] = nil
        else
            updateTimer(visualIce, label)
        end
    end
end

function ThawTimerController.Start(): ()
    if started then
        return
    end
    started = true

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
