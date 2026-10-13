local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(shared:WaitForChild("GameConfig"))
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

local hasStarted = false
local bases: { Base } = {}
local baseByPlayer: { [Player]: Base } = {}

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
end

function BaseService.Start(): ()
    if hasStarted then
        return
    end

    local basesFolder = getChild(Workspace, BASES_FOLDER_NAME, "Folder")

    local index = 1
    while true do
        local folder = basesFolder:FindFirstChild(BASE_NAME_PREFIX .. index)
        if not folder then
            break
        end
        assert(folder:IsA("Folder"), string.format("%s must be a Folder", folder:GetFullName()))

        folder:SetAttribute(OWNER_USER_ID_ATTRIBUTE, nil)
        folder:SetAttribute(PEN_LEVEL_ATTRIBUTE, nil)
        table.insert(bases, loadBase(folder, index))
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
