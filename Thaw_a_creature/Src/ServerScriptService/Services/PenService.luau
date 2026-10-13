local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(shared:WaitForChild("GameConfig"))
local PenConfig = require(shared:WaitForChild("PenConfig"))

local BaseService = require(script.Parent.BaseService)
local CreatureService = require(script.Parent.CreatureService)
local PlayerStateService = require(script.Parent.PlayerStateService)

local PenService = {}

local hasStarted = false
local lastUpgradeRequestAtByPlayer: { [Player]: number } = {}

local function isFinitePositiveInteger(value: any): boolean
    return type(value) == "number" and value > 0 and value < math.huge and value % 1 == 0
end

local function validateConfiguration(): ()
    local minInterval = PenConfig.UpgradeRequestMinInterval
    assert(
        type(minInterval) == "number" and minInterval > 0 and minInterval < math.huge,
        "PenConfig.UpgradeRequestMinInterval must be a finite positive number"
    )
    assert(PenConfig.Levels[1].UpgradeCost == 0, "Starting Pen level must not have an upgrade cost")

    for level = 2, PenConfig.MaxLevel do
        local upgradeCost = PenConfig.Levels[level].UpgradeCost
        assert(
            upgradeCost == nil or isFinitePositiveInteger(upgradeCost),
            string.format("PenConfig level %d UpgradeCost must be nil or a positive integer", level)
        )
    end
end

local function isUpgradeRateLimited(player: Player): boolean
    local now = os.clock()
    local lastRequestAt = lastUpgradeRequestAtByPlayer[player]
    lastUpgradeRequestAtByPlayer[player] = now

    return lastRequestAt ~= nil and now - lastRequestAt < PenConfig.UpgradeRequestMinInterval
end

-- Buys the next Pen level at the player's own Pen. A level without an approved UpgradeCost is never sold.
function PenService.TryUpgrade(player: Player, ...): boolean
    if select("#", ...) ~= 0 then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return false
    end

    local base = BaseService.GetBase(player)
    local interactionPoint = if base then base.PenFloor else nil
    if not interactionPoint or not interactionPoint:IsDescendantOf(Workspace) then
        return false
    end

    if (rootPart.Position - interactionPoint.Position).Magnitude > GameConfig.PenManagementMaxDistance then
        return false
    end

    if isUpgradeRateLimited(player) then
        return false
    end

    local currentLevel = playerState.PenLevel
    if not PenConfig.IsValidLevel(currentLevel) then
        return false
    end

    local nextConfig = PenConfig.Levels[currentLevel + 1]
    if not nextConfig then
        return false
    end

    local upgradeCost = nextConfig.UpgradeCost
    if not isFinitePositiveInteger(upgradeCost) then
        return false
    end

    if not PlayerStateService.TrySpendCash(player, upgradeCost) then
        return false
    end

    playerState.PenLevel = nextConfig.Level
    BaseService.SetPenLevel(player, playerState.PenLevel)
    CreatureService.SendCreatureStateUpdate(player)

    return true
end

function PenService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    validateConfiguration()

    Players.PlayerRemoving:Connect(function(player)
        lastUpgradeRequestAtByPlayer[player] = nil
    end)
end

return PenService
