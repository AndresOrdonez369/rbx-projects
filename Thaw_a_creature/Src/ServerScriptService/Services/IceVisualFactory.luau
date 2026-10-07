local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local IceConfig = require(shared:WaitForChild("IceConfig"))
local SizeConfig = require(shared:WaitForChild("SizeConfig"))

local IceVisualFactory = {}

local VISUAL_PROFILES = {
    Regular = {
        Color = Color3.fromRGB(151, 225, 255),
        Size = Vector3.new(4, 5, 4),
    },
    Thick = {
        Color = Color3.fromRGB(91, 164, 255),
        Size = Vector3.new(6, 7, 6),
    },
    Ancient = {
        Color = Color3.fromRGB(35, 132, 190),
        AccentColor = Color3.fromRGB(100, 238, 255),
        Size = Vector3.new(6, 7, 6),
    },
    Black = {
        Color = Color3.fromRGB(7, 18, 35),
        AccentColor = Color3.fromRGB(78, 225, 255),
        SecondaryAccentColor = Color3.fromRGB(143, 92, 255),
        DetailStyle = "BlackFrost",
        Size = Vector3.new(6, 7, 6),
    },
    Meteor = {
        Color = Color3.fromRGB(20, 12, 34),
        AccentColor = Color3.fromRGB(255, 104, 38),
        SecondaryAccentColor = Color3.fromRGB(74, 232, 255),
        DetailStyle = "MeteorImpact",
        Size = Vector3.new(6, 7, 6),
    },
}
local SILHOUETTE_COLOR = Color3.fromRGB(31, 42, 52)
local THAWED_ICE_COLOR = Color3.fromRGB(220, 247, 255)
local CRACK_COLOR = Color3.fromRGB(91, 164, 255)
local CRACK_NAME = "ThawCrack"
local INTERACTION_PART_NAME = "IceInteraction"
local THAW_VISUAL_STAGE_ATTRIBUTE = "ThawVisualStage"
local FIRST_CRACK_VISIBLE_PARTS = 2
local FIRST_CRACK_TRANSPARENCY = 0.05
local SECOND_CRACK_TRANSPARENCY = 0
local SECOND_CRACK_ICE_TRANSPARENCY = 0.72
local SECOND_CRACK_SILHOUETTE_TRANSPARENCY = 0
local THAW_STAGE_PROFILES = {
    Frozen = {
        IceTransparency = 0.08,
        IceColorBlend = 0,
        SilhouetteTransparency = 0.72,
        CrackTransparency = 1,
    },
    Thawing = {
        IceTransparency = 0.22,
        IceColorBlend = 0.12,
        SilhouetteTransparency = 0.48,
        CrackTransparency = 1,
    },
    NearlyReady = {
        IceTransparency = 0.38,
        IceColorBlend = 0.25,
        SilhouetteTransparency = 0.22,
        CrackTransparency = 1,
    },
    Ready = {
        IceTransparency = 0.55,
        IceColorBlend = 0.45,
        SilhouetteTransparency = 0.08,
        CrackTransparency = 1,
    },
}
local SILHOUETTE_PROFILES = {
    Compact = {
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.50, 0.48, 0.45), PositionScale = Vector3.new(0, -0.05, 0) },
        { SizeScale = Vector3.new(0.26, 0.58, 0.26), PositionScale = Vector3.new(0, 0.08, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.30, 0.22, 0.30), PositionScale = Vector3.new(0, 0.27, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.18, 0.28, 0.18), PositionScale = Vector3.new(-0.31, 0, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.18, 0.28, 0.18), PositionScale = Vector3.new(0.31, 0, 0) },
    },
    AgileQuadruped = {
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.62, 0.28, 0.34), PositionScale = Vector3.new(-0.06, 0, 0) },
        { SizeScale = Vector3.new(0.70, 0.25, 0.25), PositionScale = Vector3.new(0, 0.02, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.27, 0.24, 0.29), PositionScale = Vector3.new(0.30, 0.10, 0) },
        { SizeScale = Vector3.new(0.13, 0.30, 0.15), PositionScale = Vector3.new(-0.20, -0.22, 0) },
        { SizeScale = Vector3.new(0.13, 0.30, 0.15), PositionScale = Vector3.new(0.18, -0.22, 0) },
        { SizeScale = Vector3.new(0.30, 0.09, 0.10), PositionScale = Vector3.new(-0.32, 0.08, 0), Rotation = CFrame.Angles(0, 0, math.rad(28)) },
    },
    HeavyBeast = {
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.68, 0.43, 0.48), PositionScale = Vector3.new(-0.05, 0.02, 0) },
        { SizeScale = Vector3.new(0.60, 0.38, 0.40), PositionScale = Vector3.new(0, 0, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.32, 0.33, 0.38), PositionScale = Vector3.new(0.30, 0.07, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.26, 0.24, 0.36), PositionScale = Vector3.new(-0.21, -0.28, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.26, 0.24, 0.36), PositionScale = Vector3.new(0.19, -0.28, 0) },
    },
    GiantAncient = {
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.60, 0.56, 0.48), PositionScale = Vector3.new(-0.08, -0.04, 0) },
        { SizeScale = Vector3.new(0.60, 0.52, 0.40), PositionScale = Vector3.new(0, -0.03, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.30, 0.25, 0.33), PositionScale = Vector3.new(0.25, 0.19, 0) },
        { SizeScale = Vector3.new(0.20, 0.27, 0.25), PositionScale = Vector3.new(-0.20, -0.29, 0) },
        { SizeScale = Vector3.new(0.20, 0.27, 0.25), PositionScale = Vector3.new(0.14, -0.29, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.13, 0.36, 0.14), PositionScale = Vector3.new(0.30, -0.11, 0), Rotation = CFrame.Angles(0, 0, math.rad(-10)) },
    },
    MythicUnknown = {
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.62, 0.54, 0.50), PositionScale = Vector3.new(-0.04, -0.03, 0) },
        { SizeScale = Vector3.new(0.42, 0.50, 0.38), PositionScale = Vector3.new(-0.16, 0.03, 0), Rotation = CFrame.Angles(0, 0, math.rad(-14)) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.32, 0.31, 0.34), PositionScale = Vector3.new(0.24, 0.20, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.25, 0.33, 0.28), PositionScale = Vector3.new(-0.29, 0.18, 0) },
        { SizeScale = Vector3.new(0.20, 0.39, 0.24), PositionScale = Vector3.new(-0.21, -0.27, 0), Rotation = CFrame.Angles(0, 0, math.rad(8)) },
        { SizeScale = Vector3.new(0.20, 0.39, 0.24), PositionScale = Vector3.new(0.19, -0.27, 0), Rotation = CFrame.Angles(0, 0, math.rad(-8)) },
    },
    AncientPredator = {
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.66, 0.31, 0.32), PositionScale = Vector3.new(-0.07, -0.02, 0), Rotation = CFrame.Angles(0, 0, math.rad(-7)) },
        { SizeScale = Vector3.new(0.70, 0.25, 0.25), PositionScale = Vector3.new(0, 0, 0) },
        { Shape = Enum.PartType.Ball, SizeScale = Vector3.new(0.30, 0.27, 0.31), PositionScale = Vector3.new(0.31, 0.11, 0) },
        { SizeScale = Vector3.new(0.14, 0.31, 0.16), PositionScale = Vector3.new(-0.17, -0.24, 0) },
        { SizeScale = Vector3.new(0.14, 0.31, 0.16), PositionScale = Vector3.new(0.20, -0.23, 0) },
        { SizeScale = Vector3.new(0.34, 0.09, 0.10), PositionScale = Vector3.new(-0.30, 0.10, 0), Rotation = CFrame.Angles(0, 0, math.rad(31)) },
    },
}

local CRACK_PROFILES = {
    {
        SizeScale = Vector3.new(0.035, 0.42, 0.02),
        PositionScale = Vector3.new(-0.12, 0.18, -0.505),
        Rotation = CFrame.Angles(0, 0, math.rad(24)),
    },
    {
        SizeScale = Vector3.new(0.035, 0.30, 0.02),
        PositionScale = Vector3.new(0.02, -0.08, -0.506),
        Rotation = CFrame.Angles(0, 0, math.rad(-31)),
    },
    {
        SizeScale = Vector3.new(0.035, 0.24, 0.02),
        PositionScale = Vector3.new(0.16, 0.08, -0.507),
        Rotation = CFrame.Angles(0, 0, math.rad(43)),
    },
    {
        SizeScale = Vector3.new(0.035, 0.28, 0.02),
        PositionScale = Vector3.new(-0.24, -0.12, -0.508),
        Rotation = CFrame.Angles(0, 0, math.rad(-48)),
    },
    {
        SizeScale = Vector3.new(0.035, 0.22, 0.02),
        PositionScale = Vector3.new(0.27, -0.20, -0.509),
        Rotation = CFrame.Angles(0, 0, math.rad(18)),
    },
}

local ANCIENT_RUNE_PROFILES = {
    {
        SizeScale = Vector3.new(0.035, 0.34, 0.018),
        PositionScale = Vector3.new(0, 0.16, -0.511),
    },
    {
        SizeScale = Vector3.new(0.035, 0.23, 0.018),
        PositionScale = Vector3.new(-0.08, -0.02, -0.512),
        Rotation = CFrame.Angles(0, 0, math.rad(42)),
    },
    {
        SizeScale = Vector3.new(0.035, 0.23, 0.018),
        PositionScale = Vector3.new(0.08, -0.02, -0.512),
        Rotation = CFrame.Angles(0, 0, math.rad(-42)),
    },
    {
        SizeScale = Vector3.new(0.035, 0.24, 0.018),
        PositionScale = Vector3.new(0, -0.20, -0.513),
    },
}

local BLACK_FROST_PROFILES = {
    {
        SizeScale = Vector3.new(0.025, 0.62, 0.016),
        PositionScale = Vector3.new(-0.24, 0.08, -0.512),
        Rotation = CFrame.Angles(0, 0, math.rad(19)),
    },
    {
        SizeScale = Vector3.new(0.025, 0.50, 0.016),
        PositionScale = Vector3.new(0.22, 0.13, -0.513),
        Rotation = CFrame.Angles(0, 0, math.rad(-23)),
        UseSecondaryColor = true,
    },
    {
        SizeScale = Vector3.new(0.025, 0.39, 0.016),
        PositionScale = Vector3.new(-0.03, -0.22, -0.514),
        Rotation = CFrame.Angles(0, 0, math.rad(47)),
    },
    {
        SizeScale = Vector3.new(0.22, 0.025, 0.016),
        PositionScale = Vector3.new(-0.10, 0.27, -0.515),
        Rotation = CFrame.Angles(0, 0, math.rad(-11)),
        UseSecondaryColor = true,
    },
    {
        SizeScale = Vector3.new(0.18, 0.025, 0.016),
        PositionScale = Vector3.new(0.14, -0.09, -0.516),
        Rotation = CFrame.Angles(0, 0, math.rad(28)),
    },
    {
        SizeScale = Vector3.new(0.025, 0.34, 0.016),
        PositionScale = Vector3.new(0.03, 0.12, 0.512),
        Rotation = CFrame.Angles(0, math.rad(180), math.rad(-36)),
        UseSecondaryColor = true,
    },
}

local METEOR_IMPACT_PROFILES = {
    {
        SizeScale = Vector3.new(0.045, 0.72, 0.045),
        PositionScale = Vector3.new(-0.28, 0.04, -0.515),
        Rotation = CFrame.Angles(0, 0, math.rad(24)),
    },
    {
        SizeScale = Vector3.new(0.045, 0.58, 0.045),
        PositionScale = Vector3.new(0.25, 0.11, -0.516),
        Rotation = CFrame.Angles(0, 0, math.rad(-31)),
        UseSecondaryColor = true,
    },
    {
        SizeScale = Vector3.new(0.38, 0.045, 0.045),
        PositionScale = Vector3.new(0.02, -0.27, -0.517),
        Rotation = CFrame.Angles(0, 0, math.rad(12)),
    },
    {
        SizeScale = Vector3.new(0.24, 0.11, 0.18),
        PositionScale = Vector3.new(-0.42, 0.34, 0.08),
        Rotation = CFrame.Angles(math.rad(18), 0, math.rad(-38)),
        UseSecondaryColor = true,
    },
    {
        SizeScale = Vector3.new(0.20, 0.09, 0.16),
        PositionScale = Vector3.new(0.43, -0.31, -0.04),
        Rotation = CFrame.Angles(math.rad(-14), 0, math.rad(41)),
    },
}

local function addAncientRunes(visualIce: BasePart, accentColor: Color3)
    for _, runeProfile in ANCIENT_RUNE_PROFILES do
        local runePart = Instance.new("Part")
        runePart.Name = "AncientRune"
        runePart.Anchored = true
        runePart.CanCollide = false
        runePart.CanQuery = false
        runePart.CanTouch = false
        runePart.CastShadow = false
        runePart.Color = accentColor
        runePart.Material = Enum.Material.Neon
        runePart.Size = runeProfile.SizeScale * visualIce.Size
        runePart.TopSurface = Enum.SurfaceType.Smooth
        runePart.BottomSurface = Enum.SurfaceType.Smooth
        runePart.Transparency = 0.12

        local positionScale = runeProfile.PositionScale
        local localPosition = Vector3.new(
            positionScale.X * visualIce.Size.X,
            positionScale.Y * visualIce.Size.Y,
            positionScale.Z * visualIce.Size.Z
        )
        runePart.CFrame = visualIce.CFrame * CFrame.new(localPosition) * (runeProfile.Rotation or CFrame.identity)
        runePart.Parent = visualIce
    end
end

local function addBlackFrostDetails(visualIce: BasePart, accentColor: Color3, secondaryAccentColor: Color3)
    for _, detailProfile in BLACK_FROST_PROFILES do
        local detailPart = Instance.new("Part")
        detailPart.Name = "BlackFrostDetail"
        detailPart.Anchored = true
        detailPart.CanCollide = false
        detailPart.CanQuery = false
        detailPart.CanTouch = false
        detailPart.CastShadow = false
        detailPart.Color = if detailProfile.UseSecondaryColor then secondaryAccentColor else accentColor
        detailPart.Material = Enum.Material.Neon
        detailPart.Size = detailProfile.SizeScale * visualIce.Size
        detailPart.TopSurface = Enum.SurfaceType.Smooth
        detailPart.BottomSurface = Enum.SurfaceType.Smooth
        detailPart.Transparency = 0.18

        local positionScale = detailProfile.PositionScale
        local localPosition = Vector3.new(
            positionScale.X * visualIce.Size.X,
            positionScale.Y * visualIce.Size.Y,
            positionScale.Z * visualIce.Size.Z
        )
        detailPart.CFrame = visualIce.CFrame
            * CFrame.new(localPosition)
            * (detailProfile.Rotation or CFrame.identity)
        detailPart.Parent = visualIce
    end
end

local function addMeteorImpactDetails(visualIce: BasePart, accentColor: Color3, secondaryAccentColor: Color3)
    for _, detailProfile in METEOR_IMPACT_PROFILES do
        local detailPart = Instance.new("Part")
        detailPart.Name = "MeteorImpactDetail"
        detailPart.Anchored = true
        detailPart.CanCollide = false
        detailPart.CanQuery = false
        detailPart.CanTouch = false
        detailPart.CastShadow = false
        detailPart.Color = if detailProfile.UseSecondaryColor then secondaryAccentColor else accentColor
        detailPart.Material = Enum.Material.Neon
        detailPart.Size = detailProfile.SizeScale * visualIce.Size
        detailPart.TopSurface = Enum.SurfaceType.Smooth
        detailPart.BottomSurface = Enum.SurfaceType.Smooth
        detailPart.Transparency = 0.14

        local positionScale = detailProfile.PositionScale
        local localPosition = Vector3.new(
            positionScale.X * visualIce.Size.X,
            positionScale.Y * visualIce.Size.Y,
            positionScale.Z * visualIce.Size.Z
        )
        detailPart.CFrame = visualIce.CFrame
            * CFrame.new(localPosition)
            * (detailProfile.Rotation or CFrame.identity)
        detailPart.Parent = visualIce
    end
end

local function getVisualProfile(iceType: string)
    local iceTypeConfig = IceConfig[iceType]
    assert(iceTypeConfig, string.format("Missing IceConfig for Ice type %s", iceType))

    local presentationProfile = iceTypeConfig.PresentationProfile
    local visualProfile = VISUAL_PROFILES[presentationProfile]
    assert(visualProfile, string.format(
        "Missing visual profile %s for Ice type %s",
        tostring(presentationProfile),
        iceType
    ))

    return visualProfile, iceTypeConfig
end

local function addSilhouette(silhouetteProfile: string, visualIce: BasePart)
    local silhouettePieces = SILHOUETTE_PROFILES[silhouetteProfile]
    assert(silhouettePieces, string.format("Unsupported SilhouetteProfile %s", silhouetteProfile))

    for _, piece in silhouettePieces do
        local silhouettePart = Instance.new("Part")
        silhouettePart.Name = "SilhouettePart"
        silhouettePart.Anchored = true
        silhouettePart.CanCollide = false
        silhouettePart.CanQuery = false
        silhouettePart.CanTouch = false
        silhouettePart.CastShadow = false
        silhouettePart.Color = SILHOUETTE_COLOR
        silhouettePart.Material = Enum.Material.SmoothPlastic
        silhouettePart.Shape = piece.Shape or Enum.PartType.Block
        silhouettePart.Size = piece.SizeScale * visualIce.Size
        silhouettePart.TopSurface = Enum.SurfaceType.Smooth
        silhouettePart.BottomSurface = Enum.SurfaceType.Smooth
        silhouettePart.Transparency = 0.05

        local positionScale = piece.PositionScale
        local localPosition = Vector3.new(
            positionScale.X * visualIce.Size.X,
            positionScale.Y * visualIce.Size.Y,
            positionScale.Z * visualIce.Size.Z
        )
        silhouettePart.CFrame = visualIce.CFrame * CFrame.new(localPosition) * (piece.Rotation or CFrame.identity)
        silhouettePart.Parent = visualIce
    end
end

local function addCracks(visualIce: BasePart)
    for _, crackProfile in CRACK_PROFILES do
        local crackPart = Instance.new("Part")
        crackPart.Name = CRACK_NAME
        crackPart.Anchored = true
        crackPart.CanCollide = false
        crackPart.CanQuery = false
        crackPart.CanTouch = false
        crackPart.CastShadow = false
        crackPart.Color = CRACK_COLOR
        crackPart.Material = Enum.Material.SmoothPlastic
        crackPart.Size = crackProfile.SizeScale * visualIce.Size
        crackPart.TopSurface = Enum.SurfaceType.Smooth
        crackPart.BottomSurface = Enum.SurfaceType.Smooth
        crackPart.Transparency = 1

        local positionScale = crackProfile.PositionScale
        local localPosition = Vector3.new(
            positionScale.X * visualIce.Size.X,
            positionScale.Y * visualIce.Size.Y,
            positionScale.Z * visualIce.Size.Z
        )
        crackPart.CFrame = visualIce.CFrame * CFrame.new(localPosition) * crackProfile.Rotation
        crackPart.Parent = visualIce
    end
end

function IceVisualFactory.GetBaseSize(iceType: string): Vector3
    local visualProfile, iceTypeConfig = getVisualProfile(iceType)
    local baseVisualScale = iceTypeConfig.BaseVisualScale or iceTypeConfig.PresentationScale
    assert(
        type(baseVisualScale) == "number" and baseVisualScale > 0,
        string.format("IceConfig.%s.BaseVisualScale must be a positive number", iceType)
    )

    return visualProfile.Size * baseVisualScale
end

function IceVisualFactory.GetScaledSize(iceType: string, weightMultiplier: number): Vector3
    return IceVisualFactory.GetBaseSize(iceType) * SizeConfig.GetVisualScale(weightMultiplier)
end

function IceVisualFactory.GetInteractionPart(visualIce: BasePart): BasePart
    local interactionPart = visualIce:FindFirstChild(INTERACTION_PART_NAME)
    assert(
        interactionPart and interactionPart:IsA("BasePart"),
        string.format("%s must contain a BasePart named %s", visualIce:GetFullName(), INTERACTION_PART_NAME)
    )

    return interactionPart
end

function IceVisualFactory.Create(
    iceType: string,
    silhouetteProfile: string,
    weightMultiplier: number,
    cframe: CFrame,
    parent: Instance
): BasePart
    local visualProfile = getVisualProfile(iceType)
    local baseSize = IceVisualFactory.GetBaseSize(iceType)
    local visualSize = IceVisualFactory.GetScaledSize(iceType, weightMultiplier)

    local visualIce = Instance.new("Part")
    visualIce.Name = iceType .. "Ice"
    visualIce.Anchored = true
    visualIce.CanCollide = false
    visualIce.CanQuery = false
    visualIce.CanTouch = false
    visualIce.CastShadow = false
    visualIce.Color = visualProfile.Color
    visualIce.Material = Enum.Material.Ice
    visualIce.Size = visualSize
    visualIce.TopSurface = Enum.SurfaceType.Smooth
    visualIce.BottomSurface = Enum.SurfaceType.Smooth
    visualIce.Transparency = 0.15
    visualIce.CFrame = cframe
    visualIce:SetAttribute("IceType", iceType)

    local interactionPart = Instance.new("Part")
    interactionPart.Name = INTERACTION_PART_NAME
    interactionPart.Anchored = true
    interactionPart.CanCollide = false
    interactionPart.CanQuery = false
    interactionPart.CanTouch = false
    interactionPart.CastShadow = false
    interactionPart.Size = Vector3.new(1, 1, 1)
    interactionPart.Transparency = 1
    interactionPart.CFrame = cframe * CFrame.new(0, (baseSize.Y - visualSize.Y) * 0.5, 0)
    interactionPart.Parent = visualIce

    local silhouetteCreated, silhouetteError = pcall(addSilhouette, silhouetteProfile, visualIce)
    if not silhouetteCreated then
        visualIce:Destroy()
        error(silhouetteError, 0)
    end

    if visualProfile.DetailStyle == "MeteorImpact" then
        addMeteorImpactDetails(visualIce, visualProfile.AccentColor, visualProfile.SecondaryAccentColor)
    elseif visualProfile.DetailStyle == "BlackFrost" then
        addBlackFrostDetails(visualIce, visualProfile.AccentColor, visualProfile.SecondaryAccentColor)
    elseif visualProfile.AccentColor then
        addAncientRunes(visualIce, visualProfile.AccentColor)
    end

    visualIce.Parent = parent

    return visualIce
end

function IceVisualFactory.ApplyThawStage(visualIce: BasePart, stageName: string)
    local stageProfile = THAW_STAGE_PROFILES[stageName]
    assert(stageProfile, string.format("Unsupported thaw visual stage %s", stageName))

    if visualIce:GetAttribute(THAW_VISUAL_STAGE_ATTRIBUTE) == stageName then
        return
    end

    local iceType = visualIce:GetAttribute("IceType")
    local visualProfile = getVisualProfile(iceType)

    if not visualIce:FindFirstChild(CRACK_NAME) then
        addCracks(visualIce)
    end

    visualIce.Color = visualProfile.Color:Lerp(THAWED_ICE_COLOR, stageProfile.IceColorBlend)
    visualIce.Material = Enum.Material.Ice
    visualIce.Transparency = stageProfile.IceTransparency

    for _, descendant in visualIce:GetDescendants() do
        if descendant:IsA("BasePart") then
            if descendant.Name == "SilhouettePart" then
                descendant.Transparency = stageProfile.SilhouetteTransparency
            elseif descendant.Name == CRACK_NAME then
                descendant.Transparency = stageProfile.CrackTransparency
            end
        end
    end

    visualIce:SetAttribute(THAW_VISUAL_STAGE_ATTRIBUTE, stageName)
end

function IceVisualFactory.ApplyRevealHit(visualIce: BasePart, currentHit: number)
    local crackIndex = 0

    for _, descendant in visualIce:GetDescendants() do
        if descendant:IsA("BasePart") then
            if descendant.Name == CRACK_NAME then
                crackIndex += 1

                if currentHit >= 2 then
                    descendant.Transparency = SECOND_CRACK_TRANSPARENCY
                elseif currentHit >= 1 and crackIndex <= FIRST_CRACK_VISIBLE_PARTS then
                    descendant.Transparency = FIRST_CRACK_TRANSPARENCY
                else
                    descendant.Transparency = 1
                end
            elseif descendant.Name == "SilhouettePart" and currentHit >= 2 then
                descendant.Transparency = SECOND_CRACK_SILHOUETTE_TRANSPARENCY
            end
        end
    end

    if currentHit >= 2 then
        visualIce.Transparency = SECOND_CRACK_ICE_TRANSPARENCY
    end
end

function IceVisualFactory.SetCFrame(visualIce: BasePart, cframe: CFrame)
    local transform = cframe * visualIce.CFrame:Inverse()

    visualIce.CFrame = cframe
    for _, descendant in visualIce:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CFrame = transform * descendant.CFrame
        end
    end
end

return IceVisualFactory
