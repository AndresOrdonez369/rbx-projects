# THAW A CREATURE

## Implementation Constants & Content Configuration - Canonical v1.1

**Purpose:** Exact first-pass values, content tables, implementation constraints, and AI guardrails  
**Design Source:** Concise GDD v0.7  
**Prototype Source:** Bare-Minimum Prototype Technical Specification v1.0 FINAL  
**Launch Source:** Technical Implementation Specification v0.7  
**Development Source:** Development Plan v1.1  
**Status:** Numerical values are first-pass balancing values unless explicitly structural  

### Revision notes

- Adds all-creature launch mounts with runtime Following/Riding states.
- Locks base WalkSpeed while Following and copy-specific `FinalWalkSpeed` while Riding.
- Adds non-persistent mount state and authored Seat/default rider-anchor rules.
- Adds one universal Mounted Strike that shares attack values with the on-foot survival tool and cannot scale from creature species/rarity/size/speed.

- Records Week-1/D7-R13 PASS and Survival Pressure PASS/full promotion.
- Replaces experiment-only Survival Pressure constants with first-pass canonical production constants.
- Adds regional Frost Sprite Warmth damage `10 / 100 / 1,000 / 10,000 / 100,000` across the five progression regions.
- Locks one shared authoritative Ice field for all players and removes private onboarding-Ice configuration.
- Adds exact-Ice carrier-failure release/rescue rules for Freeze, death, reset/respawn, and disconnect.
- Preserves hidden reward + WeightMultiplier/Scale across multiplayer handoff without reroll.
- Updates the current validated 11-creature base stats and five functional Ice pools.
- Updates persistence boundaries for session-only survival state.
- Marks the remaining five species needed to reach the 16-creature launch quantity as explicit future content decisions rather than stale placeholders.

## 1. Document Authority

For launch production after the successful Week-1 gate:
1. Concise GDD v0.7 - player-facing intent.
2. Launch Technical Implementation Specification v0.7 - production behavior/architecture.
3. This Constants v1.1 - exact first-pass values/content configuration and AI guardrails.
4. Development Plan v1.1 - implementation order/gates.
5. Prototype Technical Specification v1.0 FINAL - historical Week-1 validation evidence.

If a value in this document conflicts with an older document version, this v1.1 value supersedes it unless the higher-authority current document explicitly says otherwise.

## 2. General Implementation Rule

All tunable gameplay values should live in configuration modules rather than being scattered
through service/controller code.
When implementing from this document:

Do not invent missing mechanics.
If a number is not specified:
1. preserve the documented system;
2. choose the smallest safe technical implementation;
3. flag meaningful gameplay ambiguity;
4. do not create a new progression system to solve it.


## 3. AI IMPLEMENTATION CONSIDERATIONS

This section exists specifically to prevent ChatGPT, Claude, or another implementation assistant
from making reasonable-looking assumptions that conflict with intentional design decisions.
These rules apply to all implementation tasks.


3.1 Do Not Infer Missing Gameplay Design
An AI must distinguish between four cases.
Specified Behavior
Example:

Carrying Ice increases Warmth drain.
Implement exactly as documented.

Configurable Value
Example:

CarryDrainMultiplier = 1.75.
Use the current canonical value unless the task is specifically a balance change.

Unspecified Technical Detail
Example:

exact internal helper function names.

Choose the smallest clean implementation that preserves documented behavior.
No clarification is normally required.


Unspecified Gameplay Behavior
Example:

whether players should be allowed to intentionally drop carried Ice.
Do not invent the answer.
Flag the ambiguity before introducing that behavior.


3.2 Do Not Use Genre Conventions to Fill Design Gaps
Do not assume that because another Roblox simulator commonly uses a mechanic, Thaw A
Creature should also use it.
Examples of prohibited assumptions:

"Warmth probably needs a maximum cap."

"Pets probably need multiple stats."

"There should probably be Thaw Slots."

"Night probably makes the wilderness more dangerous."

"Carrying a large Ice should probably slow the player."

"Special Ice should probably guarantee Legendary."

"Recommended Warmth probably means required Warmth."
All of those conflict with intentional decisions in the current design.


3.3 Never "Improve" Gameplay Design Without Approval
An AI implementation assistant must not independently:
add mechanics;

remove mechanics;
combine progression systems;
split progression systems;
normalize intentionally exaggerated values;
add monetization;
add convenience features;
add conventional simulator systems;
because they seem:
cleaner;
more scalable;
more balanced;
more familiar;
more monetizable;
more realistic.
Implementation and game-design revision are separate tasks.


3.4 Preserve System Responsibilities
The following division is intentional.
MaxWarmth

Expedition endurance.
Determines how long the player can survive away from safety.

Hearth

MaxWarmth training speed.
A stronger Hearth does not define the player's maximum Warmth.

Equipped Creature

Traversal creature. While Following, the player remains at base WalkSpeed. While Riding, a stronger individual creature lets the player use Warmth more efficiently by crossing distance faster.

Pen Creature

Passive Cash generation.
A creature assigned to the Pen earns income.
An Equipped creature does not simultaneously earn Pen income.


Ice

Mystery + retrieval opportunity.
The player sees something desirable before knowing the exact result.

Thawing

Anticipation + real-time progression.
It does not become a tapping or skill system.

Great Frost

World refresh + online thaw acceleration + recurring spectacle + Special
Ice cadence.
It is not primarily a punishment system.
Do not merge these responsibilities unless an explicit design revision says to.


3.5 No Hidden Progression Gates
RecommendedWarmth means:

player guidance.
It does not mean:

entry requirement.
Never implement:
```text
               1 if player.MaxWarmth < region.RecommendedWarmth then
```


```text
            2     denyEntry()
            3 end
```


Players may attempt any region.
Practical viability creates progression pressure.
Permission does not.


3.6 Unlimited Means Unlimited at the Gameplay Level
The following are intentionally uncapped:

MaxWarmth
and:

logical ThawingIce count
Do not derive gameplay caps from:
Hearth Level;
UI capacity;
display anchors;
Pen geometry;
implementation convenience;
model limits.
Technical safety limits may exist only as exploit/performance protection.
They must not function as normal progression.


3.7 Visual Structures Are Not Automatically Gameplay Structures
Examples:

12 Ice display positions != maximum 12 thawing Ice.

Region Parts != locked zones.

Four Pen creature anchors != four total owned creatures.

Candidate Ice spawn points != fixed spawn order.

Five Hearth visual models != five mechanical Hearth levels.
Do not infer gameplay rules from Workspace hierarchy or presentation assets.


3.8 Hidden Reward Information Must Remain Hidden
Before final reveal, the exact reward must not be deliberately exposed to the client unless
required by an approved presentation system.
Server-only reward data includes:
CreatureID;
exact rarity;
reward value.
Client-safe information may include:
Ice Type;
approved silhouette profile;
thaw percentage;
visual thaw stage;
approved rarity foreshadow effect.
Do not accidentally expose hidden outcomes through:
replicated object names;
obvious Attributes;
UI text;
model names;
client-readable config records;
different timers based on rarity.


3.9 Thaw Completion Is Not Creature Completion
When:
```text
           1 ThawProgress >= 100%
```


the Ice becomes:

**READY TO CRACK**
It does not automatically grant the creature.
Creature acquisition occurs only after:

**CRACK -> CRACK -> SMASH**
and successful server resolution of the final interaction.


3.10 Offline Progress Rule
The Week-1 prototype has no persistence, so offline progress is not evaluated there.

For launch, offline players receive normal real-time thaw progress. They do not receive historical one-time launch Great Frost Thaw Surges that occurred while they were absent. Do not calculate:

number of missed Great Frosts x launch Thaw Surge

on rejoin.

The intended launch distinction is:

offline = still useful

online = better

3.11 Great Frost Reset Rule
At Great Frost:
Reset
available/unclaimed wilderness Ice.
Preserve
carried Ice;
Pen Ice;
unfinished thawing Ice;
Ready Ice;

creatures;
player progression.

Apply the currently configured Great Frost thaw acceleration without inventing extra penalties.

Prototype override:
- Day thaw rate = `1x`;
- Great Frost thaw rate = `10x`;
- the multiplier applies only for each ThawItem's real-time overlap with the active Frost interval, including Ice deposited during Frost;
- Day resumes at `1x`;
- Frost-earned progress is preserved.

Launch behavior remains the one-time percentage-based Thaw Surge defined in Section 32 until a later launch design revision explicitly promotes the prototype multiplier.


3.12 Great Frost Is Opportunity, Not Punishment
Great Frost should not automatically:
kill the player;
reduce Warmth;
teleport the player;
destroy carried Ice;
require shelter;
turn the world into a generic enemy wave;
apply a survival debuff.
Its current launch role is:

refresh opportunities + accelerate thawing + occasionally create Special
Ice + deliver spectacle.

Canonical survival integration:
Great Frost clears/rebuilds authored Guarded-Ice encounters and configured breakable-route state together with the shared wilderness field.
This still does not make Great Frost itself a punishment or enemy-wave phase.

3.13 Speed Progression Is Intentionally Large
Do not normalize:

16 -> 20 -> 24 -> 28 -> 32
into conservative increments merely because they look large.
The player should visibly feel:

"I am much faster now."
This is a core progression fantasy.
Balance testing may later change the numbers.
Implementation should not preemptively weaken them.

3.14 Carrying Ice Does Not Slow Movement
The cost of carrying Ice is:

increased Warmth drain.
Do not also automatically apply:
WalkSpeed reduction;
jump reduction;
stamina penalty;
heavier controls.
Doing so would overlap the intended risk system.


3.15 Creature Stats Must Remain Simple
Creature copies may differ because of their inherited size lineage.

Approved per-copy variation is limited to one inherited size roll from the originating Ice:
- `WeightMultiplier`;
- derived `Scale`;
- derived `FinalIncome`;
- derived `FinalWalkSpeed`.

These are all consequences of the same inherited `WeightMultiplier`.
There is no independent random roll for Income or Speed.

Do not add unless a future explicit design revision approves them:
- random independent Income rolls;
- random independent Speed rolls;
- Warmth bonus;
- Luck;
- Damage;
- Defense;
- levels;
- XP;
- affixes;
- traits;
- skills;
- stamina;
- carrying capacity;
- random stat points;
- traversal abilities;
- additional pet-stat systems;
- rarity multipliers beyond configured systems.

Design principle:

> Creature copies may differ because of their inherited size lineage. Do not turn creatures into generic randomized-stat RPG pets.

Canonical survival/mount exception:
The currently Equipped creature may have temporary session-only `CreatureVitality` plus a boolean Frosted/Downed state. Every creature is mountable, but this does not add creature Damage/Defense/levels or autonomous combat. Mounted Strike is the player's universal survival attack presented through the mount and uses the same attack values as the on-foot tool.


3.16 Special Ice Does Not Automatically Mean Legendary
Special Ice means:

high-value opportunity with elevated rarity.

Use the configured Special Ice rarity tables.
Do not replace them with:
```text
           1 SpecialIce = GuaranteedLegendary
```


unless a future design change explicitly says so.


3.17 Do Not Add Convenience Systems Without Approval
Do not independently introduce:
teleport home;
sprint;
dash;
auto-sell;
auto-thaw;
auto-open;
extra Ice storage;
raw-Ice backpack;
fast travel;
pet storage upgrades;
Luck;
quests;
rebirth;
Daily rewards.
A convenience mechanic may accidentally bypass the game's intended friction.


3.18 Protect the USP
Before implementing any inferred behavior, ask whether it weakens one of these three
experiences:

I saw something I desperately wanted.

I barely managed to bring it home.

I couldn't wait to discover what was inside.
If it does:

do not implement it without explicit approval.

3.19 Protect the Five Hero Moments
Implementation decisions must not accidentally undermine:
1. First Great Frost.
2. Impossible-Looking Ice.
3. Barely-Made-It-Home.
4. Legendary Smash.
5. Becoming the Endgame Player.
Examples:
Teleporting home while carrying
Damages Hero #3.
Automatically granting a completed thaw reward
Damages Hero #4.
Weak Speed differences
Damages Hero #5.
Hiding future regions completely
Damages Hero #2.
Treating Great Frost as a minor UI timer
Damages Hero #1.


3.20 Configuration Is Not Permission to Rebalance
A number being stored in config means:

it should be easy for the designer to change.
It does not mean the implementation assistant may change it during an unrelated task.

Unless the current task is specifically balancing:

use the canonical value.

3.21 Do Not Resolve Document Contradictions Silently
If canonical documents appear to conflict:
1. identify the conflicting instructions;
2. apply the Document Authority order where the resolution is clear;
3. if meaningful ambiguity remains, stop and flag it;
4. do not silently invent a hybrid rule.


3.22 Prototype Overrides Are Not Launch Design Changes
Prototype constants intentionally compress:
thaw times;
Great Frost timing;
Hearth progression;
content.
These are testing overrides.
Do not copy them into launch merely because they already exist in code.
The architecture should support:
```text
            1 PrototypeConfig
```


versus:
```text
            1 LaunchConfig
```


or equivalent clean configuration separation.


3.23 Prototype Omission Does Not Mean Launch Removal
If a launch mechanic is missing from the Week-1 prototype, that means:

not required for prototype validation
not:

removed from the game.
Examples historically included persistence, offline thawing, multiplayer, and production world-cycle behavior.
Those systems are now production work and must follow the current Launch Technical Specification rather than assumptions derived from Week-1 omissions.


3.24 Smallest Robust Implementation
When a purely technical choice is unspecified:

implement the smallest robust solution that preserves the current architecture.
Avoid speculative infrastructure such as:
generalized ability framework;
quest framework;
universal stat framework;
complex item framework;
generic combat framework;
external framework dependency;
unless current requirements actually need it.


3.25 AI Ambiguity Protocol
If an implementation task encounters an unspecified decision, classify it.
Purely Technical and Behavior-Preserving
Proceed.
Example:

helper module naming.

Tunable Number Already Represented by Existing Config
Use the current config/default.


Player-Facing Gameplay Consequence
Do not assume.
Flag it.
Examples:
introducing a new failure penalty;
adding trading;
adding paid progression modifiers;
auto-routing behavior not specified anywhere;
any new player-facing shortcut that bypasses retrieval risk.

3.26 Resolved Player-Facing Edge Decisions
The following questions are no longer ambiguous.

Intentional raw-Ice drop
Not available.
A carry ends through Pen deposit or documented Freeze/death/reset/respawn/disconnect handling.

Universal shared Ice
Every spawned wilderness Ice is one authoritative shared server object.
No private/per-player copies.
First valid server-side Grab wins.

Carrier failure
Freeze, character death, Reset Character/respawn, or disconnect releases the exact carried Ice at the last valid safe position.
Ownership clears; any player may rescue it.
No reward/rarity/WeightMultiplier/Scale reroll.

Freeze / normal respawn recovery
Return to own base and set CurrentWarmth = MaxWarmth immediately.
Restore the currently Equipped creature from Frosted/Downed.
Permanent progression is preserved.

Launch base topology
Up to four personal plots are grouped side-by-side along one shared home-camp edge.
All plots face the same primary wilderness direction.

Visitor Hearth behavior
Another player's WarmZone does not refill CurrentWarmth, train MaxWarmth, or restore the visitor's creature Vitality.

Onboarding
No private onboarding Ice.
Guide/retarget eligible new players toward available shared Regular Ice; if none exists, communicate the next shared refresh.

Special Ice lifecycle
Special Ice follows the universal shared-Ice failure rule.
On carrier failure it drops at the last valid safe position with exact reward/size/Special metadata preserved.
A later Great Frost may remove it if still unclaimed.

Great Frost server boot
Boot during Day: populate current field immediately.
Boot during Great Frost: wait until next Day.
Do not retroactively award the launch Thaw Surge or Special Ice from a Frost transition the server did not observe.


3.27 Canonical Survival Pressure Scope
The Week-1 experiment passed and its full approved subset is launch-canonical:
- one universal swing tool;
- stationary Frost Sprites;
- Guarded Ice across all five geographic tiers;
- player damage as CurrentWarmth loss;
- regional Sprite Warmth damage;
- session-only Equipped-creature Vitality/Frosted;
- minimal survival UI/feedback;
- breakable route obstacles.

This does not approve Player HP, permanent creature loss, autonomous pet combat AI, permanent combat stats, multiple weapons, weapon progression, enemy loot/XP/currency/levels, roaming/pathfinding enemies, bosses, material currencies, crafting, or generalized combat/item/resource frameworks.


3.28 Survival Is Not Permission to Expand Genre Scope
The presence of canonical Sprites/tool/Vitality/breakables is evidence only for the approved retrieval-pressure package.
If a requested implementation changes combat progression, rewards, enemy role, permanent creature stats, resource economy, or player survival model, flag it as a new design decision before implementation.

## 4. Deprecated Rules - DO NOT IMPLEMENT

The following belong to older versions of the design and are no longer canonical:
NO: Warmth Lv.1-10 as the player's progression stat.
NO: Fixed Warmth capacity granted directly by upgrades.
NO: Equipped creature adding Warmth.
NO: Dedicated Thaw Machine.
NO: Limited Thaw Slots.
NO: Individual Ice respawning every 6/8/10/12/15 seconds.
NO: Creature-specific traversal abilities.
NO: Separate Speed upgrade tree.
NO: Speed treadmill.
NO: Carry movement slowdown.
Current model:

MaxWarmth = uncapped trainable stat
Hearth = Warmth training speed
Equipped creature = Following/Riding traversal; Riding applies Movement Speed
Pen = creatures + thawing Ice
Great Frost = primary world Ice refresh

## 5. Structural Rules

These rules are not casual balance variables.

Player:
- 1 Equipped creature maximum;
- Equipped traversal state is `Following` or `Riding`;
- Following player movement = base WalkSpeed `16`;
- Riding movement = Equipped copy `FinalWalkSpeed`;
- Ride/Unride is allowed during exploration and while carrying Ice;
- Ride/Unride never changes Pen/Inventory allocation;
- `MountState` / `IsRiding` is never persisted;
- 1 carried Ice maximum;
- 4 active Pen creature positions;
- unlimited owned creature counts;
- unlimited logical thawing Ice;
- 1 currency: Cash;
- MaxWarmth has no cap.

Ice:
- every spawned wilderness Ice is one authoritative shared server object;
- there are no private/per-player wilderness Ice copies;
- one shared Ice may have only one owner/carrier at a time;
- wilderness reward is rolled server-side before player ownership;
- Ice cannot enter normal Inventory before thawing;
- on Freeze/death/reset/respawn/disconnect before deposit, the exact same Ice is released into the shared world with no reroll;
- rescue/relay is allowed;
- there is no intentional DropIce request.

Areas:
- no hard Warmth gates;
- regions provide Recommended Warmth only.

Great Frost:
- resets eligible Available/unclaimed shared wilderness Ice;
- carried Ice survives;
- Pen/Ready Ice survives;
- an Ice released after the current Frost reset has begun survives that current transition;
- Guarded-Ice encounters and configured breakables rebuild with the shared field.

Survival:
- player survival resource is CurrentWarmth, not Player HP;
- Equipped-creature Vitality is session-only;
- Frosted/Downed never changes ownership;
- Frosted forces Unride and blocks Ride until recovery;
- the universal survival attack is not a weapon-progression system;
- on foot it presents as the tool swing; while Riding it presents as Mounted Strike;
- mounted attack damage/range/cooldown never scale from CreatureID, rarity, Scale, WeightMultiplier, or Speed;
- no trample/contact damage.

## 6. Player / Server Constants

Launch
```text
            Constant                          Value
            Target Players Per Server         4
            Base WalkSpeed with no creature   16
            Active Pen Creature Slots         4
            Equipped Creature Limit           1
            Carried Ice Limit                 1
            Currency                          Cash
```


Prototype
```text
            Constant                          Value
            MaxPlayers                        1
            Active Pen Creature Slots         4
            Equipped Creature Limit           1
            Carried Ice Limit                 1
```


## 7. Warmth - Core / Launch Direction

The big-number Warmth direction is now canonical, not a prototype-only visual trick.

```text
Constant                          Initial Value
Starting MaxWarmth                100
Spawn CurrentWarmth               MaxWarmth
Base Wilderness Drain             4 Warmth/sec
Carry Drain Multiplier            2.00x
Hearth Refill                     50% of current MaxWarmth / sec
Low-Warmth Warning                35%
Critical-Warmth Warning           15%
Frozen Threshold                  0
```

Region cold severity multiplies the base drain and provides the exponential progression curve.
Exact region multipliers and Recommended Warmth values are defined in Section 11.

## 8. Warmth Training

While inside the player's own Hearth:

```text
MaxWarmth += HearthTrainingRate * dt
```

Warmth training:
- automatic;
- uncapped;
- no XP;
- no training currency;
- no player input required.

The revised progression intentionally favors satisfying whole-number growth and very large long-term values.

CurrentWarmth refill scales with MaxWarmth:

```text
CurrentWarmthRefillPerSecond = MaxWarmth * 0.50
```

This preserves the old prototype feel of roughly filling from empty in about two seconds even after MaxWarmth becomes enormous.


## 9. Hearth Progression - Revised Prototype First Pass

The initial 3-level Day-5 Hearth proved the mechanic. Days 6-7 expand it.

```text
Hearth Lv.   Upgrade Cost   Warmth Training Rate
1            Start          +10/sec
2            $150           +50/sec
3            $1,000         +250/sec
4            $7,500         +1,250/sec
5            $60,000        +6,250/sec
6            $500,000       +31,250/sec
```

These are first-pass prototype progression values and should be tuned from actual pacing.
The functional rule is structural:
- Hearth upgrade never grants a fixed MaxWarmth amount;
- Hearth level only changes ongoing training rate;
- MaxWarmth remains uncapped.

The former Day-5 `+0.50 / +1.00 / +1.75` rates are superseded once D7-R03 is implemented.


## 10. Hearth Visual Stages

Prototype presentation target:

```text
Lv.1       Small Hearth
Lv.2       Strong Hearth
Lv.3       Iron Brazier
Lv.4       Runic Hearth
Lv.5       Frostfire Forge
Lv.6       Great Runic Furnace
```

These do not require six unique production meshes.
Presentation may reuse geometry with stronger flame/light/runes/scale.

Always communicate:

```text
HEARTH LV. X
TRAINING +<rate> WARMTH/s
NEXT $<cost> / MAX
```


## 11. Region Recommended Warmth + Cold Severity

First-pass big-number progression and canonical Frost Sprite Warmth damage:

```text
Region             Main Ice   Recommended Warmth   Cold Multiplier   Sprite Warmth Damage/Hit
Snowfield          Regular    100                  1x                10
Frozen Pass        Thick      1,000                10x               100
Ancient Expanse    Ancient    10,000               100x              1,000
Black Ice Hollow   Black      100,000              1,000x            10,000
Meteor Reach       Meteor     1,000,000            10,000x           100,000
```

Recommended Warmth is guidance only. Never a server access condition.

Warmth drain:

```text
WarmthDrainPerSecond =
    BaseWarmthDrain
    * RegionColdMultiplier
    * (Carrying and CarryMultiplier or 1)
```

Frost Sprite hit:

```text
CurrentWarmth -= RegionFrostSpriteWarmthDamage
```

Conceptual first-pass relationship:

```text
RegionFrostSpriteWarmthDamage = RegionRecommendedWarmth * 0.10
```

The configured regional damage value is authoritative.
Do not scale Sprite damage from player `MaxWarmth`, Ice rarity, Ice size, hidden creature, or Special status.
Special Ice uses its spawn region's damage value.

## 12. World Distance Targets

Keep current first-pass route anchors unless level-design playtesting changes them:

```text
Region             Target Route Distance
Snowfield          60-100 studs
Frozen Pass        180-240 studs
Ancient Expanse    340-460 studs
Black Ice Hollow   580-760 studs
Meteor Reach       900-1,100 studs
```

Recommended Warmth is not calculated from distance alone; creature Speed and regional cold combine to create risk.


## 13. Warmth Core Constants - Revised Prototype

```text
Starting MaxWarmth           100
Base Warmth Drain            4/sec
Carry Multiplier             2.00x
Hearth Refill                50% of MaxWarmth / sec
Low Warmth Threshold         35% of MaxWarmth
Critical Warmth Threshold    15% of MaxWarmth
```

The regional cold multiplier supplies the dramatic progression scaling.
CurrentWarmth is still restored to full on canonical Freeze recovery.


## 14. Creature Size / Weight Jackpot System

Each spawned Ice gets exactly one server-authoritative `WeightMultiplier`.

For any Ice/creature with `ReferenceWeight`:

```text
ActualWeight = ReferenceWeight * WeightMultiplier
Scale = cbrt(ActualWeight / ReferenceWeight)
Scale = cbrt(WeightMultiplier)
```

Supported visual Scale:

```text
Minimum Visual Scale   0.75x
Maximum Visual Scale   5.00x
```

The runtime must roll WeightMultiplier, then derive Scale through the formula.
Do not separately reroll visual Scale.

### Size bands

```text
Band       Chance   Visual Scale   WeightMultiplier Range
Small      8.0%     0.75-0.95x    0.422-0.857x
Normal     72.0%    0.95-1.25x    0.857-1.953x
Large      15.0%    1.25-1.75x    1.953-5.359x
Huge       4.0%     1.75-2.50x    5.359-15.625x
Colossal   0.9%     2.50-3.50x    15.625-42.875x
Absurd     0.1%     3.50-5.00x    42.875-125.000x
```

Within each band, bias the WeightMultiplier toward the band's lower bound so values near `5.0x` visual Scale are dramatically rarer than simply entering the Absurd band.
First-pass implementation:

```text
t = Random() ^ 2
WeightMultiplier = lerp(BandMinWeight, BandMaxWeight, t)
```

A true near-5x copy is intended to be an exceptional social/jackpot event.

The WeightMultiplier is inherited unchanged:

```text
wilderness Ice
= carried Ice
= thaw record
= revealed CreatureCopy
```


## 15. Ice Base Visual / Weight Contract

Each Ice type must define explicit:

```text
ReferenceWeight
BaseVisualScale
```

The exact authored dimensions belong to the repository asset/config audit.
Do not invent world-space dimensions if the existing visual asset already establishes its 1.0x baseline.

Recommended relative base visual multipliers for prototype tuning:

```text
Regular   1.00
Thick     1.35
Ancient   1.75
Black     2.20
Meteor    3.00
```

Runtime visual scale:

```text
FinalIceVisualScale = BaseVisualScale * SizeScale
```

All extreme Ice visuals should avoid blocking traversal physics.


## 16. Creature Base Stat Contract

Every configured species defines:

```text
ReferenceWeight
BaseVisualScale
BaseIncomePerSecond
BaseWalkSpeed
```

Current validated 11-species baseline:

| Creature | Rarity | ReferenceWeight kg | BaseVisualScale | BaseIncome/s | BaseWalkSpeed |
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

Runtime copy values:

```text
Scale = cbrt(WeightMultiplier)
IncomeMultiplier = Scale ^ 2
SpeedMultiplier = 1 + 0.15 * (Scale - 1)
FinalIncome = max(1, round(BaseIncomePerSecond * IncomeMultiplier))
FinalWalkSpeed = BaseWalkSpeed * SpeedMultiplier
```

Frosted/Downed baseline movement uses the no-creature walk speed (`16`) until recovery.

At the supported extremes:

```text
0.75x Scale -> SpeedMultiplier ~= 0.9625x
1.00x Scale -> 1.00x
2.00x Scale -> 1.15x
3.00x Scale -> 1.30x
4.00x Scale -> 1.45x
5.00x Scale -> 1.60x
```

Income intentionally scales much harder: `Scale^2`.

Do not change these approved species baselines without an explicit design decision.

## 17. Supported Rarity / Economy Tiers

Configured economy tier labels:

1. Common
2. Uncommon
3. Rare
4. Epic
5. Legendary

Current Pen-income reference baselines retained for migration/comparison only:

```text
Common       $2/sec
Uncommon     $5/sec
Rare         $12/sec
Epic         $20/sec
Legendary    $28/sec
```

After D6-R05/D6-R06, actual Pen income comes from species `BaseIncomePerSecond * Scale^2`, not directly from rarity.

The existence of Epic/Legendary economy tiers does not automatically define prototype creature content, pools, or weights.


## 18. Creature Stat Presentation

Every visible creature copy should expose at minimum:

```text
SPEED <rounded FinalWalkSpeed>
PEN $<FinalIncome>/s
```

An Equipped creature displays its intrinsic `PEN $/s` value for comparison but earns zero while Equipped.

Extreme copy Scale should remain the primary visual signal; text is secondary.


## 19. Pen Income

Income interval:

```text
1 second
```

Server calculates one aggregate payment:

```text
TotalIncome =
    PenSlot1FinalIncome
    + PenSlot2FinalIncome
    + PenSlot3FinalIncome
    + PenSlot4FinalIncome
```

No independent timer per creature.
No offline Pen income.
Equipped and Inventory copies earn zero.


## 20. Ownership / GUID Structural Constants

```text
Max Equipped Copies          1
Active Pen Creature Slots    4
Creature identity key        CreatureGUID
Discovery identity key       CreatureID / species
```

Persistent copy payload should remain minimal:

```text
CreatureID
WeightMultiplier
```

Scale / Income / Speed are derived.

## 21. Launch Creature Roster

Launch quantity target: **16 species**.

Current locked/integrated baseline: **11 species**:

**Common**  
Penguin, Rabbit, Seal

**Uncommon**  
Wolf, Bear

**Rare**  
Mammoth, Sleipnir

**Epic**  
Troll, IceSerpent

**Legendary**  
Hraesvlgr, Nidhogg

The remaining five species/content assignments are not canonically defined by this revision.
Do not resurrect stale placeholder roster names or invent the remaining species without explicit approval.

## 22. Current Functional Creature Roster

The current functional build uses all 11 validated species listed in Section 21.

The former eight-species prototype roster is deprecated.

## 23. Current Functional Ice Rarity Weights

Weights are ordered:

```text
Common / Uncommon / Rare / Epic / Legendary
```

```text
Regular   74 / 23 / 3  / 0  / 0
Thick     30 / 35 / 25 / 10 / 0
Ancient   0  / 30 / 45 / 25 / 0
Black     0  / 10 / 35 / 40 / 15
Meteor    0  / 0  / 20 / 55 / 25
```

Every row totals 100.
These are the current approved geographic-Ice rarity weights for the validated 11-species baseline.

## 24. Current 11-Species Creature Pools

Once rarity is rolled, choose uniformly among eligible creatures of that rarity within the current Ice pool unless a later explicit weighting revision says otherwise.

### Regular
- Common: Penguin, Rabbit, Seal
- Uncommon: Wolf, Bear
- Rare: Mammoth
- Epic: none
- Legendary: none

### Thick
- Common: Seal
- Uncommon: Wolf, Bear
- Rare: Mammoth, Sleipnir
- Epic: Troll
- Legendary: none

### Ancient
- Common: none
- Uncommon: Bear
- Rare: Mammoth, Sleipnir
- Epic: Troll, IceSerpent
- Legendary: none

### Black
- Common: none
- Uncommon: Wolf
- Rare: Mammoth, Sleipnir
- Epic: Troll, IceSerpent
- Legendary: Hraesvlgr

### Meteor
- Common: none
- Uncommon: none
- Rare: Mammoth, Sleipnir
- Epic: Troll, IceSerpent
- Legendary: Hraesvlgr, Nidhogg

Unlock ladder:
- Regular: core baseline;
- Thick: adds Sleipnir + Troll;
- Ancient: adds IceSerpent;
- Black: adds Hraesvlgr / first Legendary;
- Meteor: adds Nidhogg.

Nidhogg is Meteor-only in normal geographic Ice.
Hraesvlgr begins at Black.
IceSerpent begins at Ancient.

## 25. Deprecated Prototype Pool Table

The former Regular/Thick-only eight-species prototype pools are superseded by the full five-tier 11-species pools in Sections 23-24.

## 26. Bad-Luck Protection

Initial launch setting:

DISABLED
```text
            1 BadLuckProtectionEnabled = false
            2 CommonStreakThreshold = 4
```


The reward currently belongs to shared wilderness Ice before player ownership.
Player-specific pity therefore does not cleanly fit the current spawn architecture.
Do not implement until explicitly re-enabled.


## 27. Ice Spawn Counts - Launch

Initial four-player target:

```text
             Ice                                  Active Per Great Frost
             Regular                              12
             Thick                                8
             Ancient                              8
             Black                                6
             Meteor                               4
             Total                                38
```


Ice remains until:
claimed;
or removed by the next Great Frost.
No independent normal respawn timer.


## 28. Candidate Spawn Point Targets

```text
            Ice                      Candidate Points          Active
            Regular                  18                        12
            Thick                    12                        8
            Ancient                  12                        8
            Black                    9                         6
            Meteor                   6                         4
```


The game selects among authored positions.
It does not generate arbitrary world coordinates.


## 29. Prototype Spawn Counts

```text
            Ice                      Candidate Points          Active
            Regular                  6                         4
            Thick                    4                         2
```


## 30. Great Frost - Launch Timing

```text
            Constant                                Value
            Full Cycle Length                       300 sec / 5 min
            Normal Day Portion                      285 sec
            Great Frost Duration                    15 sec
```


Launch should use shared wall-clock cycle timing.

CycleEpochUnix = 0.
Canonical phase rule:
CyclePosition = (CurrentUnixTime - CycleEpochUnix) % CycleLength.
Day when CyclePosition < 285.
Great Frost when CyclePosition >= 285.

GrabLockedDuringGreatFrost = true.
A server tracks LastProcessedFrostCycle at runtime so the same Frost transition cannot be processed twice.
A server booting mid-Frost does not retroactively award Thaw Surge or Special Ice.


## 31. Great Frost Sequence

Within the 15-second Frost window:
0 sec
Great Frost begins.
~2 sec
Transition/world presentation begins.
~3 sec
Remove available/unclaimed Ice.
~4 sec
Apply online Thaw Surge.
~8 sec
Populate new Ice field.
~10 sec
Present Special Ice announcement if applicable.
15 sec
Normal phase resumes.
GrabIce confirmations become valid again when normal Day resumes.
Presentation timing may change without altering gameplay rules.


## 32. Great Frost Thaw Surge - Launch

Each unfinished Ice belonging to a player currently online receives:

15% of that Ice's BaseThawDuration
Formula:
```text
            1 BonusProgressSeconds += BaseDurationSeconds x 0.15
```


Examples:

```text
            Ice                      Base Timer               Frost Bonus
```


```text
            Regular                  1 min                     9 sec
            Thick                    3 min                     27 sec
            Ancient                  7 min                     63 sec
            Black                    15 min                    135 sec
            Meteor                   25 min                    225 sec
```


Ready Ice is unaffected.
Offline players do not receive the bonus.


## 33. Prototype Great Frost Timing + Thaw Boost

```text
            Constant                               Prototype
            Cycle Length                       120 sec
            Normal Portion                     105 sec
            Great Frost Duration               15 sec
            GreatFrostThawMultiplier            10x
            Day Thaw Multiplier                  1x
```

The prototype multiplier is deliberately exaggerated for validation.

Rules:
- `GreatFrostThawMultiplier` is active only while `CurrentPhase == GreatFrost`;
- unfinished Ice already thawing accelerates at `10x` for the Frost overlap;
- Ice deposited during Great Frost immediately accelerates at `10x` from `DepositedAtTime` until Frost ends;
- when Day resumes, thaw speed immediately returns to `1x`;
- progress earned during Great Frost is preserved;
- already-Ready Ice remains Ready;
- this replaces the superseded prototype fixed `+30 sec` grant.

Conceptual active-Frost calculation:
```text
            1 OverlapStart = max(
            2     DepositedAtTime,
            3     GreatFrostStartedAtTime
            4 )
            5 FrostSeconds = max(0, CurrentTime - OverlapStart)
            6 FrostExtra =
            7     FrostSeconds
            8     * (GreatFrostThawMultiplier - 1)
            9 EffectiveElapsed =
           10     NormalElapsed
           11     + BonusProgressSeconds
           12     + FrostExtra
```

At Great Frost -> Day, preserve the earned extra progress by folding the completed Frost overlap into `BonusProgressSeconds` (or an equivalent authoritative accumulated-bonus field) before the live Frost contribution becomes zero.


## 33A. Canonical Survival Pressure - First-Pass Production Constants

These values are the current first-pass production baseline for the promoted Survival Pressure package. They may be tuned through explicit balance changes without authorizing new mechanics.

Universal survival attack - shared by on-foot Tool Swing and Mounted Strike:

```text
SurvivalAttackServerHitRange      8 studs
SurvivalAttackCooldown            0.65 sec
SurvivalAttackDamageToFrostSprite 1
```

Compatibility: an existing implementation may retain legacy `ToolServerHitRange`, `ToolSwingCooldown`, or `ToolDamageToFrostSprite` config names internally, but both traversal states must resolve to the same values. Mounted Strike uses a logical ground/front `MountedCombatOrigin`; its effective range remains `8` studs regardless of visual creature Scale.

Frost Sprite baseline:

```text
FrostSpriteMaxHealth              3
EngagementRadius                  26 studs
AttackTelegraph                   0.75 sec
AttackCooldown                    2.40 sec
ProjectileSpeed                   40 studs/sec
CreatureVitalityDamagePerHit      25
TargetingRule                     nearest valid target (first-pass; configurable)
```

Target locks when the telegraph begins unless a later explicit targeting revision changes it.

Player Warmth damage is **regional**:

```text
Snowfield          10
Frozen Pass        100
Ancient Expanse    1,000
Black Ice Hollow   10,000
Meteor Reach       100,000
```

Do not use one flat player-damage value across all regions.

Equipped creature state:

```text
CreatureVitalityMax               100
FrostedAtVitality                 0
FrostedSpeedBonusEnabled          false
HearthRecovery                    full restore on OWN Hearth entry
```

Own-Hearth recovery immediately restores full session Vitality, clears Frosted, and makes Riding available again. If the player remains unmounted they stay at base WalkSpeed; mounted Speed returns when they Ride. Another player's Hearth does not recover the visitor's creature.

Guarded Ice authoring:
- all five geographic Ice tiers support Guarded-Ice encounters;
- some Ice opportunities may remain unguarded;
- guardian count/placement is authored/configurable;
- do not infer a guardian-count curve from region damage;
- no random generic enemy population or independent long-lived enemy respawn timers;
- Great Frost clears/rebuilds guardians with the shared field.

Breakable route baseline:

```text
Frozen Branch                     3 hits
Brittle Rock / Ice Rock           5 hits
```

Breakables grant no Wood, Stone, currency, XP, drops, or crafting materials.

## 34. Thaw Durations - Launch

```text
            Ice                                    Base Thaw Time
            Regular                            60 sec
            Thick                              180 sec / 3 min
            Ancient                            420 sec / 7 min
            Black                              900 sec / 15 min
            Meteor                             1,500 sec / 25 min
```


Timers continue offline.

Hidden rarity does not alter duration.


## 35. Validated Week-1 Thaw Durations

Current validated fast-build values:

```text
Regular     20 sec
Thick       45 sec
Ancient     90 sec
Black       180 sec
Meteor      300 sec
```

Launch production durations remain separately defined in Section 34 until explicitly rebalanced.

## 36. Thaw Progress States

```text
            Progress                            Visual State
```


```text
            0-35%                               Frozen / opaque
            35-70%                              Partial thaw
            70-99%                              Nearly Ready
            100%                                READY TO CRACK
```


Visual progress must not leak hidden rarity.


## 37. Offline Thawing

Launch formula:
```text
           1 Elapsed =
           2     CurrentUnixTime
           3     - DepositedAtUnix
           4     + BonusProgressSeconds
```


```text
           1 Progress =
           2     clamp(
           3         Elapsed / BaseDurationSeconds,
           4         0,
           5         1
           6     )
```


Offline:

normal elapsed time only.

Online:

normal elapsed time + any Great Frost bonuses actually received.

## 38. Special Ice Cadence

Initial launch value:

1 Special Ice every 3 Great Frost cycles
At a five-minute cycle:

approximately every 15 minutes.
```text
             1 SpecialIceEveryNCycles = 3
```


## 39. Special Ice Spawn Rule

Special Ice:
- spawns in addition to normal population;
- modifies a normal Ice Type;
- uses a valid authored shared spawn position;
- is shared/contestable;
- follows the universal carry/failure rules;
- stores `OriginCycleIndex` and `OriginSpawnPointID` as metadata;
- expires at a future Great Frost if still Available/unclaimed;
- on carrier failure, drops at the last valid safe carrier position with exact reward/WeightMultiplier/Special metadata preserved;
- never rerolls or teleports to origin merely because it is Special.

Eligible Types:

```text
Ancient / Black / Meteor
```

First-pass type selection remains:

```text
Ancient   50%
Black     30%
Meteor    20%
```

## 40. Special Ice Rarity Weights


Special Ice guarantees:

Rare or Legendary
Ancient Special
```text
            Rarity                               Weight
           Rare                                  75%
           Legendary                             25%
```


Black Special
```text
            Rarity                               Weight
           Rare                                  55%
           Legendary                             45%
```


Meteor Special
```text
            Rarity                               Weight
           Rare                                  35%
           Legendary                             65%
```


Creature remains restricted to that Ice Type's normal creature pool.


## 41. Special Ice Presentation

Minimum:
visually unusual;
visibly larger and/or runic;
distinguishable at distance;
server-wide notification.
Recommended phrasing:

A Strange Ice Has Awakened

Do not reveal the creature.


## 42. Reveal Constants

```text
               Constant                        Value
               Required Hits                   3
               Hit Sequence                    Crack / Crack / Smash
               Minimum Accepted Hit Interval   0.20 sec
               Target Total Interaction        3-6 sec
               Failure                         None
               Accuracy Requirement            None
               Combo Requirement               None
```


## 43. Rarity Foreshadowing

**Common**  
No special foreshadow required.

**Uncommon**  
No special foreshadow required.

**Rare**  
Hit #2 may use subtle glow/sound.

**Epic**  
Hit #2 may use clearly elevated glow/particles/sound, still without revealing exact identity.

**Legendary**  
Hit #2 may use the strongest pre-Smash rarity foreshadowing.

Exact rarity is revealed on final Smash.

## 44. Silhouette Information Rule

Silhouette is a hint, not guaranteed exact identification.

Desired progression:

```text
vague at distance
-> suggestive nearby
-> clearer during thaw
-> nearly recognizable near Ready
-> exact identity on reveal
```

Several creatures may share a reusable SilhouetteProfile.

Validated profile assignments from the existing asset/config audit include:

```text
Compact          Penguin / Rabbit / Seal
AgileQuadruped   Wolf
HeavyBeast       Bear
GiantAncient     Mammoth
MythicUnknown    Troll / Nidhogg
```

Sleipnir, IceSerpent, and Hraesvlgr must use their actual approved/configured profile once verified in the current repository; do not infer stale placeholder mappings.

Profiles should remain coarser than exact species where practical. Presentation may obscure/distort further at distance.

## 45. Interaction Distances

```text
             Interaction                            Max Server Distance
             Grab Ice                               14 studs
             Deposit at Pen                         20 studs
             Begin Reveal                           18 studs
             Crack while revealing                  20 studs
             Hearth Upgrade                         20 studs
             Pen Management                         25 studs
             Equip / Sell                           25 studs
             Survival Attack Hit                    8 studs
```


These are server-validation distances.
Prompt display distance may differ.


## 46. Request Rate Limits

```text
             Action                                 Minimum Interval
```


```text
             GrabIce                              0.35 sec
             DepositCarriedIce                    0.50 sec
             BeginReveal                          0.50 sec
             Crack                                0.20 sec
             Equip / Unequip                      0.25 sec
             Pen Management                       0.25 sec
             Sell                                 0.25 sec
             UpgradeHearth                        0.50 sec
             Survival Attack                       0.65 sec
```


These are technical anti-spam protections, not intended gameplay cooldowns.


## 47. Pen Rules

Launch:
4 active earning creature positions;
duplicates allowed;
thawing Ice consumes zero creature positions;
Pen creatures earn income;
Equipped creature earns no Pen income;
Sell from Pen leaves slot empty;
Equip from Pen leaves slot empty;
no automatic Inventory refill.


## 48. Inventory Rule

Inventory is derived from ownership.
For each species:
```text
             1 InventoryCount =
             2     OwnedCount
             3     - PenCopies
             4     - EquippedCopies
```


Invariant:
```text
             1 PenCopies + EquippedCopies <= OwnedCount
```


Inventory is not a second ownership database.


## 49. New Reveal Routing

After reveal:
Pen has space
Place creature into first available active Pen position.
Pen full
Creature remains unallocated in Inventory.
Display:

Pen Full - Added to Inventory
No modal decision is required.


## 50. Equip Rules

Equip/Unequip occurs at the player's own base.
Inventory -> Equip
Creature becomes Equipped and starts in Following state.
Pen -> Equip
Pen position becomes empty.
Replace Equipped
Old Equipped creature returns to Inventory.
Unequip
Creature returns to Inventory.
No automatic Pen refill.


## 51. Sell Rules

Sell at own base.
Inventory
```text
              1 OwnedCount -= 1
              2 Cash += SellValue
```


Pen
```text
              1 Clear Pen Slot
              2 OwnedCount -= 1
              3 Cash += SellValue
```


Equipped
```text
              1   Unequip
              2   OwnedCount -= 1
              3   Cash += SellValue
              4   RecalculateSpeed
```


Archive discovery remains.


## 52. Frozen Archive

Launch:

16 slots
Prototype stretch:

8 slots
Undiscovered:

???
Discovered:
name;
rarity;
icon/visual.
Selling all owned copies does not reverse discovery.


## 53. Equipped Creature Following / Riding

Every creature is mountable. The exact Equipped CreatureGUID has one of two exploration presentation states.

Following:
```text
Desired position behind player
-> smooth interpolation
-> snap closer when too far away
Player WalkSpeed = 16
```

Riding:
```text
player uses authored Seat / configured rider anchor
Player movement = copy FinalWalkSpeed
```

Ride/Unride:
- allowed during exploration, including while carrying Ice;
- no stamina/fuel/cooldown progression;
- no ownership/Pen/income change;
- no Ice drop;
- not persisted;
- join/respawn returns to Following.

Every production creature must expose an authored `Seat` or configured equivalent. Optional MountProfile presentation may customize rider offset/rotation, pose, camera, movement animation, carried-Ice visual offset, and mounted-attack animation. These fields are presentation only.

Do not use server-heavy pathfinding, Humanoid AI, follower/mount position for client-authoritative gameplay calculations, or vehicle-style progression systems.

### Mounted attack rule

The player's one survival attack becomes Mounted Strike while Riding. Same damage/effect, `8`-stud effective range, `0.65`-second cooldown, target categories, and server validation as on foot. Mounted Strike uses a logical ground/front combat origin so giant mounts can hit nearby ground-level Sprites. No species/rarity/Scale/Speed scaling and no trample/contact damage.


## 54. Pen Roaming Presentation

Optional cosmetic behavior:
```text
           1   Choose nearby valid point
           2   -> move
           3   -> pause
           4   -> repeat
```


No gameplay effect.
Can be removed without affecting economy.


## 55. Great Frost Player Rules

During Great Frost players may:
remain outside;
carry Ice;
return home;
train Warmth;
reveal Ready Ice;
manage creatures.
Great Frost does not automatically:
freeze;
teleport;
remove carried Ice.


## 56. Base Rules

Launch topology:
- up to 4 personal bases;
- grouped side-by-side along one shared home-camp edge;
- all face the same primary wilderness direction.

Each player has one assigned personal base.

Only own base provides:
- CurrentWarmth refill;
- MaxWarmth training;
- Hearth upgrades;
- Pen deposit/management;
- Equip/Sell;
- reveal;
- Equipped-creature Vitality/Frosted recovery.

Another player's WarmZone is social/presentation space only and provides none of the above gameplay recovery/progression.

There is **no private OnboardingIceSpawnPoint requirement** in the canonical design. Onboarding must use shared Ice opportunities.

## 57. Persistent Data - Launch

```text
DataVersion = 2+
Cash
MaxWarmth
HearthLevel

CreatureCopies[CreatureGUID] = {
    CreatureID,
    WeightMultiplier,
}

PenSlots[1..4] = CreatureGUID or nil
EquippedCreatureGUID = CreatureGUID or nil
DiscoveredCreatures[CreatureID] = true
ThawingIce[]
```

Persistent ThawItems preserve `WeightMultiplier`.

Do not persist:
- CurrentWarmth;
- carried Ice;
- dropped world-Ice ownership/position;
- RevealSession;
- world position;
- Frozen state;
- follower/mount presentation position;
- MountState / IsRiding;
- mount Seat occupancy/presentation state;
- Frost Sprite state;
- tool cooldown;
- breakable state;
- Equipped-creature current Vitality;
- Frosted/Downed state;
- current encounter target.

## 58. Join Defaults

New player:

```text
Cash = 0
MaxWarmth = 100
CurrentWarmth = 100
HearthLevel = 1
CreatureCopies = {}
PenSlots = {nil, nil, nil, nil}
EquippedCreatureGUID = nil
DiscoveredCreatures = {}
ThawingIce = {}
```

On every valid rejoin:

```text
CurrentWarmth = MaxWarmth
EquippedCreatureVitality = full if a creature is equipped
Frosted = false
MountState = Following if a creature is equipped, otherwise None
```

Onboarding configuration:

```text
OnboardingUsesSharedIce = true
PrivateOnboardingIceEnabled = false
PreferredOnboardingIceType = Regular
```

Onboarding may highlight/retarget a suitable shared Regular opportunity. It must not spawn a private duplicate.

## 59. Data Operational Constants

```text
             Constant                              Value
             Autosave Interval                     60 sec
             Save Retry Attempts                   3
             Retry Backoff                         1s / 2s / 4s
             DataVersion                           1
```


If loading fails:

never enter normal writable gameplay with a replacement blank profile that
could overwrite legitimate data.

## 60. Warmth Network Update

Recommended:

```text
             Constant                              Value
             Warmth Simulation Step                0.25 sec or finer
             Client Warmth Replication Target      4 updates/sec
```


Client may visually interpolate between updates.
Gameplay truth remains server-side.


## 61. World Cycle Network Update

Server sends:
phase;
CycleIndex;
transition timestamp.

Client displays countdown locally and periodically corrects.
Do not send a server RemoteEvent every second merely to animate a countdown.


## 62. Launch Progression Timing Targets

These are playtest targets, not gates.
First Creature

approximately 1-2 min
First Hearth Upgrade

approximately 2-4 min
Thick meaningful

approximately 5-10 cumulative min
Ancient realistic

approximately 20-35 cumulative min
Black

approximately 45-75 cumulative min
Meteor

approximately 90-150 cumulative min
Hearth Lv.10

longer-term progression target.

## 63. Prototype Timing Targets

First retrieval

under 60 sec
First reveal

ideally 1-2 min
First meaningful Equipped Speed

3-4 min
First Great Frost

approximately 1:45 after the normal phase begins.
First Hearth upgrade

approximately 2-4 min
First Thick attempt

approximately 3-6 min
Prototype pacing is intentionally compressed.


## 64. Low-Warmth Presentation

Safe

above 40%.
Low

20-40%.
Suggested:
light frost;
Warmth UI pulse.
Critical

0-20%.
Suggested:
heavier frost;
stronger wind;

warning audio;
urgent UI.
At zero:

server freezes player.

## 65. Ice Presentation Escalation

Regular
Simple recognizable frozen block.
Thick
Larger / heavier-looking.
Ancient
Aged / prehistoric / fossil or runic visual language.
Black
Dark supernatural frost.
Meteor
Celestial / magical / spectacular.
These are presentation profiles.
They do not create additional gameplay systems.


## 66. Five Hero Moment Requirements

Hero 1 - First Great Frost
Great Frost must be unmistakable even if effects are simplified.


Hero 2 - Impossible-Looking Ice
At least one future opportunity should be visible substantially before comfortable access.
No extra progression mechanic required.


Hero 3 - Barely-Made-It-Home
Low/Critical Warmth presentation must escalate visibly.

Hearth must be readable from the return approach.


Hero 4 - Legendary Smash
Legendary uses strongest reveal presentation.
Do not increase required hits.
Epicness comes from:

presentation + rarity + consequence.

Hero 5 - Endgame Speed
Legendary first-pass:

WalkSpeed 32
Old regions should feel compressed by late-game traversal.


## 67. Special-Ice Hero Rule

Special Ice should create shared server attention.
It must still require:

reach -> retrieve -> return -> thaw -> reveal.
It never directly grants a creature.


## 68. Special Ice Shared-Lifecycle Rule

Special Ice uses the same shared ownership and carrier-failure rules as all other Ice.

On carrier Freeze/death/reset/respawn/disconnect:
- release exact Special Ice at last valid safe carrier position;
- preserve reward, rarity, WeightMultiplier/Scale, and Special metadata;
- clear owner;
- set Available;
- allow any player to rescue it.

Do not return it to origin merely because it is Special.
A future Great Frost may remove it if it remains unclaimed.

## 69. Prototype Archive

Week 1:

OFF by default / P2
Internal discovery tracking may exist if trivial.
Archive UI should not delay prototype completion.


## 70. Prototype Follower / Roaming

Minimal follower
P1 if time permits.
Follower polish
P2.
Pen roaming
P2.
None block prototype success.


## 71. Prototype Sell Scope

Minimum P1:

Sell from Inventory.
Sell-from-Pen and Sell-Equipped may wait during Week 1.
Launch must support all three.


## 72. Content Configuration Rule

Each creature should define at minimum:
```text
            1 CreatureID
            2 DisplayName
            3 Rarity
            4 ModelName
            5 SilhouetteProfile
```


Do not duplicate SellValue, PenIncome, or WalkSpeed per species unless an explicit later design change introduces species-specific overrides.

RarityConfig should define per rarity:
```text
            1 WalkSpeed
            2 SellValue
            3 PenIncomePerTick
            4 RevealPresentationProfile
            5 RarityUI
            6 EffectsProfile
```


Economy and Speed derive from RarityConfig by default.

## 73. Ice Configuration Rule

Each Ice Type defines:
```text
             1   IceType
             2   RarityWeights
             3   CreaturePoolsByRarity
             4   BaseThawDuration
             5   CarryDrainMultiplier
             6   PresentationProfile
```


Initial carry multiplier for all Ice:

1.75x
Do not introduce different carry weights merely for flavor.


## 74. Hearth Configuration Rule

Each Hearth entry:
```text
             1   Level
             2   UpgradeCost
             3   WarmthTrainingRate
             4   VisualStage
```


Do not create:
```text
             1 MaxWarmthCap
```


## 75. Region Configuration Rule

Each region:
```text
             1 RegionID
             2 DisplayName
             3 RecommendedWarmth
```


Do not create:
```text
             1 MinimumWarmthRequired
```


unless the design explicitly changes.


## 76. WorldCycle Configuration

Launch:
```text
            1 CycleLength = 300
            2 GreatFrostDuration = 15
            3 CycleEpochUnix = 0
            4 ThawSurgePercent = 0.15
            5 SpecialIceEveryNCycles = 3
            6 GrabLockedDuringGreatFrost = true
```


Prototype:
```text
            1 CycleLength = 120
            2 GreatFrostDuration = 15
            3 GreatFrostThawMultiplier = 10
            4 SpecialIceEnabled = false
            5 GrabLockedDuringGreatFrost = true
```


Runtime-only:
```text
            1 LastProcessedFrostCycle
```


## 76A. SurvivalConfig - Canonical

Keep promoted survival values in one small configuration surface such as:

```text
SurvivalConfig
```

It may define only values required by the approved retrieval-pressure system:
- tool range/cooldown/damage;
- Frost Sprite health/radius/telegraph/cooldown/projectile speed;
- regional player Warmth damage;
- temporary Equipped-creature Vitality and creature damage;
- authored guard-profile metadata/counts;
- breakable hit counts.

Do not use this module as the seed of a generic combat/item/ability/loot/crafting framework.

## 77. Structural State Invariants

Always preserve:

```text
0 <= CurrentWarmth <= MaxWarmth
MaxWarmth >= StartingMaxWarmth
0 <= carried Ice count <= 1
0 <= Equipped creature count <= 1
0 <= active Pen creatures <= 4
```

Shared Ice:
- one IceInstanceID = one server-wide opportunity;
- at most one owner/carrier;
- carrier failure releases the exact Ice and clears owner;
- no reroll across release/rescue;
- no private wilderness Ice copies;
- no intentional DropIce request.

Survival:

```text
0 <= CreatureVitality <= CreatureVitalityMax
```

- Vitality is session-only and applies only to the currently Equipped creature;
- Frosted/Downed never changes creature ownership;
- Frosted/Downed forces Unride, blocks Ride, and removes mounted Speed until own-Hearth/failure recovery;
- Frost Sprite player hits reduce CurrentWarmth only;
- no Player HP;
- Sprite Warmth damage comes from region configuration.

Size lineage:

```text
Ice.WeightMultiplier
== carried/dropped Ice.WeightMultiplier
== deposited ThawItem.WeightMultiplier
== revealed CreatureCopy.WeightMultiplier
```

No failure/rescue/reveal may reroll size.

## 78. Configuration Values vs Structural Rules

Safe to tune
Warmth drain;
carry multiplier;
refill;
Hearth training rates;
Hearth costs;
Recommended Warmth;
WalkSpeeds;
creature values;
rarity weights;

spawn counts;
distances;
thaw times;
Great Frost duration;
Frost bonus;
Special cadence;
Special rarity weights.
Require explicit design decision
Do not casually alter:
one-Ice carry;
uncapped MaxWarmth;
Hearth = training rate;
Equipped creature = Following/Riding traversal; Riding applies copy FinalWalkSpeed;
4 active Pen positions;
unlimited logical thawing;
3-hit reveal;
Great Frost world refresh;
offline normal thawing;
no hard area gates;
one currency;
server authority.


## 79. Initial Balance Philosophy

The intended progression feeling is:
Early

"Getting that nearby Ice is an expedition."
Mid

"Regular is easy now. I want what is farther away."
Late

"I'm extremely fast, but the deepest Ice still gives me a reason to prepare."
Two independent progression axes:

MaxWarmth = how long I survive

Creature mounted Speed = how much distance I cover during that time

## 80. Waiting Philosophy

Thaw timers should create:

anticipation
not:

inactivity.
While waiting, the player should usually be able to:
retrieve another Ice;
train Warmth;
manage creatures;
earn Cash;
upgrade Hearth;
wait for Great Frost.
If players repeatedly have nothing useful to do:

first inspect the surrounding loop before automatically shortening every timer.

## 81. Great Frost Philosophy

The five-minute rhythm should encourage:

"I'll stay for one more Frost."
Great Frost provides:
1. refreshed wilderness opportunities;

2. online thaw acceleration;
3. recurring spectacle;
4. periodic Special Ice.
Do not convert it into a punishment timer.


## 82. Special Ice Philosophy

Special Ice should create:

urgency + aspiration + shared attention.
It must remain rare enough that normal Ice stays meaningful.
Initial cadence:

approximately every 15 minutes.
Tune from real playtesting.


## 83. Creature Progression Philosophy

Higher rarity has three simple player-facing advantages:
Pen

more passive Cash.
Sell

more immediate Cash.
Equip

more Movement Speed.
Do not add additional creature stats without a separate design decision.


## 84. Production Scope Rule

If production falls behind, simplify:
environmental art;

Hearth visual uniqueness;
Pen roaming;
follower polish;
advanced silhouette presentation;
VFX;
Archive polish.
Protect:

Retrieve -> Thaw -> Reveal -> Progress -> Retrieve again.

## 85. Final Canonical Configuration Summary

Current canonical first-pass production baseline includes:
- Starting MaxWarmth `100`;
- Base wilderness drain `4/sec`;
- Carry multiplier `2.00x` -> `8/sec` in Snowfield while carrying;
- Hearth refill `50% of MaxWarmth/sec`;
- Low/Critical thresholds `35% / 15%`;
- uncapped MaxWarmth training;
- 4 active Pen creatures;
- 1-second aggregate Pen income;
- unlimited logical thawing Ice;
- 5 geographic Ice tiers;
- one shared Ice field per server;
- exact-Ice carrier-failure release/rescue;
- 11 validated current creature species with 16-species launch quantity target;
- five rarities: Common / Uncommon / Rare / Epic / Legendary;
- per-copy CreatureGUID ownership;
- one inherited Ice WeightMultiplier;
- `0.75x-5.0x` supported visual Scale;
- `FinalIncome = max(1, round(BaseIncomePerSecond * Scale^2))`;
- `FinalWalkSpeed = BaseWalkSpeed * (1 + 0.15*(Scale-1))`;
- regional Frost Sprite Warmth damage `10 / 100 / 1,000 / 10,000 / 100,000`;
- universal survival tool;
- stationary Frost Sprites;
- Guarded Ice across all tiers;
- session-only Equipped-creature Vitality/Frosted;
- breakable route obstacles;
- one currency;
- 3-hit CRACK -> CRACK -> SMASH reveal.

Launch Great Frost cadence/thaw behavior and production thaw durations remain defined in their dedicated sections and may differ from Week-1 validation overrides.

## 85A. v1.1 Revised Canonical Progression Summary

```text
Per-copy CreatureGUID ownership
One inherited Ice WeightMultiplier per creature copy
0.75x-5.0x visual Scale
Scale = cbrt(WeightMultiplier)
IncomeMultiplier = Scale^2
SpeedMultiplier = 1 + 0.15 * (Scale - 1)
1-second aggregate Pen income
100 starting MaxWarmth
50% MaxWarmth/sec Hearth refill
Recommended Warmth: 100 / 1,000 / 10,000 / 100,000 / 1,000,000
Region Cold Multipliers: 1 / 10 / 100 / 1,000 / 10,000
Frost Sprite Warmth Damage: 10 / 100 / 1,000 / 10,000 / 100,000
Prototype Hearth training: 10 / 50 / 250 / 1,250 / 6,250 / 31,250 per second
One shared server Ice field
Failure releases exact Ice for multiplayer rescue with no reroll
Survival Pressure promoted; no generic combat progression
Every creature mountable: Following <-> Riding
Riding applies copy FinalWalkSpeed; Following uses WalkSpeed 16
Mounted Strike = same universal survival attack values
```

Balance values may change through explicit tuning without reverting the underlying architecture.

## 86. Final AI Rule

When uncertainty exists:

Do not design by assumption.
If the question is technical and does not change player behavior:

choose the smallest robust solution.
If the question changes player behavior, progression, reward, risk, pacing, or the USP:

flag it before implementation.
The AI's job while coding is:

to faithfully implement the current game design-not silently complete it
with conventions from other games.
