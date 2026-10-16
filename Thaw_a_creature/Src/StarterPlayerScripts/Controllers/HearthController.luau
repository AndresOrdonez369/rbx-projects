-- HearthController (F-D15-T06B / T06C). Client-local Hearth PRESENTATION only. Families A-E (Lv1-10).
-- Gameplay (level, costs, training, upgrade validation) is server-owned. This controller reads the owner's level
-- from HearthUpdated and is structured per Hearth model + level so visitor Hearths can be rendered later from a
-- replicated read-only level attribute (HearthVisualConfig.VisitorRendering, disabled until the server exposes it).
-- World instances are never moved or replaced: HearthBase / FireCore / FireOuter are hidden locally only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WarmthConfig = require(shared:WaitForChild("WarmthConfig"))
local HearthVisualConfig = require(shared:WaitForChild("HearthVisualConfig"))

local OwnBaseController = require(script.Parent.OwnBaseController)

local HearthController = {}

local PRESENTATION_NAME = "HearthPresentation"
local STRUCTURE_NAME = "Structure"
local WARM_ZONE_PRESENTATION_NAME = "WarmZonePresentation"
local EMBER_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SOFT_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local LEGACY_PART_NAMES = { "HearthBase", "FireCore", "FireOuter" }
local LEGACY_EFFECT_NAMES = { "Flame", "Smoke", "Embers", "HomeSparks", "WarmLight" }

local BILLBOARD_WIDTH = 250
local BILLBOARD_HEIGHT = 82
local ACCENT_COLOR = Color3.fromRGB(255, 150, 60)
local RATE_COLOR = Color3.fromRGB(255, 176, 78)
local LEVEL_COLOR = Color3.fromRGB(255, 236, 190)
local QUIET_COLOR = Color3.fromRGB(190, 174, 152)
local NEED_CASH_COLOR = Color3.fromRGB(255, 96, 80)
local NEED_CASH_FLASH_SECONDS = 1.4
local NEED_CASH_PUNCH_SCALE = 1.12
local NEED_CASH_PUNCH_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local COMPACT_SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

-- "There's home": local-only boost while the player is Low/Critical. Safe stays at the normal stage look.
-- HomeSparks are a warmth navigation cue only, never a Hearth-level effect.
local PRESSURE_LIGHT_BRIGHTNESS = { Safe = 1, Low = 1.9, Critical = 2.8 }
local PRESSURE_LIGHT_RANGE = { Safe = 1, Low = 1.7, Critical = 2.3 }
local PRESSURE_EMBER_RATE = { Safe = 1, Low = 2, Critical = 3 }
local PRESSURE_SPARK_RATE = { Safe = 0, Low = 9, Critical = 15 }
local PRESSURE_TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Palette = HearthVisualConfig.Palette
local Colors = HearthVisualConfig.StructureColors
local Transition = HearthVisualConfig.Transition
local Lod = HearthVisualConfig.Lod
local MAX_GROUND_RADIUS = HearthVisualConfig.Footprint.MaxGroundRadius
local MOTION_INTERVAL = 1 / HearthVisualConfig.Motion.UpdateHz
local UPRIGHT = CFrame.Angles(0, 0, math.pi * 0.5) -- Roblox cylinders run along X; stand them on Y.
local TAU = math.pi * 2

type RuneEntry = { Part: BasePart, Ring: any, Index: number }
type FragmentEntry = { Part: BasePart, Fragment: any }
type SpinnerEntry = { Part: BasePart, Height: number, Tilt: CFrame, SpinDegPerSec: number }
type BeamEntry = { Beam: Beam, Config: any, Index: number }

type Renderer = {
    Hearth: Model,
    HearthBase: BasePart,
    IsOwn: boolean,
    Origin: CFrame,
    Folder: Folder,
    Structure: Folder?,
    Level: number?, -- level currently built
    TargetLevel: number?, -- latest level received (may still be transitioning)
    Def: any?,
    GroundTop: number,
    Core: BasePart?,
    Shell: BasePart?,
    AuraShell: BasePart?,
    Named: { [string]: Instance },
    Lights: { Light }, -- LOD category
    Particles: { Instance }, -- LOD category (ParticleEmitter / Fire / Smoke; never HomeSparks)
    Runes: { RuneEntry },
    Fragments: { FragmentEntry },
    Spinners: { SpinnerEntry },
    PulseParts: { BasePart },
    ArcTips: { Attachment },
    Arcs: { BeamEntry },
    RibbonBeams: { BeamEntry },
    MoveParts: { BasePart },
    MoveCFrames: { CFrame },
    FlashEndsAt: number,
    TransitionToken: number,
    LodLightsOn: boolean,
    LodParticlesOn: boolean,
    Billboard: any?,
}

local started = false
local renderers: { [Model]: Renderer } = {}
local ownRenderer: Renderer? = nil
local warmthPressure = "Safe"
local lastHearthData: any = nil
local lastCash: number? = nil
local needCashRevision = 0
local motionAccumulator = 0

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")
assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

-- ===================================== formatting =====================================
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

local function trimZeros(text: string): string
    if text:find(".", 1, true) then
        text = text:gsub("0+$", ""):gsub("%.$", "")
    end
    return text
end

local function formatScientific(abs: number): string
    local mantissa, exponent = string.format("%.2e", abs):match("^(.-)e([%+%-]?%d+)$")
    if not mantissa then
        return tostring(abs)
    end
    return string.format("%se%d", trimZeros(mantissa), tonumber(exponent) :: number)
end

-- Display only: 950, 1.25K, 60K, 3.4M, 8.2B, 1.1T ... falling back to scientific notation.
local function formatCompact(value: number): string
    local abs = math.abs(value)
    local rounded = math.round(abs)
    if rounded < 1000 then
        return tostring(rounded)
    end

    local index = math.max(math.floor(math.log10(abs) / 3), 1)
    for _ = 1, 2 do
        if index > #COMPACT_SUFFIXES then
            return formatScientific(abs)
        end

        local scaled = abs / (1000 ^ index)
        local decimals = if scaled < 100 then 2 elseif scaled < 1000 then 1 else 0
        local text = trimZeros(string.format("%." .. decimals .. "f", scaled))
        if (tonumber(text) :: number) < 1000 then
            return text .. COMPACT_SUFFIXES[index]
        end
        index += 1
    end

    return formatScientific(abs)
end

-- ===================================== part / effect helpers =====================================
local function newPart(
    parent: Instance,
    name: string,
    material: Enum.Material,
    color: Color3,
    size: Vector3,
    cframe: CFrame,
    shape: Enum.PartType?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    if shape then
        part.Shape = shape
    end
    part.Material = material
    part.Color = color
    part.Size = size
    part.CFrame = cframe
    part.Parent = parent
    return part
end

-- Upright cylinder resting at `bottom` (studs above the Hearth ground).
local function disc(
    parent: Instance,
    name: string,
    origin: CFrame,
    radius: number,
    bottom: number,
    height: number,
    material: Enum.Material,
    color: Color3
): Part
    return newPart(
        parent,
        name,
        material,
        color,
        Vector3.new(height, radius * 2, radius * 2),
        origin * CFrame.new(0, bottom + height * 0.5, 0) * UPRIGHT,
        Enum.PartType.Cylinder
    )
end

-- Square bar between two world points.
local function strut(parent: Instance, name: string, from: Vector3, to: Vector3, width: number, material: Enum.Material, color: Color3): Part
    local cframe = CFrame.lookAt((from + to) * 0.5, to, Vector3.xAxis)
    return newPart(parent, name, material, color, Vector3.new(width, width, (to - from).Magnitude), cframe)
end

local function sizeSequence(size: number, endSize: number?): NumberSequence
    if endSize then
        return NumberSequence.new({
            NumberSequenceKeypoint.new(0, size),
            NumberSequenceKeypoint.new(1, endSize),
        })
    end
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, size),
        NumberSequenceKeypoint.new(0.7, size * 0.6),
        NumberSequenceKeypoint.new(1, 0),
    })
end

local function fadeSequence(start: number): NumberSequence
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, start),
        NumberSequenceKeypoint.new(0.75, math.min(start + 0.2, 0.95)),
        NumberSequenceKeypoint.new(1, 1),
    })
end

-- Fades in and out (stars / orbit motes).
local TWINKLE_SEQUENCE = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.2, 0.1),
    NumberSequenceKeypoint.new(0.75, 0.3),
    NumberSequenceKeypoint.new(1, 1),
})

local function newEmitter(renderer: Renderer, host: BasePart, name: string, params: any): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = name
    emitter.Texture = params.Texture or EMBER_TEXTURE
    emitter.Rate = params.Rate
    emitter.Speed = params.Speed or NumberRange.new(0.4, 1)
    emitter.Lifetime = params.Lifetime
    emitter.Color = ColorSequence.new(params.Color0, params.Color1)
    emitter.Size = sizeSequence(params.Size, params.EndSize)
    emitter.Transparency = if params.Twinkle then TWINKLE_SEQUENCE else fadeSequence(params.Transparency or 0.1)
    emitter.LightEmission = params.LightEmission or 0.85
    emitter.LightInfluence = 0
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-90, 90)
    emitter.Parent = host
    renderer.Named[name] = emitter
    table.insert(renderer.Particles, emitter)
    return emitter
end

local function newLight(renderer: Renderer, host: BasePart, name: string, params: any): PointLight
    local light = Instance.new("PointLight")
    light.Name = name
    light.Shadows = false
    light.Color = params.Color
    light.Brightness = params.Brightness
    light.Range = params.Range
    light.Parent = host
    renderer.Named[name] = light
    table.insert(renderer.Lights, light)
    return light
end

-- Invisible helper part (emitter volumes, rotating attachment hosts). Never collides or queries.
local function newHelper(parent: Instance, name: string, size: Vector3, cframe: CFrame, shape: Enum.PartType?): Part
    local part = newPart(parent, name, Enum.Material.SmoothPlastic, Color3.new(), size, cframe, shape)
    part.Transparency = 1
    return part
end

-- Attachment whose X axis (the Beam curve axis) points along `axis` in world space.
local function newAxisAttachment(parent: BasePart, name: string, worldPosition: Vector3, axis: Vector3): Attachment
    local unitAxis = axis.Unit
    local reference = if math.abs(unitAxis.Y) > 0.95 then Vector3.xAxis else Vector3.yAxis
    local secondary = (reference - unitAxis * unitAxis:Dot(reference)).Unit
    local attachment = Instance.new("Attachment")
    attachment.Name = name
    attachment.Parent = parent
    attachment.WorldCFrame = CFrame.fromMatrix(worldPosition, unitAxis, secondary)
    return attachment
end

-- Soft ends so beams never read as hard rods or a light column.
local function beamTransparency(value: number): NumberSequence
    local edge = math.min(1, value + 0.4)
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, edge),
        NumberSequenceKeypoint.new(0.15, value),
        NumberSequenceKeypoint.new(0.85, value),
        NumberSequenceKeypoint.new(1, edge),
    })
end

local function newBeam(parent: Instance, name: string, a0: Attachment, a1: Attachment, config: any, color: ColorSequence, width0: number, width1: number): Beam
    local beam = Instance.new("Beam")
    beam.Name = name
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Color = color
    beam.Width0 = width0
    beam.Width1 = width1
    beam.FaceCamera = true
    beam.LightEmission = config.LightEmission or 1 -- low emission keeps beam colour readable against bright sky
    beam.LightInfluence = 0
    beam.Brightness = config.Brightness or 1
    beam.Segments = 16
    beam.Transparency = beamTransparency(config.Transparency)
    if config.Texture then
        beam.Texture = config.Texture
        beam.TextureMode = Enum.TextureMode.Wrap
        beam.TextureLength = config.TextureLength or 4
        beam.TextureSpeed = config.TextureSpeed or 0.4
    end
    beam.Parent = parent
    return beam
end

-- ===================================== family builders =====================================
-- Each builder creates its family's structure and returns the world-relative height of the core centre.
-- All presentation geometry is CanCollide / CanTouch / CanQuery = false (newPart); HearthBase stays the anchor.

-- A: compact stone hearth on a low dais (covers the hidden HearthBase visually).
local function buildFamilyA(renderer: Renderer, def: any, folder: Folder): number
    local structure = def.Structure
    local origin = renderer.Origin
    disc(folder, "Dais", origin, structure.DaisRadius, 0, structure.DaisHeight, Enum.Material.Cobblestone, Colors.Stone)
    disc(folder, "Coals", origin, structure.BedRadius, structure.DaisHeight, structure.BedHeight, Enum.Material.CrackedLava, Colors.Coals)

    for index = 1, structure.StoneCount do
        local angle = (index - 1) / structure.StoneCount * TAU + 0.35
        local jitter = ((index * 37) % 11) / 11 - 0.5 -- deterministic variation, same on every client
        local size = structure.StoneSize * (1 + jitter * 0.18)
        local cframe = origin
            * CFrame.Angles(0, angle, 0)
            * CFrame.new(structure.StoneRingRadius, structure.DaisHeight + size.Y * 0.42, 0)
            * CFrame.Angles(jitter * 0.3, jitter * 0.8, -0.12)
        newPart(folder, string.format("Stone%02d", index), Enum.Material.Slate, Colors.StoneDark, size, cframe)
    end

    local bedTop = structure.DaisHeight + structure.BedHeight
    return bedTop + def.Core.Size.Y * def.Core.Lift
end

local function addPosts(renderer: Renderer, structure: any, folder: Folder, baseHeight: number, color: Color3): ()
    local origin = renderer.Origin
    for index = 1, 4 do
        local angle = math.pi * 0.25 + (index - 1) * math.pi * 0.5 -- diagonal: the front stays open
        local cosA, sinA = math.cos(angle), math.sin(angle)
        local from = origin:PointToWorldSpace(Vector3.new(cosA * structure.PostBaseRadius, baseHeight, sinA * structure.PostBaseRadius))
        local to = origin:PointToWorldSpace(Vector3.new(cosA * structure.PostTopRadius, structure.PostTop, sinA * structure.PostTopRadius))
        strut(folder, string.format("Post%02d", index), from, to, structure.PostWidth, Enum.Material.Metal, color)
    end
end

-- B: forged iron brazier (column + bowl) with four leaning posts.
local function buildFamilyB(renderer: Renderer, def: any, folder: Folder): number
    local structure = def.Structure
    local origin = renderer.Origin
    disc(folder, "Dais", origin, structure.DaisRadius, 0, structure.DaisHeight, Enum.Material.Cobblestone, Colors.StoneDark)
    disc(folder, "Column", origin, structure.ColumnRadius, structure.DaisHeight, structure.ColumnHeight, Enum.Material.Metal, Colors.Iron)
    local bowlBottom = structure.DaisHeight + structure.ColumnHeight
    disc(folder, "Bowl", origin, structure.BowlRadius, bowlBottom, structure.BowlHeight, Enum.Material.Metal, Colors.IronDark)
    local bowlTop = bowlBottom + structure.BowlHeight
    disc(folder, "Coals", origin, structure.BedRadius, bowlTop - 0.05, 0.15, Enum.Material.CrackedLava, Colors.Coals)
    addPosts(renderer, structure, folder, structure.DaisHeight, Colors.IronDark)
    return bowlTop + 0.1 + def.Core.Size.Y * def.Core.Lift
end

-- C: stepped forge (dais + cool stone tier), heavier bowl, taller posts.
local function buildFamilyC(renderer: Renderer, def: any, folder: Folder): number
    local structure = def.Structure
    local origin = renderer.Origin
    disc(folder, "Dais", origin, structure.DaisRadius, 0, structure.DaisHeight, Enum.Material.Cobblestone, Colors.StoneDark)
    disc(folder, "Tier", origin, structure.TierRadius, structure.DaisHeight, structure.TierHeight, Enum.Material.Slate, Colors.StoneCool)
    local tierTop = structure.DaisHeight + structure.TierHeight
    disc(folder, "Column", origin, structure.ColumnRadius, tierTop, structure.ColumnHeight, Enum.Material.Metal, Colors.Iron)
    local bowlBottom = tierTop + structure.ColumnHeight
    disc(folder, "Bowl", origin, structure.BowlRadius, bowlBottom, structure.BowlHeight, Enum.Material.Metal, Colors.ForgeIron)
    local bowlTop = bowlBottom + structure.BowlHeight
    disc(folder, "Coals", origin, structure.BedRadius, bowlTop - 0.05, 0.15, Enum.Material.CrackedLava, Colors.Coals)
    addPosts(renderer, structure, folder, tierTop, Colors.IronDark)
    return bowlTop + 0.1 + def.Core.Size.Y * def.Core.Lift
end

-- Crystal: an elongated Neon diamond standing on a ring position, tilted outward. Returns the part + tip position.
local function addCrystal(
    renderer: Renderer,
    folder: Folder,
    name: string,
    angle: number,
    radius: number,
    bottom: number,
    length: number,
    width: number,
    tiltDegrees: number,
    color: Color3
): (BasePart, Vector3)
    local cframe = renderer.Origin
        * CFrame.Angles(0, -angle, 0)
        * CFrame.new(radius, bottom, 0)
        * CFrame.Angles(0, 0, -math.rad(tiltDegrees)) -- positive tilt leans the tip outward
        * CFrame.new(0, length * 0.5, 0)
        * CFrame.Angles(0, math.pi * 0.25, 0)
    local crystal = newPart(folder, name, Enum.Material.Neon, color, Vector3.new(width, length, width), cframe)
    return crystal, cframe:PointToWorldSpace(Vector3.new(0, length * 0.5, 0))
end

-- D: arc furnace. Stepped forge base with a cyan channel band and four crystal / rune nodes (replacing the posts).
local function buildFamilyD(renderer: Renderer, def: any, folder: Folder): number
    local structure = def.Structure
    local origin = renderer.Origin
    disc(folder, "Dais", origin, structure.DaisRadius, 0, structure.DaisHeight, Enum.Material.Cobblestone, Colors.StoneDark)
    disc(folder, "Tier", origin, structure.TierRadius, structure.DaisHeight, structure.TierHeight, Enum.Material.Slate, Colors.StoneCool)
    local tierTop = structure.DaisHeight + structure.TierHeight
    disc(folder, "Column", origin, structure.ColumnRadius, tierTop, structure.ColumnHeight, Enum.Material.Metal, Colors.Iron)
    local bowlBottom = tierTop + structure.ColumnHeight
    local bowlMaterial = if structure.BowlMaterial == "Slate" then Enum.Material.Slate else Enum.Material.Metal
    disc(folder, "Bowl", origin, structure.BowlRadius, bowlBottom, structure.BowlHeight, bowlMaterial, Colors[structure.BowlColor])
    disc(folder, "Channel", origin, structure.BowlRadius + 0.06, bowlBottom + structure.BowlHeight * 0.4, 0.14, Enum.Material.Neon, structure.BandColor)
    local bowlTop = bowlBottom + structure.BowlHeight
    disc(folder, "Coals", origin, structure.BedRadius, bowlTop - 0.05, 0.15, Enum.Material.CrackedLava, Colors.Coals)

    for index = 1, structure.NodeCount do
        local angle = math.pi * 0.25 + (index - 1) * (TAU / structure.NodeCount) -- front stays open
        local plinthCFrame = origin
            * CFrame.Angles(0, -angle, 0)
            * CFrame.new(structure.NodeRadius, tierTop + structure.NodeHeight * 0.5, 0)
            * CFrame.Angles(0, math.pi * 0.25, 0)
        newPart(folder, string.format("Node%02d", index), Enum.Material.Basalt, Colors.MeteorStone,
            Vector3.new(structure.NodeWidth, structure.NodeHeight, structure.NodeWidth), plinthCFrame)
        local crystal, tip = addCrystal(renderer, folder, string.format("Crystal%02d", index), angle, structure.NodeRadius,
            tierTop + structure.NodeHeight - 0.15, structure.CrystalLength, structure.CrystalWidth, structure.CrystalTilt,
            structure.CrystalColor)
        table.insert(renderer.ArcTips, newAxisAttachment(crystal, "ArcTip", tip, Vector3.yAxis))
    end

    return bowlTop + 0.1 + def.Core.Size.Y * def.Core.Lift
end

-- E: meteor reactor. Dark meteor housing (three cracked petals with bright inner fissures) cradling a floating core,
-- refined violet crystal supports behind each petal.
local function buildFamilyE(renderer: Renderer, def: any, folder: Folder): number
    local structure = def.Structure
    local origin = renderer.Origin
    disc(folder, "Dais", origin, structure.DaisRadius, 0, structure.DaisHeight, Enum.Material.Basalt, Colors.MeteorStone)
    disc(folder, "Tier", origin, structure.TierRadius, structure.DaisHeight, structure.TierHeight, Enum.Material.Basalt, Palette.MeteorDark)
    local tierTop = structure.DaisHeight + structure.TierHeight
    disc(folder, "Pedestal", origin, structure.PedestalRadius, tierTop, structure.PedestalHeight, Enum.Material.Basalt, Palette.MeteorDark)

    for index = 1, structure.PetalCount do
        local angle = math.pi * 0.5 + (index - 1) * (TAU / structure.PetalCount) -- back, back-left, back-right: front open
        local petalCFrame = origin
            * CFrame.Angles(0, -angle, 0)
            * CFrame.new(structure.PetalRadius, structure.PetalBase, 0)
            * CFrame.Angles(0, 0, -math.rad(structure.PetalTilt))
            * CFrame.new(0, structure.PetalHeight * 0.5, 0)
        newPart(folder, string.format("Petal%02d", index), Enum.Material.Basalt, Palette.MeteorDark,
            Vector3.new(structure.PetalThickness, structure.PetalHeight, structure.PetalWidth), petalCFrame)
        local fissure = newPart(folder, string.format("Fissure%02d", index), Enum.Material.Neon,
            structure.FissureColors[(index - 1) % #structure.FissureColors + 1],
            Vector3.new(0.05, structure.PetalHeight * 0.8, structure.FissureWidth),
            -- Inner face: glows toward the core and reads through the open front.
            petalCFrame * CFrame.new(-(structure.PetalThickness * 0.5 + 0.03), 0, 0) * CFrame.Angles(math.rad(8 * (index - 2)), 0, 0))
        if structure.FissurePulse then
            table.insert(renderer.PulseParts, fissure)
        end

        local crystalBottom = structure.CrystalBottom
        if structure.CrystalBase then
            local base = structure.CrystalBase
            newPart(folder, string.format("CrystalBase%02d", index), Enum.Material.Basalt, Palette.MeteorDark,
                Vector3.new(base.Width, base.Height, base.Width),
                origin * CFrame.Angles(0, -angle, 0) * CFrame.new(structure.CrystalRadius, tierTop + base.Height * 0.5, 0)
                    * CFrame.Angles(0, math.pi * 0.25, 0))
        end
        local crystal, tip = addCrystal(renderer, folder, string.format("Crystal%02d", index), angle, structure.CrystalRadius,
            crystalBottom, structure.CrystalTop - crystalBottom, structure.CrystalWidth, structure.CrystalTilt,
            structure.CrystalColor)
        table.insert(renderer.ArcTips, newAxisAttachment(crystal, "ArcTip", tip, Vector3.yAxis))
    end

    return structure.CoreHeight
end

local FAMILY_BUILDERS = {
    A = buildFamilyA,
    B = buildFamilyB,
    C = buildFamilyC,
    D = buildFamilyD,
    E = buildFamilyE,
}

-- ===================================== shared motion =====================================
local function wrapAngle(degreesPerSecond: number, now: number): number
    -- Wrap in double precision first: CFrame math is float32 and server time is ~1.7e9 s.
    return (math.rad(degreesPerSecond) * now) % TAU
end

local function runeCFrame(renderer: Renderer, entry: RuneEntry, now: number): CFrame
    local ring = entry.Ring
    local angle = ((entry.Index - 1) / ring.Count * TAU + wrapAngle(ring.SpinDegPerSec, now)) % TAU
    local bob = ring.Bob * math.sin(now * 1.7 + entry.Index * 0.9)
    local stagger = if ring.Stagger and entry.Index % 2 == 0 then ring.Stagger else 0
    return renderer.Origin
        * CFrame.Angles(0, -angle, 0)
        * CFrame.new(ring.Radius, ring.Height + bob + stagger, 0)
        * CFrame.Angles(0, math.pi * 0.5, 0) -- plate faces outward
        * CFrame.Angles(0, 0, math.pi * 0.25) -- diamond glyph
end

local function fragmentCFrame(renderer: Renderer, fragment: any, now: number): CFrame
    local angle = (math.rad(fragment.Phase) + wrapAngle(fragment.Speed, now)) % TAU
    local bob = fragment.Bob * math.sin(now * 1.3 + math.rad(fragment.Phase))
    return renderer.Origin
        * CFrame.Angles(0, -angle, 0)
        * CFrame.new(fragment.Radius, fragment.Height + bob, 0)
        * CFrame.Angles(0, math.pi * 0.5 + wrapAngle(fragment.Spin, now), 0) -- slow self-rotation
        * CFrame.Angles(0, 0, math.pi * 0.25)
end

local function spinnerCFrame(renderer: Renderer, spinner: SpinnerEntry, now: number): CFrame
    return renderer.Origin * CFrame.new(0, spinner.Height, 0) * spinner.Tilt * CFrame.Angles(0, wrapAngle(spinner.SpinDegPerSec, now), 0)
end

local function pulseValue(pulse: any, now: number, phase: number): number
    return 0.5 + 0.5 * math.sin(TAU * now / pulse.PulsePeriod - phase)
end

local function updateRenderer(renderer: Renderer, now: number, clock: number): ()
    local def = renderer.Def
    if not def then
        return
    end

    local flash = math.clamp((renderer.FlashEndsAt - clock) / Transition.RuneFlashTime, 0, 1)
    local pulse = def.Runes
    local cframes = renderer.MoveCFrames
    local count = 0

    for _, entry in renderer.Runes do
        count += 1
        cframes[count] = runeCFrame(renderer, entry, now)
        local value = pulseValue(pulse, now, (entry.Index / entry.Ring.Count) * math.pi * 0.5)
        entry.Part.Transparency = (pulse.TransparencyMax + (pulse.TransparencyMin - pulse.TransparencyMax) * value) * (1 - flash)
    end
    for index, entry in renderer.Fragments do
        count += 1
        cframes[count] = fragmentCFrame(renderer, entry.Fragment, now)
        local value = pulseValue(pulse, now, index * 0.7)
        entry.Part.Transparency = (pulse.TransparencyMax + (pulse.TransparencyMin - pulse.TransparencyMax) * value) * (1 - flash)
    end
    for _, spinner in renderer.Spinners do
        count += 1
        cframes[count] = spinnerCFrame(renderer, spinner, now)
    end
    if count > 0 then
        Workspace:BulkMoveTo(renderer.MoveParts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
    end

    if pulse then
        for index, part in renderer.PulseParts do
            local value = pulseValue(pulse, now, index * 0.5)
            part.Transparency = (pulse.TransparencyMax + (pulse.TransparencyMin - pulse.TransparencyMax) * value) * (1 - flash)
        end
    end

    -- Arcs: each fades in, holds, fades out on a node, then moves to the next node (offset half a period).
    local tips = renderer.ArcTips
    for _, entry in renderer.Arcs do
        local config = entry.Config
        local phase = now / config.Period + (entry.Index - 1) * 0.5
        local cycle = math.floor(phase)
        local fraction = phase - cycle
        local tip = tips[((cycle + (entry.Index - 1) * 2) % #tips) + 1]
        if entry.Beam.Attachment0 ~= tip then
            entry.Beam.Attachment0 = tip
        end
        local envelope = math.clamp(math.sin(fraction * math.pi) * 1.6, 0, 1)
        local transparency = 1 - math.max(envelope, flash) * (1 - config.Transparency)
        entry.Beam.Transparency = beamTransparency(transparency)
        entry.Beam.Width0 = config.Width0 * (1 + flash)
    end

    for _, entry in renderer.RibbonBeams do
        local base = entry.Config.Transparency
        entry.Beam.Transparency = beamTransparency(base * (1 - flash))
    end

    local auraShell = renderer.AuraShell
    local breath = def.AuraShell and def.AuraShell.Breath
    if auraShell and breath then
        local value = 0.5 + 0.5 * math.sin(TAU * now / breath.Period)
        auraShell.Transparency = breath.TransparencyMax + (breath.TransparencyMin - breath.TransparencyMax) * value
    end

    local magicLight = renderer.Named.MagicLight :: PointLight?
    if magicLight and def.MagicLight and pulse then
        magicLight.Brightness = def.MagicLight.Brightness * (0.75 + 0.35 * pulseValue(pulse, now, 0)) * (1 + flash * 1.5)
    end
end

-- LOD categories: lights / particles can be switched without touching geometry, Neon or beams.
local function setLightsEnabled(renderer: Renderer, enabled: boolean): ()
    renderer.LodLightsOn = enabled
    for _, light in renderer.Lights do
        light.Enabled = enabled
    end
end

local function setParticlesEnabled(renderer: Renderer, enabled: boolean): ()
    renderer.LodParticlesOn = enabled
    for _, effect in renderer.Particles do
        (effect :: any).Enabled = enabled
    end
end

local function updateVisitorLod(renderer: Renderer, cameraPosition: Vector3): ()
    local distance = (renderer.Origin.Position - cameraPosition).Magnitude
    local lightsOn = distance <= Lod.LightsOffBeyond
    local particlesOn = distance <= Lod.ParticlesOffBeyond
    if lightsOn ~= renderer.LodLightsOn then
        setLightsEnabled(renderer, lightsOn)
    end
    if particlesOn ~= renderer.LodParticlesOn then
        setParticlesEnabled(renderer, particlesOn)
    end
end

-- One shared loop for every Hearth (slow motion only; particles are never animated manually).
local function onHeartbeat(deltaTime: number): ()
    motionAccumulator += deltaTime
    if motionAccumulator < MOTION_INTERVAL then
        return
    end
    motionAccumulator %= MOTION_INTERVAL

    local now = Workspace:GetServerTimeNow()
    local clock = os.clock()
    local camera = Workspace.CurrentCamera
    for _, renderer in renderers do
        if renderer.Folder.Parent then
            updateRenderer(renderer, now, clock)
            if not renderer.IsOwn and camera then
                updateVisitorLod(renderer, camera.CFrame.Position)
            end
        end
    end
end

-- ===================================== pressure (owner only) =====================================
local function applyPressure(renderer: Renderer, instant: boolean): ()
    local def = renderer.Def
    if not def or not renderer.IsOwn then
        return
    end

    local light = renderer.Named.WarmLight :: PointLight?
    if light then
        local goal = {
            Brightness = def.WarmLight.Brightness * PRESSURE_LIGHT_BRIGHTNESS[warmthPressure],
            Range = def.WarmLight.Range * PRESSURE_LIGHT_RANGE[warmthPressure],
        }
        if instant then
            light.Brightness = goal.Brightness
            light.Range = goal.Range
        else
            TweenService:Create(light, PRESSURE_TWEEN_INFO, goal):Play()
        end
    end

    local embers = renderer.Named.Embers :: ParticleEmitter?
    if embers then
        embers.Rate = def.Embers.Rate * PRESSURE_EMBER_RATE[warmthPressure]
    end

    local homeSparks = renderer.Named.HomeSparks :: ParticleEmitter?
    if homeSparks then
        local sparkRate = PRESSURE_SPARK_RATE[warmthPressure]
        homeSparks.Rate = sparkRate
        homeSparks.Enabled = sparkRate > 0
    end
end

-- Tall, slow spark column visible only while the player is Low/Critical (owner Hearth only).
local function createHomeSparks(renderer: Renderer, host: BasePart): ()
    local homeSparks = Instance.new("ParticleEmitter")
    homeSparks.Name = "HomeSparks"
    homeSparks.Enabled = false
    homeSparks.Rate = 0
    homeSparks.Texture = EMBER_TEXTURE
    homeSparks.Lifetime = NumberRange.new(2.2, 3)
    homeSparks.Speed = NumberRange.new(14, 20)
    homeSparks.Acceleration = Vector3.new(0, 2, 0)
    homeSparks.Drag = 0.4
    homeSparks.LightEmission = 1
    homeSparks.LightInfluence = 0
    homeSparks.SpreadAngle = Vector2.new(10, 10)
    homeSparks.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 120, 40))
    homeSparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.3),
        NumberSequenceKeypoint.new(0.6, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    homeSparks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.7, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    homeSparks.Parent = host
    renderer.Named.HomeSparks = homeSparks -- deliberately NOT in the LOD particle category
end

-- ===================================== level build =====================================
local function resetRendererLists(renderer: Renderer): ()
    renderer.Named = {}
    renderer.Lights = {}
    renderer.Particles = {}
    renderer.Runes = {}
    renderer.Fragments = {}
    renderer.Spinners = {}
    renderer.PulseParts = {}
    renderer.ArcTips = {}
    renderer.Arcs = {}
    renderer.RibbonBeams = {}
    renderer.MoveParts = {}
    renderer.MoveCFrames = {}
    renderer.Core = nil
    renderer.Shell = nil
    renderer.AuraShell = nil
end

local function shellMaterial(name: string?): Enum.Material
    return if name == "ForceField" then Enum.Material.ForceField else Enum.Material.Neon
end

-- Ribbon / spiral: helix points on a rotating host; each consecutive pair is one curved Beam.
local function buildRibbon(renderer: Renderer, folder: Folder, ribbon: any, ribbonIndex: number): ()
    local host = newHelper(folder, string.format("RibbonHost%d", ribbonIndex), Vector3.one * 0.2, renderer.Origin)
    table.insert(renderer.Spinners, { Part = host, Height = 0, Tilt = CFrame.identity, SpinDegPerSec = ribbon.SpinDegPerSec })

    local points = ribbon.Points
    local attachments = {}
    local derivatives = {}
    for index, point in points do
        -- Tangent direction from the neighbouring segment (helix derivative d/dtheta).
        local neighbour = points[index + 1] or points[index - 1]
        local deltaAngle = math.rad(math.abs(neighbour.Angle - point.Angle))
        local deltaHeight = if points[index + 1] then neighbour.Height - point.Height else point.Height - neighbour.Height
        local theta = math.rad(point.Angle)
        local localPosition = Vector3.new(point.Radius * math.cos(theta), point.Height, point.Radius * math.sin(theta))
        local derivative = Vector3.new(-point.Radius * math.sin(theta), deltaHeight / deltaAngle, point.Radius * math.cos(theta))
        derivatives[index] = derivative
        attachments[index] = newAxisAttachment(host, string.format("RibbonPoint%d", index),
            renderer.Origin:PointToWorldSpace(localPosition), renderer.Origin:VectorToWorldSpace(derivative))
    end

    for index = 1, #points - 1 do
        local deltaAngle = math.rad(math.abs(points[index + 1].Angle - points[index].Angle))
        local handle = 4 / 3 * math.tan(deltaAngle / 4) -- cubic Bezier approximation of a circular arc
        local width0 = ribbon.Width0 + (ribbon.Width1 - ribbon.Width0) * ((index - 1) / (#points - 1))
        local width1 = ribbon.Width0 + (ribbon.Width1 - ribbon.Width0) * (index / (#points - 1))
        local colors = ribbon.Colors
        local beam = newBeam(host, string.format("Ribbon%d_%d", ribbonIndex, index), attachments[index], attachments[index + 1],
            ribbon, ColorSequence.new(colors[index] or colors[1], colors[index + 1] or colors[#colors]), width0, width1)
        beam.CurveSize0 = derivatives[index].Magnitude * handle
        beam.CurveSize1 = -derivatives[index + 1].Magnitude * handle
        table.insert(renderer.RibbonBeams, { Beam = beam, Config = ribbon, Index = index })
    end
end

local function buildLevel(renderer: Renderer, level: number): ()
    local def = HearthVisualConfig.GetPresentation(level)
    assert(def, string.format("No Hearth presentation for level %s", tostring(level)))

    local oldStructure = renderer.Structure
    if oldStructure then
        oldStructure:Destroy()
    end
    resetRendererLists(renderer)

    local folder = Instance.new("Folder")
    folder.Name = STRUCTURE_NAME

    local builder = FAMILY_BUILDERS[def.Family]
    assert(builder, string.format("Hearth family %s is not implemented", tostring(def.Family)))
    local coreY = builder(renderer, def, folder)
    renderer.GroundTop = def.Structure.DaisHeight

    -- Core (+ optional heat / frost shell, + optional supernatural aura shell) hosts fire, light and particles.
    local origin = renderer.Origin
    local core = newPart(folder, "Core", Enum.Material.Neon, def.Core.Color, def.Core.Size, origin * CFrame.new(0, coreY, 0), Enum.PartType.Ball)
    core.Transparency = def.Core.Transparency
    renderer.Core = core

    local shell: BasePart? = nil
    if def.Shell then
        local shellY = coreY + if def.Core.Lift > 0 then def.Shell.Size.Y * 0.12 else 0
        local shellPart = newPart(folder, "Shell", shellMaterial(def.Shell.Material), def.Shell.Color, def.Shell.Size,
            origin * CFrame.new(0, shellY, 0), Enum.PartType.Ball)
        shellPart.Transparency = def.Shell.Transparency
        shell = shellPart
    end
    renderer.Shell = shell

    local auraShell: BasePart? = nil
    if def.AuraShell then
        local auraPart = newPart(folder, "AuraShell", shellMaterial(def.AuraShell.Material), def.AuraShell.Color,
            def.AuraShell.Size, origin * CFrame.new(0, coreY + 0.3, 0), Enum.PartType.Ball)
        auraPart.Transparency = def.AuraShell.Transparency
        auraShell = auraPart
    end
    renderer.AuraShell = auraShell

    local aura: BasePart? = nil
    if def.Structure.AuraSize then
        aura = newHelper(folder, "Aura", Vector3.one * def.Structure.AuraSize, origin * CFrame.new(0, coreY + 0.6, 0), Enum.PartType.Ball)
    end
    local volumeHost = aura or auraShell

    local flame = Instance.new("Fire")
    flame.Name = "Flame"
    flame.Size = def.Flame.Size
    flame.Heat = def.Flame.Heat
    flame.Color = def.Flame.Color
    flame.SecondaryColor = def.Flame.SecondaryColor
    flame.Parent = core
    renderer.Named.Flame = flame
    table.insert(renderer.Particles, flame)

    if def.FrostFlame then
        -- Frostfire layer: a second, cyan Fire on the shell wrapped around the warm core.
        local frostFlame = Instance.new("Fire")
        frostFlame.Name = "FrostFlame"
        frostFlame.Size = def.FrostFlame.Size
        frostFlame.Heat = def.FrostFlame.Heat
        frostFlame.Color = def.FrostFlame.Color
        frostFlame.SecondaryColor = def.FrostFlame.SecondaryColor
        frostFlame.Parent = shell or core
        renderer.Named.FrostFlame = frostFlame
        table.insert(renderer.Particles, frostFlame)
    end

    if def.Smoke then
        local smoke = Instance.new("Smoke")
        smoke.Name = "Smoke"
        smoke.Color = Colors.Smoke
        smoke.Opacity = def.Smoke.Opacity
        smoke.Size = def.Smoke.Size
        smoke.RiseVelocity = def.Smoke.RiseVelocity
        smoke.Parent = core
        renderer.Named.Smoke = smoke
        table.insert(renderer.Particles, smoke)
    end

    newLight(renderer, core, "WarmLight", def.WarmLight)
    if def.MagicLight then
        newLight(renderer, shell or core, "MagicLight", def.MagicLight)
    end

    local embers = newEmitter(renderer, core, "Embers", def.Embers)
    embers.Acceleration = Vector3.new(0, 3, 0)
    embers.Drag = 1
    embers.SpreadAngle = Vector2.new(28, 28)

    if def.Sparks then
        local sparks = newEmitter(renderer, core, "Sparks", def.Sparks)
        sparks.LightEmission = 1
        sparks.Acceleration = Vector3.new(0, -4, 0)
        sparks.Drag = 0.6
        sparks.SpreadAngle = Vector2.new(35, 35)
    end

    if def.Motes then
        local motes = newEmitter(renderer, volumeHost or shell or core, "Motes", def.Motes)
        motes.LightEmission = 1
        motes.Shape = Enum.ParticleEmitterShape.Sphere
        motes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
        motes.Acceleration = Vector3.new(0, 1.2, 0)
        motes.Drag = 0.8
        motes.SpreadAngle = Vector2.new(180, 180)
    end

    if def.Stars then
        -- Sparse, twinkling star motes around the core.
        local starParams = table.clone(def.Stars)
        starParams.Twinkle = true
        starParams.Speed = NumberRange.new(0, 0.3)
        local stars = newEmitter(renderer, volumeHost or shell or core, "Stars", starParams)
        stars.LightEmission = 1
        stars.Shape = Enum.ParticleEmitterShape.Sphere
        stars.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
        stars.RotSpeed = NumberRange.new(-30, 30)
    end

    if def.Inflow and volumeHost then
        -- Magical energy drawn from the aura surface into the core.
        local inflow = newEmitter(renderer, volumeHost, "Inflow", def.Inflow)
        inflow.LightEmission = 1
        inflow.Shape = Enum.ParticleEmitterShape.Sphere
        inflow.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
        inflow.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
        inflow.RotSpeed = NumberRange.new(0, 0)
    end

    if def.Arcane then
        local arcane = newEmitter(renderer, shell or core, "Arcane", def.Arcane)
        arcane.LightEmission = 1
        arcane.Acceleration = Vector3.new(0, 2, 0)
        arcane.Drag = 1
        arcane.SpreadAngle = Vector2.new(60, 60)
    end

    if def.Plume then
        -- Short, soft, diffuse violet plume (Hearth-local; never a column).
        local plumeParams = table.clone(def.Plume)
        plumeParams.Texture = SOFT_TEXTURE
        local plume = newEmitter(renderer, core, "Plume", plumeParams)
        plume.LightEmission = 0.8
        plume.Acceleration = Vector3.new(0, 1, 0)
        plume.Drag = 0.5
        plume.SpreadAngle = Vector2.new(12, 12)
        plume.RotSpeed = NumberRange.new(-20, 20)
    end

    if def.Orbit then
        -- Orbiting motes: particles locked to a slowly rotating, tilted ring host.
        local orbit = def.Orbit
        local host = newHelper(folder, "OrbitHost", Vector3.new(orbit.Radius * 2, 0.2, orbit.Radius * 2),
            origin * CFrame.new(0, orbit.Height, 0))
        local orbitParams = table.clone(orbit)
        orbitParams.Twinkle = true
        orbitParams.Speed = NumberRange.new(0, 0)
        local orbitEmitter = newEmitter(renderer, host, "Orbit", orbitParams)
        orbitEmitter.LightEmission = 1
        orbitEmitter.Shape = Enum.ParticleEmitterShape.Cylinder
        orbitEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
        orbitEmitter.LockedToPart = true
        orbitEmitter.RotSpeed = NumberRange.new(0, 0)
        table.insert(renderer.Spinners, {
            Part = host,
            Height = orbit.Height,
            Tilt = CFrame.Angles(math.rad(orbit.Tilt), 0, 0),
            SpinDegPerSec = orbit.SpinDegPerSec,
        })
    end

    local now = Workspace:GetServerTimeNow()
    if def.Runes then
        for ringIndex, ring in def.Runes.Rings do
            for index = 1, ring.Count do
                local entry: RuneEntry = { Part = nil :: any, Ring = ring, Index = index }
                local rune = newPart(folder, string.format("Rune%d_%02d", ringIndex, index), Enum.Material.Neon, ring.Color,
                    Vector3.new(ring.Size, ring.Size, 0.08), runeCFrame(renderer, entry, now))
                rune.Transparency = def.Runes.TransparencyMax
                entry.Part = rune
                table.insert(renderer.Runes, entry)
            end
        end
    end

    for index, fragment in def.Fragments or {} do
        local part = newPart(folder, string.format("Fragment%02d", index), Enum.Material.Neon, fragment.Color,
            Vector3.new(fragment.Size, fragment.Size, 0.14), fragmentCFrame(renderer, fragment, now))
        table.insert(renderer.Fragments, { Part = part, Fragment = fragment })
    end

    if def.Arcs and #renderer.ArcTips > 0 then
        local arcs = def.Arcs
        local targetY = if arcs.Target == "Apex" then arcs.ApexHeight else coreY
        local target = newAxisAttachment(core, "ArcTarget", origin:PointToWorldSpace(Vector3.new(0, targetY, 0)), Vector3.yAxis)
        for index = 1, arcs.Count do
            local beam = newBeam(core, string.format("Arc%d", index), renderer.ArcTips[index], target, arcs,
                ColorSequence.new(arcs.Color0, arcs.Color1), arcs.Width0, arcs.Width1)
            beam.CurveSize0 = arcs.CurveSize0
            beam.CurveSize1 = arcs.CurveSize1
            beam.Transparency = NumberSequence.new(1)
            table.insert(renderer.Arcs, { Beam = beam, Config = arcs, Index = index })
        end
    end

    for ribbonIndex, ribbon in def.Ribbons or {} do
        buildRibbon(renderer, folder, ribbon, ribbonIndex)
    end

    -- Shared-loop move list: runes, then fragments, then spinners (same order as updateRenderer).
    for _, entry in renderer.Runes do
        table.insert(renderer.MoveParts, entry.Part)
    end
    for _, entry in renderer.Fragments do
        table.insert(renderer.MoveParts, entry.Part)
    end
    for _, spinner in renderer.Spinners do
        table.insert(renderer.MoveParts, spinner.Part)
    end
    for index, part in renderer.MoveParts do
        renderer.MoveCFrames[index] = part.CFrame
    end

    if renderer.IsOwn then
        createHomeSparks(renderer, core)
        local billboard = renderer.Billboard
        if billboard then
            billboard.Gui.StudsOffsetWorldSpace = Vector3.new(0, def.BillboardHeight, 0)
        end
    end

    folder.Parent = renderer.Folder
    renderer.Structure = folder
    renderer.Def = def
    renderer.Level = level

    if not renderer.IsOwn then
        -- Re-apply the current LOD state to the freshly built effects.
        setLightsEnabled(renderer, renderer.LodLightsOn)
        setParticlesEnabled(renderer, renderer.LodParticlesOn)
    end
    applyPressure(renderer, true)
end

-- ===================================== upgrade transition =====================================
local function punchBillboard(renderer: Renderer, accent: Color3): ()
    local billboard = renderer.Billboard
    if not billboard then
        return
    end
    local punchInfo = TweenInfo.new(Transition.BillboardPunchTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    billboard.Punch.Scale = Transition.BillboardPunchScale
    TweenService:Create(billboard.Punch, punchInfo, { Scale = 1 }):Play()

    local fadeInfo = TweenInfo.new(Transition.BillboardPunchTime * 1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    billboard.LevelLabel.TextColor3 = accent
    TweenService:Create(billboard.LevelLabel, fadeInfo, { TextColor3 = LEVEL_COLOR }):Play()
    billboard.Stroke.Color = accent
    billboard.Stroke.Thickness = 4
    TweenService:Create(billboard.Stroke, fadeInfo, { Color = ACCENT_COLOR, Thickness = 2 }):Play()
end

local function playRing(renderer: Renderer, color: Color3, delayTime: number): ()
    task.delay(delayTime, function()
        if not renderer.Folder.Parent then
            return
        end
        local startDiameter = Transition.RingStartRadius * 2
        local endDiameter = MAX_GROUND_RADIUS * 2
        local ring = newPart(
            renderer.Folder,
            "UpgradeRing",
            Enum.Material.Neon,
            color,
            Vector3.new(Transition.RingThickness, startDiameter, startDiameter),
            renderer.Origin * CFrame.new(0, renderer.GroundTop + 0.08 + delayTime * 0.5, 0) * UPRIGHT,
            Enum.PartType.Cylinder
        )
        ring.Transparency = Transition.RingTransparency
        local ringInfo = TweenInfo.new(Transition.RingTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(ring, ringInfo, {
            Size = Vector3.new(Transition.RingThickness, endDiameter, endDiameter),
            Transparency = 1,
        }):Play()
        task.delay(Transition.RingTime + 0.05, function()
            ring:Destroy()
        end)
    end)
end

local function playUpgradeTransition(renderer: Renderer, newLevel: number): ()
    renderer.TransitionToken += 1
    local token = renderer.TransitionToken

    -- 1. Current core compresses / dims.
    local compressInfo = TweenInfo.new(Transition.CompressTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    for _, part in { renderer.Core, renderer.Shell, renderer.AuraShell } do
        if part and part.Parent then
            TweenService:Create(part, compressInfo, { Size = part.Size * Transition.CompressScale }):Play()
        end
    end
    local oldLight = renderer.Named.WarmLight :: PointLight?
    if oldLight then
        TweenService:Create(oldLight, compressInfo, { Brightness = oldLight.Brightness * Transition.CompressLight }):Play()
    end

    task.delay(Transition.SwapDelay, function()
        if token ~= renderer.TransitionToken or not renderer.Folder.Parent then
            return
        end

        -- 5. New stage appears at the peak.
        buildLevel(renderer, newLevel)
        local def = renderer.Def
        local style = def.TransitionStyle or {}
        local intensity = def.Intensity or 0.5

        local settleInfo = TweenInfo.new(Transition.SettleTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        for _, part in { renderer.Core, renderer.Shell, renderer.AuraShell } do
            if part then
                local target = part.Size
                part.Size = target * Transition.PopScale
                TweenService:Create(part, settleInfo, { Size = target }):Play()
            end
        end

        -- Major levels: the new core ignites from a start colour (meteor-dark at Lv9, white flash at Lv10).
        local core = renderer.Core
        if core and style.CoreStart then
            core.Color = style.CoreStart
            TweenService:Create(core, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Color = def.Core.Color }):Play()
        end

        -- 3. Light swell, settling to the (pressure-adjusted) stage value.
        local light = renderer.Named.WarmLight :: PointLight?
        if light then
            local goal = { Brightness = light.Brightness, Range = light.Range }
            light.Brightness = goal.Brightness * (style.LightSwell or Transition.LightSwellBrightness)
            light.Range = goal.Range * Transition.LightSwellRange
            local lightInfo = TweenInfo.new(Transition.LightSettleTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(light, lightInfo, goal):Play()
        end

        -- 2. Ember burst (+ sparks / magic where the stage has them).
        local embers = renderer.Named.Embers :: ParticleEmitter?
        if embers then
            embers:Emit(math.round(Transition.BurstEmbers + Transition.BurstEmbersPerIntensity * intensity))
        end
        for _, name in { "Sparks", "Motes", "Stars", "Orbit" } do
            local emitter = renderer.Named[name] :: ParticleEmitter?
            if emitter then
                emitter:Emit(if name == "Sparks"
                    then math.round(Transition.BurstSparks + Transition.BurstSparksPerIntensity * intensity)
                    else Transition.BurstMagic)
            end
        end

        -- 4. Rune / arc / fragment / ribbon flash (driven by the shared loop).
        renderer.FlashEndsAt = os.clock() + Transition.RuneFlashTime

        -- 6. Outward energy ring(s): one per style colour, staggered.  7. HearthStatus emphasis.
        local ringColors = style.RingColors or { def.Accent }
        for index, color in ringColors do
            playRing(renderer, color, (index - 1) * 0.08)
        end
        punchBillboard(renderer, def.Accent)
    end)
end

-- Presentation-level entry point: owner and (later) visitor Hearths both go through here.
local function setLevel(renderer: Renderer, level: number, animate: boolean): ()
    if renderer.TargetLevel == level then
        return
    end
    renderer.TargetLevel = level
    if animate then
        playUpgradeTransition(renderer, level)
    else
        renderer.TransitionToken += 1
        buildLevel(renderer, level)
    end
end

-- ===================================== renderer lifecycle =====================================
local function hideLegacyGeometry(hearth: Model): ()
    for _, name in LEGACY_PART_NAMES do
        local part = hearth:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            part.LocalTransparencyModifier = 1
            -- Remove effects an older presentation version may have attached locally.
            for _, effectName in LEGACY_EFFECT_NAMES do
                local effect = part:FindFirstChild(effectName)
                if effect and not effect:IsA("ProximityPrompt") then
                    effect:Destroy()
                end
            end
        end
    end
end

-- Prefab: ReplicatedStorage.UITemplates.HearthStatus (authored in Studio).
local function createBillboard(renderer: Renderer): ()
    local billboard = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild("HearthStatus"):Clone() :: BillboardGui
    billboard.Name = "HearthStatus"
    billboard.Enabled = false
    billboard.Adornee = renderer.HearthBase
    billboard.Parent = renderer.Folder

    local background = billboard:WaitForChild("Background")
    renderer.Billboard = {
        Gui = billboard,
        Punch = background:WaitForChild("UpgradePunch") :: UIScale,
        Stroke = background:WaitForChild("Stroke") :: UIStroke,
        LevelLabel = background:WaitForChild("Level") :: TextLabel,
        TrainingLabel = background:WaitForChild("Training") :: TextLabel,
        UpgradeLabel = background:WaitForChild("Upgrade") :: TextLabel,
    }
end

local function updateBillboardScale(renderer: Renderer): ()
    local camera = Workspace.CurrentCamera
    local billboard = renderer.Billboard
    if not camera or not billboard then
        return
    end

    -- Slightly smaller on narrow screens; never below 0.85 so text stays legible.
    local scale = math.clamp(camera.ViewportSize.X / 1000, 0.85, 1)
    billboard.Gui.Size = UDim2.fromOffset(math.round(BILLBOARD_WIDTH * scale), math.round(BILLBOARD_HEIGHT * scale))
end

local function createRenderer(hearth: Model, isOwn: boolean): Renderer
    local hearthBase = hearth:WaitForChild("HearthBase")
    assert(hearthBase:IsA("BasePart"), string.format("%s must be a BasePart", hearthBase:GetFullName()))

    local existing = hearth:FindFirstChild(PRESENTATION_NAME)
    if existing then
        existing:Destroy()
    end
    local folder = Instance.new("Folder")
    folder.Name = PRESENTATION_NAME
    folder.Parent = hearth

    hideLegacyGeometry(hearth)

    -- Ground-level origin under the authoritative HearthBase (never moved), yaw only.
    local _, yaw, _ = hearthBase.CFrame:ToOrientation()
    local groundPosition = hearthBase.Position - Vector3.new(0, hearthBase.Size.Y * 0.5, 0)

    local renderer: Renderer = {
        Hearth = hearth,
        HearthBase = hearthBase,
        IsOwn = isOwn,
        Origin = CFrame.new(groundPosition) * CFrame.fromOrientation(0, yaw, 0),
        Folder = folder,
        Structure = nil,
        Level = nil,
        TargetLevel = nil,
        Def = nil,
        GroundTop = 0,
        Core = nil,
        Shell = nil,
        AuraShell = nil,
        Named = {},
        Lights = {},
        Particles = {},
        Runes = {},
        Fragments = {},
        Spinners = {},
        PulseParts = {},
        ArcTips = {},
        Arcs = {},
        RibbonBeams = {},
        MoveParts = {},
        MoveCFrames = {},
        FlashEndsAt = 0,
        TransitionToken = 0,
        LodLightsOn = true,
        LodParticlesOn = true,
        Billboard = nil,
    }
    if isOwn then
        createBillboard(renderer)
    end

    renderers[hearth] = renderer
    return renderer
end

-- ===================================== owner (HearthUpdated) =====================================
-- Prefab: ReplicatedStorage.UITemplates.WarmZonePresentation (authored in Studio).
local function createWarmZonePresentation(warmZone: BasePart): ()
    local existing = warmZone:FindFirstChild(WARM_ZONE_PRESENTATION_NAME)
    if existing then
        existing:Destroy()
    end

    local surfaceGui = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild(WARM_ZONE_PRESENTATION_NAME):Clone()
    surfaceGui.Name = WARM_ZONE_PRESENTATION_NAME
    surfaceGui.Adornee = warmZone
    surfaceGui.Parent = warmZone
end

local function isValidUpdate(data: any): boolean
    if type(data) ~= "table"
        or type(data.HearthLevel) ~= "number"
        or data.HearthLevel % 1 ~= 0
        or HearthVisualConfig.GetPresentation(data.HearthLevel) == nil
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

local function classifyPressure(data: any): string?
    if type(data) ~= "table" then
        return nil
    end
    local current, max = data.CurrentWarmth, data.MaxWarmth
    if type(current) ~= "number" or type(max) ~= "number" or current ~= current or max ~= max or max <= 0 then
        return nil
    end

    local ratio = math.clamp(current / max, 0, 1)
    if ratio <= WarmthConfig.CriticalThreshold then
        return "Critical"
    elseif ratio <= WarmthConfig.LowThreshold then
        return "Low"
    end
    return "Safe"
end

-- Gameplay text updates immediately; only the visuals transition.
local function setUpgradeLabel(billboard: any, data: any): ()
    billboard.UpgradeLabel.Text = if data.IsMaxLevel
        then "MAX LEVEL"
        else string.format("NEXT LV. %d · $%s", data.HearthLevel + 1, formatCompact(data.NextUpgradeCost))
    billboard.UpgradeLabel.TextColor3 = if data.IsMaxLevel then RATE_COLOR else QUIET_COLOR
end

-- Affordability is known locally (CashUpdated + HearthUpdated), so an unaffordable press explains itself on the
-- Hearth billboard instead of sending a request the server would refuse without feedback.
local function flashNeedCash(renderer: Renderer, missing: number): ()
    local billboard = renderer.Billboard
    if not billboard then
        return
    end

    needCashRevision += 1
    local revision = needCashRevision
    billboard.UpgradeLabel.Text = string.format("NEED $%s MORE", formatCompact(missing))
    billboard.UpgradeLabel.TextColor3 = NEED_CASH_COLOR
    billboard.Punch.Scale = NEED_CASH_PUNCH_SCALE
    TweenService:Create(billboard.Punch, NEED_CASH_PUNCH_INFO, { Scale = 1 }):Play()

    task.delay(NEED_CASH_FLASH_SECONDS, function()
        if revision == needCashRevision and lastHearthData ~= nil then
            setUpgradeLabel(billboard, lastHearthData)
        end
    end)
end

local function applyOwnUpdate(renderer: Renderer, prompt: ProximityPrompt, data: any): ()
    if not isValidUpdate(data) then
        return
    end

    lastHearthData = data
    needCashRevision += 1
    local level = data.HearthLevel
    local billboard = renderer.Billboard
    if billboard then
        billboard.LevelLabel.Text = string.format("HEARTH LV. %d", level)
        billboard.TrainingLabel.Text = string.format("+%s MAX WARMTH/s", formatCompact(data.WarmthTrainingRate))
        setUpgradeLabel(billboard, data)
        billboard.Gui.Enabled = true
    end

    prompt.ObjectText = string.format("HEARTH LV. %d", level)
    prompt.ActionText = if data.IsMaxLevel
        then "MAX"
        else string.format("UPGRADE $%s", formatInteger(data.NextUpgradeCost))

    -- Initial sync / join / rebuild: TargetLevel is nil, so no fake upgrade plays.
    local previous = renderer.TargetLevel
    setLevel(renderer, level, previous ~= nil and level > previous)
end

-- ===================================== visitors (dormant until the level attribute exists) =====================================
local function watchVisitorHearth(hearth: Model): ()
    local attribute = HearthVisualConfig.VisitorRendering.LevelAttribute
    local function refresh()
        local level = hearth:GetAttribute(attribute)
        if type(level) ~= "number" or HearthVisualConfig.GetPresentation(level) == nil then
            return
        end
        local renderer = renderers[hearth] or createRenderer(hearth, false)
        local previous = renderer.TargetLevel
        setLevel(renderer, level, previous ~= nil and level > previous)
    end
    hearth:GetAttributeChangedSignal(attribute):Connect(refresh)
    refresh()
end

local function startVisitorRendering(ownBase: Instance): ()
    if not HearthVisualConfig.VisitorRendering.Enabled then
        return
    end
    local bases = ownBase.Parent
    if not bases then
        return
    end
    for _, base in bases:GetChildren() do
        local hearth = base:FindFirstChild("Hearth")
        if base ~= ownBase and hearth and hearth:IsA("Model") then
            watchVisitorHearth(hearth)
        end
    end
end

function HearthController.Start(): ()
    if started then
        return
    end
    started = true

    local prompt: ProximityPrompt? = nil
    local pendingUpdate: any = nil

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "CashUpdated" then
            if type(data) == "table" and type(data.Cash) == "number" then
                lastCash = data.Cash
            end
            return
        end

        if eventName == "WarmthUpdated" then
            local pressure = classifyPressure(data)
            if pressure and pressure ~= warmthPressure then
                warmthPressure = pressure
                if ownRenderer then
                    applyPressure(ownRenderer, false)
                end
            end
            return
        end

        if eventName ~= "HearthUpdated" then
            return
        end

        if ownRenderer and prompt then
            applyOwnUpdate(ownRenderer, prompt, data)
        else
            pendingUpdate = data
        end
    end)

    RunService.Heartbeat:Connect(onHeartbeat)

    task.spawn(function()
        local ownBase = OwnBaseController.WaitForOwnBase()
        local hearth = ownBase:WaitForChild("Hearth")
        local base = hearth:WaitForChild("HearthBase")
        local warmZone = ownBase:WaitForChild("WarmZone")
        local upgradePrompt = base:WaitForChild("UpgradePrompt")

        assert(hearth:IsA("Model"), string.format("%s must be a Model", hearth:GetFullName()))
        assert(warmZone:IsA("BasePart"), string.format("%s must be a BasePart", warmZone:GetFullName()))
        assert(upgradePrompt:IsA("ProximityPrompt"), string.format("%s must be a ProximityPrompt", upgradePrompt:GetFullName()))

        local renderer = createRenderer(hearth, true)
        createWarmZonePresentation(warmZone)
        updateBillboardScale(renderer)

        local camera = Workspace.CurrentCamera
        if camera then
            camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                updateBillboardScale(renderer)
            end)
        end

        upgradePrompt.Triggered:Connect(function()
            local data = lastHearthData
            local cash = lastCash
            if data ~= nil and not data.IsMaxLevel and cash ~= nil and cash < data.NextUpgradeCost then
                flashNeedCash(renderer, data.NextUpgradeCost - cash)
                return
            end
            gameplayRequest:FireServer("UpgradeHearth")
        end)

        ownRenderer = renderer
        prompt = upgradePrompt

        if pendingUpdate ~= nil then
            applyOwnUpdate(renderer, upgradePrompt, pendingUpdate)
            pendingUpdate = nil
        end

        startVisitorRendering(ownBase)
    end)
end

return HearthController
