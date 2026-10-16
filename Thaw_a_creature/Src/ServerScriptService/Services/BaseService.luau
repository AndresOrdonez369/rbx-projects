local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(shared:WaitForChild("GameConfig"))
local HearthConfig = require(shared:WaitForChild("HearthConfig"))
local PenConfig = require(shared:WaitForChild("PenConfig"))

export type Base = {
    Index: number,
    Folder: Folder,
    SpawnLocation: SpawnLocation,
    WarmZone: BasePart,
    HomeGround: BasePart,
    Hearth: Model,
    HearthBase: BasePart,
    Pen: Model,
    PenFloor: BasePart,
    -- Presentation origin: front-center of the Pen, local +Z pointing away from the lobby.
    PenOrigin: BasePart,
    PenSlotPositions: { BasePart },
    -- Thaw display origin: front-center of the thaw grid, which grows along its local +Z.
    ThawArea: BasePart,
    ThawVisuals: Folder,
}

local BaseService = {}

local BASES_FOLDER_NAME = "Bases"
local BASE_NAME_PREFIX = "Base"
-- Replicated so clients can find their own plot; gameplay authority stays in this service.
local OWNER_USER_ID_ATTRIBUTE = "OwnerUserId"
-- Replicated so every client can present each visible Pen at its owner's level.
local PEN_LEVEL_ATTRIBUTE = "PenLevel"
-- Read-only presentation state on the Hearth model so every client can show each owner's real Hearth tier.
-- Gameplay (training, upgrades) reads PlayerState only; clients never write it back.
local HEARTH_LEVEL_ATTRIBUTE = "HearthLevel"
-- Authored shared Home Camp / Lobby volume (L-D14.5-T01). Server-readable only: never collides or queries.
local HOME_SAFE_ZONE_NAME = "HomeCampSafeZone"

local hasStarted = false
local bases: { Base } = {}
local baseByPlayer: { [Player]: Base } = {}
local homeSafeZone: BasePart? = nil

local function getChild(parent: Instance, name: string, className: string): any
    local child = parent:WaitForChild(name)
    assert(child:IsA(className), string.format("%s.%s must be a %s", parent:GetFullName(), name, className))

    return child
end

local function loadBase(folder: Folder, index: number): Base
    local hearth = getChild(folder, "Hearth", "Model")
    local pen = getChild(folder, "Pen", "Model")
    local positionFolder = getChild(pen, "CreaturePositions", "Folder")

    local penSlotPositions = {}
    for slotIndex = 1, PenConfig.MaxSlots do
        penSlotPositions[slotIndex] = getChild(positionFolder, "Slot" .. slotIndex, "BasePart")
    end
    assert(
        #positionFolder:GetChildren() == PenConfig.MaxSlots,
        string.format("%s must have exactly %d creature positions", positionFolder:GetFullName(), PenConfig.MaxSlots)
    )

    return {
        Index = index,
        Folder = folder,
        SpawnLocation = getChild(folder, "SpawnLocation", "SpawnLocation"),
        WarmZone = getChild(folder, "WarmZone", "BasePart"),
        HomeGround = getChild(folder, "HomeGround", "BasePart"),
        Hearth = hearth,
        HearthBase = getChild(hearth, "HearthBase", "BasePart"),
        Pen = pen,
        PenFloor = getChild(pen, "PenFloor", "BasePart"),
        PenOrigin = getChild(pen, "PenOrigin", "BasePart"),
        PenSlotPositions = penSlotPositions,
        ThawArea = getChild(folder, "ThawArea", "BasePart"),
        ThawVisuals = getChild(folder, "ThawVisuals", "Folder"),
    }
end

function BaseService.GetBases(): { Base }
    assert(hasStarted, "BaseService must be started before reading bases")
    return bases
end

function BaseService.GetBase(player: Player): Base?
    return baseByPlayer[player]
end

function BaseService.SetPenLevel(player: Player, penLevel: number): ()
    local base = baseByPlayer[player]
    assert(PenConfig.IsValidLevel(penLevel), string.format("Unsupported PenLevel %s", tostring(penLevel)))
    if base then
        base.Folder:SetAttribute(PEN_LEVEL_ATTRIBUTE, penLevel)
    end
end

function BaseService.SetHearthLevel(player: Player, hearthLevel: number): ()
    local base = baseByPlayer[player]
    local levelConfig = HearthConfig[hearthLevel]
    assert(
        levelConfig ~= nil and levelConfig.Level == hearthLevel,
        string.format("Unsupported HearthLevel %s", tostring(hearthLevel))
    )
    if base then
        base.Hearth:SetAttribute(HEARTH_LEVEL_ATTRIBUTE, hearthLevel)
    end
end

-- The single authoritative Home Camp / Lobby membership test. Warmth safety uses it now; player-contest
-- immunity must reuse it rather than re-deriving geometry. Inclusive point-in-volume, server positions only.
function BaseService.IsPositionInsideHomeSafeZone(worldPosition: Vector3): boolean
    local zone = homeSafeZone
    assert(zone, "BaseService must be started before testing Home Safe Zone membership")

    local localPosition = zone.CFrame:PointToObjectSpace(worldPosition)
    local halfSize = zone.Size * 0.5

    return math.abs(localPosition.X) <= halfSize.X
        and math.abs(localPosition.Y) <= halfSize.Y
        and math.abs(localPosition.Z) <= halfSize.Z
end

-- Uses the player's authoritative HumanoidRootPart (also the rider's root while Riding). No character = outside.
function BaseService.IsPlayerInsideHomeSafeZone(player: Player): boolean
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not rootPart:IsA("BasePart") then
        return false
    end

    return BaseService.IsPositionInsideHomeSafeZone(rootPart.Position)
end

-- Assigns the first free plot. Returns nil when every plot is taken.
function BaseService.AssignBase(player: Player): Base?
    assert(hasStarted, "BaseService must be started before assigning bases")

    local existingBase = baseByPlayer[player]
    if existingBase then
        return existingBase
    end

    for _, base in bases do
        if base.Folder:GetAttribute(OWNER_USER_ID_ATTRIBUTE) == nil then
            base.Folder:SetAttribute(OWNER_USER_ID_ATTRIBUTE, player.UserId)
            baseByPlayer[player] = base
            player.RespawnLocation = base.SpawnLocation
            return base
        end
    end

    return nil
end

function BaseService.ReleaseBase(player: Player): ()
    local base = baseByPlayer[player]
    if not base then
        return
    end

    baseByPlayer[player] = nil
    base.Folder:SetAttribute(OWNER_USER_ID_ATTRIBUTE, nil)
    base.Folder:SetAttribute(PEN_LEVEL_ATTRIBUTE, nil)
    base.Hearth:SetAttribute(HEARTH_LEVEL_ATTRIBUTE, nil)
end

function BaseService.Start(): ()
    if hasStarted then
        return
    end

    local basesFolder = getChild(Workspace, BASES_FOLDER_NAME, "Folder")
    homeSafeZone = getChild(Workspace, HOME_SAFE_ZONE_NAME, "BasePart")

    local index = 1
    while true do
        local folder = basesFolder:FindFirstChild(BASE_NAME_PREFIX .. index)
        if not folder then
            break
        end
        assert(folder:IsA("Folder"), string.format("%s must be a Folder", folder:GetFullName()))

        folder:SetAttribute(OWNER_USER_ID_ATTRIBUTE, nil)
        folder:SetAttribute(PEN_LEVEL_ATTRIBUTE, nil)
        local base = loadBase(folder, index)
        base.Hearth:SetAttribute(HEARTH_LEVEL_ATTRIBUTE, nil)
        table.insert(bases, base)
        index += 1
    end

    assert(
        #bases >= GameConfig.MaxPlayers,
        string.format("Workspace.%s must contain at least %d bases", BASES_FOLDER_NAME, GameConfig.MaxPlayers)
    )
    if Players.MaxPlayers > #bases then
        warn(string.format(
            "[BaseService] Server size %d exceeds %d bases; extra players will be refused",
            Players.MaxPlayers,
            #bases
        ))
    end

    hasStarted = true
end

return BaseService
