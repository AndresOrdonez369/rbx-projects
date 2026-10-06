local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GuardedIceConfig = require(shared:WaitForChild("GuardedIceConfig"))

local FrostSpriteService = require(script.Parent.FrostSpriteService)
local IceService = require(script.Parent.IceService)

local GuardedIceService = {}

local guardians = {}
local hasStarted = false

local function getGuardianMarkers(profile): { BasePart }
    local iceSpawnPoints = Workspace:WaitForChild("IceSpawnPoints")
    local typeFolder = iceSpawnPoints:WaitForChild(profile.IceType)
    local spawnMarker = typeFolder:WaitForChild(profile.SpawnMarkerName)

    assert(typeFolder:IsA("Folder"), string.format("Ice spawn type %s must be a Folder", profile.IceType))
    assert(spawnMarker:IsA("BasePart"), string.format(
        "Guarded Ice spawn marker %s/%s must be a BasePart",
        profile.IceType,
        profile.SpawnMarkerName
    ))

    local guardianFolder = spawnMarker:WaitForChild(GuardedIceConfig.GuardianMarkerFolderName)
    assert(guardianFolder:IsA("Folder"), string.format(
        "Guarded Ice spawn marker %s/%s must contain a %s Folder",
        profile.IceType,
        profile.SpawnMarkerName,
        GuardedIceConfig.GuardianMarkerFolderName
    ))

    local markers = {}
    for _, child in guardianFolder:GetChildren() do
        if child:IsA("BasePart") then
            table.insert(markers, child)
        end
    end

    table.sort(markers, function(left, right)
        return left.Name < right.Name
    end)

    assert(#markers == profile.GuardianCount, string.format(
        "Guarded Ice profile %s expected %d guardian markers, got %d",
        profile.ProfileName,
        profile.GuardianCount,
        #markers
    ))

    return markers
end

function GuardedIceService.Clear(): ()
    for _, guardian in guardians do
        FrostSpriteService.Destroy(guardian)
    end

    table.clear(guardians)
end

function GuardedIceService.Rebuild(): ()
    assert(#guardians == 0, "Guarded Ice guardians must be cleared before rebuilding")

    local activeSpawnPointIDs = IceService.GetActiveAvailableSpawnPointIDs()

    for spawnPointID, profile in GuardedIceConfig.ProfilesBySpawnPointID do
        assert(spawnPointID == string.format("%s/%s", profile.IceType, profile.SpawnMarkerName), string.format(
            "Guarded Ice profile %s does not match SpawnPointID %s",
            profile.ProfileName,
            spawnPointID
        ))

        if not activeSpawnPointIDs[spawnPointID] then
            continue
        end

        local markers = getGuardianMarkers(profile)
        for _, marker in markers do
            local guardian = FrostSpriteService.Spawn(
                marker.CFrame,
                spawnPointID,
                profile.ProfileName,
                marker.Name
            )
            table.insert(guardians, guardian)
        end
    end
end

function GuardedIceService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    for _, profile in GuardedIceConfig.ProfilesBySpawnPointID do
        getGuardianMarkers(profile)
    end

    GuardedIceService.Clear()
    GuardedIceService.Rebuild()
end

return GuardedIceService
