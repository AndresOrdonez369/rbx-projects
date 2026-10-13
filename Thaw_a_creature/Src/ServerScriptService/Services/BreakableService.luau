local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SurvivalToolConfig = require(shared:WaitForChild("SurvivalToolConfig"))

local SurvivalToolService = require(script.Parent.SurvivalToolService)

-- Route obstacles cleared with the universal survival attack. They grant nothing and
-- are restored with the shared field at Great Frost.
local BreakableService = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local BREAKABLES_FOLDER_NAME = "Breakables"
local BREAKABLE_TYPE_ATTRIBUTE = "BreakableType"
local HITS_REMAINING_ATTRIBUTE = "HitsRemaining"
local IS_BROKEN_ATTRIBUTE = "IsBroken"

type PartState = {
    Part: BasePart,
    Transparency: number,
    CanCollide: boolean,
    CanQuery: boolean,
}

type BreakableRecord = {
    Target: Instance,
    HitsRequired: number,
    HitsRemaining: number,
    Parts: { PartState },
}

local records: { BreakableRecord } = {}
local hasStarted = false

local function setBroken(record: BreakableRecord, isBroken: boolean): ()
    for _, partState in record.Parts do
        partState.Part.Transparency = if isBroken then 1 else partState.Transparency
        partState.Part.CanCollide = if isBroken then false else partState.CanCollide
        partState.Part.CanQuery = if isBroken then false else partState.CanQuery
    end

    record.Target:SetAttribute(IS_BROKEN_ATTRIBUTE, isBroken)
end

local function handleHit(record: BreakableRecord, player: Player): boolean
    if record.HitsRemaining <= 0 then
        return false
    end

    -- Each accepted survival attack counts as one hit regardless of its Sprite damage value.
    record.HitsRemaining -= 1
    record.Target:SetAttribute(HITS_REMAINING_ATTRIBUTE, record.HitsRemaining)

    gameplayEvent:FireClient(player, "SurvivalFeedback", {
        Kind = "ToolHit",
        Target = record.Target,
    })

    if record.HitsRemaining <= 0 then
        setBroken(record, true)
        SurvivalToolService.UnregisterApprovedTarget(record.Target)
    end

    return true
end

local function restore(record: BreakableRecord): ()
    record.HitsRemaining = record.HitsRequired
    record.Target:SetAttribute(HITS_REMAINING_ATTRIBUTE, record.HitsRemaining)
    setBroken(record, false)

    SurvivalToolService.RegisterApprovedTarget(record.Target, function(player)
        return handleHit(record, player)
    end)
end

local function collectParts(target: Instance): { PartState }
    local parts = {}
    local candidates = if target:IsA("BasePart") then { target } else target:GetDescendants()

    for _, candidate in candidates do
        if candidate:IsA("BasePart") then
            table.insert(parts, {
                Part = candidate,
                Transparency = candidate.Transparency,
                CanCollide = candidate.CanCollide,
                CanQuery = candidate.CanQuery,
            })
        end
    end

    return parts
end

function BreakableService.ResetAll(): ()
    for _, record in records do
        restore(record)
    end
end

function BreakableService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    local folder = Workspace:FindFirstChild(BREAKABLES_FOLDER_NAME)
    if not folder then
        return
    end
    assert(folder:IsA("Folder"), string.format("Workspace.%s must be a Folder", BREAKABLES_FOLDER_NAME))

    for _, target in folder:GetChildren() do
        local breakableType = target:GetAttribute(BREAKABLE_TYPE_ATTRIBUTE)
        local hitsRequired = SurvivalToolConfig.BreakableHitsByType[breakableType]
        assert(
            type(hitsRequired) == "number" and hitsRequired >= 1 and hitsRequired % 1 == 0,
            string.format("%s must have a configured %s", target:GetFullName(), BREAKABLE_TYPE_ATTRIBUTE)
        )
        assert(target:IsA("BasePart") or target:IsA("Model"), string.format(
            "%s must be a BasePart or Model",
            target:GetFullName()
        ))

        local parts = collectParts(target)
        assert(#parts > 0, string.format("%s must contain at least one BasePart", target:GetFullName()))

        local record: BreakableRecord = {
            Target = target,
            HitsRequired = hitsRequired,
            HitsRemaining = hitsRequired,
            Parts = parts,
        }
        table.insert(records, record)
        restore(record)
    end
end

return BreakableService
