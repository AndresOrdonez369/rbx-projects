local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local PenConfig = require(shared:WaitForChild("PenConfig"))
local WarmthConfig = require(shared:WaitForChild("WarmthConfig"))

local OwnBaseController = require(script.Parent.OwnBaseController)

-- "Bring it home" (GDD Hero Moment 3, the barely-made-it-home run). While the local player carries Ice, everything
-- Carrier Commitment makes unusable slides away, the Warmth bar takes over with a time-left estimate, a compass and a
-- light pillar point at the own Pen, and frost/wind escalate as Warmth drops. Entering Home Camp plays SAFE! (or
-- CLOSE ONE!). Presentation only: no gameplay rule, timing or request changes here.
local CarryModeController = {}

-- Prefabs: StarterGui.CarryModeFx, StarterGui.MainHud (TopCenter.CarryInfo, WarmthPanel.Emphasis) and
-- ReplicatedStorage.UITemplates.PenBeacon, all authored in Studio.
local HUD_NAME = "MainHud"
local FX_NAME = "CarryModeFx"
local BEACON_TEMPLATE_NAME = "PenBeacon"
local ICE_INSTANCE_ID_ATTRIBUTE = "IceInstanceID"
local HOME_SAFE_ZONE_NAME = "HomeCampSafeZone"
local PEN_LEVEL_ATTRIBUTE = "PenLevel"
local DAY_PHASE = "Day"
local GREAT_FROST_PHASE = "GreatFrost"

-- Clusters hidden while carrying (all unusable under Carrier Commitment) and the direction each slides out to.
local HIDDEN_CLUSTERS = {
    LeftRail = Vector2.new(-1, 0),
    RightRail = Vector2.new(1, 0),
    BottomLeft = Vector2.new(0, 1),
    BottomRight = Vector2.new(0, 1),
}
local SLIDE_DISTANCE = 0.4
local SLIDE_OUT_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SLIDE_IN_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local MOUNT_HIT_REVEAL_SECONDS = 2.5

local EMPHASIS_SCALE = 1.12
local EMPHASIS_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_IN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_OUT_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BANNER_HOLD_SECONDS = 1.8
local ARRIVAL_HOLD_SECONDS = 1.8
local ARRIVAL_COOLDOWN_SECONDS = 6
local ARRIVAL_RAYS_SPEED = 25 -- degrees per second
local FLASH_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_START_TRANSPARENCY = 0.55

-- Pressure stages by CurrentWarmth / MaxWarmth while outside Home Camp.
local COLD_RATIO = 0.5
local CRITICAL_RATIO = 0.25
local CLOSE_CALL_RATIO = 0.15
local FROST_EDGE_TRANSPARENCY = { Calm = 0.72, Cold = 0.45, Critical = 0.22, Safe = 1 }
local FROST_EDGE_INFO = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local CRITICAL_PULSE_AMPLITUDE = 0.1
local CRITICAL_PULSE_SPEED = 5
local CRITICAL_SHAKE_DEGREES = 1.6
local CRITICAL_SHAKE_SPEED = 38
local FROST_WARNING_SECONDS = 30
-- The time-left estimate uses the Warmth lost over a short window, so one hit only skews it briefly.
local RATE_WINDOW_SECONDS = 4
local MIN_RATE_SPAN_SECONDS = 0.5
local INFO_REFRESH_SECONDS = 0.2
local ETA_DISPLAY_MAX_SECONDS = 300 -- beyond this the estimate is noise; show a plain instruction instead

-- Wind streaks (Cold and Critical).
local WIND_SPEED = 1.6 -- viewport widths per second
local WIND_SLANT = 0.18
local WIND_TRANSPARENCY = { Cold = 0.55, Critical = 0.3 }

-- Compass: kept inside these viewport margins; hidden while the Pen itself is comfortably on screen.
local COMPASS_MARGIN_X = 0.1
local COMPASS_MARGIN_TOP = 0.2
local COMPASS_MARGIN_BOTTOM = 0.3
local COMPASS_PULSE_AMPLITUDE = 0.06
local COMPASS_PULSE_SPEED = 4
local PEN_TARGET_HEIGHT = 6

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local started = false

type ClusterState = { Frame: GuiObject, Base: UDim2?, Revision: number }

local function getCarriedIce(): BasePart?
    local character = localPlayer.Character
    if not character then
        return nil
    end
    for _, child in character:GetChildren() do
        if child:IsA("BasePart") and child:GetAttribute(ICE_INSTANCE_ID_ATTRIBUTE) ~= nil then
            return child
        end
    end
    return nil
end

local function isInsideHomeCamp(): boolean
    local zone = Workspace:FindFirstChild(HOME_SAFE_ZONE_NAME)
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not zone or not zone:IsA("BasePart") or not root or not root:IsA("BasePart") then
        return false
    end
    local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
    local halfSize = zone.Size * 0.5
    return math.abs(localPosition.X) <= halfSize.X
        and math.abs(localPosition.Y) <= halfSize.Y
        and math.abs(localPosition.Z) <= halfSize.Z
end

local function formatClock(seconds: number): string
    local whole = math.max(0, math.floor(seconds + 0.5))
    return string.format("%d:%02d", whole // 60, whole % 60)
end

local function formatMultiplier(value: number): string
    return if value % 1 == 0 then string.format("%d", value) else string.format("%.1f", value)
end

local function getPenTarget(base: Instance): Vector3?
    local pen = base:FindFirstChild("Pen")
    local origin = pen and pen:FindFirstChild("PenOrigin")
    if not origin or not origin:IsA("BasePart") then
        return nil
    end
    local level = base:GetAttribute(PEN_LEVEL_ATTRIBUTE)
    local depth = PenConfig.Levels[if PenConfig.IsValidLevel(level) then level else 1].Depth
    return origin.CFrame:PointToWorldSpace(Vector3.new(0, 0, depth * 0.5))
end

function CarryModeController.Start(): ()
    if started then
        return
    end
    started = true

    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local hud = playerGui:WaitForChild(HUD_NAME)
    local fx = playerGui:WaitForChild(FX_NAME)
    local top = hud:WaitForChild("TopCenter")
    local warmthPanel = top:WaitForChild("WarmthPanel") :: GuiObject
    local emphasis = warmthPanel:WaitForChild("Emphasis") :: UIScale
    local carryInfo = top:WaitForChild("CarryInfo") :: GuiObject
    local drainChip = carryInfo:WaitForChild("DrainChip") :: TextLabel
    local etaLabel = carryInfo:WaitForChild("Eta") :: TextLabel
    local frostChip = carryInfo:WaitForChild("FrostChip") :: TextLabel
    local toolSlot = hud:WaitForChild("BottomCenter"):WaitForChild("ToolSlot") :: GuiObject
    local frostEdges = fx:WaitForChild("FrostEdges") :: ImageLabel
    local warmFlash = fx:WaitForChild("WarmFlash") :: Frame
    local wind = fx:WaitForChild("Wind") :: GuiObject
    local banner = fx:WaitForChild("Banner") :: GuiObject
    local bannerPop = banner:WaitForChild("Body"):WaitForChild("Pop") :: UIScale
    local compass = fx:WaitForChild("Compass") :: GuiObject
    local compassBadge = compass:WaitForChild("Badge")
    local compassPulse = compassBadge:WaitForChild("Pulse") :: UIScale
    local compassArrow = compassBadge:WaitForChild("Arrow") :: ImageLabel
    local compassDistance = compass:WaitForChild("Distance") :: TextLabel
    local arrival = fx:WaitForChild("Arrival") :: GuiObject
    local arrivalBody = arrival:WaitForChild("Body")
    local arrivalPop = arrivalBody:WaitForChild("Pop") :: UIScale
    local arrivalRays = arrivalBody:WaitForChild("Rays") :: ImageLabel
    local arrivalTitle = arrivalBody:WaitForChild("Title") :: TextLabel
    local arrivalSub = arrivalBody:WaitForChild("Sub") :: TextLabel
    local beaconTemplate = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild(BEACON_TEMPLATE_NAME) :: Model

    local clusters: { [string]: ClusterState } = {}
    for name in HIDDEN_CLUSTERS do
        clusters[name] = { Frame = hud:WaitForChild(name) :: GuiObject, Base = nil, Revision = 0 }
    end

    local streaks: { { Frame: GuiObject, X: number, Y: number, Speed: number } } = {}
    for _, child in wind:GetChildren() do
        if child:IsA("GuiObject") then
            table.insert(streaks, { Frame = child, X = math.random(), Y = math.random(), Speed = 0.7 + math.random() * 0.6 })
        end
    end

    local ownBase: Instance? = nil
    task.spawn(function()
        ownBase = OwnBaseController.WaitForOwnBase()
    end)

    local active = false
    local inCamp = false
    local stage = "Safe"
    local warmthRatio = 1
    local currentWarmth: number? = nil
    local drainRate = 0
    local warmthSamples: { { At: number, Warmth: number } } = {}
    local cyclePhase: string? = nil
    local nextTransitionUnix: number? = nil
    local lastArrivalAt = -math.huge
    local infoElapsed = 0
    local beacon: Model? = nil
    local frostTween: Tween? = nil
    local bannerRevision = 0
    local arrivalRevision = 0

    local function slideCluster(name: string, hide: boolean): ()
        local state = clusters[name]
        local frame = state.Frame
        state.Revision += 1
        local revision = state.Revision
        if hide then
            if state.Base == nil then
                state.Base = frame.Position
            end
            local base = state.Base :: UDim2
            local direction = HIDDEN_CLUSTERS[name]
            local tween = TweenService:Create(frame, SLIDE_OUT_INFO, {
                Position = base + UDim2.fromScale(direction.X * SLIDE_DISTANCE, direction.Y * SLIDE_DISTANCE),
            })
            tween.Completed:Connect(function()
                if state.Revision == revision then
                    frame.Visible = false
                end
            end)
            tween:Play()
        elseif state.Base ~= nil then
            frame.Visible = true
            TweenService:Create(frame, SLIDE_IN_INFO, { Position = state.Base }):Play()
        end
    end

    local function popOut(container: GuiObject, pop: UIScale, revisionCheck: () -> boolean): ()
        local tween = TweenService:Create(pop, POP_OUT_INFO, { Scale = 0 })
        tween.Completed:Connect(function()
            if revisionCheck() then
                container.Visible = false
            end
        end)
        tween:Play()
    end

    local function setFrostEdges(target: number): ()
        if frostTween then
            frostTween:Cancel()
        end
        frostTween = TweenService:Create(frostEdges, FROST_EDGE_INFO, { ImageTransparency = target })
        frostTween:Play()
    end

    local function computeStage(): string
        if not active or inCamp then
            return "Safe"
        elseif warmthRatio <= CRITICAL_RATIO then
            return "Critical"
        elseif warmthRatio <= COLD_RATIO then
            return "Cold"
        end
        return "Calm"
    end

    local function applyStage(): ()
        local nextStage = computeStage()
        if nextStage == stage then
            return
        end
        stage = nextStage
        setFrostEdges(FROST_EDGE_TRANSPARENCY[stage])
        wind.Visible = stage == "Cold" or stage == "Critical"
        if stage ~= "Critical" then
            warmthPanel.Rotation = 0
        end
    end

    local function refreshInfo(): ()
        if not active then
            return
        end
        if inCamp then
            drainChip.Visible = false
            etaLabel.Text = "SAFE IN CAMP · PLACE IT IN YOUR PEN"
        else
            drainChip.Visible = true
            drainChip.Text = "×" .. formatMultiplier(WarmthConfig.CarryDrainMultiplier)
            local secondsLeft = if currentWarmth and drainRate > 0 then currentWarmth / drainRate else math.huge
            etaLabel.Text = if secondsLeft <= ETA_DISPLAY_MAX_SECONDS
                then string.format("~%s OF WARMTH LEFT", formatClock(secondsLeft))
                else "HEAD HOME"
        end

        local remaining = if nextTransitionUnix then nextTransitionUnix - Workspace:GetServerTimeNow() else nil
        if cyclePhase == GREAT_FROST_PHASE then
            frostChip.Visible = true
            frostChip.Text = "GREAT FROST NOW"
        elseif cyclePhase == DAY_PHASE and remaining and remaining <= FROST_WARNING_SECONDS then
            frostChip.Visible = true
            frostChip.Text = string.format("GREAT FROST IN %s", formatClock(remaining))
        else
            frostChip.Visible = false
        end
    end

    local function showBanner(): ()
        bannerRevision += 1
        local revision = bannerRevision
        banner.Visible = true
        bannerPop.Scale = 0.5
        TweenService:Create(bannerPop, POP_IN_INFO, { Scale = 1 }):Play()
        task.delay(BANNER_HOLD_SECONDS, function()
            if bannerRevision == revision then
                popOut(banner, bannerPop, function()
                    return bannerRevision == revision
                end)
            end
        end)
    end

    local function playArrival(): ()
        local now = os.clock()
        if now - lastArrivalAt < ARRIVAL_COOLDOWN_SECONDS then
            return
        end
        lastArrivalAt = now
        arrivalRevision += 1
        local revision = arrivalRevision
        local closeCall = warmthRatio <= CLOSE_CALL_RATIO
        arrivalTitle.Text = if closeCall then "CLOSE ONE!" else "SAFE!"
        arrivalSub.Text = if closeCall then "THAT WAS WAY TOO COLD" else "THE ICE MADE IT HOME"
        arrival.Visible = true
        arrivalPop.Scale = 0.4
        TweenService:Create(arrivalPop, POP_IN_INFO, { Scale = 1 }):Play()
        warmFlash.BackgroundTransparency = FLASH_START_TRANSPARENCY
        TweenService:Create(warmFlash, FLASH_INFO, { BackgroundTransparency = 1 }):Play()
        task.delay(ARRIVAL_HOLD_SECONDS, function()
            if arrivalRevision == revision then
                popOut(arrival, arrivalPop, function()
                    return arrivalRevision == revision
                end)
            end
        end)
    end

    local function destroyBeacon(): ()
        if beacon then
            beacon:Destroy()
            beacon = nil
        end
    end

    local function enter(): ()
        active = true
        inCamp = isInsideHomeCamp()
        for name in HIDDEN_CLUSTERS do
            slideCluster(name, true)
        end
        toolSlot.Visible = false
        carryInfo.Visible = true
        TweenService:Create(emphasis, EMPHASIS_INFO, { Scale = EMPHASIS_SCALE }):Play()
        drainRate = 0
        table.clear(warmthSamples)
        refreshInfo()
        applyStage()
        showBanner()

        destroyBeacon()
        local base = ownBase
        local target = if base then getPenTarget(base) else nil
        if target then
            local clone = beaconTemplate:Clone()
            clone:PivotTo(CFrame.new(target))
            clone.Parent = Workspace
            beacon = clone
        end
    end

    local function exit(): ()
        active = false
        for name in HIDDEN_CLUSTERS do
            slideCluster(name, false)
        end
        toolSlot.Visible = true
        carryInfo.Visible = false
        TweenService:Create(emphasis, EMPHASIS_INFO, { Scale = 1 }):Play()
        warmthPanel.Rotation = 0
        compass.Visible = false
        bannerRevision += 1
        banner.Visible = false
        applyStage()
        destroyBeacon()
    end

    local function refreshCarry(): ()
        local carrying = getCarriedIce() ~= nil
        if carrying and not active then
            enter()
        elseif not carrying and active then
            exit()
        end
    end

    local function updateCompass(): ()
        local camera = Workspace.CurrentCamera
        local base = ownBase
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local target = if base then getPenTarget(base) else nil
        if not camera or not target or not root or not root:IsA("BasePart") then
            compass.Visible = false
            return
        end

        local viewport = camera.ViewportSize
        local aim = target + Vector3.new(0, PEN_TARGET_HEIGHT, 0)
        local point, onScreen = camera:WorldToViewportPoint(aim)
        local marginX = viewport.X * COMPASS_MARGIN_X
        local minY = viewport.Y * COMPASS_MARGIN_TOP
        local maxY = viewport.Y * (1 - COMPASS_MARGIN_BOTTOM)
        if onScreen and point.X > marginX and point.X < viewport.X - marginX and point.Y > minY and point.Y < maxY then
            compass.Visible = false
            return
        end

        local center = Vector2.new(viewport.X * 0.5, (minY + maxY) * 0.5)
        local direction = Vector2.new(point.X, point.Y) - center
        if point.Z < 0 then
            direction = -direction
        end
        if direction.Magnitude < 1e-3 then
            direction = Vector2.new(0, -1)
        end
        direction = direction.Unit
        local radiusX = viewport.X * 0.5 - marginX
        local radiusY = (maxY - minY) * 0.5
        local reach = math.min(
            if math.abs(direction.X) > 1e-3 then radiusX / math.abs(direction.X) else math.huge,
            if math.abs(direction.Y) > 1e-3 then radiusY / math.abs(direction.Y) else math.huge
        )
        local position = center + direction * reach

        compass.Visible = true
        compass.Position = UDim2.fromOffset(position.X, position.Y)
        compassArrow.Rotation = math.deg(math.atan2(direction.X, -direction.Y))
        compassPulse.Scale = 1 + COMPASS_PULSE_AMPLITUDE * math.sin(os.clock() * COMPASS_PULSE_SPEED)
        local distance = (Vector3.new(target.X, 0, target.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
        compassDistance.Text = string.format("PEN · %dm", math.floor(distance + 0.5))
    end

    local function updateWind(deltaTime: number): ()
        if not wind.Visible then
            return
        end
        local transparency = WIND_TRANSPARENCY[stage] or 1
        for _, streak in streaks do
            streak.X += WIND_SPEED * streak.Speed * deltaTime
            streak.Y += WIND_SLANT * streak.Speed * deltaTime
            if streak.X > 1.15 or streak.Y > 1.1 then
                streak.X = -0.15
                streak.Y = math.random() * 0.9
            end
            streak.Frame.Position = UDim2.fromScale(streak.X, streak.Y)
            streak.Frame.Rotation = math.deg(math.atan2(WIND_SLANT, WIND_SPEED))
            streak.Frame.BackgroundTransparency = transparency
        end
    end

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "WarmthUpdated" then
            if type(data) ~= "table" or type(data.CurrentWarmth) ~= "number" or type(data.MaxWarmth) ~= "number" or data.MaxWarmth <= 0 then
                return
            end
            local now = os.clock()
            local newest = warmthSamples[#warmthSamples]
            if newest and data.CurrentWarmth > newest.Warmth then
                -- Refilling (Warm Zone / respawn): the old window no longer describes a drain.
                table.clear(warmthSamples)
            end
            table.insert(warmthSamples, { At = now, Warmth = data.CurrentWarmth })
            while #warmthSamples > 2 and now - warmthSamples[1].At > RATE_WINDOW_SECONDS do
                table.remove(warmthSamples, 1)
            end
            local oldest = warmthSamples[1]
            local span = now - oldest.At
            drainRate = if span >= MIN_RATE_SPAN_SECONDS then math.max(0, (oldest.Warmth - data.CurrentWarmth) / span) else 0
            currentWarmth = data.CurrentWarmth
            warmthRatio = math.clamp(data.CurrentWarmth / data.MaxWarmth, 0, 1)
            applyStage()
        elseif eventName == "WorldCycleUpdated" then
            if type(data) == "table" and type(data.CurrentPhase) == "string" and type(data.NextTransitionUnix) == "number" then
                cyclePhase = data.CurrentPhase
                nextTransitionUnix = data.NextTransitionUnix
            end
        elseif eventName == "SurvivalFeedback" and active and type(data) == "table" and data.Kind == "CreatureHit" then
            -- The one exception: a hit on the mount briefly brings its card back.
            slideCluster("RightRail", false)
            task.delay(MOUNT_HIT_REVEAL_SECONDS, function()
                if active then
                    slideCluster("RightRail", true)
                end
            end)
        end
    end)

    RunService.RenderStepped:Connect(function(deltaTime)
        if not active then
            return
        end

        local nowInCamp = isInsideHomeCamp()
        if nowInCamp ~= inCamp then
            inCamp = nowInCamp
            if inCamp then
                playArrival()
            end
            applyStage()
            refreshInfo()
        end

        infoElapsed += deltaTime
        if infoElapsed >= INFO_REFRESH_SECONDS then
            infoElapsed = 0
            refreshInfo()
        end

        if stage == "Critical" then
            local t = os.clock()
            frostEdges.ImageTransparency = FROST_EDGE_TRANSPARENCY.Critical + CRITICAL_PULSE_AMPLITUDE * math.sin(t * CRITICAL_PULSE_SPEED)
            warmthPanel.Rotation = CRITICAL_SHAKE_DEGREES * math.sin(t * CRITICAL_SHAKE_SPEED)
        end

        if arrival.Visible then
            arrivalRays.Rotation += ARRIVAL_RAYS_SPEED * deltaTime
        end

        updateWind(deltaTime)
        updateCompass()
    end)

    local function watchCharacter(character: Model): ()
        character.ChildAdded:Connect(refreshCarry)
        character.ChildRemoved:Connect(refreshCarry)
        refreshCarry()
    end
    localPlayer.CharacterAdded:Connect(watchCharacter)
    localPlayer.CharacterRemoving:Connect(function()
        if active then
            exit()
        end
    end)
    if localPlayer.Character then
        watchCharacter(localPlayer.Character)
    end
end

return CarryModeController
