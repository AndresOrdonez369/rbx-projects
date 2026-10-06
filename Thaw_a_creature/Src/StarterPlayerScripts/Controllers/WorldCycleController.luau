local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WorldCycleController = {}

local HUD_NAME = "WorldCycleHud"
local FROST_COLOR_EFFECT_NAME = "PrototypeGreatFrostColor"
local FROST_SOUND_NAME = "PrototypeGreatFrostStart"
local FROST_SOUND_ID = "rbxasset://sounds/impact_water.mp3"
local DAY_PHASE = "Day"
local GREAT_FROST_PHASE = "GreatFrost"
local VISUAL_TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BANNER_FADE_IN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BANNER_FADE_OUT_INFO = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BANNER_HOLD_DURATION = 1.4

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

type WorldCycleSnapshot = {
    CurrentPhase: string,
    CycleIndex: number,
    PhaseEndsAtTime: number,
}

local started = false
local currentSnapshot: WorldCycleSnapshot? = nil
local lastDisplayedPhase: string? = nil
local lastDisplayedSeconds: number? = nil
local colorTween: Tween? = nil
local bannerSequence = 0

local function createHud(): (TextLabel, TextLabel)
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

    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.AnchorPoint = Vector2.new(0.5, 0)
    countdownLabel.Position = UDim2.new(0.5, 0, 0, 24)
    countdownLabel.Size = UDim2.fromOffset(220, 72)
    countdownLabel.BackgroundColor3 = Color3.fromRGB(20, 25, 32)
    countdownLabel.BackgroundTransparency = 0.2
    countdownLabel.BorderSizePixel = 0
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.Text = "GREAT FROST IN\n--:--"
    countdownLabel.TextColor3 = Color3.fromRGB(235, 249, 255)
    countdownLabel.TextSize = 24
    countdownLabel.TextStrokeTransparency = 0.75
    countdownLabel.Parent = screenGui

    local frostBanner = Instance.new("TextLabel")
    frostBanner.Name = "FrostBanner"
    frostBanner.AnchorPoint = Vector2.new(0.5, 0.5)
    frostBanner.Position = UDim2.fromScale(0.5, 0.32)
    frostBanner.Size = UDim2.fromOffset(480, 88)
    frostBanner.BackgroundColor3 = Color3.fromRGB(20, 48, 72)
    frostBanner.BackgroundTransparency = 1
    frostBanner.BorderSizePixel = 0
    frostBanner.Font = Enum.Font.GothamBlack
    frostBanner.Text = "GREAT FROST"
    frostBanner.TextColor3 = Color3.fromRGB(220, 248, 255)
    frostBanner.TextSize = 42
    frostBanner.TextStrokeColor3 = Color3.fromRGB(40, 92, 130)
    frostBanner.TextStrokeTransparency = 1
    frostBanner.TextTransparency = 1
    frostBanner.Visible = false
    frostBanner.Parent = screenGui

    return countdownLabel, frostBanner
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

local function createFrostSound(): Sound
    local existingSound = SoundService:FindFirstChild(FROST_SOUND_NAME)
    if existingSound then
        assert(existingSound:IsA("Sound"), "SoundService.PrototypeGreatFrostStart must be a Sound")
        return existingSound
    end

    local frostSound = Instance.new("Sound")
    frostSound.Name = FROST_SOUND_NAME
    frostSound.SoundId = FROST_SOUND_ID
    frostSound.Looped = false
    frostSound.Volume = 0.55
    frostSound.PlaybackSpeed = 0.8
    frostSound.Parent = SoundService

    return frostSound
end

local function setFrostVisual(colorEffect: ColorCorrectionEffect, isFrost: boolean): ()
    if colorTween then
        colorTween:Cancel()
    end

    colorTween = TweenService:Create(
        colorEffect,
        VISUAL_TWEEN_INFO,
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

local function showFrostBanner(frostBanner: TextLabel): ()
    bannerSequence += 1
    local activeSequence = bannerSequence

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

local function applyPhasePresentation(
    colorEffect: ColorCorrectionEffect,
    frostSound: Sound,
    frostBanner: TextLabel,
    phase: string,
    previousPhase: string?
): ()
    if phase == GREAT_FROST_PHASE then
        setFrostVisual(colorEffect, true)

        if previousPhase == DAY_PHASE then
            frostSound.TimePosition = 0
            frostSound:Play()
            showFrostBanner(frostBanner)
        end
        return
    end

    setFrostVisual(colorEffect, false)
    hideFrostBanner(frostBanner)
    frostSound:Stop()
end

local function formatDuration(seconds: number): string
    local wholeSeconds = math.max(0, math.ceil(seconds))
    local minutes = math.floor(wholeSeconds / 60)
    local remainingSeconds = wholeSeconds % 60

    return string.format("%d:%02d", minutes, remainingSeconds)
end

local function isValidSnapshot(data: any): boolean
    return type(data) == "table"
        and (data.CurrentPhase == DAY_PHASE or data.CurrentPhase == GREAT_FROST_PHASE)
        and type(data.CycleIndex) == "number"
        and data.CycleIndex >= 0
        and data.CycleIndex % 1 == 0
        and type(data.PhaseEndsAtTime) == "number"
end

local function updateHud(countdownLabel: TextLabel): ()
    local snapshot = currentSnapshot
    if not snapshot then
        return
    end

    local wholeSeconds = math.max(0, math.ceil(snapshot.PhaseEndsAtTime - Workspace:GetServerTimeNow()))
    if snapshot.CurrentPhase == lastDisplayedPhase and wholeSeconds == lastDisplayedSeconds then
        return
    end

    lastDisplayedPhase = snapshot.CurrentPhase
    lastDisplayedSeconds = wholeSeconds

    local heading = if snapshot.CurrentPhase == GREAT_FROST_PHASE
        then "GREAT FROST"
        else "GREAT FROST IN"
    countdownLabel.Text = heading .. "\n" .. formatDuration(wholeSeconds)
end

function WorldCycleController.Start(): ()
    if started then
        return
    end
    started = true

    local countdownLabel, frostBanner = createHud()
    local colorEffect = createColorEffect()
    local frostSound = createFrostSound()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName ~= "WorldCycleUpdated" or not isValidSnapshot(data) then
            return
        end

        local previousPhase = if currentSnapshot then currentSnapshot.CurrentPhase else nil
        local nextSnapshot = {
            CurrentPhase = data.CurrentPhase,
            CycleIndex = data.CycleIndex,
            PhaseEndsAtTime = data.PhaseEndsAtTime,
        }
        currentSnapshot = nextSnapshot

        if previousPhase ~= nextSnapshot.CurrentPhase then
            applyPhasePresentation(
                colorEffect,
                frostSound,
                frostBanner,
                nextSnapshot.CurrentPhase,
                previousPhase
            )
        end
        updateHud(countdownLabel)
    end)

    RunService.Heartbeat:Connect(function()
        updateHud(countdownLabel)
    end)
end

return WorldCycleController
