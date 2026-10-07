# THAW A CREATURE

## Bare-Minimum Prototype Technical Specification - v1.0 FINAL

**Purpose:** Validate the core game loop within 1 week before expanding into the 3-week launch build  
**Prototype Target:** End of Week 1  
**Server Size:** 1 player  
**Persistence:** None  
**Art Target:** Greybox + primitive creature blockouts  
**Architecture Goal:** Launch-compatible, ruthlessly reduced in scope  
**Design Source at close:** Concise GDD v0.6  
**Development Source at close:** Development Plan v1.0  
**Constants Source at close:** Implementation Constants v1.0  

### Revision notes

- Week-1 prototype validation is complete: **PASS**.
- D7-R13 progression validation is complete: **PASS**.
- Survival Pressure final decision: **PASS**.
- The full validated Survival Pressure package S01-S06 is promoted into launch design by GDD v0.6 / Launch Technical v0.6 / Constants v1.0 / Development Plan v1.0.
- This file is now a **historical validation artifact**. It records what Week 1 proved and may intentionally differ from newer production behavior.
- In particular, Week-1 single-player carrier failure originally removed the carried Ice; the promoted multiplayer launch rule now releases the exact Ice into the shared world for rescue instead.
- Week-1 did not validate multiplayer itself; Day 9 production work owns multiplayer implementation.

## 1. Prototype Objective

The Week-1 prototype existed to answer:

> Is the core experience compelling enough that the player voluntarily wants another expedition?

The tested experience was:

```text
See desirable Ice
-> risk Warmth
-> retrieve it
-> race it home
-> watch it thaw
-> smash it open
-> receive a creature
-> become stronger
-> want another Ice
```

It also tested whether a narrowly scoped Survival Pressure layer made retrieval more tense and memorable without turning enemy combat into the primary goal.

**Final result: PASS.**

Week 1 produced credible evidence for the retrieval USP, progression aspiration, and the Survival Pressure package. Production may continue under the newer launch-canonical documents.

## 2. Prototype Scope Philosophy

This is not a throwaway prototype.
It is:

the smallest functional slice of the launch architecture.
Systems built during Week 1 should be reusable or extendable during launch development.
However:

Launch requirements must not be implemented early merely because they
will eventually be needed.
The prototype is divided into three production priorities.
P0 - Prototype Critical
Must exist for Week 1 to successfully validate the game.
P1 - Validation Support
Should be added once the full P0 loop is working reliably.
P2 - Stretch
Only implement after P0 and P1 are stable.
EXP - Explicit Prototype Hypothesis
May temporarily test a user-approved mechanic that is not launch-canonical.
An EXP task exists to produce evidence and may be removed after testing without counting as prototype failure.
EXP behavior must not be inferred outside the exact experiment tasks.
If development falls behind:

Cut P2 first -> simplify P1 -> protect P0.
The survival EXP is not protected launch scope and must not displace the core P0 loop.

## 3. Prototype Core Loop

```text
               1 SPAWN AT HEARTH
               2         v
```


```text
            3   TRAIN WARMTH
            4           v
            5   SEE MYSTERIOUS ICE
            6           v
            7   ENTER WILDERNESS
            8           v
            9   WARMTH DRAINS
           10           v
           11   CHOOSE + GRAB ONE ICE
           12           v
           13   CARRYING INCREASES WARMTH DRAIN
           14           v
           15   RACE HOME
           16           v
           17   DEPOSIT ICE IN PEN
           18           v
           19   ICE THAWS OVER TIME
           20           v
           21   EXPLORE AGAIN / TRAIN WARMTH
           22           v
           23   GREAT FROST
           24           v
           25   WILDERNESS REROLLS + 10x THAW BOOST
           26           v
           27   ICE BECOMES READY
           28           v
           29   CRACK -> CRACK -> SMASH
           30           v
           31   RANDOM CREATURE REVEAL
           32           v
           33   EQUIP CREATURE
           34           v
           35   MOVE NOTICEABLY FASTER
           36           v
           37   ATTEMPT FARTHER ICE
```


P1 then completes the recursive progression with:

Pen -> Cash -> Hearth upgrade -> faster Warmth training -> farther
expeditions.

## 4. Prototype Success Philosophy

The prototype is not successful merely because all systems function.
It succeeds if players demonstrate behaviors such as:

"I want another Ice."

"I think I can reach that farther one now."

"I almost made it-I'm trying again."

"This creature made me way faster."

"That Ice is almost ready."

"I'll stay for one more Great Frost."
The strongest desired player story is:

"I saw this Ice really far away, barely managed to get it home, and then it
turned into a Mammoth."
A weak result is:

"You hatch pets."

## 5. P0 - Greybox World

The prototype contains one extremely simple continuous world:

Hearth -> Regular Area -> Thick Area
No portals.
No separate maps.
No production Terrain.
Use:
large Parts for ground;
simple slopes;
a few blocking rocks/walls;
minimal elevation;
one obvious forward direction.
The world should primarily test:
distance;
visibility;
Warmth pressure;
retry pacing;

whether farther opportunities create desire.


## 6. P0 - Route Structure

The prototype is not an open-world test.
Use:

1 primary route
with at most:

1-2 small alternative routes/shortcuts
where helpful.
Navigation should be obvious enough that getting lost does not interfere with evaluation of the
expedition loop.


## 7. P0 - Hearth / Warm Zone

The player spawns at a simple Hearth/base.
The Hearth area must clearly communicate:

safe zone
While inside it:
Current Warmth rapidly refills;
Max Warmth automatically trains upward.
The final Norse-inspired Hearth art is not required.
A clearly readable greybox fire/heater area is sufficient.


## 8. P0 - Warmth Model

Prototype Warmth consists of two values:
CurrentWarmth
Temporary expedition resource.
MaxWarmth

Permanent progression for the current play session.
State rule:
```text
              1 0 <= CurrentWarmth <= MaxWarmth
```


Outside the Hearth:
```text
              1 CurrentWarmth -= NormalDrainRate * dt
```


While carrying Ice:
```text
              1 CurrentWarmth -= NormalDrainRate
              2                  * CarryDrainMultiplier
              3                  * dt
```


All exact values belong in the Constants document.


## 9. P0 - Unlimited Warmth Training

While inside the player's Hearth area:

MaxWarmth continuously increases.
There is:
no Warmth Level;
no Warmth XP;
no secondary training currency;
no maximum;
no diminishing-return formula;
no player input required.
Conceptually:
```text
              1   72
              2   73
              3   74
              4   75
              5   ...
```


The prototype must test whether:

watching permanent Warmth progress while at home feels productive.

## 10. P0 - Current Warmth Refill

While inside the Hearth:

```text
            1 CurrentWarmth += RefillRate * dt
```


up to:
```text
            1 CurrentWarmth = MaxWarmth
```


Warmth refill and MaxWarmth training can happen simultaneously.


## 11. P0 - Freeze / Failure

When:
```text
            1 CurrentWarmth <= 0
```


the player enters:

**FROZEN**
The server must:
1. mark player Frozen;
2. remove/release carried Ice;
3. clear carry state;
4. return player to Hearth;
5. set CurrentWarmth = MaxWarmth;
6. allow another attempt.
The player does not lose:
MaxWarmth;
Cash;
creatures;
Pen contents;
completed reveals.
Prototype failure should cost:

time + the current Ice
not permanent progression.


## 12. P0 - Retry Philosophy

Failure should create:

"I almost made it."
rather than:

"Now I need to repeat several minutes of boring gameplay."
One reason Equipped creature Speed exists is to reduce reattempt friction as the player
progresses.
Retry pacing must be explicitly evaluated during Week 1.


## 13. P0 - Ice Spawn Architecture

Use handcrafted invisible spawn Parts.
```text
                1 Workspace
                2 +-- IceSpawnPoints
                3     +-- Regular
                4     |   +-- Spawn01
                5     |   +-- Spawn02
                6     |   +-- Spawn03
                7     |   +-- Spawn04
                8     |
                9     +-- Thick
               10         +-- Spawn01
               11         +-- Spawn02
```


Initial active targets:

Regular: 4
Thick: 2
Do not use random coordinate generation or volume-based spawning.
The level designer decides where Ice is allowed to appear.
The game decides which valid positions are currently populated.


## 14. P0 - Why Handcrafted Spawn Points

Spawn points give deliberate control over:
distance;
line of sight;
silhouettes;
route choice;

Warmth balance;
aspiration framing.
The prototype should be able to intentionally place:

an attractive Ice slightly beyond the player's comfortable range.

## 15. P0 - Ice Types

The original prototype began with Regular and Thick.
After the Day-5 core loop passed, Days 6-7 may bring forward additional functional progression Ice:

```text
Regular
Thick
Ancient
Black
Meteor (if stable/time permits)
```

Each type has its own base/reference visual size and progression region.
Every individual spawned Ice also receives a separate server-authoritative size/weight roll.

A visually enormous Ice is not a new Ice Type. It is a jackpot-sized instance of its existing type.

## 16. P0 - Server-Side Ice Result

Each wilderness Ice receives all authoritative outcome data when spawned.
Pipeline:

```text
Ice Type
  v
WeightMultiplier / Size Roll
  v
Scale = cbrt(WeightMultiplier)
  v
Rarity Roll
  v
Eligible Creature Pool
  v
Creature Roll
  v
Store Hidden Reward + Visible Size Lineage
```

Size is independent of hidden rarity/species by default.
The client may see the resulting visual Scale because it is physically visible, but may not choose or receive the hidden reward identity before reveal.

The same WeightMultiplier must survive:

```text
wilderness -> carry -> deposit -> thaw -> ready -> reveal -> creature copy
```

## 17. P0 - Randomness Rule

Creature acquisition must be genuinely random from the first reveal.
Do not script:

Penguin first
Wolf second
Mammoth third
or any equivalent tutorial reward sequence.
Design principle:

Script the learning opportunity. Never script the excitement.
Week-1 prototype does not require bad-luck protection.


## 18. P0 - Silhouette Rule

The Ice must hint at what is inside without always perfectly identifying it.
The prototype should test:

Does the silhouette itself make the player want to retrieve the Ice?
Desired information progression:

distant vague shape
-> closer visual hints
-> clearer during thaw
-> final identity at Smash
Silhouettes may be crude in Week 1.
They do not require sophisticated shaders.
But they must preserve:

mystery + desirability.

Use the canonical reusable SilhouetteProfile IDs from Implementation Constants where practical. Week-1 geometry may be crude; shared profiles are more important than exact species silhouettes.

## 19. P0 - Ice Runtime State

Each active Ice should conceptually contain:
```text
            1   IceInstanceID
            2   IceType
            3   SpawnPointID
            4
            5   CreatureID
            6   Rarity
            7   SilhouetteProfile
            8
            9   State
           10   OwnerUserID
```


Prototype states:
```text
           1    Available
           2    Carried
           3    Deposited
           4    Resolved
```


CreatureID and Rarity remain server-authoritative.


## 20. P0 - Grabbing Ice

Interaction may use a ProximityPrompt.
Client requests:
```text
           1 GrabIce(IceInstanceID)
```


Server validates:
Ice exists;
state is Available ;
player is alive;
player is not Frozen;
player carries no other Ice;
proximity is valid;
Ice remains unclaimed.
Then:
```text
           1 State = Carried
           2 OwnerUserID = Player.UserId
```


## 21. P0 - One-Ice Carry Limit

Player may carry:

0 or 1 Ice.
Never more.
Do not create:
raw Ice Inventory storage;
backpack Ice;
multiple-Ice carrying.
The only successful destination for raw Ice is:

the Pen.

## 22. P0 - Carry Behavior

While carrying Ice:
Warmth drains faster;
Movement Speed remains unchanged;
carried Ice remains visually obvious.
Do not add carry slowdown.
The tension comes from:

the Warmth countdown.

There is no intentional DropIce action in Week 1. A carried Ice leaves the carry state only through Pen deposit or failure/reset/death rules.

## 23. P0 - Death / Reset While Carrying

**Historical Week-1 behavior:** death/reset while carrying was treated as a failed expedition and the prototype cleared the carried Ice.

This behavior successfully tested whether failure itself felt retryable in a one-player prototype.

**Production supersession:** Launch Technical v0.6 replaces this with the shared multiplayer failure contract: the exact Ice is dropped at the last valid carrier position, ownership clears, and any player may rescue it without a reroll.

Do not use this historical Week-1 section to override the newer production rule.

## 24. P0 - Pen Deposit


There is no Thaw Machine.
The player carries Ice directly home and deposits it in the Pen.
Client requests:
```text
           1 DepositCarriedIce()
```


Server validates:
player owns currently carried Ice;
player is at own Pen;
Ice state is Carried .
Then:

wilderness Ice becomes a logical ThawItem .
The player becomes free to retrieve another Ice immediately.


## 25. P0 - Unlimited Simultaneous Thawing

The player may have:

multiple Ice blocks thawing simultaneously.
There is no gameplay thaw limit.
Do not implement:
Thaw Slots;
incubator capacity;
thaw slot purchases;
storage expansion.


## 26. P0 - Visual Thaw Placement Is NOT Gameplay Capacity

For Week 1, thawing Ice may be arranged using:
predefined display markers;
rows;
columns;
simple index-based positioning.
These positions exist only for presentation.

For example:
```text
           1    ThawDisplayPoint01
           2    ThawDisplayPoint02
           3    ThawDisplayPoint03
           4    ...
```


must not mean:

only three Ice blocks can thaw.
If more Ice exists than presentation markers, the display system may be simplified.
The logical thaw count remains unlimited.


## 27. P0 - Launch-Compatible Thaw Record

Although persistence is disabled, prototype thawing should use a launch-compatible data
model.
Recommended runtime record:
```text
           1    ThawID
           2    IceType
           3
           4    CreatureID
           5    Rarity
           6
           7    DepositedAtTime
           8    BaseDurationSeconds
           9    BonusProgressSeconds
```


The prototype may use server runtime time.
Launch will later replace/extend this with persistent Unix timestamps.
Do not build an unrelated throwaway countdown architecture.


## 28. P0 - Thaw Progress

Conceptually:
```text
           1 Elapsed =
           2     CurrentTime
           3     - DepositedAtTime
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


Ready:
```text
            1 Progress >= 1
```


Avoid creating one constantly saving timer object per Ice.


## 29. P0 - Prototype Thaw Timing

Week-1 timers should be intentionally short.
They are not launch retention timings.
Goal:

one tester should experience several complete retrieve -> thaw -> reveal
cycles during a short session.
The prototype is testing:

anticipation while other gameplay remains available.

## 30. P0 - Visual Thaw States

Minimum presentation:
Stage 0
Frozen / opaque.
Stage 1
Partially thawed.
Stage 2
Silhouette clearer / nearly ready.
Stage 3
READY TO CRACK.
Use cheap methods:
transparency;
material;
decal;
model state swap;

cracks.
No procedural fracture simulation.


## 31. P0 - Passive Thawing

The player does not manually speed up thawing through clicking.
There is no:
spam tap;
timing minigame;
active thaw meter.
The timer exists to create:

anticipation + overlapping gameplay.

## 32. P0 - Begin Reveal

When an Ice becomes ready:

**READY TO CRACK**
The player interacts with it.
Client requests:
```text
            1 BeginReveal(ThawID)
```


Server validates:
ThawID exists;
player owns it;
progress is complete;
player is near Pen;
no conflicting reveal is already active.


## 33. P0 - Reveal Session

Runtime representation:
```text
            1 SessionID
            2 PlayerUserID
            3 ThawID
```


```text
            4
            5 CurrentHit = 0
            6 RequiredHits = 3
            7 LastHitTime
```


Player may have:

0 or 1 active RevealSession.

## 34. P0 - CRACK -> CRACK -> SMASH

Client requests:
```text
            1 Crack(SessionID)
```


Server validates:
session;
ownership;
correct state;
request order;
reasonable rate limit.
Then:
```text
            1 CurrentHit += 1
```


Sequence:

Hit 1 = CRACK
Hit 2 = CRACK
Hit 3 = SMASH
No:
skill grade;
combo;
accuracy;
failure;
durability;
coordinate targeting.


## 35. P0 - Reveal Presentation


Minimum prototype experience:
Hit 1
Visible crack.
Hit 2
Creature/silhouette becomes clearer.
Hit 3
Ice breaks/disappears and creature appears.
Rare should receive visibly stronger presentation than Common.
Production-level VFX are not required.
But the prototype must be able to answer:

"Does the payoff justify retrieving and waiting?"

## 36. P0 - Reveal Transaction Safety

On final Smash, server must:
1. lock ThawItem as resolving;
2. retrieve stored creature result;
3. add exactly one owned creature;
4. remove/resolve ThawItem;
5. clear reveal session;
6. send reveal event.
Repeated requests must never grant duplicates.
The grant operation must behave as if it were idempotent.


## 37. P0 - Prototype Rarities

Current obtainable prototype content may still use the rarities actually configured in its pools.
The economy configuration supports five tier labels:

```text
Common
Uncommon
Rare
Epic
Legendary
```

Do not infer new creatures or pool weights from the existence of an economy tier.
The Day-6 repository audit determines which of the 11 already-authored creature meshes are currently available and how they map into prototype pools.

Rarity remains important for content probability/presentation, but fixed rarity-only Speed and Income are superseded by species base stats + copy Scale.

## 38. P0 - Equipped Creature

Player may Equip one specific CreatureGUID copy.
The server determines actual Movement Speed from:

```text
Creature species BaseWalkSpeed
x
Size-derived SpeedMultiplier
```

The copy's inherited Scale is preserved visually in the follower.

The critical test is now:
- does species identity matter?
- does an unusually large copy feel like a real traversal jackpot?
- does Speed improve noticeably without making Warmth irrelevant?

## 39. P0 - Creature Speed Philosophy

Desired feeling:

```text
baseline species identity
+
visible size jackpot
=
copy-specific traversal value
```

Scale influences Speed more gently than Income.
At the extreme `5x` visual Scale, the configured first-pass Speed multiplier is approximately `1.60x` the species BaseWalkSpeed, not `5x` WalkSpeed.

The player should be able to compare exact Speed in minimal creature presentation, but the difference must also be felt immediately in movement.

## 40. P0 - No Creature Warmth Bonus


Prototype creatures do not increase Warmth.
Responsibilities remain intentionally separate:

Warmth = endurance

Creature = traversal Speed

The Day-5 survival experiment may temporarily add session-only `CreatureVitality` to the currently Equipped creature.
That value is not a permanent creature stat, does not increase Warmth, does not create Damage/Defense/levels, and must never delete ownership.
Outside the exact `EXP-D5` tasks, creature identity remains Speed-only for prototype gameplay.

## 41. P0 - Great Frost

The Great Frost / Night cycle is mandatory.
It is one of the primary Week-1 validation systems.
The prototype Great Frost does not need final spectacle.
Minimum requirements:
countdown;
obvious lighting/sky change;
recognizable audio cue;
world Ice refresh;
thaw acceleration.
The player must clearly understand:

"The wilderness changed."

## 42. P0 - Great Frost Gameplay Behavior

When Great Frost occurs:
1. available/unclaimed wilderness Ice is removed;
2. a new Regular/Thick field is generated;
3. carried Ice remains safe;
4. Pen Ice remains safe;
5. unfinished Pen Ice thaws at `10x` while Great Frost remains active, including Ice deposited during Great Frost.
6. new GrabIce confirmations are disabled during the 15-second Great Frost transition and resume when normal Day returns.

The Night does not:
automatically freeze player;
teleport player;

force return to base.
It creates opportunity, not punishment.


## 43. P0 - Great Frost While Carrying

If the player is carrying Ice when the reset begins:

the carried Ice survives.
Only:

available/unclaimed wilderness Ice
is refreshed.


## 44. P0 - Great Frost Thaw Boost

The Week-1 prototype uses an **active thaw-speed multiplier**, not a one-time fixed progress grant.

Normal Day:
```text
               1 ThawMultiplier = 1x
```

Great Frost:
```text
               1 ThawMultiplier = 10x
```

The multiplier exists only while:
```text
               1 CurrentPhase == GreatFrost
```

Every unfinished `ThawItem` receives accelerated progress only for the real-time overlap between that item's thaw lifetime and the active Great Frost interval. This includes Ice deposited **during** Great Frost: it begins at `10x` immediately from its deposit time until the Frost ends.

Conceptually, while Great Frost is active:
```text
               1 NormalElapsed = CurrentTime - DepositedAtTime
               2 OverlapStart = max(
               3     DepositedAtTime,
               4     GreatFrostStartedAtTime
               5 )
               6 FrostSeconds = max(0, CurrentTime - OverlapStart)
               7 FrostExtra = FrostSeconds * (FrostMultiplier - 1)
               8 EffectiveElapsed =
               9     NormalElapsed
              10     + BonusProgressSeconds
              11     + FrostExtra
```

The `- 1` prevents double-counting because normal elapsed time already contributes `1x`. At `10x`, each real Frost second contributes nine additional effective thaw seconds.

When Great Frost ends, the multiplier immediately returns to `1x`. Progress earned during the Frost must not rewind; the completed Frost overlap is folded into `BonusProgressSeconds` (or an equivalent authoritative accumulated-bonus field) before live Frost contribution returns to zero.

Ready condition remains:
```text
               1 Progress >= 1
```

Already-Ready Ice remains Ready. Becoming Ready during Great Frost never auto-grants the creature; the player still performs `CRACK -> CRACK -> SMASH`.

Desired thoughts:

"I should get this Ice into the Pen before the Frost ends."

"One more Frost and this might be ready."

Exact multiplier value belongs in Constants.


## 45. P0 - World Refresh

Great Frost is the prototype's primary Ice refresh system.
Do not build complex independent respawn timers unless temporarily necessary for debugging.
After reset:

active spawn points are rerolled and repopulated.
This tests whether synchronized world refresh feels more meaningful than independent Ice
popping into existence.

## 45A. VALIDATED - Survival Pressure Boundary

The Day-5 Survival Pressure experiment passed its first gate and its End-of-Week-1 promotion decision.

Validated/promoted elements:
- one universal swing tool;
- one stationary Frost Sprite threat model;
- Guarded Ice encounters;
- player enemy hits reduce `CurrentWarmth`;
- session-only Vitality for the currently Equipped creature;
- non-permanent Frosted/Downed state;
- minimal survival feedback;
- breakable environmental route obstacles.

Final conclusion:

> Survival Pressure strengthened the Ice-retrieval story enough to justify productionization.

This still does not approve Player HP, permanent creature death, weapon progression, enemy drops, combat XP, crafting/material currencies, roaming/pathfinding enemies, bosses, or pet combat AI.

## 45B. VALIDATED - Universal Survival Tool

The experiment uses one tool and one simple verb:

```text
input -> swing -> server validates -> approved target receives effect
```

Server validates:
- request rate;
- range;
- current target state;
- whether the target belongs to the active experiment.

Do not build a generic combat/item/ability framework.
Do not add combos, blocking, heavy attacks, stamina, rarity, durability, upgrades, inventory, or multiple weapon classes.
The existing CRACK -> CRACK -> SMASH reveal interaction remains unchanged unless a later approved task explicitly changes it.

## 45C. VALIDATED - Stationary Frost Sprite

One minimal hostile threat is allowed.

State flow:

```text
Dormant -> Acquire -> Telegraph -> Attack -> Cooldown -> Acquire
```

Rules:
- stationary;
- no roaming/pathfinding;
- no chase behavior;
- no enemy drops/currency/XP/levels;
- attack uses a readable telegraph and projectile/attack;
- may target the player or the currently Equipped creature according to the configured prototype targeting rule;
- universal survival tool defeats it through configured hit count/health.

Player hit:

```text
CurrentWarmth -= configured Warmth damage
```

There is no Player HP.

Creature hit:

```text
Experimental CreatureVitality -= configured creature damage
```

## 45D. VALIDATED - Guarded Ice

Frost Sprites exist around selected authored Ice opportunities, not as generic wilderness population.
Some Ice must remain unguarded.
The Ice remains the visual and motivational objective.

A player may:
- fight;
- rush the Ice;
- retreat out of the threat area.

Guardians are cleared/rebuilt with the Great Frost field reset so stale threats do not survive an Ice opportunity reset.
Do not add independent long-lived enemy respawn timers.
Great Frost itself remains an opportunity/world-change event, not an enemy punishment phase.

## 45E. VALIDATED - Equipped Creature Vitality / Frosted State

Only the currently Equipped creature requires temporary experiment Vitality.
Pen creatures are excluded.
Creatures do not attack.

At zero Vitality:

```text
Equipped creature -> Frosted / Downed
```

Then:
- ownership is preserved;
- the creature remains logically Equipped;
- follower presentation becomes Frosted/removed;
- Equipped Speed bonus is suppressed;
- the player may continue the expedition;
- entering the Hearth/WarmZone restores the creature to full experimental Vitality, clears Frosted, and restores its Equipped Speed;
- Freeze/death/reset recovery must never create permanent creature loss.

Desired pressure:

```text
My companion went down; can I still get this Ice home?
```

not:

```text
I permanently lost the creature I collected.
```

## 45F. VALIDATED - Survival Validation Gate

The Survival Pressure validation result is **PASS**.

Observed evidence included a guarded Thick-Ice retrieval where the player returned with only 3 Warmth remaining after multiple Sprite hits. The player made meaningful fight/flight decisions because they wanted the Ice and reported caring more about the carried Ice + Warmth than about enemy farming.

The End-of-Week-1 decision promotes S01-S06 into launch scope under the newer production documents.

The production question remains:

> Does survival pressure make the retrieval story stronger?

not:

> Is combat a separate progression game?

## 45G. VALIDATED - Breakable Route Obstacles

The approved S06 direction is promoted as a narrow route-pressure mechanic using the same universal swing verb.

Purpose:
- safe longer route;
- shorter route requiring several hits;
- guarded shortcut.

Breakables grant no Wood, Stone, currency, XP, enemy drops, or crafting materials.
They are not resource nodes.

## 46. P1 - Hearth Upgrade

The initial Day-5 Hearth upgrade path proved the loop.
Days 6-7 now expand it into big-number progression.

Hearth remains functionally simple:
- Cash buys Hearth levels;
- Hearth level changes automatic `MaxWarmth` training rate;
- no Warmth cap;
- no direct fixed MaxWarmth award;
- no region hard unlock.

Presentation must make the Hearth feel important:
- large fire/heat landmark;
- visible WarmZone;
- `HEARTH LV. X`;
- `+Warmth/sec`;
- upgrade cost / MAX.

Exact revised rates/costs belong in Constants v0.9.

## 47. P1 - Cash

One currency:

**Cash**
Prototype sources:
Pen income;
selling creatures.
Primary sink:

Hearth upgrade.
Do not add another currency.


## 48. P1 - Pen Creature Positions

Pen supports:

4 active income creature positions.
These are separate from thawing Ice.
After a reveal:
Pen has space
Assign creature to first available Pen position.
Pen full
Creature remains inactive in Inventory.
No modal choice is required.


## 49. P1 - Pen Income

Use one server-side aggregate income tick every **1 second**.

For each occupied Pen slot:

```text
CreatureGUID
-> species BaseIncomePerSecond
-> copy Scale
-> FinalIncome = round(BaseIncomePerSecond * Scale^2)
```

Then grant one aggregate Cash payment.

No independent timer per creature.
No offline Pen income.
Equipped and Inventory copies earn zero.

## 50. P1 - Creature Ownership Model

The species-count model is superseded.
Prototype ownership now uses individual copies:

```text
CreatureCopies = {
    [CreatureGUID] = {
        CreatureID,
        WeightMultiplier,
    }
}
```

Derived per-copy data:

```text
Scale = cbrt(WeightMultiplier)
FinalIncome
FinalSpeed
```

The only randomized copy stat source is the inherited Ice size/weight roll.
Do not add unrelated randomized combat stats.

## 51. P1 - Inventory Definition

Inventory is not a second ownership database.
It is the set of owned CreatureGUIDs not currently assigned to Pen or Equipped:

```text
InventoryGUIDs =
all CreatureCopies keys
- PenSlots GUIDs
- EquippedCreatureGUID
```

Copies of the same species remain individually distinguishable through Scale, Speed, and Pen Income.

## 52. P1 - Minimal Inventory UI

Prototype Inventory must show enough information to compare individual copies:
- species/name;
- visual Scale or size indicator;
- Speed;
- Pen Income / sec;
- Equip;
- place/remove Pen;
- Sell.

No production polish required.
The player must not accidentally treat two different rolls of the same species as interchangeable.

## 53. P1 - Equip State Rules

Equip from Inventory:

```text
CreatureGUID -> EquippedCreatureGUID
```

Equip from Pen:

```text
clear Pen slot -> CreatureGUID becomes Equipped
```

Replace Equipped:

```text
old Equipped GUID -> Inventory
new GUID -> Equipped
```

Unequip:

```text
Equipped GUID -> Inventory
```

No automatic Pen refill.
All operations must preserve the exact individual copy and its inherited size roll.

## 54. P1 - Minimal Equipped Follower

The Equipped creature should be visibly represented at its exact copy Scale.
Minimum follower remains cosmetic:

```text
target position behind player
+ smooth interpolation
+ snap correction
```

Extreme `3.5x-5x` creatures are allowed to dominate the screen and become social trophies.
Do not convert them into physics-heavy blockers.

Show minimal world-space copy stats where readable:

```text
SPEED <value>
PEN $<value>/s
```

## 55. P2 - Follower Polish

Only after core stability:
better spacing;
smoother turning;
snap correction;
rarity effects;
animation polish.
Do not allow follower polish to consume core production time.


## 56. P1 - Sell

Minimum Week-1 selling requirement:

Sell from Inventory.
Server:
```text
              1 OwnedCount -= 1
              2 Cash += SellValue
```


If time allows:

Sell from Pen;
Sell Equipped.
Those are secondary prototype edge cases.


## 57. P1 - Prototype Creature Roster

The old eight-blockout production target is obsolete because **11 creature meshes are already complete**.

Day 6 begins with a repository audit of the actual 11 available creature models.
Then all 11 should be configured and put to use.

Do not guess the 11 model IDs from old planning documents.
The repository contents are authoritative for which meshes currently exist.

Each configured species must receive explicit:
- rarity/content assignment;
- `ReferenceWeight`;
- `BaseVisualScale`;
- `BaseIncomePerSecond`;
- `BaseWalkSpeed`;
- pool eligibility.

Those species-specific values require explicit design approval after the audit; an AI assistant must not fabricate them silently.

## 58. P1 - Creature Asset Contract

Each creature Model:

```text
CreatureModel
+-- Root
    +-- Visual Parts
```

Requirements:
- `PrimaryPart = Root`;
- standardized facing direction;
- scale-safe hierarchy;
- no gameplay scripts inside models;
- authored model represents species `1.0x` base size.

Runtime copy Scale may range from approximately `0.75x` to `5.0x`.
All existing 11 meshes must pass scaling without broken offsets, attachments, or follower placement.

## 59. P1 - Creature Visual Standard

Creatures must be silhouette-distinct and remain readable at their base size.
The size jackpot then amplifies the difference dramatically.

An absurdly large creature may visually overlap Pen anchors or dominate the camera. That is intentional social presentation.

Gameplay logic must remain independent of visual overlap.

## 60. P1 - Prototype Ice Pools

Regular and Thick remain foundational pools.
Days 6-7 now bring forward additional functional Ice types as progression content instead of using only a fake future placeholder.

Target order:

```text
Regular
Thick
Ancient
Black
Meteor if stable/time permits
```

The repository-audited 11 creature meshes should be distributed across these pools only after their exact species IDs and design assignments are approved.

Every Ice pool uses the same independent size-roll system.
Size does not change rarity odds in this revision.

## 61. P1 - Low-Warmth Feedback

Prototype needs enough feedback to create the:

Barely-Made-It-Home
moment.
Minimum states:
Safe
Normal presentation.
Low
Clear warning.
Critical
Strong visual/audio warning.

Cheap possible implementation:
Warmth UI pulse;
screen frost;
wind volume;
warning sound.
The server alone determines when freezing occurs.


## 62. P1 - Aspirational Future Target

Aspirational targets should now be functional whenever practical.
The world should naturally create `I WANT THAT` moments from:
- farther Ice types;
- visibly harsher regions;
- unusually large random Ice rolls;
- rare `3.5x-5x` jackpot Ice.

A non-interactive placeholder is no longer the preferred solution when the progression Ice can be implemented during Days 6-7.

## 63. P1 - Recommended Warmth

Every progression region should visibly communicate a Recommended Warmth target.
The numbers intentionally make large jumps and may reach thousands, hundreds of thousands, or millions as progression deepens.

Recommended Warmth is informational only.
It must never block movement or interaction.

Region signs should communicate approximately:

```text
<REGION NAME>
RECOMMENDED WARMTH
<big number>
```

Exact first-pass values and cold multipliers belong in Constants v0.9.

## 64. P2 - Frozen Archive

Optional only.
Minimal prototype version:

X / 8

Undiscovered:

???
Discovered:

name / simple icon.
Archive polish is not part of Week-1 core validation.


## 65. P2 - Pen Creature Roaming

Optional.
If P0/P1 are stable, Pen creatures may:

select nearby visual point -> move -> pause -> repeat.
Do not use gameplay AI.
Fixed creature placement is acceptable for prototype.


## 66. P2 - Special Ice

Special Ice is a launch design requirement but not required to validate Week 1.
If development is ahead:

create one simple visually special Ice with elevated rarity.
Do not build:
full cadence;
complete server announcement system;
final Special Ice VFX.
The Great Frost itself must work first.


## 67. P2 - Improved Great Frost Presentation

Optional additions:
aurora;
frost wave;

stronger wind;
environment particles;
runic effects.
P0 only needs:

clearly recognizable transformation.

## 68. P2 - Reveal Polish

Optional improvements:
camera impact;
larger particles;
rarity sting;
stronger sound;
creature pose.
Do not polish reveal before the underlying three-hit interaction is proven satisfying.


## 69. Prototype Architecture

Use launch-compatible structure.
```text
             1   ReplicatedStorage
             2   +-- Shared
             3   |   +-- GameConfig
             4   |   +-- CreatureConfig
             5   |   +-- IceConfig
             6   |   +-- RarityConfig
             7   |   +-- WarmthConfig
             8   |   +-- HearthConfig
             9   |   +-- RegionConfig
            10   |   +-- WorldCycleConfig
            10   |
            11   +-- Remotes
            12       +-- GameplayRequest
            13       +-- GameplayEvent
```


```text
             1   ServerScriptService
             2   +-- ServerBootstrap
             3   |
             4   +-- Services
             5       +-- PlayerStateService
             6       +-- WarmthService
             7       +-- IceService
             8       +-- ThawService
             9       +-- CreatureService
            10       +-- WorldCycleService
```


```text
             1 StarterPlayer
             2 +-- StarterPlayerScripts
```


```text
            3         +-- ClientBootstrap
            4         |
            5         +-- Controllers
            6             +-- InteractionController
            7             +-- WarmthController
            8             +-- ThawController
            9             +-- CreatureVisualController
           10             +-- WorldCycleController
           11             +-- EffectsController
           12             +-- UIController
```


Do not implement DataService in Week 1.


## 70. Server Authority

Server owns gameplay truth for:
Cash;
CurrentWarmth;
MaxWarmth;
HearthLevel;
Warmth training;
Ice state;
Ice ownership;
Ice reward result;
thaw progress;
Great Frost gameplay;
OwnedCreatures;
Pen slots;
EquippedCreature;
Movement Speed;
reveal grant.
Client handles:
input;
UI;
audio;
camera;
particles;
follower visuals;
Pen roaming;

presentation.


## 71. Prototype Remote Requests

Use one shared gameplay request channel with actions such as:
```text
            1   ClientReady
            2
            3   GrabIce
            4   DepositCarriedIce
            5
            6   BeginReveal
            7   Crack
            8
            9   PlaceInPen
           10   RemoveFromPen
           11
           12   EquipCreature
           13   UnequipCreature
           14
           15   SellCreature
           16   UpgradeHearth
```


Do not create one RemoteEvent per button.


## 72. Prototype Server Events

Server-to-client gameplay events may include:
```text
            1   StateSnapshot
            2   StateUpdated
            3
            4   WarmthUpdated
            5   Frozen
            6
            7   CarryStateUpdated
            8
            9   IceDeposited
           10   ThawUpdated
           11   ThawReady
           12
           13   GreatFrostStarted
           14   IceFieldReset
           15
           16   RevealStarted
           17   CrackConfirmed
           18   RevealCreature
           19
           20   PenUpdated
           21   EquippedUpdated
           22   HearthUpdated
           23   CashUpdated
           24
           25   ShowMessage
```


## 73. Remote Validation


Even with MaxPlayers = 1 , basic launch-compatible validation is required.
Every relevant request validates:
argument type;
player state;
ownership;
target existence;
proximity;
action order;
rate limits;
legal gameplay state.
Never trust client-provided:
Cash;
Warmth;
rarity;
creature result;
Movement Speed;
thaw completion;
Ice ownership.


## 74. Prototype Runtime State

Relevant PlayerState now includes:

```text
CurrentWarmth
MaxWarmth
Cash
HearthLevel
CurrentlyCarryingIceID
ActiveThawItems
ReadyThawItems
CreatureCopies
PenSlots[1..4] -> CreatureGUID or nil
EquippedCreatureGUID or nil
CreatureVitality / CreatureFrosted (experiment session state)
```

Wilderness/Thaw Ice records preserve `WeightMultiplier` until reveal.
CreatureCopies preserve `WeightMultiplier` after reveal.
Derived `Scale`, `FinalIncome`, and `FinalSpeed` need not be stored redundantly.

## 75. Critical State Invariants

The server must preserve:

```text
0 <= CurrentWarmth <= MaxWarmth
MaxWarmth >= starting value
0 or 1 carried Ice
0 or 1 owner per wilderness Ice
0 or 1 EquippedCreatureGUID
max 4 occupied PenSlots
all Pen/Equipped GUIDs exist in CreatureCopies
no CreatureGUID appears in more than one allocation state
```

There is no gameplay maximum for simultaneous thawing Ice.

Size lineage invariant:

```text
Ice.WeightMultiplier
== deposited ThawItem.WeightMultiplier
== revealed CreatureCopy.WeightMultiplier
```

No reveal may reroll size.
Only the server mutates ownership, Cash, Warmth progression, HearthLevel, Pen allocation, Equipped GUID, Ice reward data, or size lineage.

## 76. Prototype Edge-Case Rules

The following records Week-1 runtime behavior and is preserved for validation history.

Great Frost while carrying Ice  
Carried Ice survived.

Great Frost while Ice is thawing  
The Great Frost Thaw Boost applied at `10x` only while Great Frost remained active; Day remained `1x`.

Great Frost while Ice is Ready  
Ready Ice remained Ready.

Freeze / character reset while carrying Ice  
Week-1 prototype treated the retrieval as failed and cleared the carried Ice.

**Production supersession:** v0.6 launch behavior now releases the exact same Ice into the shared world on Freeze/death/reset/disconnect.

Pen full on reveal  
Creature remains in Inventory.

Equip from full Pen  
Selected slot empties; creature becomes Equipped.

Multiple Ready Ice  
Each remains independently available for reveal.

Repeated final Crack request  
Must never duplicate creature grant.

Intentional DropIce  
Not available.

Character reset without carried Ice  
Return to Hearth and set CurrentWarmth = MaxWarmth; no permanent progression loss.

## 77. Day 1 - Foundation + Warmth

Build:
folder structure;
configs;
remotes;
greybox;
Hearth;
Regular/Thick distance layout;
Warm Zone;
CurrentWarmth;
MaxWarmth;
drain;
refill;
training;
freeze/reset.
End-of-Day Test
Player can:

spawn -> leave Hearth -> drain -> freeze -> return -> train MaxWarmth.

## 78. Day 2 - Expedition


Build:
Ice spawn markers;
Regular Ice;
basic Thick Ice;
Ice runtime records;
server reward roll;
Grab validation;
one-Ice carry;
carry presentation;
carry drain;
failed retrieval;
Pen deposit.
End-of-Day Test
Player can:

see Ice -> choose it -> grab it -> race home -> succeed or freeze.
This is the first test of the USP.


## 79. Day 3 - Thaw + Reveal

Build:
ThawItem;
launch-compatible timing;
multiple simultaneous Ice;
simple thaw presentation;
Ready state;
RevealSession;
CRACK -> CRACK -> SMASH;
idempotent creature grant;
2-3 initial blockout creatures.
End-of-Day Test
Complete:

wilderness Ice -> retrieval -> Pen -> thaw -> reveal -> creature.

## 80. Day 4 - Creature Progression

Build P0:
ownership;
Equip;
rarity-based Speed.
Then add simplest necessary P1:
four Pen positions;
minimal Inventory;
minimal follower if time;
basic income/Sell only if time remains.
End-of-Day Test
Player can:

reveal -> Equip -> feel dramatically faster -> immediately attempt another
expedition.

## 81. STOP GATE #1 - End of Day 4

Before continuing, test:

Is choosing Ice interesting?

Is carrying it home tense?

Is failure retryable?

Does thawing create anticipation?

Does CRACK -> CRACK -> SMASH feel worthwhile?

Does a better creature make the player meaningfully faster?

If the answer to these is weak:

Do not continue adding systems.
Use Days 5-7 to improve P0.


## 82. Day 5 - Great Frost + Survival Pressure Experiment + Progression Loop

If Gate #1 passes, preserve this order.

First complete the core Great Frost P0 loop:
- WorldCycleService;
- Great Frost countdown;
- simple transformation presentation;
- world Ice reset;
- Great Frost Thaw Boost.

Then run the exact `EXP-D5` survival sequence from Development Plan v0.9:
- universal survival tool;
- stationary Frost Sprite;
- Guarded Ice encounters;
- Equipped-creature Vitality/Frosted state;
- minimal survival feedback;
- survival validation gate;
- breakable-environment test only after PASS/PARTIAL PASS and only if time remains.

After the experiment has a recorded PASS/PARTIAL PASS/FAIL outcome, continue the P1 economy:
- Cash;
- Pen income;
- Hearth upgrade;
- faster Warmth training.

End-of-Day Test
Canonical progression remains:

expedition -> Pen -> training -> Great Frost -> thaw acceleration -> refreshed
wilderness -> reveal -> better creature -> faster expedition.

The survival experiment must also have a recorded outcome and must not replace Ice retrieval as the objective.

## 83. Day 6 - Jackpot / Per-Copy Metagame Foundation

Day 6 is now an implementation day.
The old eight-blockout task is obsolete because 11 creature meshes already exist.

Build in this order:
1. audit the 11 existing creature models/config IDs;
2. migrate ownership from species counts to CreatureGUID copies;
3. add authoritative Ice WeightMultiplier + derived Scale;
4. scale wilderness/carry/thaw/reveal Ice consistently;
5. inherit exact size roll into revealed creature copy;
6. configure the audited species with explicit base size/weight/income/speed values after design approval;
7. derive size-based FinalIncome and FinalSpeed;
8. migrate Pen/Equip/Inventory to GUID allocation;
9. update 1-second Pen income to sum copy-specific FinalIncome;
10. show Speed + Pen Income on creature presentation;
11. run a focused jackpot test proving giant Ice -> giant creature -> exceptional stats.

Keep the Day-5 survival experiment enabled because its gate passed, but do not expand enemy/combat scope.

Continuous sanity testing remains required after each risky task; Day 6 does not wait for a separate QA day.

## 84. Day 7 - Big-Number Progression + World Expansion

Day 7 is also an implementation day.
Regression testing remains continuous inside each task rather than consuming the entire day.

Build in this order:
1. rebalance Warmth into big-number progression;
2. convert Hearth CurrentWarmth refill to scale with MaxWarmth;
3. expand Hearth levels/training rates and upgrade costs;
4. increase Hearth presentation/prominence without changing its role;
5. create/expand progression regions;
6. add Recommended Warmth signs;
7. add region cold multipliers so large Warmth values remain meaningful in a manageable map;
8. implement Ancient Ice;
9. implement Black Ice if stable;
10. implement Meteor Ice if time/stability permits;
11. distribute the 11 audited creatures across progression pools after design approval;
12. retain/finish Safe -> Low -> Critical Warmth feedback using percentage thresholds;
13. run a focused progression test: see impossible opportunity -> train/find better copy -> eventually reach it.

Do not eliminate sanity tests. Every risky change still follows implementation -> Studio verification -> diagnostic cleanup -> commit.

## 85. Prototype First Three Minutes

0:00-1:00
Player:
spawns beside Hearth;
sees nearby Ice;
enters snow;
notices Warmth draining;
grabs Ice;
sees drain increase;
races home;
deposits Ice.


1:00-2:00
Ice visibly thaws.
Player discovers:

MaxWarmth increases while at home.
They may:
stay briefly;
or immediately retrieve another Ice.


2:00-3:00
At least one onboarding-time Ice should become ready quickly enough to teach:

**CRACK -> CRACK -> SMASH**
Creature revealed.
Equipping it teaches:

creature = Speed.
Another attractive target should already be visible.

## 86. Hero Moment Coverage

The prototype tests the mechanical foundation of the five canonical Hero Moments.
1. First Great Frost
P0 required.
Presentation may be primitive.
2. Impossible-Looking Ice
P1 cheap aspiration test.
Use distant Thick/future placeholder.
3. Barely-Made-It-Home
P0 critical.
This is the most important USP test.
4. Legendary Smash
Prototype substitutes:

Rare reveal.
The interaction should still demonstrate payoff potential.
5. Becoming the Endgame Player
Prototype substitutes:

Rare creature Speed.
The upgrade must already feel dramatically powerful.


## 87. Explicitly Excluded From Week 1

Do not implement:
DataStore;
persistence;
offline thawing;
multiplayer;
multiple player bases;
full Special Ice system;

Ancient Ice;
Black Ice;
Meteor Ice;
Legendary creatures;
final environment art;
final Terrain;
production Norse architecture;
production aurora/Frost effects;
final creature models;
monetization;
trading;
prestige;
rebirth;
Daily systems;
pickaxes;
mining;
enemies or combat outside the exact approved `EXP-D5` Survival Pressure Experiment;
bosses;
creature-specific traversal;
separate Speed training;
treadmill;
Luck progression;
additional currencies;
randomized individual creature stats;
Thaw Slot upgrades;
offline Pen income;
complex follower AI;
complex Pen AI.


## 87A. Prototype Validation - Survival Pressure Experiment

This experiment is optional to the canonical prototype success but mandatory to conclude once started.

Ask:
- Did guarded Ice become more desirable or merely more annoying?
- Did the player fight because they wanted the Ice?
- Did Warmth damage remain readable as the single player survival resource?
- Did creature Frosting create a memorable return decision without discouraging use of valuable creatures?
- Did the tool create useful agency without becoming a new grind?
- Did the player talk about the Ice/return trip more than the enemies?

Strong evidence resembles:

```text
I wanted that Ice, the sprites got my creature, and I barely made it home.
```

Concerning evidence resembles:

```text
Killing monsters was the fun part. Where can I farm more?
```

The final Week-1 decision must be PASS, PARTIAL PASS, or FAIL.
Only the specific subset supported by evidence may be considered for later launch promotion.

## 88. Prototype Validation - Retrieval

Ask:

Does seeing an Ice create desire?

Does distance create a meaningful decision?

Does the return trip create tension?

Does the player monitor Warmth while carrying?

Does failing produce a reattempt instead of frustration?
Most importantly:

Is retrieving Ice more memorable than simply receiving the creature?

## 89. Prototype Validation - Thawing

Ask:

Does depositing Ice create anticipation?

Is seeing several Ice blocks thawing exciting?

Does the player naturally find another activity while waiting?

Is passive waiting acceptable because progression continues elsewhere?

## 90. Prototype Validation - Warmth Training

Ask:

Does MaxWarmth increasing at home feel productive?

Does the player understand that more Warmth means farther expeditions?

Does faster training create desire for a better Hearth?

## 91. Prototype Validation - Speed

Ask:

Is the Speed difference immediately obvious?

Does it feel powerful rather than merely numerical?

Does it make previous terrain faster to traverse?

Does it materially improve retry pacing?

## 92. Prototype Validation - Great Frost

Ask:

Does the countdown create anticipation?

Does the player look toward the wilderness when it happens?

Does a refreshed Ice field feel meaningful?

Does the Great Frost Thaw Boost create:

"I should get this Ice into the Pen before the Frost ends."

and/or:

"I'll stay for one more cycle."

## 93. Prototype Validation - Reveal

Ask:

Is CRACK -> CRACK -> SMASH satisfying?

Is it satisfying after repeated uses?

Does the creature feel worth the expedition and wait?

Does stronger rarity presentation increase excitement?

## 94. Prototype Validation - Aspiration

Ask:

Does the player notice something farther away that they want?

Can they identify what progression would help them reach it?
Desired reasoning:

More Warmth + faster creature = I can try that next.

## 95. Primary Behavioral Metric

Track:

Reveal -> Next Ice Pickup Time
After revealing a creature:

how quickly does the player voluntarily begin another retrieval?
Desired response:

Reveal -> "Again."
This is a directional prototype metric, not a final KPI.
It must be paired with observation.


## 96. Most Important Qualitative Test

After approximately ten minutes, ask:

"What was the coolest thing that happened?"
Desired answer resembles:

"I went really far for an Ice, almost froze bringing it back, then it became a
Mammoth."
Concerning answer:

"I opened some pets."
If players primarily perceive:

pet hatching
rather than:

dangerous retrieval + anticipation
the USP has not been validated.


## 97. Secondary Qualitative Test

Ask:

"What do you want to do next?"
Strong answers include:

"Reach that farther Ice."

"Get a Rare."

"Train more Warmth."

"Get a faster creature."

"Wait for the next Frost."
The player should leave the prototype with an unresolved goal already in mind.


## 98. End-of-Week Stop Gate - FINAL RESULT

**PASS.**

Credible Week-1 evidence supports:
- Ice itself is desirable;
- retrieval creates tension;
- near-failure encourages another attempt;
- thawing creates anticipation;
- players remain productive during waiting;
- Warmth training feels meaningful;
- Hearth upgrades create dramatic acceleration;
- better creature copies make traversal materially faster;
- Great Frost renews opportunity;
- reveal creates desire for another Ice;
- future progression is visible through deeper regions/large Ice;
- players can describe memorable retrieval stories rather than only "hatching pets".

D7-R13 Progression Validation Gate: **PASS**.
Survival Pressure final decision: **PASS**.

The prototype has completed its purpose. Further launch production must follow the newer production-canonical documents rather than treating this file as an open feature list.

## 99. P0 Definition of Done

The minimum acceptable Week-1 build allows one player to repeatedly:

spawn at Hearth
-> automatically train MaxWarmth
-> enter wilderness
-> grab one Ice
-> experience increased carry drain
-> freeze or successfully return
-> deposit Ice into Pen
-> have multiple Ice thaw simultaneously
-> experience Great Frost
-> see wilderness Ice reroll
-> experience the active Great Frost Thaw Boost
-> get an Ice to Ready
-> CRACK -> CRACK -> SMASH
-> receive exactly one random creature
-> Equip it
-> move substantially faster
-> attempt another expedition
If this works and is compelling:

the prototype succeeds even if some P1/P2 content is unfinished.

## 100. Full Week-1 Target

If production proceeds smoothly, the revised target includes:
- all 11 already-authored creature meshes integrated after repository audit;
- individual CreatureGUID ownership;
- inherited Ice -> creature size/weight lineage;
- up to 5x visual Scale jackpots;
- species base Income/Speed with size-derived copy stats;
- Regular + Thick plus Ancient/Black and Meteor if stable;
- 4 active Pen creatures with 1-second copy-specific income;
- Cash;
- expanded Hearth levels and big-number Warmth training;
- minimal per-copy Inventory/Equip/Sell;
- scaled Equipped follower;
- Safe/Low/Critical Warmth presentation;
- progression regions with Recommended Warmth signs;
- the approved Day-5 survival-pressure subset.

Optional polish remains:
Archive;
Pen roaming;
Special Ice;
follower polish;
advanced Frost VFX;
reveal polish.

If the Day-5 survival experiment is started, Week 1 must also end with documented evidence and an explicit `PASS`, `PARTIAL PASS`, or `FAIL`.
The experiment itself does not need to pass for the prototype to succeed.


## 101. AI Implementation Workflow

For every task:
1. Read the exact task in the Development Plan.
2. Identify whether it is P0, P1, P2, or EXP.
3. Consult this prototype specification.
4. Consult Implementation Constants for exact numbers.
5. Consult the Launch Technical Specification only for architecture clarification.
6. Implement only the requested task and strictly necessary dependencies.
7. Test the task.
8. Fix failures.
9. Report:
files created/modified;
where they belong;
how to test;
expected successful behavior.
10. Stop.

The AI must not automatically proceed to the next task.

## 102. AI Scope Rule

Do not independently introduce:
future launch systems;
additional currencies;
abstractions;
new progression;
third-party frameworks;
extra remotes;
complex reusable systems "for later."

For `EXP-D5` only, implement exactly the approved survival experiment and no adjacent genre systems.
Do not generalize it into combat, item, ability, crafting, or resource frameworks.
Do not create Player HP, permanent creature loss, pet combat, roaming enemies, enemy drops/XP, material currencies, or weapon progression.

Prefer:

the smallest robust implementation that preserves launch compatibility.

## 103. Canonical One-Week Rule - CLOSED

Week 1 is complete.

The one-week rule succeeded because the prototype reached a playable, repeatedly testable loop before production conversion.

Do not reopen the prototype by adding unrelated launch systems to this document.
Use GDD v0.6, Launch Technical v0.6, Constants v1.0, and Development Plan v1.0 for production.

## 104. Canonical Prototype Priority

When time becomes constrained, protect in this order:

1. Retrieval


See -> Grab -> Carry -> Return/Freeze.

2. Thaw + Reveal


Deposit -> Wait -> CRACK -> CRACK -> SMASH.

3. Creature Speed


Reward materially changes the next expedition.

4. Warmth Training


Player can always make expedition progress at home.

5. Great Frost


World refresh + the active Great Frost Thaw Boost creates session rhythm.

6. Basic Economy


Pen -> Cash -> Hearth -> faster training.

Experimental survival pressure sits outside this protected order.
It survives only if evidence shows it materially strengthens retrieval.
Everything after the protected core is secondary.


## 105. Canonical Prototype Identity - FINAL

The Week-1 prototype proved a game about:

> seeing something desirable in the frozen wilderness, risking Warmth to bring it home, surviving authored pressure, waiting for it to thaw, smashing it open, becoming stronger, and immediately wanting to go farther.

It also proved that survival mechanics can strengthen that story when they remain subordinate to Ice retrieval.

The finalized prototype is now evidence, not the production-behavior authority.
