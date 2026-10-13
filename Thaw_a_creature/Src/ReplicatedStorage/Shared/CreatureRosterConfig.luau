local CreatureRosterConfig = {
    RarityOrder = {
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
    },
    -- Approved v1.2 launch roster: 20 species, four signature creatures per region.
    CreatureIDsByRarity = {
        Common = { "Penguin", "Rabbit", "Seal", "WhiteStag", "Sabertooth", "GiantSpider", "Griffin" },
        Uncommon = { "Wolf", "Bear", "Dreadmare" },
        Rare = { "Mammoth", "Sleipnir", "Manticore", "Kirin" },
        Epic = { "Troll", "IceSerpent", "Phoenix" },
        Legendary = { "Hraesvlgr", "Nidhogg", "Tyrannosaurus" },
    },
}

return CreatureRosterConfig
