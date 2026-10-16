local PrototypeConfig = {
    MaxPlayers = 4,
    BaseWalkSpeed = 16,
    PenIncomeIntervalSeconds = 1,
    EquippedCreatureLimit = 1,
    CarriedIceLimit = 1,
    GrabIceMaxDistance = 14,
    GrabIceRequestMinInterval = 0.35,
    DepositIceMaxDistance = 20,
    DepositIceRequestMinInterval = 0.50,
    DropIceRequestMinInterval = 0.50,
    -- After an intentional DropIce the original dropper cannot start a Grab Hold on that same Ice for this long.
    DropIceSelfRegrabLockSeconds = 0.75,
    PenManagementMaxDistance = 25,
    PenManagementRequestMinInterval = 0.25,
    EquipMaxDistance = 25,
    EquipRequestMinInterval = 0.25,
    -- Sell is a small cleanup payout: this many seconds of the species BaseIncomePerSecond, never size-scaled.
    -- Owner-approved Day-14 balance decision (L-D14-T02, 2026-10-13).
    SellValueBaseIncomeSeconds = 10,
    Currency = "Cash",
}

return PrototypeConfig
