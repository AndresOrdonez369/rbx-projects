-- Endgame mount presentation (F-D17-T05). Client-only and purely cosmetic.
-- Everything is driven by each rider's ACTUAL replicated horizontal velocity and the mount clone's physical size;
-- it never reads rarity, species stats or WalkSpeed, and it never touches movement, ownership or carry rules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local CreatureVisualController = require(script.Parent.CreatureVisualController)

local MountSpeedController = {}

local MOUNT_STATE_ATTRIBUTE = "MountState"
local RIDING_STATE = "Riding"
local FX_ATTACHMENT_NAME = "MountSpeedFx"
local WIND_GUI_NAME = "MountSpeedWind"

-- Speed response (studs/s of real horizontal velocity)
local SPEED_NONE = 24 -- at or below: no speed presentation
local SPEED_FULL = 60 -- at or above: full endgame presentation
local SPEED_SMOOTHING = 6
local TELEPORT_SPEED = 160 -- samples faster than this are teleports, not movement

-- Mount body motion (applied to the cosmetic clone, pivoting around the saddle so the rider stays seated)
local MAX_LEAN_DEGREES = 6
local LEAN_PER_SPEED_TURN = 0.08 -- degrees per (stud/s * rad/s)
local MAX_PITCH_DOWN_DEGREES = 5
local MAX_PITCH_UP_DEGREES = 3
local CRUISE_PITCH_DEGREES = 2.5
local ACCEL_PITCH_PER_STUD = 0.05
local ROCK_DEGREES = 0.8
local MOTION_SMOOTHING = 6
local BOB_HEIGHT_FRACTION, BOB_MIN, BOB_MAX = 0.012, 0.05, 0.3
local BOB_FULL_SPEED = 30
local STRIDE_DEPTH_FRACTION, STRIDE_MIN, STRIDE_MAX = 0.9, 4, 30
local STRIDE_FREQ_MIN, STRIDE_FREQ_MAX = 0.8, 3.2

-- Local rider FOV
local FOV_MAX_BOOST = 8
local FOV_SMOOTHING = 4
local FOV_EXTERNAL_TOLERANCE = 0.005 -- any FOV change this controller did not make = another owner is active
local FOV_YIELD_SECONDS = 0.6
local FOV_RESTORE_EPSILON = 0.03
local FOV_WRITE_STEP = 0.02 -- skip imperceptible updates so steady riding does not rewrite FOV every frame

-- Rider-only wind streaks
local WIND_SPEED_START = 40
local WIND_STREAK_COUNT = 8
local WIND_STREAK_MAX_OPACITY = 0.32
local WIND_STREAK_LIFETIME_MIN, WIND_STREAK_LIFETIME_MAX = 0.22, 0.38
local WIND_SOUND_ID = "" -- PENDING ASSET: optional mount wind loop (silent until approved)
local WIND_SOUND_MAX_VOLUME = 0.35

-- Observer trails / wake
local TRAIL_SPEED_START = 32
local TRAIL_LIFETIME_SHORT = 0.15 -- at 32
local TRAIL_LIFETIME_LONG = 0.45 -- at 50
local WAKE_SPEED_START = 52 -- lingering wind wake begins
local WAKE_LIFETIME_MAX = 1.5 -- at 60+
local TRAIL_WIDTH_FRACTION, TRAIL_WIDTH_MIN, TRAIL_WIDTH_MAX = 0.08, 0.3, 1.4
local TRAIL_COLOR = ColorSequence.new(Color3.fromRGB(235, 248, 255), Color3.fromRGB(160, 225, 255))
local SOFT_TEXTURE_ID = "rbxasset://textures/particles/smoke_main.dds"

local SNOW_SPEED_START = 30
local SNOW_RATE_MIN, SNOW_RATE_MAX = 3, 6
local SNOW_SIZE_FRACTION, SNOW_SIZE_MIN, SNOW_SIZE_MAX = 0.12, 0.8, 3

-- Large-mount ground response (physical size only): a restrained snow displacement burst on each stride downbeat.
local LARGE_HEIGHT = 10
local LARGE_FOOTPRINT = 14
local GROUND_RESPONSE_SPEED = 34
local GROUND_RESPONSE_BURST = 5

-- Observer culling
local MAX_REMOTE_EFFECT_RIDERS = 6
local REMOTE_EFFECT_RANGE = 300

local localPlayer = Players.LocalPlayer
local started = false
local riderStates: { [Player]: any } = {}
local fovBaseline: number? = nil
local fovBoost = 0
local fovObserved: number? = nil -- last FOV seen or written by this controller
local fovLastExternalChange = -math.huge
local windGui: ScreenGui? = nil
local windStreaks: { any } = {}
local windSound: Sound? = nil
local randomSource = Random.new()

local function smoothAlpha(rate: number, deltaTime: number): number
    return 1 - math.exp(-rate * deltaTime)
end

local function speedIntensity(speed: number): number
    local x = math.clamp((speed - SPEED_NONE) / (SPEED_FULL - SPEED_NONE), 0, 1)
    return x * x * (3 - 2 * x) -- smoothstep: no hard steps
end

local function rampBetween(value: number, low: number, high: number): number
    return math.clamp((value - low) / (high - low), 0, 1)
end

-- Saddle-pivoted motion handed to CreatureVisualController; world position stays locked to the rider.
local function mountMotion(player: Player, _model: Model, riderAnchor: Vector3): CFrame
    local state = riderStates[player]
    if not state then
        return CFrame.identity
    end
    return CFrame.new(0, state.Bob, 0)
        * CFrame.new(riderAnchor)
        * CFrame.Angles(math.rad(state.Pitch), 0, math.rad(state.Lean))
        * CFrame.new(-riderAnchor)
end

-- ---------- per-mount observer effects (reused instances, parented to the cosmetic clone) ----------
local function destroyEffects(state): ()
    local effects = state.Effects
    state.Effects = nil
    if not effects then
        return
    end
    for _, instance in effects.Instances do
        if instance.Parent then
            instance:Destroy()
        end
    end
end

local function createEffects(state, model: Model)
    local host = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not host then
        return nil
    end
    local pivot = model:GetPivot()
    local boxCFrame, boxSize = model:GetBoundingBox()
    local center = pivot:PointToObjectSpace(boxCFrame.Position)
    local instances = {}

    local function attach(position: Vector3): Attachment
        local attachment = Instance.new("Attachment")
        attachment.Name = FX_ATTACHMENT_NAME
        attachment.CFrame = host.CFrame:ToObjectSpace(pivot * CFrame.new(position))
        attachment.Parent = host
        table.insert(instances, attachment)
        return attachment
    end

    -- Two flank trails, scale-aware, from the rear third of the body.
    local trailWidth = math.clamp(boxSize.Y * TRAIL_WIDTH_FRACTION, TRAIL_WIDTH_MIN, TRAIL_WIDTH_MAX)
    local trailY = center.Y + boxSize.Y * 0.05
    local trailZ = center.Z + boxSize.Z * 0.32
    local trails = {}
    for _, side in { -1, 1 } do
        local x = center.X + side * boxSize.X * 0.38
        local low = attach(Vector3.new(x, trailY - trailWidth * 0.5, trailZ))
        local high = attach(Vector3.new(x, trailY + trailWidth * 0.5, trailZ))
        local trail = Instance.new("Trail")
        trail.Name = "SpeedTrail"
        trail.Attachment0 = low
        trail.Attachment1 = high
        trail.FaceCamera = true
        trail.Texture = SOFT_TEXTURE_ID
        trail.TextureMode = Enum.TextureMode.Stretch
        trail.LightEmission = 0.5
        trail.LightInfluence = 0.3
        trail.Color = TRAIL_COLOR
        trail.WidthScale = NumberSequence.new(1, 0.35)
        trail.MinLength = 0.05
        trail.Lifetime = TRAIL_LIFETIME_SHORT
        trail.Enabled = false
        trail.Parent = host
        table.insert(instances, trail)
        table.insert(trails, trail)
    end

    -- Snow wake (and large-mount ground response bursts) from the rear of the footprint.
    local footprint = math.max(boxSize.X, boxSize.Z)
    local snowSize = math.clamp(footprint * SNOW_SIZE_FRACTION, SNOW_SIZE_MIN, SNOW_SIZE_MAX)
    local snowAttachment = attach(Vector3.new(center.X, 0.3, center.Z + boxSize.Z * 0.3))
    local snow = Instance.new("ParticleEmitter")
    snow.Name = "SnowWake"
    snow.Texture = SOFT_TEXTURE_ID
    snow.Color = ColorSequence.new(Color3.fromRGB(245, 250, 255))
    snow.LightEmission = 0.1
    snow.LightInfluence = 1
    snow.Rate = 0
    snow.Lifetime = NumberRange.new(0.5, 0.8)
    snow.Speed = NumberRange.new(2, 4.5)
    snow.SpreadAngle = Vector2.new(55, 55)
    snow.EmissionDirection = Enum.NormalId.Top
    snow.Acceleration = Vector3.new(0, -6, 0)
    snow.Drag = 2
    snow.Rotation = NumberRange.new(0, 360)
    snow.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, snowSize * 0.6),
        NumberSequenceKeypoint.new(1, snowSize * 1.4),
    })
    snow.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    snow.Parent = snowAttachment
    table.insert(instances, snow)

    return {
        Model = model,
        Instances = instances,
        Trails = trails,
        Snow = snow,
        TrailKey = -1,
        SnowKey = -1,
        IsLarge = boxSize.Y >= LARGE_HEIGHT and footprint >= LARGE_FOOTPRINT,
    }
end

local function updateEffects(state, speed: number): ()
    local effects = state.Effects
    if not effects then
        return
    end

    -- Trails: short at 32-40, readable at 50+, lingering wind wake above 52.
    local trailAlpha = rampBetween(speed, TRAIL_SPEED_START, 50)
    local wakeAlpha = rampBetween(speed, WAKE_SPEED_START, SPEED_FULL)
    local trailKey = if speed < TRAIL_SPEED_START then 0 else math.floor((trailAlpha + wakeAlpha) * 20) + 1
    if trailKey ~= effects.TrailKey then
        effects.TrailKey = trailKey
        local enabled = trailKey > 0
        local lifetime = TRAIL_LIFETIME_SHORT
            + (TRAIL_LIFETIME_LONG - TRAIL_LIFETIME_SHORT) * trailAlpha
            + (WAKE_LIFETIME_MAX - TRAIL_LIFETIME_LONG) * wakeAlpha
        local head = 0.72 - 0.3 * trailAlpha
        local transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, head),
            NumberSequenceKeypoint.new(0.35, head + (1 - head) * (0.25 + 0.35 * wakeAlpha)),
            NumberSequenceKeypoint.new(1, 1),
        })
        for _, trail in effects.Trails do
            trail.Enabled = enabled
            trail.Lifetime = lifetime
            trail.Transparency = transparency
        end
    end

    -- Snow wake: 3-6 small puffs/s only while moving fast.
    local snowKey = if speed < SNOW_SPEED_START then 0 else math.floor(rampBetween(speed, SNOW_SPEED_START, SPEED_FULL) * 6) + 1
    if snowKey ~= effects.SnowKey then
        effects.SnowKey = snowKey
        effects.Snow.Rate = if snowKey == 0 then 0 else SNOW_RATE_MIN + (SNOW_RATE_MAX - SNOW_RATE_MIN) * (snowKey - 1) / 6
    end

    -- Large mounts: a restrained displacement burst on each stride downbeat (no camera effects for anyone).
    if effects.IsLarge and state.Downbeat and speed >= GROUND_RESPONSE_SPEED then
        effects.Snow:Emit(GROUND_RESPONSE_BURST)
    end
end

-- ---------- local rider: FOV, wind streaks, wind sound hook ----------
-- Prefab: StarterGui.MountSpeedWind with Streak1..StreakN frames (authored in Studio).
local function ensureWindGui(): ()
    if windGui and windGui.Parent then
        return
    end
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    local gui = if playerGui then playerGui:FindFirstChild(WIND_GUI_NAME) else nil
    if not gui or not gui:IsA("ScreenGui") then
        return
    end
    table.clear(windStreaks)
    for index = 1, WIND_STREAK_COUNT do
        local frame = gui:FindFirstChild("Streak" .. index)
        if frame and frame:IsA("Frame") then
            table.insert(windStreaks, { Frame = frame, Progress = randomSource:NextNumber(), Lifetime = 0.3, Angle = 0, Length = 80 })
        end
    end
    windGui = gui
end

local function respawnStreak(streak): ()
    -- Peripheral left/right bands only; the centre of the screen stays clean.
    local side = if randomSource:NextNumber() < 0.5 then 0 else math.pi
    streak.Angle = side + randomSource:NextNumber(-0.55, 0.55)
    streak.Lifetime = randomSource:NextNumber(WIND_STREAK_LIFETIME_MIN, WIND_STREAK_LIFETIME_MAX)
    streak.Length = randomSource:NextNumber(60, 130)
    streak.Progress = 0
end

local function updateWind(deltaTime: number, speed: number): ()
    local intensity = rampBetween(speed, WIND_SPEED_START, SPEED_FULL)
    if windSound then
        windSound.Volume = WIND_SOUND_MAX_VOLUME * intensity
    end
    if intensity <= 0.01 then
        if windGui then
            windGui.Enabled = false
        end
        return
    end
    ensureWindGui()
    local gui = windGui
    local camera = Workspace.CurrentCamera
    if not gui or not camera then
        return
    end
    gui.Enabled = true
    local viewport = camera.ViewportSize
    local center = viewport * 0.5
    local reach = math.min(viewport.X, viewport.Y)
    local thickness = if viewport.Y < 600 then 1 else 2
    for _, streak in windStreaks do
        streak.Progress += deltaTime / streak.Lifetime
        if streak.Progress >= 1 then
            respawnStreak(streak)
        end
        local direction = Vector2.new(math.cos(streak.Angle), math.sin(streak.Angle))
        local radius = reach * (0.42 + 0.45 * streak.Progress)
        local position = center + direction * radius
        local frame = streak.Frame
        frame.Position = UDim2.fromOffset(position.X, position.Y)
        frame.Size = UDim2.fromOffset(streak.Length, thickness)
        frame.Rotation = math.deg(streak.Angle)
        frame.BackgroundTransparency = 1 - WIND_STREAK_MAX_OPACITY * intensity * math.sin(math.pi * streak.Progress)
    end
end

local function startWindSound(): ()
    if WIND_SOUND_ID == "" or windSound then
        return
    end
    local sound = Instance.new("Sound")
    sound.Name = "MountWind"
    sound.SoundId = WIND_SOUND_ID
    sound.Looped = true
    sound.Volume = 0
    sound.Parent = SoundService
    sound:Play()
    windSound = sound
end

local function stopWindSound(): ()
    if windSound then
        windSound:Destroy()
        windSound = nil
    end
end

-- FOV ownership. The mount contribution is an offset over a captured TRUE baseline, and it only ever writes when
-- its value changes. Every frame it observes the camera (read-only): any change it did not make means another
-- system (e.g. the Legendary reveal punch) owns the FOV, and the mount then neither writes nor captures a baseline
-- until the FOV has been quiet for FOV_YIELD_SECONDS. The baseline is restored exactly once riding ends.
local function updateFov(deltaTime: number, riding: boolean, speed: number): ()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local now = os.clock()
    local current = camera.FieldOfView
    if fovObserved ~= nil and math.abs(current - fovObserved) > FOV_EXTERNAL_TOLERANCE then
        fovLastExternalChange = now
    end
    fovObserved = current
    if now - fovLastExternalChange < FOV_YIELD_SECONDS then
        return -- another system owns the FOV: never write, never capture a temporary value as the baseline
    end

    if riding and fovBaseline == nil then
        fovBaseline = current
        fovBoost = 0
    end
    local baseline = fovBaseline
    if baseline == nil then
        return
    end

    local target = if riding then FOV_MAX_BOOST * speedIntensity(speed) else 0
    fovBoost += (target - fovBoost) * smoothAlpha(FOV_SMOOTHING, deltaTime)
    if not riding and fovBoost < FOV_RESTORE_EPSILON then
        if current ~= baseline then
            camera.FieldOfView = baseline
        end
        fovObserved = baseline
        fovBaseline = nil
        fovBoost = 0
        return
    end
    local value = baseline + fovBoost
    if math.abs(current - value) > FOV_WRITE_STEP then
        camera.FieldOfView = value
        fovObserved = value
    end
end

-- ---------- central update ----------
local function updateRiderState(state, root: BasePart, model: Model?, deltaTime: number): ()
    local position = root.Position
    local delta = Vector3.new(position.X - state.LastPosition.X, 0, position.Z - state.LastPosition.Z)
    state.LastPosition = position
    local sampleSpeed = delta.Magnitude / deltaTime
    local previousSpeed = state.Speed
    if sampleSpeed < TELEPORT_SPEED then
        state.Speed += (sampleSpeed - state.Speed) * smoothAlpha(SPEED_SMOOTHING, deltaTime)
    end
    local speed = state.Speed
    state.Accel += ((speed - previousSpeed) / deltaTime - state.Accel) * smoothAlpha(4, deltaTime)

    local look = root.CFrame.LookVector
    local yaw = math.atan2(-look.X, -look.Z)
    local yawDelta = (yaw - state.LastYaw + math.pi) % (2 * math.pi) - math.pi
    state.LastYaw = yaw
    state.YawRate += (yawDelta / deltaTime - state.YawRate) * smoothAlpha(8, deltaTime)

    -- Size-aware stride: bigger bodies bob slower and slightly deeper.
    local height, depth = 6, 8
    if model then
        if not state.ModelSize or state.SizedModel ~= model then
            local _, size = model:GetBoundingBox()
            state.ModelSize = size
            state.SizedModel = model
        end
        height, depth = state.ModelSize.Y, state.ModelSize.Z
    end
    local stride = math.clamp(depth * STRIDE_DEPTH_FRACTION, STRIDE_MIN, STRIDE_MAX)
    local frequency = math.clamp(speed / stride, STRIDE_FREQ_MIN, STRIDE_FREQ_MAX)
    local moving = math.clamp(speed / BOB_FULL_SPEED, 0, 1)
    local previousPhase = state.Phase
    state.Phase += deltaTime * frequency * (if moving > 0.05 then 1 else 0)
    state.Downbeat = math.floor(state.Phase) ~= math.floor(previousPhase)

    local alpha = smoothAlpha(MOTION_SMOOTHING, deltaTime)
    state.Moving += (moving - state.Moving) * alpha
    local bobAmplitude = math.clamp(height * BOB_HEIGHT_FRACTION, BOB_MIN, BOB_MAX)
    state.Bob = bobAmplitude * state.Moving * math.abs(math.sin(math.pi * state.Phase))

    local intensity = speedIntensity(speed)
    local leanTarget = math.clamp(speed * state.YawRate * LEAN_PER_SPEED_TURN, -MAX_LEAN_DEGREES, MAX_LEAN_DEGREES)
        * math.clamp(speed / 16, 0, 1)
    local pitchTarget = -(CRUISE_PITCH_DEGREES * (0.3 * state.Moving + 0.7 * intensity))
        - math.clamp(state.Accel * ACCEL_PITCH_PER_STUD, -2, 2)
        + ROCK_DEGREES * state.Moving * math.sin(2 * math.pi * state.Phase)
    pitchTarget = math.clamp(pitchTarget, -MAX_PITCH_DOWN_DEGREES, MAX_PITCH_UP_DEGREES)
    state.Lean += (leanTarget - state.Lean) * alpha
    state.Pitch += (pitchTarget - state.Pitch) * alpha
end

local function onHeartbeat(deltaTime: number): ()
    if deltaTime <= 0 then
        return
    end
    local camera = Workspace.CurrentCamera
    local cameraPosition = if camera then camera.CFrame.Position else Vector3.zero

    local candidates = {}
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local riding = player:GetAttribute(MOUNT_STATE_ATTRIBUTE) == RIDING_STATE
        local state = riderStates[player]
        if not riding or not root or not root:IsA("BasePart") then
            if state then
                destroyEffects(state)
                riderStates[player] = nil
            end
            continue
        end

        if not state then
            local look = root.CFrame.LookVector
            state = {
                LastPosition = root.Position,
                LastYaw = math.atan2(-look.X, -look.Z),
                Speed = 0,
                Accel = 0,
                YawRate = 0,
                Phase = 0,
                Moving = 0,
                Bob = 0,
                Lean = 0,
                Pitch = 0,
                Downbeat = false,
                Effects = nil,
            }
            riderStates[player] = state
        end

        local model = CreatureVisualController.GetMountModel(player)
        updateRiderState(state, root, model, deltaTime)

        if state.Effects and state.Effects.Model ~= model then
            destroyEffects(state) -- the clone was rebuilt; its children went with it
        end
        if model then
            table.insert(candidates, {
                Player = player,
                State = state,
                Model = model,
                Distance = if player == localPlayer then -1 else (root.Position - cameraPosition).Magnitude,
            })
        end
    end

    -- Observer culling: the local rider plus the nearest remote riders in range.
    table.sort(candidates, function(a, b)
        return a.Distance < b.Distance
    end)
    local remoteCount = 0
    for _, candidate in candidates do
        local active = candidate.Distance < 0
        if not active and candidate.Distance <= REMOTE_EFFECT_RANGE and remoteCount < MAX_REMOTE_EFFECT_RIDERS then
            remoteCount += 1
            active = true
        end
        local state = candidate.State
        if active then
            if not state.Effects then
                state.Effects = createEffects(state, candidate.Model)
            end
            updateEffects(state, state.Speed)
        elseif state.Effects then
            destroyEffects(state)
        end
    end

    -- Local rider senses
    local localState = riderStates[localPlayer]
    local localRiding = localState ~= nil
    local localSpeed = if localState then localState.Speed else 0
    updateFov(deltaTime, localRiding, localSpeed)
    if localRiding then
        startWindSound()
        updateWind(deltaTime, localSpeed)
    else
        stopWindSound()
        if windGui then
            windGui.Enabled = false
        end
    end
end

function MountSpeedController.Start(): ()
    if started then
        return
    end
    started = true

    CreatureVisualController.SetMountMotionProvider(mountMotion)
    RunService.Heartbeat:Connect(onHeartbeat)
    Players.PlayerRemoving:Connect(function(player)
        local state = riderStates[player]
        if state then
            destroyEffects(state)
            riderStates[player] = nil
        end
    end)
end

return MountSpeedController
