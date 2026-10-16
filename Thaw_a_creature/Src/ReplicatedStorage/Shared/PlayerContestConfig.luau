-- Wilderness player contest (L-D14.5-T05 / T06). Timings and mount damage are the Implementation Constants v1.4
-- first-pass values. Contest never damages Player HP, Warmth, Cash, ownership, Inventory, Pen or Ice state.
local PlayerContestConfig = {
    Enabled = true,
    RagdollDuration = 1.25,
    PostRecoveryImmunity = 1.75,
    MountedCarrierHitGrace = 1.75,
    -- Fraction of CreatureSurvivalConfig.CreatureVitalityMax removed per validated mount hit / forced knock-off.
    MountDamageFraction = 0.25,
    -- Designer-tunable feel values, to be locked by multiplayer playtest (not canonical yet).
    KnockbackHorizontalSpeed = 40,
    KnockbackVerticalSpeed = 18,
    -- Body half-width allowance when testing an on-foot target's root against the swing hitbox.
    OnFootTargetPadding = 1,
}

return PlayerContestConfig
