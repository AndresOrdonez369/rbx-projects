local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WorldCycleConfig = require(shared:WaitForChild("WorldCycleConfig"))

export type Phase = "Day" | "GreatFrost"

export type WorldCycleState = {
    CurrentPhase: Phase,
    PhaseStartedAtTime: number,
    PhaseEndsAtTime: number,
    CycleIndex: number,
}

local WorldCycleService = {}

local DAY_PHASE: Phase = "Day"
local GREAT_FROST_PHASE: Phase = "GreatFrost"
local DAY_DURATION = WorldCycleConfig.CycleLength - WorldCycleConfig.GreatFrostDuration

local hasStarted = false
local currentState: WorldCycleState? = nil
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

local function copyState(state: WorldCycleState): WorldCycleState
    return {
        CurrentPhase = state.CurrentPhase,
        PhaseStartedAtTime = state.PhaseStartedAtTime,
        PhaseEndsAtTime = state.PhaseEndsAtTime,
        CycleIndex = state.CycleIndex,
    }
end

local function setPhase(phase: Phase, cycleIndex: number, phaseStartedAtTime: number, duration: number): ()
    local state: WorldCycleState = {
        CurrentPhase = phase,
        PhaseStartedAtTime = phaseStartedAtTime,
        PhaseEndsAtTime = phaseStartedAtTime + duration,
        CycleIndex = cycleIndex,
    }
    currentState = state

    phaseChanged:Fire(copyState(state))
end

local function runCycle(): ()
    while true do
        local state = currentState
        assert(state, "WorldCycleService must have state while running")

        local timeRemaining = state.PhaseEndsAtTime - Workspace:GetServerTimeNow()
        if timeRemaining > 0 then
            task.wait(timeRemaining)
        end

        state = currentState
        assert(state, "WorldCycleService must have state while transitioning")

        if Workspace:GetServerTimeNow() >= state.PhaseEndsAtTime then
            if state.CurrentPhase == DAY_PHASE then
                setPhase(GREAT_FROST_PHASE, state.CycleIndex, state.PhaseEndsAtTime, WorldCycleConfig.GreatFrostDuration)
            else
                setPhase(DAY_PHASE, state.CycleIndex + 1, state.PhaseEndsAtTime, DAY_DURATION)
            end
        end
    end
end

function WorldCycleService.GetState(): WorldCycleState?
    local state = currentState
    if not state then
        return nil
    end

    return copyState(state)
end

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

    local startedAtTime = Workspace:GetServerTimeNow()
    setPhase(DAY_PHASE, 0, startedAtTime, DAY_DURATION)
    task.spawn(runCycle)
end

return WorldCycleService
