-- HearthVisualConfig (F-D15-T06B). PRESENTATION ONLY.
-- Gameplay values (levels, costs, training rates, upgrade rules) live in HearthConfig and are never read or
-- duplicated here. 10 functional levels map onto 5 structural families:
--   A = Lv1-2 (survival fire)   B = Lv3-4 (constructed / first runes)   C = Lv5-6 (frostfire forge)
--   D = Lv7-8 (arc furnace / astral engine)   E = Lv9-10 (meteor reactor / mythic heart)
local HearthVisualConfig = {}

local function rgb(r: number, g: number, b: number): Color3
    return Color3.fromRGB(r, g, b)
end

local function range(low: number, high: number): NumberRange
    return NumberRange.new(low, high)
end

-- Locked palette. Orange/gold = warmth, cyan = runic/frost magic, violet/magenta = high tier, white = max power.
local Palette = table.freeze({
    WarmGold = rgb(255, 209, 40),
    FireOrange = rgb(255, 63, 10),
    MeteorCyan = rgb(74, 232, 255),
    BlackIceViolet = rgb(143, 92, 255),
    AwakenedLavender = rgb(150, 125, 255),
    AstralMagenta = rgb(214, 107, 255),
    WhiteGold = rgb(255, 241, 194),
    MeteorDark = rgb(20, 12, 34),
})
HearthVisualConfig.Palette = Palette

-- Neon surfaces render brighter and pinker than particles / beams / lights. These are the Neon-surface inputs that
-- READ as Black-Ice Violet / Awakened Lavender in game (measured in Studio daylight); glow layers keep the locked values.
local NeonColors = table.freeze({
    Violet = rgb(92, 54, 228),
    Lavender = rgb(118, 92, 240),
})
HearthVisualConfig.NeonColors = NeonColors

-- Structural materials (stone / iron). Not glow colours.
HearthVisualConfig.StructureColors = table.freeze({
    Stone = rgb(118, 110, 102),
    StoneDark = rgb(86, 80, 76),
    StoneCool = rgb(72, 74, 90),
    Iron = rgb(60, 58, 63),
    IronDark = rgb(42, 40, 45),
    ForgeIron = rgb(74, 62, 56),
    MeteorStone = rgb(40, 34, 48), -- dark support stone for D/E (makes the core read brighter)
    Coals = rgb(255, 110, 40),
    Smoke = rgb(92, 83, 76),
})

-- Measured on Base1: Pen.PenFloor is 4.66 studs from the Hearth centre, the front fence rail 5.85.
-- Nothing at ground level may extend past this radius (the ~5.5 brief value would clip the Pen floor).
HearthVisualConfig.Footprint = table.freeze({
    MaxGroundRadius = 4.4,
})

-- One shared update loop for slow rune motion / pulses (server time keeps every client in sync).
HearthVisualConfig.Motion = table.freeze({
    UpdateHz = 20,
})

-- LOD foundation for visitor Hearths (owner Hearth always renders fully).
HearthVisualConfig.Lod = table.freeze({
    LightsOffBeyond = 60,
    ParticlesOffBeyond = 90,
})

-- Visitor Hearths render only once the server exposes a replicated, read-only level on the Hearth model.
-- Leave disabled until HearthService sets the attribute (Systems-owned).
HearthVisualConfig.VisitorRendering = table.freeze({
    Enabled = false,
    LevelAttribute = "HearthLevel",
})

-- Upgrade transition (presentation only; gameplay has already changed server-side). Total ~1.1 s.
HearthVisualConfig.Transition = table.freeze({
    CompressTime = 0.22, -- 1. old core compresses / dims
    CompressScale = 0.55,
    CompressLight = 0.35,
    SwapDelay = 0.26, -- 5. new stage appears at the peak
    PopScale = 1.35, -- new core starts oversized, settles
    SettleTime = 0.55,
    LightSwellBrightness = 3.2, -- 3. light swell (multiplier of the new stage light)
    LightSwellRange = 1.5,
    LightSettleTime = 0.85,
    RuneFlashTime = 0.6, -- 4. rune / magic flash
    RingStartRadius = 0.8, -- 6. outward energy ring (never past Footprint.MaxGroundRadius)
    RingThickness = 0.14,
    RingTime = 0.6,
    RingTransparency = 0.12,
    BillboardPunchScale = 1.22, -- 7. HearthStatus emphasis
    BillboardPunchTime = 0.5,
    BurstEmbers = 18, -- 2. ember burst: base + per-intensity
    BurstEmbersPerIntensity = 30,
    BurstSparks = 10,
    BurstSparksPerIntensity = 20,
    BurstMagic = 12,
})

HearthVisualConfig.Families = table.freeze({
    A = table.freeze({ Name = "Survival Fire", Levels = { 1, 2 }, Implemented = true }),
    B = table.freeze({ Name = "Constructed Hearth", Levels = { 3, 4 }, Implemented = true }),
    C = table.freeze({ Name = "Frostfire Forge", Levels = { 5, 6 }, Implemented = true }),
    D = table.freeze({ Name = "Arc / Astral Forge", Levels = { 7, 8 }, Implemented = true }),
    E = table.freeze({ Name = "Meteor / Great Frost", Levels = { 9, 10 }, Implemented = true }),
})

local Levels = {}

-- ===================== FAMILY A: survival fire -> strong reliable Hearth =====================
Levels[1] = {
    DisplayName = "Small Hearth",
    Family = "A",
    Intensity = 0.15,
    Accent = Palette.WarmGold,
    BillboardHeight = 6.5,
    Structure = {
        DaisRadius = 4.2, -- covers the hidden HearthBase collider (8 studs long) and nothing more
        DaisHeight = 0.9,
        BedRadius = 1.3,
        BedHeight = 0.22,
        StoneCount = 6,
        StoneRingRadius = 1.75,
        StoneSize = Vector3.new(0.95, 0.7, 0.75),
    },
    Core = { Size = Vector3.new(1.1, 1.25, 1.1), Lift = 0.3, Color = Palette.WarmGold, Transparency = 0.12 },
    Shell = { Size = Vector3.new(1.6, 2, 1.6), Color = Palette.FireOrange, Transparency = 0.55, Material = "Neon" },
    Flame = { Size = 3.6, Heat = 5, Color = Palette.WarmGold, SecondaryColor = Palette.FireOrange },
    Smoke = { Opacity = 0.06, Size = 2.2, RiseVelocity = 2.2 },
    Embers = { Rate = 3, Speed = range(3, 5), Lifetime = range(0.9, 1.4), Size = 0.16,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    WarmLight = { Brightness = 1.5, Range = 16, Color = rgb(255, 150, 60) },
}

Levels[2] = {
    DisplayName = "Strong Hearth",
    Family = "A",
    Intensity = 0.3,
    Accent = Palette.WarmGold,
    BillboardHeight = 7,
    Structure = {
        DaisRadius = 4.2,
        DaisHeight = 0.9,
        BedRadius = 1.4,
        BedHeight = 0.26,
        StoneCount = 6, -- same structure, bigger / hotter fire
        StoneRingRadius = 1.8,
        StoneSize = Vector3.new(1.05, 0.85, 0.8),
    },
    Core = { Size = Vector3.new(1.45, 1.8, 1.45), Lift = 0.32,
        Color = Palette.WarmGold:Lerp(Palette.WhiteGold, 0.4), Transparency = 0.04 },
    Shell = { Size = Vector3.new(2.2, 2.8, 2.2), Color = Palette.FireOrange, Transparency = 0.48, Material = "Neon" },
    Flame = { Size = 5, Heat = 7, Color = Palette.WarmGold, SecondaryColor = Palette.FireOrange },
    Smoke = { Opacity = 0.08, Size = 2.8, RiseVelocity = 2.8 },
    Embers = { Rate = 6, Speed = range(4, 6.5), Lifetime = range(0.9, 1.5), Size = 0.18,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    Sparks = { Rate = 4, Speed = range(7, 11), Lifetime = range(0.45, 0.85), Size = 0.12,
        Color0 = Palette.WhiteGold, Color1 = Palette.WarmGold },
    WarmLight = { Brightness = 2.1, Range = 20, Color = rgb(255, 158, 66) },
}

-- ===================== FAMILY B: constructed Hearth -> first unmistakable runic magic =====================
Levels[3] = {
    DisplayName = "Iron Brazier",
    Family = "B",
    Intensity = 0.45,
    Accent = Palette.WarmGold,
    BillboardHeight = 8.5,
    Structure = {
        DaisRadius = 4.2,
        DaisHeight = 0.8,
        ColumnRadius = 0.6,
        ColumnHeight = 1.5,
        BowlRadius = 1.85,
        BowlHeight = 0.6,
        BedRadius = 1.6,
        PostBaseRadius = 2.6,
        PostTopRadius = 2.15,
        PostTop = 5.2,
        PostWidth = 0.32,
    },
    Core = { Size = Vector3.new(1.5, 2, 1.5), Lift = 0.32,
        Color = Palette.WarmGold:Lerp(Palette.WhiteGold, 0.55), Transparency = 0 },
    Shell = { Size = Vector3.new(2.4, 3.2, 2.4), Color = Palette.FireOrange, Transparency = 0.45, Material = "Neon" },
    Flame = { Size = 6.5, Heat = 10, Color = Palette.WarmGold, SecondaryColor = Palette.FireOrange },
    Smoke = { Opacity = 0.1, Size = 3.2, RiseVelocity = 4.2 },
    Embers = { Rate = 9, Speed = range(5, 8), Lifetime = range(1, 1.6), Size = 0.19,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    Sparks = { Rate = 7, Speed = range(9, 14), Lifetime = range(0.45, 0.85), Size = 0.13,
        Color0 = Palette.WhiteGold, Color1 = Palette.WarmGold },
    -- Extremely subtle magic hint: a few pale motes with only a trace of cyan.
    Motes = { Rate = 1, Lifetime = range(2, 3), Size = 0.14, Transparency = 0.55,
        Color0 = Palette.WhiteGold, Color1 = Palette.WhiteGold:Lerp(Palette.MeteorCyan, 0.35) },
    WarmLight = { Brightness = 2.8, Range = 24, Color = rgb(255, 164, 70) },
}

Levels[4] = {
    DisplayName = "Runic Hearth",
    Family = "B",
    Intensity = 0.6,
    Accent = Palette.MeteorCyan,
    BillboardHeight = 9,
    Structure = {
        DaisRadius = 4.2,
        DaisHeight = 0.8,
        ColumnRadius = 0.6,
        ColumnHeight = 1.6,
        BowlRadius = 1.9,
        BowlHeight = 0.62,
        BedRadius = 1.65,
        PostBaseRadius = 2.6,
        PostTopRadius = 2.15,
        PostTop = 5.6,
        PostWidth = 0.32,
    },
    Core = { Size = Vector3.new(1.6, 2.2, 1.6), Lift = 0.32,
        Color = Palette.WarmGold:Lerp(Palette.WhiteGold, 0.6), Transparency = 0 },
    Shell = { Size = Vector3.new(2.6, 3.4, 2.6), Color = Palette.FireOrange, Transparency = 0.45, Material = "Neon" },
    Flame = { Size = 7.5, Heat = 11, Color = Palette.WarmGold, SecondaryColor = Palette.FireOrange },
    Smoke = { Opacity = 0.1, Size = 3.4, RiseVelocity = 4.5 },
    Embers = { Rate = 11, Speed = range(5, 8.5), Lifetime = range(1, 1.6), Size = 0.2,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    Sparks = { Rate = 8, Speed = range(9, 14), Lifetime = range(0.45, 0.85), Size = 0.13,
        Color0 = Palette.WhiteGold, Color1 = Palette.WarmGold },
    -- MILESTONE: cyan runic magic (supersedes the old warm-gold runes).
    Motes = { Rate = 5, Lifetime = range(1.8, 2.6), Size = 0.32, Transparency = 0.15,
        Color0 = Palette.MeteorCyan, Color1 = Palette.MeteorCyan:Lerp(Palette.WhiteGold, 0.3) },
    Runes = {
        PulsePeriod = 3,
        TransparencyMin = 0.02,
        TransparencyMax = 0.45,
        Rings = {
            { Count = 8, Radius = 3, Height = 3.7, Size = 0.72, Color = Palette.MeteorCyan, SpinDegPerSec = 6, Bob = 0.1 },
        },
    },
    MagicLight = { Brightness = 0.9, Range = 11, Color = Palette.MeteorCyan },
    WarmLight = { Brightness = 3.2, Range = 26, Color = rgb(255, 170, 74) },
}

-- ===================== FAMILY C: frostfire forge -> great magical furnace =====================
Levels[5] = {
    DisplayName = "Frostfire Forge",
    Family = "C",
    Intensity = 0.8,
    Accent = Palette.MeteorCyan,
    BillboardHeight = 11,
    Structure = {
        DaisRadius = 4.3,
        DaisHeight = 0.8,
        TierRadius = 3,
        TierHeight = 0.5,
        ColumnRadius = 0.7,
        ColumnHeight = 1.8,
        BowlRadius = 2.1,
        BowlHeight = 0.7,
        BedRadius = 1.85,
        PostBaseRadius = 2.75,
        PostTopRadius = 2.3,
        PostTop = 7.4,
        PostWidth = 0.36,
        AuraSize = 6.4, -- invisible emitter volume for wisps / inflowing energy
    },
    -- Layered colour: white-gold core, orange Fire, cyan frostfire shell.
    Core = { Size = Vector3.new(1.8, 2.5, 1.8), Lift = 0.34,
        Color = Palette.WhiteGold:Lerp(Palette.WarmGold, 0.45), Transparency = 0 },
    Shell = { Size = Vector3.new(3.2, 4.4, 3.2), Color = Palette.MeteorCyan, Transparency = 0, Material = "ForceField" },
    Flame = { Size = 8, Heat = 11, Color = rgb(255, 150, 45), SecondaryColor = Palette.FireOrange },
    -- Frostfire: a cyan flame layer wrapped around the warm core (rises above it as a cyan crown).
    FrostFlame = { Size = 6, Heat = 15, Color = Palette.MeteorCyan,
        SecondaryColor = Palette.MeteorCyan:Lerp(Palette.BlackIceViolet, 0.2) },
    Smoke = { Opacity = 0.04, Size = 3, RiseVelocity = 4 },
    Embers = { Rate = 12, Speed = range(5, 9), Lifetime = range(1, 1.6), Size = 0.2,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    Motes = { Rate = 6, Lifetime = range(1.8, 2.6), Size = 0.38, Transparency = 0.1,
        Color0 = Palette.MeteorCyan, Color1 = Palette.MeteorCyan:Lerp(Palette.WhiteGold, 0.3) },
    Inflow = { Rate = 6, Speed = range(3, 3.6), Lifetime = range(0.85, 1.05), Size = 0.36,
        Color0 = Palette.MeteorCyan, Color1 = Palette.WarmGold },
    -- First restrained violet: an accent, never dominant.
    Arcane = { Rate = 1.5, Speed = range(4, 7), Lifetime = range(0.6, 1), Size = 0.2,
        Color0 = Palette.BlackIceViolet, Color1 = Palette.AwakenedLavender },
    Runes = {
        PulsePeriod = 2.8,
        TransparencyMin = 0,
        TransparencyMax = 0.35,
        Rings = {
            { Count = 8, Radius = 3.1, Height = 4.5, Size = 0.7, Color = Palette.MeteorCyan, SpinDegPerSec = 7, Bob = 0.12 },
        },
    },
    MagicLight = { Brightness = 1.3, Range = 14, Color = Palette.MeteorCyan },
    -- F-D15-T06D: late WarmLight plateaus (no Pen / Ice / creature whiteout); prestige comes from core, crystals,
    -- runes, beams, aura and MagicLight. Brightness / Range still rise every level.
    WarmLight = { Brightness = 3.25, Range = 27, Color = rgb(255, 174, 90) },
}

Levels[6] = {
    DisplayName = "Great Runic Furnace",
    Family = "C",
    Intensity = 1,
    Accent = Palette.MeteorCyan,
    BillboardHeight = 12,
    Structure = {
        DaisRadius = 4.3,
        DaisHeight = 0.8,
        TierRadius = 3,
        TierHeight = 0.6,
        ColumnRadius = 0.7,
        ColumnHeight = 2,
        BowlRadius = 2.15,
        BowlHeight = 0.75,
        BedRadius = 1.9,
        PostBaseRadius = 2.75,
        PostTopRadius = 2.25,
        PostTop = 8.4,
        PostWidth = 0.38,
        AuraSize = 7,
    },
    Core = { Size = Vector3.new(2, 2.8, 2), Lift = 0.34,
        Color = Palette.WhiteGold:Lerp(Palette.WarmGold, 0.3), Transparency = 0 },
    Shell = { Size = Vector3.new(3.6, 5, 3.6), Color = Palette.MeteorCyan, Transparency = 0, Material = "ForceField" },
    Flame = { Size = 9, Heat = 12, Color = rgb(255, 160, 50), SecondaryColor = Palette.FireOrange },
    FrostFlame = { Size = 7.5, Heat = 18, Color = Palette.MeteorCyan,
        SecondaryColor = Palette.MeteorCyan:Lerp(Palette.BlackIceViolet, 0.35) },
    Smoke = { Opacity = 0.04, Size = 3.2, RiseVelocity = 4.5 },
    Embers = { Rate = 14, Speed = range(5.5, 9.5), Lifetime = range(1, 1.7), Size = 0.21,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    Motes = { Rate = 9, Lifetime = range(1.8, 2.8), Size = 0.42, Transparency = 0.05,
        Color0 = Palette.MeteorCyan, Color1 = Palette.MeteorCyan:Lerp(Palette.WhiteGold, 0.3) },
    Inflow = { Rate = 10, Speed = range(3.2, 3.8), Lifetime = range(0.85, 1.05), Size = 0.4,
        Color0 = Palette.MeteorCyan, Color1 = Palette.WarmGold },
    Arcane = { Rate = 4, Speed = range(4, 8), Lifetime = range(0.6, 1.1), Size = 0.22,
        Color0 = Palette.BlackIceViolet, Color1 = Palette.AwakenedLavender },
    Runes = {
        PulsePeriod = 2.4,
        TransparencyMin = 0,
        TransparencyMax = 0.3,
        Rings = {
            { Count = 8, Radius = 3.1, Height = 4.6, Size = 0.76, Color = Palette.MeteorCyan, SpinDegPerSec = 8, Bob = 0.12 },
            -- Upper counter-rotating ring with a faint lavender tint: sets up the Lv7 violet read.
            { Count = 4, Radius = 2, Height = 7.2, Size = 0.56,
                Color = Palette.MeteorCyan:Lerp(Palette.AwakenedLavender, 0.35), SpinDegPerSec = -11, Bob = 0.16 },
        },
    },
    MagicLight = { Brightness = 1.6, Range = 16, Color = Palette.MeteorCyan },
    WarmLight = { Brightness = 3.28, Range = 28, Color = rgb(255, 175, 94) },
}

-- ===================== FAMILY D: magical furnace -> astral warmth engine =====================
-- Beams use soft-ended colour gradients (no texture): the shared aurora texture read too faint at Hearth scale.

Levels[7] = {
    DisplayName = "Runic Arc Furnace",
    Family = "D",
    Intensity = 1.1,
    Accent = Palette.BlackIceViolet,
    BillboardHeight = 13,
    -- MILESTONE: violet arc energy.
    TransitionStyle = { RingColors = { Palette.BlackIceViolet, Palette.MeteorCyan } },
    Structure = {
        DaisRadius = 4.3,
        DaisHeight = 0.8,
        TierRadius = 3.1,
        TierHeight = 0.6,
        ColumnRadius = 0.75,
        ColumnHeight = 2,
        BowlRadius = 2.1,
        BowlHeight = 0.8,
        BowlMaterial = "Metal",
        BowlColor = "ForgeIron",
        BedRadius = 1.85,
        BandColor = Palette.MeteorCyan, -- cyan emissive channel around the bowl
        -- Four crystal / rune nodes replace the forged posts.
        NodeCount = 4,
        NodeRadius = 3.15,
        NodeWidth = 0.8,
        NodeHeight = 3,
        CrystalWidth = 0.6,
        CrystalLength = 3,
        CrystalTilt = 10,
        CrystalColor = NeonColors.Violet,
        AuraSize = 7,
    },
    Core = { Size = Vector3.new(2, 2.8, 2), Lift = 0.34,
        Color = Palette.WhiteGold:Lerp(Palette.WarmGold, 0.3), Transparency = 0 },
    Shell = { Size = Vector3.new(3.6, 5, 3.6), Color = Palette.MeteorCyan, Transparency = 0.05, Material = "ForceField" },
    Flame = { Size = 9, Heat = 12, Color = rgb(255, 160, 50), SecondaryColor = Palette.FireOrange },
    FrostFlame = { Size = 7, Heat = 18, Color = Palette.MeteorCyan,
        SecondaryColor = Palette.MeteorCyan:Lerp(Palette.BlackIceViolet, 0.55) },
    Embers = { Rate = 14, Speed = range(5.5, 9.5), Lifetime = range(1, 1.7), Size = 0.21,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    -- Violet becomes a major layer: strong violet wisps.
    Motes = { Rate = 9, Lifetime = range(2, 3), Size = 0.46, Transparency = 0.05,
        Color0 = Palette.BlackIceViolet, Color1 = Palette.AwakenedLavender },
    Orbit = { Height = 8.6, Radius = 2.5, Tilt = 14, SpinDegPerSec = 28, Rate = 10, Lifetime = range(2.2, 3),
        Size = 0.32, Color0 = Palette.MeteorCyan, Color1 = Palette.BlackIceViolet },
    Inflow = { Rate = 10, Speed = range(3.2, 3.8), Lifetime = range(0.85, 1.05), Size = 0.4,
        Color0 = Palette.MeteorCyan, Color1 = Palette.WarmGold },
    Arcane = { Rate = 5, Speed = range(4, 8), Lifetime = range(0.6, 1.1), Size = 0.24,
        Color0 = Palette.BlackIceViolet, Color1 = Palette.AwakenedLavender },
    Runes = {
        PulsePeriod = 2.4,
        TransparencyMin = 0,
        TransparencyMax = 0.3,
        Rings = {
            -- Staggered (alternating heights) for slightly more complex but readable motion.
            { Count = 6, Radius = 2.65, Height = 5.3, Size = 0.66, Color = Palette.MeteorCyan, SpinDegPerSec = 10,
                Bob = 0.12, Stagger = 0.4 },
        },
    },
    -- Slow, controlled arcs from crystal tips into the core (max 2, fading in/out, never flickering).
    Arcs = { Count = 2, Target = "Core", Period = 4.5, Width0 = 0.32, Width1 = 0.16, CurveSize0 = 2.4, CurveSize1 = 2.4,
        Transparency = 0.15, Color0 = Palette.BlackIceViolet, Color1 = Palette.MeteorCyan, Brightness = 1.8, LightEmission = 0.35 },
    MagicLight = { Brightness = 1.8, Range = 18, Color = Palette.BlackIceViolet:Lerp(Palette.MeteorCyan, 0.3) },
    WarmLight = { Brightness = 3.31, Range = 29, Color = rgb(255, 176, 98) },
}

Levels[8] = {
    DisplayName = "Astral Warmth Forge",
    Family = "D",
    Intensity = 1.2,
    Accent = Palette.AwakenedLavender,
    BillboardHeight = 14.5,
    -- MILESTONE: astral / floating / aurora.
    TransitionStyle = { RingColors = { Palette.WhiteGold, Palette.AwakenedLavender } },
    Structure = {
        DaisRadius = 4.3,
        DaisHeight = 0.8,
        TierRadius = 3.1,
        TierHeight = 0.6,
        ColumnRadius = 0.55, -- lighter, less forged
        ColumnHeight = 2,
        BowlRadius = 2,
        BowlHeight = 0.6,
        BowlMaterial = "Slate",
        BowlColor = "StoneCool",
        BedRadius = 1.75,
        BandColor = Palette.MeteorCyan,
        NodeCount = 4,
        NodeRadius = 3.15,
        NodeWidth = 0.7,
        NodeHeight = 2.4,
        CrystalWidth = 0.55,
        CrystalLength = 4.4, -- taller, refined
        CrystalTilt = 5,
        CrystalColor = NeonColors.Lavender,
        AuraSize = 7.4,
    },
    Core = { Size = Vector3.new(2.2, 3, 2.2), Lift = 0.34,
        Color = Palette.WhiteGold:Lerp(Palette.WarmGold, 0.15), Transparency = 0 },
    Shell = { Size = Vector3.new(3.8, 5.2, 3.8), Color = Palette.MeteorCyan:Lerp(Palette.AwakenedLavender, 0.25),
        Transparency = 0.05, Material = "ForceField" },
    Flame = { Size = 9, Heat = 13, Color = rgb(255, 175, 70), SecondaryColor = Palette.FireOrange },
    FrostFlame = { Size = 6.5, Heat = 18, Color = Palette.MeteorCyan, SecondaryColor = Palette.AwakenedLavender },
    Embers = { Rate = 14, Speed = range(5.5, 9.5), Lifetime = range(1, 1.7), Size = 0.21,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    -- Soft aurora-like wisps.
    Motes = { Rate = 10, Lifetime = range(2, 3), Size = 0.5, Transparency = 0.1,
        Color0 = Palette.AwakenedLavender, Color1 = Palette.MeteorCyan },
    Orbit = { Height = 9.5, Radius = 2.7, Tilt = 18, SpinDegPerSec = 24, Rate = 14, Lifetime = range(2.2, 3),
        Size = 0.34, Color0 = Palette.WhiteGold, Color1 = Palette.AwakenedLavender },
    Inflow = { Rate = 10, Speed = range(3.2, 3.8), Lifetime = range(0.85, 1.05), Size = 0.4,
        Color0 = Palette.MeteorCyan, Color1 = Palette.WarmGold },
    Arcane = { Rate = 4, Speed = range(4, 8), Lifetime = range(0.6, 1.1), Size = 0.24,
        Color0 = Palette.BlackIceViolet, Color1 = Palette.AstralMagenta },
    Runes = { PulsePeriod = 2.6, TransparencyMin = 0, TransparencyMax = 0.3, Rings = {} },
    -- Floating rune fragments replace the fixed rune ring (deterministic, no physics).
    Fragments = {
        { Radius = 2.9, Height = 7.4, Size = 0.8, Speed = 12, Phase = 0, Bob = 0.25, Spin = 40, Color = Palette.MeteorCyan },
        { Radius = 2.4, Height = 9, Size = 0.6, Speed = 12, Phase = 60, Bob = 0.3, Spin = -55, Color = Palette.MeteorCyan },
        { Radius = 3, Height = 8.2, Size = 0.7, Speed = 12, Phase = 120, Bob = 0.25, Spin = 35, Color = NeonColors.Lavender },
        { Radius = 2.2, Height = 10.4, Size = 0.55, Speed = 12, Phase = 180, Bob = 0.3, Spin = -45, Color = Palette.MeteorCyan },
        { Radius = 2.8, Height = 7.8, Size = 0.75, Speed = 12, Phase = 240, Bob = 0.25, Spin = 50, Color = Palette.MeteorCyan },
        { Radius = 2.5, Height = 9.6, Size = 0.6, Speed = 12, Phase = 300, Bob = 0.3, Spin = -40,
            Color = Palette.AstralMagenta:Lerp(Palette.AwakenedLavender, 0.5) },
    },
    -- Violet / magenta streams rising from crystal tips into a point above the flame.
    Arcs = { Count = 2, Target = "Apex", ApexHeight = 11.6, Period = 5, Width0 = 0.35, Width1 = 0.75,
        CurveSize0 = 3, CurveSize1 = -2.5, Transparency = 0.3, Color0 = Palette.BlackIceViolet, Color1 = Palette.AstralMagenta,
        Brightness = 1.6, LightEmission = 0.3 },
    -- One small localized aurora ribbon (half-turn) circling the upper silhouette. Not a curtain.
    Ribbons = {
        { SpinDegPerSec = 18, Width0 = 0.9, Width1 = 0.6, Transparency = 0.3, Brightness = 1.6, LightEmission = 0.3,
            Colors = { Palette.MeteorCyan, Palette.AwakenedLavender },
            Points = { { Angle = 0, Height = 9.8, Radius = 2.8 }, { Angle = 180, Height = 10.6, Radius = 2.6 } } },
    },
    MagicLight = { Brightness = 2, Range = 20, Color = Palette.AwakenedLavender:Lerp(Palette.MeteorCyan, 0.3) },
    WarmLight = { Brightness = 3.34, Range = 30, Color = rgb(255, 177, 101) },
}

-- ===================== FAMILY E: meteor-infused reactor -> mythic heart of warmth =====================
Levels[9] = {
    DisplayName = "Meteor Hearth",
    Family = "E",
    Intensity = 1.35,
    Accent = Palette.BlackIceViolet,
    BillboardHeight = 17,
    -- MILESTONE: meteor-dark reactor ignites to a white-hot centre.
    TransitionStyle = { RingColors = { Palette.BlackIceViolet, Palette.MeteorCyan }, CoreStart = Palette.MeteorDark },
    Structure = {
        DaisRadius = 4.3,
        DaisHeight = 0.8,
        TierRadius = 3.2,
        TierHeight = 0.7,
        PedestalRadius = 1.1,
        PedestalHeight = 1.3,
        -- Dark meteor housing: three cracked petals cradling the core; bright fissures on their inner faces.
        PetalCount = 3,
        PetalRadius = 1.75,
        PetalWidth = 1.7,
        PetalHeight = 4,
        PetalThickness = 0.6,
        PetalTilt = 22,
        PetalBase = 2.4,
        FissureWidth = 0.3,
        FissureColors = { Palette.MeteorCyan, Palette.FireOrange, Palette.BlackIceViolet },
        -- Refined crystal supports rising behind each petal.
        CrystalCount = 3,
        CrystalRadius = 3.3,
        CrystalWidth = 0.55,
        CrystalBottom = 2.6,
        CrystalTop = 11.4,
        CrystalTilt = -4,
        CrystalColor = NeonColors.Violet,
        CrystalBase = { Width = 0.9, Height = 1.1 },
        CoreHeight = 5.6,
    },
    Core = { Size = Vector3.new(2.2, 2.2, 2.2), Lift = 0, Color = Palette.WhiteGold, Transparency = 0 },
    Shell = { Size = Vector3.new(3.3, 3.3, 3.3), Color = Palette.FireOrange, Transparency = 0.6, Material = "Neon" }, -- heat layer
    -- Violet aura stays light so it never tints the white-gold core at distance.
    AuraShell = { Size = Vector3.new(6.2, 6.6, 6.2), Color = Palette.BlackIceViolet, Transparency = 0.4, Material = "ForceField",
        Breath = { Period = 4, TransparencyMin = 0.3, TransparencyMax = 0.6 } },
    Flame = { Size = 6, Heat = 9, Color = rgb(255, 170, 60), SecondaryColor = Palette.FireOrange },
    Embers = { Rate = 12, Speed = range(5.5, 9.5), Lifetime = range(1, 1.7), Size = 0.21,
        Color0 = Palette.WhiteGold, Color1 = Palette.FireOrange },
    Stars = { Rate = 4, Lifetime = range(1.6, 2.6), Size = 0.36, Color0 = Palette.WhiteGold, Color1 = Palette.MeteorCyan },
    Orbit = { Height = 10.4, Radius = 2.9, Tilt = 16, SpinDegPerSec = 20, Rate = 12, Lifetime = range(2.2, 3),
        Size = 0.3, Color0 = Palette.WhiteGold, Color1 = Palette.BlackIceViolet },
    -- Restrained, diffuse, short violet plume (Hearth-local; never a column).
    Plume = { Rate = 6, Speed = range(3.5, 4.5), Lifetime = range(1.8, 2.2), Size = 1.8, EndSize = 3.6, Transparency = 0.4,
        Color0 = Palette.BlackIceViolet, Color1 = Palette.AwakenedLavender },
    Inflow = { Rate = 8, Speed = range(3.2, 3.8), Lifetime = range(0.85, 1.05), Size = 0.36,
        Color0 = Palette.BlackIceViolet, Color1 = Palette.WhiteGold },
    Runes = {
        PulsePeriod = 3,
        TransparencyMin = 0.05,
        TransparencyMax = 0.35,
        Rings = {
            { Count = 6, Radius = 3.7, Height = 2.3, Size = 0.6, Color = Palette.MeteorCyan, SpinDegPerSec = 8, Bob = 0.08 },
        },
    },
    Arcs = { Count = 2, Target = "Core", Period = 5, Width0 = 0.28, Width1 = 0.14, CurveSize0 = 2.2, CurveSize1 = 2.2,
        Transparency = 0.2, Color0 = Palette.BlackIceViolet, Color1 = Palette.MeteorCyan, Brightness = 1.8, LightEmission = 0.35 },
    MagicLight = { Brightness = 2.2, Range = 20, Color = Palette.BlackIceViolet },
    WarmLight = { Brightness = 3.37, Range = 31, Color = rgb(255, 178, 104) },
}

Levels[10] = {
    DisplayName = "Heart of the Great Frost",
    Family = "E",
    Intensity = 1.5,
    Accent = Palette.WhiteGold,
    BillboardHeight = 19,
    -- MILESTONE: unified mythic aurora heart.
    TransitionStyle = { RingColors = { Palette.MeteorCyan, Palette.BlackIceViolet, Palette.AstralMagenta },
        CoreStart = Color3.new(1, 1, 1), LightSwell = 4 },
    Structure = {
        DaisRadius = 4.3,
        DaisHeight = 0.8,
        TierRadius = 3.2,
        TierHeight = 0.7,
        PedestalRadius = 1,
        PedestalHeight = 1.4,
        PetalCount = 3, -- slimmer, taller, more elegant than Lv9
        PetalRadius = 1.7,
        PetalWidth = 1.3,
        PetalHeight = 4.8,
        PetalThickness = 0.5,
        PetalTilt = 17,
        PetalBase = 2.5,
        FissureWidth = 0.3,
        FissureColors = { Palette.MeteorCyan, Palette.MeteorCyan, Palette.MeteorCyan }, -- cyan runic channels
        FissurePulse = true,
        CrystalCount = 3, -- floating crystals (no bases)
        CrystalRadius = 3.4,
        CrystalWidth = 0.5,
        CrystalBottom = 4,
        CrystalTop = 13,
        CrystalTilt = -3,
        CrystalColor = NeonColors.Violet,
        CoreHeight = 6.2,
    },
    Core = { Size = Vector3.new(3, 3, 3), Lift = 0, Color = Palette.WhiteGold, Transparency = 0 },
    Shell = { Size = Vector3.new(4.2, 4.2, 4.2), Color = Palette.FireOrange, Transparency = 0.62, Material = "Neon" },
    AuraShell = { Size = Vector3.new(6.8, 7.4, 6.8), Color = Palette.BlackIceViolet, Transparency = 0.45, Material = "ForceField",
        Breath = { Period = 4.5, TransparencyMin = 0.35, TransparencyMax = 0.65 } },
    Flame = { Size = 7, Heat = 10, Color = rgb(255, 185, 80), SecondaryColor = Palette.FireOrange },
    Embers = { Rate = 14, Speed = range(5.5, 9.5), Lifetime = range(1, 1.7), Size = 0.22,
        Color0 = Palette.WarmGold, Color1 = Palette.FireOrange },
    Stars = { Rate = 5, Lifetime = range(1.6, 2.6), Size = 0.38, Color0 = Palette.WhiteGold, Color1 = Palette.MeteorCyan },
    Orbit = { Height = 11.2, Radius = 3.1, Tilt = 12, SpinDegPerSec = 18, Rate = 14, Lifetime = range(2.2, 3),
        Size = 0.32, Color0 = Palette.WhiteGold, Color1 = Palette.AwakenedLavender },
    Inflow = { Rate = 10, Speed = range(3.2, 3.8), Lifetime = range(0.85, 1.05), Size = 0.38,
        Color0 = Palette.MeteorCyan, Color1 = Palette.WhiteGold },
    Arcane = { Rate = 2.5, Speed = range(4, 8), Lifetime = range(0.6, 1.1), Size = 0.22, -- magenta accent only
        Color0 = Palette.AstralMagenta, Color1 = Palette.AwakenedLavender },
    Runes = { PulsePeriod = 3.2, TransparencyMin = 0, TransparencyMax = 0.35, Rings = {} },
    Fragments = {
        { Radius = 2.8, Height = 9.2, Size = 0.75, Speed = 10, Phase = 0, Bob = 0.25, Spin = 35, Color = Palette.MeteorCyan },
        { Radius = 2.4, Height = 11, Size = 0.6, Speed = 10, Phase = 72, Bob = 0.3, Spin = -45, Color = Palette.MeteorCyan },
        { Radius = 2.9, Height = 10, Size = 0.7, Speed = 10, Phase = 144, Bob = 0.25, Spin = 40, Color = Palette.MeteorCyan },
        { Radius = 2.3, Height = 12.4, Size = 0.55, Speed = 10, Phase = 216, Bob = 0.3, Spin = -50, Color = NeonColors.Lavender },
        { Radius = 2.6, Height = 13.4, Size = 0.5, Speed = 10, Phase = 288, Bob = 0.3, Spin = 45, Color = Palette.MeteorCyan },
    },
    -- Localized aurora spiral: ~0.9 helix turn (3 Beams) rising from 6.6 to 15.2 studs and tapering in.
    Ribbons = {
        { SpinDegPerSec = 14, Width0 = 1.1, Width1 = 0.55, Transparency = 0.22, Brightness = 1.6, LightEmission = 0.3,
            Colors = { Palette.MeteorCyan, Palette.BlackIceViolet, Palette.BlackIceViolet, Palette.AstralMagenta },
            Points = {
                { Angle = 0, Height = 6.6, Radius = 3 },
                { Angle = 110, Height = 9.6, Radius = 2.7 },
                { Angle = 220, Height = 12.4, Radius = 2.3 },
                { Angle = 320, Height = 15.2, Radius = 1.7 },
            } },
    },
    MagicLight = { Brightness = 2.4, Range = 22, Color = Palette.BlackIceViolet:Lerp(Palette.MeteorCyan, 0.25) },
    WarmLight = { Brightness = 3.4, Range = 32, Color = rgb(255, 178, 106) },
}

HearthVisualConfig.MaxLevel = 10

-- Returns the definition that should be rendered for a functional level (D/E fall back), or nil if unknown.
function HearthVisualConfig.GetPresentation(level: number): any?
    if type(level) ~= "number" or level % 1 ~= 0 then
        return nil
    end
    local definition = Levels[level]
    if definition == nil then
        return nil
    end
    if definition.Implemented == false then
        return Levels[definition.FallbackLevel]
    end
    return definition
end

function HearthVisualConfig.GetDisplayName(level: number): string?
    local definition = Levels[level]
    return if definition then definition.DisplayName else nil
end

-- Load-time validation: every level resolves, implemented levels belong to A-C and respect the ground footprint.
local maxRadius = HearthVisualConfig.Footprint.MaxGroundRadius
for level = 1, HearthVisualConfig.MaxLevel do
    local definition = Levels[level]
    assert(definition and type(definition.DisplayName) == "string", string.format("HearthVisualConfig level %d missing", level))
    assert(HearthVisualConfig.Families[definition.Family], string.format("HearthVisualConfig level %d has unknown family", level))
    local presentation = HearthVisualConfig.GetPresentation(level)
    assert(presentation and presentation.Implemented ~= false, string.format("HearthVisualConfig level %d does not resolve", level))
    local structure = presentation.Structure
    assert(structure.DaisRadius <= maxRadius, string.format("HearthVisualConfig level %d dais exceeds footprint", level))
    if structure.PostBaseRadius then
        assert(structure.PostBaseRadius + structure.PostWidth <= maxRadius, string.format("HearthVisualConfig level %d posts exceed footprint", level))
    end
    if presentation.Runes then
        for _, ring in presentation.Runes.Rings do
            assert(ring.Radius + ring.Size <= maxRadius, string.format("HearthVisualConfig level %d rune ring exceeds footprint", level))
        end
    end
    if structure.NodeRadius then
        assert(structure.NodeRadius + structure.NodeWidth * 0.75 <= maxRadius, string.format("HearthVisualConfig level %d nodes exceed footprint", level))
    end
    if structure.PetalRadius then
        local reach = structure.PetalRadius + structure.PetalHeight * math.sin(math.rad(structure.PetalTilt)) + structure.PetalThickness
        assert(reach <= maxRadius, string.format("HearthVisualConfig level %d petals exceed footprint", level))
    end
    if structure.CrystalRadius then
        assert(structure.CrystalRadius + structure.CrystalWidth <= maxRadius, string.format("HearthVisualConfig level %d crystals exceed footprint", level))
    end
    for _, fragment in presentation.Fragments or {} do
        assert(fragment.Radius + fragment.Size <= maxRadius, string.format("HearthVisualConfig level %d fragment exceeds footprint", level))
    end
    for _, ribbon in presentation.Ribbons or {} do
        for _, point in ribbon.Points do
            assert(point.Radius + ribbon.Width0 * 0.5 <= maxRadius, string.format("HearthVisualConfig level %d ribbon exceeds footprint", level))
        end
    end
    if presentation.Orbit then
        assert(presentation.Orbit.Radius <= maxRadius, string.format("HearthVisualConfig level %d orbit exceeds footprint", level))
    end
end

HearthVisualConfig.Levels = Levels

return HearthVisualConfig
