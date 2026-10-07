local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureSurvivalConfig = require(shared:WaitForChild("CreatureSurvivalConfig"))
local GameConfig = require(shared:WaitForChild("GameConfig"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

export type ThawItem = {
    ThawID: string,
    PlayerUserID: number,
    IceType: string,
    IsSpecial: boolean,
    CreatureID: string,
    Rarity: string,
    WeightMultiplier: number,
    IsResolving: boolean?,
    DepositedAtTime: number,
    BaseDurationSeconds: number,
    BonusProgressSeconds: number,
    -- Set when restored from saved data: Great Frost only accelerates time the owner was present for.
    PresentSinceTime: number?,
}

export type RevealSession = {
    SessionID: string,
    PlayerUserID: number,
    ThawID: string,
    CurrentHit: number,
    RequiredHits: number,
    LastHitTime: number?,
}

export type CreatureCopy = {
    CreatureID: string,
    WeightMultiplier: number,
}

export type PersistentThawRecord = {
    ThawID: string,
    IceType: string,
    IsSpecial: boolean,
    CreatureID: string,
    Rarity: string,
    WeightMultiplier: number,
    DepositedAtUnix: number,
    BaseDurationSeconds: number,
    BonusProgressSeconds: number,
}

export type PersistentData = {
    DataVersion: number,
    Cash: number,
    MaxWarmth: number,
    HearthLevel: number,
    CreatureCopies: { [string]: CreatureCopy },
    PenSlots: { [number]: string? },
    EquippedCreatureGUID: string?,
    DiscoveredCreatures: { [string]: boolean },
    ThawingIce: { PersistentThawRecord },
}

export type PlayerState = {
    Cash: number,
    CurrentWarmth: number,
    MaxWarmth: number,
    HearthLevel: number,
    CreatureCopies: { [string]: CreatureCopy },
    PenSlots: { [number]: string? },
    EquippedCreatureGUID: string?,
    DiscoveredCreatures: { [string]: boolean },
    CreatureVitality: number?,
    CreatureFrosted: boolean?,
    CurrentlyCarryingIceID: string?,
    ActiveThawItems: { [string]: ThawItem },
    ActiveRevealSession: RevealSession?,
    IsFrozen: boolean,
}

local PlayerStateService = {}

local playerStates: { [Player]: PlayerState } = {}

assert(GameConfig.ActivePenCreatureSlots == 4, "The prototype must have exactly four active Pen creature slots")

local function createEmptyPenSlots(): { [number]: string? }
    -- The fixed 1..4 indices are always read explicitly. Empty slots are nil.
    return table.create(GameConfig.ActivePenCreatureSlots)
end

local function createStateFromPersistentData(player: Player, data: PersistentData): PlayerState
    local restoredAtTime = Workspace:GetServerTimeNow()

    local creatureCopies = {}
    for creatureGUID, copy in data.CreatureCopies do
        creatureCopies[creatureGUID] = {
            CreatureID = copy.CreatureID,
            WeightMultiplier = copy.WeightMultiplier,
        }
    end

    local penSlots = createEmptyPenSlots()
    for slotIndex = 1, GameConfig.ActivePenCreatureSlots do
        penSlots[slotIndex] = data.PenSlots[slotIndex]
    end

    local activeThawItems = {}
    for _, record in data.ThawingIce do
        activeThawItems[record.ThawID] = {
            ThawID = record.ThawID,
            PlayerUserID = player.UserId,
            IceType = record.IceType,
            IsSpecial = record.IsSpecial,
            CreatureID = record.CreatureID,
            Rarity = record.Rarity,
            WeightMultiplier = record.WeightMultiplier,
            DepositedAtTime = record.DepositedAtUnix,
            BaseDurationSeconds = record.BaseDurationSeconds,
            BonusProgressSeconds = record.BonusProgressSeconds,
            PresentSinceTime = restoredAtTime,
        }
    end

    local hasEquippedCreature = data.EquippedCreatureGUID ~= nil

    return {
        Cash = data.Cash,
        CurrentWarmth = data.MaxWarmth,
        MaxWarmth = data.MaxWarmth,
        HearthLevel = data.HearthLevel,
        CreatureCopies = creatureCopies,
        PenSlots = penSlots,
        EquippedCreatureGUID = data.EquippedCreatureGUID,
        DiscoveredCreatures = table.clone(data.DiscoveredCreatures),
        CreatureVitality = if hasEquippedCreature then CreatureSurvivalConfig.CreatureVitalityMax else nil,
        CreatureFrosted = if hasEquippedCreature then false else nil,
        CurrentlyCarryingIceID = nil,
        ActiveThawItems = activeThawItems,
        ActiveRevealSession = nil,
        IsFrozen = false,
    }
end

function PlayerStateService.CreateState(player: Player, data: PersistentData): PlayerState
    local existingState = playerStates[player]
    if existingState then
        return existingState
    end

    local state = createStateFromPersistentData(player, data)
    playerStates[player] = state

    return state
end

function PlayerStateService.GetState(player: Player): PlayerState?
    return playerStates[player]
end

function PlayerStateService.GetCash(player: Player): number?
    local state = playerStates[player]
    return if state then state.Cash else nil
end

function PlayerStateService.SendCashUpdate(player: Player): boolean
    local cash = PlayerStateService.GetCash(player)
    if cash == nil then
        return false
    end

    gameplayEvent:FireClient(player, "CashUpdated", {
        Cash = cash,
    })

    return true
end

function PlayerStateService.AddCash(player: Player, amount: number): (boolean, number?)
    if type(amount) ~= "number"
        or amount <= 0
        or amount >= math.huge
        or amount % 1 ~= 0
    then
        return false, nil
    end

    local state = playerStates[player]
    if not state then
        return false, nil
    end

    local nextCash = state.Cash + amount
    if nextCash >= math.huge then
        return false, nil
    end

    state.Cash = nextCash
    PlayerStateService.SendCashUpdate(player)

    return true, nextCash
end

function PlayerStateService.TrySpendCash(player: Player, amount: number): (boolean, number?)
    if type(amount) ~= "number"
        or amount <= 0
        or amount >= math.huge
        or amount % 1 ~= 0
    then
        return false, nil
    end

    local state = playerStates[player]
    if not state
        or type(state.Cash) ~= "number"
        or state.Cash < amount
        or state.Cash >= math.huge
        or state.Cash % 1 ~= 0
    then
        return false, nil
    end

    state.Cash -= amount
    PlayerStateService.SendCashUpdate(player)

    return true, state.Cash
end

function PlayerStateService.RemoveState(player: Player): ()
    playerStates[player] = nil
end

return PlayerStateService
