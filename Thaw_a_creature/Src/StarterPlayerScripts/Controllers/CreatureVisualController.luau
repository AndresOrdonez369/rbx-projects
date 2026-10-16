local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureStatPresentation = require(shared:WaitForChild("CreatureStatPresentation"))
local CreatureSurvivalConfig = require(shared:WaitForChild("CreatureSurvivalConfig"))

-- Presents every player's Equipped creature: following behind them like a pet, or under them while Riding.
-- While the creature is Frosted (Vitality 0) it is shown as a floating Frosted Companion Orb instead, and the exact
-- Equipped creature rematerializes when the server clears Frosted. Driven by the mount attributes the server
-- replicates on each Player; purely cosmetic (the Orb never collides, queries or touches).
local CreatureVisualController = {}

-- Following ("pet") motion. Presentation only: the server keeps its own logical target for gameplay checks.
-- The follower keeps slack instead of being glued behind the player: it stays put while comfortably close, walks in
-- along its own line when left behind, trails the direction of travel, turns at a limited rate and hops with its stride.
local SNAP_DISTANCE = 40
local FOLLOW_GAP = 3.5 -- clear space between the player and the creature's footprint
local FOLLOW_SLACK = 2.5 -- extra distance an idle follower tolerates before walking again
local PLAYER_RADIUS = 1.5
local PLAYER_MOVING_SPEED = 2
local SIDE_BIAS = 0.5 -- while trailing, how strongly the follower keeps to the side it is already on
local AHEAD_THRESHOLD = -0.2 -- dot(away-from-player, travel) above this means the follower is in the player's path
local AHEAD_SIDESTEP_BACK = 0.3 -- how much the sidestep also drifts back
local MIN_FOLLOW_SPEED = 20
local FOLLOW_SPEED_MULTIPLIER = 1.35 -- relative to the player's speed, so a lagging follower catches up
local ARRIVE_GAIN = 3 -- desired speed per stud of remaining distance (eases into the stop)
local ACCELERATION_RATE = 6
local SEPARATION_PUSH_SPEED = 30 -- studs/s a follower overlapping the player is eased out
local GROUND_SMOOTHING_RATE = 15
local GROUND_RAY_HEIGHT = 8
local GROUND_RAY_DEPTH = 30
local FALLBACK_GROUND_OFFSET = 3
local MOVING_FACING_SPEED = 1.5
local IDLE_FACE_DELAY = 0.6
local IDLE_FACE_DEADBAND = math.rad(25)
local IDLE_FACE_SETTLE = math.rad(3)
local TURN_SPEED = math.rad(260)
local TURN_RADIUS_DAMPING = 6 -- bigger creatures turn more slowly
local STRIDE_BASE = 1.4
local STRIDE_PER_RADIUS = 0.6
local GAIT_FULL_SPEED = 6
local HOP_BASE = 0.12
local HOP_PER_RADIUS = 0.05
local WADDLE_ANGLE = math.rad(4)
local LEAN_ANGLE = math.rad(5)
local BREATH_AMPLITUDE = 0.04
local BREATH_SPEED = 2
local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local FOLLOWER_NAME = "EquippedFollower"
local RIDER_ANCHOR_ATTRIBUTE = "RiderAnchorOffset"
local MOUNT_CREATURE_ID_ATTRIBUTE = "MountCreatureID"
local MOUNT_SCALE_ATTRIBUTE = "MountScale"
local MOUNT_STATE_ATTRIBUTE = "MountState"
local MOUNT_FROSTED_ATTRIBUTE = "MountFrosted"
local RIDING_STATE = "Riding"
-- Frosted Companion Orb (L-D14.5-T02).
local ORB_NAME = "FrostedCompanionOrb"
local ORB_DIAMETER = 1.6
local ORB_HOVER_HEIGHT = 3.5
local ORB_BOB_AMPLITUDE = 0.35
local ORB_BOB_SPEED = 2.2
local ORB_COLOR = Color3.fromRGB(175, 225, 255)
local ORB_WISP_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

type Presentation = {
    Model: Model,
    Character: Model,
    RootPart: BasePart,
    RiderAnchor: Vector3,
    IsFrostedOrb: boolean,
    Radius: number,
    Position: Vector3?, -- simulated flat (Y = 0) position while Following; nil until placed
    GroundY: number?,
    Velocity: Vector3,
    Yaw: number,
    StridePhase: number,
    IdleTime: number,
    TurningToPlayer: boolean,
}

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")
local creatureVisuals = ReplicatedStorage:WaitForChild(CREATURE_VISUALS_FOLDER_NAME)

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")
assert(creatureVisuals:IsA("Folder"), "ReplicatedStorage.CreatureVisuals must be a Folder")

local started = false
local presentationsByPlayer: { [Player]: Presentation } = {}
-- Optional cosmetic motion layered on a Riding mount (MountSpeedController); never moves the saddle off the rider.
local mountMotionProvider: ((Player, Model, Vector3) -> CFrame)? = nil
local rebuildRevisionByPlayer: { [Player]: number } = {}
local localStats: CreatureStatPresentation.DisplayStats? = nil

local function destroyPresentation(player: Player): ()
    local presentation = presentationsByPlayer[player]
    presentationsByPlayer[player] = nil
    if presentation then
        presentation.Model:Destroy()
    end
end

local function makeFollowerSafe(model: Model): ()
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
        end
    end
end

local function createFrostedOrb(): Model
    local model = Instance.new("Model")
    model.Name = ORB_NAME

    local core = Instance.new("Part")
    core.Name = "Core"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.one * ORB_DIAMETER
    core.Material = Enum.Material.Neon
    core.Color = ORB_COLOR
    core.Transparency = 0.15
    core.CastShadow = false
    core.Parent = model

    local light = Instance.new("PointLight")
    light.Color = ORB_COLOR
    light.Range = 8
    light.Brightness = 1.2
    light.Parent = core

    local wisps = Instance.new("ParticleEmitter")
    wisps.Name = "Wisps"
    wisps.Texture = ORB_WISP_TEXTURE
    wisps.Color = ColorSequence.new(ORB_COLOR)
    wisps.LightEmission = 0.8
    wisps.Rate = 6
    wisps.Lifetime = NumberRange.new(0.6, 1)
    wisps.Speed = NumberRange.new(0.5, 1.5)
    wisps.SpreadAngle = Vector2.new(180, 180)
    wisps.Size = NumberSequence.new(0.25, 0)
    wisps.Parent = core

    model.PrimaryPart = core
    makeFollowerSafe(model)

    return model
end

local function getTargetCFrame(player: Player, presentation: Presentation): CFrame
    local rootPart = presentation.RootPart
    local isRiding = player:GetAttribute(MOUNT_STATE_ATTRIBUTE) == RIDING_STATE
    local riderAnchor = presentation.RiderAnchor
    local anchorPosition = if isRiding
        then rootPart.Position
        else rootPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, CreatureSurvivalConfig.LogicalTargetFollowDistance))

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { presentation.Character, presentation.Model }

    local rayOrigin = anchorPosition + Vector3.new(0, CreatureSurvivalConfig.LogicalTargetGroundRayHeight, 0)
    local rayDepth = CreatureSurvivalConfig.LogicalTargetGroundRayDepth + if isRiding then math.max(riderAnchor.Y, 0) else 0
    local groundResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -rayDepth, 0), raycastParams)
    local targetPosition = if groundResult then groundResult.Position else anchorPosition
    local lookVector = rootPart.CFrame.LookVector
    local horizontalLook = Vector3.new(lookVector.X, 0, lookVector.Z)

    if horizontalLook.Magnitude < 0.001 then
        horizontalLook = Vector3.new(0, 0, -1)
    else
        horizontalLook = horizontalLook.Unit
    end

    local groundCFrame = CFrame.lookAt(targetPosition, targetPosition + horizontalLook)
    if not isRiding then
        return groundCFrame
    end

    -- Match the server's logical mount pivot: the scaled rider anchor sits beneath the rider.
    return groundCFrame * CFrame.new(-riderAnchor.X, 0, -riderAnchor.Z)
end

local function flat(vector: Vector3): Vector3
    return Vector3.new(vector.X, 0, vector.Z)
end

-- Yaw whose CFrame.Angles(0, yaw, 0).LookVector points along the given flat direction.
local function yawFromDirection(direction: Vector3): number
    return math.atan2(-direction.X, -direction.Z)
end

local function angleBetween(fromYaw: number, toYaw: number): number
    return (toYaw - fromYaw + math.pi) % (2 * math.pi) - math.pi
end

local function newPresentation(
    model: Model,
    character: Model,
    rootPart: BasePart,
    riderAnchor: Vector3,
    isOrb: boolean
): Presentation
    local size = model:GetExtentsSize()
    return {
        Model = model,
        Character = character,
        RootPart = rootPart,
        RiderAnchor = riderAnchor,
        IsFrostedOrb = isOrb,
        Radius = math.max(size.X, size.Z) * 0.5,
        Position = nil,
        GroundY = nil,
        Velocity = Vector3.zero,
        Yaw = 0,
        StridePhase = 0,
        IdleTime = 0,
        TurningToPlayer = false,
    }
end

-- Keeps the follower simulation on the model's current pose (spawn, Riding) so Following resumes from there.
local function syncFollowerState(presentation: Presentation): ()
    local pivot = presentation.Model:GetPivot()
    presentation.Position = flat(pivot.Position)
    presentation.GroundY = pivot.Position.Y
    presentation.Velocity = Vector3.zero
    local look = flat(pivot.LookVector)
    if look.Magnitude > 1e-3 then
        presentation.Yaw = yawFromDirection(look)
    end
end

local function findGroundY(presentation: Presentation, position: Vector3, referenceY: number): number
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { presentation.Character, presentation.Model }

    local origin = Vector3.new(position.X, referenceY + GROUND_RAY_HEIGHT, position.Z)
    local result = Workspace:Raycast(origin, Vector3.new(0, -(GROUND_RAY_HEIGHT + GROUND_RAY_DEPTH), 0), raycastParams)
    return if result then result.Position.Y else referenceY - FALLBACK_GROUND_OFFSET
end

local function stepFollower(presentation: Presentation, deltaTime: number): CFrame
    local root = presentation.RootPart
    local playerPosition = flat(root.Position)
    local radius = presentation.Radius
    local followDistance = radius + PLAYER_RADIUS + FOLLOW_GAP
    local minDistance = radius + PLAYER_RADIUS
    local playerVelocity = flat(root.AssemblyLinearVelocity)
    local playerSpeed = playerVelocity.Magnitude
    local playerLook = flat(root.CFrame.LookVector)
    playerLook = if playerLook.Magnitude > 1e-3 then playerLook.Unit else Vector3.new(0, 0, -1)

    local position = presentation.Position
    if not position or (position - playerPosition).Magnitude > SNAP_DISTANCE then
        -- (Re)appear directly behind the player when first shown or left far behind (teleport, respawn).
        position = playerPosition - playerLook * followDistance
        presentation.Velocity = Vector3.zero
        presentation.Yaw = yawFromDirection(playerLook)
        presentation.GroundY = nil
    end
    local currentPosition = position :: Vector3

    local offset = currentPosition - playerPosition
    local distance = offset.Magnitude
    local awayDirection = if distance > 1e-3 then offset / distance else -playerLook

    local target = currentPosition
    if playerSpeed > PLAYER_MOVING_SPEED then
        -- Trail behind the direction of travel, keeping to the side it is already on instead of cutting across.
        local moveDirection = playerVelocity / playerSpeed
        local trail = awayDirection * SIDE_BIAS - moveDirection
        if awayDirection:Dot(moveDirection) > AHEAD_THRESHOLD then
            -- The player is walking toward it: step out of the way on its own side, then fall in behind.
            local side = Vector3.new(-moveDirection.Z, 0, moveDirection.X)
            if side:Dot(awayDirection) < 0 then
                side = -side
            end
            trail = side - moveDirection * AHEAD_SIDESTEP_BACK
        end
        trail = if trail.Magnitude > 1e-3 then trail.Unit else -moveDirection
        target = playerPosition + trail * followDistance
    elseif distance > followDistance + FOLLOW_SLACK then
        -- Left behind while the player stands still: walk in along its own line (never orbit around them).
        target = playerPosition + awayDirection * followDistance
    elseif distance < minDistance + 0.5 then
        -- The player walked into it: step aside.
        target = playerPosition + awayDirection * (minDistance + 1)
    end

    -- Match the player's own velocity while they move (so it keeps its spot instead of lagging), plus a correction
    -- toward the target that eases off as it arrives.
    local toTarget = target - currentPosition
    local maxSpeed = math.max(MIN_FOLLOW_SPEED, playerSpeed * FOLLOW_SPEED_MULTIPLIER)
    local feedForward = if playerSpeed > PLAYER_MOVING_SPEED then playerVelocity else Vector3.zero
    local desiredVelocity = feedForward + toTarget * ARRIVE_GAIN
    if desiredVelocity.Magnitude > maxSpeed then
        desiredVelocity = desiredVelocity.Unit * maxSpeed
    elseif desiredVelocity.Magnitude < 0.05 then
        desiredVelocity = Vector3.zero
    end
    local velocity = presentation.Velocity:Lerp(desiredVelocity, 1 - math.exp(-ACCELERATION_RATE * deltaTime))
    currentPosition += velocity * deltaTime

    -- Never stay inside the player: slide out at a capped speed (e.g. right after Unride) instead of popping out.
    local separation = currentPosition - playerPosition
    if separation.Magnitude < minDistance then
        local pushDirection = if separation.Magnitude > 1e-3 then separation.Unit else awayDirection
        local depth = minDistance - separation.Magnitude
        currentPosition += pushDirection * math.min(depth, SEPARATION_PUSH_SPEED * deltaTime)
    end

    presentation.Position = currentPosition
    presentation.Velocity = velocity

    local groundTarget = findGroundY(presentation, currentPosition, root.Position.Y)
    local previousGroundY = presentation.GroundY
    local groundY = if previousGroundY
        then previousGroundY + (groundTarget - previousGroundY) * (1 - math.exp(-GROUND_SMOOTHING_RATE * deltaTime))
        else groundTarget
    presentation.GroundY = groundY

    -- Face where it walks; once settled, turn to look at the player (with a deadband so it does not twitch).
    local speed = velocity.Magnitude
    local targetYaw = presentation.Yaw
    if speed > MOVING_FACING_SPEED then
        presentation.IdleTime = 0
        presentation.TurningToPlayer = false
        targetYaw = yawFromDirection(velocity)
    else
        presentation.IdleTime += deltaTime
        local toPlayer = playerPosition - currentPosition
        if presentation.IdleTime > IDLE_FACE_DELAY and toPlayer.Magnitude > 1e-3 then
            local facePlayerYaw = yawFromDirection(toPlayer)
            local remaining = math.abs(angleBetween(presentation.Yaw, facePlayerYaw))
            if remaining > IDLE_FACE_DEADBAND then
                presentation.TurningToPlayer = true
            elseif remaining < IDLE_FACE_SETTLE then
                presentation.TurningToPlayer = false
            end
            if presentation.TurningToPlayer then
                targetYaw = facePlayerYaw
            end
        end
    end
    local maxTurn = TURN_SPEED / (1 + radius / TURN_RADIUS_DAMPING) * deltaTime
    presentation.Yaw += math.clamp(angleBetween(presentation.Yaw, targetYaw), -maxTurn, maxTurn)

    if presentation.IsFrostedOrb then
        local bob = ORB_BOB_AMPLITUDE * math.sin(os.clock() * ORB_BOB_SPEED)
        return CFrame.new(currentPosition.X, groundY + ORB_HOVER_HEIGHT + bob, currentPosition.Z)
    end

    -- Procedural gait: a small hop per step, a side-to-side waddle and a forward lean, all scaled by speed.
    local stride = STRIDE_BASE + radius * STRIDE_PER_RADIUS
    presentation.StridePhase = (presentation.StridePhase + speed * deltaTime / stride) % 2
    local gait = math.clamp(speed / GAIT_FULL_SPEED, 0, 1)
    local swing = math.sin(presentation.StridePhase * math.pi)
    local hop = math.abs(swing) * (HOP_BASE + radius * HOP_PER_RADIUS) * gait
    local roll = swing * WADDLE_ANGLE * gait
    local lean = math.clamp(speed / MIN_FOLLOW_SPEED, 0, 1) * LEAN_ANGLE
    local breath = (1 - gait) * BREATH_AMPLITUDE * math.sin(os.clock() * BREATH_SPEED)

    return CFrame.new(currentPosition.X, groundY + hop + breath, currentPosition.Z)
        * CFrame.Angles(0, presentation.Yaw, 0)
        * CFrame.Angles(-lean, 0, roll)
end

local function rebuildPresentation(player: Player): ()
    local revision = (rebuildRevisionByPlayer[player] or 0) + 1
    rebuildRevisionByPlayer[player] = revision
    destroyPresentation(player)

    local creatureID = player:GetAttribute(MOUNT_CREATURE_ID_ATTRIBUTE)
    local scale = player:GetAttribute(MOUNT_SCALE_ATTRIBUTE)
    local character = player.Character
    if type(creatureID) ~= "string"
        or type(scale) ~= "number"
        or scale <= 0
        or not character
    then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 10)
    if rebuildRevisionByPlayer[player] ~= revision
        or player.Character ~= character
        or not rootPart
        or not rootPart:IsA("BasePart")
    then
        return
    end

    if player:GetAttribute(MOUNT_FROSTED_ATTRIBUTE) == true then
        local orb = createFrostedOrb()
        local orbPresentation = newPresentation(orb, character, rootPart, Vector3.zero, true)
        orb:PivotTo(getTargetCFrame(player, orbPresentation) * CFrame.new(0, ORB_HOVER_HEIGHT, 0))
        orb.Parent = Workspace
        presentationsByPlayer[player] = orbPresentation
        return
    end

    local creature = CreatureConfig[creatureID]
    local source = creature and creatureVisuals:FindFirstChild(creature.ModelName)
    if not source or not source:IsA("Model") then
        return
    end

    local templateAnchor = source:GetAttribute(RIDER_ANCHOR_ATTRIBUTE)
    local model = source:Clone()
    makeFollowerSafe(model)
    model:ScaleTo(model:GetScale() * scale)
    model.Name = FOLLOWER_NAME
    model:SetAttribute("CreatureID", creatureID)
    model:SetAttribute("SizeScale", scale)

    -- Only the local player sees their own copy's stat card.
    local stats = localStats
    if player == localPlayer and stats and stats.Scale == scale then
        CreatureStatPresentation.Attach(model, stats)
    end

    local riderAnchor = (if typeof(templateAnchor) == "Vector3" then templateAnchor else Vector3.zero) * scale
    local presentation = newPresentation(model, character, rootPart, riderAnchor, false)
    model:PivotTo(getTargetCFrame(player, presentation))
    syncFollowerState(presentation)
    model.Parent = Workspace
    presentationsByPlayer[player] = presentation
end

local function updatePresentations(deltaTime: number): ()
    for player, presentation in presentationsByPlayer do
        if player.Character ~= presentation.Character or not presentation.RootPart:IsDescendantOf(presentation.Character) then
            continue
        end

        -- A mount stays locked under its rider; a follower moves on its own (see stepFollower).
        if player:GetAttribute(MOUNT_STATE_ATTRIBUTE) == RIDING_STATE and not presentation.IsFrostedOrb then
            local targetCFrame = getTargetCFrame(player, presentation)
            local provider = mountMotionProvider
            presentation.Model:PivotTo(
                if provider then targetCFrame * provider(player, presentation.Model, presentation.RiderAnchor) else targetCFrame
            )
            syncFollowerState(presentation)
        else
            presentation.Model:PivotTo(stepFollower(presentation, deltaTime))
        end
    end
end

local function watchPlayer(player: Player): ()
    for _, attributeName in { MOUNT_CREATURE_ID_ATTRIBUTE, MOUNT_SCALE_ATTRIBUTE, MOUNT_FROSTED_ATTRIBUTE } do
        player:GetAttributeChangedSignal(attributeName):Connect(function()
            rebuildPresentation(player)
        end)
    end

    player.CharacterAdded:Connect(function()
        rebuildPresentation(player)
    end)

    player.CharacterRemoving:Connect(function(character)
        local presentation = presentationsByPlayer[player]
        if presentation and presentation.Character == character then
            destroyPresentation(player)
        end
    end)

    task.spawn(rebuildPresentation, player)
end

function CreatureVisualController.SetMountMotionProvider(provider: ((Player, Model, Vector3) -> CFrame)?): ()
    mountMotionProvider = provider
end

function CreatureVisualController.GetMountModel(player: Player): Model?
    local presentation = presentationsByPlayer[player]
    return if presentation and not presentation.IsFrostedOrb and presentation.Model.Parent
        then presentation.Model
        else nil
end

function CreatureVisualController.Start(): ()
    if started then
        return
    end
    started = true

    -- The server's private equip update carries the local copy's display stats.
    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName ~= "EquippedCreatureChanged" or type(data) ~= "table" then
            return
        end

        local stats = {
            Scale = data.Scale,
            FinalIncome = data.FinalIncome,
            FinalWalkSpeed = data.FinalWalkSpeed,
        }
        local nextStats = if CreatureStatPresentation.IsValidDisplayStats(stats) then stats else nil
        local previousStats = localStats
        local statsChanged = (nextStats == nil) ~= (previousStats == nil)
            or (nextStats ~= nil and previousStats ~= nil and (
                nextStats.Scale ~= previousStats.Scale
                or nextStats.FinalIncome ~= previousStats.FinalIncome
                or nextStats.FinalWalkSpeed ~= previousStats.FinalWalkSpeed
            ))
        localStats = nextStats

        -- Vitality and mount-state updates reuse this event; only new copy stats need a new card.
        if statsChanged then
            rebuildPresentation(localPlayer)
        end
    end)

    for _, player in Players:GetPlayers() do
        watchPlayer(player)
    end
    Players.PlayerAdded:Connect(watchPlayer)
    Players.PlayerRemoving:Connect(function(player)
        destroyPresentation(player)
        rebuildRevisionByPlayer[player] = nil
    end)

    RunService.Heartbeat:Connect(updatePresentations)
end

return CreatureVisualController
