# THAW A CREATURE - v1.1 Production Baseline Revision Summary

This revision keeps the approved v1.0 survival/shared-Ice production baseline and adds **rideable Equipped creatures as launch scope**. Every creature can be mounted; when not ridden it keeps follower behavior. The player may Ride/Unride during exploration, and mounted combat is a presentation of the same universal survival attack rather than a new combat progression system.

## Current production checkpoint

- Week 1 prototype validation: **PASS**.
- D7-R13 progression validation: **PASS**.
- Survival Pressure validation: **PASS**.
- The full approved survival package S01-S06 is promoted into launch scope.
- Day 8 persistence foundation: **COMPLETE**.
- Day 9 multiplayer + personal bases: **IN PROGRESS** under concurrent engineering.
- Existing Day-8/Day-9 work is not restarted merely because the canonical documents changed; new requirements are integrated at the smallest safe production boundary.

## Canonical authority after Week 1

Week 1 is now a historical validation artifact rather than the production-behavior authority.

For launch production, use this order:
1. Concise GDD v0.7 - player-facing intent.
2. Launch Technical Implementation Specification v0.7 - production behavior and architecture.
3. Implementation Constants v1.1 - exact first-pass values, content tables, and AI guardrails.
4. Development Plan v1.1 - implementation order, ownership, and gates.
5. Bare-Minimum Prototype Technical Specification v1.0 FINAL - historical Week-1 behavior and validation evidence.

The Prototype Technical Specification remains authoritative for what Week 1 actually validated, but it must not override an explicitly promoted launch rule in the newer production documents.

## Survival Pressure - promoted launch scope

The full validated package is now canonical:

- one universal survival tool with one simple swing verb;
- stationary Frost Sprites with readable telegraph -> attack -> cooldown behavior;
- Guarded Ice encounters across all five geographic Ice tiers;
- Frost Sprite hits reduce `CurrentWarmth`; there is no Player HP;
- region-scaled Frost Sprite Warmth damage;
- session-only Vitality for the currently Equipped creature;
- non-permanent Frosted/Downed state at zero creature Vitality;
- Frosted forces Unride, blocks Ride, removes mounted Speed, and never removes ownership;
- own-Hearth recovery restores creature Vitality and Speed;
- minimal survival feedback;
- breakable route obstacles using the same universal swing verb.

Survival exists to strengthen retrieval. It does **not** create a separate combat-progression game.

Still excluded without a separate later decision:
- Player HP;
- permanent creature death;
- multiple weapons or weapon classes;
- weapon rarity/durability/upgrades/inventory;
- combos/block/heavy attacks/stamina;
- enemy drops/currency/XP/levels;
- bosses;
- roaming/pathfinding/chase enemies;
- autonomous pet combat AI or independent creature combat;
- Wood/Stone/material currencies;
- crafting/recipes/resource farming.

## Mounted Equipped Creatures - approved launch scope

Every creature is mountable at launch. The creature selected through the existing Equip flow remains the single `EquippedCreatureGUID` and has two non-persistent exploration presentation states:

```text
FOLLOWING <-> RIDING
```

Rules:
- Equip/Unequip still occurs at the player's own base/Pen management flow.
- Equipping from Pen clears that Pen slot and the Equipped copy earns no Pen income.
- An Equipped creature starts/rejoins in `FOLLOWING`.
- In `FOLLOWING`, the creature uses the existing lightweight follower behavior and the player moves on foot at base WalkSpeed `16`.
- `Ride` and `Unride` are available during exploration without returning to base, including while carrying Ice.
- In `RIDING`, movement uses that exact copy's `FinalWalkSpeed`.
- Ride/Unride never changes ownership, Pen allocation, income allocation, Ice ownership, or the Equipped GUID.
- `IsRiding` / MountState is runtime-only and is not persisted.
- Every production creature uses its authored `Seat` as the default rider anchor. Optional per-species presentation profiles may improve rider pose, camera, offsets, and animation without adding species-specific traversal powers.
- Frosted/Downed immediately forces Unride, blocks Ride, and leaves the creature logically Equipped. Own-Hearth recovery restores Vitality and allows Riding again.

### Universal survival attack while mounted

The player still learns **one survival attack input**.

```text
FOLLOWING / on foot -> universal tool swing
RIDING             -> Mounted Strike
```

Both use the same gameplay attack:
- same configured damage/effect;
- same cooldown;
- same approved target categories (Frost Sprites and approved breakable route obstacles);
- same server authority and validation;
- no species, rarity, Scale, WeightMultiplier, or Speed damage scaling.

Mounted Strike originates from a server-authoritative ground/front combat origin associated with the mount rather than the rider's hand/Seat height. Effective attack range stays size-independent so a giant Nidhogg is not stronger than a Rabbit. There is no trample/contact damage. Species-specific bites, stomps, kicks, swipes, headbutts, etc. are presentation only. Giant-mount camera/target readability may use scale-aware camera offsets and/or a subtle valid-target marker.

This does **not** authorize autonomous pet combat AI, creature Damage stats, autonomous attacks, creature-specific combat abilities, or a mount-combat progression tree.

## Regional Frost Sprite Warmth damage - approved

| Region | Main Ice | Recommended Warmth | Frost Sprite Warmth Damage / Hit |
|---|---|---:|---:|
| Snowfield | Regular | 100 | **10** |
| Frozen Pass | Thick | 1,000 | **100** |
| Ancient Expanse | Ancient | 10,000 | **1,000** |
| Black Ice Hollow | Black | 100,000 | **10,000** |
| Meteor Reach | Meteor | 1,000,000 | **100,000** |

First-pass rule:

```text
FrostSpriteWarmthDamage = RegionRecommendedWarmth * 0.10
```

Use the authored/configured region value. Do not scale Sprite Warmth damage from the player's current `MaxWarmth`, Ice rarity, Ice size, hidden creature, or Special-Ice flag.

This makes old-region threats naturally become weaker as the player progresses.

## Universal shared-Ice multiplayer contract - approved

Every spawned Ice opportunity is one authoritative server object shared by all players.

This applies to:
- Regular;
- Thick;
- Ancient;
- Black;
- Meteor;
- Special Ice;
- onboarding/tutorial guidance. There are no private per-player Ice copies.

First valid server-side Grab wins.

On carrier failure before deposit - Freeze, character death, Reset Character/respawn, or disconnect - the **exact same Ice** returns to the shared world at the carrier's last valid world position:

```text
same IceInstanceID
same IceType
same hidden CreatureID
same Rarity
same WeightMultiplier
same Scale
same Special metadata, if any
-> OwnerUserID = nil
-> State = Available
-> any player may claim it
```

No reroll occurs on handoff.

If the last carrier position is invalid, use the last valid grounded/safe carrier position. If no valid safe position exists, use the Ice's authored origin as the final fallback.

There is still no intentional `DropIce` action.

Rescue/relay gameplay is allowed: another player may recover a failed carrier's Ice and becomes the depositor if they successfully bring it to their own Pen.

## Great Frost + dropped Ice

- Carried Ice survives Great Frost as before.
- If its carrier fails during the already-running Great Frost transition, the dropped Ice survives that transition and becomes shared/available subject to Grab locking.
- A future Great Frost may remove it if it is still unclaimed.
- Great Frost also clears/rebuilds Guarded-Ice threat encounters with the shared field.

## Onboarding revision

The former private onboarding-Ice exception is removed.

Onboarding may guide a new player to an accessible shared Regular Ice, but it must not create a private or duplicated wilderness Ice opportunity.

If no suitable Regular Ice is currently available, onboarding may communicate/wait for the shared world refresh rather than violating the shared-Ice rule.

## Persistence boundary

Do not persist:
- `CurrentWarmth`;
- carried Ice ownership;
- dropped world-Ice ownership/position;
- Frost Sprite health/target/cooldown state;
- current breakable damage/state;
- universal-tool cooldown;
- current Equipped-creature Vitality;
- current Ride/Unride state (`IsRiding` / MountState);
- mount presentation/seat occupancy state;
- Frosted/Downed state;
- current encounter target.

Persistent creature ownership remains exact `CreatureGUID` copies. Deposited Ice becomes a persistent `ThawItem`; carried/dropped wilderness Ice remains session/world state.

## Current validated 11-creature baseline

| Creature | Rarity | Ref Kg | Base Visual | Base Income/s | Base Speed |
|---|---|---:|---:|---:|---:|
| Penguin | Common | 25 | 1.0000 | 2 | 22 |
| Rabbit | Common | 4 | 1.0000 | 2 | 26 |
| Seal | Common | 180 | 1.0000 | 3 | 20 |
| Wolf | Uncommon | 65 | 1.0000 | 5 | 31 |
| Bear | Uncommon | 500 | 1.0000 | 7 | 26 |
| Mammoth | Rare | 6,000 | 1.4373 | 15 | 30 |
| Sleipnir | Rare | 900 | 1.4798 | 10 | 39 |
| Troll | Epic | 1,200 | 1.4798 | 24 | 35 |
| IceSerpent | Epic | 3,000 | 2.2605 | 20 | 44 |
| Hraesvlgr | Legendary | 5,000 | 1.7404 | 32 | 50 |
| Nidhogg | Legendary | 8,000 | 2.1523 | 40 | 46 |

The 16-species launch quantity target may still be pursued, but the remaining five species/content assignments require explicit later approval rather than resurrecting stale placeholder mappings.

## Current functional Ice pools - 11-creature baseline

Rarity weights are ordered `Common / Uncommon / Rare / Epic / Legendary`.

| Ice | Weights | Eligible creatures |
|---|---|---|
| Regular | `74 / 23 / 3 / 0 / 0` | C: Penguin, Rabbit, Seal; U: Wolf, Bear; R: Mammoth |
| Thick | `30 / 35 / 25 / 10 / 0` | C: Seal; U: Wolf, Bear; R: Mammoth, Sleipnir; E: Troll |
| Ancient | `0 / 30 / 45 / 25 / 0` | U: Bear; R: Mammoth, Sleipnir; E: Troll, IceSerpent |
| Black | `0 / 10 / 35 / 40 / 15` | U: Wolf; R: Mammoth, Sleipnir; E: Troll, IceSerpent; L: Hraesvlgr |
| Meteor | `0 / 0 / 20 / 55 / 25` | R: Mammoth, Sleipnir; E: Troll, IceSerpent; L: Hraesvlgr, Nidhogg |

Unlock ladder:
- Regular: core baseline;
- Thick: adds Sleipnir + Troll;
- Ancient: adds IceSerpent;
- Black: adds Hraesvlgr / first Legendary;
- Meteor: adds Nidhogg.

## Current progression constants retained

| Region | Main Ice | Recommended Warmth | Cold Multiplier |
|---|---|---:|---:|
| Snowfield | Regular | 100 | 1x |
| Frozen Pass | Thick | 1,000 | 10x |
| Ancient Expanse | Ancient | 10,000 | 100x |
| Black Ice Hollow | Black | 100,000 | 1,000x |
| Meteor Reach | Meteor | 1,000,000 | 10,000x |

Core Warmth values:
- Starting MaxWarmth: `100`;
- Base wilderness drain: `4/sec`;
- Carry multiplier: `2.00x`;
- Hearth refill: `50% of MaxWarmth/sec`;
- Low warning: `35%`;
- Critical warning: `15%`.

## Documentation versions in this baseline

- `00_Thaw_A_Creature_v1.1_Revision_Summary.md`
- `01_Thaw_A_Creature_Concise_GDD_Canonical_v0.7.md`
- `02_Thaw_A_Creature_Technical_Implementation_3Week_v0.7.md`
- `03_Thaw_A_Creature_Bare_Minimum_Prototype_Technical_v1.0_FINAL.md`
- `04_Thaw_A_Creature_Development_Plan_Canonical_v1.1.md`
- `05_Thaw_A_Creature_Implementation_Constants_Canonical_v1.1.md`
- `Thaw_A_Creature_Development_Handoff_v1.1.md`


## v1.1 production note

The Week-1 Prototype Technical Specification remains **v1.0 FINAL** and is intentionally not rewritten to pretend mounts were validated in Week 1. Mounting is a post-prototype launch-production decision governed by the v0.7/v1.1 production documents.
