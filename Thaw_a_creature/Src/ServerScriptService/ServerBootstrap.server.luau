local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent.Services.BaseService)
local BreakableService = require(script.Parent.Services.BreakableService)
local CreatureService = require(script.Parent.Services.CreatureService)
local CreatureRevealService = require(script.Parent.Services.CreatureRevealService)
local DataService = require(script.Parent.Services.DataService)
local FrostSpriteService = require(script.Parent.Services.FrostSpriteService)
local GuardedIceService = require(script.Parent.Services.GuardedIceService)
local HearthService = require(script.Parent.Services.HearthService)
local IceService = require(script.Parent.Services.IceService)
local OnboardingService = require(script.Parent.Services.OnboardingService)
local PenService = require(script.Parent.Services.PenService)
local PlayerStateService = require(script.Parent.Services.PlayerStateService)
local RegionService = require(script.Parent.Services.RegionService)
local SurvivalToolService = require(script.Parent.Services.SurvivalToolService)
local ThawService = require(script.Parent.Services.ThawService)
local WarmthService = require(script.Parent.Services.WarmthService)
local WorldCycleService = require(script.Parent.Services.WorldCycleService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

-- Carrier Commitment (L-D14.5-T04): while carrying Ice, only these gameplay requests are accepted. Movement and jump
-- are not requests. Everything else (survival attacks, Grab, creature management, Sell, upgrades, reveal) is rejected.
local CARRIER_ALLOWED_ACTIONS = {
    DepositCarriedIce = true,
    DropIce = true,
    RideEquippedCreature = true,
    UnrideEquippedCreature = true,
}

local servicesStarted = false
local clientReadyPlayers: { [Player]: boolean } = {}

local function getWorldCycleClientState(): { [string]: string | number }
    local state = WorldCycleService.GetState()

    return {
        CurrentPhase = state.CurrentPhase,
        CycleIndex = state.CycleIndex,
        NextTransitionUnix = state.NextTransitionUnix,
        TimeRemaining = state.TimeRemaining,
    }
end

local function sendWorldCycleUpdate(player: Player): ()
    gameplayEvent:FireClient(player, "WorldCycleUpdated", getWorldCycleClientState())
end

local function sendInitialState(player: Player): ()
    if not servicesStarted or not clientReadyPlayers[player] or not PlayerStateService.GetState(player) then
        return
    end

    clientReadyPlayers[player] = nil

    PlayerStateService.SendCashUpdate(player)
    HearthService.SendHearthUpdate(player)
    WarmthService.SendWarmthUpdate(player)
    CreatureService.SendEquippedCreatureUpdate(player)
    CreatureService.SendCreatureStateUpdate(player)
    sendWorldCycleUpdate(player)
    OnboardingService.SendOnboardingUpdate(player)
end

local function initializePlayer(player: Player): ()
    -- Assigned before the first character spawn so the player starts at their own plot.
    if not BaseService.AssignBase(player) then
        player:Kick("This server has no free base. Please join another server.")
        return
    end

    -- Gameplay that depends on persistent state stays unavailable until the profile is loaded.
    local persistentData = DataService.LoadAsync(player)
    if not persistentData or player.Parent ~= Players then
        return
    end

    PlayerStateService.CreateState(player, persistentData)
    BaseService.SetPenLevel(player, persistentData.PenLevel)
    BaseService.SetHearthLevel(player, persistentData.HearthLevel)

    -- Before services start, their Start() presents every player that already has state.
    if servicesStarted then
        CreatureService.RefreshPlayerPresentation(player)
        ThawService.RefreshPlayerVisuals(player)
    end

    sendInitialState(player)
end

BaseService.Start()
DataService.Start()

Players.PlayerAdded:Connect(initializePlayer)

for _, player in Players:GetPlayers() do
    task.spawn(initializePlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
    clientReadyPlayers[player] = nil
    DataService.Release(player)
    PlayerStateService.RemoveState(player)
    -- Deferred so every service's own PlayerRemoving cleanup still sees the assigned plot.
    task.defer(BaseService.ReleaseBase, player)
end)

gameplayRequest.OnServerEvent:Connect(function(player, action, ...)
    if action == "ClientReady" then
        clientReadyPlayers[player] = true
        sendInitialState(player)
        return
    end

    if not servicesStarted then
        return
    end

    if IceService.IsCarryingIce(player) and not CARRIER_ALLOWED_ACTIONS[action] then
        return
    end

    if action == "GrabIce" then
        IceService.TryGrabIce(player, ...)
        return
    end

    if action == "DepositCarriedIce" then
        local deposited, rejectReason = IceService.TryDepositCarriedIce(player, ...)
        -- Feedback for the placement ghost (F-D15-T05C1); the server decision is already final.
        gameplayEvent:FireClient(player, "ThawPlacementResult", {
            Accepted = deposited == true,
            Reason = if deposited then nil else (rejectReason or "Rejected"),
        })
        if deposited then
            OnboardingService.SendOnboardingUpdate(player)
        end
        return
    end

    if action == "DropIce" then
        IceService.TryDropIce(player, ...)
        return
    end

    if action == "BeginReveal" then
        ThawService.TryBeginReveal(player, ...)
        return
    end

    if action == "Crack" then
        ThawService.TryCrack(player, ...)
        return
    end

    if action == "PlaceInPen" then
        CreatureService.TryPlaceInPen(player, ...)
        return
    end

    if action == "RemoveFromPen" then
        CreatureService.TryRemoveFromPen(player, ...)
        return
    end

    if action == "SellCreature" then
        CreatureService.TrySellCreature(player, ...)
        return
    end

    if action == "EquipCreature" then
        CreatureService.TryEquipCreature(player, ...)
        return
    end

    if action == "UnequipCreature" then
        CreatureService.TryUnequipCreature(player, ...)
        return
    end

    if action == "RideEquippedCreature" then
        CreatureService.TryRideEquippedCreature(player, ...)
        return
    end

    if action == "UnrideEquippedCreature" then
        CreatureService.TryUnrideEquippedCreature(player, ...)
        return
    end

    if action == "SwingSurvivalTool" then
        SurvivalToolService.TrySwing(player, ...)
        return
    end

    if action == "UpgradeHearth" then
        HearthService.TryUpgrade(player, ...)
        return
    end

    if action == "UpgradePen" then
        PenService.TryUpgrade(player, ...)
        return
    end
end)

WorldCycleService.ConnectPhaseChanged(function(worldCycleState)
    local fieldRefreshed = IceService.HandleWorldCyclePhaseChanged(
        worldCycleState.CurrentPhase,
        worldCycleState.CycleIndex
    )

    -- Guardians and route obstacles belong to the field: rebuild them whenever a new field was populated.
    if fieldRefreshed then
        GuardedIceService.Clear()
        GuardedIceService.Rebuild()
        BreakableService.ResetAll()
    end

    ThawService.HandleWorldCyclePhaseChanged(worldCycleState.CurrentPhase, worldCycleState.CycleIndex)

    gameplayEvent:FireAllClients("WorldCycleUpdated", getWorldCycleClientState())
end)

CreatureRevealService.Start()
CreatureService.Start()
HearthService.Start()
PenService.Start()
ThawService.Start()
IceService.Start()
RegionService.Start()
WarmthService.Start()
SurvivalToolService.Start()
BreakableService.Start()
FrostSpriteService.Start()
GuardedIceService.Start()
WorldCycleService.Start()

servicesStarted = true

for player in clientReadyPlayers do
    sendInitialState(player)
end
