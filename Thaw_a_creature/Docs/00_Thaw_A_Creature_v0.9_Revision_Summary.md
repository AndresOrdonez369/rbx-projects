# THAW A CREATURE - v0.5 / v0.9 Revision Summary

This pack promotes the post-Day-5 design revision to canonical documentation.

## Locked structural changes

- One server-authoritative Ice `WeightMultiplier` is rolled at wilderness spawn.
- `Scale = cbrt(ActualWeight / ReferenceWeight) = cbrt(WeightMultiplier)`.
- The exact size roll survives wilderness -> carry -> thaw -> reveal -> creature copy.
- Visual Scale supports approximately `0.75x` to `5.0x`.
- Rare `3.5x-5.0x` results are intentional jackpot/social-trophy events.
- Creature ownership becomes per-copy using `CreatureGUID`.
- Species baseline Income/Speed and copy-Scale stat formulas are configured
  targets; D6-R06 activates them.
- D6-R06 target: `FinalIncome = round(BaseIncomePerSecond * Scale^2)`.
- D6-R06 target: `SpeedMultiplier = 1 + 0.15 * (Scale - 1)`.
- Pen income remains one aggregate server payment every 1 second.
- Warmth becomes big-number uncapped progression.
- Recommended Warmth grows by orders of magnitude and remains guidance only.
- Regions use cold multipliers so large Warmth numbers remain meaningful without requiring an enormous physical map.
- Hearth keeps the same function but receives dramatically stronger progression rates and presentation.
- Day 6-7 are implementation days with continuous task-level sanity testing.
- All 11 already-finished creature meshes should be used; do not recreate the old eight-blockout target.

## First-pass size bands

| Band | Chance | Visual Scale |
|---|---:|---:|
| Small | 8.0% | 0.75-0.95x |
| Normal | 72.0% | 0.95-1.25x |
| Large | 15.0% | 1.25-1.75x |
| Huge | 4.0% | 1.75-2.50x |
| Colossal | 0.9% | 2.50-3.50x |
| Absurd | 0.1% | 3.50-5.00x |

Within each band, the weight roll is biased toward the lower bound so a result near 5x remains exceptionally rare.

## First-pass big-number progression

| Region | Main Ice | Recommended Warmth | Cold Multiplier |
|---|---|---:|---:|
| Snowfield | Regular | 100 | 1x |
| Frozen Pass | Thick | 1,000 | 10x |
| Ancient Expanse | Ancient | 10,000 | 100x |
| Black Ice Hollow | Black | 100,000 | 1,000x |
| Meteor Reach | Meteor | 1,000,000 | 10,000x |

Prototype Hearth expansion:

| Hearth Level | Cost | Training Rate |
|---|---:|---:|
| 1 | Start | +10 Warmth/sec |
| 2 | $150 | +50/sec |
| 3 | $1,000 | +250/sec |
| 4 | $7,500 | +1,250/sec |
| 5 | $60,000 | +6,250/sec |
| 6 | $500,000 | +31,250/sec |

## D6-R05 Prototype Result

`D6-R05 - Configure All 11 Existing Creatures` is complete. The current
Week-1 prototype roster is 11 species: Common — Penguin, Rabbit, Seal;
Uncommon — Wolf, Bear; Rare — Mammoth, Sleipnir; Epic — Troll, IceSerpent;
Legendary — Hraesvlgr, Nidhogg. Epic and Legendary are active prototype
content.

Current prototype pools are Regular `74/23/3/0/0` and Thick `30/32/24/11/3`.
Sleipnir, IceSerpent, and Hraesvlgr are configured and runtime-verified
against the live Studio models. This is a Week-1 prototype result and does not
automatically revise the separate launch roster.

## Next implementation task

`D6-R06 - Size-Based Income + Speed`
