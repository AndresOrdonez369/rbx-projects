local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local WorldCycleController = {}

-- Prefab: StarterGui.MainHud.BottomRight.CountdownCard and StarterGui.MainHud.FrostBanner (authored in Studio).
local HUD_NAME = "MainHud"
local FROST_COLOR_EFFECT_NAME = "PrototypeGreatFrostColor"
local DAY_PHASE = "Day"
local GREAT_FROST_PHASE = "GreatFrost"
local CARD_NAME = "CountdownCard"
local CARD_STROKE_NORMAL = Color3.fromRGB(127, 219, 255)
local CARD_STROKE_ACTIVE = Color3.fromRGB(120, 235, 255)
local CARD_HEADER_NORMAL = Color3.fromRGB(150, 182, 212)
local CARD_HEADER_ACTIVE = Color3.fromRGB(170, 240, 255)
local CARD_TIMER_NORMAL = Color3.fromRGB(244, 250, 255)
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
    Brightness = -0.03,
    Contrast = 0.12,
    Saturation = -0.12,
    TintColor = Color3.fromRGB(222, 236, 255),
}

-- ===== Great Frost hero-moment presentation =====
-- Client-local only. Lighting / Atmosphere / Bloom / SunRays / Sky values are captured before the first change and written
-- back exactly on release. Runtime instances live in Workspace.GreatFrostFx (or SoundService) and are destroyed afterwards.
local FROST_SOUND_ID = "" -- PENDING ASSET: impact boom (plays as the frost front passes the camera)
local FROST_SOUND_VOLUME = 0.6
local FROST_WIND_SOUND_ID = "" -- PENDING ASSET: looping cold wind bed (anticipation -> hold -> release)
local FROST_WIND_VOLUME = 0.35

local AURORA_TEXTURE_ID = "rbxassetid://137572511255384"
local FROST_FRONT_TEXTURE_ID = "rbxassetid://75153374661843"

local FROST_SKY_ENABLED = true
local FROST_SKY_FACES = {
    SkyboxUp = "rbxassetid://80932886209552",
    SkyboxRt = "rbxassetid://100842900778006",
    SkyboxLf = "rbxassetid://86998401320670",
    SkyboxFt = "rbxassetid://137764167860507",
    SkyboxDn = "rbxassetid://111550153240111",
    SkyboxBk = "rbxassetid://126444668120231",
}
local SKY_SAVED_PROPERTIES = { "SkyboxUp", "SkyboxRt", "SkyboxLf", "SkyboxFt", "SkyboxDn", "SkyboxBk", "CelestialBodiesShown" }

local FX_FOLDER_NAME = "GreatFrostFx"

local ANTICIPATION_SECONDS = 4
local ANTICIPATION_BLEND = 0.35
local ANTICIPATION_SNOW_RATE = 8
local ANTICIPATION_TIMEOUT = 3 -- unwind an anticipation if the Frost never arrives
local IMPACT_BLEND_SECONDS = 1.2
local RELEASE_SECONDS = 1.4
local FROST_ENTER_GRADE_INFO = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FROST_RELEASE_GRADE_INFO = TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Full-Frost world targets (worldBlend = 1). The change is carried by sky / atmosphere / light, not the colour grade.
local FROST_ATMOSPHERE = {
    Density = 0.36,
    Haze = 0.8,
    Color = Color3.fromRGB(120, 150, 190),
    Decay = Color3.fromRGB(60, 80, 120),
}
local FROST_LIGHTING = {
    Brightness = 2.2,
    ExposureCompensation = -0.2,
    Ambient = Color3.fromRGB(62, 74, 100),
    OutdoorAmbient = Color3.fromRGB(70, 88, 120),
}
local BLOOM_LIFT_INTENSITY = 0.7
local BLOOM_LIFT_THRESHOLD_DROP = 1.0
local BLOOM_THRESHOLD_FLOOR = 0.8

local SNOW_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local SNOW_HOLD_RATE = 14
local SNOW_BURST_COUNT = 50
local SNOW_OFFSET = Vector3.new(0, 26, 18) -- slightly north of the camera so flakes blow in with the front

-- Frost front: unlit mist panels that advance from the deep north (+Z, Meteor Reach side) and sweep through the camera.
local FRONT_WIDTH = 1400
local FRONT_HEIGHT = 230
local FRONT_CENTER_Y = 60
local FRONT_LAYERS = {
    { Dx = 0, Dy = 0, Dz = 0, Tile = 420, Brightness = 1.6 },
    { Dx = 40, Dy = -12, Dz = 35, Tile = 350, Brightness = 1.4 },
}
local FRONT_COLOR = ColorSequence.new(Color3.fromRGB(205, 232, 255), Color3.fromRGB(165, 210, 250))
local FRONT_START_OFFSET = 480 -- studs north of the camera when anticipation begins
local FRONT_GATHER_OFFSET = 260 -- where the wall waits at the moment of impact
local FRONT_END_OFFSET = -260
local FRONT_GATHER_FADE = 0.75
local FRONT_SWEEP_SECONDS = 1.6
local FRONT_FADE_OUT_SECONDS = 0.5

local ICE_REACTION_WINDOW = 2.5
local ICE_PUFF_COUNT = 8
local ICE_PUFF_CAP = 40

-- Aurora: unlit curtain panels on the northern sky. Texture keeps its authored orientation; side fades via UIGradient.
local AURORA_FADE_IN_SECONDS = 2.5
local AURORA_CURTAINS = {
    {
        Dx = -60, Dz = 340, Y = 230, Width = 1800, Height = 300, Tile = 480,
        Brightness = 1.8, Transparency = 0.15, Drift = 40, DriftSpeed = 0.05,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 255, 200)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 200, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 255, 210)),
        }),
    },
    {
        Dx = 40, Dz = 450, Y = 280, Width = 1900, Height = 320, Tile = 560,
        Brightness = 1.5, Transparency = 0.3, Drift = 55, DriftSpeed = -0.035,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 190, 255)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(150, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 220, 255)),
        }),
    },
}
local PANEL_SIDE_FADE = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.18, 0),
    NumberSequenceKeypoint.new(0.82, 0),
    NumberSequenceKeypoint.new(1, 1),
})

-- Meteor beacon: subtle local colour pulse on its Neon parts during the Frost (exact colours restored afterwards).
local BEACON_PULSE_COLOR = Color3.fromRGB(255, 200, 120)
local BEACON_PULSE_AMOUNT = 0.4
local BEACON_PULSE_SPEED = 2.2

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

local function bindHud(): (Hud, CanvasGroup)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = playerGui:WaitForChild(HUD_NAME)
    local card = screenGui:WaitForChild("BottomRight"):WaitForChild(CARD_NAME)

    return {
        Scale = card:WaitForChild("Pulse") :: UIScale,
        Stroke = card:WaitForChild("Stroke") :: UIStroke,
        Header = card:WaitForChild("Header") :: TextLabel,
        Timer = card:WaitForChild("Timer") :: TextLabel,
    }, screenGui:WaitForChild("FrostBanner") :: CanvasGroup
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

local function hideFrostBanner(frostBanner: CanvasGroup): ()
    bannerSequence += 1
    frostBanner.Visible = false
    frostBanner.GroupTransparency = 1
end

local function showFrostBanner(frostBanner: CanvasGroup, text: string): ()
    bannerSequence += 1
    local activeSequence = bannerSequence

    local label = frostBanner:FindFirstChild("Text")
    if label and label:IsA("TextLabel") then
        label.Text = text
    end
    frostBanner.GroupTransparency = 1
    frostBanner.Visible = true

    local fadeIn = TweenService:Create(frostBanner, BANNER_FADE_IN_INFO, {
        GroupTransparency = 0,
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
            GroupTransparency = 1,
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
local sunRays: SunRaysEffect? = nil
local atmosphereBaseline: { [string]: any }? = nil
local bloomBaseline: { [string]: any }? = nil
local lightingBaseline: { [string]: any }? = nil
local sunRaysBaseline: number? = nil
local baselineCaptured = false
local worldBlend = Instance.new("NumberValue") -- 0 = Day art, 1 = full Frost world
local bloomLift = Instance.new("NumberValue")
local auroraFade = Instance.new("NumberValue")
local frontFade = Instance.new("NumberValue")
local frontOffset = Instance.new("NumberValue") -- front distance north of the camera (studs)
local valueTweens: { [Instance]: Tween } = {}
local fxGeneration = 0
local anticipating = false
local fxFolder: Folder? = nil
local snowPart: Part? = nil
local snowEmitter: ParticleEmitter? = nil
local snowTween: Tween? = nil
local auroraPanels: { BasePart } = {}
local auroraGuis: { SurfaceGui } = {}
local auroraLabels: { ImageLabel } = {}
local auroraLabelBase: { number } = {}
local frontPanels: { BasePart } = {}
local frontGuis: { SurfaceGui } = {}
local frontLabels: { ImageLabel } = {}
local frontSweeping = false
local frontPassed = false
local frontPassedCallback: (() -> ())? = nil
local skySaved: { [string]: any }? = nil
local createdSky: Sky? = nil
local beaconColors: { [BasePart]: Color3 } = {}
local beaconActive = false
local windSound: Sound? = nil
local iceReactionGeneration = 0
local icePuffed: { [Instance]: boolean } = {}
local iceReactionConnection: RBXScriptConnection? = nil
local icePending: { Instance } = {}

local function cancelValueTween(value: NumberValue): ()
    local old = valueTweens[value]
    if old then
        old:Cancel()
        valueTweens[value] = nil
    end
end

local function tweenValue(value: NumberValue, goal: number, seconds: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
    cancelValueTween(value)
    local tween = TweenService:Create(
        value,
        TweenInfo.new(seconds, style or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.InOut),
        { Value = goal }
    )
    valueTweens[value] = tween
    tween:Play()
    return tween
end

local function getFxFolder(): Folder
    local folder = fxFolder
    if folder and folder.Parent then
        return folder
    end
    local created = Instance.new("Folder")
    created.Name = FX_FOLDER_NAME
    created.Parent = Workspace
    fxFolder = created
    return created
end

local function destroyFxFolderIfEmpty(): ()
    local folder = fxFolder
    if folder and #folder:GetChildren() == 0 then
        folder:Destroy()
        fxFolder = nil
    end
end

local function captureBaseline(): ()
    if baselineCaptured then
        return
    end
    baselineCaptured = true
    atmosphereBaseline = if atmosphere
        then {
            Density = atmosphere.Density,
            Haze = atmosphere.Haze,
            Color = atmosphere.Color,
            Decay = atmosphere.Decay,
        }
        else nil
    bloomBaseline = if bloom then { Intensity = bloom.Intensity, Threshold = bloom.Threshold } else nil
    lightingBaseline = {
        Brightness = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    }
    sunRaysBaseline = if sunRays then sunRays.Intensity else nil
end

local function applyWorld(): ()
    if not baselineCaptured then
        return
    end
    local alpha = worldBlend.Value
    local atmo = atmosphereBaseline
    if atmosphere and atmo then
        atmosphere.Density = atmo.Density + (FROST_ATMOSPHERE.Density - atmo.Density) * alpha
        atmosphere.Haze = atmo.Haze + (FROST_ATMOSPHERE.Haze - atmo.Haze) * alpha
        atmosphere.Color = atmo.Color:Lerp(FROST_ATMOSPHERE.Color, alpha)
        atmosphere.Decay = atmo.Decay:Lerp(FROST_ATMOSPHERE.Decay, alpha)
    end
    local light = lightingBaseline
    if light then
        Lighting.Brightness = light.Brightness + (FROST_LIGHTING.Brightness - light.Brightness) * alpha
        Lighting.ExposureCompensation = light.ExposureCompensation
            + (FROST_LIGHTING.ExposureCompensation - light.ExposureCompensation) * alpha
        Lighting.Ambient = light.Ambient:Lerp(FROST_LIGHTING.Ambient, alpha)
        Lighting.OutdoorAmbient = light.OutdoorAmbient:Lerp(FROST_LIGHTING.OutdoorAmbient, alpha)
    end
    if sunRays and sunRaysBaseline then
        sunRays.Intensity = sunRaysBaseline * (1 - alpha)
    end
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

local function applyPanelAlpha(guis: { SurfaceGui }, labels: { ImageLabel }, bases: { number }?, alpha: number): ()
    for index, label in labels do
        local base = if bases then bases[index] or 0 else 0
        label.ImageTransparency = base + (1 - base) * (1 - alpha)
    end
    for _, gui in guis do
        gui.Enabled = alpha > 0.01
    end
end

local function applyAuroraFade(): ()
    applyPanelAlpha(auroraGuis, auroraLabels, auroraLabelBase, auroraFade.Value)
end

local function applyFrontFade(): ()
    applyPanelAlpha(frontGuis, frontLabels, nil, frontFade.Value)
end

-- Writes every captured value back exactly.
local function restoreBaseline(): ()
    cancelValueTween(worldBlend)
    cancelValueTween(bloomLift)
    worldBlend.Value = 0
    bloomLift.Value = 0
    if baselineCaptured then
        local atmo = atmosphereBaseline
        if atmosphere and atmo then
            atmosphere.Density = atmo.Density
            atmosphere.Haze = atmo.Haze
            atmosphere.Color = atmo.Color
            atmosphere.Decay = atmo.Decay
        end
        local bloomBase = bloomBaseline
        if bloom and bloomBase then
            bloom.Intensity = bloomBase.Intensity
            bloom.Threshold = bloomBase.Threshold
        end
        local light = lightingBaseline
        if light then
            Lighting.Brightness = light.Brightness
            Lighting.ExposureCompensation = light.ExposureCompensation
            Lighting.Ambient = light.Ambient
            Lighting.OutdoorAmbient = light.OutdoorAmbient
        end
        if sunRays and sunRaysBaseline then
            sunRays.Intensity = sunRaysBaseline
        end
    end
    baselineCaptured = false
end

-- ---------- Frost sky (client-local swap; original Sky properties restored exactly) ----------
local function applyFrostSky(): ()
    if not FROST_SKY_ENABLED or skySaved then
        return
    end
    local sky: any = Lighting:FindFirstChildOfClass("Sky")
    local saved: { [string]: any } = {}
    if sky then
        for _, property in SKY_SAVED_PROPERTIES do
            saved[property] = sky[property]
        end
    else
        sky = Instance.new("Sky")
        sky.Name = "GreatFrostSky"
        createdSky = sky
    end
    saved.Sky = sky
    skySaved = saved
    for property, id in FROST_SKY_FACES do
        sky[property] = id
    end
    sky.CelestialBodiesShown = false
    if createdSky then
        createdSky.Parent = Lighting
    end
end

local function restoreSky(): ()
    local saved = skySaved
    skySaved = nil
    if createdSky then
        createdSky:Destroy()
        createdSky = nil
        return
    end
    if not saved then
        return
    end
    local sky: any = saved.Sky
    if sky and sky.Parent then
        for _, property in SKY_SAVED_PROPERTIES do
            sky[property] = saved[property]
        end
    end
end

-- ---------- audio hooks (silent until approved IDs exist) ----------
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

local function startWind(volume: number, seconds: number): ()
    if FROST_WIND_SOUND_ID == "" then
        return
    end
    local sound = windSound
    if not sound then
        local created = Instance.new("Sound")
        created.Name = "GreatFrostWind"
        created.SoundId = FROST_WIND_SOUND_ID
        created.Looped = true
        created.Volume = 0
        created.Parent = SoundService
        created:Play()
        windSound = created
        sound = created
    end
    TweenService:Create(sound, TweenInfo.new(math.max(seconds, 0.05), Enum.EasingStyle.Sine), { Volume = volume }):Play()
end

local function stopWind(seconds: number): ()
    local sound = windSound
    if not sound then
        return
    end
    windSound = nil
    TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Volume = 0 }):Play()
    Debris:AddItem(sound, seconds + 0.2)
end

-- ---------- snow ----------
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
    part.Size = Vector3.new(80, 1, 80)
    local camera = Workspace.CurrentCamera
    part.CFrame = CFrame.new((if camera then camera.CFrame.Position else Vector3.zero) + SNOW_OFFSET)
    part.Parent = getFxFolder()

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Snow"
    emitter.Rate = 0
    emitter.Texture = SNOW_TEXTURE
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.SpreadAngle = Vector2.new(20, 20)
    emitter.Lifetime = NumberRange.new(3.5, 5)
    emitter.Speed = NumberRange.new(8, 13)
    emitter.Acceleration = Vector3.new(2, -2, -7) -- wind from the north
    emitter.Drag = 0.2
    emitter.LightEmission = 0.4
    emitter.LightInfluence = 0.4
    emitter.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255), Color3.fromRGB(190, 225, 255))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0.4),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.12, 0.2),
        NumberSequenceKeypoint.new(0.8, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = part

    snowPart = part
    snowEmitter = emitter
    return emitter
end

local function setSnowRate(rate: number, seconds: number): ()
    local emitter = ensureSnow()
    if snowTween then
        snowTween:Cancel()
        snowTween = nil
    end
    if seconds <= 0 then
        emitter.Rate = rate
        return
    end
    local tween = TweenService:Create(emitter, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Rate = rate })
    snowTween = tween
    tween:Play()
end

local function destroySnow(): ()
    if snowTween then
        snowTween:Cancel()
        snowTween = nil
    end
    if snowPart then
        snowPart:Destroy()
    end
    snowPart = nil
    snowEmitter = nil
    destroyFxFolderIfEmpty()
end

-- ---------- unlit texture panels (aurora curtains + frost front) ----------
local function createPanel(
    name: string,
    width: number,
    height: number,
    texture: string,
    tile: number,
    brightness: number,
    color: ColorSequence
): (BasePart, SurfaceGui, ImageLabel)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Transparency = 1
    part.Size = Vector3.new(width, height, 0.2)
    part.CFrame = CFrame.new(0, -1000, 0)

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front -- faces -Z, toward a camera south of the panel
    gui.LightInfluence = 0
    gui.Brightness = brightness
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 1
    gui.Enabled = false
    gui.Parent = part

    local label = Instance.new("ImageLabel")
    label.Name = "Texture"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Image = texture
    label.ScaleType = Enum.ScaleType.Tile
    label.TileSize = UDim2.new(0, tile, 1, 0)
    label.ImageTransparency = 1
    label.Parent = gui

    local gradient = Instance.new("UIGradient")
    gradient.Color = color
    gradient.Transparency = PANEL_SIDE_FADE
    gradient.Parent = label

    part.Parent = getFxFolder()
    return part, gui, label
end

local function startAurora(fadeSeconds: number): ()
    if #auroraPanels == 0 then
        for index, spec in AURORA_CURTAINS do
            local part, gui, label = createPanel(
                "GreatFrostAurora" .. index,
                spec.Width,
                spec.Height,
                AURORA_TEXTURE_ID,
                spec.Tile,
                spec.Brightness,
                spec.Color
            )
            table.insert(auroraPanels, part)
            table.insert(auroraGuis, gui)
            table.insert(auroraLabels, label)
            table.insert(auroraLabelBase, spec.Transparency)
        end
        applyAuroraFade()
    end
    tweenValue(auroraFade, 1, fadeSeconds)
end

local function destroyAurora(): ()
    cancelValueTween(auroraFade)
    for _, part in auroraPanels do
        part:Destroy()
    end
    table.clear(auroraPanels)
    table.clear(auroraGuis)
    table.clear(auroraLabels)
    table.clear(auroraLabelBase)
    auroraFade.Value = 0
end

local function ensureFront(): boolean
    if #frontPanels > 0 then
        return false
    end
    for index, layer in FRONT_LAYERS do
        local part, gui, label = createPanel(
            "GreatFrostFront" .. index,
            FRONT_WIDTH,
            FRONT_HEIGHT,
            FROST_FRONT_TEXTURE_ID,
            layer.Tile,
            layer.Brightness,
            FRONT_COLOR
        )
        table.insert(frontPanels, part)
        table.insert(frontGuis, gui)
        table.insert(frontLabels, label)
    end
    frontFade.Value = 0
    applyFrontFade()
    return true
end

local function destroyFront(): ()
    cancelValueTween(frontFade)
    cancelValueTween(frontOffset)
    for _, part in frontPanels do
        part:Destroy()
    end
    table.clear(frontPanels)
    table.clear(frontGuis)
    table.clear(frontLabels)
    table.clear(icePending)
    frontSweeping = false
    frontPassed = false
    frontPassedCallback = nil
    frontFade.Value = 0
end

-- ---------- Meteor beacon pulse ----------
local function startBeaconPulse(): ()
    if beaconActive then
        return
    end
    local regions = Workspace:FindFirstChild("ProgressionRegions")
    local reach = if regions then regions:FindFirstChild("MeteorReach") else nil
    local beacon = if reach then reach:FindFirstChild("MeteorBeacon") else nil
    if not beacon then
        return
    end
    table.clear(beaconColors)
    for _, descendant in beacon:GetDescendants() do
        if descendant:IsA("BasePart") and descendant.Material == Enum.Material.Neon then
            beaconColors[descendant] = descendant.Color
        end
    end
    beaconActive = next(beaconColors) ~= nil
end

local function restoreBeacon(): ()
    for part, color in beaconColors do
        if part.Parent then
            part.Color = color
        end
    end
    table.clear(beaconColors)
    beaconActive = false
end

-- ---------- Ice field reaction (local puffs only; Ice attributes / prompts / physics untouched) ----------
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

local function icePosition(ice: Instance): Vector3?
    if ice:IsA("BasePart") then
        return ice.Position
    elseif ice:IsA("Model") then
        return ice:GetPivot().Position
    end
    return nil
end

-- While the front is sweeping, each Ice puffs as the wall reaches it; otherwise immediately.
local function queueIce(ice: Instance): ()
    if frontSweeping then
        table.insert(icePending, ice)
    else
        puffIce(ice)
    end
end

local function processIcePending(frontZ: number): ()
    for index = #icePending, 1, -1 do
        local ice = icePending[index]
        local position = if ice.Parent then icePosition(ice) else nil
        if not position then
            table.remove(icePending, index)
        elseif position.Z >= frontZ then
            table.remove(icePending, index)
            puffIce(ice)
        end
    end
end

local function flushIcePending(): ()
    for _, ice in icePending do
        if ice.Parent then
            puffIce(ice)
        end
    end
    table.clear(icePending)
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
        queueIce(child)
    end

    iceReactionConnection = folder.ChildAdded:Connect(function(child)
        if generation == iceReactionGeneration and count < ICE_PUFF_CAP then
            count += 1
            queueIce(child)
        end
    end)

    task.delay(ICE_REACTION_WINDOW, function()
        if generation == iceReactionGeneration and iceReactionConnection then
            iceReactionConnection:Disconnect()
            iceReactionConnection = nil
        end
    end)
end

-- ---------- phase sequences ----------
local function cleanupWorldFx(): ()
    destroyFront()
    destroyAurora()
    restoreBeacon()
    restoreSky()
    restoreBaseline()
end

local function scheduleSnowCleanup(generation: number, delaySeconds: number): ()
    task.delay(delaySeconds, function()
        if generation == fxGeneration then
            destroySnow()
        end
    end)
end

-- Last seconds of Day: wind and snow build, the world cools, the frost wall gathers far to the north.
local function startAnticipation(remaining: number): ()
    anticipating = true
    captureBaseline()
    local seconds = math.max(remaining, 0.5)
    tweenValue(worldBlend, ANTICIPATION_BLEND, seconds)
    setSnowRate(ANTICIPATION_SNOW_RATE, seconds)
    startWind(FROST_WIND_VOLUME * 0.5, seconds)
    ensureFront()
    frontOffset.Value = FRONT_START_OFFSET
    tweenValue(frontOffset, FRONT_GATHER_OFFSET, seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    tweenValue(frontFade, FRONT_GATHER_FADE, seconds)
end

-- The Frost never arrived (schedule moved / server stalled): unwind quietly.
local function cancelAnticipation(): ()
    fxGeneration += 1
    local generation = fxGeneration
    anticipating = false
    tweenValue(worldBlend, 0, RELEASE_SECONDS)
    tweenValue(frontFade, 0, RELEASE_SECONDS)
    if snowEmitter then
        setSnowRate(0, 1.2)
    end
    stopWind(RELEASE_SECONDS)
    task.delay(RELEASE_SECONDS + 0.3, function()
        if generation == fxGeneration then
            cleanupWorldFx()
        end
    end)
    scheduleSnowCleanup(generation, RELEASE_SECONDS + 4.5)
end

-- The moment the frost wall reaches the camera: sky turns, light flares, snow bursts, banner lands.
local function onFrontReachedCamera(): ()
    applyFrostSky()
    local lift = tweenValue(bloomLift, 1, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    lift.Completed:Once(function(state)
        if state == Enum.PlaybackState.Completed then
            tweenValue(bloomLift, 0, 1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)
    ensureSnow():Emit(SNOW_BURST_COUNT)
    playFrostSound()
    local callback = frontPassedCallback
    frontPassedCallback = nil
    if callback then
        callback()
    end
end

local function playFrostImpact(onFrontPassed: () -> ()): ()
    fxGeneration += 1
    local generation = fxGeneration
    anticipating = false
    captureBaseline()

    tweenValue(worldBlend, 1, IMPACT_BLEND_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    setSnowRate(SNOW_HOLD_RATE, IMPACT_BLEND_SECONDS)
    startWind(FROST_WIND_VOLUME, IMPACT_BLEND_SECONDS)
    startAurora(AURORA_FADE_IN_SECONDS)
    startBeaconPulse()

    if ensureFront() then
        frontOffset.Value = FRONT_GATHER_OFFSET -- no anticipation seen (e.g. joined in the last seconds)
    end
    frontSweeping = true
    frontPassed = false
    frontPassedCallback = onFrontPassed
    tweenValue(frontFade, 1, 0.25)
    local sweep = tweenValue(frontOffset, FRONT_END_OFFSET, FRONT_SWEEP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    sweep.Completed:Once(function(state)
        if state ~= Enum.PlaybackState.Completed or generation ~= fxGeneration then
            return
        end
        if not frontPassed then
            frontPassed = true
            onFrontReachedCamera()
        end
        frontSweeping = false
        flushIcePending()
        local fade = tweenValue(frontFade, 0, FRONT_FADE_OUT_SECONDS)
        fade.Completed:Once(function(fadeState)
            if fadeState == Enum.PlaybackState.Completed and generation == fxGeneration then
                destroyFront()
            end
        end)
    end)

    startIceReaction()
end

-- Joining mid-Frost: hold state only (no anticipation, front, puffs or burst).
local function applyFrostHold(): ()
    fxGeneration += 1
    anticipating = false
    destroyFront()
    captureBaseline()
    cancelValueTween(worldBlend)
    worldBlend.Value = 1
    applyWorld()
    applyFrostSky()
    ensureSnow()
    setSnowRate(SNOW_HOLD_RATE, 0)
    startWind(FROST_WIND_VOLUME, 1)
    startAurora(AURORA_FADE_IN_SECONDS)
    startBeaconPulse()
end

local function releaseFrostFx(): ()
    fxGeneration += 1
    local generation = fxGeneration
    anticipating = false
    captureBaseline()
    destroyFront()
    restoreSky() -- the sun returns under the release flash

    tweenValue(worldBlend, 0, RELEASE_SECONDS)
    tweenValue(auroraFade, 0, RELEASE_SECONDS)
    if snowEmitter then
        setSnowRate(0, 1.2)
    end
    stopWind(RELEASE_SECONDS)

    -- Brief, restrained warm release beat.
    local lift = tweenValue(bloomLift, 0.4, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    lift.Completed:Once(function(state)
        if state == Enum.PlaybackState.Completed then
            tweenValue(bloomLift, 0, 1.0)
        end
    end)

    task.delay(RELEASE_SECONDS + 0.3, function()
        if generation == fxGeneration then
            cleanupWorldFx()
        end
    end)
    scheduleSnowCleanup(generation, RELEASE_SECONDS + 4.5)
end

-- Called from the existing Heartbeat: camera-relative FX placement, front pass detection, beacon pulse, anticipation timing.
local function updateFx(): ()
    local camera = Workspace.CurrentCamera
    if camera then
        local camPosition = camera.CFrame.Position
        if snowPart and snowPart.Parent then
            snowPart.CFrame = CFrame.new(camPosition + SNOW_OFFSET)
        end

        local t = os.clock()
        for index, panel in auroraPanels do
            local spec = AURORA_CURTAINS[index]
            local drift = spec.Drift * math.sin(t * spec.DriftSpeed + index * 1.7)
            local sway = 8 * math.sin(t * 0.12 + index * 2.3)
            panel.CFrame = CFrame.new(camPosition.X + spec.Dx + drift, spec.Y + sway, camPosition.Z + spec.Dz)
        end

        if #frontPanels > 0 then
            local offset = frontOffset.Value
            for index, panel in frontPanels do
                local layer = FRONT_LAYERS[index]
                panel.CFrame = CFrame.new(
                    camPosition.X + layer.Dx,
                    FRONT_CENTER_Y + layer.Dy,
                    camPosition.Z + offset + layer.Dz
                )
            end
            if frontSweeping then
                if not frontPassed and offset <= 0 then
                    frontPassed = true
                    onFrontReachedCamera()
                end
                if #icePending > 0 then
                    processIcePending(camPosition.Z + offset)
                end
            end
        end

        if beaconActive then
            local strength = auroraFade.Value * BEACON_PULSE_AMOUNT * (0.5 + 0.5 * math.sin(t * BEACON_PULSE_SPEED))
            for part, base in beaconColors do
                part.Color = base:Lerp(BEACON_PULSE_COLOR, strength)
            end
        end
    end

    local snapshot = currentSnapshot
    if snapshot and snapshot.CurrentPhase == DAY_PHASE then
        local remaining = snapshot.NextTransitionUnix - Workspace:GetServerTimeNow()
        if not anticipating then
            if remaining > 0 and remaining <= ANTICIPATION_SECONDS then
                startAnticipation(remaining)
            end
        elseif remaining < -ANTICIPATION_TIMEOUT or remaining > ANTICIPATION_SECONDS + 1 then
            cancelAnticipation()
        end
    end
end

local function applyPhasePresentation(
    colorEffect: ColorCorrectionEffect,
    frostBanner: CanvasGroup,
    phase: string,
    previousPhase: string?
): ()
    if phase == GREAT_FROST_PHASE then
        setFrostVisual(colorEffect, true)

        if previousPhase == DAY_PHASE then
            -- The world leads: the banner lands when the frost wall reaches the camera.
            playFrostImpact(function()
                showFrostBanner(frostBanner, FROST_BANNER_TEXT)
            end)
        elseif previousPhase == nil then
            applyFrostHold()
        end
        return
    end

    setFrostVisual(colorEffect, false)
    hideFrostBanner(frostBanner)
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
    hud.Stroke.Thickness = if isFrost then 3 else 2
    hud.Stroke.Transparency = if isFrost then 0.1 else 0.55

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
        then duration .. ' <font size="14">LEFT</font>'
        else '<font size="15">IN </font>' .. duration
end

function WorldCycleController.Start(): ()
    if started then
        return
    end
    started = true

    local hud, frostBanner = bindHud()
    local colorEffect = createColorEffect()
    atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
    worldBlend.Changed:Connect(applyWorld)
    bloomLift.Changed:Connect(applyBloom)
    auroraFade.Changed:Connect(applyAuroraFade)
    frontFade.Changed:Connect(applyFrontFade)
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

    RunService.Heartbeat:Connect(function()
        updateHud(hud)
        updateFx()
    end)
end

return WorldCycleController
