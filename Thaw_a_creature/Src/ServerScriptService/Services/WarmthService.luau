local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local HearthConfig = require(shared:WaitForChild("HearthConfig"))
local RegionConfig = require(shared:WaitForChild("RegionConfig"))
local WarmthConfig = require(shared:WaitForChild("WarmthConfig"))

local CreatureService = require(script.Parent.CreatureService)
local IceService = require(script.Parent.IceService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RegionService = require(script.Parent.RegionService)

local WarmthService = {}

local PRESENTATION_UPDATE_INTERVAL = 0.25

local warmZone: BasePart? = nil
local homeSpawn: SpawnLocation? = nil
local updateConnection: RBXScriptConnection? = nil
local presentationUpdateElapsed = 0
local warmZonePresenceByPlayer: { [Player]: { Character: Model, IsInside: boolean } } = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local function getPrototypeBasePart(name: string): BasePart
    local prototypeBase = Workspace:WaitForChild("PrototypeBase")
    local part = prototypeBase:WaitForChild(name)

    assert(part:IsA("BasePart"), string.format("Workspace.PrototypeBase.%s must be a BasePart", name))

    return part
end

local function getHomeSpawn(): SpawnLocation
    local spawn = getPrototypeBasePart("SpawnLocation")

    assert(spawn:IsA("SpawnLocation"), "Workspace.PrototypeBase.SpawnLocation must be a SpawnLocation")

    return spawn
end

local function isCharacterInsideWarmZone(character: Model, zone: BasePart): boolean?
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return nil
    end

    local localPosition = zone.CFrame:PointToObjectSpace(rootPart.Position)
    local halfSize = zone.Size * 0.5

    return math.abs(localPosition.X) <= halfSize.X
        and math.abs(localPosition.Z) <= halfSize.Z
end

local function freezeAndReturnHome(
    player: Player,
    character: Model,
    state: PlayerStateService.PlayerState,
    spawn: SpawnLocation
)
    if state.IsFrozen then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return
    end

    state.IsFrozen = true
    IceService.DiscardCarriedIce(player)

    local verticalOffset = spawn.Size.Y * 0.5 + humanoid.HipHeight + rootPart.Size.Y * 0.5
    character:PivotTo(spawn.CFrame * CFrame.new(0, verticalOffset, 0))
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    state.CurrentWarmth = state.MaxWarmth
    state.IsFrozen = false
end

local function sendWarmthUpdate(player: Player, state: PlayerStateService.PlayerState)
    gameplayEvent:FireClient(player, "WarmthUpdated", {
        CurrentWarmth = state.CurrentWarmth,
        MaxWarmth = state.MaxWarmth,
    })
end

local function updateWarmth(deltaTime: number)
    local zone = warmZone
    local spawn = homeSpawn
    if not zone or not spawn then
        return
    end

    for _, player in Players:GetPlayers() do
        local state = PlayerStateService.GetState(player)
        local character = player.Character

        if state and character then
            local isInside = isCharacterInsideWarmZone(character, zone)
            if not state.IsFrozen and isInside ~= nil then
                local previousPresence = warmZonePresenceByPlayer[player]
                local enteredWarmZone = isInside
                    and (not previousPresence
                        or previousPresence.Character ~= character
                        or not previousPresence.IsInside)
                warmZonePresenceByPlayer[player] = {
                    Character = character,
                    IsInside = isInside,
                }

                if isInside then
                    if enteredWarmZone then
                        CreatureService.RecoverEquippedCreatureAtHearth(player)
                    end

                    local hearthLevelConfig = HearthConfig[state.HearthLevel]
                    assert(hearthLevelConfig, string.format("Missing HearthConfig for level %d", state.HearthLevel))

                    state.MaxWarmth += hearthLevelConfig.WarmthTrainingRate * deltaTime
                    local currentWarmthRefillPerSecond = state.MaxWarmth
                        * WarmthConfig.RefillFractionOfMaxWarmthPerSecond
                    state.CurrentWarmth = math.min(
                        state.CurrentWarmth + currentWarmthRefillPerSecond * deltaTime,
                        state.MaxWarmth
                    )
                else
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    assert(rootPart and rootPart:IsA("BasePart"), "Validated character must have a HumanoidRootPart")

                    local regionId = RegionService.GetRegionAtPosition(rootPart.Position)
                    local regionColdMultiplier = if regionId then RegionConfig[regionId].ColdMultiplier else 1
                    local isCarrying = state.CurrentlyCarryingIceID ~= nil
                    local carryMultiplier = if isCarrying
                        then WarmthConfig.CarryDrainMultiplier
                        else 1
                    local drainPerSecond = WarmthConfig.NormalDrainRate
                        * regionColdMultiplier
                        * carryMultiplier

                    state.CurrentWarmth = math.max(
                        state.CurrentWarmth - drainPerSecond * deltaTime,
                        0
                    )

                    if state.CurrentWarmth <= WarmthConfig.FrozenThreshold then
                        freezeAndReturnHome(player, character, state, spawn)
                    end
                end
            end
        end
    end

    presentationUpdateElapsed += deltaTime
    if presentationUpdateElapsed >= PRESENTATION_UPDATE_INTERVAL then
        presentationUpdateElapsed %= PRESENTATION_UPDATE_INTERVAL

        for _, player in Players:GetPlayers() do
            local state = PlayerStateService.GetState(player)
            if state then
                sendWarmthUpdate(player, state)
            end
        end
    end
end

function WarmthService.SendWarmthUpdate(player: Player)
    local state = PlayerStateService.GetState(player)
    if state then
        sendWarmthUpdate(player, state)
    end
end

function WarmthService.ApplyDamage(player: Player, amount: number): (boolean, number?, number?)
    if type(amount) ~= "number" or amount <= 0 then
        return false, nil, nil
    end

    local state = PlayerStateService.GetState(player)
    local character = player.Character
    local spawn = homeSpawn
    if not state or state.IsFrozen or not character or not spawn then
        return false, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return false, nil, nil
    end

    local warmthBefore = state.CurrentWarmth
    state.CurrentWarmth = math.max(warmthBefore - amount, 0)
    local warmthAfterDamage = state.CurrentWarmth

    if state.CurrentWarmth <= WarmthConfig.FrozenThreshold then
        freezeAndReturnHome(player, character, state, spawn)
    end

    sendWarmthUpdate(player, state)
    return true, warmthBefore, warmthAfterDamage
end

function WarmthService.Start()
    if updateConnection then
        return
    end

    warmZone = getPrototypeBasePart("WarmZone")
    homeSpawn = getHomeSpawn()
    Players.PlayerRemoving:Connect(function(player)
        warmZonePresenceByPlayer[player] = nil
    end)
    updateConnection = RunService.Heartbeat:Connect(updateWarmth)
end

return WarmthService
