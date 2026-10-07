local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local HearthConfig = require(shared:WaitForChild("HearthConfig"))

local BaseService = require(script.Parent.BaseService)
local PlayerStateService = require(script.Parent.PlayerStateService)

local HearthService = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local hasStarted = false
local lastUpgradeRequestAtByPlayer: { [Player]: number } = {}

local function isFinitePositiveNumber(value: any): boolean
    return type(value) == "number" and value > 0 and value < math.huge
end

local function isFinitePositiveInteger(value: any): boolean
    return isFinitePositiveNumber(value) and value % 1 == 0
end

local function validateConfiguration(): ()
    assert(
        isFinitePositiveNumber(HearthConfig.UpgradeMaxDistance),
        "HearthConfig.UpgradeMaxDistance must be a finite positive number"
    )
    assert(
        isFinitePositiveNumber(HearthConfig.UpgradeRequestMinInterval),
        "HearthConfig.UpgradeRequestMinInterval must be a finite positive number"
    )

    for level = 1, 6 do
        local levelConfig = HearthConfig[level]
        assert(type(levelConfig) == "table", string.format("Missing HearthConfig for level %d", level))
        assert(levelConfig.Level == level, string.format("HearthConfig level %d must identify itself", level))
        assert(
            isFinitePositiveNumber(levelConfig.WarmthTrainingRate),
            string.format("HearthConfig level %d must have a finite positive WarmthTrainingRate", level)
        )
        assert(
            type(levelConfig.VisualStage) == "string" and levelConfig.VisualStage ~= "",
            string.format("HearthConfig level %d must have a non-empty VisualStage", level)
        )

        if level == 1 then
            assert(levelConfig.UpgradeCost == 0, "Starting Hearth level must not have an upgrade cost")
        else
            assert(
                isFinitePositiveInteger(levelConfig.UpgradeCost),
                string.format("HearthConfig level %d must have a finite positive integer UpgradeCost", level)
            )
        end
    end

    assert(HearthConfig[7] == nil, "Hearth progression must stop at level 6")
end

local function getClientState(hearthLevel: number): { [string]: any }?
    local currentConfig = HearthConfig[hearthLevel]
    if not currentConfig then
        return nil
    end

    local nextConfig = HearthConfig[hearthLevel + 1]
    return {
        HearthLevel = hearthLevel,
        WarmthTrainingRate = currentConfig.WarmthTrainingRate,
        VisualStage = currentConfig.VisualStage,
        NextUpgradeCost = if nextConfig then nextConfig.UpgradeCost else nil,
        IsMaxLevel = nextConfig == nil,
    }
end

function HearthService.SendHearthUpdate(player: Player): boolean
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return false
    end

    local clientState = getClientState(playerState.HearthLevel)
    if not clientState then
        return false
    end

    gameplayEvent:FireClient(player, "HearthUpdated", clientState)
    return true
end

local function isUpgradeRateLimited(player: Player): boolean
    local now = os.clock()
    local lastRequestAt = lastUpgradeRequestAtByPlayer[player]
    lastUpgradeRequestAtByPlayer[player] = now

    return lastRequestAt ~= nil and now - lastRequestAt < HearthConfig.UpgradeRequestMinInterval
end

function HearthService.TryUpgrade(player: Player, ...): boolean
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

    -- Only the player's own Hearth can be upgraded.
    local base = BaseService.GetBase(player)
    local interactionPoint = if base then base.HearthBase else nil
    if not interactionPoint or not interactionPoint:IsDescendantOf(Workspace) then
        return false
    end

    if (rootPart.Position - interactionPoint.Position).Magnitude > HearthConfig.UpgradeMaxDistance then
        return false
    end

    if isUpgradeRateLimited(player) then
        return false
    end

    local currentLevel = playerState.HearthLevel
    local currentConfig = if type(currentLevel) == "number" and currentLevel % 1 == 0
        then HearthConfig[currentLevel]
        else nil
    if not currentConfig or currentConfig.Level ~= currentLevel then
        return false
    end

    local nextConfig = HearthConfig[currentLevel + 1]
    if not nextConfig or nextConfig.Level ~= currentLevel + 1 then
        return false
    end

    local upgradeCost = nextConfig.UpgradeCost
    if not isFinitePositiveInteger(upgradeCost) then
        return false
    end

    if type(playerState.Cash) ~= "number" or playerState.Cash < upgradeCost then
        return false
    end

    local spent = PlayerStateService.TrySpendCash(player, upgradeCost)
    if not spent then
        return false
    end

    playerState.HearthLevel = nextConfig.Level
    HearthService.SendHearthUpdate(player)

    return true
end

function HearthService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    validateConfiguration()

    for _, base in BaseService.GetBases() do
        local prompt = base.HearthBase:WaitForChild("UpgradePrompt")
        assert(prompt:IsA("ProximityPrompt"), string.format("%s.UpgradePrompt must be a ProximityPrompt", base.HearthBase:GetFullName()))
    end

    Players.PlayerRemoving:Connect(function(player)
        lastUpgradeRequestAtByPlayer[player] = nil
    end)
end

return HearthService
