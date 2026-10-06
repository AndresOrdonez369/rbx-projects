local PrototypeConfig = {
    Regular = {
        IceType = "Regular",
        ActiveSpawnCount = 4,
        RarityWeights = {
            Common = 74,
            Uncommon = 23,
            Rare = 3,
            Epic = 0,
            Legendary = 0,
        },
        CreaturePoolsByRarity = {
            Common = { "Penguin", "Rabbit", "Seal" },
            Uncommon = { "Wolf", "Bear" },
            Rare = { "Mammoth" },
            Epic = {},
            Legendary = {},
        },
        BaseThawDuration = 20,
        CarryDrainMultiplier = 2.00,
        PresentationProfile = "Regular",
        PresentationScale = 1.00,
    },
    Thick = {
        IceType = "Thick",
        ActiveSpawnCount = 2,
        RarityWeights = {
            Common = 30,
            Uncommon = 32,
            Rare = 24,
            Epic = 11,
            Legendary = 3,
        },
        CreaturePoolsByRarity = {
            Common = { "Seal" },
            Uncommon = { "Wolf", "Bear" },
            Rare = { "Mammoth", "Sleipnir" },
            Epic = { "Troll", "IceSerpent" },
            Legendary = { "Hraesvlgr", "Nidhogg" },
        },
        BaseThawDuration = 45,
        CarryDrainMultiplier = 2.00,
        PresentationProfile = "Thick",
        PresentationScale = 1.40,
    },
}

return PrototypeConfig
