local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent.PlayerStateService)

local OnboardingService = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

-- A player stays eligible for shared-Ice guidance until their first Ice reaches their Pen.
local function isEligible(state: PlayerStateService.PlayerState): boolean
    return next(state.CreatureCopies) == nil
        and next(state.ActiveThawItems) == nil
        and next(state.DiscoveredCreatures) == nil
end

function OnboardingService.SendOnboardingUpdate(player: Player): ()
    local state = PlayerStateService.GetState(player)
    if not state then
        return
    end

    gameplayEvent:FireClient(player, "OnboardingUpdated", {
        Active = isEligible(state),
    })
end

return OnboardingService
