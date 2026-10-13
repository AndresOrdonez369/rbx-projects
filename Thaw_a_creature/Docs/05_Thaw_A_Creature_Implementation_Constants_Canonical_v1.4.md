# THAW A CREATURE

## Implementation Constants & Content Configuration - Canonical v1.4

**Purpose:** Exact first-pass values, content tables, implementation constraints, and AI guardrails  
**Design Source:** Concise GDD v1.0  
**Prototype Source:** Bare-Minimum Prototype Technical Specification v1.0 FINAL  
**Launch Source:** Technical Implementation Specification v1.0  
**Development Source:** Development Plan v1.4  
**Status:** Numerical values are first-pass balancing values unless explicitly structural  

### Revision notes

- Adds Grab Hold constants: visible-Scale range `0.75x-5.00x`, hold range `1.00-2.00 sec`, first-pass linear interpolation, no reservation on hold start.
- Adds Carrier Commitment structural rules and canonical intentional DropIce, including a first-pass `0.75 sec` same-player self-regrab lock.
- Refines Wilderness Contest constants for mounted play: `25% of CreatureVitalityMax` per validated PvP forced knock-off and per valid mounted-carrier mount hit; carrier player/ice remain protected; existing Frosted behavior resolves at zero Vitality.
- Adds Home Camp / Lobby Safe-Zone rules: zero Warmth drain throughout the shared lobby, including while carrying Ice; only the owner's own WarmZone refills/trains and restores Frosted companion Vitality.
- Adds Frosted Companion Orb presentation constants while preserving session-only Frosted state and logical Equipped ownership.
- Adds seven Pen levels with capacity `4 -> 10`, fixed width `32`, depth `24 -> 48`, and approved Cash upgrade costs `150K / 2.5M / 10M / 40M / 150M / 750M`.
- Records player-chosen session thaw placement inside the Pen as presentation-only state; exact placement CFrames do not persist and logical thaw capacity remains unlimited.
- Corrects §33A Frost Sprite regional Warmth damage to the canonical `10 / 100 / 4,000 / 250,000 / 8,000,000`.
- Raises the approved launch roster to 20 species / four signature creatures per region and defines region-exclusive normal-Ice pools.
- Rebalances BaseIncomePerSecond across all 20 launch species into overlapping regional economic bands while preserving the existing Scale^2 income formula.
- Keeps existing 11-species BaseWalkSpeed values and adds controlled BaseWalkSpeed values for the nine new launch species.
- Allows the nine new species to use placeholder meshes; final ReferenceWeight/BaseVisualScale/SilhouetteProfile values remain provisional until actual asset audits.
- Replaces the prototype six-level Hearth table with the approved 10-level launch costs and Warmth training rates.
- Updates Recommended Warmth to 100 / 1,000 / 40,000 / 2,500,000 / 80,000,000 with corresponding cold multipliers and 10%-of-recommendation Sprite damage.
- Changes Special Ice rarity weights to 90% Rare / 10% Legendary in Ancient, Black, and Meteor.
- Expands Frozen Archive to 20 slots and records Sell as a low-value cleanup payout whose exact Day-14 constants remain intentionally secondary to Pen income.


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
- Updates persistence boundaries for session-only survival state.

## 1. Document Authority

For launch production after the successful Week-1 gate:
1. Concise GDD v1.0 - player-facing intent.
2. Launch Technical Implementation Specification v1.0 - production behavior/architecture.
3. This Constants v1.4 - exact first-pass values/content configuration and AI guardrails.
4. Development Plan v1.4 - implementation order/gates.
5. Prototype Technical Specification v1.0 FINAL - historical Week-1 validation evidence.

If a value in this document conflicts with an older document version, this v1.4 value supersedes it unless the higher-authority current document explicitly says otherwise.

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

CarryDrainMultiplier = 2.00.
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

Ice Grab interaction
Wilderness Ice requires a continuous size-scaled hold. First-pass hold scales linearly from `1.00 sec` at `0.75x` visual Scale to `2.00 sec` at `5.00x`. Starting a hold does not reserve the Ice. First valid completed hold accepted by the server wins.

Carrier action set
After successful Grab, the player enters Carrier Commitment. Allowed gameplay actions are movement, jump, Ride/Unride, intentional DropIce, and valid own-Pen deposit/placement. Survival attacks, breakables, other Grab attempts, creature management, Sell, upgrades, reveal, and unrelated progression interactions are rejected while carrying.

Intentional raw-Ice drop
Available through the canonical server-authoritative `DropIce` request. It preserves exact Ice identity/reward/size/Special metadata, returns the Ice to shared `Available` state at a valid safe grounded position, never rerolls, and never directly trades/transfers ownership. The original dropper uses the configured same-player self-regrab lock before starting another full Grab Hold.

Universal shared Ice
Every spawned wilderness Ice is one authoritative shared server object. No private/per-player copies. The first valid completed Grab Hold accepted by the server wins.

Mounted wilderness contest
A validated PvP contest hit against a mounted non-carrier force-Unrides/ragdolls the player and removes `25% of CreatureVitalityMax` from the Equipped creature. A mounted carrier is not player-ragdolled/knocked off while mount Vitality remains above zero; instead a valid hit removes the same `25%` mount Vitality. At zero, normal Frosted/Downed forces Unride while the exact carried Ice remains carried.

Carrier failure
Freeze, character death, Reset Character/respawn, or disconnect releases the exact carried Ice at the last valid safe position. Ownership clears; any player may rescue it after satisfying normal Grab Hold rules. No reward/rarity/WeightMultiplier/Scale reroll.

Freeze / normal respawn recovery
Return to own base and set CurrentWarmth = MaxWarmth immediately. Restore the currently Equipped creature from Frosted/Downed. Permanent progression is preserved.

Launch base topology
Up to four personal plots are grouped side-by-side along one shared home-camp edge. All plots face the same primary wilderness direction.

Visitor Hearth behavior
Another player's WarmZone does not refill CurrentWarmth, train MaxWarmth, or restore the visitor's creature Vitality.

Onboarding
No private onboarding Ice. Guide/retarget eligible new players toward available shared Regular Ice; if none exists, communicate the next shared refresh.

Special Ice lifecycle
Special Ice follows the universal shared-Ice failure/drop identity-preservation rules. On carrier failure or intentional Drop it preserves exact reward/size/Special metadata; a later Great Frost may remove it if still unclaimed.

Great Frost server boot
Boot during Day: populate current field immediately. Boot during Great Frost: wait until next Day. Do not retroactively award the launch Thaw Surge or Special Ice from a Frost transition the server did not observe.


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
- active Pen creature capacity = `PenCapacity(PenLevel)`, from 4 at Lv1 through 10 at Lv7;
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
- intentional DropIce is allowed and preserves exact Ice identity/reward/size/Special metadata;
- every Available Ice claim requires the canonical size-scaled Grab Hold;
- starting a hold never reserves the Ice;
- rescue/relay is allowed;
- while carrying, Carrier Commitment restricts gameplay actions to move/jump/Ride-Unride/Drop/deposit-placement.

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


## 9. Hearth Progression - Launch First Pass

The Week-1 six-level Hearth proved the mechanic. Launch uses ten levels with a deliberately longer minutes-to-hours progression curve and increasingly large visible training numbers.

| Hearth Lv. | Upgrade Cost | Warmth Training Rate |
|---:|---:|---:|
| 1 | Start | +3/sec |
| 2 | $5,000 | +5/sec |
| 3 | $100,000 | +30/sec |
| 4 | $500,000 | +50/sec |
| 5 | $2,000,000 | +500/sec |
| 6 | $10,000,000 | +1,000/sec |
| 7 | $50,000,000 | +5,000/sec |
| 8 | $250,000,000 | +10,000/sec |
| 9 | $2,000,000,000 | +50,000/sec |
| 10 | $10,000,000,000 | +100,000/sec |

Functional rules are structural:
- Hearth upgrade never grants a fixed MaxWarmth amount;
- Hearth level only changes ongoing automatic training rate;
- MaxWarmth remains uncapped;
- only the player's own Hearth trains MaxWarmth;
- exact balance values remain first-pass and may be tuned through explicit playtest revisions.

Pacing intent:
- early region preparation is measured in minutes;
- midgame preparation is measured in tens of minutes / around an hour;
- late-game preparation is measured in hours;
- faster mounts and jackpot copies may sequence-break recommendations without turning them into hard gates.

## 10. Hearth Visual Stages

Existing approved/prototype presentation labels may continue where useful:

```text
Lv.1       Small Hearth
Lv.2       Strong Hearth
Lv.3       Iron Brazier
Lv.4       Runic Hearth
Lv.5       Frostfire Forge
Lv.6       Great Runic Furnace
```

Lv.7-Lv.10 may use explicit placeholder/reused `VisualStage` references until the world-art pass defines final presentation. Do not block mechanical 10-level progression on ten unique production meshes or invent permanent art names merely to satisfy config.

Presentation may reuse geometry with stronger flame/light/runes/scale.

Always communicate:

```text
HEARTH LV. X
TRAINING +<rate> WARMTH/s
NEXT $<cost> / MAX
```

## 11. Region Recommended Warmth + Cold Severity

First-pass launch progression:

| Region | Main Ice | Recommended Warmth | Cold Multiplier | Base Drain/s | Carry Drain/s | Sprite Warmth Damage/Hit |
|---|---|---:|---:|---:|---:|---:|
| Snowfield | Regular | 100 | 1x | 4 | 8 | 10 |
| Frozen Pass | Thick | 1,000 | 5x | 20 | 40 | 100 |
| Ancient Expanse | Ancient | 40,000 | 125x | 500 | 1,000 | 4,000 |
| Black Ice Hollow | Black | 2,500,000 | 6,250x | 25,000 | 50,000 | 250,000 |
| Meteor Reach | Meteor | 80,000,000 | 150,000x | 600,000 | 1,200,000 | 8,000,000 |

Recommended Warmth is guidance only. Never a server access condition.

Home Camp / Lobby Safe Zone:
```text
InsideHomeCampSafeZone and not inside own WarmZone:
    CurrentWarmth change = 0
    MaxWarmth training = 0
```

This remains true while carrying Ice. The Safe Zone does not refill CurrentWarmth, train MaxWarmth, or recover a Frosted companion by itself. Only the player's **own** WarmZone provides those benefits. Another player's WarmZone remains social-only.

Warmth drain applies only outside the Home Camp / Lobby Safe Zone:

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

Structural first-pass relationship:

```text
RegionFrostSpriteWarmthDamage = RegionRecommendedWarmth * 0.10
```

The configured regional damage value is authoritative.
Do not scale Sprite damage from player `MaxWarmth`, Ice rarity, Ice size, hidden creature, or Special status.
Special Ice uses its spawn region's damage value.

Approximate training-pacing benchmarks at the intended Hearth pair for each transition:

```text
100 -> 1,000                 about 3-5 min
1,000 -> 40,000              about 13-22 min
40,000 -> 2,500,000          about 41-82 min
2,500,000 -> 80,000,000      about 2.2-4.3 hr
80,000,000 -> ~2.5B          about 6.7-13.4 hr (post-Meteor benchmark)
```

These are balance targets, not access rules.

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

Launch first-pass gameplay baseline:

| Region | Creature | Rarity | BaseIncome/s | BaseWalkSpeed |
|---|---|---|---:|---:|
| Regular | Penguin | Common | 10 | 22 |
| Regular | Rabbit | Common | 12 | 26 |
| Regular | Seal | Common | 15 | 20 |
| Regular | Wolf | Uncommon | 30 | 31 |
| Thick | White Stag | Common | 100 | 34 |
| Thick | Bear | Uncommon | 200 | 26 |
| Thick | Sleipnir | Rare | 500 | 39 |
| Thick | Troll | Epic | 3,000 | 35 |
| Ancient | Sabertooth | Common | 1,000 | 37 |
| Ancient | Mammoth | Rare | 2,500 | 30 |
| Ancient | IceSerpent | Epic | 7,500 | 44 |
| Ancient | Tyrannosaurus | Legendary | 30,000 | 33 |
| Black | Giant Spider | Common | 10,000 | 40 |
| Black | Dreadmare | Uncommon | 25,000 | 48 |
| Black | Manticore | Rare | 60,000 | 44 |
| Black | Hraesvlgr | Legendary | 300,000 | 50 |
| Meteor | Griffin | Common | 100,000 | 49 |
| Meteor | Kirin | Rare | 250,000 | 52 |
| Meteor | Phoenix | Epic | 600,000 | 50 |
| Meteor | Nidhogg | Legendary | 3,000,000 | 46 |

Existing production-asset reference values remain:

| Creature | ReferenceWeight kg | BaseVisualScale |
|---|---:|---:|
| Penguin | 25 | 1.0000 |
| Rabbit | 4 | 1.0000 |
| Seal | 180 | 1.0000 |
| Wolf | 65 | 1.0000 |
| Bear | 500 | 1.0000 |
| Mammoth | 6,000 | 1.4373 |
| Sleipnir | 900 | 1.4798 |
| Troll | 1,200 | 1.4798 |
| IceSerpent | 3,000 | 2.2605 |
| Hraesvlgr | 5,000 | 1.7404 |
| Nidhogg | 8,000 | 2.1523 |

Asset-dependent fields for these nine new species remain intentionally provisional until their production models exist:

```text
White Stag
Sabertooth
Tyrannosaurus
Giant Spider
Dreadmare
Manticore
Griffin
Kirin
Phoenix

ReferenceWeight = TBD from final asset/content audit
BaseVisualScale = TBD from final asset/content audit
SilhouetteProfile = provisional placeholder allowed during Day 11
ModelName = functional placeholder allowed during Day 11
```

Day 11 may use provisional values sufficient for placeholder runtime presentation. Those values are not canonical final art values and must not override the approved rarity, region, BaseIncomePerSecond, or BaseWalkSpeed.

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

Economic design rule:
- Income = exponential regional progression;
- Speed = controlled species progression;
- Rarity = collection desirability / exceptional species result inside the region;
- Size = individual-copy jackpot multiplier.

Adjacent regional value bands intentionally overlap. A previous-region apex can outperform the next region's first one or two results, while the next region's upper tiers normally overtake it at equal Scale. Exceptional size rolls may break that ordering.


## 17. Supported Rarity / Presentation Tiers

Configured rarity labels:

1. Common
2. Uncommon
3. Rare
4. Epic
5. Legendary

Rarity does **not** directly determine Pen Income or Equipped Speed. Those are species baselines modified by copy Scale.

SellValue remains a separate low-value cleanup economy. Exact SellValue constants are deferred to Day 14 and must remain intentionally small relative to recurring Pen income. Do not infer SellValue from BaseIncome, rarity, or `Scale^2` without an explicit balance decision.

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

Launch quantity target: **20 species**.
Exactly four signature creatures belong to each geographic region:

```text
REGULAR / SNOWFIELD
Common      Penguin, Rabbit, Seal
Uncommon    Wolf

THICK / FROZEN PASS
Common      White Stag
Uncommon    Bear
Rare        Sleipnir
Epic        Troll

ANCIENT / ANCIENT EXPANSE
Common      Sabertooth
Rare        Mammoth
Epic        IceSerpent
Legendary   Tyrannosaurus

BLACK / BLACK ICE HOLLOW
Common      Giant Spider
Uncommon    Dreadmare
Rare        Manticore
Legendary   Hraesvlgr

METEOR / METEOR REACH
Common      Griffin
Rare        Kirin
Epic        Phoenix
Legendary   Nidhogg
```

The nine new species may use placeholder meshes until final production assets are available.

Creature-source rule: real animals, extinct animals, Norse mythology, worldwide folklore/myth, and original fantasy are all valid when the regional family remains coherent and immediately readable/desirable.

## 22. Current Functional Creature Roster

The launch content target is the 20-species roster above.

The existing 11 production meshes remain valid historical/asset foundations, but their launch BaseIncome values and normal geographic pool assignments are superseded by this v1.2 configuration.
The nine new species may be represented by functional placeholders during Day 11.

## 23. Normal Geographic Ice Rarity Weights

Weights are ordered:

```text
Common / Uncommon / Rare / Epic / Legendary
```

```text
Regular   80 / 20 / 0  / 0  / 0
Thick     60 / 25 / 11 / 4  / 0
Ancient   60 / 0  / 25 / 11 / 4
Black     60 / 25 / 11 / 0  / 4
Meteor    60 / 0  / 25 / 11 / 4
```

Every row totals 100.

Design rule:

> Farther Ice does not guarantee a better rarity. It guarantees a more extraordinary creature fantasy/economic band.

## 24. Region-Exclusive Creature Pools

Normal geographic Ice pools are region-exclusive.
Once rarity is rolled, choose from the approved species of that rarity within the current region. Do not automatically inherit earlier-region creatures.

### Regular
- Common: Penguin, Rabbit, Seal (uniform among the three)
- Uncommon: Wolf
- Rare: none
- Epic: none
- Legendary: none

### Thick
- Common: White Stag
- Uncommon: Bear
- Rare: Sleipnir
- Epic: Troll
- Legendary: none

### Ancient
- Common: Sabertooth
- Uncommon: none
- Rare: Mammoth
- Epic: IceSerpent
- Legendary: Tyrannosaurus

### Black
- Common: Giant Spider
- Uncommon: Dreadmare
- Rare: Manticore
- Epic: none
- Legendary: Hraesvlgr

### Meteor
- Common: Griffin
- Uncommon: none
- Rare: Kirin
- Epic: Phoenix
- Legendary: Nidhogg

## 25. Deprecated Prototype Pool Tables

Earlier cumulative 8-species/11-species geographic pool tables are historical and superseded for launch by Sections 23-24.

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
Ancient Expanse    4,000
Black Ice Hollow   250,000
Meteor Reach       8,000,000
```

Do not use one flat player-damage value across all regions.

Equipped creature state:

```text
CreatureVitalityMax               100
FrostedAtVitality                 0
FrostedSpeedBonusEnabled          false
FrostedPresentationProfile        FrostedCompanionOrb
FrostedOrbTargetable              false
FrostedRecoverySource             OwnWarmZoneOnly
HearthRecovery                    full restore on OWN Hearth entry
```

Grab Hold baseline:

```text
GrabHoldMinScale                           0.75
GrabHoldMaxScale                           5.00
GrabHoldMinSeconds                         1.00 sec
GrabHoldMaxSeconds                         2.00 sec
GrabHoldInterpolation                      Linear (first pass)
GrabHoldReservesIce                        false
DropIceSelfRegrabLock                      0.75 sec
```

First-pass formula:

```text
NormalizedScale = clamp((Scale - 0.75) / (5.00 - 0.75), 0, 1)
GrabHoldSeconds = lerp(1.00, 2.00, NormalizedScale)
```

Player contest baseline:

```text
PlayerContestEnabled                       true
PlayerContestWildernessOnly                true
PlayerContestHomeCampSafe                  true
PlayerContestRagdollDuration               1.25 sec
PlayerContestPostRecoveryImmunity          1.75 sec
PlayerContestMountedCarrierHitGrace        1.75 sec
PlayerContestMountDamageFraction           0.25 of CreatureVitalityMax
PlayerContestDamageToPlayerHP              0
PlayerContestDamageToWarmth                0
PlayerContestForcesIceDrop                 false
CarrierCanUseSurvivalAttack                false
CarrierOnFootPlayerContestImmune           true
CarrierMountedPlayerRagdollImmune          true
CarrierMountedMountDamageEnabled           true
```

Knockback strength/direction remains a designer-tunable feel value to be locked by multiplayer playtest. It must be strong enough to create a meaningful pre-Grab window without becoming a map-launch/grief tool. Mount damage never scales from species, rarity, Scale, WeightMultiplier, Speed, velocity, or visual mass.

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

```text
Rare        90%
Legendary   10%
```

The same first-pass rarity split applies to Ancient, Black, and Meteor Special Ice.

Eligible regional creature mapping:

```text
Ancient   Rare Mammoth      / Legendary Tyrannosaurus
Black     Rare Manticore    / Legendary Hraesvlgr
Meteor    Rare Kirin        / Legendary Nidhogg
```

Creature remains restricted to that Ice Type's approved regional family.
Special Ice does not add earlier-region creatures or reroll outside that family.

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

White Stag, Sabertooth, Tyrannosaurus, Giant Spider, Dreadmare, Manticore, Griffin, Kirin, and Phoenix may use provisional placeholder `SilhouetteProfile` assignments during Day 11. Final profiles are approved from the actual production models; do not canonize guessed final silhouettes before those assets exist.

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
             Pen Upgrade                            25 studs
             Equip / Sell                           25 studs
             Survival Attack Hit                    8 studs
```


These are server-validation distances.
Prompt display distance may differ. The player must remain within server-valid Grab distance for the full Grab Hold; leaving range cancels/reset progress.


## 46. Request Rate Limits

```text
             Action                                 Minimum Interval
```


```text
             GrabIce                              0.35 sec
             DropIce                              0.50 sec
             DepositCarriedIce                    0.50 sec
             BeginReveal                          0.50 sec
             Crack                                0.20 sec
             Equip / Unequip                      0.25 sec
             Pen Management                       0.25 sec
             Sell                                 0.25 sec
             UpgradeHearth                        0.50 sec
             UpgradePen                           0.50 sec
             Survival Attack                       0.65 sec
```


These are technical anti-spam protections, not intended gameplay cooldowns.


## 47. Pen Rules

Launch Pen progression:

| Pen Level | Active Earning Capacity | Width X | Depth Z | Upgrade Cost |
|---|---:|---:|---:|---:|
| 1 | 4 | 32 | 24 | Start |
| 2 | 5 | 32 | 28 | 150,000 |
| 3 | 6 | 32 | 32 | 2,500,000 |
| 4 | 7 | 32 | 36 | 10,000,000 |
| 5 | 8 | 32 | 40 | 40,000,000 |
| 6 | 9 | 32 | 44 | 150,000,000 |
| 7 | 10 | 32 | 48 | 750,000,000 |

Rules:
- X width never changes; every upgrade adds `+4 Z` and `+1` active earning creature;
- all seven levels use normal Cash progression; no Robux capacity;
- no downgrade;
- duplicates allowed;
- thawing Ice consumes zero creature capacity;
- Pen creatures earn income;
- Equipped creature earns no Pen income;
- Sell from Pen leaves logical slot empty;
- Equip from Pen leaves logical slot empty;
- no automatic Inventory refill;
- logical `PenSlots[1..10]` are invisible bookkeeping only; active creature visuals roam the shared unlocked Pen area.


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

Inventory:
```text
OwnedCount -= 1
Cash += SellValue
```

Pen:
```text
Clear Pen Slot
OwnedCount -= 1
Cash += SellValue
```

Equipped:
```text
Unequip
OwnedCount -= 1
Cash += SellValue
RecalculateSpeed
```

Archive discovery remains.

Economy intent:

> **Sell = inventory cleanup + small consolation payout.**

Exact SellValue constants are a Day-14 balance decision. They must remain low enough that selling does not compete with keeping strong creatures in the Pen. Do not automatically apply the full `Scale^2` Income multiplier to SellValue.

## 52. Frozen Archive

Launch:

```text
20 slots
X / 20
```

Undiscovered:

```text
???
```

Discovered:
- name;
- rarity;
- icon/visual.

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

The player's one survival attack becomes Mounted Strike while Riding. When **not carrying Ice**, it uses the same `8`-stud effective range, `0.65`-second cooldown, server authority, and approved target rules as on foot, including wilderness contest targets. Carrier Commitment disables Mounted Strike while carrying. Mounted Strike uses a logical ground/front combat origin so giant mounts can hit nearby ground-level Sprites/player targets without gaining extra reach. No species/rarity/Scale/Speed/velocity scaling and no trample/contact damage. A validated contest forced-Unride against a mounted non-carrier applies `0.25 * CreatureVitalityMax`; a mounted carrier instead takes the same mount-Vitality fraction without player ragdoll/knockback unless that hit reaches Frosted zero.


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

PenLevel = 1..7
PenSlots[1..10] = CreatureGUID or nil
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
PenSlots[1..10] = nil
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
CreatureID
DisplayName
Rarity
ModelName
SilhouetteProfile
ReferenceWeight
BaseVisualScale
BaseIncomePerSecond
BaseWalkSpeed
```

Species owns baseline Income and Speed. Do not derive those values from RarityConfig.

For the nine new Day-11 species, `ModelName` may point to a functional placeholder mesh. Placeholder `ReferenceWeight`, `BaseVisualScale`, and `SilhouetteProfile` may be provisional until final asset audit; the approved rarity, regional pool, BaseIncomePerSecond, and BaseWalkSpeed remain authoritative.

RarityConfig should define rarity-facing presentation and any explicitly approved low-value Sell baseline, for example:

```text
SellValue
RevealPresentationProfile
RarityUI
EffectsProfile
```

SellValue is intentionally secondary to Pen income and must not be inferred as a major progression reward.

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

2.00x
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
- temporary Equipped-creature Vitality and Frosted state;
- player-contest ragdoll/grace and mounted `CreatureVitality` damage fraction;
- Grab Hold duration/Scale endpoints and interpolation;
- DropIce self-regrab lock;
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
0 <= active Pen creatures <= PenCapacity(PenLevel) <= 10
```

Shared Ice:
- one IceInstanceID = one server-wide opportunity;
- at most one owner/carrier;
- carrier failure releases the exact Ice and clears owner;
- intentional DropIce releases the exact Ice and clears owner;
- no reroll across Drop/release/rescue;
- no private wilderness Ice copies;
- an Ice remains unowned/Available while Grab Hold is in progress; only completion may atomically assign carrier;
- while carrying, Carrier Commitment is server-enforced.

Survival:

```text
0 <= CreatureVitality <= CreatureVitalityMax
```

- Vitality is session-only and applies only to the currently Equipped creature;
- Frosted/Downed never changes creature ownership;
- Frosted/Downed forces Unride, blocks Ride, and removes mounted Speed until own-Hearth/failure recovery;
- Frost Sprite player hits reduce CurrentWarmth only;
- validated PvP forced-Unride of a mounted non-carrier removes exactly the configured fraction of `CreatureVitalityMax`;
- validated PvP hit on a mounted carrier removes the configured mount-Vitality fraction but never directly ragdolls/knocks back the carrier or forces Ice drop;
- Carrier Commitment disables player survival attacks while carrying;
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
PenLevel-based active capacity `4 -> 10`;
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
- Carry multiplier `2.00x`;
- Hearth refill `50% of MaxWarmth/sec`;
- Low/Critical thresholds `35% / 15%`;
- uncapped MaxWarmth training;
- 10 Hearth levels with rates `3 / 5 / 30 / 50 / 500 / 1,000 / 5,000 / 10,000 / 50,000 / 100,000` per second;
- Hearth upgrade costs `Start / 5K / 100K / 500K / 2M / 10M / 50M / 250M / 2B / 10B`;
- 7 Pen levels with `4 -> 10` active Pen creatures;
- 1-second aggregate Pen income;
- unlimited logical thawing Ice;
- 5 geographic Ice tiers;
- one shared Ice field per server;
- exact-Ice carrier-failure release/rescue;
- 20 approved launch creature species / four signature creatures per region;
- nine new species may use placeholder meshes until final art audit;
- region-exclusive normal Ice families;
- five rarities: Common / Uncommon / Rare / Epic / Legendary;
- per-copy CreatureGUID ownership;
- one inherited Ice WeightMultiplier;
- `0.75x-5.0x` supported visual Scale;
- `FinalIncome = max(1, round(BaseIncomePerSecond * Scale^2))`;
- `FinalWalkSpeed = BaseWalkSpeed * (1 + 0.15*(Scale-1))`;
- Recommended Warmth `100 / 1,000 / 40,000 / 2,500,000 / 80,000,000`;
- regional Cold Multipliers `1 / 5 / 125 / 6,250 / 150,000`;
- regional Frost Sprite Warmth damage `10 / 100 / 4,000 / 250,000 / 8,000,000`;
- Special Ice Rare/Legendary split `90% / 10%` for Ancient/Black/Meteor;
- universal survival tool;
- stationary Frost Sprites;
- Guarded Ice across all tiers;
- session-only Equipped-creature Vitality/Frosted;
- breakable route obstacles;
- one currency;
- low-value Sell cleanup path;
- Frozen Archive `X / 20`;
- 3-hit CRACK -> CRACK -> SMASH reveal.

Launch Great Frost cadence/thaw behavior and production thaw durations remain defined in their dedicated sections and may differ from Week-1 validation overrides.

## 85A. v1.4 Revised Canonical Progression Summary

```text
Per-copy CreatureGUID ownership
One inherited Ice WeightMultiplier per creature copy
0.75x-5.0x visual Scale
Scale = cbrt(WeightMultiplier)
IncomeMultiplier = Scale^2
SpeedMultiplier = 1 + 0.15 * (Scale - 1)
20 launch species / 4 signature creatures per region
Normal Ice pools are region-exclusive
Region = fantasy/economic band
Rarity = exceptional species result within region
Size = exceptional individual-copy jackpot
Pen levels 1-7: capacity 4-10, width 32, depth 24-48
Pen upgrade costs: Start / 150K / 2.5M / 10M / 40M / 150M / 750M
1-second aggregate Pen income
Home Camp/Lobby: zero Warmth drain; own WarmZone only for refill/training/recovery
100 starting MaxWarmth
50% MaxWarmth/sec Hearth refill
Recommended Warmth: 100 / 1,000 / 40,000 / 2,500,000 / 80,000,000
Region Cold Multipliers: 1 / 5 / 125 / 6,250 / 150,000
Frost Sprite Warmth Damage: 10 / 100 / 4,000 / 250,000 / 8,000,000
Hearth training: 3 / 5 / 30 / 50 / 500 / 1,000 / 5,000 / 10,000 / 50,000 / 100,000 per second
Hearth costs: Start / 5K / 100K / 500K / 2M / 10M / 50M / 250M / 2B / 10B
Special Ice: 90% Rare / 10% Legendary in Ancient, Black, Meteor
Sell = cleanup + small consolation payout
Archive = X / 20
One shared server Ice field
Failure releases exact Ice for multiplayer rescue with no reroll
Survival Pressure promoted; no generic combat progression
Every creature mountable: Following <-> Riding
Riding applies copy FinalWalkSpeed; Following uses WalkSpeed 16
Mounted Strike = same universal survival attack values
Frosted creature presentation = floating Frosted Companion Orb until own-WarmZone/failure recovery
Grab Hold = 1.00 sec at 0.75x -> 2.00 sec at 5.00x, linear first pass, no reservation on hold start
Carrier Commitment = move / jump / Ride-Unride / DropIce / own-Pen deposit-placement only
DropIce = exact shared Ice release, no reroll, 0.75 sec original-dropper regrab lock, fresh full Grab Hold required
Wilderness contest = pre-Grab ragdoll/knockback; mounted non-carrier forced knock-off also deals 25% Max creature Vitality
Mounted carrier contest = rider stays protected; mount loses 25% Max Vitality per valid separated hit; Frosted at 0 forces Unride but Ice remains carried
Home Camp/Lobby = PvP safe + zero Warmth drain
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
