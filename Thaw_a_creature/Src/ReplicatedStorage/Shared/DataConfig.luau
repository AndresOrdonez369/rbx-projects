local DataConfig = {
    DataStoreName = "PlayerData",
    KeyPrefix = "Player_",
    DataVersion = 2,
    AutosaveIntervalSeconds = 60,
    SaveRetryAttempts = 3,
    RetryBackoffSeconds = { 1, 2, 4 },
    -- A session lock not refreshed for this long belongs to a crashed server and may be taken over.
    SessionLockStaleSeconds = 180,
}

return DataConfig
