local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureSurvivalConfig = require(shared:WaitForChild("CreatureSurvivalConfig"))
local FrostSpriteConfig = require(shared:WaitForChild("FrostSpriteConfig"))

local CreatureService = require(script.Parent.CreatureService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local SurvivalToolService = require(script.Parent.SurvivalToolService)
local WarmthService = require(script.Parent.WarmthService)

local FrostSpriteService = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

type PlayerTarget = {
    Kind: "Player",
    Player: Player,
}

type CreatureTarget = {
    Kind: "Creature",
    Player: Player,
    CreatureGUID: string,
}

type SpriteTarget = PlayerTarget | CreatureTarget

type SpriteRecord = {
    Model: Model,
    Core: BasePart,
    TelegraphLight: PointLight?,
    CurrentProjectile: BasePart?,
    CurrentHealth: number,
    IsDefeated: boolean,
}

local SPRITE_MODEL_NAME = "FrostSprite"
local ACTIVE_SPRITE_FOLDER_NAME = "ActiveFrostSprites"
local CORE_PART_NAME = "Core"
local TELEGRAPH_LIGHT_NAME = "TelegraphLight"
local PROJECTILE_NAME = "FrostSpriteProjectile"
local PROJECTILE_SIZE = Vector3.new(1.25, 1.25, 1.25)
local PROJECTILE_RADIUS = PROJECTILE_SIZE.X * 0.5
local TARGET_SCAN_INTERVAL = 0.1

local recordsByModel: { [Model]: SpriteRecord } = {}
local spriteTemplate: Model? = nil
local activeSpriteFolder: Folder? = nil
local hasStarted = false

local function getValidPlayerRoot(player: Player): BasePart?
    if player.Parent ~= Players or not PlayerStateService.GetState(player) then
        return nil
    end

    local character = player.Character
    if not character or not character:IsDescendantOf(Workspace) then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return nil
    end

    return rootPart
end

local function getTargetPosition(target: SpriteTarget): Vector3?
    if target.Kind == "Player" then
        local rootPart = getValidPlayerRoot(target.Player)
        return if rootPart then rootPart.Position else nil
    end

    return CreatureService.GetLogicalEquippedCreatureTargetPosition(target.Player, target.CreatureGUID)
end

local function acquireNearestTarget(origin: Vector3): SpriteTarget?
    assert(FrostSpriteConfig.TargetingRule == "NearestValidTarget", "Unsupported Frost Sprite targeting rule")

    local nearestTarget: SpriteTarget? = nil
    local nearestDistance = math.huge

    for _, player in Players:GetPlayers() do
        local rootPart = getValidPlayerRoot(player)
        if rootPart then
            local distance = (rootPart.Position - origin).Magnitude
            if distance <= FrostSpriteConfig.EngagementRadius and distance < nearestDistance then
                nearestDistance = distance
                nearestTarget = {
                    Kind = "Player",
                    Player = player,
                }
            end
        end

        local playerState = PlayerStateService.GetState(player)
        local equippedCreatureGUID = playerState and playerState.EquippedCreatureGUID
        if type(equippedCreatureGUID) == "string" then
            local creaturePosition = CreatureService.GetLogicalEquippedCreatureTargetPosition(
                player,
                equippedCreatureGUID
            )
            if creaturePosition then
                local distance = (creaturePosition - origin).Magnitude
                if distance <= FrostSpriteConfig.EngagementRadius and distance < nearestDistance then
                    nearestDistance = distance
                    nearestTarget = {
                        Kind = "Creature",
                        Player = player,
                        CreatureGUID = equippedCreatureGUID,
                    }
                end
            end
        end
    end

    return nearestTarget
end

local function setTelegraphEnabled(record: SpriteRecord, enabled: boolean): ()
    record.Model:SetAttribute("IsTelegraphing", enabled)

    if enabled then
        record.Core.Color = Color3.fromRGB(170, 235, 255)
        record.Core.Material = Enum.Material.Neon
    else
        record.Core.Color = Color3.fromRGB(75, 145, 205)
        record.Core.Material = Enum.Material.Ice
    end

    if record.TelegraphLight then
        record.TelegraphLight.Enabled = enabled
    end
end

local function destroyProjectile(record: SpriteRecord): ()
    local projectile = record.CurrentProjectile
    record.CurrentProjectile = nil
    if projectile then
        projectile:Destroy()
    end
end

local function isLockedTargetHit(target: SpriteTarget, hitInstance: Instance): boolean
    if target.Kind == "Player" then
        local character = target.Player.Character
        return character ~= nil and hitInstance:IsDescendantOf(character)
    end

    return false
end

local function getExpandedBoxHitDistance(
    segmentOrigin: Vector3,
    segment: Vector3,
    boxCFrame: CFrame,
    boxSize: Vector3,
    expansion: number
): number?
    local localOrigin = boxCFrame:PointToObjectSpace(segmentOrigin)
    local localEnd = boxCFrame:PointToObjectSpace(segmentOrigin + segment)
    local localSegment = localEnd - localOrigin
    local halfSize = boxSize * 0.5 + Vector3.one * expansion
    local minimumTime = 0
    local maximumTime = 1

    local function intersectsAxis(origin: number, direction: number, halfExtent: number): boolean
        if math.abs(direction) < 0.000001 then
            return math.abs(origin) <= halfExtent
        end

        local entryTime = (-halfExtent - origin) / direction
        local exitTime = (halfExtent - origin) / direction
        if entryTime > exitTime then
            entryTime, exitTime = exitTime, entryTime
        end

        minimumTime = math.max(minimumTime, entryTime)
        maximumTime = math.min(maximumTime, exitTime)
        return minimumTime <= maximumTime
    end

    if not intersectsAxis(localOrigin.X, localSegment.X, halfSize.X)
        or not intersectsAxis(localOrigin.Y, localSegment.Y, halfSize.Y)
        or not intersectsAxis(localOrigin.Z, localSegment.Z, halfSize.Z)
    then
        return nil
    end

    return segment.Magnitude * minimumTime
end

local function applyCreatureHit(target: CreatureTarget): ()
    local hitApplied = CreatureService.ApplyEquippedCreatureDamage(
        target.Player,
        target.CreatureGUID,
        CreatureSurvivalConfig.CreatureVitalityDamagePerHit
    )
    if hitApplied then
        gameplayEvent:FireClient(target.Player, "SurvivalFeedback", {
            Kind = "CreatureHit",
        })
    end
end

local function runProjectile(record: SpriteRecord, target: SpriteTarget, targetPosition: Vector3): boolean
    if record.IsDefeated or not record.Model:IsDescendantOf(Workspace) then
        return false
    end

    local origin = record.Core.Position
    local displacement = targetPosition - origin
    if displacement.Magnitude < 0.001 then
        return true
    end

    local direction = displacement.Unit
    local maxTravelDistance = displacement.Magnitude + PROJECTILE_SIZE.Z
    local traveledDistance = 0
    local creatureHadVisualBounds = false

    local projectile = Instance.new("Part")
    projectile.Name = PROJECTILE_NAME
    projectile.Shape = Enum.PartType.Ball
    projectile.Size = PROJECTILE_SIZE
    projectile.Color = Color3.fromRGB(130, 225, 255)
    projectile.Material = Enum.Material.Neon
    projectile.Anchored = true
    projectile.CanCollide = false
    projectile.CanQuery = false
    projectile.CanTouch = false
    projectile.CFrame = CFrame.new(origin)
    projectile.Parent = Workspace
    record.CurrentProjectile = projectile

    local castParams = RaycastParams.new()
    castParams.FilterType = Enum.RaycastFilterType.Exclude
    castParams.FilterDescendantsInstances = { record.Model, projectile }

    while not record.IsDefeated and projectile.Parent do
        if not getTargetPosition(target) then
            destroyProjectile(record)
            return false
        end

        local deltaTime = RunService.Heartbeat:Wait()
        local remainingDistance = maxTravelDistance - traveledDistance
        local stepDistance = math.min(FrostSpriteConfig.ProjectileSpeed * deltaTime, remainingDistance)
        if stepDistance <= 0 then
            break
        end

        local step = direction * stepDistance
        local projectilePreviousPosition = projectile.Position
        local result = Workspace:Spherecast(projectilePreviousPosition, PROJECTILE_RADIUS, step, castParams)
        local physicalHitDistance = if result then result.Distance else stepDistance
        local collisionStep = direction * math.min(stepDistance, physicalHitDistance)
        local creatureHitDistance: number? = nil
        if target.Kind == "Creature" then
            local boundsCFrame, boundsSize = CreatureService.GetLogicalEquippedCreatureTargetBounds(
                target.Player,
                target.CreatureGUID
            )
            if boundsCFrame and boundsSize then
                creatureHadVisualBounds = true
                creatureHitDistance = getExpandedBoxHitDistance(
                    projectilePreviousPosition,
                    collisionStep,
                    boundsCFrame,
                    boundsSize,
                    PROJECTILE_RADIUS
                )
            end
        end

        if creatureHitDistance then
            projectile.Position = projectilePreviousPosition + direction * creatureHitDistance
            applyCreatureHit(target :: CreatureTarget)
            break
        end

        if result then
            projectile.Position = projectilePreviousPosition + direction * result.Distance
            if isLockedTargetHit(target, result.Instance) and target.Kind == "Player" then
                local hitApplied = WarmthService.ApplyDamage(
                    target.Player,
                    FrostSpriteConfig.PlayerWarmthDamagePerHit
                )
                if hitApplied then
                    gameplayEvent:FireClient(target.Player, "SurvivalFeedback", {
                        Kind = "PlayerHit",
                    })
                end
            end
            break
        end

        projectile.Position = projectilePreviousPosition + step
        traveledDistance += stepDistance
    end

    if not record.IsDefeated
        and target.Kind == "Creature"
        and not creatureHadVisualBounds
        and traveledDistance >= maxTravelDistance
        and getTargetPosition(target)
    then
        applyCreatureHit(target :: CreatureTarget)
    end

    destroyProjectile(record)
    return not record.IsDefeated
end

local function destroyRecord(record: SpriteRecord): boolean
    if record.IsDefeated then
        return false
    end

    record.IsDefeated = true
    recordsByModel[record.Model] = nil
    setTelegraphEnabled(record, false)
    destroyProjectile(record)
    SurvivalToolService.UnregisterApprovedTarget(record.Model)
    record.Model:Destroy()

    return true
end

local function handleToolHit(record: SpriteRecord, player: Player, damage: number): boolean
    if record.IsDefeated or damage <= 0 then
        return false
    end

    record.CurrentHealth = math.max(record.CurrentHealth - damage, 0)
    record.Model:SetAttribute("CurrentHealth", record.CurrentHealth)

    gameplayEvent:FireClient(player, "SurvivalFeedback", {
        Kind = "ToolHit",
        Target = record.Model,
    })

    if record.CurrentHealth <= 0 then
        destroyRecord(record)
    end

    return true
end

local function runStateMachine(record: SpriteRecord): ()
    while not record.IsDefeated and record.Model:IsDescendantOf(Workspace) do
        local target = acquireNearestTarget(record.Core.Position)
        if not target then
            task.wait(TARGET_SCAN_INTERVAL)
            continue
        end

        local lockedTarget = target
        setTelegraphEnabled(record, true)
        task.wait(FrostSpriteConfig.AttackTelegraph)

        if record.IsDefeated then
            break
        end
        setTelegraphEnabled(record, false)

        local lockedPosition = getTargetPosition(lockedTarget)
        if not lockedPosition then
            continue
        end

        local completed = runProjectile(record, lockedTarget, lockedPosition)
        if not completed then
            continue
        end

        task.wait(FrostSpriteConfig.AttackCooldown)
    end

    if not record.IsDefeated then
        destroyRecord(record)
    end
end

function FrostSpriteService.Spawn(
    spawnCFrame: CFrame,
    spawnPointID: string,
    guardProfile: string,
    guardianMarkerID: string
): Model
    assert(hasStarted, "FrostSpriteService must be started before spawning guardians")
    assert(type(spawnPointID) == "string" and spawnPointID ~= "", "Frost Sprite requires a SpawnPointID")

    local template = spriteTemplate
    local folder = activeSpriteFolder
    assert(template and folder, "FrostSpriteService runtime folders must exist before spawning")

    local templateCore = template:FindFirstChild(CORE_PART_NAME)
    assert(templateCore and templateCore:IsA("BasePart"), "Frost Sprite template Core must be a BasePart")

    local model = template:Clone()
    model.Name = string.format("FrostSprite_%s_%s", guardProfile, guardianMarkerID)
    model:SetAttribute("GuardedSpawnPointID", spawnPointID)
    model:SetAttribute("GuardProfile", guardProfile)
    model:SetAttribute("GuardianMarkerID", guardianMarkerID)
    model:SetAttribute("CurrentHealth", FrostSpriteConfig.FrostSpriteMaxHealth)
    model:SetAttribute("MaxHealth", FrostSpriteConfig.FrostSpriteMaxHealth)
    model:SetAttribute("IsTelegraphing", false)

    local transform = spawnCFrame * templateCore.CFrame:Inverse()
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CFrame = transform * descendant.CFrame
        end
    end

    local core = model:FindFirstChild(CORE_PART_NAME)
    assert(core and core:IsA("BasePart"), "Spawned Frost Sprite Core must be a BasePart")

    local light = core:FindFirstChild(TELEGRAPH_LIGHT_NAME)
    assert(light == nil or light:IsA("PointLight"), "Frost Sprite telegraph light must be a PointLight")

    model.Parent = folder

    local record: SpriteRecord = {
        Model = model,
        Core = core,
        TelegraphLight = light :: PointLight?,
        CurrentProjectile = nil,
        CurrentHealth = FrostSpriteConfig.FrostSpriteMaxHealth,
        IsDefeated = false,
    }
    recordsByModel[model] = record

    SurvivalToolService.RegisterApprovedTarget(model, function(player, damage)
        return handleToolHit(record, player, damage)
    end)
    task.spawn(runStateMachine, record)

    return model
end

function FrostSpriteService.Destroy(model: Model): boolean
    local record = recordsByModel[model]
    if not record then
        return false
    end

    return destroyRecord(record)
end

function FrostSpriteService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    local template = ServerStorage:WaitForChild(SPRITE_MODEL_NAME)
    assert(template:IsA("Model"), "ServerStorage.FrostSprite must be a Model")

    local core = template:WaitForChild(CORE_PART_NAME)
    assert(core:IsA("BasePart"), "ServerStorage.FrostSprite.Core must be a BasePart")

    local light = core:FindFirstChild(TELEGRAPH_LIGHT_NAME)
    assert(light == nil or light:IsA("PointLight"), "Frost Sprite telegraph light must be a PointLight")

    local existingFolder = Workspace:FindFirstChild(ACTIVE_SPRITE_FOLDER_NAME)
    if existingFolder then
        assert(existingFolder:IsA("Folder"), string.format("Workspace.%s must be a Folder", ACTIVE_SPRITE_FOLDER_NAME))
        activeSpriteFolder = existingFolder
    else
        local folder = Instance.new("Folder")
        folder.Name = ACTIVE_SPRITE_FOLDER_NAME
        folder.Parent = Workspace
        activeSpriteFolder = folder
    end

    spriteTemplate = template
end

return FrostSpriteService
