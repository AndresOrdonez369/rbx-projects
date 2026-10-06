local HearthConfig = {
    UpgradeMaxDistance = 20,
    UpgradeRequestMinInterval = 0.50,
    [1] = {
        Level = 1,
        UpgradeCost = 0,
        WarmthTrainingRate = 10,
        VisualStage = "Small Hearth",
    },
    [2] = {
        Level = 2,
        UpgradeCost = 150,
        WarmthTrainingRate = 50,
        VisualStage = "Strong Hearth",
    },
    [3] = {
        Level = 3,
        UpgradeCost = 1000,
        WarmthTrainingRate = 250,
        VisualStage = "Iron Brazier",
    },
    [4] = {
        Level = 4,
        UpgradeCost = 7500,
        WarmthTrainingRate = 1250,
        VisualStage = "Runic Hearth",
    },
    [5] = {
        Level = 5,
        UpgradeCost = 60000,
        WarmthTrainingRate = 6250,
        VisualStage = "Frostfire Forge",
    },
    [6] = {
        Level = 6,
        UpgradeCost = 500000,
        WarmthTrainingRate = 31250,
        VisualStage = "Great Runic Furnace",
    },
}

return HearthConfig
