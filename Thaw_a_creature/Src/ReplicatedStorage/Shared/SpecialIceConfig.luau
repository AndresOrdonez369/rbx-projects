-- Special Ice modifies a normal Ice Type and keeps that type's region-exclusive creature pool.
local SpecialIceConfig = {
    TypeWeights = {
        { IceType = "Ancient", Weight = 50 },
        { IceType = "Black", Weight = 30 },
        { IceType = "Meteor", Weight = 20 },
    },
    RarityWeightsByIceType = {
        Ancient = {
            Common = 0,
            Uncommon = 0,
            Rare = 90,
            Epic = 0,
            Legendary = 10,
        },
        Black = {
            Common = 0,
            Uncommon = 0,
            Rare = 90,
            Epic = 0,
            Legendary = 10,
        },
        Meteor = {
            Common = 0,
            Uncommon = 0,
            Rare = 90,
            Epic = 0,
            Legendary = 10,
        },
    },
    -- Pre-reveal silhouette shared by every Special Ice of a type, so the outline cannot separate its
    -- Rare result from its Legendary one. Types left out already share one profile across their results.
    SilhouetteProfileByIceType = {
        Meteor = "MythicUnknown",
    },
}

return SpecialIceConfig
