local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local WorldCycleController = {}

local HUD_NAME = "WorldCycleHud"
local FROST_COLOR_EFFECT_NAME = "PrototypeGreatFrostColor"
local DAY_PHASE = "Day"
local GREAT_FROST_PHASE = "GreatFrost"
local CARD_NAME = "CountdownCard"
local CARD_WIDTH = 170
local CARD_HEIGHT = 46
local CARD_TOP_OFFSET = 24
local CARD_BACKING_COLOR = Color3.fromRGB(14, 22, 32)
local CARD_STROKE_NORMAL = Color3.fromRGB(120, 176, 214)
local CARD_STROKE_ACTIVE = Color3.fromRGB(120, 235, 255)
local CARD_HEADER_NORMAL = Color3.fromRGB(150, 196, 226)
local CARD_HEADER_ACTIVE = Color3.fromRGB(170, 240, 255)
local CARD_TIMER_NORMAL = Color3.fromRGB(235, 249, 255)
local CARD_TIMER_ACTIVE = Color3.fromRGB(190, 245, 255)
local CARD_PULSE_INFO = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local VISUAL_TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BANNER_FADE_IN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BANNER_FADE_OUT_INFO = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BANNER_HOLD_DURATION = 1.4
local FROST_BANNER_TEXT = "GREAT FROST"
local SPECIAL_ICE_BANNER_TEXT = "A STRANGE ICE HAS AWAKENED"
-- Shown after the Great Frost banner has faded so the two announcements never overlap.
local SPECIAL_ICE_BANNER_DELAY = 4

local DAY_COLOR_PROPERTIES = {
    Brightness = 0,
    Contrast = 0,
    Saturation = 0,
    TintColor = Color3.fromRGB(255, 255, 255),
}

local FROST_COLOR_PROPERTIES = {
    Brightness = -0.08,
    Contrast = 0.22,
    Saturation = -0.3,
    TintColor = Color3.fromRGB(170, 220, 255),
}

-- ===== Great Frost hero-moment presentation (client-local; all Lighting values restored to captured baselines) =====
local FROST_SOUND_ID = "" -- PENDING ASSET: silent until an approved wind/frost sound is chosen
local FROST_SOUND_VOLUME = 0.6

local ANTICIPATION_SECONDS = 3
local ANTICIPATION_BLEND = 0.3
local ANTICIPATION_SNOW_RATE = 16
local IMPACT_BLEND_SECONDS = 1.0
local RELEASE_SECONDS = 1.4
local FROST_ENTER_GRADE_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FROST_RELEASE_GRADE_INFO = TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local FROST_ATMOSPHERE = {
    Density = 0.46,
    Haze = 1.2,
    Color = Color3.fromRGB(196, 218, 238),
    Decay = Color3.fromRGB(120, 150, 190),
}
local BLOOM_LIFT_INTENSITY = 0.7
local BLOOM_LIFT_THRESHOLD_DROP = 1.0
local BLOOM_THRESHOLD_FLOOR = 0.8

local SNOW_HOLD_RATE = 22
local SNOW_BURST_COUNT = 70
local SNOW_OFFSET = Vector3.new(-10, 26, -6)

local WAVE_SECONDS = 1.3
local WAVE_SIZE = 300
local WAVE_COLOR = Color3.fromRGB(150, 230, 255)

local ICE_REACTION_WINDOW = 1.5
local ICE_PUFF_COUNT = 8
local ICE_PUFF_CAP = 40

local AURORA_FADE_IN_SECONDS = 2
local AURORA_BEAMS = {
    { Z = 380, Y = 210, X0 = -340, X1 = 300, Curve = 90, Width = 70, C0 = Color3.fromRGB(90, 255, 205), C1 = Color3.fromRGB(80, 190, 255) },
    { Z = 470, Y = 250, X0 = -260, X1 = 360, Curve = -110, Width = 85, C0 = Color3.fromRGB(80, 220, 255), C1 = Color3.fromRGB(110, 255, 190) },
    { Z = 560, Y = 225, X0 = -380, X1 = 240, Curve = 80, Width = 60, C0 = Color3.fromRGB(110, 255, 210), C1 = Color3.fromRGB(70, 170, 255) },
}

type Hud = {
    Scale: UIScale,
    Stroke: UIStroke,
    Header: TextLabel,
    Timer: TextLabel,
}

type WorldCycleSnapshot = {
    CurrentPhase: string,
    CycleIndex: number,
    NextTransitionUnix: number,
}

local started = false
local currentSnapshot: WorldCycleSnapshot? = nil
local lastDisplayedPhase: string? = nil
local lastDisplayedSeconds: number? = nil
local colorTween: Tween? = nil
local bannerSequence = 0
local pulseTween: Tween? = nil

local function createHud(): (Hud, TextLabel)
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

    -- Compact persistent card: header + timer. Active Great Frost brightens the accent and pulses gently.
    local card = Instance.new("Frame")
    card.Name = CARD_NAME
    card.AnchorPoint = Vector2.new(0.5, 0)
    card.Position = UDim2.new(0.5, 0, 0, CARD_TOP_OFFSET)
    card.Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
    card.BackgroundColor3 = CARD_BACKING_COLOR
    card.BackgroundTransparency = 0.12
    card.BorderSizePixel = 0
    card.Parent = screenGui

    local cardScale = Instance.new("UIScale")
    cardScale.Parent = card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = CARD_STROKE_NORMAL
    stroke.Thickness = 1.5
    stroke.Transparency = 0.35
    stroke.Parent = card

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Position = UDim2.fromOffset(0, 5)
    header.Size = UDim2.new(1, 0, 0, 14)
    header.Font = Enum.Font.GothamBold
    header.Text = "GREAT FROST"
    header.TextColor3 = CARD_HEADER_NORMAL
    header.TextSize = 12
    header.TextStrokeColor3 = Color3.fromRGB(5, 10, 16)
    header.TextStrokeTransparency = 0.6
    header.Parent = card

    local timer = Instance.new("TextLabel")
    timer.Name = "Timer"
    timer.BackgroundTransparency = 1
    timer.Position = UDim2.fromOffset(0, 19)
    timer.Size = UDim2.new(1, 0, 0, 24)
    timer.Font = Enum.Font.GothamBlack
    timer.RichText = true
    timer.Text = "--:--"
    timer.TextColor3 = CARD_TIMER_NORMAL
    timer.TextSize = 22
    timer.TextStrokeColor3 = Color3.fromRGB(5, 10, 16)
    timer.TextStrokeTransparency = 0.5
    timer.Parent = card

    local frostBanner = Instance.new("TextLabel")
    frostBanner.Name = "FrostBanner"
    frostBanner.AnchorPoint = Vector2.new(0.5, 0.5)
    frostBanner.Position = UDim2.fromScale(0.5, 0.32)
    frostBanner.Size = UDim2.fromOffset(440, 80)
    frostBanner.BackgroundColor3 = Color3.fromRGB(20, 48, 72)
    frostBanner.BackgroundTransparency = 1
    frostBanner.BorderSizePixel = 0
    frostBanner.Font = Enum.Font.GothamBlack
    frostBanner.Text = "GREAT FROST"
    frostBanner.TextColor3 = Color3.fromRGB(220, 248, 255)
    frostBanner.TextSize = 40
    frostBanner.TextStrokeColor3 = Color3.fromRGB(40, 92, 130)
    frostBanner.TextStrokeTransparency = 1
    frostBanner.TextTransparency = 1
    frostBanner.Visible = false
    frostBanner.Parent = screenGui

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 12)
    bannerCorner.Parent = frostBanner

    return { Scale = cardScale, Stroke = stroke, Header = header, Timer = timer }, frostBanner
end

local function createColorEffect(): ColorCorrectionEffect
    local existingEffect = Lighting:FindFirstChild(FROST_COLOR_EFFECT_NAME)
    if existingEffect then
        assert(
            existingEffect:IsA("ColorCorrectionEffect"),
            "Lighting.PrototypeGreatFrostColor must be a ColorCorrectionEffect"
        )
        return existingEffect
    end

    local colorEffect = Instance.new("ColorCorrectionEffect")
    colorEffect.Name = FROST_COLOR_EFFECT_NAME
    colorEffect.Brightness = DAY_COLOR_PROPERTIES.Brightness
    colorEffect.Contrast = DAY_COLOR_PROPERTIES.Contrast
    colorEffect.Saturation = DAY_COLOR_PROPERTIES.Saturation
    colorEffect.TintColor = DAY_COLOR_PROPERTIES.TintColor
    colorEffect.Parent = Lighting

    return colorEffect
end

local function setFrostVisual(colorEffect: ColorCorrectionEffect, isFrost: boolean): ()
    if colorTween then
        colorTween:Cancel()
    end

    colorTween = TweenService:Create(
        colorEffect,
        if isFrost then FROST_ENTER_GRADE_INFO else FROST_RELEASE_GRADE_INFO,
        if isFrost then FROST_COLOR_PROPERTIES else DAY_COLOR_PROPERTIES
    )
    colorTween:Play()
end

local function hideFrostBanner(frostBanner: TextLabel): ()
    bannerSequence += 1
    frostBanner.Visible = false
    frostBanner.BackgroundTransparency = 1
    frostBanner.TextTransparency = 1
    frostBanner.TextStrokeTransparency = 1
end

local function showFrostBanner(frostBanner: TextLabel, text: string): ()
    bannerSequence += 1
    local activeSequence = bannerSequence

    frostBanner.Text = text
    frostBanner.BackgroundTransparency = 1
    frostBanner.TextTransparency = 1
    frostBanner.TextStrokeTransparency = 1
    frostBanner.Visible = true

    local fadeIn = TweenService:Create(frostBanner, BANNER_FADE_IN_INFO, {
        BackgroundTransparency = 0.18,
        TextTransparency = 0,
        TextStrokeTransparency = 0.45,
    })
    fadeIn:Play()

    task.spawn(function()
        fadeIn.Completed:Wait()
        if activeSequence ~= bannerSequence then
            return
        end

        task.wait(BANNER_HOLD_DURATION)
        if activeSequence ~= bannerSequence then
            return
        end

        local fadeOut = TweenService:Create(frostBanner, BANNER_FADE_OUT_INFO, {
            BackgroundTransparency = 1,
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        })
        fadeOut:Play()
        fadeOut.Completed:Wait()

        if activeSequence == bannerSequence then
            frostBanner.Visible = false
        end
    end)
end

-- ---------- world-event FX state ----------
local atmosphere: Atmosphere? = nil
local bloom: BloomEffect? = nil
local atmosphereBaseline: { [string]: any }? = nil
local bloomBaseline: { [string]: any }? = nil
local baselineCaptured = false
local worldBlend = Instance.new("NumberValue") -- 0 = Day art, 1 = full Frost atmosphere
local bloomLift = Instance.new("NumberValue")
local auroraFade = Instance.new("NumberValue")
local valueTweens: { [Instance]: Tween } = {}
local fxGeneration = 0
local anticipating = false
local snowPart: Part? = nil
local snowEmitter: ParticleEmitter? = nil
local auroraBeams: { Beam } = {}
local auroraAttachments: { Attachment } = {}
local auroraSpecs: { any } = {}
local iceReactionGeneration = 0
local icePuffed: { [Instance]: boolean } = {}
local iceReactionConnection: RBXScriptConnection? = nil

local function tweenValue(value: NumberValue, goal: number, seconds: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
    local old = valueTweens[value]
    if old then
        old:Cancel()
    end
    local tween = TweenService:Create(
        value,
        TweenInfo.new(seconds, style or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.InOut),
        { Value = goal }
    )
    valueTweens[value] = tween
    tween:Play()
    return tween
end

local function captureBaseline(): ()
    if baselineCaptured then
        return
    end
    baselineCaptured = true
    if atmosphere then
        atmosphereBaseline = {
            Density = atmosphere.Density,
            Haze = atmosphere.Haze,
            Color = atmosphere.Color,
            Decay = atmosphere.Decay,
        }
    end
    if bloom then
        bloomBaseline = {
            Intensity = bloom.Intensity,
            Threshold = bloom.Threshold,
        }
    end
end

local function applyAtmosphere(): ()
    local base = atmosphereBaseline
    if not atmosphere or not base or not baselineCaptured then
        return
    end
    local alpha = worldBlend.Value
    atmosphere.Density = base.Density + (FROST_ATMOSPHERE.Density - base.Density) * alpha
    atmosphere.Haze = base.Haze + (FROST_ATMOSPHERE.Haze - base.Haze) * alpha
    atmosphere.Color = base.Color:Lerp(FROST_ATMOSPHERE.Color, alpha)
    atmosphere.Decay = base.Decay:Lerp(FROST_ATMOSPHERE.Decay, alpha)
end

local function applyBloom(): ()
    local base = bloomBaseline
    if not bloom or not base or not baselineCaptured then
        return
    end
    local lift = bloomLift.Value
    if lift <= 0.001 then
        bloom.Intensity = base.Intensity
        bloom.Threshold = base.Threshold
        return
    end
    bloom.Intensity = base.Intensity + BLOOM_LIFT_INTENSITY * lift
    bloom.Threshold = math.max(base.Threshold - BLOOM_LIFT_THRESHOLD_DROP * lift, math.min(BLOOM_THRESHOLD_FLOOR, base.Threshold))
end

local function applyAuroraFade(): ()
    local alpha = auroraFade.Value
    for _, beam in auroraBeams do
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 1 - 0.42 * alpha),
            NumberSequenceKeypoint.new(0.5, 1 - 0.55 * alpha),
            NumberSequenceKeypoint.new(0.8, 1 - 0.42 * alpha),
            NumberSequenceKeypoint.new(1, 1),
        })
        beam.Enabled = alpha > 0.01
    end
end

local function restoreBaseline(): ()
    worldBlend.Value = 0
    bloomLift.Value = 0
    applyAtmosphere()
    applyBloom()
    baselineCaptured = false
end

local function playFrostSound(): ()
    if FROST_SOUND_ID == "" then
        return
    end
    local sound = Instance.new("Sound")
    sound.Name = "GreatFrostImpact"
    sound.SoundId = FROST_SOUND_ID
    sound.Volume = FROST_SOUND_VOLUME
    sound.Parent = SoundService
    sound:Play()
    Debris:AddItem(sound, 8)
end

local function ensureSnow(): ParticleEmitter
    if snowPart and snowPart.Parent and snowEmitter then
        return snowEmitter
    end

    local part = Instance.new("Part")
    part.Name = "GreatFrostSnow"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Transparency = 1
    part.Size = Vector3.new(70, 1, 70)
    local camera = Workspace.CurrentCamera
    part.CFrame = CFrame.new((if camera then camera.CFrame.Position else Vector3.zero) + SNOW_OFFSET)
    part.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Snow"
    emitter.Rate = 0
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.SpreadAngle = Vector2.new(22, 22)
    emitter.Lifetime = NumberRange.new(3.5, 5)
    emitter.Speed = NumberRange.new(8, 14)
    emitter.Acceleration = Vector3.new(7, -2, 3)
    emitter.Drag = 0.2
    emitter.LightEmission = 0.5
    emitter.LightInfluence = 0.3
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-60, 60)
    emitter.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255), Color3.fromRGB(170, 215, 255))
    emitter.Size = NumberSequence.new(0.45)
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.12, 0.3),
        NumberSequenceKeypoint.new(0.8, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = part

    snowPart = part
    snowEmitter = emitter
    return emitter
end

local function setSnowRate(rate: number, seconds: number): ()
    local emitter = ensureSnow()
    if seconds <= 0 then
        emitter.Rate = rate
        return
    end
    TweenService:Create(emitter, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Rate = rate }):Play()
end

local function destroySnow(): ()
    if snowPart then
        snowPart:Destroy()
    end
    snowPart = nil
    snowEmitter = nil
end

local function startAurora(fadeSeconds: number): ()
    if #auroraBeams == 0 then
        for index, spec in AURORA_BEAMS do
            local a0 = Instance.new("Attachment")
            a0.Name = "GreatFrostAuroraA" .. index
            a0.Parent = Workspace.Terrain
            local a1 = Instance.new("Attachment")
            a1.Name = "GreatFrostAuroraB" .. index
            a1.Parent = Workspace.Terrain

            local beam = Instance.new("Beam")
            beam.Name = "GreatFrostAurora" .. index
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.Segments = 24
            beam.CurveSize0 = spec.Curve
            beam.CurveSize1 = -spec.Curve * 0.6
            beam.Width0 = spec.Width
            beam.Width1 = spec.Width * 0.7
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Color = ColorSequence.new(spec.C0, spec.C1)
            beam.Enabled = false
            beam.Parent = Workspace.Terrain

            table.insert(auroraBeams, beam)
            table.insert(auroraAttachments, a0)
            table.insert(auroraAttachments, a1)
            table.insert(auroraSpecs, spec)
        end
        applyAuroraFade()
    end
    tweenValue(auroraFade, 1, fadeSeconds)
end

local function destroyAurora(): ()
    for _, beam in auroraBeams do
        beam:Destroy()
    end
    for _, attachment in auroraAttachments do
        attachment:Destroy()
    end
    table.clear(auroraBeams)
    table.clear(auroraAttachments)
    table.clear(auroraSpecs)
    auroraFade.Value = 0
end

local function spawnFrostWave(): ()
    local character = Players.LocalPlayer.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    if not root or not root:IsA("BasePart") then
        return
    end

    local wave = Instance.new("Part")
    wave.Name = "GreatFrostWave"
    wave.Anchored = true
    wave.CanCollide = false
    wave.CanQuery = false
    wave.CanTouch = false
    wave.CastShadow = false
    wave.Transparency = 1
    wave.Size = Vector3.new(4, 0.2, 4)
    wave.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.6, 0))
    wave.Parent = Workspace

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Top
    gui.LightInfluence = 0
    gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    gui.CanvasSize = Vector2.new(512, 512)
    gui.Parent = wave

    local ring = Instance.new("Frame")
    ring.Size = UDim2.fromScale(1, 1)
    ring.BackgroundTransparency = 1
    ring.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = ring

    local stroke = Instance.new("UIStroke")
    stroke.Color = WAVE_COLOR
    stroke.Thickness = 18
    stroke.Transparency = 0.2
    stroke.Parent = ring

    TweenService:Create(
        wave,
        TweenInfo.new(WAVE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(WAVE_SIZE, 0.2, WAVE_SIZE) }
    ):Play()
    TweenService:Create(
        stroke,
        TweenInfo.new(WAVE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Transparency = 1 }
    ):Play()
    Debris:AddItem(wave, WAVE_SECONDS + 0.2)
end

-- One local puff per Ice per transition; the emitter is temporary and the Ice itself is never touched.
local function puffIce(ice: Instance): ()
    local target: BasePart? = nil
    if ice:IsA("BasePart") then
        target = ice
    elseif ice:IsA("Model") then
        target = ice.PrimaryPart or ice:FindFirstChildWhichIsA("BasePart", true)
    end
    if not target or icePuffed[ice] then
        return
    end
    icePuffed[ice] = true

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "GreatFrostPuff"
    emitter.Rate = 0
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Lifetime = NumberRange.new(0.7, 1)
    emitter.Speed = NumberRange.new(5, 11)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Drag = 3
    emitter.LightEmission = 0.7
    emitter.LightInfluence = 0
    emitter.Color = ColorSequence.new(Color3.fromRGB(240, 252, 255), Color3.fromRGB(150, 210, 255))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = target
    emitter:Emit(ICE_PUFF_COUNT)
    Debris:AddItem(emitter, 1.5)
end

local function startIceReaction(): ()
    iceReactionGeneration += 1
    local generation = iceReactionGeneration
    table.clear(icePuffed)
    if iceReactionConnection then
        iceReactionConnection:Disconnect()
        iceReactionConnection = nil
    end

    local folder = Workspace:FindFirstChild("ActiveIce")
    if not folder then
        return
    end

    local count = 0
    for _, child in folder:GetChildren() do
        if count >= ICE_PUFF_CAP then
            break
        end
        count += 1
        puffIce(child)
    end

    iceReactionConnection = folder.ChildAdded:Connect(function(child)
        if generation == iceReactionGeneration and count < ICE_PUFF_CAP then
            count += 1
            puffIce(child)
        end
    end)

    task.delay(ICE_REACTION_WINDOW, function()
        if generation == iceReactionGeneration and iceReactionConnection then
            iceReactionConnection:Disconnect()
            iceReactionConnection = nil
        end
    end)
end

local function startAnticipation(remaining: number): ()
    anticipating = true
    captureBaseline()
    tweenValue(worldBlend, ANTICIPATION_BLEND, math.max(remaining, 0.5))
    ensureSnow()
    setSnowRate(ANTICIPATION_SNOW_RATE, math.max(remaining, 0.5))
end

local function playFrostImpact(): ()
    fxGeneration += 1
    anticipating = false
    captureBaseline()

    tweenValue(worldBlend, 1, IMPACT_BLEND_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local lift = tweenValue(bloomLift, 1, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    lift.Completed:Once(function(state)
        if state == Enum.PlaybackState.Completed then
            tweenValue(bloomLift, 0, 1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)

    local emitter = ensureSnow()
    emitter:Emit(SNOW_BURST_COUNT)
    setSnowRate(SNOW_HOLD_RATE, IMPACT_BLEND_SECONDS)

    spawnFrostWave()
    playFrostSound()
    startAurora(AURORA_FADE_IN_SECONDS)
    startIceReaction()
end

-- Joining mid-Frost: hold state only, no anticipation / wave / puffs.
local function applyFrostHold(): ()
    fxGeneration += 1
    anticipating = false
    captureBaseline()
    worldBlend.Value = 1
    ensureSnow()
    setSnowRate(SNOW_HOLD_RATE, 0)
    startAurora(AURORA_FADE_IN_SECONDS)
end

local function releaseFrostFx(): ()
    fxGeneration += 1
    local generation = fxGeneration
    anticipating = false
    captureBaseline()

    tweenValue(worldBlend, 0, RELEASE_SECONDS)
    tweenValue(auroraFade, 0, RELEASE_SECONDS)
    if snowEmitter then
        setSnowRate(0, 1.2)
    end

    -- Restrained light release.
    local lift = tweenValue(bloomLift, 0.4, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    lift.Completed:Once(function(state)
        if state == Enum.PlaybackState.Completed then
            tweenValue(bloomLift, 0, 1.0)
        end
    end)

    task.delay(RELEASE_SECONDS + 0.3, function()
        if generation ~= fxGeneration then
            return
        end
        destroyAurora()
        restoreBaseline()
    end)
    task.delay(RELEASE_SECONDS + 4.5, function()
        if generation == fxGeneration then
            destroySnow()
        end
    end)
end

-- Called from the existing Heartbeat: keeps the sky-follow FX attached to the camera and starts the T-3s anticipation.
local function updateFx(): ()
    local camera = Workspace.CurrentCamera
    if camera then
        local camPosition = camera.CFrame.Position
        if snowPart and snowPart.Parent then
            snowPart.CFrame = CFrame.new(camPosition + SNOW_OFFSET)
        end

        if #auroraSpecs > 0 then
            local t = os.clock()
            for index, spec in auroraSpecs do
                local sway = 14 * math.sin(t * 0.15 + index * 1.7)
                local base = Vector3.new(camPosition.X, spec.Y + sway, camPosition.Z + spec.Z)
                auroraAttachments[index * 2 - 1].WorldPosition = base + Vector3.new(spec.X0, 0, 0)
                auroraAttachments[index * 2].WorldPosition = base + Vector3.new(spec.X1, -sway * 0.6, 0)
            end
        end
    end

    local snapshot = currentSnapshot
    if snapshot and snapshot.CurrentPhase == DAY_PHASE and not anticipating then
        local remaining = snapshot.NextTransitionUnix - Workspace:GetServerTimeNow()
        if remaining > 0 and remaining <= ANTICIPATION_SECONDS then
            startAnticipation(remaining)
        end
    end
end

local function applyPhasePresentation(
    colorEffect: ColorCorrectionEffect,
    frostBanner: TextLabel,
    phase: string,
    previousPhase: string?
): ()
    if phase == GREAT_FROST_PHASE then
        setFrostVisual(colorEffect, true)

        if previousPhase == DAY_PHASE then
            showFrostBanner(frostBanner, FROST_BANNER_TEXT)
            playFrostImpact()
        elseif previousPhase == nil then
            applyFrostHold()
        end
        return
    end

    setFrostVisual(colorEffect, false)
    hideFrostBanner(frostBanner)
    anticipating = false
    if previousPhase == GREAT_FROST_PHASE then
        releaseFrostFx()
    end
end

local function formatDuration(seconds: number): string
    local wholeSeconds = math.max(0, math.ceil(seconds))
    if wholeSeconds >= 3600 then
        local hours = math.floor(wholeSeconds / 3600)
        local minutes = math.floor((wholeSeconds % 3600) / 60)
        return string.format("%d:%02d:%02d", hours, minutes, wholeSeconds % 60)
    end

    return string.format("%d:%02d", math.floor(wholeSeconds / 60), wholeSeconds % 60)
end

local function isValidSnapshot(data: any): boolean
    return type(data) == "table"
        and (data.CurrentPhase == DAY_PHASE or data.CurrentPhase == GREAT_FROST_PHASE)
        and type(data.CycleIndex) == "number"
        and data.CycleIndex >= 0
        and data.CycleIndex % 1 == 0
        and type(data.NextTransitionUnix) == "number"
end

local function applyCardState(hud: Hud, isFrost: boolean): ()
    if pulseTween then
        pulseTween:Cancel()
        pulseTween = nil
    end

    hud.Header.TextColor3 = if isFrost then CARD_HEADER_ACTIVE else CARD_HEADER_NORMAL
    hud.Timer.TextColor3 = if isFrost then CARD_TIMER_ACTIVE else CARD_TIMER_NORMAL
    hud.Stroke.Color = if isFrost then CARD_STROKE_ACTIVE else CARD_STROKE_NORMAL
    hud.Stroke.Thickness = if isFrost then 2.5 else 1.5
    hud.Stroke.Transparency = if isFrost then 0.1 else 0.35

    if isFrost then
        pulseTween = TweenService:Create(hud.Stroke, CARD_PULSE_INFO, { Transparency = 0.5 })
        pulseTween:Play()
    end
end

local function updateHud(hud: Hud): ()
    local snapshot = currentSnapshot
    if not snapshot then
        return
    end

    local wholeSeconds = math.max(0, math.ceil(snapshot.NextTransitionUnix - Workspace:GetServerTimeNow()))
    if snapshot.CurrentPhase == lastDisplayedPhase and wholeSeconds == lastDisplayedSeconds then
        return
    end

    if snapshot.CurrentPhase ~= lastDisplayedPhase then
        applyCardState(hud, snapshot.CurrentPhase == GREAT_FROST_PHASE)
    end
    lastDisplayedPhase = snapshot.CurrentPhase
    lastDisplayedSeconds = wholeSeconds

    local duration = formatDuration(wholeSeconds)
    hud.Timer.Text = if snapshot.CurrentPhase == GREAT_FROST_PHASE
        then duration .. ' <font size="12">REMAINING</font>'
        else '<font size="13">IN </font>' .. duration
end

local function updateViewportScale(hud: Hud): ()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    -- Slightly smaller on narrow screens; never below 0.8 so the timer stays legible.
    hud.Scale.Scale = math.clamp(camera.ViewportSize.X / 800, 0.8, 1)
end

function WorldCycleController.Start(): ()
    if started then
        return
    end
    started = true

    local hud, frostBanner = createHud()
    local colorEffect = createColorEffect()
    atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    worldBlend.Changed:Connect(applyAtmosphere)
    bloomLift.Changed:Connect(applyBloom)
    auroraFade.Changed:Connect(applyAuroraFade)
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "SpecialIceAwakened" then
            task.delay(SPECIAL_ICE_BANNER_DELAY, showFrostBanner, frostBanner, SPECIAL_ICE_BANNER_TEXT)
            return
        end

        if eventName ~= "WorldCycleUpdated" or not isValidSnapshot(data) then
            return
        end

        local previousPhase = if currentSnapshot then currentSnapshot.CurrentPhase else nil
        local nextSnapshot = {
            CurrentPhase = data.CurrentPhase,
            CycleIndex = data.CycleIndex,
            NextTransitionUnix = data.NextTransitionUnix,
        }
        currentSnapshot = nextSnapshot

        if previousPhase ~= nextSnapshot.CurrentPhase then
            applyPhasePresentation(
                colorEffect,
                frostBanner,
                nextSnapshot.CurrentPhase,
                previousPhase
            )
        end
        updateHud(hud)
    end)

    updateViewportScale(hud)
    local camera = Workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            updateViewportScale(hud)
        end)
    end

    RunService.Heartbeat:Connect(function()
        updateHud(hud)
        updateFx()
    end)
end

return WorldCycleController
