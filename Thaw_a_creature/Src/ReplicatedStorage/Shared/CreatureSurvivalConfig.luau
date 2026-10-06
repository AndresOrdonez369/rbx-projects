local PrototypeConfig = {
    CreatureVitalityMax = 100,
    CreatureVitalityDamagePerHit = 25,
    FrostedAtVitality = 0,
    FrostedSpeedBonusEnabled = false,
    HearthRecovery = "FullRestoreOnEntry",

    -- Mirrors the existing cosmetic follower positioning convention so the
    -- server can derive a logical target point without trusting the client.
    LogicalTargetFollowDistance = 6,
    LogicalTargetGroundRayHeight = 8,
    LogicalTargetGroundRayDepth = 24,
}

return PrototypeConfig
