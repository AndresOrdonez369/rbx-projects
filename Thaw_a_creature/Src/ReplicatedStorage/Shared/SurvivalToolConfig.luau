local PrototypeConfig = {
    ToolServerHitRange = 8,
    ToolSwingCooldown = 0.65,
    ToolDamageToFrostSprite = 1,
    HitboxWidth = 4,
    HitboxHeight = 4,
    HitboxDepth = 8,
    -- Mounted Strike resolves from the mount's ground/front point raised to on-foot attack height,
    -- so its reach envelope matches the on-foot swing regardless of mount Scale.
    MountedCombatOriginHeight = 3,
    -- Accepted survival attacks needed to clear each authored route obstacle type.
    BreakableHitsByType = {
        FrozenBranch = 3,
        BrittleRock = 5,
    },
}

return PrototypeConfig
