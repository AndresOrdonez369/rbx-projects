local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Presentation only: every ProximityPrompt is switched to Custom style locally and shown with the PromptCard prefab.
-- Services keep owning HoldDuration, ActionText/ObjectText and Enabled; input still flows through the prompt itself.
local PromptController = {}

local CARD_TEMPLATE_NAME = "PromptCard" -- template: ReplicatedStorage.UITemplates.PromptCard
local POP_IN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_OUT_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local PRESS_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TRIGGER_PULSE_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_HIDDEN_SCALE = 0.6
local KEY_PRESSED_SCALE = 0.86
local TRIGGER_PULSE_SCALE = 1.1
-- Card size follows viewport height like the HUD, but never below the size that keeps the 60 px badge a 44 px touch target.
local PROMPT_REFERENCE_HEIGHT = 720
local MIN_PROMPT_SCALE = 0.75
local MAX_PROMPT_SCALE = 1

local started = false
local cardTemplate: BillboardGui
local playerGui: PlayerGui

local function useCustomStyle(descendant: Instance): ()
    if descendant:IsA("ProximityPrompt") then
        descendant.Style = Enum.ProximityPromptStyle.Custom
    end
end

local function getPromptScale(): number
    local camera = Workspace.CurrentCamera
    if not camera then
        return MAX_PROMPT_SCALE
    end
    return math.clamp(camera.ViewportSize.Y / PROMPT_REFERENCE_HEIGHT, MIN_PROMPT_SCALE, MAX_PROMPT_SCALE)
end

local function getKeyText(keyCode: Enum.KeyCode): string
    local text = UserInputService:GetStringForKeyCode(keyCode)
    if text == "" then
        text = keyCode.Name
    end
    return string.upper(text)
end

-- The Ring's two clipped half-discs are revealed clockwise from the top by rotating their gradient step.
local function setHoldProgress(ring: Frame, progress: number): ()
    local degrees = math.clamp(progress, 0, 1) * 360
    local right = ring:FindFirstChild("Right") :: Frame
    local left = ring:FindFirstChild("Left") :: Frame
    ((right:FindFirstChild("Disc") :: Frame):FindFirstChild("Sweep") :: UIGradient).Rotation = math.clamp(degrees, 0, 180) - 180
    ((left:FindFirstChild("Disc") :: Frame):FindFirstChild("Sweep") :: UIGradient).Rotation = math.clamp(degrees - 180, 0, 180)
end

local function showPrompt(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): ()
    if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
        return
    end

    local gui = cardTemplate:Clone()
    local card = gui:FindFirstChild("Card") :: Frame
    local pop = card:FindFirstChild("Pop") :: UIScale
    local badge = card:FindFirstChild("Badge") :: GuiButton
    local ring = badge:FindFirstChild("Ring") :: Frame
    local holdTag = badge:FindFirstChild("HoldTag") :: TextLabel
    local key = badge:FindFirstChild("Key") :: Frame
    local keyPress = key:FindFirstChild("Press") :: UIScale
    local keyLabel = key:FindFirstChild("KeyLabel") :: TextLabel
    local keyIcon = key:FindFirstChild("KeyIcon") :: ImageLabel
    local texts = card:FindFirstChild("Texts") :: Frame
    local objectText = texts:FindFirstChild("ObjectText") :: TextLabel
    local actionText = texts:FindFirstChild("ActionText") :: TextLabel

    local baseScale = getPromptScale()
    local connections: { RBXScriptConnection } = {}
    local holdStartedAt: number? = nil
    local pointerDown = false

    local function refreshTexts(): ()
        actionText.Text = prompt.ActionText
        objectText.Text = prompt.ObjectText
        objectText.Visible = prompt.ObjectText ~= ""
        holdTag.Visible = prompt.HoldDuration > 0
    end

    local function refreshKey(): ()
        if inputType == Enum.ProximityPromptInputType.Touch then
            -- Prefab KeyIcon already holds the tap glyph.
            keyLabel.Visible = false
            keyIcon.Visible = true
            return
        end

        if inputType == Enum.ProximityPromptInputType.Gamepad then
            local image = UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)
            if image ~= "" then
                keyIcon.Image = image
                keyIcon.ImageColor3 = Color3.new(1, 1, 1)
                keyLabel.Visible = false
                keyIcon.Visible = true
                return
            end
            keyLabel.Text = getKeyText(prompt.GamepadKeyCode)
        else
            keyLabel.Text = getKeyText(prompt.KeyboardKeyCode)
        end
        keyLabel.Visible = true
        keyIcon.Visible = false
    end

    local function press(): ()
        TweenService:Create(keyPress, PRESS_INFO, { Scale = KEY_PRESSED_SCALE }):Play()
    end

    local function release(): ()
        holdStartedAt = nil
        setHoldProgress(ring, 0)
        TweenService:Create(keyPress, RELEASE_INFO, { Scale = 1 }):Play()
    end

    refreshTexts()
    refreshKey()
    setHoldProgress(ring, 0)

    gui.Adornee = prompt.Parent
    gui.SizeOffset = Vector2.new(prompt.UIOffset.X / gui.Size.X.Offset, prompt.UIOffset.Y / gui.Size.Y.Offset)
    pop.Scale = baseScale * POP_HIDDEN_SCALE
    gui.Parent = playerGui
    TweenService:Create(pop, POP_IN_INFO, { Scale = baseScale }):Play()

    for _, property in { "ActionText", "ObjectText", "HoldDuration" } do
        table.insert(connections, prompt:GetPropertyChangedSignal(property):Connect(refreshTexts))
    end
    table.insert(connections, prompt:GetPropertyChangedSignal("KeyboardKeyCode"):Connect(refreshKey))
    table.insert(connections, prompt:GetPropertyChangedSignal("GamepadKeyCode"):Connect(refreshKey))

    table.insert(connections, prompt.PromptButtonHoldBegan:Connect(function()
        holdStartedAt = os.clock()
        press()
    end))
    table.insert(connections, prompt.PromptButtonHoldEnded:Connect(release))
    table.insert(connections, prompt.Triggered:Connect(function()
        holdStartedAt = nil
        setHoldProgress(ring, if prompt.HoldDuration > 0 then 1 else 0)
        press()
        pop.Scale = baseScale * TRIGGER_PULSE_SCALE
        TweenService:Create(pop, TRIGGER_PULSE_INFO, { Scale = baseScale }):Play()
    end))
    table.insert(connections, prompt.TriggerEnded:Connect(release))

    table.insert(connections, RunService.RenderStepped:Connect(function()
        local startedAt = holdStartedAt
        if startedAt then
            setHoldProgress(ring, (os.clock() - startedAt) / math.max(prompt.HoldDuration, 0.001))
        end
    end))

    -- Tap/click: the card and badge both accept it; the prompt itself still decides hold vs. instant trigger.
    local function onPointerBegan(input: InputObject): ()
        if pointerDown or not prompt.ClickablePrompt then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if input.UserInputState ~= Enum.UserInputState.Change then
                pointerDown = true
                prompt:InputHoldBegin()
            end
        end
    end

    local function onPointerEnded(input: InputObject): ()
        if not pointerDown then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pointerDown = false
            prompt:InputHoldEnd()
        end
    end

    for _, target in { card, badge } :: { GuiObject } do
        table.insert(connections, target.InputBegan:Connect(onPointerBegan))
        table.insert(connections, target.InputEnded:Connect(onPointerEnded))
    end

    local hiddenConnection: RBXScriptConnection
    hiddenConnection = prompt.PromptHidden:Connect(function()
        hiddenConnection:Disconnect()
        for _, connection in connections do
            connection:Disconnect()
        end
        if pointerDown then
            pointerDown = false
            prompt:InputHoldEnd()
        end

        TweenService:Create(pop, POP_OUT_INFO, { Scale = baseScale * POP_HIDDEN_SCALE }):Play()
        task.delay(POP_OUT_INFO.Time, function()
            gui:Destroy()
        end)
    end)
end

function PromptController.Start(): ()
    if started then
        return
    end
    started = true

    playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
    cardTemplate = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild(CARD_TEMPLATE_NAME) :: BillboardGui

    ProximityPromptService.PromptShown:Connect(showPrompt)

    for _, descendant in Workspace:GetDescendants() do
        useCustomStyle(descendant)
    end
    Workspace.DescendantAdded:Connect(useCustomStyle)
end

return PromptController
