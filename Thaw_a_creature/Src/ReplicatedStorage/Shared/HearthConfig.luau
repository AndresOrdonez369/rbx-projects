local HearthConfig = {
    MaxLevel = 10,
    UpgradeMaxDistance = 20,
    UpgradeRequestMinInterval = 0.50,
    [1] = {
        Level = 1,
        UpgradeCost = 0,
        WarmthTrainingRate = 3,
        VisualStage = "Small Hearth",
    },
    [2] = {
        Level = 2,
        UpgradeCost = 5000,
        WarmthTrainingRate = 5,
        VisualStage = "Strong Hearth",
    },
    [3] = {
        Level = 3,
        UpgradeCost = 100000,
        WarmthTrainingRate = 30,
        VisualStage = "Iron Brazier",
    },
    [4] = {
        Level = 4,
        UpgradeCost = 500000,
        WarmthTrainingRate = 50,
        VisualStage = "Runic Hearth",
    },
    [5] = {
        Level = 5,
        UpgradeCost = 2000000,
        WarmthTrainingRate = 500,
        VisualStage = "Frostfire Forge",
    },
    [6] = {
        Level = 6,
        UpgradeCost = 10000000,
        WarmthTrainingRate = 1000,
        VisualStage = "Great Runic Furnace",
    },
    -- Lv.7-10 reuse the Lv.6 VisualStage as a placeholder until the world-art pass defines them.
    [7] = {
        Level = 7,
        UpgradeCost = 50000000,
        WarmthTrainingRate = 5000,
        VisualStage = "Great Runic Furnace",
    },
    [8] = {
        Level = 8,
        UpgradeCost = 250000000,
        WarmthTrainingRate = 10000,
        VisualStage = "Great Runic Furnace",
    },
    [9] = {
        Level = 9,
        UpgradeCost = 2000000000,
        WarmthTrainingRate = 50000,
        VisualStage = "Great Runic Furnace",
    },
    [10] = {
        Level = 10,
        UpgradeCost = 10000000000,
        WarmthTrainingRate = 100000,
        VisualStage = "Great Runic Furnace",
    },
}

return HearthConfig
