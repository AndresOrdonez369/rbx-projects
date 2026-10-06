# THAW A CREATURE

## Implementation Constants & Content Configuration - Canonical v0.9

**Purpose:** Exact first-pass values, content tables, implementation constraints, and AI guardrails  
**Design Source:** Concise GDD v0.5  
**Prototype Source:** Bare-Minimum Prototype Technical Specification v0.9  
**Launch Source:** Technical Implementation Specification v0.5  
**Development Source:** Development Plan v0.9  
**Status:** Numerical values are first-pass balancing values unless explicitly structural  

### Revision notes

- Adds the canonical inherited Ice/creature size-roll system with `MaxVisualScale = 5.0`.
- Records D6-R06 target species-baseline Income/Speed formulas; current runtime
  remains rarity-driven until that task is implemented.
- Preserves 1-second aggregate Pen income and records Epic/Legendary economy tier values as real configuration.
- Rebalances prototype Warmth into big-number progression with exponential Recommended Warmth and regional cold multipliers.
- Expands prototype Hearth progression to a first-pass six-level big-number curve.
- Records percentage-based Warmth warning thresholds and scalable Hearth refill.

- Replaced the Week-1 prototype fixed `+30 sec` Thaw Surge with `GreatFrostThawMultiplier = 10`: the multiplier is active only during Great Frost, applies to Ice deposited mid-Frost for its remaining overlap, returns to `1x` during Day, and preserves Frost-earned progress.
- Synchronized sources to Prototype Technical Specification v0.9 and Development Plan v0.9.
- Added exact first-pass constants and AI guardrails for the Day-5 Survival Pressure Experiment.
- Kept the experiment prototype-only: no launch combat/enemy/pet-Vitality scope is implied unless the Week-1 promotion gate approves a specific subset and later canonical launch documents are revised.
- Integrated the approved Day-4 Stop-Gate Week-1 balance overrides: prototype carry multiplier `2.00x` and prototype creature speeds `16 / 22 / 28 / 34`.
- Resolved previously flagged player-facing ambiguities instead of leaving them for AI inference.
- Added exact shared wall-clock Great Frost phase/boot rules and Grab locking.
- Added Special Ice origin/expiry behavior and launch onboarding-Ice configuration.
- Added canonical reusable SilhouetteProfile mapping.
- Normalized Creature/Rarity/Ice/WorldCycle configuration schema names across all documents.

---

## 1. Document Authority

When documents appear to conflict, use this order:
1. Concise GDD - intended player experience and design.
2. Relevant Technical Specification - system behavior and architecture.
Prototype Technical Specification governs Week-1 prototype scope.
Launch Technical Specification governs production launch implementation.
3. This Constants Document - exact first-pass values and content configuration.
4. Development Plan - implementation order and production priority.

A later document version supersedes an earlier version of the same document.
If an exact number changes during playtesting:

Update the configuration value.
Do not rewrite the gameplay architecture merely to rebalance a number.


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

Movement Speed.
A stronger creature lets the player use their Warmth more efficiently by crossing distance faster.

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

Prototype exception:
If the approved Day-5 Survival Pressure Experiment is active, Great Frost may clear/rebuild the authored Guarded Ice encounters together with the wilderness Ice field.
This does not make Great Frost itself a punishment or enemy phase.

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
At launch, creature gameplay identity comes primarily from:
rarity;
Pen income;
Sell value;
Equipped Speed.

Approved per-copy variation is one inherited Ice `WeightMultiplier`. That one
size lineage derives the copy's Scale and will derive FinalIncome and
FinalWalkSpeed when D6-R06 activates them. There is no independent random
Income or Speed roll.

Do not add without a future explicit design revision:
random independent Income rolls;
random independent Speed rolls;
Damage;
Defense;
Luck;
levels;
XP;
affixes;
traits;
skills;
stamina;
carrying capacity;
random stat points;
additional pet-stat systems;
Warmth bonuses;
traversal abilities;
rarity multipliers beyond configured systems.

Creature copies may differ because of their inherited size lineage. Do not turn
creatures into generic randomized-stat RPG pets.

Prototype exception:
During the exact approved Day-5 Survival Pressure Experiment only, the currently Equipped creature may have temporary session-only `CreatureVitality` plus a boolean Frosted/Downed state.
This is threat-state for the experiment, not a permanent creature stat or launch identity.
It must never alter ownership, create Damage/Defense/levels, affect Pen creatures, or become a generic creature-stat framework.


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
mounts;
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
Examples:
persistence;
offline thawing;
multiplayer;
Special Ice;
Legendary creatures;
Ancient/Black/Meteor Ice.
Consult the Launch Technical Specification before interpreting prototype omissions.


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
Not available at prototype or launch.
A carry ends through Pen deposit or documented failure/reset/death/disconnect handling.

Freeze / normal respawn recovery
Return to own base and set CurrentWarmth = MaxWarmth immediately.
Permanent progression is preserved.

Launch base topology
Up to four personal plots are grouped side-by-side along one shared home-camp edge.
All plots face the same primary wilderness direction.

Visitor Hearth behavior
Another player's WarmZone does not refill CurrentWarmth and does not train MaxWarmth.

First-time onboarding Ice
Enabled at launch only.
A player with no discovered creatures, no ThawingIce, and no carried Ice may receive one private Regular Ice at their authored OnboardingIceSpawnPoint.
It uses normal Regular random reward rules, is not contestable, and is not reset by Great Frost.

Special Ice lifecycle
Unclaimed Special Ice expires at the next Great Frost field reset.
If a carrier fails before deposit, return it to its origin only while its OriginCycleIndex opportunity is still current; otherwise remove it.
Carried Special Ice still survives Great Frost like any carried Ice.

Great Frost server boot
Boot during Day: populate current field immediately.
Boot during Great Frost: wait until next Day.
Do not retroactively award the launch Thaw Surge or Special Ice from a Frost transition the server did not observe.


3.27 Approved Prototype Exception - Day-5 Survival Pressure
The Development Plan v0.9 and Prototype Technical Specification v0.9 explicitly authorize the `EXP-D5` Survival Pressure Experiment.
Within those tasks only, AI/developers may implement:
- one universal swing tool;
- one stationary Frost Sprite enemy type;
- selected authored Guarded Ice encounters;
- player enemy damage as direct `CurrentWarmth` loss;
- temporary session-only Equipped-creature Vitality/Frosted state;
- minimal survival UI/feedback;
- breakable environmental obstacles only after the first survival validation gate passes/partially passes.

This exception does not approve:
- Player HP;
- permanent creature death/loss;
- creature combat AI;
- permanent combat stats;
- multiple weapons;
- weapon rarity/durability/upgrades/inventory;
- enemy drops/currency/XP/levels;
- roaming/pathfinding enemies;
- bosses;
- material currencies;
- crafting/recipes;
- generalized combat/item/ability/resource frameworks.

If an EXP implementation requires a player-facing behavior not specified by the Plan, Prototype Spec, or this Constants document, do not infer it from survival-game conventions.
Flag it.

3.28 Experiment Does Not Equal Launch Promotion
The launch documents remain authoritative for launch scope.
The presence of experiment code or config is not evidence that combat/enemies/pet Vitality belong in production.
At the End-of-Week-1 gate, record `PASS`, `PARTIAL PASS`, or `FAIL`.
Only a specifically promoted subset may enter later GDD/Launch Technical/Development Plan revisions.
If FAIL, remove/disable experiment-only gameplay before Week 2.


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
Equipped creature = Movement Speed
Pen = creatures + thawing Ice
Great Frost = primary world Ice refresh

## 5. Structural Rules

These rules are not casual balancing variables.
Player
1 Equipped creature maximum.
1 carried Ice maximum.
4 active Pen creature positions.
Unlimited owned creature counts.
Unlimited logical thawing Ice.
1 currency: Cash.
MaxWarmth has no cap.
Ice
Wilderness Ice reward is rolled server-side.
One wilderness Ice may have only one owner.
Ice cannot enter normal Inventory before thawing.
Thaw duration depends on Ice Type, not hidden rarity.
Areas
No hard Warmth gates.
Regions provide Recommended Warmth only.
Great Frost
resets only available/unclaimed wilderness Ice;
carried Ice survives;
Pen Ice survives;
Ready Ice survives;
prototype Pen Ice receives the active 10x Great Frost Thaw Boost; launch online players receive the configured launch Thaw Surge.

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

First-pass big-number progression:

```text
Region             Main Ice   Recommended Warmth   Cold Multiplier
Snowfield          Regular    100                  1x
Frozen Pass        Thick      1,000                10x
Ancient Expanse    Ancient    10,000               100x
Black Ice Hollow   Black      100,000              1,000x
Meteor Reach       Meteor     1,000,000            10,000x
```

Guidance only. Never a server access condition.

Warmth drain:

```text
WarmthDrainPerSecond =
    BaseWarmthDrain
    * RegionColdMultiplier
    * (Carrying and CarryMultiplier or 1)
```

This makes the numbers grow by orders of magnitude while keeping the physical world manageable.


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

Every configured species must define:

```text
ReferenceWeight
BaseVisualScale
BaseIncomePerSecond
BaseWalkSpeed
```

Approved D6-R06 target runtime copy values (not active until D6-R06):

```text
Scale = cbrt(WeightMultiplier)
IncomeMultiplier = Scale ^ 2
SpeedMultiplier = 1 + 0.15 * (Scale - 1)
FinalIncome = max(1, round(BaseIncomePerSecond * IncomeMultiplier))
FinalWalkSpeed = BaseWalkSpeed * SpeedMultiplier
```

At the supported extremes:

```text
0.75x Scale -> SpeedMultiplier ~= 0.9625x
1.00x Scale -> 1.00x
2.00x Scale -> 1.15x
3.00x Scale -> 1.30x
4.00x Scale -> 1.45x
5.00x Scale -> 1.60x
```

Income intentionally scales much harder:

```text
1x Scale -> 1x income
2x Scale -> 4x income
3x Scale -> 9x income
4x Scale -> 16x income
5x Scale -> 25x income
```

D6-R05 designer-approved prototype species baselines are now locked below.
Future changes still require explicit design approval.

| Creature | Rarity | ReferenceWeight kg | BaseVisualScale | BaseIncomePerSecond | BaseWalkSpeed |
|---|---|---:|---:|---:|---:|
| Penguin | Common | 25 | 1.0000 | 2 | 22 |
| Rabbit | Common | 4 | 1.0000 | 2 | 26 |
| Seal | Common | 180 | 1.0000 | 3 | 20 |
| Wolf | Uncommon | 65 | 1.0000 | 5 | 31 |
| Bear | Uncommon | 500 | 1.0000 | 7 | 26 |
| Mammoth | Rare | 6000 | 1.4373 | 15 | 30 |
| Sleipnir | Rare | 900 | 1.4798 | 10 | 39 |
| Troll | Epic | 1200 | 1.4798 | 24 | 35 |
| IceSerpent | Epic | 3000 | 2.2605 | 20 | 44 |
| Hraesvlgr | Legendary | 5000 | 1.7404 | 32 | 50 |
| Nidhogg | Legendary | 8000 | 2.1523 | 40 | 46 |

`ReferenceWeight` is the species baseline used by `ActualWeight =
ReferenceWeight * WeightMultiplier`. `BaseVisualScale` is approved species
metadata/reference. D6-R04 preserves the authored live model baseline and
applies copy SizeScale relative to it; BaseVisualScale must not be multiplied
onto the authored runtime model scale a second time. A 1.0x copy is normal-sized
for that species, not a claim that all species have identical world dimensions.

The approved 0.75x-5.0x copy Scale system remains active. BaseIncomePerSecond
and BaseWalkSpeed are configured but inactive until D6-R06; current runtime Pen
Income and Equipped WalkSpeed remain rarity-driven.


## 17. Supported Rarity / Economy Tiers

Configured economy tier labels:

1. Common
2. Uncommon
3. Rare
4. Epic
5. Legendary

All five labels are used by the active Week-1 prototype roster. This does not
automatically revise the separate launch roster or launch pools.

Current Pen-income reference baselines retained for migration/comparison only:

```text
Common       $2/sec
Uncommon     $5/sec
Rare         $12/sec
Epic         $20/sec
Legendary    $28/sec
```

These rarity Pen-income values remain migration/reference values while current
runtime income still relies on them. D6-R06 will replace gameplay reliance with
species `BaseIncomePerSecond * Scale^2`.


## 18. D6-R06 Target Creature Stat Presentation

Every visible creature copy should expose at minimum:

```text
SPEED <rounded FinalWalkSpeed>
PEN $<FinalIncome>/s
```

An Equipped creature displays its intrinsic `PEN $/s` value for comparison but earns zero while Equipped.

Extreme copy Scale should remain the primary visual signal; text is secondary.


## 19. D6-R06 Target Pen Income

Current runtime uses the existing rarity-driven aggregate Pen income. This
section records the replacement behavior for D6-R06.

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

**Common**
1. Penguin
2. Rabbit
3. Seal
4. Arctic Fox

**Uncommon**
5. Wolf
6. Polar Bear
7. Moose
8. Walrus

**Rare**
9. Mammoth
10. Sabertooth
11. Woolly Rhino
12. Raptor
13. Dire Wolf

**Legendary**
14. Yeti
15. Frost Serpent
16. Ice Dragon

Total:

16

## 22. Prototype Creature Roster

**Common**
Penguin
Rabbit
Seal
**Uncommon**
Wolf
Bear
**Rare**
Mammoth
Sleipnir
**Epic**
Troll
IceSerpent
**Legendary**
Hraesvlgr
Nidhogg

Total: 11

## 23. Launch Normal Ice Rarity Weights

These are launch-target values, not the current Week-1 prototype Regular/Thick
weights. See Section 25 for current prototype pools.

Regular Ice
```text
            Rarity              Weight
```


```text
            Common              75%
            Uncommon            23%
            Rare                2%
            Legendary           0%
```


Thick Ice
```text
            Rarity              Weight
            Common              45%
            Uncommon            45%
            Rare                10%
            Legendary           0%
```


Ancient Ice

```text
             Rarity                       Weight
             Common                       10%
             Uncommon                     40%
             Rare                         45%
             Legendary                    5%
```


Black Ice
```text
             Rarity                       Weight
             Common                       0%
             Uncommon                     20%
             Rare                         55%
             Legendary                    25%
```


Meteor Ice
```text
             Rarity                       Weight
             Common                       0%
             Uncommon                     0%
             Rare                         60%
             Legendary                    40%
```


## 24. Launch Creature Pools

Once rarity has been rolled:

choose uniformly among eligible creatures of that rarity within the current Ice
pool.
Regular
**Common**

Penguin
Rabbit
Seal
Arctic Fox
**Uncommon**
Wolf
Polar Bear
**Rare**
Mammoth
**Legendary**
None


Thick
**Common**
Seal
Arctic Fox
**Uncommon**
Wolf
Polar Bear
Moose
Walrus
**Rare**
Mammoth
Sabertooth
**Legendary**
None


Ancient
**Common**
Arctic Fox

**Uncommon**
Polar Bear
Moose
Walrus
**Rare**
Mammoth
Sabertooth
Woolly Rhino
Raptor
**Legendary**
Yeti


Black
**Common**
None
**Uncommon**
Polar Bear
Moose
**Rare**
Sabertooth
Raptor
Dire Wolf
**Legendary**
Yeti
Frost Serpent


Meteor
**Common**
None
**Uncommon**
None

**Rare**
Woolly Rhino
Raptor
Dire Wolf
**Legendary**
Yeti
Frost Serpent
Ice Dragon


## 25. Prototype Ice Pools

Only Regular and Thick are active in the current Week-1 prototype. Selection
rolls rarity from the Ice-type weights, then chooses uniformly among eligible
species in that rarity. There are no per-species weights.

**Regular — 74 / 23 / 3 / 0 / 0**

**Common**
Penguin
Rabbit
Seal
**Uncommon**
Wolf
Bear
**Rare**
Mammoth
**Epic**
None
**Legendary**
None

Total eligible species: 6

**Thick — 30 / 32 / 24 / 11 / 3**

**Common**
Seal
**Uncommon**
Wolf
Bear
**Rare**
Mammoth
Sleipnir
**Epic**
Troll
IceSerpent
**Legendary**
Hraesvlgr
Nidhogg

Total eligible species: 9

Across Regular and Thick, all 11 current prototype creatures are obtainable.


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


## 33A. Prototype Survival Pressure Experiment - First-Pass Constants

These constants are active only while the `EXP-D5` experiment is enabled.
They are intentionally simple first-pass values for rapid playtesting, not launch balance.

Universal survival tool:

```text
             Constant                         Prototype Value
             ToolServerHitRange               8 studs
             ToolSwingCooldown                0.65 sec
             ToolDamageToFrostSprite           1
```

Frost Sprite:

```text
             Constant                         Prototype Value
             FrostSpriteMaxHealth              3
             EngagementRadius                  26 studs
             AttackTelegraph                   0.75 sec
             AttackCooldown                    2.40 sec
             ProjectileSpeed                   40 studs/sec
             PlayerWarmthDamagePerHit           10
             CreatureVitalityDamagePerHit       25
             TargetingRule                     nearest valid target
```

Target locks when the telegraph begins.

Equipped creature experimental state:

```text
             Constant                         Prototype Value
             CreatureVitalityMax               100
             FrostedAtVitality                  0
             FrostedSpeedBonusEnabled           false
             HearthRecovery                     full restore on Hearth entry
```

Hearth recovery means a valid entry into the player's Hearth/WarmZone immediately restores full experimental Vitality, clears Frosted, and restores the Equipped Speed bonus.

Guarded Ice authoring target for the first test:

```text
             Encounter Profile                Guardian Count
             Light Guarded Regular             1 Frost Sprite
             Medium Guarded Thick              2 Frost Sprites
             Heavy Guarded Thick               3 Frost Sprites
             Maximum Guarded Encounters        3 authored Ice opportunities
```

All remaining prototype Ice opportunities should remain unguarded.
Do not add random enemy population or independent enemy respawn timers.
Great Frost clears and rebuilds active guardians with the Ice field.

Conditional breakable-environment test - only after PASS/PARTIAL PASS:

```text
             Breakable                        Hits To Break
             Frozen Branch                    3
             Brittle Rock / Ice Rock           5
```

Breakables grant no Wood, Stone, currency, XP, drops, or crafting materials.

Balance note:
These values are allowed to change during the survival playtest as explicit balance changes.
Changing them does not authorize new mechanics.


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


## 35. Prototype Thaw Durations

```text
            Ice                                 Prototype Time
            Regular                             20 sec
            Thick                               45 sec
```


These values are validation overrides only.


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
spawns in addition to normal population;
modifies a normal Ice Type;
uses a valid authored spawn position;
is shared/contestable;
follows normal carry rules.
stores OriginCycleIndex and OriginSpawnPointID;
expires from the shared field at the next Great Frost if still unclaimed;
returns to its origin after carrier failure/disconnect only while its originating opportunity remains current;
disappears on such a failure if a newer Great Frost has superseded that opportunity.
Eligible Types:

Ancient / Black / Meteor
Selection:

```text
               Type                          Weight
               Ancient                       50%
               Black                         30%
               Meteor                        20%
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
Hit #2 may use subtle:
glow;
sound.
**Legendary**
Hit #2 may use stronger:
glow;
particles;
sound.
Exact rarity is revealed on final Smash.

## 44. Silhouette Information Rule

Silhouette is a:

hint, not guaranteed exact identification.
Desired progression:

vague at distance
-> suggestive nearby
-> clearer during thaw
-> nearly recognizable near Ready
-> exact identity on reveal
Several creatures may share a silhouette profile.

Canonical launch SilhouetteProfile mapping:

```text
            Profile              Creatures
            Compact              Penguin / Rabbit / Seal
            AgileQuadruped       Arctic Fox / Wolf
            HeavyBeast           Polar Bear / Walrus
            Antlered             Moose
            GiantAncient         Mammoth / Woolly Rhino
            AncientPredator      Sabertooth / Raptor / Dire Wolf
            MythicUnknown        Yeti / Frost Serpent / Ice Dragon
```


Profiles are deliberately coarser than exact species. Presentation may obscure/distort further at distance. `Antlered` currently maps only to Moose; that is acceptable because the global rule is hint-not-guaranteed-identification where practical, not mandatory ambiguity for every species.


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
             EXP Survival Tool Hit                  8 studs (prototype only)
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
             EXP Survival Tool Swing               0.65 sec (prototype only)
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
Creature becomes Equipped.
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


## 53. Follower Presentation

Follower is cosmetic.
Recommended behavior:
```text
              1 Desired position behind player
              2 -> smooth interpolation
              3 -> snap closer when too far away
```


Do not use:

server-heavy pathfinding;
Humanoid AI;
follower position for gameplay calculations.


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
up to 4 personal bases;
grouped side-by-side along one shared home-camp edge;
all face the same primary wilderness direction.

Each player has one assigned personal base.
Warmth training occurs only in own Hearth/WarmZone.
Current Warmth refill also occurs only in own WarmZone.
Another player's WarmZone is visual/social space only for the visitor and provides no refill/training.
Deposit occurs only at own Pen.
Hearth upgrades only at own base.
Pen management only at own base.
Equip/Sell only at own base.
Reveals occur at own Pen.
Other players cannot manipulate another player's base progression.

Each base should contain one authored OnboardingIceSpawnPoint for the launch-only private onboarding exception.

## 57. Persistent Data - Launch

```text
            1     DataVersion = 1
            2
            3     Cash
            4
            5     MaxWarmth
            6     HearthLevel
            7
            8     OwnedCreatures
            9     PenSlots
           10     EquippedCreature
           11     DiscoveredCreatures
           12
           13     ThawingIce
```


Do not persist:
CurrentWarmth;
carried Ice;
RevealSession;
world position;
Frozen state;
follower position.


## 58. Join Defaults

New player:
```text
            1     Cash = 0
            2
            3     MaxWarmth = 70
            4     CurrentWarmth = 70
            5
            6     HearthLevel = 1
            7
            8     OwnedCreatures = {}
            9     PenSlots = {nil, nil, nil, nil}
           10     EquippedCreature = nil
           11
           12     DiscoveredCreatures = {}
           13     ThawingIce = {}
```


On every valid rejoin:
```text
             1 CurrentWarmth = MaxWarmth
```


Launch onboarding configuration:
OnboardingIceEnabled = true
OnboardingIceType = Regular
OnboardingIcePrivate = true
OnboardingIceAffectedByGreatFrost = false

Eligibility is derived from existing state:
DiscoveredCreatures is empty;
ThawingIce is empty;
no carried Ice.
No extra persistent onboarding boolean is required.

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


## 68. Prototype Special Ice

Week 1:
```text
             1 PrototypeSpecialIceEnabled = false
```


P2 stretch only.
Do not allow it to delay prototype P0/P1 validation.


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


## 76A. SurvivalExperiment Configuration - Prototype Only

If the Day-5 experiment is enabled, keep its tunable values in one small prototype-only configuration surface such as:

```text
             1 SurvivalExperimentConfig
```

It may define only the values required by the approved experiment:
- tool range/cooldown/damage;
- Frost Sprite health/radius/telegraph/cooldown/projectile speed/damage;
- temporary creature Vitality;
- authored guard-profile counts;
- conditional breakable hit counts.

Do not use this module as the seed of a generic combat/item/ability framework.
If the experiment fails, it should be straightforward to disable/remove its config and implementation.


## 77. Structural State Invariants

Always preserve:
```text
             1 0 <= CurrentWarmth <= MaxWarmth
```

When the survival experiment is enabled:
```text
             1 0 <= CreatureVitality <= CreatureVitalityMax
             2 CreatureVitality is session-only and applies only to the currently Equipped creature
             3 Frosted/Downed never changes creature ownership
             4 Frosted/Downed suppresses only the Equipped Speed bonus until Hearth recovery
```


```text
             1 MaxWarmth >= StartingMaxWarmth
```


```text
             1 0 <= carried Ice count <= 1
```


```text
             1 0 <= Equipped creature count <= 1
```


```text
             1 Active Pen creature count <= 4
```


```text
             1 PenCopies + EquippedCopies <= OwnedCopies
```


```text
             1 Each wilderness Ice has at most one OwnerUserID
```


```text
             1 Each ThawItem grants at most one creature
```

Carried raw Ice has no normal Inventory representation.
There is no intentional DropIce action.

There is intentionally:

no gameplay maximum for logical ThawItems.

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
Equipped creature = Speed;
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

Creature Speed = how much distance I cover during that time

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

The first-pass launch build uses:

100 Starting MaxWarmth

4 Warmth/sec normal drain

7 Warmth/sec while carrying

uncapped MaxWarmth training

10 Hearth levels

16 / 20 / 24 / 28 / 32 movement progression

4 active Pen creatures

1-second aggregate Pen income interval

unlimited logical thawing Ice

1 / 3 / 7 / 15 / 25-minute thaw times

5-minute Great Frost cycle

15% online Thaw Surge

Special Ice every 3 Frost cycles

5 Ice types

16 creatures

4 rarities

1 currency

3-hit CRACK -> CRACK -> SMASH reveal
These numbers are the values the launch implementation should start with.
They are not permission for an AI assistant to reinterpret the underlying systems.

Current Week-1 prototype validation overrides additionally use:
- `2.00x` carry multiplier -> `8 Warmth/sec` while carrying;
- `16 / 22 / 28 / 34` None/Common/Uncommon/Rare WalkSpeed;
- `GreatFrostThawMultiplier = 10` only while the prototype Great Frost phase is active;
- the Section 33A Survival Pressure constants only while the approved experiment is enabled.

Prototype experiment values are not launch defaults.


## 85A. v0.9 Revised Canonical Progression Summary

The current approved first-pass prototype direction additionally uses:

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
Prototype Hearth training: 10 / 50 / 250 / 1,250 / 6,250 / 31,250 per second
```

These values are first-pass tuning values. The structural design is the inherited size jackpot + per-copy ownership + big-number Warmth progression. Balance may change without reverting that architecture.

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
