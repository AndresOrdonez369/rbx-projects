local RarityConfig = {
    Common = {
        Order = 1,
        WalkSpeed = 22,
        SellValue = 20,
        PenIncomePerTick = 2,
        RevealPresentationProfile = "Common",
        RarityUI = {},
        EffectsProfile = "Common",
    },
    Uncommon = {
        Order = 2,
        WalkSpeed = 28,
        SellValue = 45,
        PenIncomePerTick = 5,
        RevealPresentationProfile = "Uncommon",
        RarityUI = {},
        EffectsProfile = "Uncommon",
    },
    Rare = {
        Order = 3,
        WalkSpeed = 34,
        SellValue = 120,
        PenIncomePerTick = 12,
        RevealPresentationProfile = "Rare",
        RarityUI = {},
        EffectsProfile = "Rare",
    },
    Epic = {
        Order = 4,
        WalkSpeed = 40,
        PenIncomePerTick = 20,
        RevealPresentationProfile = "Epic",
        RarityUI = {},
        EffectsProfile = "Epic",
    },
    Legendary = {
        Order = 5,
        WalkSpeed = 46,
        PenIncomePerTick = 28,
        RevealPresentationProfile = "Legendary",
        RarityUI = {},
        EffectsProfile = "Legendary",
    },
}

return RarityConfig
