local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RegionConfig = require(shared:WaitForChild("RegionConfig"))

type RegionEntry = {
    RegionId: string,
    ColdMultiplier: number,
    Bounds: BasePart,
}

local RegionService = {}

local hasStarted = false
local regionEntries: { RegionEntry } = {}
local reportedOverlaps: { [string]: boolean } = {}

local function isPointInsideBounds(worldPosition: Vector3, bounds: BasePart): boolean
    local localPosition = bounds.CFrame:PointToObjectSpace(worldPosition)
    local halfSize = bounds.Size * 0.5

    return math.abs(localPosition.X) <= halfSize.X
        and math.abs(localPosition.Y) <= halfSize.Y
        and math.abs(localPosition.Z) <= halfSize.Z
end

local function reportOverlap(matches: { RegionEntry }, selectedRegionId: string): ()
    local regionIds: { string } = {}
    for _, entry in matches do
        table.insert(regionIds, entry.RegionId)
    end

    table.sort(regionIds)
    local overlapKey = table.concat(regionIds, "|")
    if reportedOverlaps[overlapKey] then
        return
    end
    reportedOverlaps[overlapKey] = true

    warn(string.format(
        "[D7-R07] RegionBounds overlap detected for %s; using higher-cold region %s",
        table.concat(regionIds, ", "),
        selectedRegionId
    ))
end

function RegionService.GetRegionAtPosition(worldPosition: Vector3): string?
    assert(hasStarted, "RegionService must be started before resolving positions")

    local matches: { RegionEntry } = {}
    for _, entry in regionEntries do
        if isPointInsideBounds(worldPosition, entry.Bounds) then
            table.insert(matches, entry)
        end
    end

    local selected = matches[1]
    if not selected then
        return nil
    end

    if #matches > 1 then
        reportOverlap(matches, selected.RegionId)
    end

    return selected.RegionId
end

function RegionService.Start(): ()
    if hasStarted then
        return
    end

    local progressionRegions = Workspace:WaitForChild("ProgressionRegions")
    assert(progressionRegions:IsA("Folder"), "Workspace.ProgressionRegions must be a Folder")

    for regionId, regionData in RegionConfig do
        local coldMultiplier = regionData.ColdMultiplier
        assert(
            type(coldMultiplier) == "number" and coldMultiplier > 0,
            string.format("RegionConfig.%s.ColdMultiplier must be a positive number", regionId)
        )

        local regionFolder = progressionRegions:WaitForChild(regionId)
        local bounds = regionFolder:WaitForChild("RegionBounds")
        assert(
            regionFolder:IsA("Folder"),
            string.format("Workspace.ProgressionRegions.%s must be a Folder", regionId)
        )
        assert(
            bounds:IsA("BasePart"),
            string.format("Workspace.ProgressionRegions.%s.RegionBounds must be a BasePart", regionId)
        )

        table.insert(regionEntries, {
            RegionId = regionId,
            ColdMultiplier = coldMultiplier,
            Bounds = bounds,
        })
    end

    table.sort(regionEntries, function(left: RegionEntry, right: RegionEntry): boolean
        if left.ColdMultiplier == right.ColdMultiplier then
            return left.RegionId < right.RegionId
        end

        return left.ColdMultiplier > right.ColdMultiplier
    end)

    hasStarted = true
end

return RegionService
