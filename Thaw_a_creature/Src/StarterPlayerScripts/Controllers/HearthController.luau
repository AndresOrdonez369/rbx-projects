local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OwnBaseController = require(script.Parent.OwnBaseController)

local HearthController = {}

local PRESENTATION_NAME = "HearthPresentation"
local WARM_ZONE_PRESENTATION_NAME = "WarmZonePresentation"
local EMBER_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

type StageStyle = {
    OuterSize: Vector3,
    CoreSize: Vector3,
    FireSize: number,
    FireHeat: number,
    LightBrightness: number,
    LightRange: number,
    SmokeOpacity: number,
    SmokeSize: number,
    SmokeRiseVelocity: number,
    EmberRate: number,
    EmberSpeed: NumberRange,
    PostHeight: number,
    PostWidth: number,
    RuneRadius: number,
    RuneTransparency: number,
    OuterColor: Color3,
    CoreColor: Color3,
    LightColor: Color3,
    RuneColor: Color3,
}

type Presentation = {
    Billboard: BillboardGui,
    FireOuter: BasePart,
    FireCore: BasePart,
    Flame: Fire,
    Light: PointLight,
    Smoke: Smoke,
    Embers: ParticleEmitter,
    Posts: { BasePart },
    Runes: { BasePart },
    LevelLabel: TextLabel,
    StageLabel: TextLabel,
    TrainingLabel: TextLabel,
    UpgradeLabel: TextLabel,
}

local function stageStyle(
    outerSize: Vector3,
    coreSize: Vector3,
    fireSize: number,
    fireHeat: number,
    lightBrightness: number,
    lightRange: number,
    smokeOpacity: number,
    smokeSize: number,
    smokeRiseVelocity: number,
    emberRate: number,
    emberSpeed: NumberRange,
    postHeight: number,
    postWidth: number,
    runeRadius: number,
    runeTransparency: number,
    outerColor: Color3,
    coreColor: Color3,
    lightColor: Color3,
    runeColor: Color3
): StageStyle
    return {
        OuterSize = outerSize,
        CoreSize = coreSize,
        FireSize = fireSize,
        FireHeat = fireHeat,
        LightBrightness = lightBrightness,
        LightRange = lightRange,
        SmokeOpacity = smokeOpacity,
        SmokeSize = smokeSize,
        SmokeRiseVelocity = smokeRiseVelocity,
        EmberRate = emberRate,
        EmberSpeed = emberSpeed,
        PostHeight = postHeight,
        PostWidth = postWidth,
        RuneRadius = runeRadius,
        RuneTransparency = runeTransparency,
        OuterColor = outerColor,
        CoreColor = coreColor,
        LightColor = lightColor,
        RuneColor = runeColor,
    }
end

local STAGE_STYLES: { [number]: StageStyle } = {
    [1] = stageStyle(
        Vector3.new(2.8, 3.2, 2.8), Vector3.new(1.4, 2.2, 1.4),
        4, 5, 1.6, 18, 0.05, 2.5, 2, 3, NumberRange.new(3, 5), 0, 0.55, 0, 1,
        Color3.fromRGB(255, 82, 18), Color3.fromRGB(255, 213, 62),
        Color3.fromRGB(255, 151, 62), Color3.fromRGB(255, 177, 68)
    ),
    [2] = stageStyle(
        Vector3.new(3.4, 4.1, 3.4), Vector3.new(1.8, 3, 1.8),
        5, 6, 2.1, 21, 0.07, 3, 2.3, 5, NumberRange.new(3.5, 5.5), 0, 0.6, 0, 1,
        Color3.fromRGB(255, 91, 20), Color3.fromRGB(255, 220, 70),
        Color3.fromRGB(255, 157, 66), Color3.fromRGB(255, 183, 72)
    ),
    [3] = stageStyle(
        Vector3.new(4.2, 5.2, 4.2), Vector3.new(2.2, 3.8, 2.2),
        7, 8, 2.8, 24, 0.09, 3.6, 2.6, 7, NumberRange.new(4, 6), 2.4, 0.68, 0, 1,
        Color3.fromRGB(255, 98, 22), Color3.fromRGB(255, 226, 78),
        Color3.fromRGB(255, 164, 70), Color3.fromRGB(255, 190, 78)
    ),
    [4] = stageStyle(
        Vector3.new(4.8, 6.3, 4.8), Vector3.new(2.5, 4.7, 2.5),
        8.5, 10, 3.6, 28, 0.11, 4.2, 3, 10, NumberRange.new(4.5, 6.5), 3.1, 0.76, 5.1, 0.28,
        Color3.fromRGB(255, 105, 24), Color3.fromRGB(255, 232, 88),
        Color3.fromRGB(255, 171, 74), Color3.fromRGB(255, 196, 82)
    ),
    [5] = stageStyle(
        Vector3.new(5.7, 7.6, 5.7), Vector3.new(3, 5.6, 3),
        10.5, 12, 4.7, 33, 0.13, 4.8, 3.4, 13, NumberRange.new(5, 7.5), 4, 0.86, 5.8, 0.18,
        Color3.fromRGB(102, 203, 255), Color3.fromRGB(255, 225, 126),
        Color3.fromRGB(255, 184, 104), Color3.fromRGB(104, 222, 255)
    ),
    [6] = stageStyle(
        Vector3.new(6.6, 9, 6.6), Vector3.new(3.6, 6.8, 3.6),
        13, 15, 6, 38, 0.15, 5.5, 3.8, 16, NumberRange.new(5.5, 8.5), 5, 0.96, 6.6, 0.08,
        Color3.fromRGB(86, 215, 255), Color3.fromRGB(255, 238, 158),
        Color3.fromRGB(255, 199, 130), Color3.fromRGB(126, 235, 255)
    ),
}

local started = false
local presentation: Presentation? = nil

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")
assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local function formatInteger(value: number): string
    local digits = tostring(value)
    local parts = {}

    while #digits > 3 do
        table.insert(parts, 1, string.sub(digits, -3))
        digits = string.sub(digits, 1, -4)
    end

    table.insert(parts, 1, digits)
    return table.concat(parts, ",")
end

local function createSafePart(name: string, parent: Instance): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Parent = parent
    return part
end

local function createBillboardLabel(name: string, position: UDim2, size: UDim2, color: Color3): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = color
    label.TextScaled = true
    label.TextStrokeColor3 = Color3.fromRGB(20, 10, 4)
    label.TextStrokeTransparency = 0.2
    return label
end

local function createWarmZonePresentation(warmZone: BasePart): ()
    local existing = warmZone:FindFirstChild(WARM_ZONE_PRESENTATION_NAME)
    if existing then
        existing:Destroy()
    end

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = WARM_ZONE_PRESENTATION_NAME
    surfaceGui.Adornee = warmZone
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.LightInfluence = 0
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    surfaceGui.CanvasSize = Vector2.new(920, 760)
    surfaceGui.Parent = warmZone

    local glow = Instance.new("Frame")
    glow.Name = "WarmGroundGlow"
    glow.Position = UDim2.fromScale(0.03, 0.05)
    glow.Size = UDim2.fromScale(0.94, 0.9)
    glow.BackgroundColor3 = Color3.fromRGB(255, 143, 45)
    glow.BackgroundTransparency = 0.91
    glow.BorderSizePixel = 0
    glow.Parent = surfaceGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.18, 0)
    corner.Parent = glow

    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(255, 181, 79)
    border.Thickness = 5
    border.Transparency = 0.58
    border.Parent = glow

    local meaning = Instance.new("TextLabel")
    meaning.Name = "WarmZoneMeaning"
    meaning.Position = UDim2.fromScale(0.1, 0.07)
    meaning.Size = UDim2.fromScale(0.8, 0.09)
    meaning.BackgroundTransparency = 1
    meaning.Font = Enum.Font.GothamBold
    meaning.Text = "WARM ZONE  •  TRAINING + REFILL + SAFETY"
    meaning.TextColor3 = Color3.fromRGB(255, 211, 132)
    meaning.TextScaled = true
    meaning.TextStrokeColor3 = Color3.fromRGB(75, 34, 8)
    meaning.TextStrokeTransparency = 0.45
    meaning.TextTransparency = 0.12
    meaning.Parent = surfaceGui
end

local function createPresentation(
    hearth: Model,
    hearthBase: BasePart,
    fireOuter: BasePart,
    fireCore: BasePart
): Presentation
    local existing = hearth:FindFirstChild(PRESENTATION_NAME)
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = PRESENTATION_NAME
    folder.Parent = hearth

    for _, effectName in { "Flame", "Smoke", "Embers" } do
        local existingEffect = fireOuter:FindFirstChild(effectName)
        if existingEffect then
            existingEffect:Destroy()
        end
    end
    local existingLight = fireCore:FindFirstChild("WarmLight")
    if existingLight then
        existingLight:Destroy()
    end

    local flame = Instance.new("Fire")
    flame.Name = "Flame"
    flame.Enabled = false
    flame.Parent = fireOuter

    local light = Instance.new("PointLight")
    light.Name = "WarmLight"
    light.Enabled = false
    light.Shadows = false
    light.Parent = fireCore

    local smoke = Instance.new("Smoke")
    smoke.Name = "Smoke"
    smoke.Enabled = false
    smoke.Color = Color3.fromRGB(92, 83, 76)
    smoke.Parent = fireOuter

    local embers = Instance.new("ParticleEmitter")
    embers.Name = "Embers"
    embers.Enabled = false
    embers.Texture = EMBER_TEXTURE
    embers.Lifetime = NumberRange.new(0.8, 1.4)
    embers.Acceleration = Vector3.new(0, 3, 0)
    embers.Drag = 1
    embers.LightEmission = 0.8
    embers.LightInfluence = 0
    embers.Rotation = NumberRange.new(0, 360)
    embers.RotSpeed = NumberRange.new(-90, 90)
    embers.SpreadAngle = Vector2.new(28, 28)
    embers.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(0.7, 0.1),
        NumberSequenceKeypoint.new(1, 0),
    })
    embers.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.75, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    })
    embers.Parent = fireOuter

    local posts = {}
    for index = 1, 4 do
        local post = createSafePart(string.format("BrazierPost%02d", index), folder)
        post.Color = Color3.fromRGB(50, 52, 56)
        post.Material = Enum.Material.Metal
        table.insert(posts, post)
    end

    local runes = {}
    for index = 1, 8 do
        local rune = createSafePart(string.format("Rune%02d", index), folder)
        rune.Material = Enum.Material.Neon
        table.insert(runes, rune)
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HearthStatus"
    billboard.Enabled = false
    billboard.Adornee = hearthBase
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 110
    billboard.Size = UDim2.fromOffset(390, 158)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 8.5, 0)
    billboard.Parent = folder

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(30, 15, 7)
    background.BackgroundTransparency = 0.16
    background.BorderSizePixel = 0
    background.Parent = billboard

    local backgroundCorner = Instance.new("UICorner")
    backgroundCorner.CornerRadius = UDim.new(0, 12)
    backgroundCorner.Parent = background

    local backgroundBorder = Instance.new("UIStroke")
    backgroundBorder.Color = Color3.fromRGB(255, 170, 70)
    backgroundBorder.Thickness = 3
    backgroundBorder.Transparency = 0.1
    backgroundBorder.Parent = background

    local levelLabel = createBillboardLabel(
        "Level", UDim2.fromScale(0.04, 0.03), UDim2.fromScale(0.92, 0.28), Color3.fromRGB(255, 236, 190)
    )
    levelLabel.Parent = background
    local stageLabel = createBillboardLabel(
        "Stage", UDim2.fromScale(0.08, 0.28), UDim2.fromScale(0.84, 0.16), Color3.fromRGB(255, 176, 78)
    )
    stageLabel.Parent = background
    local trainingLabel = createBillboardLabel(
        "Training", UDim2.fromScale(0.05, 0.48), UDim2.fromScale(0.9, 0.21), Color3.fromRGB(255, 213, 112)
    )
    trainingLabel.Parent = background
    local upgradeLabel = createBillboardLabel(
        "Upgrade", UDim2.fromScale(0.05, 0.72), UDim2.fromScale(0.9, 0.21), Color3.fromRGB(255, 245, 220)
    )
    upgradeLabel.Parent = background

    return {
        Billboard = billboard,
        FireOuter = fireOuter,
        FireCore = fireCore,
        Flame = flame,
        Light = light,
        Smoke = smoke,
        Embers = embers,
        Posts = posts,
        Runes = runes,
        LevelLabel = levelLabel,
        StageLabel = stageLabel,
        TrainingLabel = trainingLabel,
        UpgradeLabel = upgradeLabel,
    }
end

local function isValidUpdate(data: any): boolean
    if type(data) ~= "table"
        or type(data.HearthLevel) ~= "number"
        or data.HearthLevel % 1 ~= 0
        or STAGE_STYLES[data.HearthLevel] == nil
        or type(data.WarmthTrainingRate) ~= "number"
        or data.WarmthTrainingRate <= 0
        or data.WarmthTrainingRate >= math.huge
        or data.WarmthTrainingRate % 1 ~= 0
        or type(data.VisualStage) ~= "string"
        or data.VisualStage == ""
        or type(data.IsMaxLevel) ~= "boolean"
    then
        return false
    end

    if data.IsMaxLevel then
        return data.NextUpgradeCost == nil
    end

    return type(data.NextUpgradeCost) == "number"
        and data.NextUpgradeCost > 0
        and data.NextUpgradeCost < math.huge
        and data.NextUpgradeCost % 1 == 0
end

local function applyStage(
    hearthBase: BasePart,
    prompt: ProximityPrompt,
    currentPresentation: Presentation,
    data: any
): ()
    if not isValidUpdate(data) then
        return
    end

    local level = data.HearthLevel
    local style = STAGE_STYLES[level]
    local baseTop = hearthBase.Size.Y * 0.5
    local outerHeight = baseTop + style.OuterSize.Y * 0.42
    local coreHeight = baseTop + style.CoreSize.Y * 0.42

    currentPresentation.FireOuter.Size = style.OuterSize
    currentPresentation.FireOuter.CFrame = hearthBase.CFrame * CFrame.new(0, outerHeight, 0)
    currentPresentation.FireOuter.Color = style.OuterColor
    currentPresentation.FireCore.Size = style.CoreSize
    currentPresentation.FireCore.CFrame = hearthBase.CFrame * CFrame.new(0, coreHeight, 0)
    currentPresentation.FireCore.Color = style.CoreColor

    currentPresentation.Flame.Color = style.CoreColor
    currentPresentation.Flame.SecondaryColor = style.OuterColor
    currentPresentation.Flame.Size = style.FireSize
    currentPresentation.Flame.Heat = style.FireHeat
    currentPresentation.Light.Color = style.LightColor
    currentPresentation.Light.Brightness = style.LightBrightness
    currentPresentation.Light.Range = style.LightRange
    currentPresentation.Smoke.Opacity = style.SmokeOpacity
    currentPresentation.Smoke.Size = style.SmokeSize
    currentPresentation.Smoke.RiseVelocity = style.SmokeRiseVelocity
    currentPresentation.Embers.Color = ColorSequence.new(style.CoreColor, style.OuterColor)
    currentPresentation.Embers.Rate = style.EmberRate
    currentPresentation.Embers.Speed = style.EmberSpeed
    currentPresentation.Flame.Enabled = true
    currentPresentation.Light.Enabled = true
    currentPresentation.Smoke.Enabled = true
    currentPresentation.Embers.Enabled = true
    currentPresentation.Billboard.Enabled = true

    for index, post in currentPresentation.Posts do
        local angle = (index - 1) * math.pi * 0.5
        local postHeight = math.max(style.PostHeight, 0.1)
        post.Size = Vector3.new(style.PostWidth, postHeight, style.PostWidth * 1.35)
        post.CFrame = hearthBase.CFrame
            * CFrame.new(math.cos(angle) * 3.25, baseTop + postHeight * 0.5, math.sin(angle) * 3.25)
            * CFrame.Angles(0, -angle, 0)
        post.Transparency = if style.PostHeight > 0 then 0.08 else 1
    end

    for index, rune in currentPresentation.Runes do
        local angle = (index - 1) * math.pi * 0.25
        local radius = math.max(style.RuneRadius, 0.1)
        rune.Size = Vector3.new(1.65 + level * 0.08, 0.12, 0.34)
        rune.CFrame = hearthBase.CFrame
            * CFrame.new(math.cos(angle) * radius, baseTop + 0.08, math.sin(angle) * radius)
            * CFrame.Angles(0, -angle + math.pi * 0.5, 0)
        rune.Color = style.RuneColor
        rune.Transparency = style.RuneTransparency
    end

    currentPresentation.LevelLabel.Text = string.format("HEARTH LV. %d", level)
    currentPresentation.StageLabel.Text = string.upper(data.VisualStage)
    currentPresentation.TrainingLabel.Text = string.format(
        "TRAINING +%s WARMTH/s",
        formatInteger(data.WarmthTrainingRate)
    )
    currentPresentation.UpgradeLabel.Text = if data.IsMaxLevel
        then "MAX"
        else string.format("NEXT $%s", formatInteger(data.NextUpgradeCost))

    prompt.ObjectText = string.format("HEARTH LV. %d", level)
    prompt.ActionText = if data.IsMaxLevel
        then "MAX"
        else string.format("UPGRADE $%s", formatInteger(data.NextUpgradeCost))
end

function HearthController.Start(): ()
    if started then
        return
    end
    started = true

    -- Only the player's own Hearth is presented; HearthUpdated always describes it.
    local hearthBase: BasePart? = nil
    local prompt: ProximityPrompt? = nil
    local pendingUpdate: any = nil

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName ~= "HearthUpdated" then
            return
        end

        if presentation and hearthBase and prompt then
            applyStage(hearthBase, prompt, presentation, data)
        else
            pendingUpdate = data
        end
    end)

    task.spawn(function()
        local ownBase = OwnBaseController.WaitForOwnBase()
        local hearth = ownBase:WaitForChild("Hearth")
        local base = hearth:WaitForChild("HearthBase")
        local fireOuter = hearth:WaitForChild("FireOuter")
        local fireCore = hearth:WaitForChild("FireCore")
        local warmZone = ownBase:WaitForChild("WarmZone")
        local upgradePrompt = base:WaitForChild("UpgradePrompt")

        assert(hearth:IsA("Model"), string.format("%s must be a Model", hearth:GetFullName()))
        assert(base:IsA("BasePart"), string.format("%s must be a BasePart", base:GetFullName()))
        assert(fireOuter:IsA("BasePart"), string.format("%s must be a BasePart", fireOuter:GetFullName()))
        assert(fireCore:IsA("BasePart"), string.format("%s must be a BasePart", fireCore:GetFullName()))
        assert(warmZone:IsA("BasePart"), string.format("%s must be a BasePart", warmZone:GetFullName()))
        assert(upgradePrompt:IsA("ProximityPrompt"), string.format("%s must be a ProximityPrompt", upgradePrompt:GetFullName()))

        presentation = createPresentation(hearth, base, fireOuter, fireCore)
        createWarmZonePresentation(warmZone)
        hearthBase = base
        prompt = upgradePrompt

        upgradePrompt.Triggered:Connect(function()
            gameplayRequest:FireServer("UpgradeHearth")
        end)

        local currentPresentation = presentation
        if pendingUpdate ~= nil and currentPresentation then
            applyStage(base, upgradePrompt, currentPresentation, pendingUpdate)
            pendingUpdate = nil
        end
    end)
end

return HearthController
