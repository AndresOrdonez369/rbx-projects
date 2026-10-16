local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureSurvivalConfig = require(shared:WaitForChild("CreatureSurvivalConfig"))
local PlayerContestConfig = require(shared:WaitForChild("PlayerContestConfig"))
local SurvivalToolConfig = require(shared:WaitForChild("SurvivalToolConfig"))

local BaseService = require(script.Parent.BaseService)
local CreatureService = require(script.Parent.CreatureService)
local IceService = require(script.Parent.IceService)
local PlayerStateService = require(script.Parent.PlayerStateService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

-- Wilderness player contest (L-D14.5-T05 / T06), resolved through the one survival attack.
-- Non-carrier: ragdoll + knockback (mounted: also 25% mount Vitality and forced Unride). On-foot carrier: immune.
-- Mounted carrier: the mount alone loses 25% Vitality, then a short hit grace. Home Camp is always safe.
-- Never touches Player HP, Warmth, Cash, ownership, Inventory, Pen, or Ice state/ownership.
local PlayerContestService = {}

local KNOCKBACK_EVENT = "ContestKnockback"

export type ContestTarget = {
    Player: Player,
    IsRiding: boolean,
}

local function isInsideSwingReach(attackOrigin: CFrame, point: Vector3, padding: number): boolean
    local localPoint = attackOrigin:PointToObjectSpace(point)
    if localPoint.Z >= 0 then
        return false
    end

    return math.abs(localPoint.X) <= SurvivalToolConfig.HitboxWidth * 0.5 + padding
        and math.abs(localPoint.Y) <= SurvivalToolConfig.HitboxHeight * 0.5 + padding
        and -localPoint.Z <= SurvivalToolConfig.HitboxDepth + padding
        and (point - attackOrigin.Position).Magnitude <= SurvivalToolConfig.ToolServerHitRange + padding
end

local function getClosestPointOnBox(boxCFrame: CFrame, boxSize: Vector3, point: Vector3): Vector3
    local localPoint = boxCFrame:PointToObjectSpace(point)
    local halfSize = boxSize * 0.5

    return boxCFrame:PointToWorldSpace(Vector3.new(
        math.clamp(localPoint.X, -halfSize.X, halfSize.X),
        math.clamp(localPoint.Y, -halfSize.Y, halfSize.Y),
        math.clamp(localPoint.Z, -halfSize.Z, halfSize.Z)
    ))
end

local function getValidRoot(player: Player): BasePart?
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

-- Eligibility shared by target search and hit application. Returns whether the target is Riding when eligible.
local function getEligibleTargetState(attacker: Player, target: Player): (boolean, boolean)
    if target == attacker or target.Parent ~= Players then
        return false, false
    end

    local playerState = PlayerStateService.GetState(target)
    if not playerState or playerState.IsFrozen or not getValidRoot(target) then
        return false, false
    end

    local now = os.clock()
    if now < playerState.ContestRagdollUntil or now < playerState.ContestImmuneUntil then
        return false, false
    end

    if BaseService.IsPlayerInsideHomeSafeZone(target) then
        return false, false
    end

    local isRiding = playerState.IsRiding == true
    -- An on-foot carrier is immune to player contest (CarrierOnFootPlayerContestImmune).
    if IceService.IsCarryingIce(target) and not isRiding then
        return false, false
    end

    return true, isRiding
end

-- The point a swing must reach: the rider's logical mount body while Riding, otherwise the player's root.
local function getContestPoint(target: Player, isRiding: boolean, attackOrigin: CFrame): (Vector3?, number)
    local rootPart = getValidRoot(target)
    if not rootPart then
        return nil, 0
    end

    if isRiding then
        local playerState = PlayerStateService.GetState(target)
        local creatureGUID = playerState and playerState.EquippedCreatureGUID
        if type(creatureGUID) == "string" then
            local boundsCFrame, boundsSize = CreatureService.GetLogicalEquippedCreatureTargetBounds(target, creatureGUID)
            if boundsCFrame and boundsSize then
                return getClosestPointOnBox(boundsCFrame, boundsSize, attackOrigin.Position), 0
            end
        end
    end

    return rootPart.Position, PlayerContestConfig.OnFootTargetPadding
end

local function damageMount(target: Player): boolean
    local playerState = PlayerStateService.GetState(target)
    local creatureGUID = playerState and playerState.EquippedCreatureGUID
    if type(creatureGUID) ~= "string" then
        return false
    end

    local amount = PlayerContestConfig.MountDamageFraction * CreatureSurvivalConfig.CreatureVitalityMax
    local applied = CreatureService.ApplyEquippedCreatureDamage(target, creatureGUID, amount)
    if applied then
        gameplayEvent:FireClient(target, "SurvivalFeedback", {
            Kind = "CreatureHit",
        })
    end

    return applied
end

local function startRagdoll(target: Player, attackOrigin: CFrame): ()
    local playerState = PlayerStateService.GetState(target)
    local rootPart = getValidRoot(target)
    if not playerState or not rootPart then
        return
    end

    local now = os.clock()
    playerState.ContestRagdollUntil = now + PlayerContestConfig.RagdollDuration
    playerState.ContestImmuneUntil = playerState.ContestRagdollUntil + PlayerContestConfig.PostRecoveryImmunity

    local away = rootPart.Position - attackOrigin.Position
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.001 then
        local look = attackOrigin.LookVector
        away = Vector3.new(look.X, 0, look.Z)
    end
    away = if away.Magnitude < 0.001 then Vector3.new(0, 0, -1) else away.Unit

    -- The target's client owns its character physics, so it applies the shove; the server owns the timing above.
    gameplayEvent:FireClient(target, KNOCKBACK_EVENT, {
        Direction = away,
        HorizontalSpeed = PlayerContestConfig.KnockbackHorizontalSpeed,
        VerticalSpeed = PlayerContestConfig.KnockbackVerticalSpeed,
        Duration = PlayerContestConfig.RagdollDuration,
    })
end

-- Survival attacks are unavailable while ragdolled (and the Grab Hold rules block holds for the same window).
function PlayerContestService.IsRagdolled(player: Player): boolean
    local playerState = PlayerStateService.GetState(player)
    return playerState ~= nil and os.clock() < playerState.ContestRagdollUntil
end

-- Nearest rival this swing reaches, with its distance from the attack origin. Both sides must be in the wilderness.
function PlayerContestService.FindNearestTarget(attacker: Player, attackOrigin: CFrame): (ContestTarget?, number)
    if not PlayerContestConfig.Enabled or BaseService.IsPlayerInsideHomeSafeZone(attacker) then
        return nil, math.huge
    end

    local nearestTarget: ContestTarget? = nil
    local nearestDistance = math.huge

    for _, target in Players:GetPlayers() do
        local isEligible, isRiding = getEligibleTargetState(attacker, target)
        if not isEligible then
            continue
        end

        local point, padding = getContestPoint(target, isRiding, attackOrigin)
        if point and isInsideSwingReach(attackOrigin, point, padding) then
            local distance = (point - attackOrigin.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestTarget = {
                    Player = target,
                    IsRiding = isRiding,
                }
            end
        end
    end

    return nearestTarget, nearestDistance
end

function PlayerContestService.TryApplyHit(attacker: Player, contestTarget: ContestTarget, attackOrigin: CFrame): boolean
    local target = contestTarget.Player
    local isEligible, isRiding = getEligibleTargetState(attacker, target)
    if not isEligible or isRiding ~= contestTarget.IsRiding then
        return false
    end

    local playerState = PlayerStateService.GetState(target)
    assert(playerState, "Eligible contest target must have state")

    if IceService.IsCarryingIce(target) then
        -- Mounted carrier (T06): rider and Ice stay protected. At zero Vitality the normal Frosted path forces Unride
        -- and the exact Ice simply stays carried on foot.
        if not damageMount(target) then
            return false
        end

        playerState.ContestImmuneUntil = os.clock() + PlayerContestConfig.MountedCarrierHitGrace
        return true
    end

    -- Non-carrier (T05): any Grab Hold in progress resets, and the target ends up on foot (no auto-remount).
    IceService.CancelGrabHold(target, "ContestHit")
    if isRiding then
        damageMount(target)
        CreatureService.ForceUnride(target)
    end
    startRagdoll(target, attackOrigin)

    return true
end

return PlayerContestService
