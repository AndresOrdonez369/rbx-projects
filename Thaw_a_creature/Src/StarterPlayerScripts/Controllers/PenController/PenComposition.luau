-- PenComposition (F-D15-T05B.3): client-only presentation helper, required by PenController (never autoloaded).
-- Spatially NEUTRAL Pen life: every active creature is an equal resident of the whole unlocked Pen.
--   * neutral homes: a stable per-CreatureGUID seed spreads roots over the usable Pen. Size, Scale, species, rarity and
--     income are never inputs. Recomputed only when Pen membership or Pen depth changes (Ice never enters it);
--   * local destinations around the current spot, with a weak pull back toward home so the spread holds over time;
--   * movement CHARACTER by body size (reach / speed / pause / turn live in PenController.SIZE_CLASSES + Reach here)
--     never decides WHERE a creature may be;
--   * root-only spacing: bodies, wings and tails may overlap each other and spill through / over the fence;
--   * a narrow gate-root exclusion and a small local Ice footing detour.
-- Pure maths over PenController's creature records: it never edits instances, Scale, server state or gameplay.
local PenComposition = {}

local CFG = {
    RootMargin = 1.5, -- roots stay this far inside the side / rear fence (bodies may spill far beyond it)
    FrontMargin = 1.5, -- roots stay this far behind the front fence
    GateRootHalf = 8, -- the central gate entrance (gate half-width): no ROOT parks here...
    GateRootDepth = 6, -- ...this deep into the Pen. Heads, bodies, wings and tails may still cross it.
    RootScale = 0.5, -- root personal radius = clamp(narrow body half-extent * this, RootMin, RootMax)
    RootMin = 2,
    RootMax = 7,
    HomeSpread = 1.6, -- homes prefer this multiple of the root spacing between each other
    HomeTries = 40,
    FootingScale = 0.6, -- Ice detour footing = min(narrow core half-extent * this, FootingMax)
    FootingMax = 4,
    HomePull = 0.3, -- chance a new destination is drawn around home instead of around the current spot
    DestinationTries = 20,
    -- Destination reach per movement character (studs). Bigger bodies travel shorter, slower legs - never elsewhere.
    Reach = {
        Small = { 4, 14 },
        Medium = { 4, 12 },
        Large = { 3, 9 },
        Huge = { 3, 7 },
    },
    Glance = { Small = 35, Medium = 35, Large = 25, Huge = 14 },
    HomeYawRange = 100, -- initial facing: anywhere within this many degrees of facing the Lobby
}
PenComposition.Config = CFG

local function hash(text: string): number
    local h = 5381
    for i = 1, #text do
        h = (h * 33 + string.byte(text, i)) % 2147483647
    end
    return h
end

local function rootArea(env): (number, number, number, number)
    local half = env.HalfWidth - CFG.RootMargin
    return -half, half, CFG.FrontMargin, math.max(CFG.FrontMargin + 1, env.Depth - CFG.RootMargin)
end

local function inGate(x: number, z: number): boolean
    return math.abs(x) < CFG.GateRootHalf and z < CFG.GateRootDepth
end

local function rootRadius(c): number
    return math.clamp(math.min(c.HalfW, c.HalfL) * CFG.RootScale, CFG.RootMin, CFG.RootMax)
end

local function footing(c): number
    return math.min(math.min(c.CoreW, c.CoreL) * CFG.FootingScale, CFG.FootingMax)
end

-- Local Ice detour: only the creature's footing keeps clear of an ACTUAL placed Ice footprint + comfort gap.
local function iceClear(ctx, c, x: number, z: number): boolean
    local gap = ctx.CompEnv.IceGap
    local foot = footing(c)
    for _, o in ctx.Obstacles or {} do
        local clearance = math.max(o.HalfX, o.HalfZ) + gap + foot
        if (o.X - x) ^ 2 + (o.Z - z) ^ 2 < clearance * clearance then
            return false
        end
    end
    return true
end

local function inArea(env, x: number, z: number): boolean
    local xMin, xMax, zMin, zMax = rootArea(env)
    return x >= xMin - 1e-3 and x <= xMax + 1e-3 and z >= zMin - 1e-3 and z <= zMax + 1e-3
end

-- A legal resting spot for this creature's ROOT: inside the unlocked Pen, outside the gate entrance, off actual Ice.
function PenComposition.RootValid(ctx, c, x: number, z: number): boolean
    return inArea(ctx.CompEnv, x, z) and not inGate(x, z) and iceClear(ctx, c, x, z)
end

-- Root-only spacing: two roots never share effectively the same point (moving apart is always allowed).
function PenComposition.SpacingClear(ctx, c, x: number, z: number): boolean
    local mine = rootRadius(c)
    for _, o in ctx.Creatures do
        if o ~= c then
            local need = mine + rootRadius(o)
            local nextDistance = (x - o.X) ^ 2 + (z - o.Z) ^ 2
            if nextDistance < need * need and nextDistance < (c.X - o.X) ^ 2 + (c.Z - o.Z) ^ 2 then
                return false
            end
            if o.Mode == "walk" and o.TX and (x - o.TX) ^ 2 + (z - o.TZ) ^ 2 < need * need then
                return false
            end
        end
    end
    return true
end

-- Walk step check: never step INTO actual Ice footing (stepping out of it is fine) or onto another root.
function PenComposition.StepClear(ctx, c, x: number, z: number): boolean
    if not iceClear(ctx, c, x, z) and iceClear(ctx, c, c.X, c.Z) then
        return false
    end
    local mine = rootRadius(c)
    for _, o in ctx.Creatures do
        if o ~= c then
            local need = mine + rootRadius(o)
            local nextDistance = (x - o.X) ^ 2 + (z - o.Z) ^ 2
            if nextDistance < need * need and nextDistance < (c.X - o.X) ^ 2 + (c.Z - o.Z) ^ 2 then
                return false
            end
        end
    end
    return true
end

-- Neutral deterministic homes for EVERY creature (giants included): placement order and candidate spots come only from
-- a stable hash of CreatureGUID. Join burst snaps creatures onto their homes; later membership / depth changes only
-- update the homes (creatures keep wandering, nothing reshuffles).
function PenComposition.Plan(ctx, env)
    local list = {}
    for _, c in ctx.Creatures do
        table.insert(list, c)
    end
    table.sort(list, function(a, b)
        local ha, hb = hash(a.GUID), hash(b.GUID)
        if ha ~= hb then
            return ha < hb
        end
        return a.GUID < b.GUID
    end)
    local xMin, xMax, zMin, zMax = rootArea(env)
    local placed = {}
    local now = os.clock()
    for _, c in list do
        local rng = Random.new(hash(c.GUID))
        local mine = rootRadius(c)
        local bestX, bestZ, bestGap = (xMin + xMax) / 2, (zMin + zMax) / 2, -math.huge
        for _ = 1, CFG.HomeTries do
            local x, z = rng:NextNumber(xMin, xMax), rng:NextNumber(zMin, zMax)
            if not inGate(x, z) then
                local gap = math.huge
                for _, p in placed do
                    local spacing = (mine + rootRadius(p)) * CFG.HomeSpread
                    gap = math.min(gap, math.sqrt((x - p.NestX) ^ 2 + (z - p.NestZ) ^ 2) - spacing)
                end
                if gap >= 0 then
                    bestX, bestZ, bestGap = x, z, gap
                    break
                elseif gap > bestGap then
                    bestX, bestZ, bestGap = x, z, gap
                end
            end
        end
        c.NestX, c.NestZ = bestX, bestZ
        c.NestYaw = math.rad(rng:NextNumber(-CFG.HomeYawRange, CFG.HomeYawRange))
        table.insert(placed, c)
        if now - (c.RegisteredAt or 0) < env.JoinSnap then
            c.X, c.Z = bestX, bestZ
            c.Yaw, c.BaseYaw, c.GlanceYaw = c.NestYaw, c.NestYaw, c.NestYaw
            c.Mode, c.TX, c.TZ = "idle", nil, nil
        end
    end
end

-- A local destination: around the current spot, or (sometimes) around home. Reach is movement character only.
function PenComposition.PickDestination(ctx, c): (number?, number?)
    local env = ctx.CompEnv
    local rng = c.Rng
    local reach = CFG.Reach[c.Class] or CFG.Reach.Medium
    local xMin, xMax, zMin, zMax = rootArea(env)
    local standingClear = iceClear(ctx, c, c.X, c.Z)
    for _ = 1, CFG.DestinationTries do
        local fromX, fromZ = c.X, c.Z
        if c.NestX and rng:NextNumber() < CFG.HomePull then
            fromX, fromZ = c.NestX, c.NestZ
        end
        local angle = rng:NextNumber(0, 2 * math.pi)
        local distance = rng:NextNumber(reach[1], reach[2])
        local x = fromX + math.cos(angle) * distance
        local z = fromZ + math.sin(angle) * distance
        -- Out-of-Pen candidates are re-drawn, never clamped (clamping would pile roots up along the fence).
        if x >= xMin and x <= xMax and z >= zMin and z <= zMax
            and (x - c.X) ^ 2 + (z - c.Z) ^ 2 > 1
            and not inGate(x, z)
            and iceClear(ctx, c, x, z)
            and (not standingClear or iceClear(ctx, c, (x + c.X) / 2, (z + c.Z) / 2))
            and PenComposition.SpacingClear(ctx, c, x, z)
        then
            return x, z
        end
    end
    return nil, nil
end

-- Nearest legal root spot (misplaced after a Pen change or an Ice dropped on the creature).
function PenComposition.Nearest(ctx, c): (number?, number?)
    if PenComposition.RootValid(ctx, c, c.X, c.Z) then
        return c.X, c.Z
    end
    local xMin, xMax, zMin, zMax = rootArea(ctx.CompEnv)
    for radius = 1, 30, 1.5 do
        for k = 0, 11 do
            local angle = k / 12 * 2 * math.pi
            local x = math.clamp(c.X + math.cos(angle) * radius, xMin, xMax)
            local z = math.clamp(c.Z + math.sin(angle) * radius, zMin, zMax)
            if PenComposition.RootValid(ctx, c, x, z) then
                return x, z
            end
        end
    end
    return nil, nil
end

function PenComposition.GlanceYaw(c): number
    local degrees = CFG.Glance[c.Class] or 35
    return c.BaseYaw + math.rad(c.Rng:NextNumber(-degrees, degrees))
end

-- Changes only with Pen progression (displayed depth). Ice placement / removal never re-plans creatures.
function PenComposition.Signature(ctx): string
    return string.format("%.1f", ctx.Depth or 0)
end

return PenComposition
