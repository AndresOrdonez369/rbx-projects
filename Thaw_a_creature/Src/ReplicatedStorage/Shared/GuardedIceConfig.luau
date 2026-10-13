local PrototypeConfig = {
    GuardianMarkerFolderName = "GuardianMarkers",
    ProfilesBySpawnPointID = {
        ["Regular/Spawn04"] = {
            ProfileName = "LightGuardedRegular",
            IceType = "Regular",
            SpawnMarkerName = "Spawn04",
            GuardianCount = 1,
        },
        ["Thick/Spawn03"] = {
            ProfileName = "MediumGuardedThick",
            IceType = "Thick",
            SpawnMarkerName = "Spawn03",
            GuardianCount = 2,
        },
        ["Thick/Spawn04"] = {
            ProfileName = "HeavyGuardedThick",
            IceType = "Thick",
            SpawnMarkerName = "Spawn04",
            GuardianCount = 3,
        },
        -- First-pass placeholder encounters proving every geographic tier supports Guarded Ice.
        ["Ancient/Spawn03"] = {
            ProfileName = "LightGuardedAncient",
            IceType = "Ancient",
            SpawnMarkerName = "Spawn03",
            GuardianCount = 1,
        },
        ["Black/Spawn02"] = {
            ProfileName = "LightGuardedBlack",
            IceType = "Black",
            SpawnMarkerName = "Spawn02",
            GuardianCount = 1,
        },
        ["Meteor/Spawn03"] = {
            ProfileName = "LightGuardedMeteor",
            IceType = "Meteor",
            SpawnMarkerName = "Spawn03",
            GuardianCount = 1,
        },
    },
}

return PrototypeConfig
