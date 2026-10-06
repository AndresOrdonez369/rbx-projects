local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(shared:WaitForChild("GameConfig"))
local HearthConfig = require(shared:WaitForChild("HearthConfig"))
local WarmthConfig = require(shared:WaitForChild("WarmthConfig"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

export type ThawItem = {
    ThawID: string,
    PlayerUserID: number,
    IceType: string,
    CreatureID: string,
    Rarity: string,
    WeightMultiplier: number,
    IsResolving: boolean?,
    DepositedAtTime: number,
    BaseDurationSeconds: number,
    BonusProgressSeconds: number,
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

export type PlayerState = {
    Cash: number,
    CurrentWarmth: number,
    MaxWarmth: number,
    HearthLevel: number,
    CreatureCopies: { [string]: CreatureCopy },
    PenSlots: { [number]: string? },
    EquippedCreatureGUID: string?,
    CreatureVitality: number?,
    CreatureFrosted: boolean?,
    CurrentlyCarryingIceID: string?,
    ActiveThawItems: { [string]: ThawItem },
    ActiveRevealSession: RevealSession?,
    IsFrozen: boolean,
}

local PlayerStateService = {}

local DEFAULT_CASH = 0
local STARTING_HEARTH_LEVEL = HearthConfig[1].Level

local playerStates: { [Player]: PlayerState } = {}

assert(GameConfig.ActivePenCreatureSlots == 4, "The prototype must have exactly four active Pen creature slots")

local function createEmptyPenSlots(): { [number]: string? }
    -- The fixed 1..4 indices are always read explicitly. Empty slots are nil.
    return table.create(GameConfig.ActivePenCreatureSlots)
end

local function createInitialState(): PlayerState
    local maxWarmth = WarmthConfig.StartingMaxWarmth

    return {
        Cash = DEFAULT_CASH,
        CurrentWarmth = maxWarmth,
        MaxWarmth = maxWarmth,
        HearthLevel = STARTING_HEARTH_LEVEL,
        CreatureCopies = {},
        PenSlots = createEmptyPenSlots(),
        EquippedCreatureGUID = nil,
        CreatureVitality = nil,
        CreatureFrosted = nil,
        CurrentlyCarryingIceID = nil,
        ActiveThawItems = {},
        ActiveRevealSession = nil,
        IsFrozen = false,
    }
end

function PlayerStateService.CreateState(player: Player): PlayerState
    local existingState = playerStates[player]
    if existingState then
        return existingState
    end

    local state = createInitialState()
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
