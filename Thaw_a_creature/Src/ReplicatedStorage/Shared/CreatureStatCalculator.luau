local CreatureConfig = require(script.Parent.CreatureConfig)
local SizeConfig = require(script.Parent.SizeConfig)

export type CreatureCopyStats = {
    Scale: number,
    FinalIncome: number,
    FinalWalkSpeed: number,
}

local CreatureStatCalculator = {}

local SPEED_SCALE_FACTOR = 0.15

local function isFinitePositiveNumber(value: any): boolean
    return type(value) == "number"
        and value == value
        and value > 0
        and value < math.huge
end

function CreatureStatCalculator.Derive(
    creatureID: string,
    weightMultiplier: number
): CreatureCopyStats
    assert(type(creatureID) == "string" and creatureID ~= "", "CreatureID must be a non-empty string")

    local species = CreatureConfig[creatureID]
    assert(species, string.format("CreatureID %s is not configured", creatureID))
    assert(
        isFinitePositiveNumber(weightMultiplier),
        string.format("CreatureID %s WeightMultiplier must be finite and positive", creatureID)
    )
    assert(
        isFinitePositiveNumber(species.BaseIncomePerSecond),
        string.format("CreatureConfig.%s.BaseIncomePerSecond must be finite and positive", creatureID)
    )
    assert(
        isFinitePositiveNumber(species.BaseWalkSpeed),
        string.format("CreatureConfig.%s.BaseWalkSpeed must be finite and positive", creatureID)
    )

    local scale = SizeConfig.GetVisualScale(weightMultiplier)
    assert(
        isFinitePositiveNumber(scale),
        string.format("CreatureID %s derived Scale must be finite and positive", creatureID)
    )

    local finalIncome = math.max(1, math.round(species.BaseIncomePerSecond * scale ^ 2))
    local speedMultiplier = 1 + SPEED_SCALE_FACTOR * (scale - 1)
    local finalWalkSpeed = species.BaseWalkSpeed * speedMultiplier

    assert(
        isFinitePositiveNumber(finalIncome) and finalIncome % 1 == 0,
        string.format("CreatureID %s derived FinalIncome must be a finite positive integer", creatureID)
    )
    assert(
        isFinitePositiveNumber(finalWalkSpeed),
        string.format("CreatureID %s derived FinalWalkSpeed must be finite and positive", creatureID)
    )

    return {
        Scale = scale,
        FinalIncome = finalIncome,
        FinalWalkSpeed = finalWalkSpeed,
    }
end

return CreatureStatCalculator
