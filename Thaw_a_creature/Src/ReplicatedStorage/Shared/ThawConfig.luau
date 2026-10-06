local ThawConfig = {
    PresentationUpdateIntervalSeconds = 0.5,
    ReadyPromptMaxActivationDistance = 18,
    BeginRevealMaxDistance = 18,
    BeginRevealRequestMinInterval = 0.50,
    CrackMaxDistance = 20,
    CrackRequestMinInterval = 0.20,
    VisualStages = {
        Frozen = {
            MinimumProgress = 0,
        },
        Thawing = {
            MinimumProgress = 0.35,
        },
        NearlyReady = {
            MinimumProgress = 0.70,
        },
        Ready = {
            MinimumProgress = 1,
        },
    },
}

return ThawConfig
