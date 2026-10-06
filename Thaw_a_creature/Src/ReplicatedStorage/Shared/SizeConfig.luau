local MIN_VISUAL_SCALE = 0.75
local MAX_VISUAL_SCALE = 5.00
local CONFIG_EPSILON = 0.000001
local SCALE_WEIGHT_TOLERANCE = 0.002

local function isFiniteNumber(value: any): boolean
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

local function getVisualScale(weightMultiplier: number): number
    assert(
        isFiniteNumber(weightMultiplier) and weightMultiplier > 0,
        "WeightMultiplier must be a finite positive number"
    )

    local scale = weightMultiplier ^ (1 / 3)
    assert(
        scale >= MIN_VISUAL_SCALE - CONFIG_EPSILON
            and scale <= MAX_VISUAL_SCALE + CONFIG_EPSILON,
        string.format("WeightMultiplier %s derives unsupported visual Scale %s", weightMultiplier, scale)
    )

    return scale
end

local SizeConfig = {
    MinVisualScale = MIN_VISUAL_SCALE,
    MaxVisualScale = MAX_VISUAL_SCALE,
    WithinBandBiasExponent = 2,
    SizeBands = {
        {
            Name = "Small",
            Chance = 0.08,
            MinVisualScale = 0.75,
            MaxVisualScale = 0.95,
            MinWeightMultiplier = 0.422,
            MaxWeightMultiplier = 0.857,
        },
        {
            Name = "Normal",
            Chance = 0.72,
            MinVisualScale = 0.95,
            MaxVisualScale = 1.25,
            MinWeightMultiplier = 0.857,
            MaxWeightMultiplier = 1.953,
        },
        {
            Name = "Large",
            Chance = 0.15,
            MinVisualScale = 1.25,
            MaxVisualScale = 1.75,
            MinWeightMultiplier = 1.953,
            MaxWeightMultiplier = 5.359,
        },
        {
            Name = "Huge",
            Chance = 0.04,
            MinVisualScale = 1.75,
            MaxVisualScale = 2.50,
            MinWeightMultiplier = 5.359,
            MaxWeightMultiplier = 15.625,
        },
        {
            Name = "Colossal",
            Chance = 0.009,
            MinVisualScale = 2.50,
            MaxVisualScale = 3.50,
            MinWeightMultiplier = 15.625,
            MaxWeightMultiplier = 42.875,
        },
        {
            Name = "Absurd",
            Chance = 0.001,
            MinVisualScale = 3.50,
            MaxVisualScale = 5.00,
            MinWeightMultiplier = 42.875,
            MaxWeightMultiplier = 125.000,
        },
    },
    GetVisualScale = getVisualScale,
}

local function validateConfig(): ()
    assert(
        isFiniteNumber(SizeConfig.MinVisualScale)
            and isFiniteNumber(SizeConfig.MaxVisualScale)
            and SizeConfig.MinVisualScale > 0
            and SizeConfig.MinVisualScale <= SizeConfig.MaxVisualScale,
        "SizeConfig visual Scale bounds must be finite, positive, and ordered"
    )
    assert(
        isFiniteNumber(SizeConfig.WithinBandBiasExponent) and SizeConfig.WithinBandBiasExponent > 0,
        "SizeConfig.WithinBandBiasExponent must be finite and positive"
    )
    assert(#SizeConfig.SizeBands > 0, "SizeConfig must define at least one size band")

    local totalChance = 0
    local previousBand = nil

    for index, band in SizeConfig.SizeBands do
        assert(type(band.Name) == "string" and band.Name ~= "", string.format("Size band %d must have a name", index))
        assert(
            isFiniteNumber(band.Chance) and band.Chance >= 0,
            string.format("Size band %s Chance must be finite and non-negative", band.Name)
        )
        assert(
            isFiniteNumber(band.MinWeightMultiplier)
                and isFiniteNumber(band.MaxWeightMultiplier)
                and band.MinWeightMultiplier > 0
                and band.MinWeightMultiplier <= band.MaxWeightMultiplier,
            string.format("Size band %s WeightMultiplier bounds must be finite, positive, and ordered", band.Name)
        )
        assert(
            isFiniteNumber(band.MinVisualScale)
                and isFiniteNumber(band.MaxVisualScale)
                and band.MinVisualScale >= SizeConfig.MinVisualScale
                and band.MinVisualScale <= band.MaxVisualScale
                and band.MaxVisualScale <= SizeConfig.MaxVisualScale,
            string.format("Size band %s visual Scale bounds are invalid", band.Name)
        )

        local derivedMinScale = getVisualScale(band.MinWeightMultiplier)
        local derivedMaxScale = getVisualScale(band.MaxWeightMultiplier)
        assert(
            math.abs(derivedMinScale - band.MinVisualScale) <= SCALE_WEIGHT_TOLERANCE
                and math.abs(derivedMaxScale - band.MaxVisualScale) <= SCALE_WEIGHT_TOLERANCE,
            string.format("Size band %s WeightMultiplier bounds do not match its visual Scale bounds", band.Name)
        )

        if previousBand then
            assert(
                band.MinVisualScale >= previousBand.MaxVisualScale - CONFIG_EPSILON
                    and band.MinWeightMultiplier >= previousBand.MaxWeightMultiplier - CONFIG_EPSILON,
                string.format("Size band %s is out of order", band.Name)
            )
        end

        totalChance += band.Chance
        previousBand = band
    end

    assert(
        math.abs(totalChance - 1) <= CONFIG_EPSILON,
        string.format("SizeConfig band chances must total 1.0, got %.9f", totalChance)
    )
end

validateConfig()

return SizeConfig
