local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WorldCycleConfig = require(shared:WaitForChild("WorldCycleConfig"))

export type Phase = "Day" | "GreatFrost"

export type WorldCycleState = {
    CurrentPhase: Phase,
    CycleIndex: number,
    PhaseStartedAtUnix: number,
    NextTransitionUnix: number,
    TimeRemaining: number,
}

local WorldCycleService = {}

local DAY_PHASE: Phase = "Day"
local GREAT_FROST_PHASE: Phase = "GreatFrost"
local DAY_DURATION = WorldCycleConfig.CycleLength - WorldCycleConfig.GreatFrostDuration

local hasStarted = false
-- Runtime only: a Frost transition is processed at most once and never retroactively on boot.
local lastProcessedFrostCycle: number? = nil
local phaseChanged = Instance.new("BindableEvent")

assert(WorldCycleConfig.CycleLength > 0, "WorldCycleConfig.CycleLength must be greater than zero")
assert(
    WorldCycleConfig.GreatFrostDuration > 0,
    "WorldCycleConfig.GreatFrostDuration must be greater than zero"
)
assert(
    DAY_DURATION > 0,
    "WorldCycleConfig.GreatFrostDuration must be shorter than WorldCycleConfig.CycleLength"
)

-- Every server derives the same rhythm from the shared wall-clock epoch.
local function computeState(nowUnix: number): WorldCycleState
    local cycleIndex = math.floor((nowUnix - WorldCycleConfig.CycleEpochUnix) / WorldCycleConfig.CycleLength)
    local cycleStartUnix = WorldCycleConfig.CycleEpochUnix + cycleIndex * WorldCycleConfig.CycleLength
    local frostStartUnix = cycleStartUnix + DAY_DURATION

    if nowUnix < frostStartUnix then
        return {
            CurrentPhase = DAY_PHASE,
            CycleIndex = cycleIndex,
            PhaseStartedAtUnix = cycleStartUnix,
            NextTransitionUnix = frostStartUnix,
            TimeRemaining = frostStartUnix - nowUnix,
        }
    end

    local nextCycleStartUnix = cycleStartUnix + WorldCycleConfig.CycleLength
    return {
        CurrentPhase = GREAT_FROST_PHASE,
        CycleIndex = cycleIndex,
        PhaseStartedAtUnix = frostStartUnix,
        NextTransitionUnix = nextCycleStartUnix,
        TimeRemaining = nextCycleStartUnix - nowUnix,
    }
end

local function runCycle(): ()
    local observedState = computeState(Workspace:GetServerTimeNow())

    while true do
        local timeRemaining = observedState.NextTransitionUnix - Workspace:GetServerTimeNow()
        if timeRemaining > 0 then
            task.wait(timeRemaining)
        end

        local nextState = computeState(Workspace:GetServerTimeNow())
        if nextState.CurrentPhase ~= observedState.CurrentPhase or nextState.CycleIndex ~= observedState.CycleIndex then
            observedState = nextState

            local isDuplicateFrost = nextState.CurrentPhase == GREAT_FROST_PHASE
                and lastProcessedFrostCycle == nextState.CycleIndex
            if not isDuplicateFrost then
                if nextState.CurrentPhase == GREAT_FROST_PHASE then
                    lastProcessedFrostCycle = nextState.CycleIndex
                end
                phaseChanged:Fire(nextState)
            end
        end
    end
end

-- Pure wall-clock read; valid before Start so other services can boot into the current phase.
function WorldCycleService.GetState(): WorldCycleState
    return computeState(Workspace:GetServerTimeNow())
end

-- Fires only for transitions this server observes while running, never for the phase it booted into.
function WorldCycleService.ConnectPhaseChanged(
    callback: (WorldCycleState) -> ()
): RBXScriptConnection
    return phaseChanged.Event:Connect(callback)
end

function WorldCycleService.Start(): ()
    if hasStarted then
        return
    end

    hasStarted = true
    task.spawn(runCycle)
end

return WorldCycleService
