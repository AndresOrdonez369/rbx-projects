local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local OnboardingConfig = require(shared:WaitForChild("OnboardingConfig"))
local OwnBaseController = require(script.Parent.OwnBaseController)

local OnboardingController = {}

local HUD_NAME = "OnboardingHud"
local MARKER_NAME = "OnboardingIceMarker"
local HOME_MARKER_NAME = "OnboardingHomeMarker"
local HIGHLIGHT_NAME = "OnboardingIceHighlight"
local PULSE_NAME = "OnboardingPulse"
local ACTIVE_ICE_FOLDER_NAME = "ActiveIce"
local GRAB_PROMPT_NAME = "GrabPrompt"
local INVENTORY_HUD_NAME = "CreatureInventoryHud"
local INVENTORY_BUTTON_NAME = "CreaturesButton"
local MOUNT_STATE_ATTRIBUTE = "MountState"
local RIDING_STATE = "Riding"
local FOLLOWING_STATE = "Following"
local GREAT_FROST_PHASE = "GreatFrost"
local REFRESH_INTERVAL = 0.25
local MARKER_HEIGHT_ABOVE_ICE = 2.5
local HOME_MARKER_HEIGHT = 9
local RIDE_CLOSURE_SECONDS = 1

-- Onboarding accent: fresh mint, deliberately unlike rarity gold or the Frost cyan.
local GUIDE_COLOR = Color3.fromRGB(126, 232, 190)
local CARD_BACKING_COLOR = Color3.fromRGB(14, 22, 30)
local CARD_WIDTH = 280
local CARD_HEIGHT = 40
local CARD_TOP_OFFSET = 80 -- sits below the Great Frost countdown card (top 24, height 46)

local FIND_TEXT = "FIND AN ICE"
local HOME_TEXT = "BRING IT HOME"
local EQUIP_TEXT = "EQUIP YOUR CREATURE"
local RIDE_TEXT_DESKTOP = "PRESS R TO RIDE"
local RIDE_TEXT_TOUCH = "TAP RIDE"
local RIDE_DONE_TEXT = "RIDE!"
local GREAT_FROST_TEXT = "ICE UNLOCKS WHEN FROST ENDS"
local NO_ICE_TEXT = "ALL ICE CLAIMED · WAIT FOR FROST"

type Hud = {
    Card: Frame,
    CardScale: UIScale,
    CardLabel: TextLabel,
    Marker: BillboardGui,
    MarkerLabel: TextLabel,
    HomeMarker: BillboardGui,
    HomeLabel: TextLabel,
    Highlight: Highlight,
}

-- After the first Ice is deposited the server flips Active off, so Equip/Ride run from local session state.
type PostPhase = "Equip" | "Ride" | "Done" | "Retired"

local started = false
local isEligible = false
local sessionStarted = false
local currentPhase: string? = nil
local targetIce: BasePart? = nil
local postPhase: PostPhase? = nil
local penFloor: BasePart? = nil
local doneToken = 0
local pulseTween: Tween? = nil
local pulseStroke: UIStroke? = nil

local function createLabelCard(parent: Instance): (Frame, UIScale, TextLabel)
    local card = Instance.new("Frame")
    card.Name = "ObjectiveCard"
    card.AnchorPoint = Vector2.new(0.5, 0)
    card.Position = UDim2.new(0.5, 0, 0, CARD_TOP_OFFSET)
    card.Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
    card.BackgroundColor3 = CARD_BACKING_COLOR
    card.BackgroundTransparency = 0.12
    card.BorderSizePixel = 0
    card.Visible = false
    card.Parent = parent

    local scale = Instance.new("UIScale")
    scale.Parent = card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = GUIDE_COLOR
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = card

    local label = Instance.new("TextLabel")
    label.Name = "Objective"
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(10, 0)
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Font = Enum.Font.GothamBlack
    label.Text = ""
    label.TextColor3 = Color3.fromRGB(240, 252, 247)
    label.TextScaled = true
    label.TextStrokeColor3 = Color3.fromRGB(5, 10, 16)
    label.TextStrokeTransparency = 0.5
    label.Parent = card

    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = 11
    constraint.MaxTextSize = 20
    constraint.Parent = label

    return card, scale, label
end

local function createMarker(name: string, parent: Instance): (BillboardGui, TextLabel)
    local marker = Instance.new("BillboardGui")
    marker.Name = name
    marker.AlwaysOnTop = true
    marker.LightInfluence = 0
    marker.ResetOnSpawn = false
    marker.Size = UDim2.fromOffset(170, 44)
    marker.Enabled = false
    marker.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = ""
    label.TextColor3 = GUIDE_COLOR
    label.TextSize = 16
    label.TextStrokeColor3 = Color3.fromRGB(5, 10, 16)
    label.TextStrokeTransparency = 0.3
    label.Parent = marker

    return marker, label
end

local function createHud(): Hud
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    for _, name in { HUD_NAME, MARKER_NAME, HOME_MARKER_NAME } do
        local existing = playerGui:FindFirstChild(name)
        if existing then
            existing:Destroy()
        end
    end

    local camera = Workspace.CurrentCamera
    local existingHighlight = camera:FindFirstChild(HIGHLIGHT_NAME)
    if existingHighlight then
        existingHighlight:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = HUD_NAME
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.Parent = playerGui

    local card, cardScale, cardLabel = createLabelCard(screenGui)

    -- Outline only, so the silhouette inside the Ice keeps its normal read.
    local highlight = Instance.new("Highlight")
    highlight.Name = HIGHLIGHT_NAME
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 1
    highlight.OutlineColor = GUIDE_COLOR
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Parent = camera

    local marker, markerLabel = createMarker(MARKER_NAME, playerGui)
    local homeMarker, homeLabel = createMarker(HOME_MARKER_NAME, playerGui)

    return {
        Card = card,
        CardScale = cardScale,
        CardLabel = cardLabel,
        Marker = marker,
        MarkerLabel = markerLabel,
        HomeMarker = homeMarker,
        HomeLabel = homeLabel,
        Highlight = highlight,
    }
end

local function isCarryingIce(character: Model): boolean
    for _, child in character:GetChildren() do
        if child:GetAttribute("IceInstanceID") ~= nil then
            return true
        end
    end

    return false
end

-- Available means still resting in the shared field with a usable Grab prompt.
local function isGuideCandidate(ice: Instance, activeIceFolder: Folder): boolean
    if ice.Parent ~= activeIceFolder or not ice:IsA("BasePart") then
        return false
    end

    if ice:GetAttribute("IceType") ~= OnboardingConfig.PreferredOnboardingIceType then
        return false
    end

    local prompt = ice:FindFirstChild(GRAB_PROMPT_NAME, true)
    return prompt ~= nil and prompt:IsA("ProximityPrompt") and prompt.Enabled
end

local function findNearestCandidate(activeIceFolder: Folder, origin: Vector3): BasePart?
    local nearestIce = nil
    local nearestDistance = math.huge

    for _, ice in activeIceFolder:GetChildren() do
        if isGuideCandidate(ice, activeIceFolder) then
            local distance = (ice.Position - origin).Magnitude
            if distance < nearestDistance then
                nearestIce = ice
                nearestDistance = distance
            end
        end
    end

    return nearestIce
end

local function setTarget(hud: Hud, ice: BasePart?): ()
    if ice ~= targetIce then
        targetIce = ice
        hud.Highlight.Adornee = ice
        hud.Marker.Adornee = ice

        if ice then
            hud.Marker.StudsOffsetWorldSpace = Vector3.new(0, ice.Size.Y * 0.5 + MARKER_HEIGHT_ABOVE_ICE, 0)
        end
    end

    hud.Highlight.Enabled = ice ~= nil
    hud.Marker.Enabled = ice ~= nil
end

local function setHomeMarker(hud: Hud, visible: boolean, rootPart: BasePart?): ()
    local floor = penFloor
    if not visible or not floor or not floor.Parent or not rootPart then
        hud.HomeMarker.Enabled = false
        return
    end

    if hud.HomeMarker.Adornee ~= floor then
        hud.HomeMarker.Adornee = floor
        hud.HomeMarker.StudsOffsetWorldSpace = Vector3.new(0, floor.Size.Y * 0.5 + HOME_MARKER_HEIGHT, 0)
    end

    local distance = math.floor((floor.Position - rootPart.Position).Magnitude + 0.5)
    hud.HomeLabel.Text = string.format("HOME\n%d studs", distance)
    hud.HomeMarker.Enabled = true
end

local function setCard(hud: Hud, text: string?): ()
    if text then
        hud.CardLabel.Text = text
    end
    hud.Card.Visible = text ~= nil
end

-- Subtle local pulse on the existing CREATURES button (read-only: only adds/removes our own stroke).
local function setButtonPulse(active: boolean): ()
    if not active then
        if pulseTween then
            pulseTween:Cancel()
            pulseTween = nil
        end
        if pulseStroke then
            pulseStroke:Destroy()
            pulseStroke = nil
        end
        return
    end

    if pulseStroke and pulseStroke.Parent then
        return
    end

    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    local inventoryHud = if playerGui then playerGui:FindFirstChild(INVENTORY_HUD_NAME) else nil
    local button = if inventoryHud then inventoryHud:FindFirstChild(INVENTORY_BUTTON_NAME, true) else nil
    if not button or not button:IsA("GuiButton") then
        return -- not built yet; the next refresh retries
    end

    local stroke = Instance.new("UIStroke")
    stroke.Name = PULSE_NAME
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = GUIDE_COLOR
    stroke.Thickness = 3
    stroke.Transparency = 0
    stroke.Parent = button
    pulseStroke = stroke

    pulseTween = TweenService:Create(
        stroke,
        TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.8 }
    )
    pulseTween:Play()
end

local function getMountState(): string?
    local state = Players.LocalPlayer:GetAttribute(MOUNT_STATE_ATTRIBUTE)
    return if type(state) == "string" then state else nil
end

local function getRideText(): string
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return RIDE_TEXT_TOUCH
    end
    return RIDE_TEXT_DESKTOP
end

local function setPostPhase(phase: PostPhase?): ()
    postPhase = phase
    if phase ~= "Equip" then
        setButtonPulse(false)
    end
end

local function completeRide(): ()
    if postPhase ~= "Equip" and postPhase ~= "Ride" then
        return
    end

    setPostPhase("Done")
    doneToken += 1
    local token = doneToken
    task.delay(RIDE_CLOSURE_SECONDS, function()
        if token == doneToken and postPhase == "Done" then
            setPostPhase("Retired")
        end
    end)
end

local function refresh(hud: Hud, activeIceFolder: Folder): ()
    local character = Players.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local hasRoot = rootPart ~= nil and rootPart:IsA("BasePart")

    -- Post-deposit steps: Equip -> Ride -> RIDE! (session only; the existing prompts teach thaw/crack).
    if postPhase ~= nil then
        setTarget(hud, nil)
        setHomeMarker(hud, false, nil)

        if postPhase == "Equip" then
            setButtonPulse(true)
            setCard(hud, EQUIP_TEXT)
        elseif postPhase == "Ride" then
            setCard(hud, getRideText())
        elseif postPhase == "Done" then
            setCard(hud, RIDE_DONE_TEXT)
        else
            setCard(hud, nil)
        end
        return
    end

    if not isEligible or not character or not hasRoot then
        setTarget(hud, nil)
        setHomeMarker(hud, false, nil)
        setCard(hud, nil)
        return
    end

    local root = rootPart :: BasePart

    -- Carrying: point at the player's own Pen (resolved via OwnBaseController).
    if isCarryingIce(character) then
        setTarget(hud, nil)
        setHomeMarker(hud, true, root)
        setCard(hud, HOME_TEXT)
        return
    end
    setHomeMarker(hud, false, nil)

    -- Keep the current target while it stays available; retarget only when it is claimed or removed.
    local nextTarget = targetIce
    if not nextTarget or not isGuideCandidate(nextTarget, activeIceFolder) then
        nextTarget = findNearestCandidate(activeIceFolder, root.Position)
    end
    setTarget(hud, nextTarget)

    if nextTarget then
        local distance = math.floor((nextTarget.Position - root.Position).Magnitude + 0.5)
        hud.MarkerLabel.Text = string.format("SHARED ICE\n%d studs", distance)
        setCard(hud, FIND_TEXT)
    elseif currentPhase == GREAT_FROST_PHASE then
        setCard(hud, GREAT_FROST_TEXT)
    else
        setCard(hud, NO_ICE_TEXT)
    end
end

local function updateViewportScale(hud: Hud): ()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    -- Compact on portrait phones; never below 0.7 so the objective stays legible.
    hud.CardScale.Scale = math.clamp(camera.ViewportSize.X / 600, 0.7, 1)
end

function OnboardingController.Start(): ()
    if started then
        return
    end
    started = true

    local hud = createHud()
    local activeIceFolder = Workspace:WaitForChild(ACTIVE_ICE_FOLDER_NAME)
    assert(activeIceFolder:IsA("Folder"), string.format("Workspace.%s must be a Folder", ACTIVE_ICE_FOLDER_NAME))

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")
    assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

    updateViewportScale(hud)
    local camera = Workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            updateViewportScale(hud)
        end)
    end

    -- Own Pen from the existing own-base reference (never guessed from names).
    task.spawn(function()
        local ownBase = OwnBaseController.WaitForOwnBase()
        local pen = ownBase:WaitForChild("Pen")
        local floor = pen:WaitForChild("PenFloor")
        if floor:IsA("BasePart") then
            penFloor = floor
        end
    end)

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "OnboardingUpdated" then
            if type(data) == "table" and type(data.Active) == "boolean" then
                isEligible = data.Active
                if data.Active then
                    sessionStarted = true
                end
                refresh(hud, activeIceFolder)
            end
        elseif eventName == "WorldCycleUpdated" then
            if type(data) == "table" and type(data.CurrentPhase) == "string" then
                currentPhase = data.CurrentPhase
                refresh(hud, activeIceFolder)
            end
        elseif eventName == "CreatureRevealed" then
            -- First reveal of a session that began with onboarding: move on to Equip.
            if sessionStarted and postPhase == nil then
                local mountState = getMountState()
                if mountState == RIDING_STATE then
                    setPostPhase("Retired")
                elseif mountState == FOLLOWING_STATE then
                    setPostPhase("Ride")
                else
                    setPostPhase("Equip")
                end
                refresh(hud, activeIceFolder)
            end
        elseif eventName == "EquippedCreatureChanged" then
            if postPhase == "Equip" and type(data) == "table" and type(data.EquippedCreatureGUID) == "string" then
                setPostPhase("Ride")
                refresh(hud, activeIceFolder)
            end
        end
    end)

    Players.LocalPlayer:GetAttributeChangedSignal(MOUNT_STATE_ATTRIBUTE):Connect(function()
        local state = getMountState()
        if state == RIDING_STATE then
            completeRide()
        elseif state == FOLLOWING_STATE and postPhase == "Equip" then
            setPostPhase("Ride")
        end
        refresh(hud, activeIceFolder)
    end)

    Players.LocalPlayer.CharacterRemoving:Connect(function()
        setTarget(hud, nil)
        setHomeMarker(hud, false, nil)
    end)

    local elapsed = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        elapsed += deltaTime
        if elapsed < REFRESH_INTERVAL then
            return
        end
        elapsed = 0

        refresh(hud, activeIceFolder)
    end)
end

return OnboardingController
