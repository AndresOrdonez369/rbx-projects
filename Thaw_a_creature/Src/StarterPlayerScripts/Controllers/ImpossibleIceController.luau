-- Awakened Ice hero presentation (F-D17-T02). Client-local, presentation only.
-- Every Ice with IsSpecial == true receives the SAME rules, scaled only by its physical size: the presentation never
-- reads CreatureID, rarity or silhouette data, and it never touches Ice state, prompts, ownership or physics.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ImpossibleIceController = {}

local ACTIVE_ICE_FOLDER_NAME = "ActiveIce"
local FX_FOLDER_NAME = "AwakenedIceFx"
local SPECIAL_ATTRIBUTE = "IsSpecial"

-- Engineer-owned gold pole + light (IceVisualFactory.ApplySpecialPresentation). Hidden locally only, never edited.
local HIDE_LEGACY_SPECIAL_POLE = true
local LEGACY_POLE_NAME = "SpecialBeam"
local LEGACY_LIGHT_NAME = "SpecialGlow"

local RUNE_TEXTURE_ID = "rbxassetid://122781986052793"
local AURORA_TEXTURE_ID = "rbxassetid://137572511255384"
local SOFT_TEXTURE_ID = "rbxasset://textures/particles/smoke_main.dds"

local PULSE_PERIOD = 3.6 -- seconds, from server time so every client breathes together
local CARRIER_SCAN_INTERVAL = 1

-- Palette: cold, ancient, no gold.
local SHARD_COLOR = Color3.fromRGB(22, 48, 74)
local OUTLINE_COLOR = Color3.fromRGB(140, 236, 255)
local FILL_COLOR = Color3.fromRGB(14, 30, 46)
local HEART_COLOR = Color3.fromRGB(95, 200, 255)
local LIGHT_COLOR = Color3.fromRGB(110, 200, 255)
local RUNE_COLOR = Color3.fromRGB(214, 244, 255)
local MIST_COLOR = Color3.fromRGB(200, 232, 255)
local WISP_COLOR = Color3.fromRGB(130, 225, 255)
local GLOW_COLOR = Color3.fromRGB(120, 210, 255)
local COLUMN_GRADIENT = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 255, 205)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 205, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 125, 255)),
})
-- Same gradient for a beam drawn top -> base (keeps teal at the Ice, violet at the top).
local COLUMN_GRADIENT_REVERSED = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 125, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 205, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 255, 205)),
})

-- Crystal crown: asymmetric shards around the footprint (fractions of Ice width W / height H).
-- X/Z = footprint offset (x W / x D), Height = x H, Width = x W, Tilt = degrees (X, Y, Z).
-- Front (-Z, the face toward home) stays low so the crown frames the Ice instead of hiding it.
local SHARDS = {
    { X = -0.12, Z = 0.50, Height = 2.10, Width = 0.58, Tilt = Vector3.new(8, 45, 5) },
    { X = -0.55, Z = 0.12, Height = 1.75, Width = 0.46, Tilt = Vector3.new(-4, 30, 14) },
    { X = 0.50, Z = 0.10, Height = 1.45, Width = 0.42, Tilt = Vector3.new(4, -20, -15) },
    { X = 0.32, Z = 0.52, Height = 1.25, Width = 0.36, Tilt = Vector3.new(11, 60, -8) },
    { X = 0.70, Z = -0.32, Height = 0.80, Width = 0.30, Tilt = Vector3.new(-9, 15, -28) },
    { X = -0.72, Z = -0.36, Height = 0.66, Width = 0.28, Tilt = Vector3.new(-13, -35, 30) },
    { X = 0.10, Z = -0.66, Height = 0.38, Width = 0.24, Tilt = Vector3.new(-22, 45, 6) },
}
local SHARD_SINK = 0.08 -- x H below the Ice base so shards erupt from the ground

-- Rune band
local RUNE_PIXELS_PER_STUD = 20
local RUNE_ASPECT = 4 -- texture width / height
local RUNE_SCROLL_STUDS_PER_SECOND = 0.6
local RUNE_HEIGHT_FRACTION = 0.2
local RUNE_HEIGHT_MIN, RUNE_HEIGHT_MAX = 1.5, 7
local RUNE_CENTER_FRACTION = 0.12 -- x H above the Ice centre
local RUNE_MARGIN = 1.08
local RUNE_VISIBLE_DISTANCE = 320

-- Aurora column: one camera-facing column of two additive beams on shared attachments
-- (a soft glow body for distance + aurora rays rising through it).
local COLUMN_WIDTH_FRACTION, COLUMN_WIDTH_MIN, COLUMN_WIDTH_MAX = 1.3, 9, 30
local COLUMN_HEIGHT_FRACTION, COLUMN_HEIGHT_MIN, COLUMN_HEIGHT_MAX = 9, 150, 320
local COLUMN_NEAR_FADE_START, COLUMN_NEAR_FADE_END = 25, 85
local COLUMN_GLOW_OPACITY = 0.75
local COLUMN_RAY_OPACITY = 0.95
local COLUMN_RAY_SPEED = 0.06

-- Long-distance glow: a soft cold halo beam on the Ice (no icon / text), faded out as the camera approaches
local GLOW_FADE_START, GLOW_FADE_END = 170, 300
local GLOW_MAX_OPACITY = 0.9
local GLOW_WIDTH_FRACTION, GLOW_WIDTH_MIN, GLOW_WIDTH_MAX = 2.6, 16, 70

-- Heart: brighter at distance (silhouette already blurred by IceController), dim up close so it never sharpens the shape.
local HEART_NEAR_DISTANCE, HEART_FAR_DISTANCE = 45, 140
local LIGHT_RANGE_MIN, LIGHT_RANGE_MAX = 18, 48

local started = false
local fxFolder: Folder? = nil
local presentations: { [BasePart]: any } = {}
local watchedIce: { [Instance]: RBXScriptConnection } = {}
local connections: { RBXScriptConnection } = {}
local scanElapsed = 0

local function clampNumber(value: number, low: number, high: number): number
    return math.clamp(value, low, high)
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

local function makeDecorPart(name: string, parent: Instance, className: string?): BasePart
    local part = Instance.new(className or "Part") :: BasePart
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

-- Wild = in ActiveIce; Carried = welded into a player's character. Anything else ends the presentation.
local function getIceState(ice: BasePart): (string?, Player?)
    if not ice.Parent or ice:GetAttribute(SPECIAL_ATTRIBUTE) ~= true then
        return nil, nil
    end
    if ice.Parent.Name == ACTIVE_ICE_FOLDER_NAME and ice.Parent.Parent == Workspace then
        return "Wild", nil
    end
    local carrier = Players:GetPlayerFromCharacter(ice.Parent)
    if carrier then
        return "Carried", carrier
    end
    return nil, nil
end

local function setLegacyPoleHidden(ice: BasePart, hidden: boolean): ()
    if not HIDE_LEGACY_SPECIAL_POLE then
        return
    end
    local pole = ice:FindFirstChild(LEGACY_POLE_NAME)
    if pole and pole:IsA("BasePart") then
        pole.LocalTransparencyModifier = if hidden then 1 else 0
    end
    local light = ice:FindFirstChild(LEGACY_LIGHT_NAME)
    if light and light:IsA("Light") then
        light.Enabled = not hidden
    end
end

local function createRuneFace(band: BasePart, face: Enum.NormalId, facePixels: number, phasePixels: number, tilePixels: number)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "Runes" .. face.Name
    gui.Face = face
    gui.LightInfluence = 0
    gui.Brightness = 1.4
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = RUNE_PIXELS_PER_STUD
    gui.Parent = band

    local label = Instance.new("ImageLabel")
    label.Name = "Runes"
    label.BackgroundTransparency = 1
    label.Image = RUNE_TEXTURE_ID
    label.ImageColor3 = RUNE_COLOR
    label.ScaleType = Enum.ScaleType.Tile
    label.TileSize = UDim2.new(0, tilePixels, 1, 0)
    label.Size = UDim2.new(0, facePixels + tilePixels, 1, 0)
    label.Parent = gui

    return { Gui = gui, Label = label, Phase = phasePixels }
end

local function createPresentation(ice: BasePart)
    local size = ice.Size
    local width, height, depth = size.X, size.Y, size.Z

    local root = Instance.new("Folder")
    root.Name = "AwakenedIce"
    root.Parent = getFxFolder()

    -- Crystal crown
    local crown = Instance.new("Model")
    crown.Name = "Crown"
    crown.Parent = root
    local shards = {}
    local shardOffsets = {}
    for index, spec in SHARDS do
        local shardHeight = spec.Height * height
        local shardWidth = spec.Width * width
        -- Corner wedges taper to a point: a crystal spike from a single native part.
        local shard = makeDecorPart("Shard" .. index, crown, "CornerWedgePart")
        shard.Material = Enum.Material.Glass
        shard.Color = SHARD_COLOR
        shard.Transparency = 0.12
        shard.Size = Vector3.new(shardWidth, shardHeight, shardWidth * 0.8)
        local tilt = spec.Tilt
        shardOffsets[index] = CFrame.new(spec.X * width, -height * 0.5 - SHARD_SINK * height, spec.Z * depth)
            * CFrame.Angles(math.rad(tilt.X), math.rad(tilt.Y), math.rad(tilt.Z))
            * CFrame.new(0, shardHeight * 0.5, 0)
        shards[index] = shard
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "CrownEdge"
    highlight.Adornee = crown
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillColor = FILL_COLOR
    highlight.FillTransparency = 0.9
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.OutlineTransparency = 0.4
    highlight.Parent = crown

    -- Backlit heart (behind the silhouette, inside the Ice)
    local heartSize = math.min(width, height) * 0.5
    local heart = makeDecorPart("Heart", root) :: Part
    heart.Shape = Enum.PartType.Ball
    heart.Material = Enum.Material.Neon
    heart.Color = HEART_COLOR
    heart.Transparency = 0.6
    heart.Size = Vector3.new(heartSize, heartSize, heartSize)
    local heartOffset = CFrame.new(0, -height * 0.05, depth * 0.18)

    local light = Instance.new("PointLight")
    light.Name = "HeartLight"
    light.Color = LIGHT_COLOR
    light.Range = clampNumber(height * 1.8, LIGHT_RANGE_MIN, LIGHT_RANGE_MAX)
    light.Brightness = 1
    light.Shadows = false
    light.Parent = heart

    -- Aurora column rising from the Ice top (travels with the Ice: attachments live on the heart)
    local columnWidth = clampNumber(width * COLUMN_WIDTH_FRACTION, COLUMN_WIDTH_MIN, COLUMN_WIDTH_MAX)
    local columnHeight = clampNumber(height * COLUMN_HEIGHT_FRACTION, COLUMN_HEIGHT_MIN, COLUMN_HEIGHT_MAX)
    local columnBase = Instance.new("Attachment")
    columnBase.Name = "ColumnBase"
    columnBase.Position = Vector3.new(0, height * 0.5, -depth * 0.18)
    columnBase.Parent = heart
    local columnTop = Instance.new("Attachment")
    columnTop.Name = "ColumnTop"
    columnTop.Position = columnBase.Position + Vector3.new(0, columnHeight, 0)
    columnTop.Parent = heart
    -- Beam textures run top-of-image at Attachment0; the aurora's bright ragged edge must sit on the Ice,
    -- so the ray beam is drawn top -> base.
    local function makeColumnBeam(name: string, texture: string, widthScale0: number, widthScale1: number, fromTop: boolean): Beam
        local beam = Instance.new("Beam")
        beam.Name = name
        beam.Attachment0 = if fromTop then columnTop else columnBase
        beam.Attachment1 = if fromTop then columnBase else columnTop
        beam.FaceCamera = true
        beam.Segments = 8
        beam.Texture = texture
        beam.TextureMode = Enum.TextureMode.Stretch
        beam.TextureLength = 1
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Brightness = 1.5
        beam.Color = if fromTop then COLUMN_GRADIENT_REVERSED else COLUMN_GRADIENT
        beam.Width0 = columnWidth * (if fromTop then widthScale1 else widthScale0)
        beam.Width1 = columnWidth * (if fromTop then widthScale0 else widthScale1)
        beam.Transparency = NumberSequence.new(1)
        beam.Parent = heart
        return beam
    end
    local columnGlow = makeColumnBeam("ColumnGlow", SOFT_TEXTURE_ID, 1.0, 1.7, false)
    local columnRays = makeColumnBeam("ColumnRays", AURORA_TEXTURE_ID, 0.7, 1.3, true)
    columnRays.TextureSpeed = -COLUMN_RAY_SPEED -- rays drift upward

    -- Long-distance glow: a soft cold halo around the Ice itself (no icon, no text)
    local glowWidth = clampNumber(width * GLOW_WIDTH_FRACTION, GLOW_WIDTH_MIN, GLOW_WIDTH_MAX)
    local glowLow = Instance.new("Attachment")
    glowLow.Name = "GlowLow"
    glowLow.Position = Vector3.new(0, -glowWidth * 0.45, 0)
    glowLow.Parent = heart
    local glowHigh = Instance.new("Attachment")
    glowHigh.Name = "GlowHigh"
    glowHigh.Position = Vector3.new(0, glowWidth * 0.45, 0)
    glowHigh.Parent = heart
    local glow = Instance.new("Beam")
    glow.Name = "DistanceGlow"
    glow.Attachment0 = glowLow
    glow.Attachment1 = glowHigh
    glow.FaceCamera = true
    glow.Segments = 1
    glow.Texture = SOFT_TEXTURE_ID
    glow.TextureMode = Enum.TextureMode.Stretch
    glow.TextureLength = 1
    glow.LightEmission = 1
    glow.LightInfluence = 0
    glow.Brightness = 2.5
    glow.Color = ColorSequence.new(GLOW_COLOR)
    glow.Width0 = glowWidth
    glow.Width1 = glowWidth
    glow.Transparency = NumberSequence.new(1)
    glow.Enabled = false
    glow.Parent = heart

    -- Rune band wrapped around the Ice, scrolling continuously around all four faces
    local runeHeight = clampNumber(height * RUNE_HEIGHT_FRACTION, RUNE_HEIGHT_MIN, RUNE_HEIGHT_MAX)
    local bandWidth, bandDepth = width * RUNE_MARGIN, depth * RUNE_MARGIN
    local band = makeDecorPart("RuneBand", root)
    band.Transparency = 1
    band.Size = Vector3.new(bandWidth, runeHeight, bandDepth)
    local bandOffset = CFrame.new(0, height * RUNE_CENTER_FRACTION, 0)
    local tilePixels = math.max(8, math.floor(runeHeight * RUNE_PIXELS_PER_STUD * RUNE_ASPECT))
    local widthPixels = math.floor(bandWidth * RUNE_PIXELS_PER_STUD)
    local depthPixels = math.floor(bandDepth * RUNE_PIXELS_PER_STUD)
    -- Walking around the Ice: Front -> Left -> Back -> Right, each face continuing the previous one's right edge.
    local runeFaces = {
        createRuneFace(band, Enum.NormalId.Front, widthPixels, 0, tilePixels),
        createRuneFace(band, Enum.NormalId.Left, depthPixels, widthPixels, tilePixels),
        createRuneFace(band, Enum.NormalId.Back, widthPixels, widthPixels + depthPixels, tilePixels),
        createRuneFace(band, Enum.NormalId.Right, depthPixels, widthPixels * 2 + depthPixels, tilePixels),
    }

    -- Low mist + a few frost wisps (about 25 particles alive)
    local mistAttachment = Instance.new("Attachment")
    mistAttachment.Name = "Mist"
    mistAttachment.Position = Vector3.new(0, -height * 0.5 - height * RUNE_CENTER_FRACTION + 0.5, 0)
    mistAttachment.Parent = band
    local mistSize = clampNumber(width * 0.45, 3, 12)
    local mist = Instance.new("ParticleEmitter")
    mist.Name = "ColdMist"
    mist.Texture = SOFT_TEXTURE_ID
    mist.Color = ColorSequence.new(MIST_COLOR)
    mist.LightEmission = 0.25
    mist.LightInfluence = 0.5
    mist.Rate = 2.5
    mist.Lifetime = NumberRange.new(5, 7)
    mist.Speed = NumberRange.new(1, 2.5)
    mist.SpreadAngle = Vector2.new(85, 85)
    mist.EmissionDirection = Enum.NormalId.Top
    mist.Acceleration = Vector3.new(0, 0.25, 0)
    mist.Drag = 0.8
    mist.Rotation = NumberRange.new(0, 360)
    mist.RotSpeed = NumberRange.new(-12, 12)
    mist.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, mistSize * 0.6),
        NumberSequenceKeypoint.new(1, mistSize),
    })
    mist.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, 0.78),
        NumberSequenceKeypoint.new(1, 1),
    })
    mist.Parent = mistAttachment

    local wispAttachment = Instance.new("Attachment")
    wispAttachment.Name = "Wisps"
    wispAttachment.Position = Vector3.new(0, -height * RUNE_CENTER_FRACTION, 0)
    wispAttachment.Parent = band
    local wispSize = clampNumber(width * 0.08, 0.6, 2.2)
    local wisps = Instance.new("ParticleEmitter")
    wisps.Name = "FrostWisps"
    wisps.Texture = SOFT_TEXTURE_ID
    wisps.Color = ColorSequence.new(WISP_COLOR)
    wisps.LightEmission = 0.8
    wisps.LightInfluence = 0
    wisps.Rate = 2
    wisps.Lifetime = NumberRange.new(3, 4)
    wisps.Speed = NumberRange.new(1, 2.2)
    wisps.SpreadAngle = Vector2.new(35, 35)
    wisps.EmissionDirection = Enum.NormalId.Top
    wisps.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, wispSize * 0.5),
        NumberSequenceKeypoint.new(1, wispSize * 1.4),
    })
    wisps.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.4, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    wisps.Parent = wispAttachment

    setLegacyPoleHidden(ice, true)

    return {
        Ice = ice,
        Root = root,
        Shards = shards,
        ShardOffsets = shardOffsets,
        Highlight = highlight,
        Heart = heart,
        HeartOffset = heartOffset,
        Light = light,
        ColumnGlow = columnGlow,
        ColumnRays = columnRays,
        ColumnOpacityKey = -1,
        Glow = glow,
        GlowOpacityKey = -1,
        Band = band,
        BandOffset = bandOffset,
        RuneFaces = runeFaces,
        TilePixels = tilePixels,
        LastCFrame = nil,
        LocalCarrier = nil,
    }
end

local function destroyPresentation(ice: BasePart): ()
    local presentation = presentations[ice]
    if not presentation then
        return
    end
    presentations[ice] = nil
    presentation.Root:Destroy()
    setLegacyPoleHidden(ice, false)
    local folder = fxFolder
    if folder and next(presentations) == nil then
        folder:Destroy()
        fxFolder = nil
    end
end

local function ensurePresentation(ice: Instance): ()
    if not ice:IsA("BasePart") or presentations[ice] then
        return
    end
    if getIceState(ice) == nil then
        return
    end
    presentations[ice] = createPresentation(ice)
end

local function placePresentation(presentation, iceCFrame: CFrame): ()
    for index, shard in presentation.Shards do
        shard.CFrame = iceCFrame * presentation.ShardOffsets[index]
    end
    presentation.Heart.CFrame = iceCFrame * presentation.HeartOffset
    presentation.Band.CFrame = iceCFrame * presentation.BandOffset
end

local function updatePresentation(presentation, cameraPosition: Vector3, serverTime: number, carrier: Player?): ()
    local ice: BasePart = presentation.Ice
    local iceCFrame = ice.CFrame
    if presentation.LastCFrame ~= iceCFrame then
        presentation.LastCFrame = iceCFrame
        placePresentation(presentation, iceCFrame)
    end

    -- The local carrier gets a quieter crown so the decoration never blocks their own view.
    local isLocalCarrier = carrier ~= nil and carrier == Players.LocalPlayer
    if presentation.LocalCarrier ~= isLocalCarrier then
        presentation.LocalCarrier = isLocalCarrier
        for _, shard in presentation.Shards do
            shard.LocalTransparencyModifier = if isLocalCarrier then 0.8 else 0
        end
        presentation.Heart.LocalTransparencyModifier = if isLocalCarrier then 0.5 else 0
    end

    local phase = (serverTime % PULSE_PERIOD) / PULSE_PERIOD
    local pulse = (0.5 - 0.5 * math.cos(phase * math.pi * 2)) ^ 2
    local distance = (iceCFrame.Position - cameraPosition).Magnitude

    -- Heart + light
    local farFactor = math.clamp((distance - HEART_NEAR_DISTANCE) / (HEART_FAR_DISTANCE - HEART_NEAR_DISTANCE), 0, 1)
    presentation.Heart.Transparency = 0.82 - 0.42 * farFactor - 0.08 * pulse
    presentation.Light.Brightness = 0.8 + 1.0 * pulse + 0.6 * farFactor

    -- Crown edge
    presentation.Highlight.OutlineTransparency = 0.35 - 0.25 * pulse

    -- Aurora column: fades near the camera; sequences rebuilt only when the quantised opacity changes
    local columnAlpha = math.clamp((distance - COLUMN_NEAR_FADE_START) / (COLUMN_NEAR_FADE_END - COLUMN_NEAR_FADE_START), 0, 1)
    local opacity = columnAlpha * (0.75 + 0.25 * pulse)
    local opacityKey = math.floor(opacity * 40 + 0.5)
    if opacityKey ~= presentation.ColumnOpacityKey then
        presentation.ColumnOpacityKey = opacityKey
        local quantised = opacityKey / 40
        -- Strongest just above the Ice, thinning out toward the sky (mirrored for the top -> base ray beam).
        local function columnSequence(peak: number, fromTop: boolean): NumberSequence
            local core = 1 - peak * quantised
            local mid = core + (1 - core) * 0.35
            if fromTop then
                return NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.45, mid),
                    NumberSequenceKeypoint.new(0.94, core),
                    NumberSequenceKeypoint.new(1, 1),
                })
            end
            return NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.06, core),
                NumberSequenceKeypoint.new(0.55, mid),
                NumberSequenceKeypoint.new(1, 1),
            })
        end
        presentation.ColumnGlow.Transparency = columnSequence(COLUMN_GLOW_OPACITY, false)
        presentation.ColumnRays.Transparency = columnSequence(COLUMN_RAY_OPACITY, true)
        presentation.ColumnGlow.Enabled = quantised > 0
        presentation.ColumnRays.Enabled = quantised > 0
    end

    -- Distance glow: long range only
    local glowAlpha = math.clamp((distance - GLOW_FADE_START) / (GLOW_FADE_END - GLOW_FADE_START), 0, 1)
    local glowKey = math.floor(glowAlpha * (0.8 + 0.2 * pulse) * 40 + 0.5)
    if glowKey ~= presentation.GlowOpacityKey then
        presentation.GlowOpacityKey = glowKey
        presentation.Glow.Enabled = glowKey > 0
        presentation.Glow.Transparency = NumberSequence.new(1 - GLOW_MAX_OPACITY * glowKey / 40)
    end

    -- Rune band: slow continuous orbit, breathing brightness
    if distance <= RUNE_VISIBLE_DISTANCE then
        local tilePixels = presentation.TilePixels
        local scroll = serverTime * RUNE_SCROLL_STUDS_PER_SECOND * RUNE_PIXELS_PER_STUD
        for _, face in presentation.RuneFaces do
            face.Gui.Enabled = true
            face.Gui.Brightness = 1.1 + 0.9 * pulse
            face.Label.ImageTransparency = 0.25 - 0.15 * pulse
            face.Label.Position = UDim2.fromOffset(-math.floor((face.Phase + scroll) % tilePixels), 0)
        end
    else
        for _, face in presentation.RuneFaces do
            face.Gui.Enabled = false
        end
    end
end

local function watchIce(ice: Instance): ()
    if watchedIce[ice] or not ice:IsA("BasePart") then
        return
    end
    ensurePresentation(ice)
    -- IsSpecial may replicate a moment after the Ice itself.
    watchedIce[ice] = ice:GetAttributeChangedSignal(SPECIAL_ATTRIBUTE):Connect(function()
        if ice:GetAttribute(SPECIAL_ATTRIBUTE) == true then
            ensurePresentation(ice)
        end
    end)
end

local function unwatchIce(ice: Instance): ()
    local connection = watchedIce[ice]
    if connection then
        connection:Disconnect()
        watchedIce[ice] = nil
    end
end

-- Catches Special Ice already being carried when this client joins (and any carry that started elsewhere).
local function scanCarriers(): ()
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if character then
            for _, child in character:GetChildren() do
                if child:IsA("BasePart") and child:GetAttribute(SPECIAL_ATTRIBUTE) == true then
                    ensurePresentation(child)
                end
            end
        end
    end
    -- The server may attach the legacy pole after our first pass.
    for ice in presentations do
        setLegacyPoleHidden(ice, true)
    end
end

local function onHeartbeat(deltaTime: number): ()
    scanElapsed += deltaTime
    if scanElapsed >= CARRIER_SCAN_INTERVAL then
        scanElapsed = 0
        scanCarriers()
    end

    if next(presentations) == nil then
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local cameraPosition = camera.CFrame.Position
    local serverTime = Workspace:GetServerTimeNow()

    for ice, presentation in presentations do
        local state, carrier = getIceState(ice)
        if state == nil then
            destroyPresentation(ice)
        else
            updatePresentation(presentation, cameraPosition, serverTime, carrier)
        end
    end
end

function ImpossibleIceController.Start(): ()
    if started then
        return
    end
    started = true

    local activeIceFolder = Workspace:WaitForChild(ACTIVE_ICE_FOLDER_NAME)
    for _, ice in activeIceFolder:GetChildren() do
        watchIce(ice)
    end
    table.insert(connections, activeIceFolder.ChildAdded:Connect(watchIce))
    table.insert(connections, activeIceFolder.ChildRemoved:Connect(unwatchIce))
    table.insert(connections, RunService.Heartbeat:Connect(onHeartbeat))
    scanCarriers()
end

function ImpossibleIceController.Stop(): ()
    if not started then
        return
    end
    started = false
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
    for ice in watchedIce do
        unwatchIce(ice)
    end
    for ice in presentations do
        destroyPresentation(ice)
    end
end

return ImpossibleIceController
