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
    PenManagementMaxDistance = 25,
    PenManagementRequestMinInterval = 0.25,
    EquipMaxDistance = 25,
    EquipRequestMinInterval = 0.25,
    -- Sell is a small cleanup payout: this many seconds of the species BaseIncomePerSecond, never size-scaled.
    SellValueBaseIncomeSeconds = 10,
    Currency = "Cash",
}

return PrototypeConfig
