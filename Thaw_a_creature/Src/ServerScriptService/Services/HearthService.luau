local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(shared:WaitForChild("GameConfig"))
local HearthConfig = require(shared:WaitForChild("HearthConfig"))

local PlayerStateService = require(script.Parent.PlayerStateService)

local HearthService = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local hasStarted = false
local hearthInteractionPoint: BasePart? = nil
local prototypeBaseOwner: Player? = nil
local lastUpgradeRequestAtByPlayer: { [Player]: number } = {}

local function isFinitePositiveNumber(value: any): boolean
    return type(value) == "number" and value > 0 and value < math.huge
end

local function isFinitePositiveInteger(value: any): boolean
    return isFinitePositiveNumber(value) and value % 1 == 0
end

local function validateConfiguration(): ()
    assert(GameConfig.MaxPlayers == 1, "Prototype Hearth ownership requires the single-player Week-1 topology")
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

    local interactionPoint = hearthInteractionPoint
    if player ~= prototypeBaseOwner
        or not interactionPoint
        or not interactionPoint:IsDescendantOf(Workspace)
    then
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

    local prototypeBase = Workspace:WaitForChild("PrototypeBase")
    local hearth = prototypeBase:WaitForChild("Hearth")
    local interactionPoint = hearth:WaitForChild("HearthBase")
    local prompt = interactionPoint:WaitForChild("UpgradePrompt")

    assert(prototypeBase:IsA("Folder"), "Workspace.PrototypeBase must be a Folder")
    assert(hearth:IsA("Model"), "Workspace.PrototypeBase.Hearth must be a Model")
    assert(interactionPoint:IsA("BasePart"), "Workspace.PrototypeBase.Hearth.HearthBase must be a BasePart")
    assert(prompt:IsA("ProximityPrompt"), "Workspace.PrototypeBase.Hearth.HearthBase.UpgradePrompt must be a ProximityPrompt")

    hearthInteractionPoint = interactionPoint

    local function assignPrototypeBaseOwner(player: Player): ()
        if prototypeBaseOwner == nil then
            prototypeBaseOwner = player
        end
    end

    Players.PlayerAdded:Connect(assignPrototypeBaseOwner)
    Players.PlayerRemoving:Connect(function(player)
        lastUpgradeRequestAtByPlayer[player] = nil
        if prototypeBaseOwner == player then
            prototypeBaseOwner = nil
        end
    end)

    for _, player in Players:GetPlayers() do
        assignPrototypeBaseOwner(player)
    end
end

return HearthService
