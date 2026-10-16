-- Thaw placement rules (F-D15-T05C1), shared so the server authority (ThawService) and the client placement ghost use
-- the exact same math. Pure functions only: no instances, no state.
--
-- Coordinates are Pen-local, measured from the base's PenOrigin: X runs across the Pen (-Width/2 .. +Width/2) and Z runs
-- from the front fence / gate (0) toward the rear fence (+Depth of the current PenLevel). Footprints are half extents
-- of the Ice's authoritative scaled size (IceVisualFactory.GetScaledSize on the server; the carried Ice on the client).
local PenConfig = require(script.Parent:WaitForChild("PenConfig"))

export type Box = {
    X: number,
    Z: number,
    HalfX: number,
    HalfZ: number,
    Oversize: boolean?,
}

local ThawPlacement = {
    FenceClearance = 1, -- footprints stay this far inside the side / rear fence lines
    FrontClearance = 1, -- and this far behind the front fence line
    GateHalfWidth = 9.5, -- the gate opening (16 wide) plus pillar clearance is kept free...
    GateDepth = 7, -- ...this deep into the Pen, so the entry is never blocked
    IceGap = 0.6, -- minimum gap between two thawing Ice footprints
    MaxReach = 75, -- server sanity: horizontal distance from the requester to the chosen spot
    ScanStep = 1, -- fallback search resolution (studs)
}

local function getDepth(penLevel: any): number
    local level = if PenConfig.IsValidLevel(penLevel) then penLevel else 1
    return PenConfig.Levels[level].Depth
end

local function isFiniteNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

-- The rectangle every normal footprint must stay inside for the current PenLevel.
function ThawPlacement.GetInterior(penLevel: any): (number, number, number, number)
    local half = PenConfig.Width / 2 - ThawPlacement.FenceClearance
    return -half, half, ThawPlacement.FrontClearance, getDepth(penLevel) - ThawPlacement.FenceClearance
end

-- A footprint larger than the unlocked interior itself (jackpot-scale Ice) is "oversize": its centre must be inside the
-- Pen behind the gate, its body may spill over the fence like a giant creature, and it never blocks (nor is blocked by)
-- other Ice. Scale is never clamped to make it fit.
function ThawPlacement.IsOversize(penLevel: any, halfX: number, halfZ: number): boolean
    local xMin, xMax, zMin, zMax = ThawPlacement.GetInterior(penLevel)
    return halfX * 2 > xMax - xMin or halfZ * 2 > zMax - zMin
end

-- Fits the interior but no position avoids the gate strip (e.g. a Meteor in a Lv1 Pen): only the gate rule is waived;
-- fence, bounds and overlap rules still apply.
local function canClearGate(penLevel: any, halfX: number, halfZ: number): boolean
    local xMin, xMax, zMin, zMax = ThawPlacement.GetInterior(penLevel)
    local fitsBehindGate = halfZ * 2 <= zMax - ThawPlacement.GateDepth
    local fitsBesideGate = halfX * 2 <= xMax - ThawPlacement.GateHalfWidth and halfZ * 2 <= zMax - zMin
    return fitsBehindGate or fitsBesideGate
end

local function touchesGate(x: number, z: number, halfX: number, halfZ: number): boolean
    local gate = ThawPlacement.GateHalfWidth
    return x - halfX < gate and x + halfX > -gate and z - halfZ < ThawPlacement.GateDepth
end

local function overlapArea(x: number, z: number, halfX: number, halfZ: number, box: Box): number
    local gap = ThawPlacement.IceGap
    local dx = halfX + box.HalfX + gap - math.abs(x - box.X)
    local dz = halfZ + box.HalfZ + gap - math.abs(z - box.Z)
    if dx <= 0 or dz <= 0 then
        return 0
    end
    return dx * dz
end

-- Authoritative rule set. Returns (true) or (false, reason). Roaming creatures are never obstacles.
function ThawPlacement.Validate(penLevel: any, x: any, z: any, halfX: number, halfZ: number, occupied: { Box }): (boolean, string?)
    if not isFiniteNumber(x) or not isFiniteNumber(z) or not isFiniteNumber(halfX) or not isFiniteNumber(halfZ) then
        return false, "Invalid"
    end
    local xMin, xMax, zMin, zMax = ThawPlacement.GetInterior(penLevel)
    if ThawPlacement.IsOversize(penLevel, halfX, halfZ) then
        if x < xMin or x > xMax or z < ThawPlacement.GateDepth or z > zMax then
            return false, "OutsidePen"
        end
        return true
    end
    if x - halfX < xMin or x + halfX > xMax or z - halfZ < zMin or z + halfZ > zMax then
        return false, "OutsidePen"
    end
    if touchesGate(x, z, halfX, halfZ) and canClearGate(penLevel, halfX, halfZ) then
        return false, "GateArea"
    end
    for _, box in occupied do
        if not box.Oversize and overlapArea(x, z, halfX, halfZ, box) > 0 then
            return false, "Overlap"
        end
    end
    return true
end

-- Candidate X positions: centre first, then outward alternating, then the exact side limits (tight packing).
local function getCandidateXs(halfX: number, xMax: number): { number }
    local range = xMax - halfX
    local xs = { 0 }
    local step = ThawPlacement.ScanStep
    local offset = step
    while offset < range do
        table.insert(xs, offset)
        table.insert(xs, -offset)
        offset += step
    end
    if range > 0 then
        table.insert(xs, range)
        table.insert(xs, -range)
    end
    return xs
end

-- Deterministic fallback / reconstruction spot. Returns (x, z, fitsCleanly).
--  1. the first valid spot, scanning front-to-back and centre-outward, always inside the unlocked Pen;
--  2. when nothing valid is left, the in-Pen spot with the least overlap (Ice is compressed, never pushed through the
--     rear fence, the Snowfield or the wilderness, and never onto the gate);
--  3. oversize Ice takes a rear-biased showcase spot, staggered across lanes.
function ThawPlacement.FindFallback(penLevel: any, halfX: number, halfZ: number, occupied: { Box }): (number, number, boolean)
    local xMin, xMax, zMin, zMax = ThawPlacement.GetInterior(penLevel)
    if ThawPlacement.IsOversize(penLevel, halfX, halfZ) then
        local count = 0
        for _, box in occupied do
            if box.Oversize then
                count += 1
            end
        end
        -- Rear-biased showcase: the front edge stays behind the gate strip when possible, so the gate, banner and Hearth
        -- stay clear and any spill goes over the rear / side fence (like a giant creature), never forward.
        local lanes = { 0, -6, 6, -10, 10 }
        local x = math.clamp(lanes[count % #lanes + 1], xMin, xMax)
        local z = math.clamp(ThawPlacement.GateDepth + halfZ, ThawPlacement.GateDepth, zMax)
        return x, z, false
    end

    local xs = getCandidateXs(halfX, xMax)
    local step = ThawPlacement.ScanStep
    local zStart, zEnd = zMin + halfZ, zMax - halfZ
    local z = zStart
    while z <= zEnd + 1e-6 do
        for _, x in xs do
            if ThawPlacement.Validate(penLevel, x, z, halfX, halfZ, occupied) then
                return x, z, true
            end
        end
        z += step
    end

    -- Pen is full for this footprint: least-overlap in-Pen spot (deterministic: first minimum wins).
    local bestX, bestZ, bestCost = 0, math.max(zStart, zEnd), math.huge
    z = zStart
    while z <= zEnd + 1e-6 do
        for _, x in xs do
            if not (touchesGate(x, z, halfX, halfZ) and canClearGate(penLevel, halfX, halfZ)) then
                local cost = 0
                for _, box in occupied do
                    if not box.Oversize then
                        cost += overlapArea(x, z, halfX, halfZ, box)
                    end
                end
                if cost < bestCost then
                    bestX, bestZ, bestCost = x, z, cost
                end
            end
        end
        z += step
    end
    return bestX, bestZ, false
end

-- One-click snapping (F-D15-T05C1.2, client preview only; the server still runs Validate on the final spot): the valid
-- spot nearest to a pointer point, within maxRadius studs. Returns (x, z) or nil when nothing reasonable is valid.
-- Oversize Ice uses the same click: centre kept inside the Pen and, when possible, its front edge behind the front fence
-- so the spill goes rear / sideways instead of over the gate.
function ThawPlacement.FindNearest(
    penLevel: any,
    x: number,
    z: number,
    halfX: number,
    halfZ: number,
    occupied: { Box },
    maxRadius: number
): (number?, number?)
    local xMin, xMax, zMin, zMax = ThawPlacement.GetInterior(penLevel)
    if ThawPlacement.IsOversize(penLevel, halfX, halfZ) then
        local zFront = math.min(math.max(ThawPlacement.GateDepth, zMin + halfZ), zMax)
        return math.clamp(x, xMin, xMax), math.clamp(z, zFront, zMax)
    end
    local cx = if xMin + halfX <= xMax - halfX then math.clamp(x, xMin + halfX, xMax - halfX) else 0
    local cz = if zMin + halfZ <= zMax - halfZ then math.clamp(z, zMin + halfZ, zMax - halfZ) else (zMin + zMax) / 2
    if ThawPlacement.Validate(penLevel, cx, cz, halfX, halfZ, occupied) then
        return cx, cz
    end
    local step = 0.5
    local radius = step
    while radius <= maxRadius + 1e-6 do
        local count = math.max(8, math.floor(2 * math.pi * radius / step))
        local bestX, bestZ, bestDistance = nil, nil, math.huge
        for k = 0, count - 1 do
            local angle = k / count * 2 * math.pi
            local px, pz = cx + math.cos(angle) * radius, cz + math.sin(angle) * radius
            if ThawPlacement.Validate(penLevel, px, pz, halfX, halfZ, occupied) then
                local distance = (px - x) ^ 2 + (pz - z) ^ 2
                if distance < bestDistance then
                    bestX, bestZ, bestDistance = px, pz, distance
                end
            end
        end
        if bestX then
            return bestX, bestZ
        end
        radius += step
    end
    return nil, nil
end

return ThawPlacement
