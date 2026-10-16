local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WarmthConfig = require(shared:WaitForChild("WarmthConfig"))

local WarmthController = {}

-- Prefabs: StarterGui.MainHud.TopCenter.WarmthPanel and StarterGui.WarmthFx (authored in Studio).
local HUD_NAME = "MainHud"
local FX_NAME = "WarmthFx"
local SAFE_STATE = "Safe"
local LOW_STATE = "Low"
local CRITICAL_STATE = "Critical"

-- Panel colours tint the prefab's frosted gradient (white = untinted).
local NORMAL_BACKGROUND_COLOR = Color3.fromRGB(255, 255, 255)
local LOW_BACKGROUND_COLOR = Color3.fromRGB(165, 225, 255)
local CRITICAL_BACKGROUND_COLOR = Color3.fromRGB(255, 120, 112)
local PANEL_TRANSPARENCY = 0.06

local SAFE_FILL_COLOR = Color3.fromRGB(255, 154, 56)
local SAFE_RIM_COLOR = Color3.fromRGB(127, 219, 255)
local SAFE_RIM_TRANSPARENCY = 0.55
local LOW_ACCENT_COLOR = Color3.fromRGB(110, 215, 255)
local CRITICAL_ACCENT_COLOR = Color3.fromRGB(255, 82, 70)
local LOW_TAG_TEXT_COLOR = Color3.fromRGB(8, 30, 44)
local CRITICAL_TAG_TEXT_COLOR = Color3.fromRGB(255, 255, 255)

-- Low: frost creeps in from beyond the screen edge. Critical: full frost with a restrained pulse.
local LOW_VIGNETTE_SCALE = 1.14
local CRITICAL_VIGNETTE_SCALE = 1
local LOW_EDGE_TRANSPARENCY = 0.4
local CRITICAL_EDGE_TRANSPARENCY = 0.12
local CRITICAL_EDGE_PULSE_TRANSPARENCY = 0.32
local FROST_PULSE_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- One-shot impact when first entering Critical.
local IMPACT_FLASH_COLOR = Color3.fromRGB(205, 238, 255)
local IMPACT_FLASH_TRANSPARENCY = 0.72
local IMPACT_FLASH_SECONDS = 0.4

-- Relief only after gradual recovery; any single-update ratio jump above this is treated as a reset/freeze-like restore.
local RELIEF_SECONDS = 0.5
local RELIEF_WARM_TRANSPARENCY = 0.3
local RELIEF_MAX_RATIO_JUMP = 0.3

-- Local-only outline on the carried Ice while Low/Critical.
local CARRY_HIGHLIGHT_NAME = "CarriedIceDanger"
local CARRY_LOW_OUTLINE_COLOR = Color3.fromRGB(120, 215, 255)
local CARRY_CRITICAL_OUTLINE_COLOR = Color3.fromRGB(200, 240, 255)
local CARRY_LOW_OUTLINE_TRANSPARENCY = 0.4
local CARRY_CRITICAL_OUTLINE_TRANSPARENCY = 0.1
local CARRY_CRITICAL_PULSE_TRANSPARENCY = 0.55

-- Critical audio hook. PENDING ASSET: leave empty until an approved sound is chosen; empty means silent.
local CRITICAL_SOUND_ID = ""
local CRITICAL_SOUND_VOLUME = 0.35
local CRITICAL_SOUND_FADE_SECONDS = 0.3

-- Low: slow (period ~2.4s). Critical: period ~0.5s (each direction 0.25s).
local LOW_PULSE_INFO = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local CRITICAL_PULSE_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local BAR_TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

-- Max Warmth gain popup (world-space feedback above the local character).
local GAIN_POPUP_NAME = "MaxWarmthGainPopup" -- template: ReplicatedStorage.UITemplates.MaxWarmthGainPopup
local GAIN_SHOWER_INTERVAL_SECONDS = 0.5 -- real deltas are grouped into one shower per interval
local GAIN_SHOWER_CHUNKS = 4
local GAIN_SHOWER_SPREAD_SECONDS = 0.45 -- chunks of one shower are staggered over this time
local GAIN_POPUP_LIFETIME_SECONDS = 0.7
local GAIN_POPUP_FADE_DELAY_SECONDS = 0.35
local GAIN_POPUP_BASE_HEIGHT = 2.6
local GAIN_POPUP_HEIGHT_JITTER = 0.9
local GAIN_POPUP_SPREAD_X = 1.6
local GAIN_POPUP_SPREAD_Z = 0.7
local GAIN_POPUP_DRIFT_X = 1.0
local GAIN_POPUP_RISE_MIN = 3.2
local GAIN_POPUP_RISE_MAX = 4.4
local GAIN_POPUP_MAX_ACTIVE = 10
local GAIN_CAPTION_BURST_GAP_SECONDS = 2
local GAIN_COLOR_LOW = Color3.fromRGB(255, 142, 48)
local GAIN_COLOR_HIGH = Color3.fromRGB(255, 176, 52)

type Hud = {
    Panel: Frame,
    PanelStroke: UIStroke,
    ValueLabel: TextLabel,
    Fill: Frame,
    Tag: TextLabel,
    PulseOverlay: Frame,
    HitOverlay: Frame,
    FrostEdges: { ImageLabel },
    WarmEdges: { ImageLabel },
    ImpactFlash: Frame,
}

local started = false
local hitFlashRevision = 0
local presentationState = SAFE_STATE
local pulseTween: Tween? = nil
local fillTween: Tween? = nil
local hasRendered = false
local previousMaxWarmth: number? = nil
local pendingMaxGain = 0
local lastGainPopupAt = -math.huge
local showerGeneration = 0
local lastShowerAt = -math.huge
local gainRandom = Random.new()
local gainFlushScheduled = false
local activeGainPopups: { BillboardGui } = {}
local frostTweens: { Tween } = {}
local frostGeneration = 0
local flashTween: Tween? = nil
local previousRatio: number? = nil
local reliefAllowed = false
local carryHighlight: Highlight? = nil
local carryPulseTween: Tween? = nil
local criticalSound: Sound? = nil
local criticalSoundTween: Tween? = nil
local gainPopupTemplate: BillboardGui? = nil

local function bindHud(): Hud
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local panel = playerGui:WaitForChild(HUD_NAME):WaitForChild("TopCenter"):WaitForChild("WarmthPanel") :: Frame
    local fx = playerGui:WaitForChild(FX_NAME)
    local bar = panel:WaitForChild("BarBackground")

    return {
        Panel = panel,
        PanelStroke = panel:WaitForChild("WarningStroke") :: UIStroke,
        ValueLabel = panel:WaitForChild("Value") :: TextLabel,
        Fill = bar:WaitForChild("Fill") :: Frame,
        Tag = panel:WaitForChild("StateTag") :: TextLabel,
        PulseOverlay = panel:WaitForChild("PulseOverlay") :: Frame,
        HitOverlay = panel:WaitForChild("HitOverlay") :: Frame,
        FrostEdges = { fx:WaitForChild("FrostVignette") :: ImageLabel },
        WarmEdges = { fx:WaitForChild("WarmVignette") :: ImageLabel },
        ImpactFlash = fx:WaitForChild("ImpactFlash") :: Frame,
    }
end

-- Compact display only; the underlying numbers are never changed.
local function formatScientific(abs: number, sign: string): string
    local text = string.format("%.2e", abs)
    local mantissa, exponent = text:match("^(.-)e([%+%-]?%d+)$")
    if not mantissa then
        return sign .. text
    end
    return string.format("%s%se%d", sign, mantissa, tonumber(exponent) :: number)
end

local function formatCompact(value: number): string
    local sign = if value < 0 then "-" else ""
    local abs = math.abs(value)

    local rounded = math.round(abs)
    if rounded < 1000 then
        return sign .. tostring(rounded)
    end

    local index = math.floor(math.log10(abs) / 3)
    while index > 1 and abs / (1000 ^ index) < 1 do
        index -= 1
    end
    index = math.max(index, 1)

    for _ = 1, 2 do
        if index > #SUFFIXES then
            return formatScientific(abs, sign)
        end

        local scaled = abs / (1000 ^ index)
        local decimals = if scaled < 10 then 2 elseif scaled < 100 then 1 else 0
        local text = string.format("%." .. decimals .. "f", scaled)

        if (tonumber(text) :: number) < 1000 then
            return sign .. text .. SUFFIXES[index]
        end

        index += 1 -- rounding carried over (e.g. 999.96K -> 1.00M)
    end

    return formatScientific(abs, sign)
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

local function setFrostEdges(frostEdges: { ImageLabel }, visible: boolean, transparency: number): ()
    for _, edge in frostEdges do
        edge.ImageTransparency = transparency
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

local function cancelFrostTweens(): ()
    frostGeneration += 1
    for _, tween in frostTweens do
        tween:Cancel()
    end
    table.clear(frostTweens)
end

-- The vignette is centred; growing it past the screen pushes the frost outward (shallower).
local function setEdgeDepth(edges: { ImageLabel }, scale: number): ()
    for _, edge in edges do
        edge.Size = UDim2.fromScale(scale, scale)
    end
end

local function stopCarryPulse(): ()
    if carryPulseTween then
        carryPulseTween:Cancel()
        carryPulseTween = nil
    end
end

local function removeCarryHighlight(): ()
    stopCarryPulse()
    if carryHighlight then
        carryHighlight.Enabled = false
        carryHighlight.Adornee = nil
    end
end

local function findCarriedIce(): BasePart?
    local character = Players.LocalPlayer.Character
    if not character then
        return nil
    end

    for _, child in character:GetChildren() do
        if child:IsA("BasePart") and child:GetAttribute("IceInstanceID") ~= nil then
            return child
        end
    end

    return nil
end

-- Presentation only: never touches the Ice's physics, welds, ownership or server state.
local function updateCarryHighlight(): ()
    local ice = if presentationState ~= SAFE_STATE then findCarriedIce() else nil
    if not ice then
        removeCarryHighlight()
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    if not carryHighlight or not carryHighlight.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Name = CARRY_HIGHLIGHT_NAME
        highlight.FillTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = camera
        carryHighlight = highlight
    end

    local highlight = carryHighlight :: Highlight
    highlight.Adornee = ice
    highlight.Enabled = true

    if presentationState == CRITICAL_STATE then
        highlight.OutlineColor = CARRY_CRITICAL_OUTLINE_COLOR
        if not carryPulseTween then
            highlight.OutlineTransparency = CARRY_CRITICAL_OUTLINE_TRANSPARENCY
            carryPulseTween = TweenService:Create(highlight, FROST_PULSE_INFO, {
                OutlineTransparency = CARRY_CRITICAL_PULSE_TRANSPARENCY,
            })
            carryPulseTween:Play()
        end
    else
        stopCarryPulse()
        highlight.OutlineColor = CARRY_LOW_OUTLINE_COLOR
        highlight.OutlineTransparency = CARRY_LOW_OUTLINE_TRANSPARENCY
    end
end

-- Critical loop hook. Silent while CRITICAL_SOUND_ID is empty (asset pending).
local function setCriticalAudio(active: boolean): ()
    if CRITICAL_SOUND_ID == "" then
        return
    end

    if not criticalSound or not criticalSound.Parent then
        local sound = Instance.new("Sound")
        sound.Name = "CriticalWarmthLoop"
        sound.SoundId = CRITICAL_SOUND_ID
        sound.Looped = true
        sound.Volume = 0
        sound.Parent = SoundService
        criticalSound = sound
    end

    local sound = criticalSound :: Sound
    if criticalSoundTween then
        criticalSoundTween:Cancel()
    end

    if active then
        sound:Play()
    end
    criticalSoundTween = TweenService:Create(
        sound,
        TweenInfo.new(CRITICAL_SOUND_FADE_SECONDS),
        { Volume = if active then CRITICAL_SOUND_VOLUME else 0 }
    )
    criticalSoundTween.Completed:Once(function()
        if not active and sound.Parent then
            sound:Stop()
        end
    end)
    criticalSoundTween:Play()
end

local function playImpactFlash(hud: Hud): ()
    if flashTween then
        flashTween:Cancel()
    end
    hud.ImpactFlash.BackgroundTransparency = IMPACT_FLASH_TRANSPARENCY
    flashTween = TweenService:Create(
        hud.ImpactFlash,
        TweenInfo.new(IMPACT_FLASH_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 1 }
    )
    flashTween:Play()
end

local function playRelief(hud: Hud): ()
    local generation = frostGeneration
    local info = TweenInfo.new(RELIEF_SECONDS, Enum.EasingStyle.Linear)

    for _, edge in hud.FrostEdges do
        local tween = TweenService:Create(edge, info, { ImageTransparency = 1 })
        table.insert(frostTweens, tween)
        tween:Play()
    end

    setEdgeDepth(hud.WarmEdges, LOW_VIGNETTE_SCALE)
    setFrostEdges(hud.WarmEdges, true, RELIEF_WARM_TRANSPARENCY)
    for _, edge in hud.WarmEdges do
        local tween = TweenService:Create(edge, info, { ImageTransparency = 1 })
        table.insert(frostTweens, tween)
        tween:Play()
    end

    task.delay(RELIEF_SECONDS + 0.05, function()
        if generation ~= frostGeneration then
            return
        end
        setFrostEdges(hud.FrostEdges, false, 1)
        setFrostEdges(hud.WarmEdges, false, 1)
    end)
end

local function applyPresentationState(hud: Hud, nextState: string, force: boolean?): ()
    if nextState == presentationState and not force then
        return
    end

    local previousState = presentationState
    presentationState = nextState
    cancelFrostTweens()
    setFrostEdges(hud.WarmEdges, false, 1)

    if nextState == SAFE_STATE then
        stopPulse(hud)
        hud.Panel.BackgroundColor3 = NORMAL_BACKGROUND_COLOR
        hud.Panel.BackgroundTransparency = PANEL_TRANSPARENCY
        hud.PanelStroke.Color = SAFE_RIM_COLOR
        hud.PanelStroke.Thickness = 2
        hud.PanelStroke.Transparency = SAFE_RIM_TRANSPARENCY
        hud.Fill.BackgroundColor3 = SAFE_FILL_COLOR
        hud.Tag.Text = ""
        hud.Tag.Visible = false

        local wasPressured = previousState == LOW_STATE or previousState == CRITICAL_STATE
        if reliefAllowed and wasPressured and not force then
            playRelief(hud)
        else
            setFrostEdges(hud.FrostEdges, false, 1)
        end
        reliefAllowed = false

        setCriticalAudio(false)
        updateCarryHighlight()
        return
    end

    hud.PanelStroke.Thickness = 3
    hud.Tag.Visible = true

    if nextState == LOW_STATE then
        hud.Panel.BackgroundColor3 = LOW_BACKGROUND_COLOR
        hud.Panel.BackgroundTransparency = PANEL_TRANSPARENCY
        hud.PanelStroke.Color = LOW_ACCENT_COLOR
        hud.PanelStroke.Transparency = 0.25
        hud.Fill.BackgroundColor3 = LOW_ACCENT_COLOR
        hud.Tag.Text = "LOW"
        hud.Tag.BackgroundColor3 = LOW_ACCENT_COLOR
        hud.Tag.TextColor3 = LOW_TAG_TEXT_COLOR
        setEdgeDepth(hud.FrostEdges, LOW_VIGNETTE_SCALE)
        setFrostEdges(hud.FrostEdges, true, LOW_EDGE_TRANSPARENCY)
        startPulse(hud, LOW_ACCENT_COLOR, 0.92, 0.78, LOW_PULSE_INFO)
        setCriticalAudio(false)
        updateCarryHighlight()
        return
    end

    hud.Panel.BackgroundColor3 = CRITICAL_BACKGROUND_COLOR
    hud.Panel.BackgroundTransparency = PANEL_TRANSPARENCY
    hud.PanelStroke.Color = CRITICAL_ACCENT_COLOR
    hud.PanelStroke.Transparency = 0
    hud.Fill.BackgroundColor3 = CRITICAL_ACCENT_COLOR
    hud.Tag.Text = "CRITICAL"
    hud.Tag.BackgroundColor3 = CRITICAL_ACCENT_COLOR
    hud.Tag.TextColor3 = CRITICAL_TAG_TEXT_COLOR
    setEdgeDepth(hud.FrostEdges, CRITICAL_VIGNETTE_SCALE)
    setFrostEdges(hud.FrostEdges, true, CRITICAL_EDGE_TRANSPARENCY)
    for _, edge in hud.FrostEdges do
        local tween = TweenService:Create(edge, FROST_PULSE_INFO, {
            ImageTransparency = CRITICAL_EDGE_PULSE_TRANSPARENCY,
        })
        table.insert(frostTweens, tween)
        tween:Play()
    end
    startPulse(hud, CRITICAL_ACCENT_COLOR, 0.78, 0.45, CRITICAL_PULSE_INFO)
    if previousState ~= CRITICAL_STATE and not force then
        playImpactFlash(hud)
    end
    setCriticalAudio(true)
    updateCarryHighlight()
end

local function setFillRatio(hud: Hud, ratio: number, instant: boolean): ()
    if fillTween then
        fillTween:Cancel()
        fillTween = nil
    end

    local target = UDim2.fromScale(ratio, 1)
    if instant then
        hud.Fill.Size = target
        return
    end

    fillTween = TweenService:Create(hud.Fill, BAR_TWEEN_INFO, { Size = target })
    fillTween:Play()
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

local trackMaxWarmthGain

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
        formatCompact(currentWarmth),
        formatCompact(maxWarmth)
    )
    trackMaxWarmthGain(maxWarmth)

    local nextState, ratio = classifyWarmth(currentWarmth, maxWarmth)
    setFillRatio(hud, ratio, not hasRendered)
    hasRendered = true

    -- Relief only for gradual recovery; a big single-update jump (reset/freeze-like restore) is silent.
    reliefAllowed = previousRatio ~= nil and (ratio - previousRatio) <= RELIEF_MAX_RATIO_JUMP
    previousRatio = ratio
    applyPresentationState(hud, nextState)
    reliefAllowed = false
end

local function clearGainPopups(): ()
    showerGeneration += 1 -- cancels chunks that are still waiting to spawn
    for _, popup in activeGainPopups do
        if popup.Parent then
            popup:Destroy()
        end
    end
    table.clear(activeGainPopups)
    pendingMaxGain = 0
end

local function spawnGainNumber(amount: number, showCaption: boolean): ()
    local character = Players.LocalPlayer.Character
    local head = if character then character:FindFirstChild("Head") else nil
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if not head
        or not head:IsA("BasePart")
        or not head:IsDescendantOf(Workspace)
        or not humanoid
        or humanoid.Health <= 0
    then
        return
    end

    for index = #activeGainPopups, 1, -1 do
        if not activeGainPopups[index].Parent then
            table.remove(activeGainPopups, index)
        end
    end
    while #activeGainPopups >= GAIN_POPUP_MAX_ACTIVE do
        local oldest = table.remove(activeGainPopups, 1)
        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end

    local startOffset = Vector3.new(
        gainRandom:NextNumber(-GAIN_POPUP_SPREAD_X, GAIN_POPUP_SPREAD_X),
        GAIN_POPUP_BASE_HEIGHT + gainRandom:NextNumber(0, GAIN_POPUP_HEIGHT_JITTER),
        gainRandom:NextNumber(-GAIN_POPUP_SPREAD_Z, GAIN_POPUP_SPREAD_Z)
    )
    local endOffset = startOffset
        + Vector3.new(
            gainRandom:NextNumber(-GAIN_POPUP_DRIFT_X, GAIN_POPUP_DRIFT_X),
            gainRandom:NextNumber(GAIN_POPUP_RISE_MIN, GAIN_POPUP_RISE_MAX),
            0
        )
    local finalScale = gainRandom:NextNumber(0.9, 1.3)

    local template = gainPopupTemplate
    if not template then
        return
    end

    local popup = template:Clone()
    popup.Name = GAIN_POPUP_NAME
    popup.Adornee = head
    popup.StudsOffsetWorldSpace = startOffset

    local holder = popup:WaitForChild("Holder")
    local scale = holder:WaitForChild("Scale") :: UIScale
    scale.Scale = finalScale * 0.55

    local gainLabel = holder:WaitForChild("Gain") :: TextLabel
    gainLabel.Size = UDim2.fromScale(1, if showCaption then 0.68 else 1)
    gainLabel.Text = "+" .. formatCompact(amount)
    gainLabel.TextColor3 = GAIN_COLOR_LOW:Lerp(GAIN_COLOR_HIGH, gainRandom:NextNumber())

    local fadeTargets: { TextLabel } = { gainLabel }
    local caption = holder:WaitForChild("Caption") :: TextLabel
    caption.Visible = showCaption
    if showCaption then
        table.insert(fadeTargets, caption)
    end

    popup.Parent = head
    table.insert(activeGainPopups, popup)

    -- Quick pop-in with overshoot.
    TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = finalScale,
    }):Play()

    -- Rise and drift; destroy when finished (no per-popup loops or connections).
    local moveTween = TweenService:Create(
        popup,
        TweenInfo.new(GAIN_POPUP_LIFETIME_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { StudsOffsetWorldSpace = endOffset }
    )
    moveTween.Completed:Once(function()
        if popup.Parent then
            popup:Destroy()
        end
    end)
    moveTween:Play()

    local fadeInfo = TweenInfo.new(
        GAIN_POPUP_LIFETIME_SECONDS - GAIN_POPUP_FADE_DELAY_SECONDS,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In,
        0,
        false,
        GAIN_POPUP_FADE_DELAY_SECONDS
    )
    for _, label in fadeTargets do
        TweenService:Create(label, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    end
end

-- Splits a whole-number gain into `count` chunks whose sum is exactly `amount`.
local function splitGain(amount: number, count: number): { number }
    local chunks = {}
    local base = amount // count
    local remainder = amount - base * count
    for index = 1, count do
        chunks[index] = base + (if index <= remainder then 1 else 0)
    end
    return chunks
end

local function flushMaxGain(): ()
    local amount = math.floor(pendingMaxGain + 1e-6)
    if amount < 1 then
        return -- too small to display yet; keep accumulating the real delta
    end

    pendingMaxGain -= amount -- fractional leftovers carry into the next shower
    local now = os.clock()
    local newBurst = now - lastShowerAt > GAIN_CAPTION_BURST_GAP_SECONDS
    lastShowerAt = now
    lastGainPopupAt = now

    local chunks = splitGain(amount, math.min(GAIN_SHOWER_CHUNKS, amount))
    local generation = showerGeneration
    local step = GAIN_SHOWER_SPREAD_SECONDS / math.max(#chunks - 1, 1)
    for index, chunk in chunks do
        local showCaption = newBurst and index == 1
        if index == 1 then
            spawnGainNumber(chunk, showCaption)
        else
            task.delay(step * (index - 1), function()
                if generation == showerGeneration then
                    spawnGainNumber(chunk, false)
                end
            end)
        end
    end
end

-- Real replicated MaxWarmth only: every positive delta feeds a shower; one shower per interval.
function trackMaxWarmthGain(maxWarmth: number): ()
    local previous = previousMaxWarmth
    previousMaxWarmth = maxWarmth
    if previous == nil then
        return
    end

    local delta = maxWarmth - previous
    if delta <= 0 then
        return
    end

    pendingMaxGain += delta

    local waitTime = GAIN_SHOWER_INTERVAL_SECONDS - (os.clock() - lastGainPopupAt)
    if waitTime <= 0 then
        flushMaxGain()
    elseif not gainFlushScheduled then
        gainFlushScheduled = true
        local generation = showerGeneration
        task.delay(waitTime, function()
            gainFlushScheduled = false
            if generation == showerGeneration and pendingMaxGain > 0 then
                flushMaxGain()
            end
        end)
    end
end

function WarmthController.Start(): ()
    if started then
        return
    end
    started = true

    local hud = bindHud()
    gainPopupTemplate = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild(GAIN_POPUP_NAME) :: BillboardGui
    Players.LocalPlayer.CharacterRemoving:Connect(clearGainPopups)
    Players.LocalPlayer.CharacterRemoving:Connect(function()
        previousRatio = nil
        reliefAllowed = false
        removeCarryHighlight()
    end)

    local function bindCharacter(character: Model): ()
        character.ChildAdded:Connect(updateCarryHighlight)
        character.ChildRemoved:Connect(updateCarryHighlight)
        updateCarryHighlight()
    end
    Players.LocalPlayer.CharacterAdded:Connect(bindCharacter)
    if Players.LocalPlayer.Character then
        bindCharacter(Players.LocalPlayer.Character)
    end
    applyPresentationState(hud, SAFE_STATE, true)
    setFillRatio(hud, 1, true)

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
