-- Pen Level sets only the active earning/display creature capacity and the Pen presentation size.
-- Thawing never depends on the Pen: it stays logically unlimited.
-- Width/Depth are presentation footprints in studs from the base's PenOrigin (Depth runs along its
-- local +Z, away from the lobby); they are not gameplay hitboxes.
-- UpgradeCost is the Cash price to reach that level (design-locked F-D15-T05C); Level 1 is the free start.
local MAX_SLOTS = 10

local LEVELS = {
    { Level = 1, Capacity = 4, Depth = 24, UpgradeCost = 0 },
    { Level = 2, Capacity = 5, Depth = 28, UpgradeCost = 150000 },
    { Level = 3, Capacity = 6, Depth = 32, UpgradeCost = 2500000 },
    { Level = 4, Capacity = 7, Depth = 36, UpgradeCost = 10000000 },
    { Level = 5, Capacity = 8, Depth = 40, UpgradeCost = 40000000 },
    { Level = 6, Capacity = 9, Depth = 44, UpgradeCost = 150000000 },
    { Level = 7, Capacity = 10, Depth = 48, UpgradeCost = 750000000 },
}

local function isValidLevel(penLevel: any): boolean
    return type(penLevel) == "number" and penLevel % 1 == 0 and LEVELS[penLevel] ~= nil
end

local function getCapacity(penLevel: number): number
    assert(isValidLevel(penLevel), string.format("Unsupported PenLevel %s", tostring(penLevel)))
    return LEVELS[penLevel].Capacity
end

for index, levelConfig in LEVELS do
    assert(levelConfig.Level == index, string.format("PenConfig level %d must identify itself", index))
    assert(levelConfig.Capacity <= MAX_SLOTS, string.format("PenConfig level %d exceeds %d slots", index, MAX_SLOTS))
end
assert(LEVELS[#LEVELS].Capacity == MAX_SLOTS, "The highest Pen level must unlock every slot")

local PenConfig = {
    Width = 32,
    MaxSlots = MAX_SLOTS,
    MaxLevel = #LEVELS,
    UpgradeRequestMinInterval = 0.50,
    Levels = LEVELS,
    IsValidLevel = isValidLevel,
    GetCapacity = getCapacity,
}

return PenConfig
