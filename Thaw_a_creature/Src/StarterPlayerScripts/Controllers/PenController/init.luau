-- Living Pen presentation (F-D15-T05C). Client-local only: it never grants Cash, never moves gameplay anchors
-- (PenOrigin / PenFloor / CreaturePositions) and never changes server-owned state. It owns:
--   * the paddock size/colour per replicated PenLevel (Workspace.Bases.BaseN.PenArt, authored at Lv1),
--   * the upgrade animation (only on a real +1 PenLevel change, never on hydration),
--   * roaming / idle life for the server's Pen creature models (moved locally; server never re-pivots them),
--   * per-creature cash popups that mirror the real FinalIncome once per second,
--   * the wooden banner at the gate (owner upgrade button -> GameplayRequest "UpgradePen", visitors read-only).
-- F-D15-T05B trophy-paddock pass (still client-local presentation only):
--   * chunky fence + signature gate arch + curb/apron kit, tiered by PenLevel (locked rail colour families kept),
--   * Huge showcase: rear-biased deterministic anchors, restrained sway, Pen-only shadows off (exact Scale kept),
--   * clamped stat-card / popup anchors and compact card numbers (server values untouched),
--   * thaw beds under any existing Ice + visitor-visible NEARLY READY / READY base cue (from ThawVisualStage only).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local PenConfig = require(shared:WaitForChild("PenConfig"))
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local GameConfig = require(shared:WaitForChild("GameConfig"))
-- F-D15-T05B.2: pet-first home bands / showcase anchors for non-Huge creatures (client-only helper, child module).
local PenComposition = require(script:WaitForChild("PenComposition"))

local PenController = {}

local localPlayer = Players.LocalPlayer

local BASES_FOLDER_NAME = "Bases"
local PEN_ART_NAME = "PenArt"
local PEN_LEVEL_ATTRIBUTE = "PenLevel"
local OWNER_ATTRIBUTE = "OwnerUserId"
local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local PLAYER_FOLDER_PREFIX = "Player_"
local STAT_BILLBOARD_NAME = "CreatureStatBillboard"
local TEMPORARY_PREFIX = "TemporaryReveal_"

-- Paddock geometry (pen-local: X across, Y up from the floor top, Z away from the lobby). The Edit-authored PenArt parts
-- are re-shaped locally into the chunky trophy-paddock kit (F-D15-T05B); gameplay anchors are never touched.
local HALF_WIDTH = PenConfig.Width / 2
local GATE_HALF_WIDTH = 8
local RAIL_HEIGHTS = { 1.15, 2.45 }
local RAIL_SIZE_THIN = 0.55
local RAIL_SIZE_TALL = 0.5
local POST_SIZE = Vector3.new(1.3, 3.7, 1.3)
local POST_SPACING = 8
local MAX_SIDE_POSTS = 6
local REAR_POST_X = { -8, 0, 8 }
local GROUND_THICKNESS = 0.22
local GROUND_EDGE = 0.4
local CURB_WIDTH = 1.1
local CURB_HEIGHT = 0.35
local GATE_PILLAR_SIZE = Vector3.new(2.2, 6.4, 2.2)
local KIT_FOLDER_NAME = "PenKitLocal"

local CYAN = Color3.fromRGB(80, 215, 255)
local VIOLET = Color3.fromRGB(118, 92, 240)
local ACCENT_COLOR = CYAN
local SNOW_COLOR = Color3.fromRGB(246, 250, 255)
local LANTERN_COLOR = Color3.fromRGB(255, 190, 90)
local APRON_COLOR = Color3.fromRGB(176, 128, 92)
local FENCE_PALETTE = {
    Color3.fromRGB(122, 96, 72), -- Lv1 weathered brown pine
    Color3.fromRGB(190, 138, 70), -- Lv2 golden cedar
    Color3.fromRGB(156, 80, 56), -- Lv3 reddish cedar
    Color3.fromRGB(188, 198, 204), -- Lv4 pale frostwood
    Color3.fromRGB(104, 160, 206), -- Lv5 glacier blue
    Color3.fromRGB(100, 84, 164), -- Lv6 indigo / violet frostwood
    Color3.fromRGB(42, 44, 54), -- Lv7 blackened frostwood (+ icy cyan caps)
}
-- Darker trim per level family (posts, gate frame, curbs) so every rail colour reads against the snow ground.
local TRIM_PALETTE = {
    Color3.fromRGB(86, 58, 38),
    Color3.fromRGB(112, 70, 34),
    Color3.fromRGB(92, 42, 30),
    Color3.fromRGB(58, 78, 104),
    Color3.fromRGB(34, 78, 132),
    Color3.fromRGB(50, 38, 104),
    Color3.fromRGB(24, 26, 36),
}
-- Reusable prestige kit: rail colour family stays locked; ornament steps up (snow -> lanterns/crest -> rune/crystal -> black-ice).
local WOOD = Enum.Material.Wood
local PLANKS = Enum.Material.WoodPlanks
local SMOOTH = Enum.Material.SmoothPlastic
local SLATE = Enum.Material.Slate
local TIERS = {
    { PostMaterial = WOOD, RailMaterial = PLANKS, Snow = true },
    { PostMaterial = WOOD, RailMaterial = PLANKS, Snow = true, Band = Color3.fromRGB(236, 178, 82), Lantern = true },
    { PostMaterial = WOOD, RailMaterial = PLANKS, Snow = true, Band = Color3.fromRGB(244, 198, 112), Lantern = true, Crest = 1 },
    { PostMaterial = SMOOTH, RailMaterial = SMOOTH, Snow = true, Band = Color3.fromRGB(150, 200, 232), Lantern = true, Crest = 1 },
    { PostMaterial = SMOOTH, RailMaterial = SMOOTH, Snow = true, Band = CYAN, NeonBand = true, Crest = 2, Gem = CYAN, Rune = CYAN, Crystal = CYAN },
    { PostMaterial = SLATE, RailMaterial = SMOOTH, Snow = true, Band = VIOLET, NeonBand = true, Crest = 2, Gem = VIOLET, Rune = CYAN, Crystal = VIOLET, Crystal2 = CYAN },
    { PostMaterial = SLATE, RailMaterial = SMOOTH, Snow = false, Band = CYAN, NeonBand = true, Crest = 2, Gem = CYAN, Rune = CYAN, Crystal = CYAN, Crystal2 = Color3.fromRGB(92, 54, 228), NeonCaps = true },
}

-- Upgrade animation
local UPGRADE_SECONDS = 1.2
local HYDRATION_GRACE_SECONDS = 3
local PUFF_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"

-- Roaming (F-D15-T05B.3: spatially neutral; where-rules live in the PenComposition helper)
local OBSTACLE_GAP = 1 -- comfortable margin around each ACTUAL placed Ice footprint
local OBSTACLE_REFRESH_SECONDS = 0.5
local CULL_DISTANCE = 260
local NEAR_DISTANCE = 100
local FAR_UPDATE_INTERVAL = 0.1
local SIZE_CLASSES = {
    Small = { MaxFootprint = 6, Speed = { 3, 5 }, Range = nil, Idle = { 1.5, 4 }, Turn = 6, Breath = 0.03 },
    Medium = { MaxFootprint = 12, Speed = { 2.5, 4 }, Range = { 4, 14 }, Idle = { 2.5, 6 }, Turn = 3.5, Breath = 0.04 },
    -- Movement CHARACTER only (speed / pause / turn); it never decides where in the Pen a creature may be.
    Large = { MaxFootprint = PenConfig.Width * 2, Speed = { 1.4, 2.6 }, Idle = { 4, 8 }, Turn = 1.6, Breath = 0.05 },
    -- Extreme bodies (5x giants): slow, heavy, deliberate travel + long pauses; same whole-Pen freedom as everyone.
    Huge = { MaxFootprint = math.huge, Speed = { 0.6, 1.1 }, Idle = { 5, 10 }, Turn = 0.35, Breath = 0.07 },
}

-- Every creature is an equal resident of the whole unlocked Pen (F-D15-T05B.3): no bands, no Huge rear showcase. Bodies
-- keep exact Scale and may spill through / over the fence; only the reduced core is used for spacing.
local ROAM = {
    WideCore = 0.6, -- long / wide bodies collide / bound by their core, so wings and tails may overlap
    WideAt = 0.75, -- fraction of the Pen width from which a body counts as long / wide (a 30-stud serpent in a 32-stud Pen)
}

-- Giant presentation (visual only - never spatial priority): idle sway amplitude and the join-burst snap window.
local HUGE = {
    Sway = 0.35,
    JoinSnapSeconds = 4,
}

-- Owner reaction
local REACT_DISTANCE = 14
local REACT_RELEASE_DISTANCE = 22
local REACT_SECONDS = 3
local REACT_COOLDOWN_SECONDS = 6
local REACT_APPROACH = 2
local REACT_CHECK_INTERVAL = 0.2

-- Cash popups (presentation only)
local POPUP_SECONDS = 0.9
local POPUP_RISE = 2.4
local POPUP_OWN_DISTANCE = 120
local POPUP_OTHER_DISTANCE = 45
-- Popup lane + world-space creature UI anchors (never above the useful presentation height).
local UI = {
    PopupLift = 2.4,
    PopupJitter = 1.6,
    PopupSize = UDim2.fromOffset(160, 46),
    PopupSizeSmall = UDim2.fromOffset(124, 36),
    PopupText = 30,
    PopupTextSmall = 23,
    SmallViewportWidth = 900,
    TopMargin = 1.4,
    MaxHeight = 14,
    HugeHeight = 10,
    HugeForward = 12,
    CardAttachmentName = "CreatureStatAttachment",
}

-- Server stat card (presentation override only: shorter range, no longer drawn through the world)
local CARD_MAX_DISTANCE = 30

-- Banner
local BANNER_PIXELS_PER_STUD = 60
local BANNER_REFRESH_SECONDS = 0.5
local FLASH_SECONDS = 1.6
local PENDING_SECONDS = 2.5
local BUTTON_LOCK_SECONDS = 0.6
local SHAKE_SECONDS = 0.45

local started = false
local contexts = {}
local popupPool = {}
local activePopups = {}
local cash: number? = nil
local ownIncomeByGUID: { [string]: number } = {}
local toastSequence = 0
local gameplayRequest: RemoteEvent
local smallViewport = false

-- ===== helpers =====
local function compact(value: number): string
    local n = math.floor(value + 0.5)
    local suffixes = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
    for _, suffix in suffixes do
        if n >= suffix[1] then
            local v = n / suffix[1]
            local text
            if v >= 100 then
                text = string.format("%d", math.floor(v))
            elseif v >= 10 then
                text = string.format("%.1f", math.floor(v * 10) / 10)
            else
                text = string.format("%.2f", math.floor(v * 100) / 100)
            end
            if string.find(text, ".", 1, true) then
                text = string.gsub(text, "0+$", "")
                text = string.gsub(text, "%.$", "")
            end
            return text .. suffix[2]
        end
    end
    return tostring(n)
end

local function hashString(text: string): number
    local h = 5381
    for i = 1, #text do
        h = (h * 33 + string.byte(text, i)) % 2147483647
    end
    return h
end

local function angleDelta(from: number, to: number): number
    return (to - from + math.pi) % (2 * math.pi) - math.pi
end

local function approachAngle(current: number, target: number, maxStep: number): number
    local delta = angleDelta(current, target)
    if math.abs(delta) <= maxStep then
        return target
    end
    return current + math.sign(delta) * maxStep
end

local function yawFromDirection(dx: number, dz: number): number
    -- CFrame.Angles(0, yaw, 0).LookVector == (-sin yaw, 0, -cos yaw)
    return math.atan2(-dx, -dz)
end

local function getLevelConfig(level: number?)
    return PenConfig.Levels[if level and PenConfig.IsValidLevel(level) then level else 1]
end

local function getRootPart(): BasePart?
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function isOwner(ctx): boolean
    return ctx.Base:GetAttribute(OWNER_ATTRIBUTE) == localPlayer.UserId
end

-- ===== paddock geometry =====
local CAP_ROT = CFrame.Angles(0, 0, math.pi / 2) -- cylinders stand upright (their axis is local X)
local CAP_SIZE = Vector3.new(0.45, 1.8, 1.8)
local GEM_SIZE = Vector3.new(0.75, 0.75, 0.75)
local GEM_ROT = CFrame.Angles(math.rad(45), 0, math.rad(45))
local GATE_PILLAR_X = GATE_HALF_WIDTH + GATE_PILLAR_SIZE.X / 2
local FRONT_RAIL_INNER = GATE_PILLAR_X + GATE_PILLAR_SIZE.X / 2
local GATE_CAP_SIZE = Vector3.new(2.8, 0.5, 2.8)
local GATE_LINTEL_SIZE = Vector3.new(GATE_PILLAR_X * 2 + 2.6, 1.1, 1.7)
local GATE_LINTEL_Y = GATE_PILLAR_SIZE.Y + GATE_CAP_SIZE.Y + GATE_LINTEL_SIZE.Y / 2
local GATE_LINTEL_TOP = GATE_LINTEL_Y + GATE_LINTEL_SIZE.Y / 2
local BANNER_POST_SIZE = Vector3.new(0.85, 5.6, 0.85)

local KIT_CYLINDERS = { "GateSnowL", "GateSnowR", "BannerCapL", "BannerCapR" }
local KIT_BLOCKS = {
    "GatePlinthL", "GatePlinthR", "GateBandL", "GateBandR", "GateLintel", "GateLintelSnow", "GateCrestA", "GateCrestB",
    "GateEmblem", "GateRune", "GateLanternL", "GateLanternR", "GateCrystalL", "GateCrystalR", "GateCrystalL2",
    "GateCrystalR2", "GemPostFL", "GemPostFR", "GemPostB1", "GemPostB2", "GemPostB3", "BannerGem",
    "CurbL", "CurbR", "CurbB", "GateApron",
}
local GEM_NAMES = { "GemPostFL", "GemPostFR", "GemPostB1", "GemPostB2", "GemPostB3", "BannerGem" }

local function newKitPart(name: string, parent: Instance, shape: Enum.PartType?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Material = Enum.Material.SmoothPlastic
    if shape then
        part.Shape = shape
    end
    part.Parent = parent
    return part
end

local function capName(postName: string): string
    return "Cap" .. postName
end

-- Client-local ornament kit (never replicated, never collides, no scripts/lights/emitters). Parts are reused by every
-- level; applyStyle decides what shows.
local function createKit(ctx)
    local folder = Instance.new("Folder")
    folder.Name = KIT_FOLDER_NAME
    local kit = {}
    local function cylinder(name: string)
        kit[name] = newKitPart(name, folder, Enum.PartType.Cylinder)
    end
    for index = 1, MAX_SIDE_POSTS do
        cylinder(capName("PostL" .. index))
        cylinder(capName("PostR" .. index))
    end
    for index = 1, #REAR_POST_X do
        cylinder(capName("PostB" .. index))
    end
    cylinder(capName("PostFL"))
    cylinder(capName("PostFR"))
    for _, name in KIT_CYLINDERS do
        cylinder(name)
    end
    for _, name in KIT_BLOCKS do
        kit[name] = newKitPart(name, folder)
    end
    local beds = Instance.new("Folder")
    beds.Name = "ThawBeds"
    beds.Parent = folder
    folder.Parent = ctx.Art
    ctx.KitFolder = folder
    ctx.BedFolder = beds
    ctx.Kit = kit
end

local function setPart(ctx, name: string, size: Vector3, localCFrame: CFrame)
    local part = ctx.Parts[name] or ctx.Kit[name]
    if part then
        part.Size = size
        part.CFrame = ctx.Origin * localCFrame
    end
end

local function applyGeometry(ctx, depth: number, postDepth: number?)
    ctx.Depth = depth
    setPart(ctx, "Ground", Vector3.new(HALF_WIDTH * 2 + GROUND_EDGE * 2, GROUND_THICKNESS, depth + GROUND_EDGE),
        CFrame.new(0, -GROUND_THICKNESS / 2, (depth + GROUND_EDGE) / 2))
    -- Trim curb hugging the unlocked footprint only (never extends past the Pen).
    local curbX = HALF_WIDTH + GROUND_EDGE + CURB_WIDTH / 2 - 0.2
    local curbLength = depth + GROUND_EDGE + CURB_WIDTH
    setPart(ctx, "CurbL", Vector3.new(CURB_WIDTH, CURB_HEIGHT, curbLength), CFrame.new(-curbX, CURB_HEIGHT / 2 - 0.05, curbLength / 2))
    setPart(ctx, "CurbR", Vector3.new(CURB_WIDTH, CURB_HEIGHT, curbLength), CFrame.new(curbX, CURB_HEIGHT / 2 - 0.05, curbLength / 2))
    setPart(ctx, "CurbB", Vector3.new(curbX * 2 + CURB_WIDTH, CURB_HEIGHT, CURB_WIDTH),
        CFrame.new(0, CURB_HEIGHT / 2 - 0.05, depth + GROUND_EDGE + CURB_WIDTH / 2 - 0.2))
    for index, height in RAIL_HEIGHTS do
        setPart(ctx, "RailL" .. index, Vector3.new(RAIL_SIZE_THIN, RAIL_SIZE_TALL, depth), CFrame.new(-HALF_WIDTH, height, depth / 2))
        setPart(ctx, "RailR" .. index, Vector3.new(RAIL_SIZE_THIN, RAIL_SIZE_TALL, depth), CFrame.new(HALF_WIDTH, height, depth / 2))
        setPart(ctx, "RailB" .. index, Vector3.new(HALF_WIDTH * 2, RAIL_SIZE_TALL, RAIL_SIZE_THIN), CFrame.new(0, height, depth))
    end
    -- Post count follows the level's final depth so posts never pop during the overshoot of an upgrade.
    local segments = math.max(1, math.ceil((postDepth or depth) / POST_SPACING - 1e-6))
    for index = 1, MAX_SIDE_POSTS do
        local z = depth * math.min(index, segments) / segments
        local hidden = index > segments
        for _, side in { { "PostL", -HALF_WIDTH }, { "PostR", HALF_WIDTH } } do
            local name = side[1] .. index
            setPart(ctx, name, POST_SIZE, CFrame.new(side[2], POST_SIZE.Y / 2, z))
            local part = ctx.Parts[name]
            if part then
                part.Transparency = if hidden then 1 else 0
            end
            setPart(ctx, capName(name), CAP_SIZE, CFrame.new(side[2], POST_SIZE.Y + CAP_SIZE.X / 2, z) * CAP_ROT)
            local cap = ctx.Kit[capName(name)]
            if cap then
                cap.Transparency = if hidden then 1 else 0
            end
        end
    end
    for index, x in REAR_POST_X do
        setPart(ctx, "PostB" .. index, POST_SIZE, CFrame.new(x, POST_SIZE.Y / 2, depth))
        setPart(ctx, capName("PostB" .. index), CAP_SIZE, CFrame.new(x, POST_SIZE.Y + CAP_SIZE.X / 2, depth) * CAP_ROT)
        setPart(ctx, "GemPostB" .. index, GEM_SIZE, CFrame.new(x, POST_SIZE.Y + CAP_SIZE.X + 0.5, depth) * GEM_ROT)
    end
end

local RAIL_NAMES = { "RailL1", "RailL2", "RailR1", "RailR2", "RailB1", "RailB2", "RailFL1", "RailFL2", "RailFR1", "RailFR2", "BannerTrim" }

-- Fixed front: chunky gate arch, front fence, banner supports, entry apron. Never depends on the level.
local function applyStaticKit(ctx)
    for name, x in { PostFL = -HALF_WIDTH, PostFR = HALF_WIDTH } do
        setPart(ctx, name, POST_SIZE, CFrame.new(x, POST_SIZE.Y / 2, 0))
        setPart(ctx, capName(name), CAP_SIZE, CFrame.new(x, POST_SIZE.Y + CAP_SIZE.X / 2, 0) * CAP_ROT)
        setPart(ctx, "Gem" .. name, GEM_SIZE, CFrame.new(x, POST_SIZE.Y + CAP_SIZE.X + 0.5, 0) * GEM_ROT)
    end
    local railLength = HALF_WIDTH - FRONT_RAIL_INNER
    local railX = (HALF_WIDTH + FRONT_RAIL_INNER) / 2
    for index, height in RAIL_HEIGHTS do
        setPart(ctx, "RailFL" .. index, Vector3.new(railLength, RAIL_SIZE_TALL, RAIL_SIZE_THIN), CFrame.new(-railX, height, 0))
        setPart(ctx, "RailFR" .. index, Vector3.new(railLength, RAIL_SIZE_TALL, RAIL_SIZE_THIN), CFrame.new(railX, height, 0))
    end
    for _, side in { { "L", -1 }, { "R", 1 } } do
        local suffix, sign = side[1], side[2]
        local x = sign * GATE_PILLAR_X
        setPart(ctx, "GatePost" .. suffix, GATE_PILLAR_SIZE, CFrame.new(x, GATE_PILLAR_SIZE.Y / 2, 0))
        setPart(ctx, "GatePlinth" .. suffix, Vector3.new(3, 0.8, 3), CFrame.new(x, 0.4, 0))
        setPart(ctx, "GateBand" .. suffix, Vector3.new(2.45, 0.5, 2.45), CFrame.new(x, 4.6, 0))
        setPart(ctx, "GateCap" .. suffix, GATE_CAP_SIZE, CFrame.new(x, GATE_PILLAR_SIZE.Y + GATE_CAP_SIZE.Y / 2, 0))
        setPart(ctx, "GateSnow" .. suffix, Vector3.new(0.5, 2.6, 2.6), CFrame.new(sign * 10.2, GATE_LINTEL_TOP + 0.45, 0) * CAP_ROT)
        setPart(ctx, "GateLantern" .. suffix, Vector3.new(0.8, 1.05, 0.8), CFrame.new(sign * 5.4, GATE_LINTEL_Y - 1.4, 0))
        setPart(ctx, "GateCrystal" .. suffix, Vector3.new(0.95, 3, 0.95),
            CFrame.new(sign * 10.2, GATE_LINTEL_TOP + 1.75, 0) * CFrame.Angles(0, 0, math.rad(-16 * sign)))
        setPart(ctx, "GateCrystal" .. suffix .. "2", Vector3.new(0.65, 1.9, 0.65),
            CFrame.new(sign * 8.9, GATE_LINTEL_TOP + 1.05, 0.3) * CFrame.Angles(0, 0, math.rad(8 * sign)))
    end
    setPart(ctx, "GateLintel", GATE_LINTEL_SIZE, CFrame.new(0, GATE_LINTEL_Y, 0))
    setPart(ctx, "GateLintelSnow", Vector3.new(GATE_LINTEL_SIZE.X + 0.4, 0.4, GATE_LINTEL_SIZE.Z + 0.3), CFrame.new(0, GATE_LINTEL_TOP + 0.2, 0))
    setPart(ctx, "GateCrestA", Vector3.new(8, 1, 1.3), CFrame.new(0, GATE_LINTEL_TOP + 0.5, 0))
    setPart(ctx, "GateCrestB", Vector3.new(3.8, 1, 1.3), CFrame.new(0, GATE_LINTEL_TOP + 1.5, 0))
    setPart(ctx, "GateEmblem", Vector3.new(1.3, 1.3, 0.4), CFrame.new(0, GATE_LINTEL_Y, -GATE_LINTEL_SIZE.Z / 2 - 0.1) * CFrame.Angles(0, 0, math.rad(45)))
    setPart(ctx, "GateRune", Vector3.new(14, 0.2, 0.12), CFrame.new(0, GATE_LINTEL_Y - 0.32, -GATE_LINTEL_SIZE.Z / 2 - 0.03))
    setPart(ctx, "GateApron", Vector3.new(GATE_PILLAR_X * 2 + 3.2, 0.12, 4.2), CFrame.new(0, 0.06, -2.4))
    for name, x in { BannerPostL = 8.6, BannerPostR = 15.4 } do
        setPart(ctx, name, BANNER_POST_SIZE, CFrame.new(x, BANNER_POST_SIZE.Y / 2, -1.8))
    end
    setPart(ctx, "BannerCapL", Vector3.new(0.4, 1.25, 1.25), CFrame.new(8.6, BANNER_POST_SIZE.Y + 0.2, -1.8) * CAP_ROT)
    setPart(ctx, "BannerCapR", Vector3.new(0.4, 1.25, 1.25), CFrame.new(15.4, BANNER_POST_SIZE.Y + 0.2, -1.8) * CAP_ROT)
    setPart(ctx, "BannerGem", Vector3.new(0.7, 0.7, 0.7), CFrame.new(12, 5.95, -1.8) * GEM_ROT)
end

local function setLook(part: BasePart?, color: Color3, material: Enum.Material, visible: boolean)
    if part then
        part.Color = color
        part.Material = material
        part.Transparency = if visible then 0 else 1
    end
end

-- Level presentation: rail colour (locked family) + tier trim/ornament. Post visibility belongs to applyGeometry.
local function applyStyle(ctx, color: Color3, level: number)
    ctx.Color = color
    ctx.StyleLevel = level
    local tier = TIERS[level] or TIERS[1]
    local trim = TRIM_PALETTE[level] or TRIM_PALETTE[1]
    local parts, kit = ctx.Parts, ctx.Kit
    for _, name in RAIL_NAMES do
        local part = parts[name]
        if part then
            part.Color = color
            part.Material = tier.RailMaterial
        end
    end
    local capColor = if tier.NeonCaps then ACCENT_COLOR else SNOW_COLOR
    local capMaterial = if tier.NeonCaps then Enum.Material.Neon else SMOOTH
    for name, part in parts do
        if string.sub(name, 1, 4) == "Post" or name == "BannerPostL" or name == "BannerPostR" then
            part.Color = trim
            part.Material = tier.PostMaterial
            local cap = kit[capName(name)]
            if cap then
                setLook(cap, capColor, capMaterial, part.Transparency < 1)
            end
        end
    end
    for _, name in GEM_NAMES do
        setLook(kit[name], tier.Gem or ACCENT_COLOR, Enum.Material.Neon, tier.Gem ~= nil)
    end
    for _, suffix in { "L", "R" } do
        setLook(parts["GatePost" .. suffix], trim, tier.PostMaterial, true)
        setLook(kit["GatePlinth" .. suffix], trim:Lerp(Color3.new(0, 0, 0), 0.25), SLATE, true)
        setLook(parts["GateCap" .. suffix], if tier.NeonCaps then ACCENT_COLOR else trim:Lerp(Color3.new(0, 0, 0), 0.15),
            if tier.NeonCaps then Enum.Material.Neon else SLATE, true)
        setLook(kit["GateBand" .. suffix], tier.Band or trim, if tier.NeonBand then Enum.Material.Neon else SMOOTH, tier.Band ~= nil)
        setLook(kit["GateSnow" .. suffix], SNOW_COLOR, SMOOTH, tier.Snow)
        setLook(kit["GateLantern" .. suffix], LANTERN_COLOR, Enum.Material.Neon, tier.Lantern == true)
        setLook(kit["GateCrystal" .. suffix], tier.Crystal or ACCENT_COLOR, Enum.Material.Neon, tier.Crystal ~= nil)
        setLook(kit["GateCrystal" .. suffix .. "2"], tier.Crystal2 or ACCENT_COLOR, Enum.Material.Neon, tier.Crystal2 ~= nil)
    end
    setLook(kit.GateLintel, if tier.NeonCaps then trim else color, tier.PostMaterial, true)
    setLook(kit.GateLintelSnow, SNOW_COLOR, SMOOTH, tier.Snow)
    setLook(kit.GateCrestA, trim, tier.PostMaterial, (tier.Crest or 0) >= 1)
    setLook(kit.GateCrestB, trim, tier.PostMaterial, (tier.Crest or 0) >= 2)
    setLook(kit.GateEmblem, tier.Gem or tier.Band or trim, if tier.Gem then Enum.Material.Neon else SMOOTH, level >= 2)
    setLook(kit.GateRune, tier.Rune or ACCENT_COLOR, Enum.Material.Neon, tier.Rune ~= nil)
    for _, name in { "CurbL", "CurbR", "CurbB" } do
        setLook(kit[name], trim, SLATE, true)
    end
    setLook(kit.GateApron, APRON_COLOR, SLATE, true)
    -- Packed-snow paddock floor, a touch cooler than pure white so the Hearth's warm light never clips it.
    setLook(parts.Ground, Color3.fromRGB(196, 214, 234), Enum.Material.Snow, true)
    setLook(kit.BannerCapL, capColor, capMaterial, true)
    setLook(kit.BannerCapR, capColor, capMaterial, true)
end

local function getPuffEmitter(ctx): ParticleEmitter?
    if ctx.Puff and ctx.Puff.Parent then
        return ctx.Puff
    end
    local root = ctx.Parts.Root
    if not root then
        return nil
    end
    local attachment = Instance.new("Attachment")
    attachment.Name = "PenUpgradePuff"
    attachment.Parent = root
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Puff"
    emitter.Enabled = false
    emitter.Texture = PUFF_TEXTURE
    emitter.Color = ColorSequence.new(Color3.fromRGB(240, 246, 255))
    emitter.LightEmission = 0.15
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 2.8) })
    emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
    emitter.Lifetime = NumberRange.new(0.7, 1.1)
    emitter.Speed = NumberRange.new(2.5, 5)
    emitter.Drag = 4
    emitter.SpreadAngle = Vector2.new(70, 70)
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.Acceleration = Vector3.new(0, -2, 0)
    emitter.Parent = attachment
    ctx.Puff = emitter
    return emitter
end

local function puffAlongRear(ctx, depth: number)
    local emitter = getPuffEmitter(ctx)
    if not emitter then
        return
    end
    local attachment = emitter.Parent :: Attachment
    -- Root sits at the PenOrigin, so attachment positions are pen-local.
    for _, x in { -HALF_WIDTH, -8, 0, 8, HALF_WIDTH } do
        attachment.Position = Vector3.new(x, 0.4, depth)
        emitter:Emit(5)
    end
end

-- Prefab: StarterGui.PenUpgradeToast (authored in Studio).
local function showToast(level: number)
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    local gui = if playerGui then playerGui:FindFirstChild("PenUpgradeToast") else nil
    if not gui or not gui:IsA("ScreenGui") then
        return
    end
    toastSequence += 1
    local sequence = toastSequence

    local frame = gui:WaitForChild("Toast")
    local scale = frame:WaitForChild("Pop") :: UIScale
    local title = frame:WaitForChild("Title") :: TextLabel
    local sub = frame:WaitForChild("Sub") :: TextLabel
    title.Text = string.format("PEN LV. %d", level)
    for _, label in { title, sub } do
        label.TextTransparency = 0
        label.TextStrokeTransparency = 0.2
    end
    scale.Scale = 0.6
    gui.Enabled = true

    TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    task.delay(2.1, function()
        if toastSequence ~= sequence then
            return
        end
        local info = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(title, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
        TweenService:Create(sub, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
        task.delay(0.5, function()
            if toastSequence == sequence then
                gui.Enabled = false
            end
        end)
    end)
end

local function snapToLevel(ctx, level: number)
    ctx.Anim = nil
    ctx.DisplayLevel = level
    applyGeometry(ctx, getLevelConfig(level).Depth)
    applyStyle(ctx, FENCE_PALETTE[level], level)
end

-- Small snow puff at the arch when the new tier ornament swaps in (same emitter, no new effects).
local function puffAtGate(ctx)
    local emitter = getPuffEmitter(ctx)
    if not emitter then
        return
    end
    local attachment = emitter.Parent :: Attachment
    for _, x in { -GATE_PILLAR_X, 0, GATE_PILLAR_X } do
        attachment.Position = Vector3.new(x, GATE_LINTEL_TOP, 0)
        emitter:Emit(4)
    end
end

local function startUpgradeAnimation(ctx, level: number)
    ctx.Anim = {
        FromDepth = ctx.Depth,
        ToDepth = getLevelConfig(level).Depth,
        FromColor = ctx.Color,
        ToColor = FENCE_PALETTE[level],
        FromLevel = ctx.StyleLevel or ctx.DisplayLevel,
        Swapped = false,
        Start = os.clock(),
        Level = level,
    }
    ctx.DisplayLevel = level
    puffAlongRear(ctx, ctx.Depth)
end

local function updateAnimation(ctx, now: number)
    local anim = ctx.Anim
    if not anim then
        return
    end
    local alpha = math.clamp((now - anim.Start) / UPGRADE_SECONDS, 0, 1)
    local grow = TweenService:GetValue(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tint = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    applyGeometry(ctx, anim.FromDepth + (anim.ToDepth - anim.FromDepth) * grow, anim.ToDepth)
    if alpha >= 0.5 and not anim.Swapped then
        anim.Swapped = true
        puffAtGate(ctx)
    end
    applyStyle(ctx, anim.FromColor:Lerp(anim.ToColor, tint), if anim.Swapped then anim.Level else anim.FromLevel)
    if alpha >= 1 then
        ctx.Anim = nil
        applyGeometry(ctx, anim.ToDepth)
        applyStyle(ctx, anim.ToColor, anim.Level)
        puffAlongRear(ctx, anim.ToDepth)
    end
end

-- ===== creatures =====
local function classify(footprint: number): string
    if footprint <= SIZE_CLASSES.Small.MaxFootprint then
        return "Small"
    elseif footprint <= SIZE_CLASSES.Medium.MaxFootprint then
        return "Medium"
    elseif footprint <= SIZE_CLASSES.Large.MaxFootprint then
        return "Large"
    end
    return "Huge"
end

local function randomRange(rng: Random, range): number
    return rng:NextNumber(range[1], range[2])
end

local function enterIdle(c, now: number, short: boolean?)
    local class = SIZE_CLASSES[c.Class]
    c.Mode = "idle"
    c.BaseYaw = c.Yaw
    c.GlanceYaw = c.Yaw
    c.GlanceAt = now + c.Rng:NextNumber(0.8, 2.5)
    c.NextAt = now + (if short then c.Rng:NextNumber(1, 2) else randomRange(c.Rng, class.Idle))
end

-- Every size picks a local destination anywhere in the unlocked Pen (reach / speed are movement character only).
local function chooseDestination(ctx, c, now: number)
    local x, z = PenComposition.PickDestination(ctx, c)
    if x then
        c.Mode = "walk"
        c.TX, c.TZ = x, z
        c.Speed = randomRange(c.Rng, SIZE_CLASSES[c.Class].Speed)
        return
    end
    enterIdle(c, now, true)
end

-- Misplaced (Pen depth change, an Ice dropped onto the root): walk / snap to the nearest legal root spot.
local function softReset(ctx, c, now: number)
    local x, z = PenComposition.Nearest(ctx, c)
    if not x then
        return
    end
    if (x - c.X) ^ 2 + (z - c.Z) ^ 2 > 64 then
        c.X, c.Z = x, z
        enterIdle(c, now, true)
    else
        c.Mode = "walk"
        c.TX, c.TZ = x, z
        c.Speed = (SIZE_CLASSES[c.Class].Speed[2]) * 1.4
    end
end

local function poseCreature(ctx, c, now: number)
    local class = SIZE_CLASSES[c.Class]
    local bob, pitch, roll = 0, 0, 0
    if c.Mode == "walk" or (c.Mode == "react" and c.Moving) then
        local speed = c.Speed or 2
        local phase = c.BobT
        if c.Class == "Small" then
            bob = math.abs(math.sin(phase * 2.2 * speed)) * 0.32
            pitch = math.sin(phase * 2.2 * speed) * 0.05
        elseif c.Class == "Medium" then
            bob = math.abs(math.sin(phase * 1.6 * speed)) * 0.12
            roll = math.sin(phase * 1.6 * speed) * 0.03
        else
            bob = math.abs(math.sin(phase * 1.2 * speed)) * 0.07
            roll = math.sin(phase * 1.2 * speed) * 0.02
        end
    else
        bob = (math.sin(now * 1.7 + c.Phase * 6.283) + 1) * class.Breath
    end
    local swayX, swayZ = 0, 0
    if c.Class == "Huge" then
        swayX = math.sin(now * 0.31 + c.Phase * 6.283) * HUGE.Sway
        swayZ = math.sin(now * 0.23 + c.Phase * 3.7) * HUGE.Sway * 0.6
    end
    local pivot = ctx.Origin
        * CFrame.new(c.X + swayX, c.Y + bob, c.Z + swayZ)
        * CFrame.Angles(0, c.Yaw, 0)
        * CFrame.Angles(pitch, 0, roll)
        * c.Residual
    local cframes = table.create(#c.Parts)
    for index, offset in c.Offsets do
        cframes[index] = pivot * offset
    end
    Workspace:BulkMoveTo(c.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

-- F-D15-T05B.3: neutral deterministic homes for every creature (no bands, no Huge anchors). Re-planned only when Pen
-- membership or Pen depth changes; Ice never triggers it.
local function assignDepthPrefs(ctx)
    if not ctx.CompEnv then
        ctx.CompEnv = {
            HalfWidth = HALF_WIDTH,
            IceGap = OBSTACLE_GAP,
            JoinSnap = HUGE.JoinSnapSeconds,
        }
    end
    ctx.CompEnv.Depth = ctx.Depth
    PenComposition.Plan(ctx, ctx.CompEnv)
end

local function stepCreature(ctx, c, dt: number, now: number)
    local class = SIZE_CLASSES[c.Class]
    c.Moving = false
    if c.Mode == "react" then
        local root = getRootPart()
        if not root or now >= c.ReactUntil then
            ctx.React = nil
            ctx.ReactCooldownUntil = now + REACT_COOLDOWN_SECONDS
            enterIdle(c, now)
        else
            local p = ctx.Origin:PointToObjectSpace(root.Position)
            local dx, dz = p.X - c.X, p.Z - c.Z
            if dx * dx + dz * dz > REACT_RELEASE_DISTANCE ^ 2 then
                c.ReactUntil = now
            end
            c.Yaw = approachAngle(c.Yaw, yawFromDirection(dx, dz), class.Turn * dt)
            if c.TX then
                local mx, mz = c.TX - c.X, c.TZ - c.Z
                local distance = math.sqrt(mx * mx + mz * mz)
                if distance > 0.05 then
                    local step = math.min(distance, (c.Speed or 2) * dt)
                    c.X += mx / distance * step
                    c.Z += mz / distance * step
                    c.Moving = true
                    c.BobT += dt
                end
            end
        end
        return
    end

    if c.Mode == "walk" then
        local dx, dz = c.TX - c.X, c.TZ - c.Z
        local distance = math.sqrt(dx * dx + dz * dz)
        if distance < 0.15 then
            enterIdle(c, now)
            return
        end
        local desired = yawFromDirection(dx, dz)
        c.Yaw = approachAngle(c.Yaw, desired, class.Turn * dt)
        local misalign = math.abs(angleDelta(c.Yaw, desired))
        if misalign < 0.9 then
            local step = math.min(distance, c.Speed * dt * (1 - misalign / 1.8))
            local nx, nz = c.X + dx / distance * step, c.Z + dz / distance * step
            -- Root-only spacing + local Ice footing detour (bodies / wings / tails may overlap and spill).
            if not PenComposition.StepClear(ctx, c, nx, nz) then
                enterIdle(c, now, true)
                return
            end
            c.X, c.Z = nx, nz
            c.Moving = true
            c.BobT += dt
        end
        return
    end

    -- idle: glances, then pick the next destination
    if now >= c.GlanceAt then
        c.GlanceYaw = PenComposition.GlanceYaw(c)
        c.GlanceAt = now + c.Rng:NextNumber(1.5, 3.5)
    end
    c.Yaw = approachAngle(c.Yaw, c.GlanceYaw, class.Turn * 0.5 * dt)
    if now >= c.NextAt then
        chooseDestination(ctx, c, now)
    end
end

-- ===== world-space creature UI anchors =====
-- Card sits at the creature's top (+margin) but never above UI.MaxHeight. Huge creatures anchor just in front of their
-- showcase position, inside the Pen at a ground-readable height (never at a 90+ stud bounding-box top).
local function getUiWorldPosition(ctx, c): Vector3
    if c.Class == "Huge" then
        local forward = math.min(UI.HugeForward, (c.ExtZ or c.HalfL) * 0.6)
        local x = math.clamp(c.X, -HALF_WIDTH + 3, HALF_WIDTH - 3)
        local z = math.clamp(c.Z - forward, 4, math.max(4, ctx.Depth - 3))
        return ctx.Origin * Vector3.new(x, math.min(c.UiAbove, UI.HugeHeight), z)
    end
    local root = c.Root.Position
    return Vector3.new(root.X, ctx.Origin.Position.Y + c.UiAbove, root.Z)
end

-- ===== cash popups =====
local function acquirePopup(): BillboardGui?
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return nil
    end
    local popup = table.remove(popupPool)
    if popup and popup.Parent then
        return popup
    end
    -- Prefab: ReplicatedStorage.UITemplates.PenCashPopup (authored in Studio).
    popup = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild("PenCashPopup"):Clone() :: BillboardGui
    popup.Name = "PenCashPopup"
    popup.Enabled = false
    popup.Parent = playerGui
    return popup
end

local function releasePopup(entry)
    local popup = entry.Gui
    popup.Enabled = false
    popup.Adornee = nil
    entry.Creature.Popup = nil
    table.insert(popupPool, popup)
end

local function spawnPopup(ctx, c, now: number, cameraPosition: Vector3)
    if not c.Income or not c.Root or not c.Root.Parent then
        return
    end
    local own = isOwner(ctx)
    local maxDistance = if own then POPUP_OWN_DISTANCE else POPUP_OTHER_DISTANCE
    -- Popup lane sits just above the stat card; a small per-creature sideways offset keeps neighbours from stacking.
    local anchor = getUiWorldPosition(ctx, c) + Vector3.new(((c.Phase * 7.3) % 1 - 0.5) * UI.PopupJitter, UI.PopupLift, 0)
    if (anchor - cameraPosition).Magnitude > maxDistance then
        return
    end
    if c.Popup then
        releasePopup(c.Popup)
    end
    local popup = acquirePopup()
    if not popup then
        return
    end
    local label = popup:FindFirstChild("Amount") :: TextLabel
    label.Text = "+$" .. compact(c.Income)
    label.TextSize = if smallViewport then UI.PopupTextSmall else UI.PopupText
    popup.Size = if smallViewport then UI.PopupSizeSmall else UI.PopupSize
    label.TextTransparency = 0
    label.TextStrokeTransparency = 0.15
    popup.MaxDistance = maxDistance
    popup.Adornee = c.Root
    local offset = anchor - c.Root.Position
    popup.StudsOffsetWorldSpace = offset
    local punch = popup:FindFirstChild("Punch") :: UIScale
    punch.Scale = 0.55
    popup.Enabled = true
    local entry = { Gui = popup, Label = label, Punch = punch, Start = now, Creature = c, Offset = offset }
    c.Popup = entry
    activePopups[entry] = true
end

local function updatePopups(now: number)
    for entry in activePopups do
        local alpha = (now - entry.Start) / POPUP_SECONDS
        if alpha >= 1 or entry.Creature.Popup ~= entry then
            activePopups[entry] = nil
            if entry.Creature.Popup == entry then
                releasePopup(entry)
            end
        else
            local rise = 1 - (1 - alpha) ^ 3
            entry.Gui.StudsOffsetWorldSpace = entry.Offset + Vector3.new(0, POPUP_RISE * rise, 0)
            local s
            if alpha < 0.12 then
                s = 0.55 + (1.18 - 0.55) * (alpha / 0.12)
            elseif alpha < 0.24 then
                s = 1.18 - 0.18 * ((alpha - 0.12) / 0.12)
            else
                s = 1
            end
            entry.Punch.Scale = s
            local fade = math.clamp((alpha - 0.6) / 0.4, 0, 1)
            entry.Label.TextTransparency = fade
            entry.Label.TextStrokeTransparency = 0.15 + 0.85 * fade
        end
    end
end

-- ===== income =====
-- The server card text stays the source of truth; Pen cards are re-rendered locally with compact numbers and the exact
-- value is kept on the label (client-local attribute) for the banner / popup income read.
local RAW_INCOME_ATTRIBUTE = "PenRawIncome"
local COMPACT_HOOK_ATTRIBUTE = "PenCompactHooked"

local function formatCardLabel(label: TextLabel)
    local speed, amount = string.match(label.Text, "^SPEED ([%d%.]+)\nPEN %$(%d+)/s$")
    local value = tonumber(amount)
    if not speed or not value then
        return
    end
    label:SetAttribute(RAW_INCOME_ATTRIBUTE, value)
    local formatted = "SPEED " .. speed .. "\nPEN $" .. compact(value) .. "/s"
    if formatted ~= label.Text then
        label.Text = formatted
    end
end

local function readCardIncome(model: Model): number?
    for _, descendant in model:GetDescendants() do
        if descendant.Name == "Stats" and descendant:IsA("TextLabel") then
            local raw = descendant:GetAttribute(RAW_INCOME_ATTRIBUTE)
            if type(raw) == "number" then
                return raw
            end
            local amount = string.match(descendant.Text, "PEN %$(%d+)/s")
            if amount then
                return tonumber(amount)
            end
        end
    end
    return nil
end

local function resolveIncome(c)
    -- 1) the server's replicated stat card (exact FinalIncome); 2) own CreatureStateUpdated record; 3) formula fallback.
    local fromCard = readCardIncome(c.Model)
    if fromCard then
        c.Income = fromCard
        c.IncomeSource = "card"
        return
    end
    if c.GUID and ownIncomeByGUID[c.GUID] then
        c.Income = ownIncomeByGUID[c.GUID]
        c.IncomeSource = "state"
        return
    end
    local species = CreatureConfig[c.CreatureID]
    local scale = c.Model:GetAttribute("SizeScale")
    if species and type(species.BaseIncomePerSecond) == "number" and type(scale) == "number" then
        c.Income = math.max(1, math.round(species.BaseIncomePerSecond * scale ^ 2))
        c.IncomeSource = "formula"
    end
end

local function tameCard(instance: Instance)
    if instance:IsA("BillboardGui") and instance.Name == STAT_BILLBOARD_NAME then
        instance.AlwaysOnTop = false
        instance.MaxDistance = CARD_MAX_DISTANCE
    elseif instance:IsA("TextLabel") and instance.Name == "Stats" then
        formatCardLabel(instance)
        if not instance:GetAttribute(COMPACT_HOOK_ATTRIBUTE) then
            instance:SetAttribute(COMPACT_HOOK_ATTRIBUTE, true)
            instance:GetPropertyChangedSignal("Text"):Connect(function()
                formatCardLabel(instance)
            end)
        end
    end
end

-- Moves the server-made card attachment (client-local) to the clamped presentation anchor.
local function adjustCard(ctx, c)
    if not c.Root or not c.Root.Parent or ctx.Creatures[c.Model] ~= c then
        return
    end
    local world = getUiWorldPosition(ctx, c)
    for _, descendant in c.Model:GetDescendants() do
        if descendant:IsA("Attachment") and descendant.Name == UI.CardAttachmentName then
            local parent = descendant.Parent
            if parent and parent:IsA("BasePart") then
                descendant.Position = parent.CFrame:PointToObjectSpace(world)
            end
        elseif descendant:IsA("BillboardGui") and descendant.Name == STAT_BILLBOARD_NAME then
            -- A Huge card sits inside its own body, so it must draw through it; range stays short.
            descendant.AlwaysOnTop = c.Class == "Huge"
            descendant.MaxDistance = CARD_MAX_DISTANCE
        end
    end
end

-- ===== registration =====
local function unregisterCreature(ctx, model: Model)
    local c = ctx.Creatures[model]
    if not c then
        return
    end
    ctx.Creatures[model] = nil
    assignDepthPrefs(ctx)
    for _, connection in c.Connections do
        connection:Disconnect()
    end
    if c.Popup then
        activePopups[c.Popup] = nil
        releasePopup(c.Popup)
    end
    if ctx.React == c then
        ctx.React = nil
    end
    ctx.BannerDirty = true
end

local function registerCreature(ctx, model: Model)
    if ctx.Creatures[model] or not model:IsDescendantOf(Workspace) then
        return
    end
    if string.sub(model.Name, 1, #TEMPORARY_PREFIX) == TEMPORARY_PREFIX then
        return
    end
    local guid = model:GetAttribute("CreatureGUID")
    if type(guid) ~= "string" then
        return
    end
    local parts = {}
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
        tameCard(descendant)
    end
    if #parts == 0 then
        -- Streaming: wait for the first part, then register.
        local connection
        connection = model.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("BasePart") then
                connection:Disconnect()
                task.defer(registerCreature, ctx, model)
            end
        end)
        return
    end

    local serverPivot = model:GetPivot()
    local extents = model:GetExtentsSize()
    -- Body half-extents along the pivot's right / look axes (the pivot is the creature's facing).
    local boxCFrame, boxSize = model:GetBoundingBox()
    local function halfAlong(axis: Vector3): number
        return (math.abs(axis:Dot(boxCFrame.RightVector)) * boxSize.X
            + math.abs(axis:Dot(boxCFrame.UpVector)) * boxSize.Y
            + math.abs(axis:Dot(boxCFrame.LookVector)) * boxSize.Z) / 2
    end
    local halfW = halfAlong(serverPivot.RightVector)
    local halfL = halfAlong(serverPivot.LookVector)
    local footprint = 2 * math.max(halfW, halfL)
    local wide = footprint > PenConfig.Width * ROAM.WideAt
    local core = if wide then ROAM.WideCore else 1
    local localPivot = ctx.Origin:ToObjectSpace(serverPivot)
    local look = localPivot.LookVector
    local yaw = yawFromDirection(look.X, look.Z)
    local root = model.PrimaryPart or parts[1]
    local seed = hashString(guid)

    local c = {
        Model = model,
        GUID = guid,
        CreatureID = model:GetAttribute("CreatureID"),
        Parts = parts,
        Offsets = {},
        ServerPivot = serverPivot,
        Root = root,
        Footprint = footprint,
        HalfW = halfW,
        HalfL = halfL,
        Wide = wide,
        CoreW = halfW * core,
        CoreL = halfL * core,
        Radius = (halfW + halfL) / 2 * core,
        -- Creature-vs-creature personal space: between the body's half-width and its mean radius, so two long bodies
        -- can stand side by side in the 32-stud Pen instead of excluding each other's whole depth band.
        Personal = (math.min(halfW, halfL) + (halfW + halfL) / 2) / 2 * core,
        BoundRadius = math.max((halfW + halfL) / 2, 0.75 * halfL) * core,
        HomeYaw = yaw,
        Class = classify(footprint),
        X = localPivot.Position.X,
        Y = localPivot.Position.Y,
        Z = localPivot.Position.Z,
        Yaw = yaw,
        BaseYaw = yaw,
        GlanceYaw = yaw,
        Residual = (CFrame.Angles(0, yaw, 0)):Inverse() * localPivot.Rotation,
        Mode = "idle",
        NextAt = 0,
        GlanceAt = 0,
        BobT = 0,
        Phase = (seed % 100000) / 100000,
        Rng = Random.new(seed),
        Accumulated = 0,
        RegisteredAt = os.clock(),
        UiAbove = math.min(boxCFrame.Position.Y + halfAlong(Vector3.yAxis) + UI.TopMargin - ctx.Origin.Position.Y, UI.MaxHeight),
        Extents = extents,
        Connections = {},
    }
    for index, part in parts do
        c.Offsets[index] = serverPivot:ToObjectSpace(part.CFrame)
    end
    c.LastPopupIndex = math.floor(Workspace:GetServerTimeNow() + c.Phase)
    resolveIncome(c)
    ctx.Creatures[model] = c
    enterIdle(c, os.clock())
    c.NextAt = os.clock() + c.Rng:NextNumber(0.3, 2.5)
    if c.Class == "Huge" then
        -- Shadow only (never position): a 100-200 stud body must not drop a base-sized shadow sheet (client-local).
        for _, part in parts do
            part.CastShadow = false
        end
    end
    assignDepthPrefs(ctx)

    table.insert(c.Connections, model.DescendantAdded:Connect(function(descendant)
        tameCard(descendant)
        if descendant.Name == UI.CardAttachmentName or descendant.Name == STAT_BILLBOARD_NAME then
            task.defer(adjustCard, ctx, c)
        end
        if descendant:IsA("BasePart") then
            if c.Class == "Huge" then
                descendant.CastShadow = false
            end
            -- Late-streamed part: it arrives at its server location, relative to the untouched server pivot.
            table.insert(c.Parts, descendant)
            table.insert(c.Offsets, c.ServerPivot:ToObjectSpace(descendant.CFrame))
        elseif descendant:IsA("TextLabel") and descendant.Name == "Stats" then
            task.defer(function()
                resolveIncome(c)
                ctx.BannerDirty = true
            end)
        end
    end))
    table.insert(c.Connections, model.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            local index = table.find(c.Parts, descendant)
            if index then
                table.remove(c.Parts, index)
                table.remove(c.Offsets, index)
            end
        end
    end))
    table.insert(c.Connections, model.AncestryChanged:Connect(function()
        if not model:IsDescendantOf(ctx.Pen) then
            unregisterCreature(ctx, model)
        end
    end))
    adjustCard(ctx, c)
    ctx.BannerDirty = true
end

local function isPenCreatureModel(ctx, instance: Instance): boolean
    if not instance:IsA("Model") then
        return false
    end
    local folder = instance.Parent
    local container = folder and folder.Parent
    return folder ~= nil
        and folder:IsA("Folder")
        and string.sub(folder.Name, 1, #PLAYER_FOLDER_PREFIX) == PLAYER_FOLDER_PREFIX
        and container ~= nil
        and container.Name == CREATURE_VISUALS_FOLDER_NAME
        and container.Parent == ctx.Pen
end

-- Obstacles are the ACTUAL placed Ice (ThawVisuals/Player_<id>/<Ice>), sized to the visible bed ring around it.
local function refreshObstacles(ctx)
    local obstacles = {}
    local function add(child: Instance)
        local cframe, size
        if child:IsA("Model") then
            local ok, boxCFrame, boxSize = pcall(child.GetBoundingBox, child)
            if ok then
                cframe, size = boxCFrame, boxSize
            end
        elseif child:IsA("BasePart") then
            cframe, size = child.CFrame, child.Size
        end
        if cframe then
            local p = ctx.Origin:PointToObjectSpace(cframe.Position)
            local half = math.max(size.X, size.Z) * 0.55 -- the actual Ice footprint (+ its thin contact patch)
            if p.X > -HALF_WIDTH - half - 4 and p.X < HALF_WIDTH + half + 4 and p.Z > -half - 4 and p.Z < 60 + half then
                table.insert(obstacles, { X = p.X, Z = p.Z, HalfX = half, HalfZ = half })
            end
        end
    end
    local thawVisuals = ctx.Base:FindFirstChild("ThawVisuals")
    if thawVisuals then
        for _, child in thawVisuals:GetChildren() do
            if child:IsA("Folder") then
                for _, ice in child:GetChildren() do
                    add(ice)
                end
            else
                add(child)
            end
        end
    end
    ctx.Obstacles = obstacles
end

-- ===== thaw contact patch (presentation only) =====
-- F-D15-T05C1.2: the former 3-disc hero bed (slate ring + neon glow pool + melt disc) is reduced to one thin, low-weight
-- melt / contact patch under each Ice. It exists only because an Ice exists there and follows it. NEARLY READY / READY
-- stay readable through a restrained tint shift (no neon, no glow pool, no beacon) on top of the Ice's own Ready
-- billboard / prompt. The stage comes from the replicated ThawVisualStage attribute only (nothing hidden is revealed).
local BED = {
    Scale = 1.1,
    Height = 0.06,
    Colors = {
        Frozen = Color3.fromRGB(176, 200, 220),
        Thawing = Color3.fromRGB(160, 196, 226),
        NearlyReady = Color3.fromRGB(122, 186, 236),
        Ready = Color3.fromRGB(96, 196, 246),
    },
    Transparency = { Frozen = 0.7, Thawing = 0.64, NearlyReady = 0.56, Ready = 0.46 },
    CueDistance = 200,
}

local function destroyBed(bed)
    bed.Melt:Destroy()
end

local function applyBedStage(bed, stage: any)
    bed.Applied = stage
    bed.Melt.Color = BED.Colors[stage] or BED.Colors.Frozen
    bed.Melt.Transparency = BED.Transparency[stage] or BED.Transparency.Frozen
end

local function placeBed(bed, ice: BasePart)
    local position, size = ice.Position, ice.Size
    if bed.Position == position and bed.Size == size then
        return
    end
    bed.Position, bed.Size = position, size
    local diameter = math.max(size.X, size.Z)
    local bottom = position.Y - size.Y / 2
    local function put(part: BasePart, height: number, scale: number)
        part.Size = Vector3.new(height, diameter * scale, diameter * scale)
        part.CFrame = CFrame.new(position.X, bottom + height / 2, position.Z) * CAP_ROT
    end
    put(bed.Melt, BED.Height, BED.Scale)
end

local function createBed(ctx, ice: BasePart)
    local melt = newKitPart("BedMelt", ctx.BedFolder, Enum.PartType.Cylinder)
    melt.Material = Enum.Material.SmoothPlastic
    melt.Reflectance = 0.05
    local bed = { Melt = melt, Phase = (hashString(ice:GetFullName()) % 628) / 100, Near = false }
    applyBedStage(bed, ice:GetAttribute("ThawVisualStage"))
    ctx.Beds[ice] = bed
    return bed
end

local function refreshBeds(ctx, cameraPosition: Vector3)
    if not ctx.BedFolder then
        return
    end
    local seen = {}
    local thawVisuals = ctx.Base:FindFirstChild("ThawVisuals")
    if thawVisuals then
        for _, folder in thawVisuals:GetChildren() do
            if folder:IsA("Folder") then
                for _, ice in folder:GetChildren() do
                    if ice:IsA("BasePart") then
                        seen[ice] = true
                        local bed = ctx.Beds[ice] or createBed(ctx, ice)
                        placeBed(bed, ice)
                        local stage = ice:GetAttribute("ThawVisualStage")
                        if stage ~= bed.Applied then
                            applyBedStage(bed, stage)
                        end
                        bed.Near = (ice.Position - cameraPosition).Magnitude <= BED.CueDistance
                    end
                end
            end
        end
    end
    for ice, bed in ctx.Beds do
        if not seen[ice] then
            destroyBed(bed)
            ctx.Beds[ice] = nil
        end
    end
end

-- Restrained Ready breathing on the patch only near the camera; everything else keeps its static stage look.
local function updateBeds(ctx, now: number)
    for _, bed in ctx.Beds do
        if bed.Near and bed.Applied == "Ready" then
            bed.Melt.Transparency = BED.Transparency.Ready + 0.12 * (0.5 + 0.5 * math.sin(now * 2.4 + bed.Phase))
        end
    end
end

local function updateOwnerReaction(ctx, now: number)
    if ctx.React or now < ctx.ReactCooldownUntil or not isOwner(ctx) then
        return
    end
    local root = getRootPart()
    if not root then
        return
    end
    local p = ctx.Origin:PointToObjectSpace(root.Position)
    local best, bestDistance = nil, math.huge
    for _, c in ctx.Creatures do
        local distance = math.sqrt((p.X - c.X) ^ 2 + (p.Z - c.Z) ^ 2) - c.Radius
        if c.Class ~= "Huge" and distance < REACT_DISTANCE and distance < bestDistance then
            best, bestDistance = c, distance
        end
    end
    if not best then
        return
    end
    local c = best
    ctx.React = c
    c.Mode = "react"
    c.ReactUntil = now + REACT_SECONDS
    c.TX, c.TZ = nil, nil
    if c.Class ~= "Huge" then
        local dx, dz = p.X - c.X, p.Z - c.Z
        local distance = math.sqrt(dx * dx + dz * dz)
        local approach = math.min(REACT_APPROACH, math.max(0, distance - c.Radius - 2.5))
        if distance > 0.01 and approach > 0.2 then
            local x, z = c.X + dx / distance * approach, c.Z + dz / distance * approach
            if PenComposition.RootValid(ctx, c, x, z) and PenComposition.SpacingClear(ctx, c, x, z) then
                c.TX, c.TZ = x, z
                c.Speed = SIZE_CLASSES[c.Class].Speed[2]
            end
        end
    end
end

-- ===== banner =====
local function buildBanner(ctx)
    local board = ctx.Parts.BannerBoard
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    if not board or not playerGui then
        return
    end
    -- Prefab: ReplicatedStorage.UITemplates.PenBanner (authored in Studio).
    local gui = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild("PenBanner"):Clone() :: SurfaceGui
    gui.Name = "PenBanner_" .. ctx.Base.Name
    gui.Adornee = board
    gui.PixelsPerStud = BANNER_PIXELS_PER_STUD

    local body = gui:WaitForChild("Body") :: Frame
    local title = body:WaitForChild("Title") :: TextLabel
    local income = body:WaitForChild("Income") :: TextLabel
    local count = body:WaitForChild("Count") :: TextLabel
    local button = body:WaitForChild("Upgrade") :: TextButton
    local stroke = button:WaitForChild("Stroke") :: UIStroke

    gui.Parent = playerGui
    ctx.Banner = { Gui = gui, Body = body, Title = title, Income = income, Count = count, Button = button, Stroke = stroke }

    button.Activated:Connect(function()
        local now = os.clock()
        if not isOwner(ctx) or now < ctx.ButtonLockUntil then
            return
        end
        local level = ctx.Level
        if not level or level >= PenConfig.MaxLevel then
            return
        end
        local cost = PenConfig.Levels[level + 1].UpgradeCost
        if type(cost) ~= "number" then
            return
        end
        ctx.ButtonLockUntil = now + BUTTON_LOCK_SECONDS
        local root = getRootPart()
        local floor = ctx.Pen:FindFirstChild("PenFloor")
        if root and floor and (root.Position - floor.Position).Magnitude > GameConfig.PenManagementMaxDistance - 0.5 then
            ctx.Flash = { Text = "WALK CLOSER", Color = Color3.fromRGB(150, 150, 160), Until = now + FLASH_SECONDS }
            ctx.BannerDirty = true
            return
        end
        if cash ~= nil and cash < cost then
            ctx.Flash = { Text = "NEED $" .. compact(cost - cash) .. " MORE", Color = Color3.fromRGB(225, 72, 60), Until = now + FLASH_SECONDS }
            ctx.ShakeUntil = now + SHAKE_SECONDS
            ctx.BannerDirty = true
            return
        end
        ctx.PendingUntil = now + PENDING_SECONDS
        ctx.BannerDirty = true
        gameplayRequest:FireServer("UpgradePen")
    end)
end

local function refreshBanner(ctx, now: number)
    local banner = ctx.Banner
    if not banner then
        return
    end
    ctx.BannerDirty = false
    ctx.BannerNextRefresh = now + BANNER_REFRESH_SECONDS
    local level = ctx.Level
    local ownerId = ctx.Base:GetAttribute(OWNER_ATTRIBUTE)
    local button = banner.Button
    if not level or type(ownerId) ~= "number" then
        banner.Title.Text = "OPEN PLOT"
        banner.Income.Text = ""
        banner.Count.Text = ""
        button.Visible = false
        return
    end
    local total, count = 0, 0
    for _, c in ctx.Creatures do
        count += 1
        if c.Income then
            total += c.Income
        end
    end
    banner.Title.Text = string.format("PEN LV. %d", level)
    banner.Income.Text = "TOTAL $" .. compact(total) .. "/s"
    banner.Count.Text = string.format("%d / %d CREATURES", count, PenConfig.GetCapacity(level))
    button.Visible = true

    if ownerId ~= localPlayer.UserId then
        local owner = Players:GetPlayerByUserId(ownerId)
        button.Active = false
        button.AutoButtonColor = false
        button.BackgroundTransparency = 1
        banner.Stroke.Enabled = false
        button.TextColor3 = Color3.fromRGB(245, 228, 196)
        button.Text = if owner then string.upper(owner.DisplayName) .. "'S PEN" else "PEN"
        return
    end

    button.BackgroundTransparency = 0
    banner.Stroke.Enabled = true
    button.TextColor3 = Color3.fromRGB(40, 26, 8)
    if level >= PenConfig.MaxLevel then
        button.Active = false
        button.AutoButtonColor = false
        button.BackgroundColor3 = Color3.fromRGB(196, 150, 60)
        button.Text = "MAX LEVEL"
        return
    end
    local flash = ctx.Flash
    if flash and now < flash.Until then
        button.Active = true
        button.AutoButtonColor = false
        button.BackgroundColor3 = flash.Color
        button.TextColor3 = Color3.fromRGB(255, 248, 240)
        button.Text = flash.Text
        return
    end
    ctx.Flash = nil
    if now < ctx.PendingUntil then
        button.Active = false
        button.AutoButtonColor = false
        button.BackgroundColor3 = Color3.fromRGB(220, 190, 120)
        button.Text = "UPGRADING..."
        return
    end
    local cost = PenConfig.Levels[level + 1].UpgradeCost
    button.Active = true
    button.AutoButtonColor = true
    button.BackgroundColor3 = Color3.fromRGB(255, 200, 70)
    button.Text = "UPGRADE PEN  $" .. compact(cost)
end

local function updateShake(ctx, now: number)
    local banner = ctx.Banner
    if not banner then
        return
    end
    if now < ctx.ShakeUntil then
        local remaining = (ctx.ShakeUntil - now) / SHAKE_SECONDS
        banner.Body.Position = UDim2.fromOffset(math.sin(now * 70) * 9 * remaining, 0)
    elseif banner.Body.Position ~= UDim2.new() then
        banner.Body.Position = UDim2.new()
    end
end

-- ===== level / ownership =====
local function onLevelChanged(ctx)
    local value = ctx.Base:GetAttribute(PEN_LEVEL_ATTRIBUTE)
    local newLevel = if PenConfig.IsValidLevel(value) then value else nil
    local oldLevel = ctx.Level
    ctx.Level = newLevel
    ctx.PendingUntil = 0
    local isRealUpgrade = oldLevel ~= nil
        and newLevel ~= nil
        and newLevel == oldLevel + 1
        and os.clock() - ctx.OwnerChangedAt > HYDRATION_GRACE_SECONDS
    if isRealUpgrade then
        startUpgradeAnimation(ctx, newLevel)
        if isOwner(ctx) then
            showToast(newLevel)
        end
    else
        snapToLevel(ctx, newLevel or 1)
    end
    ctx.BannerDirty = true
end

local function setupBase(base: Instance)
    if not base:IsA("Folder") or contexts[base] then
        return
    end
    local art = base:WaitForChild(PEN_ART_NAME, 30)
    local pen = base:WaitForChild("Pen", 30)
    if not art or not pen then
        warn(string.format("[PenController] %s is missing PenArt or Pen; living Pen presentation skipped", base:GetFullName()))
        return
    end
    local parts = {}
    for _, part in art:GetChildren() do
        if part:IsA("BasePart") then
            parts[part.Name] = part
        end
    end
    local penOrigin = pen:FindFirstChild("PenOrigin")
    local origin = if penOrigin and penOrigin:IsA("BasePart") then penOrigin.CFrame
        elseif parts.Root then parts.Root.CFrame
        else nil
    if not origin then
        warn(string.format("[PenController] %s has no PenOrigin", base:GetFullName()))
        return
    end
    local ctx = {
        Base = base,
        Pen = pen,
        Art = art,
        Parts = parts,
        Origin = CFrame.new(origin.Position) * origin.Rotation,
        Level = nil,
        DisplayLevel = 1,
        Depth = getLevelConfig(1).Depth,
        Color = FENCE_PALETTE[1],
        Anim = nil,
        Creatures = {},
        Obstacles = {},
        ObstaclesAt = 0,
        OwnerChangedAt = os.clock(),
        React = nil,
        ReactCooldownUntil = 0,
        ReactCheckAt = 0,
        BannerDirty = true,
        BannerNextRefresh = 0,
        ButtonLockUntil = 0,
        PendingUntil = 0,
        ShakeUntil = 0,
        Flash = nil,
        Kit = {},
        Beds = {},
    }
    contexts[base] = ctx
    createKit(ctx)
    applyStaticKit(ctx)
    onLevelChanged(ctx)
    buildBanner(ctx)

    base:GetAttributeChangedSignal(PEN_LEVEL_ATTRIBUTE):Connect(function()
        onLevelChanged(ctx)
    end)
    base:GetAttributeChangedSignal(OWNER_ATTRIBUTE):Connect(function()
        ctx.OwnerChangedAt = os.clock()
        ctx.React = nil
        ctx.BannerDirty = true
    end)

    for _, descendant in pen:GetDescendants() do
        if isPenCreatureModel(ctx, descendant) then
            registerCreature(ctx, descendant)
        end
    end
    pen.DescendantAdded:Connect(function(descendant)
        if isPenCreatureModel(ctx, descendant) then
            task.defer(registerCreature, ctx, descendant)
        end
    end)
end

-- ===== main loop =====
local function update(dt: number)
    local now = os.clock()
    local serverNow = Workspace:GetServerTimeNow()
    local camera = Workspace.CurrentCamera
    local cameraPosition = if camera then camera.CFrame.Position else Vector3.zero
    smallViewport = camera ~= nil and camera.ViewportSize.X < UI.SmallViewportWidth
    for _, ctx in contexts do
        updateAnimation(ctx, now)
        if now >= ctx.ObstaclesAt then
            ctx.ObstaclesAt = now + OBSTACLE_REFRESH_SECONDS
            refreshObstacles(ctx)
            refreshBeds(ctx, cameraPosition)
            local signature = PenComposition.Signature(ctx)
            if signature ~= ctx.CompSignature then
                ctx.CompSignature = signature
                assignDepthPrefs(ctx)
            end
            for _, c in ctx.Creatures do
                if c.Class == "Huge" then
                    adjustCard(ctx, c)
                end
                if c.Mode ~= "walk" and c.Mode ~= "react" and not PenComposition.RootValid(ctx, c, c.X, c.Z) then
                    softReset(ctx, c, now)
                end
            end
        end
        if now >= ctx.ReactCheckAt then
            ctx.ReactCheckAt = now + REACT_CHECK_INTERVAL
            updateOwnerReaction(ctx, now)
        end
        for _, c in ctx.Creatures do
            local distance = (ctx.Origin * Vector3.new(c.X, c.Y, c.Z) - cameraPosition).Magnitude
            if distance <= CULL_DISTANCE then
                c.Accumulated += dt
                if distance <= NEAR_DISTANCE or c.Accumulated >= FAR_UPDATE_INTERVAL then
                    local step = math.min(c.Accumulated, 0.25)
                    c.Accumulated = 0
                    stepCreature(ctx, c, step, now)
                    if #c.Parts > 0 then
                        poseCreature(ctx, c, now)
                    end
                end
            end
            local popupIndex = math.floor(serverNow + c.Phase)
            if popupIndex ~= c.LastPopupIndex then
                c.LastPopupIndex = popupIndex
                if not c.Income then
                    resolveIncome(c)
                end
                spawnPopup(ctx, c, now, cameraPosition)
            end
        end
        if ctx.BannerDirty or now >= ctx.BannerNextRefresh then
            refreshBanner(ctx, now)
        end
        updateShake(ctx, now)
        updateBeds(ctx, now)
    end
    updatePopups(now)
end

function PenController.Start(): ()
    if started then
        return
    end
    started = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    gameplayRequest = remotes:WaitForChild("GameplayRequest")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if type(data) ~= "table" then
            return
        end
        if eventName == "CashUpdated" then
            if type(data.Cash) == "number" and data.Cash >= 0 and data.Cash < math.huge then
                cash = data.Cash
                for _, ctx in contexts do
                    if isOwner(ctx) then
                        ctx.BannerDirty = true
                    end
                end
            end
        elseif eventName == "CreatureStateUpdated" then
            if type(data.Creatures) == "table" then
                table.clear(ownIncomeByGUID)
                for _, record in data.Creatures do
                    if type(record) == "table" and record.AllocationState == "Pen"
                        and type(record.CreatureGUID) == "string" and type(record.FinalIncome) == "number" then
                        ownIncomeByGUID[record.CreatureGUID] = record.FinalIncome
                    end
                end
            end
        end
    end)

    task.spawn(function()
        local bases = Workspace:WaitForChild(BASES_FOLDER_NAME)
        for _, base in bases:GetChildren() do
            task.spawn(setupBase, base)
        end
        bases.ChildAdded:Connect(function(base)
            task.spawn(setupBase, base)
        end)
    end)

    RunService.Heartbeat:Connect(update)
end

return PenController
