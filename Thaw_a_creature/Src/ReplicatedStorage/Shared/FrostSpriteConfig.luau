local PrototypeConfig = {
    FrostSpriteMaxHealth = 3,
    EngagementRadius = 26,
    AttackTelegraph = 0.75,
    AttackCooldown = 2.40,
    ProjectileSpeed = 40,
    -- Player hits cost CurrentWarmth by the Sprite's region, never by MaxWarmth, Ice reward or Special status.
    PlayerWarmthDamageByRegion = {
        Snowfield = 10,
        FrozenPass = 100,
        AncientExpanse = 4000,
        BlackIceHollow = 250000,
        MeteorReach = 8000000,
    },
    TargetingRule = "NearestValidTarget",
}

return PrototypeConfig
