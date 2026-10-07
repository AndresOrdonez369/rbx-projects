# THAW A CREATURE

## Development Plan - Prototype to 3-Week Public Launch - Canonical v1.1

**Production Window:** 3 weeks  
**Week 1:** Bare-Minimum Validation Prototype  
**Week 2:** Production Conversion + Full Launch Systems  
**Week 3:** Content Presentation + Hero Moments + QA + Launch Candidate  

### Revision notes

- Adds rideable Equipped creatures as launch scope: every creature supports Following/Riding states.
- Keeps Equip/Unequip as base allocation while Ride/Unride becomes an exploration action available while carrying Ice.
- Makes copy-specific `FinalWalkSpeed` apply while Riding; Following uses base player WalkSpeed.
- Adds one mechanically identical Mounted Strike presentation for the universal survival attack.
- Schedules mount productionization into Day 10 before Week-2 feature lock without reopening completed Day 8 or restarting engineer-owned Day 9.

- Closes Week 1 with Prototype Gate **PASS**, D7-R13 **PASS**, and Survival Pressure **PASS**.
- Promotes the full validated survival package S01-S06 into launch scope.
- Locks Frost Sprite guardian availability across all five geographic Ice tiers and region-scaled Warmth damage.
- Locks every spawned Ice as one shared server opportunity; removes private onboarding-Ice tasks.
- Adds exact-Ice failure drop/rescue on Freeze, death, reset/respawn, and disconnect.
- Allows multiplayer rescue/relay without adding an intentional DropIce/transfer action.
- Marks Day 8 persistence foundation **COMPLETE** and Day 9 multiplayer/personal bases **IN PROGRESS**.
- Integrates new multiplayer/survival requirements into Day 9 and Day 10 rather than restarting completed work.
- Changes post-Week-1 document authority so the finalized prototype spec is historical evidence, not the production-behavior authority.

## 1. Document Authority

Week 1 is complete, so production authority now differs from the original prototype-development phase.

For launch production, use this order:
1. Concise GDD v0.7 - player-facing design intent.
2. Launch Technical Implementation Specification v0.7 - production behavior and architecture.
3. Implementation Constants & Content Configuration v1.1 - exact values/content/AI guardrails.
4. This Development Plan v1.1 - implementation sequence, ownership, and gates.
5. Bare-Minimum Prototype Technical Specification v1.0 FINAL - historical Week-1 behavior and validation evidence.

The finalized Prototype Spec remains authoritative for what Week 1 proved, but it must not override an explicitly promoted launch rule in the newer production documents.

The current launch-canonical model remains:

```text
uncapped MaxWarmth
+ Hearth training rate
+ Equipped creature Following/Riding + mounted Speed
+ Pen thawing
+ Great Frost world resets
+ narrow retrieval-focused Survival Pressure
+ one shared server Ice field
```

Implementation must use current Constants v1.1 immediately. Do not use obsolete Warmth-Level, private-Ice, or experiment-only rules.

### Promoted Survival Scope - Retrieval Pressure

The Day-5 Survival Pressure experiment passed and its full approved subset S01-S06 is now launch scope:
- one universal swing tool;
- stationary Frost Sprites;
- Guarded Ice encounters across all five region/Ice tiers;
- player hits reduce `CurrentWarmth` rather than Player HP;
- region-scaled Frost Sprite Warmth damage;
- session-only Equipped-creature Vitality/Frosted state;
- own-Hearth recovery;
- minimal survival feedback;
- minimal breakable route obstacles.

This promotion does **not** authorize generic combat scope.
Do not add Player HP, permanent creature death, multiple weapons, weapon progression, enemy drops/XP/currency/levels, bosses, roaming/pathfinding AI, autonomous pet combat AI / independent creature combat, Wood/Stone currencies, crafting, or resource farming.

Survival exists to strengthen the Ice journey.

### Approved Launch Mount Scope

- every creature is mountable;
- Equip/Unequip remains own-base allocation;
- Equipped runtime states are `Following` and `Riding`;
- unmounted Equipped creatures keep follower behavior;
- player moves at base WalkSpeed while Following;
- Riding uses the exact copy's `FinalWalkSpeed`;
- Ride/Unride is available during exploration, including while carrying Ice;
- mount state is runtime-only and is not persisted;
- Frosted forces Unride and blocks Ride until recovery;
- every creature uses its authored Seat/default rider anchor;
- the player's one survival attack becomes tool swing on foot and mechanically identical Mounted Strike while Riding;
- Mounted Strike does not scale damage/range/cooldown from species, rarity, Scale, WeightMultiplier, or Speed;
- no trample/contact damage, autonomous pet combat, mount Damage stats, or creature-specific traversal abilities.

## 2. AI / Developer Execution Rule

Every task should be implemented independently.
For each task:
1. read the exact task;
2. identify its priority and completion condition;
3. consult Launch Technical v0.7 for production behavior;
4. consult Implementation Constants v1.1 for exact values/content configuration;
5. consult the GDD only when player-facing intent needs clarification;
6. implement only the current task and strictly necessary dependencies;
7. test it;
8. fix failures;
9. report files created/modified, placement, test procedure, and successful result;
10. stop.

Do not automatically proceed to the next task.
Do not introduce systems, currencies, libraries, progression tracks, remotes, or abstraction layers that are not specified.

For canonical Survival Pressure work:
- keep gameplay authority server-side;
- keep tunable values in `SurvivalConfig` or the validated equivalent;
- reuse stable validated prototype code where safe;
- do not build a generic combat/item/ability framework;
- preserve Warmth as the player's expedition-survival resource;
- preserve CRACK -> CRACK -> SMASH;
- preserve shared-Ice identity and no-reroll rescue behavior.

## 3. Three-Week Production Rule

The build should remain playable every day.

Major gates:

**Gate A - End of Day 4: PASSED**  
Retrieval -> Thaw -> Reveal -> Equip Speed -> Repeat worked.

**Gate B - End of Week 1: PASSED**  
The retrieval fantasy produced credible evidence. D7-R13 passed. Survival Pressure received final **PASS** and is promoted.

**Gate C - End of Week 2: pending**  
Feature lock. All launch gameplay systems must exist. Week 3 should not invent major mechanics.

Current production position:
- Day 8: complete;
- Day 9: in progress;
- new v1.1 multiplayer/survival/mount requirements must be integrated without unnecessary rewrites of verified systems.

## WEEK 1 - BARE-MINIMUM VALIDATION PROTOTYPE

Goal: Prove the core experience before committing to production content.
Server: 1 player
Persistence: None
Creatures: Integrate all 11 already-completed meshes after repository audit
Ownership: Individual CreatureGUID copies with inherited size rolls
Ice: Regular / Thick, then Ancient / Black / Meteor as Days 6-7 permit
World: Greybox progression regions with Recommended Warmth signage
Architecture: Launch-compatible

Prototype priority labels:
- `P0` - prototype critical;
- `P1` - validation support;
- `P2` - stretch;
- `EXP` - explicit design hypothesis under test; not launch-canonical until promoted at the End-of-Week-1 gate.

An `EXP` task may be removed after testing without counting as prototype failure.
Its job is to produce evidence, not to become permanent scope by default.


## 4. Day 1 - Foundation + Warmth

### P0-D1-T01 - Create Project Structure

Create:
```text
             1   ReplicatedStorage
             2   +-- Shared
             3   +-- Remotes
             4
             5   ServerScriptService
             6   +-- Services
             7
             8   StarterPlayer
             9   +-- StarterPlayerScripts
            10       +-- Controllers
            11
            12   Workspace
            13   +-- Wilderness
            14   +-- IceSpawnPoints
            15   +-- PrototypeBase
```


Done when: expected folders exist with no unnecessary systems.


### P0-D1-T02 - Shared Remotes

Create:
```text
           1 GameplayRequest
           2 GameplayEvent
```


Do not create individual remotes per interaction.
Done when: server and client can exchange one test request/event.


### P0-D1-T03 - Initial Config Modules

Create launch-compatible:
```text
           1   GameConfig
           2   CreatureConfig
           3   IceConfig
           4   RarityConfig
           5   WarmthConfig
           6   HearthConfig
           7   WorldCycleConfig
```


Only prototype entries are needed.
Done when: gameplay values can be changed without editing service code.


### P0-D1-T04 - Greybox World

Create:

Hearth -> Regular -> Thick
Use Parts only.
Keep:
one main direction;
minimal geometry;
at most 1-2 small route variations.
Done when: player can clearly identify home, near territory, and farther territory.


### P0-D1-T05 - Prototype Hearth

Create:

spawn;
visible Hearth placeholder;
WarmZone;
Pen placeholder.
No production art.


### P0-D1-T06 - PlayerStateService

Create session-only state supporting:
```text
             1   Cash
             2   CurrentWarmth
             3   MaxWarmth
             4   HearthLevel
             5
             6   OwnedCreatures
             7   PenSlots
             8   EquippedCreature
             9
            10   CurrentlyCarryingIceID
            11   ActiveThawItems
            12   ActiveRevealSession
            13
            14   IsFrozen
```


### P0-D1-T07 - Current Warmth Drain

Outside own Hearth:

CurrentWarmth decreases continuously.
Server authoritative.


### P0-D1-T08 - Warmth Refill

Inside Hearth:

CurrentWarmth rapidly refills toward MaxWarmth.

### P0-D1-T09 - Unlimited MaxWarmth Training

Inside Hearth:

MaxWarmth continuously increases.
No:

cap;
Warmth levels;
XP currency;
clicking.


### P0-D1-T10 - Freeze State

At zero CurrentWarmth:
enter Frozen;
return player home;
set CurrentWarmth = MaxWarmth;
retain MaxWarmth.


### DAY 1 GATE

Player must be able to:

spawn -> train -> leave -> lose Warmth -> freeze -> return -> retain trained
MaxWarmth.
Do not proceed if this loop is unreliable.


## 5. Day 2 - Expedition / Retrieval

### P0-D2-T01 - Handcrafted Ice Spawn Points

Create:
```text
            1 IceSpawnPoints
            2 +-- Regular
            3 +-- Thick
```


Prototype active target:

4 Regular
2 Thick
Use Parts as authored locations.


### P0-D2-T02 - IceService


Create basic wilderness Ice lifecycle.
Each Ice tracks:
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


### P0-D2-T03 - Server Reward Roll

On spawn:

Ice Type -> Rarity -> Creature -> SilhouetteProfile.
Store reward server-side.
Do not expose exact creature/rariy before reveal.


### P0-D2-T04 - Genuine Randomness

Do not script tutorial rewards.
First reveal is random.
Bad-luck protection is not required Week 1.


### P0-D2-T05 - Prototype Silhouette Support

Ice must visually hint that something is inside.
It may be crude.
Requirement:

player should have something visual to want.
Exact identity should not always be obvious.


### P0-D2-T06 - GrabIce

Implement:

```text
            1 GrabIce(IceInstanceID)
```


Validate:
existence;
proximity;
state;
player not Frozen;
no current carried Ice.


### P0-D2-T07 - One-Ice Carry

Enforce:

0 or 1 Ice carried.
No raw Ice Inventory.
No intentional DropIce action.


### P0-D2-T08 - Carry Presentation

Attach or otherwise visually carry the selected Ice.
Keep implementation simple.


### P0-D2-T09 - Carry Warmth Drain

While carrying:

Warmth drain increases.
Movement Speed does not decrease.


### P0-D2-T10 - Carry Failure Handling

Freeze / death / reset while carrying:

retrieval fails.
Clear carried state.
Prevent teleport-home exploits.

### P0-D2-T11 - Pen Deposit

Implement:
```text
            1 DepositCarriedIce()
```


Validate own Pen / carry ownership.
Convert wilderness Ice into a ThawItem .


### DAY 2 GATE

Player must now be able to:

see an Ice -> choose it -> grab it -> race home -> successfully deposit OR
freeze and lose it.
This is the first real USP test.


## 6. Day 3 - Thaw + Reveal

### P0-D3-T01 - ThawService

Create launch-compatible logical ThawItems:
```text
            1   ThawID
            2   IceType
            3   CreatureID
            4   Rarity
            5
            6   DepositedAtTime
            7   BaseDurationSeconds
            8   BonusProgressSeconds
```


Do not build disposable per-Ice countdown code.


### P0-D3-T02 - Multiple Simultaneous Thawing

Allow unlimited logical ThawItems.
No gameplay Thaw Slots.


### P0-D3-T03 - Visual Thaw Placement

Create simple visual arrangement.
Display positions are:

presentation only.
They must not become a capacity system.


### P0-D3-T04 - Prototype Thaw Timers

Use short testing timers.
Players should experience several reveals within a short session.


### P0-D3-T05 - Thaw Progress Calculation

Use:

elapsed time + bonus progress.
Architecture should convert easily to Unix-time persistence in Week 2.


### P0-D3-T06 - Thaw Visual Stages

Minimum:

Frozen -> Thawing -> Nearly Ready -> Ready.
Cheap visual swaps are sufficient.


### P0-D3-T07 - Ready State

At 100%:

**READY TO CRACK**
Expose interaction.


### P0-D3-T08 - BeginReveal

Create server-side RevealSession.
Enforce one active session per player.


### P0-D3-T09 - CRACK


Hit #1:
validate;
advance;
visually crack Ice.


### P0-D3-T10 - CRACK

Hit #2:
validate;
advance;
expose creature more clearly;
allow rarity presentation foreshadow later.


### P0-D3-T11 - SMASH

Hit #3:
resolve exactly once;
grant stored creature;
destroy/remove ThawItem;
fire reveal event.


### P0-D3-T12 - Idempotent Reward Grant

Repeated/remitted requests must never grant duplicate creatures.


### P0-D3-T13 - First Creature Blockouts

Create 2-3 distinct Part creatures sufficient to test reveals.


### DAY 3 GATE

Complete loop must exist:

Wilderness Ice -> Retrieve -> Pen -> Thaw -> CRACK -> CRACK -> SMASH
-> Creature.

## 7. Day 4 - Creature Progression


### P0-D4-T01 - Owned Creature Counts

Implement species-count ownership.
Example:
```text
           1 Penguin = 2
           2 Mammoth = 1
```


No per-copy random stats.


### P0-D4-T02 - Rarity-Based Speed

Implement actual server-authoritative WalkSpeed based on Equipped creature rarity.
Differences must be intentionally large enough to notice.


### P0-D4-T03 - Equip Creature

Allow:

1 Equipped creature.
Server recalculates real movement Speed.


### P0-D4-T04 - Unequip / Replace

Old Equipped creature returns to Inventory.
Speed recalculates immediately.


### P0-D4-T05 - No Creature Warmth Bonus

Verify creatures affect Speed only.
Warmth remains independent.


### P1-D4-T06 - Four Pen Creature Positions

If time permits, establish 4 active Pen income positions.
Thawing Ice remains separate.


### P1-D4-T07 - Minimal Inventory State

Inventory = owned copies not assigned to:

Pen;
Equipped.
UI may remain crude.


### P1-D4-T08 - Minimal Follower

If time permits, visually represent Equipped creature following the player.
Do not spend substantial time polishing it.


## 8. STOP GATE #1 - END OF DAY 4

At this point, the player must be able to:

retrieve Ice -> thaw it -> smash it -> get creature -> Equip it -> feel
dramatically faster -> try again.
Test immediately.
Ask:
Is Ice desirable?
Is returning home tense?
Does failure invite another attempt?
Does thawing create anticipation?
Is Smash satisfying?
Does creature Speed materially improve the next run?
If these answers are weak:

STOP FEATURE DEVELOPMENT.
Use Days 5-7 to improve the P0 loop.
Do not add Great Frost or more content merely because they are scheduled.


## 9. Day 5 - Great Frost + Survival Pressure Experiment + Recursive Progression

Only continue if Gate #1 is healthy.
The order matters:

1. finish the core Great Frost P0 loop;
2. test survival pressure before investing further in P1 economy;
3. resume Cash / Pen Income / Hearth upgrades after the survival experiment has a recorded outcome.

### P0-D5-T01 - WorldCycleService

Create repeating:

Day -> Great Frost -> Day
cycle.
Prototype may use server-session timing.
Launch synchronization comes Week 2.


### P0-D5-T02 - Great Frost Countdown

Expose clear countdown to client.


### P0-D5-T03 - Prototype Frost Presentation

Minimum:
obvious lighting change;
audio cue;
UI messaging.
Do not build final spectacle yet.


### P0-D5-T04 - Ice Field Reset

At Frost:
remove available/unclaimed Ice;
preserve carried Ice;
repopulate spawn points.
Disable new GrabIce confirmations during the 15-second Frost transition; re-enable when Day resumes.


### P0-D5-T05 - Great Frost Thaw Boost

During normal Day:

`ThawMultiplier = 1x`

During the full authoritative Great Frost phase:

`ThawMultiplier = 10x`

Requirements:
- the multiplier is active only while Great Frost is active;
- unfinished Ice already in the Pen accelerates for the portion of time that overlaps Great Frost;
- Ice deposited during Great Frost immediately receives `10x` for the remaining Frost duration;
- when Day resumes, thaw speed immediately returns to `1x`;
- progress earned during Great Frost is preserved and never rewinds;
- Ready Ice remains Ready;
- no creature is auto-granted.

Do not implement this as a one-time fixed `+30 sec` grant.


### EXP-D5-S01 - Universal Survival Tool

Prototype one universal melee-style tool with one simple verb:

input -> swing -> server validates -> valid target receives the approved effect.

Purpose:
provide tactile agency during dangerous retrieval without creating a full weapon system.

Requirements:
- one tool only;
- simple swing cadence;
- server-authoritative range / cooldown / target validation;
- usable against approved experimental threats;
- later usable against approved breakable environment objects if `EXP-D5-GATE` passes;
- existing reveal interaction remains unchanged during this experiment.

Do not add:
combos;
blocking;
heavy attacks;
stamina;
weapon rarity;
weapon durability;
weapon upgrades;
weapon inventory;
multiple weapon classes;
combat XP.


### EXP-D5-S02 - Stationary Frost Sprite

Create one minimal hostile wilderness threat.

Behavior:
- stationary;
- no pathfinding or roaming;
- dormant outside its engagement radius;
- when a valid target enters range: telegraph -> projectile/attack -> cooldown -> repeat;
- may target the player or the currently Equipped creature when both are valid;
- can be defeated by the universal survival tool;
- exact health, range, cooldown, projectile speed, Warmth damage, and creature damage remain configurable experiment values.

Player hit result:

CurrentWarmth decreases.

Do not create Player HP.

Creature hit result:

temporary experimental CreatureVitality decreases.

Do not add:
enemy drops;
enemy currency;
enemy XP;
enemy levels;
roaming AI;
melee chase behavior;
boss logic.


### EXP-D5-S03 - Guarded Ice Encounters

Bind Frost Sprites to selected authored Ice opportunities rather than scattering generic enemies through the wilderness.

Prototype intent:

Guardians should communicate:

"That Ice is dangerous, therefore it may be worth attempting."

Requirements:
- some Ice remains completely unguarded;
- selected Regular Ice may use a light threat;
- selected Thick / desirable Ice may use stronger guardian presence;
- guardian placement remains authored and readable;
- guardians exist to increase Ice-retrieval tension, not to become a farming objective;
- a player can choose to fight, rush the Ice, or retreat;
- guardians remain stationary, so leaving their threat area is a valid disengage action;
- Great Frost field reset also clears/rebuilds active experimental guardian encounters so Ice opportunities and their danger reroll together;
- do not create independent long-lived enemy respawn timers for this prototype.

Do not make every Ice guarded.
Do not hide the desirable Ice behind an unreadable enemy wall.
The Ice must remain the visual and motivational objective.


### EXP-D5-S04 - Equipped Creature Vitality / Frosted State

Add temporary session-only Vitality to the currently Equipped creature for the survival experiment.

Purpose:
test whether protecting the player's companion creates stronger expedition attachment and danger.

Rules:
- only the currently Equipped creature needs experimental Vitality;
- creatures do not attack;
- creatures do not gain Damage, Defense, levels, random stats, or combat abilities;
- damage never deletes ownership;
- damage never destroys a creature permanently;
- Pen creatures are not part of this experiment.

At zero experimental CreatureVitality:

Equipped creature -> FROSTED / DOWNED

Then:
- creature remains owned;
- follower is visibly Frosted/removed from active following presentation;
- Equipped Speed bonus is temporarily unavailable for the remainder of the dangerous return;
- the player may continue the expedition;
- returning to the Hearth restores the creature and its normal Equipped Speed;
- Freeze/reset recovery must never create permanent creature loss.

The desired tension is:

"My companion went down; can I still get this Ice home?"

not:

"I permanently lost the creature I collected."


### EXP-D5-S05 - Minimal Survival Feedback

Add only enough presentation for the experiment to be readable.

Minimum:
- simple Equipped-creature Vitality bar while relevant;
- simple Frost Sprite health/readability feedback;
- readable enemy attack telegraph;
- clear player-hit feedback tied to Warmth loss;
- clear creature-hit feedback;
- obvious Frosted/Downed state;
- simple tool hit confirmation.

Do not build production combat UI.
Do not add a second player survival meter.
Warmth remains the player's expedition-survival resource.


### EXP-D5-GATE - Survival Pressure Validation

Stop after S01-S05 and playtest before adding breakable environment content or expanding combat.

The question is not:

"Is combat fun?"

The question is:

"Does survival pressure make retrieving desirable Ice significantly more tense, memorable, and story-worthy?"

Observe:
- Does the player willingly engage guardians because they want the Ice?
- Does a guarded Ice feel more desirable / dangerous rather than merely annoying?
- Does the player understand that enemy hits reduce Warmth rather than a separate HP stat?
- Does creature danger create protect/retreat decisions?
- Does the Frosted creature state create a dramatic return without making players afraid to use good creatures?
- Does the universal tool feel like useful agency rather than the new main progression system?
- Does the player still talk about the Ice and return trip more than the enemies?

Ask:

"What was the coolest thing that happened?"

"Why did you fight or avoid the Frost Sprites?"

"What did you care about most during the encounter?"

Strong evidence resembles:

"I wanted that Ice, the sprites got my creature, and I barely made it home."

Concerning evidence resembles:

"Killing monsters was the fun part. Where can I farm more?"

Gate outcome:

PASS
- survival pressure clearly strengthens retrieval;
- keep S01-S05 enabled for Day 6-7 validation;
- proceed to S06 if time remains;
- this is still prototype evidence, not final launch approval.

PARTIAL PASS
- preserve only the specific element(s) that clearly strengthen retrieval;
- remove or disable distracting parts;
- do not broaden scope.

FAIL
- remove/disable the experimental survival mechanics cleanly;
- preserve the playtest conclusion;
- continue with the canonical P1 economy tasks;
- do not treat the failed experiment as prototype failure if the original retrieval loop remains compelling.


### EXP-D5-S06 - Breakable Environment Test - Only After PASS/PARTIAL PASS

Only implement this task if `EXP-D5-GATE` supports continuing the experiment.

Create a tiny set of breakable environmental obstacles/nodes that use the same universal swing verb.
Examples may include:
- frozen branch / wood obstacle;
- brittle stone / ice-covered rock;
- frost crystal obstruction.

Purpose:
test whether breaking through the environment adds useful route-time decisions during Warmth pressure.

Use them to create choices such as:

safe longer route
vs.
short route requiring several hits
vs.
guarded shortcut.

Do not add yet:
Wood currency;
Stone currency;
material inventory;
crafting;
recipes;
resource economy;
node farming loop;
resource drops from enemies.

If players strongly want material gathering after this test, record it as a separate post-prototype design hypothesis.
Do not invent a crafting game to justify the nodes.


### P1-D5-T06 - Cash

Implement one currency.


### P1-D5-T07 - Pen Income

Aggregate all four Pen positions into one server income tick.


### P1-D5-T08 - Hearth Upgrade

Minimum:

2 functional Hearth levels.
Upgrade increases:

Warmth training rate.
No Warmth cap.
No direct Warmth award.


### DAY 5 GATE - PASSED / IMPLEMENTATION COMPLETE

Day-5 implementation is complete. The canonical progression works:

retrieve -> deposit -> train -> Frost -> thaw acceleration -> refreshed Ice ->
reveal -> better creature -> faster expedition.

Recorded Survival Pressure Experiment outcome: **PASS**.

Observed evidence: guarded retrieval increased tension while the player still cared most about the carried Ice and CurrentWarmth. Keep S01-S05 enabled as approved prototype evidence; do not broaden combat scope automatically.

If PASS/PARTIAL PASS:
Day 5 should additionally demonstrate that selected desirable Ice can create readable survival pressure without replacing Ice as the objective.

If FAIL:
Day 5 remains valid after the experimental systems are removed/disabled and the canonical progression loop is healthy.

## 10. Day 6 - Jackpot / Per-Copy Metagame Foundation - COMPLETE

Survival rule:
- `EXP-D5-GATE = PASS`;
- keep S01-S05 active;
- do not add new enemy types, weapon progression, resource currencies, crafting, pet attacks, or combat XP during this revision.

### D6-R00 - Audit the 11 Existing Creature Assets

**COMPLETE - live Studio audit verified.**

Verified `Workspace.Creatures` contains exactly 11 direct-child Models:
- `BEAR`;
- `HRAESVLGR`;
- `ICESERPENT`;
- `MAMMOTH`;
- `NIDHOGG`;
- `PENGUIN`;
- `RABBIT`;
- `SEAL`;
- `SLEIPNIR`;
- `TROLL`;
- `WOLF`.

Current `CreatureConfig` matches 8 live species:
- Bear;
- Mammoth;
- Nidhogg;
- Penguin;
- Rabbit;
- Seal;
- Troll;
- Wolf.

Currently unconfigured live models:
- Hraesvlgr;
- IceSerpent;
- Sleipnir.

Verified live asset contract:
- all 11 currently lack `PrimaryPart`;
- all 11 currently lack a direct child named `Root`;
- each is a simple two-MeshPart Model with no embedded gameplay scripts, Humanoid, AnimationController, Motor6D, or WeldConstraint;
- several preserve authored Model scale greater than `1.0`;
- current presentation clones normalize collision/query/touch behavior at runtime.

D6-R00 did not normalize models, assign new stats, change rarity, or change Ice pools.
The authored relative model sizes are evidence for later `BaseVisualScale` design; they must not be silently flattened.

Technical debt note:
The production creature asset source should eventually be reproducible through source control / build tooling before launch or persistence hardening. The current live Studio models under `Workspace.Creatures` do not block D6-R01 ownership migration.

### D6-R01 - Per-Copy Creature Ownership Migration

Replace species-count ownership with:

```text
CreatureCopies[CreatureGUID] = {
    CreatureID,
    WeightMultiplier,
}
```

Migrate PenSlots and Equipped state to CreatureGUID allocation.
Preserve discovery as species-based.
Do this before persistence work.

### D6-R02 - Authoritative Ice Weight + Scale Roll

At Ice spawn, server rolls exactly one WeightMultiplier using Constants v0.9.
Derive:

```text
Scale = cbrt(WeightMultiplier)
```

Maximum supported visual Scale = `5.0x`.
No rerolls during carry/deposit/reveal.

### D6-R03 - Ice Visual Scaling Through Full Journey

Apply exact derived Scale to:
- wilderness Ice;
- carried Ice;
- deposited/thawing Ice;
- Ready/reveal Ice.

Extreme Ice must remain non-blocking to player traversal physics.

### D6-R04 - Creature Size Inheritance

Reveal creates one CreatureGUID using the Ice's exact WeightMultiplier.
The resulting creature uses the same derived Scale relative to that species' base size.

### D6-R05 - Configure All 11 Existing Creatures

After D6-R00 audit and explicit design approval, every existing mesh receives:
- Rarity/content assignment;
- ReferenceWeight;
- BaseVisualScale;
- BaseIncomePerSecond;
- BaseWalkSpeed;
- eligible Ice pools.

Do not create redundant blockout meshes.

### D6-R06 - Size-Based Income + Speed

Use current canonical first-pass formulas:

```text
FinalIncome = round(BaseIncomePerSecond * Scale^2)
SpeedMultiplier = 1 + 0.15 * (Scale - 1)
FinalWalkSpeed = BaseWalkSpeed * SpeedMultiplier
```

Income scales much harder than Speed.

### D6-R07 - GUID Pen / Equip / Inventory

All allocation actions operate on exact CreatureGUID copies.
Copies of the same species remain distinguishable.
No copy may exist in two allocation states simultaneously.

### D6-R08 - Copy-Specific Pen Income

Keep one aggregate 1-second Pen tick.
Each occupied slot contributes that copy's FinalIncome.
Equipped and Inventory copies contribute zero.

### D6-R09 - Creature Stat Presentation

Minimum world/inventory readability:

```text
SPEED <value>
PEN $<value>/s
```

Extreme Scale should be visually obvious without needing text.

### D6-R10 - Jackpot Validation Gate

Focused test, not a full QA day.
Prove:

```text
giant Ice
-> risky retrieval
-> same-scale giant creature
-> unusually strong Income
-> noticeably better Speed
```

Strong evidence:
- player changes route because one Ice is visibly enormous;
- duplicates remain exciting because copy rolls differ;
- a huge creature feels like a social trophy;
- the jackpot strengthens retrieval/reveal rather than replacing it.

Do not move to persistence until the per-copy data model is stable.


## 11. Day 7 - Big-Number Progression + World Expansion - COMPLETE

Day 7 is no longer reserved as QA-only.
Continue using the established per-task workflow: implement -> Studio sanity test -> cleanup -> commit.

### D7-R01 - Big-Number Warmth Rebalance

Adopt Constants v0.9 first-pass big-number values.
Warmth should visibly climb in satisfying whole-number quantities.
No cap.

### D7-R02 - Scalable Hearth Refill

CurrentWarmth refill must scale with MaxWarmth so huge progression values do not create long idle refill waits.
Use the configured fraction-of-MaxWarmth refill rule.

### D7-R03 - Hearth Progression Expansion

Expand the prototype beyond the initial three levels using the v0.9 cost/rate curve.
Keep the same mechanic: Cash -> faster automatic MaxWarmth training.
No direct fixed MaxWarmth purchase.

### D7-R04 - Hearth Prominence Pass

Make the Hearth an obvious progression landmark through:
- stronger fire/light/smoke/embers;
- visible WarmZone treatment;
- `HEARTH LV. X`;
- `+Warmth/sec`;
- upgrade cost / MAX.

Do not change its core function.

### D7-R05 - Expanded Progression Regions

Greybox enough world depth to support:
- Snowfield / Regular;
- Frozen Pass / Thick;
- Ancient Expanse / Ancient;
- Black Ice Hollow / Black;
- Meteor Reach / Meteor if stable/time permits.

Keep handcrafted spawn points and clear sightlines/aspiration framing.

### D7-R06 - Recommended Warmth Signs

Every region entrance clearly displays its configured Recommended Warmth.
Guidance only; never a hard gate.

### D7-R07 - Regional Cold Severity

Apply `RegionColdMultiplier` to base Warmth drain.
Carrying multiplier still stacks with regional cold.
This lets Recommended Warmth grow by orders of magnitude without an impossibly large physical map.

### D7-R08 - Ancient Ice

Implement functional Ancient Ice using authored points, pool, thaw config, presentation, and region assignment.

### D7-R09 - Black Ice

Implement functional Black Ice if D7-R08 is stable.

### D7-R10 - Meteor Ice

Implement functional Meteor Ice if time/stability permits.
Do not force it if the underlying size/ownership systems are not healthy.

### D7-R11 - 11-Creature Pool Expansion

Distribute the repository-audited 11 creature species across functional pools according to explicit approved content mapping.
Do not fabricate assignments.

### D7-R12 - Low-Warmth Feedback

Implement/retain percentage-based:

```text
Safe -> Low -> Critical
```

Presentation must remain readable with large Warmth numbers.

### D7-R13 - Progression Validation Gate

Focused test:

> Did the player see something enormous or far away, understand the Warmth target, improve Hearth and/or find a better creature copy, and eventually reach it?

Strong evidence:
- Warmth growth itself feels satisfying;
- Hearth upgrades create dramatic acceleration;
- region signs invite risk rather than block access;
- huge creature rolls noticeably compress earlier terrain;
- deeper Ice types create new desire.

Day 7 still includes sanity/regression checks inside each task, but no longer spends the full day on QA-only work.

## 12. END-OF-WEEK-1 PROTOTYPE GATE - PASSED

Final result: **PASS**.

Credible evidence supports:
- players want visible Ice;
- retrieval creates tension;
- near-failure produces retry desire;
- thawing creates anticipation;
- productive activity exists during thawing;
- Warmth training feels valuable;
- Hearth upgrades create dramatic acceleration;
- better creature copies make traversal materially faster;
- region signs invite risk rather than hard-gate access;
- Great Frost refreshes interest;
- reveal creates another-Ice desire;
- deeper Ice types create aspiration;
- players can tell memorable retrieval stories rather than only describing pet hatching.

D7-R13 Progression Validation Gate: **PASS**.

The project is approved to continue into launch production.

### 12A. Survival Pressure Promotion Decision - PASS

Final decision: **PASS - full approved subset promoted.**

Promoted mechanics:
1. Universal survival tool.
2. Stationary Frost Sprites.
3. Guarded Ice.
4. Frost Sprite hits reduce `CurrentWarmth`; no Player HP.
5. Equipped-creature session Vitality.
6. Frosted/Downed state with temporary Speed suppression and no ownership loss.
7. Own-Hearth recovery.
8. Minimal survival feedback.
9. Breakable route obstacles using the same universal tool.
10. Regional guardian presence across all five Ice/region tiers.
11. Regional Warmth damage: `10 / 100 / 1,000 / 10,000 / 100,000` from Snowfield through Meteor Reach.

Promotion boundaries remain strict:
- no material currencies/crafting;
- no permanent creature death;
- no Player HP;
- no multiple weapons/weapon progression;
- no enemy drops/combat XP;
- no bosses/roaming AI;
- no autonomous pet combat AI / independent creature combat.

Productionization is scheduled into the active Week-2 multiplayer/world-cycle work below.

### 12B. Parallel Creature Production Track - ACTIVE

Creature art remains a parallel production track after the successful Week-1 gate.

Rules:
- preserve engineering priorities;
- use standardized Root/scale/orientation from the asset contract;
- prioritize readability and reuse simple animation/rig solutions;
- do not add creature-specific gameplay abilities;
- the current 11 validated species remain mechanically valid;
- the remaining five species required to reach the 16-species launch quantity need explicit content approval before implementation.

If creature production slips, simplify environment/animation before cutting the 16-species quantity target.

## WEEK 2 - PRODUCTION CONVERSION + FULL LAUNCH SYSTEMS

Survival Pressure is now launch-canonical and must be productionized without expanding beyond the approved subset.

Goal: transform the validated prototype into the complete mechanical launch game.
By the end of Week 2 all launch gameplay systems - including shared-Ice multiplayer and promoted Survival Pressure - must exist.
Art may still be unfinished.


## 13. Day 8 - Persistence Foundation - COMPLETE

**Status:** implemented and runtime-operational before this v1.1 documentation revision.

Do not restart Day 8 merely because Survival Pressure was promoted.
Audit only the new non-persistence boundaries below.

### L-D8-T01 - DataService - COMPLETE

DataService is the only service allowed to communicate directly with persistent storage.

### L-D8-T02 - Persistent Schema - COMPLETE

Current production schema supports exact per-copy progression:

```text
DataVersion
Cash
MaxWarmth
HearthLevel
CreatureCopies[CreatureGUID] = { CreatureID, WeightMultiplier }
PenSlots[1..4] = CreatureGUID or nil
EquippedCreatureGUID = CreatureGUID or nil
DiscoveredCreatures[CreatureID] = true
ThawingIce[]
```

### L-D8-T03 - Persistent Thaw Format - COMPLETE

Persistent ThawItems preserve exact size lineage:

```text
ThawID
IceType
IsSpecial
CreatureID
Rarity
WeightMultiplier
DepositedAtUnix
BaseDurationSeconds
BonusProgressSeconds
```

### L-D8-T04 - Load Failure Protection - COMPLETE

Never overwrite legitimate data with an empty/default profile after a failed load.

### L-D8-T05 - Join Restore - COMPLETE

Restore creatures/Pen/Equipped/ThawItems; derive Scale/Income/Speed; set `CurrentWarmth = MaxWarmth`.

### L-D8-T06 - Offline Thawing - COMPLETE

Calculate elapsed real time for deposited Ice. Ready Ice remains Ready and is never auto-granted.

### L-D8-T07 - Save / Rejoin Test - COMPLETE

Persistent progression has been runtime-tested.

### v1.1 Survival + Mount Persistence Audit

Confirm D8 does **not** persist:
- CurrentWarmth;
- carried/dropped wilderness Ice;
- Frost Sprite state;
- tool cooldown;
- breakable current state;
- Equipped-creature current Vitality;
- Frosted/Downed state;
- Ride/Unride state (`IsRiding` / MountState);
- mount Seat/presentation state;
- current encounter target.

If D8 already ignores these runtime fields, no implementation change is required.

## 14. Day 9 - Multiplayer + Personal Bases - IN PROGRESS

**Status:** engineer-owned/in progress at the time of this revision.

Do not discard working D9 infrastructure. Integrate the v1.1 shared-Ice and Survival Pressure requirements into the existing implementation; mount productionization is scheduled in Day 10.

### L-D9-T01 - Raise Server Target

Initial target: 4 players/server.

### L-D9-T02 - BaseService

Assign one personal base per player using the canonical four-plot shared-camp topology.

### L-D9-T03 - Base Ownership

Only the owner can refill/train/upgrade/deposit/manage Pen/Equip/Sell/reveal at that base.
Another player's Hearth/WarmZone provides no refill/training.

Own-Hearth rule now also includes:
- restore the owner's Equipped-creature Vitality;
- clear Frosted/Downed;
- restore Equipped Speed.

Another player's Hearth must not restore a visitor's creature.

### L-D9-T04 - Universal Shared Wilderness

All players use the exact same Ice field.
There are **no private/per-player Ice copies**.
This applies to Regular, Thick, Ancient, Black, Meteor, and Special Ice.

Onboarding may guide players to shared Regular Ice but may not create private Ice.

### L-D9-T05 - Shared Ice Contention

First valid server-side Grab wins.
One IceInstanceID may have only one carrier.
All clients observe the same ownership state.

### L-D9-T06 - Universal Carrier-Failure Drop / Rescue

On Freeze, character death, Reset Character/respawn, or disconnect before Pen deposit:
- release the exact same Ice at the carrier's last valid safe position;
- preserve IceInstanceID, IceType, CreatureID, Rarity, WeightMultiplier/Scale, and Special metadata;
- clear owner;
- set Available;
- allow any player to Grab it.

If the failure position is invalid, fall back to last valid grounded/safe position, then authored origin.

No reroll.
No intentional DropIce request.
Rescue/relay is valid gameplay.

### L-D9-T07 - Multiplayer Remote Validation

Audit all remotes for proximity, ownership, rate limiting, state transitions, and shared-world races.

### L-D9-T08 - Base Isolation Test

Player A must never manipulate Player B's Hearth/Pen/ThawItem/creature/reveal or gain Warmth/creature recovery from Player B's WarmZone.

### L-D9-T09 - Shared Onboarding Guidance

Remove/avoid the old private onboarding-Ice path.

Eligible new players may be guided/highlighted toward a suitable available shared Regular Ice.
If that Ice is taken, retarget another shared Regular.
If none is available, communicate the shared Great Frost/world refresh rather than spawning a private copy.

### L-D9-T10 - Shared-Ice Multiplayer Test

With 2-4 players verify:
- everyone sees the same Ice opportunities;
- first valid Grab wins;
- no duplicate claims;
- carrier Freeze drops the exact Ice;
- death/reset drops the exact Ice;
- disconnect drops the exact Ice;
- another player can rescue/deposit it;
- no reward/WeightMultiplier reroll occurs;
- own-base deposit isolation holds.

### L-D9-T11 - Multiplayer Survival Foundation

Productionize the existing validated survival behavior enough for multiplayer safety:
- Frost Sprites are shared authoritative world threats, not per-player clones;
- player Warmth damage applies only to the player hit;
- creature Vitality is per player's currently Equipped creature;
- multiple players may hit the same Sprite through server validation;
- exact target-priority policy remains configurable;
- no aggro/assist/kill-credit/loot system is inferred.

Mount note for D9: do not redesign stable BaseService around mounts. Equip/Unequip stays own-base management. Ride/Unride is a later exploration/runtime action and must not be restricted to the base by incidental D9 validation.

## 15. Day 10 - Production World Cycle + Survival + Mount Integration

### L-D10-T01 - Wall-Clock Great Frost

Use canonical shared timing and expose CycleIndex / CurrentPhase / NextTransitionUnix / TimeRemaining.

### L-D10-T02 - Server Boot / Synchronization

Servers share a consistent cycle rhythm and do not retroactively process missed Frost transitions.

### L-D10-T03 - Online Thaw Acceleration

Apply only the configured launch online Frost bonus to eligible deposited Ice. Offline thawing remains separate.

### L-D10-T04 - Production Shared Ice / Guardian Field Reset

During Great Frost:
- lock new Grab confirmations;
- remove eligible Available shared Ice from the prior field;
- preserve carried Ice;
- preserve Pen/Ready Ice;
- clear/rebuild Guarded-Ice Sprite encounters;
- reset/rebuild authored breakable route state where configured;
- populate the new shared field;
- unlock Grab when Day resumes.

If a carried Ice's owner fails during the already-running Frost transition, the released Ice survives that current transition and becomes Available subject to Grab locking. A future Great Frost may remove it if still unclaimed.

### L-D10-T05 - Special-Ice Cadence

Implement configured observed-Frost cadence.

### L-D10-T06 - Special Ice Roll Profile

Special Ice remains visibly special with elevated rarity opportunity while exact reward stays hidden.

### L-D10-T07 - Universal Special Ice Lifecycle

Special Ice uses the same shared carrier-failure contract as all Ice:
- no special return-to-origin on ordinary failure;
- release exact Ice at last valid safe carrier position;
- preserve reward/WeightMultiplier/Special metadata;
- any player may rescue it;
- future Great Frost may remove it if still unclaimed.

### L-D10-T08 - Server-Wide Special Ice Event

Send presentation event without exposing exact reward.

### L-D10-S01 - Production SurvivalConfig

Promote validated values into `SurvivalConfig` or existing equivalent; do not build a generic combat framework.

### L-D10-S02 - Regional Frost Sprite Warmth Damage

Lock first-pass values:

```text
Snowfield          10
Frozen Pass        100
Ancient Expanse    1,000
Black Ice Hollow   10,000
Meteor Reach       100,000
```

Damage comes from the Sprite's region/location, not player MaxWarmth or Ice reward.

### L-D10-S03 - Guarded Ice Across All Tiers

Regular, Thick, Ancient, Black, and Meteor regions may all author Guarded-Ice encounters.
Not every individual Ice must be guarded.
Special Ice uses the threat profile of the region where it spawns.

### L-D10-S04 - Equipped Creature Vitality Production Pass

Preserve session-only Vitality, Frosted/Downed, Speed suppression, no ownership loss, and own-Hearth recovery.

### L-D10-S05 - Breakable Route Obstacles Production Pass

Reuse the universal swing verb for route obstacles.
No resources/currency/crafting/drops.

### L-D10-S06 - Multiplayer Survival Regression

Verify with multiple players:
- shared Sprite state;
- correct player-specific Warmth damage;
- correct creature-specific Vitality damage;
- safe own-Hearth recovery;
- universal attack validation;
- no survival state persistence;
- Great Frost resets guardians/breakables correctly;
- retrieval remains the primary objective.

### L-D10-M01 - Mount Runtime State

Add runtime-only `MountState = None / Following / Riding`.
Equip/join/respawn with an Equipped creature begins in Following. Do not persist mount state.

### L-D10-M02 - All-Creature Seat / Mount Contract

Audit every current launch creature asset for its authored Seat/default rider anchor. Create the smallest shared mount presentation contract. Optional per-species MountProfile data may refine pose/camera/animation, but no species gets unique traversal mechanics.

### L-D10-M03 - Ride / Unride Exploration Flow

Ride/Unride must work away from base and while carrying Ice. They must not change ownership, Pen allocation, carried-Ice state, or income allocation. Following uses player base WalkSpeed `16`; Riding uses the equipped copy's `FinalWalkSpeed`.

### L-D10-M04 - Following / Riding Presentation

When not Riding, preserve the existing follower behavior. When Riding, use the creature Seat/configured rider anchor and scale-aware camera framing. Giant/small mounts are valid and should not be normalized away.

### L-D10-M05 - Universal Mounted Strike

Use the same survival attack input and gameplay values as the on-foot tool. Riding changes presentation to Mounted Strike and uses a server-authoritative ground/front `MountedCombatOrigin`. Same damage, cooldown, valid targets, and effective range. No species/rarity/Scale/Speed scaling and no trample/contact damage.

Species-specific bite/stomp/kick/swipe/headbutt animations are optional presentation only. Giant-mount readability may use camera offsets and/or a subtle valid-target marker; no auto-attack.

### L-D10-M06 - Frosted Forced Unride

If the Equipped creature reaches zero Vitality while Riding, force Unride immediately, return the player to base WalkSpeed, keep the creature logically Equipped, and reject Ride until own-Hearth/failure recovery restores it.

### L-D10-M07 - Mount + Carry + Multiplayer Regression

Test at minimum:
- Ride/Unride with and without carried Ice;
- no Ice drop/duplication during Ride transitions;
- following/riding visible correctly to other players;
- mounted attack against shared Frost Sprites and breakables;
- giant mount can hit/read nearby ground-level Sprite without enlarged combat power;
- Frosted forces safe Unride;
- reconnect/respawn starts Following, not Riding;
- equipped copy still earns zero Pen income in both states.

## 16. Day 11 - 16-Creature Target + Five Rarities

The current build already supports five rarity tiers and 11 validated species.
Do not re-add Legendary or overwrite the approved 11-species baseline.

### L-D11-T01 - Productionize Five-Rarity Presentation

Verify Common / Uncommon / Rare / Epic / Legendary presentation, reveal treatment, UI, and pool support are production-ready.

### L-D11-T02 - Preserve the Locked 11-Species Baseline

Current approved species:

```text
Common      Penguin, Rabbit, Seal
Uncommon    Wolf, Bear
Rare        Mammoth, Sleipnir
Epic        Troll, IceSerpent
Legendary   Hraesvlgr, Nidhogg
```

Do not change their approved base stats/pools during roster expansion unless separately approved.

### L-D11-T03 - Add Remaining 5 Launch Species - Requires Explicit Content Approval

The 16-species launch quantity target remains, but the remaining five species are not defined by this v1.1 revision.
Before implementation, explicitly approve for each new species:
- CreatureID/name;
- rarity;
- model/asset;
- ReferenceWeight;
- BaseVisualScale;
- BaseIncomePerSecond;
- BaseWalkSpeed;
- eligible Ice pools;
- SilhouetteProfile.

Do not resurrect stale placeholder species lists automatically.

### L-D11-T04 - Full Ownership Support

Verify all configured launch species support Inventory, Pen, Equip, Sell, Archive, persistence, inherited Scale, Following/Riding mount presentation, and Frosted-session behavior where applicable.

### L-D11-T05 - Full Speed / Income Progression

Verify species baselines + inherited size Scale create clearly different copy values across the full content progression without making rarity itself a hidden second stat formula.

## 17. Day 12 - Five Ice Types

### L-D12-T01 - Ancient Ice

Add config, spawn points, pool and presentation profile.


### L-D12-T02 - Black Ice

Add config, spawn points, pool and presentation profile.


### L-D12-T03 - Meteor Ice

Add config, spawn points, pool and presentation profile.


### L-D12-T04 - Full Ice Pools

Configure all five Ice types according to canonical creature pools.

### L-D12-T05 - Full Rarity Weights

Keep them configuration-driven.


### L-D12-T06 - Thaw Durations by Ice Type

Use Ice Type-not rolled rarity-to determine duration.
Protect reward mystery.


### L-D12-T07 - Long-Distance Silhouette Support

Ensure later Ice can visually advertise mystery without revealing exact species.


## 18. Day 13 - Warmth / Hearth Progression

### L-D13-T01 - 10 Hearth Levels

Implement complete launch progression.
Each level defines:
cost;
training rate;
visual stage reference.


### L-D13-T02 - Unlimited MaxWarmth

Verify there is no hidden maximum.


### L-D13-T03 - Recommended Warmth

Configure:
Regular;
Thick;
Ancient;
Black;
Meteor.
Recommendations must not become hard gates.


### L-D13-T04 - Region Communication


Expose Recommended Warmth through simple UI/signage.


### L-D13-T05 - Warmth / Speed Interaction Test

Verify faster creatures can meaningfully sequence-break recommendations without trivializing
the entire world.


### L-D13-T06 - Carry Drain Balance Hook

Keep multiplier configurable by Ice if needed, but do not add new endurance systems.


## 19. Day 14 - Economy + Collection + Feature Lock

### L-D14-T01 - Final Pen Income

All four slots operate correctly.


### L-D14-T02 - Full Sell Paths

Support:
Inventory;
Pen;
Equipped.


### L-D14-T03 - Production Inventory Logic

Finalize count consistency and state validation.


### L-D14-T04 - Frozen Archive

Full:

X / 16
with discovery persistence.


### L-D14-T05 - Discovery Never Reverses

Selling final copy must not remove discovery.

### L-D14-T06 - Economy Integration

Verify:

creatures -> Cash -> Hearth -> faster Warmth training.

### L-D14-T07 - Pen / Thaw Separation

Verify:

4 creature-income positions
!=
thaw capacity.
Thaw remains logically unlimited.


### L-D14-T08 - FEATURE LOCK

At end of Day 14:

No new launch gameplay systems.
The launch should now mechanically exist.


## WEEK 3 - PRESENTATION, HERO MOMENTS, QA, LAUNCH

Goal: Make the validated game look desirable, communicate progression clearly, deliver the
USP, and survive public players.
Do not use Week 3 to redesign the economy or add major mechanics unless a critical defect
forces it.


## 20. Day 15 - World Art Direction Pass

### F-D15-T01 - Norse-Inspired Fantasy Pass

Begin converting greybox toward:

stylized Great Frost fantasy.
Use:
snow;

carved wood;
Hearths;
runestones;
aurora language;
ancient frozen environment.
Do not create lore-heavy systems.


### F-D15-T02 - Preserve Simple Level Geometry

Do not turn the map into a complex open world.
Production time remains creature-focused.


### F-D15-T03 - Region Differentiation

Make progression readable:

Regular -> Thick -> Ancient -> Black -> Meteor.

### F-D15-T04 - Distant Aspiration

Ensure players can see visually exciting later content before reaching it.
This supports Hero Moment #2.


### F-D15-T05 - Pen Presentation

Pen should read as:

living trophy room + thawing area.

### F-D15-T06 - Hearth Presentation

Make Hearth progression visibly noticeable without requiring ten unique high-complexity
models.
Reuse visual stages where necessary.


## 21. Day 16 - Creature Finalization + Integration Pass


F-D16-T01 through F-D16-T16 - Creature Asset Finalization
Finish, simplify where necessary, and integrate production-quality versions of all 16 launch creatures. Creature production should already have been running in parallel since the Week-1 gate; Day 16 is the finalization/integration deadline, not the starting point.
Priority:
1. silhouette;
2. appeal;
3. readability;
4. visual distinction;
5. technical consistency.
Do not over-invest in animation complexity.


### F-D16-T17 - Creature Asset Contract QA

All creatures:
Root;
PrimaryPart;
standardized orientation;
correct scale;
no gameplay scripts.


### F-D16-T18 - Pen / Following / Riding Compatibility

Verify every final creature works in Pen, follower, and mounted contexts. Confirm the authored Seat/default rider anchor, camera framing, rider pose, carried-Ice presentation, and optional mounted-attack animation remain readable from minimum to maximum Scale.


## 22. Day 17 - Hero Moment Pass

This day is explicitly dedicated to making existing mechanics feel epic.
### F-D17-T01 - Hero #1: Great Frost

Improve:
sky transition;
aurora;
sound;
wind;
frost wave / world reaction.
Desired:

"Wait, what just happened?"

### F-D17-T02 - Hero #2: Impossible Ice

Ensure one or more later opportunities create:

"I need THAT."
Use scale, silhouette, glow, runes, distance.


### F-D17-T03 - Hero #3: Barely-Made-It-Home

Polish:
low-Warmth visual escalation;
critical audio;
Hearth readability;
carry presentation.
Desired:

"I barely made it."

### F-D17-T04 - Hero #4: Legendary Smash

Add:
stronger cracks;
final explosion;
camera impact;
rarity sound;
runic effects;
creature pose/movement.
Desired:

"NO WAY, I GOT IT."

### F-D17-T05 - Hero #5: Endgame Player


Polish:
real Legendary Speed;
run animation;
subtle FOV;
snow/movement trail;
follower presence.
Desired observer response:

"How do I become that player?"

## 23. Day 18 - UI + Onboarding

### F-D18-T01 - Warmth UI

Clearly show:
Current;
Max;
Low/Critical state.


### F-D18-T02 - Warmth Training UI

Player should understand:

Warmth is increasing while at home.
Do not add unnecessary XP systems.


### F-D18-T03 - Great Frost Countdown

Readable without dominating screen.


### F-D18-T04 - Thaw Status

Players can easily identify:
thawing;
nearly ready;
ready.

### F-D18-T05 - Recommended Warmth

Communicate region guidance without implying hard locking.


### F-D18-T06 - Minimal First-Time Guidance

Teach through actions:

get Ice -> return -> thaw -> reveal -> Equip -> Ride.
Avoid tutorial walls.


### F-D18-T06A - Shared Onboarding Ice Readability
Ensure onboarding clearly points a new player toward a suitable available shared Regular Ice without implying private ownership. If that Ice is claimed, retarget another shared Regular opportunity. If none is currently available, communicate the next shared Great Frost/world refresh.

### F-D18-T07 - First Great Frost Timing

Ensure the player encounters one sufficiently early to understand the world's rhythm.


### F-D18-T08 - Early Aspirational Content

Ensure first session exposes something extraordinary beyond current reach.


## 24. Day 19 - Mobile + Multiplayer QA

### F-D19-T01 - Mobile Grab Interaction


### F-D19-T02 - Mobile Deposit


### F-D19-T03 - Mobile Crack Inputs


### F-D19-T04 - Mobile Inventory / Equip / Ride / Sell


### F-D19-T05 - Mobile UI Legibility


### F-D19-T06 - Four-Player Ice Competition


### F-D19-T07 - Simultaneous Reveals


### F-D19-T08 - Simultaneous Great Frost


### F-D19-T09 - Shared Special Ice Competition


### F-D19-T10 - Base Isolation


### F-D19-T11 - Visitor WarmZone Test

Verify another player's Hearth does not refill/train the visitor.

### F-D19-T12 - Depleted-Field New Player Test

Verify a first-time player can start immediately even when shared nearby Ice is gone.

### F-D19-T13 - Special Ice Failure Test

Verify Special Ice returns/vanishes correctly based on OriginCycleIndex after freeze, reset, death, and disconnect.

## 25. Day 20 - Persistence + Balance + Exploit QA

### F-D20-T01 - Rejoin With Thawing Ice


### F-D20-T02 - Rejoin With Ready Ice


### F-D20-T03 - Offline Time Accuracy


### F-D20-T04 - Great Frost Bonus Does Not Apply Offline


### F-D20-T05 - Duplicate Reward Protection


### F-D20-T06 - Data Save/Load Stress


### F-D20-T07 - Inventory/Pen/Equip Invariants


### F-D20-T08 - Warmth Economy Balance

Check progression pacing.


### F-D20-T09 - Speed Balance

Check:
dramatic enough;
not uncontrollable;
retries meaningfully faster.


### F-D20-T10 - Thaw Timing Balance

Check:
anticipation;
productive waiting;

offline progress;
online Great Frost advantage.


### F-D20-T11 - Special Ice Cadence

Check:
sufficiently exciting;
not so frequent that it stops feeling special.


### F-D20-T12 - Server Remote Abuse

Attempt invalid:
Grab;
Crack;
Sell;
Equip;
Deposit;
Upgrade.


## 26. Day 21 - Final Regression + Launch Candidate

No new features.
Test complete journeys:
New Player

Spawn -> first Ice -> thaw -> reveal -> Equip -> progression.
Returning Player

Load -> find offline-thawed Ice -> reveal -> continue.
Midgame Player

Hearth progression -> Ancient/Black attempt.
Endgame Player

fast traversal -> Meteor -> Legendary aspiration.

Multiplayer Player

witness another player's advanced progression.
Great Frost

reset -> Surge -> Special Ice.

Onboarding Edge Case

join during depleted nearby field -> onboarding retargets available shared Regular Ice or communicates next shared refresh -> no private Ice spawned.

Special Failure Edge Case

claim Special Ice -> fail -> exact Special Ice drops shared with no reroll -> later eligible Frost may remove it if still unclaimed.

### F-D21-T01 - Final Save Test


### F-D21-T02 - Final Join/Leave Test


### F-D21-T03 - Final Mobile Test


### F-D21-T04 - Final Multiplayer Test


### F-D21-T05 - Final Hero-Moment Test

All five should be recognizably present.


### F-D21-T06 - Final USP Test

Ask:

Does five seconds of gameplay communicate dangerous Ice retrieval
rather than generic pet hatching?

### F-D21-T07 - Launch Candidate

Only once critical regressions are resolved.


## 27. Prototype P2 Tasks That May Move Into Week 2/3

If these were skipped in Week 1, that is acceptable.
They can be completed later if useful:
Archive;
Pen roaming;

follower/mount presentation polish;
enhanced Great Frost presentation;
Special Ice presentation;
reveal polish.
Skipping these does not mean prototype failure.


## 28. Scope Protection - What to Cut First

Current scope status:
- Survival Pressure S01-S06 is promoted launch scope.
- Following/Riding mounts for every Equipped creature are approved launch scope.
- The universal Mounted Strike is only the mounted presentation of the same survival attack.
- Unapproved materials/crafting/permanent creature death, autonomous pet combat, creature Damage stats, mount stamina/fuel, and creature-specific traversal abilities remain outside scope.

If production falls behind, cut or simplify in this order:
Cut First
complex Terrain;
environmental decoration;
unique art for all 10 Hearth levels;
Pen creature roaming;
custom follower/mount animation polish;
elaborate Ice destruction;
advanced aurora/particle layers;
fancy Archive presentation;
secondary UI animations.
Simplify Next
region environmental differences;
silhouette sophistication;
creature animations;
Great Frost effect complexity;
unique Ice visual states.
Protect
Do not casually cut:
Warmth;
Warmth training;
Hearth upgrades;
creature mounted Speed;
basic Following/Riding mount loop;
one-Ice retrieval;

carrying risk;
Pen thawing;
offline thawing;
CRACK -> CRACK -> SMASH;
Great Frost reset;
Thaw Surge;
Special Ice;
persistence;
multiplayer authority;
5 Ice progression structure;
16-creature launch target.
If a protected item becomes impossible, stop and make an explicit design decision rather than
silently removing it.


## 29. Creature Production Rule

Creature work is expected to consume a large portion of production time.
Therefore:

The environment must remain intentionally cheap.
A simple world containing excellent creatures is preferable to:

a beautiful world containing unfinished creatures.
For creature production, prioritize:
1. strong silhouette;
2. appealing proportions;
3. rarity/fantasy escalation;
4. clean technical setup;
5. simple reusable animation.

Do not spend time creating unnecessary creature-specific gameplay abilities.


## 30. World Production Rule

The map's job is to:

communicate distance;
frame desirable Ice;
support Warmth tension;
establish Great Frost fantasy;
make deeper territory feel increasingly extraordinary.
It is not required to be:
large;
maze-like;
highly open;
full of traversal mechanics.
Use simple authored paths and handcrafted spawn points.


## 31. USP Production Filter

Before accepting a new task during the three-week schedule, ask whether it strengthens:
1.

I saw something I desperately wanted.
2.

I barely managed to bring it home.
3.

I couldn't wait to discover what was inside.
If not, and it consumes meaningful production time:

defer it.

## 32. Hero-Moment Production Filter

When feedback says:

"The game isn't epic enough,"
do not immediately add another system.

Check:
First Great Frost;
Impossible Ice;
Barely-Made-It-Home;
Legendary Smash;
Endgame Speed.
Improve those first.


## 33. Week 1 Completion Definition - ACHIEVED

Week 1 succeeded.

Validated:

```text
retrieval -> anticipation -> reveal -> progression -> another retrieval
```

D7-R13: **PASS**.  
Survival Pressure: **PASS / full approved subset promoted**.

Do not reopen Week 1 as an excuse to add unrelated systems. New work belongs to production tasks.

## 34. Week 2 Completion Definition

Week 2 succeeds when the complete launch game exists mechanically.

Required:
- persistence + offline thawing;
- multiplayer + personal-base isolation;
- one shared authoritative Ice field;
- exact-Ice failure drop/rescue with no reroll;
- promoted Survival Pressure productionized for multiplayer;
- every Equipped creature supports Following/Riding and universal mounted attack;
- five-rarity support;
- current 11 species preserved and remaining five approved/implemented if the 16-species target is retained;
- 5 Ice types;
- 10 Hearth levels;
- permanent Warmth training;
- full copy-specific Speed/Income progression;
- Pen economy;
- Inventory;
- Sell;
- Archive;
- synchronized Great Frost;
- launch thaw acceleration;
- Special Ice using the universal shared lifecycle;
- Guarded Ice/region Sprite damage/breakable route integration.

No new major feature categories should enter after this gate.

## 35. Week 3 Completion Definition

Week 3 succeeds when:
players understand the game immediately;
all five Hero Moments read clearly;
the Norse-inspired Great Frost fantasy is recognizable;
16 creatures are visually appealing;
mobile works;
multiplayer works;
saves work;
offline thawing works;
no critical exploit destroys progression;
no major feature is still under construction.


## 36. Canonical Daily Summary

Day 1  
Warmth + Hearth + greybox.

Day 2  
Ice retrieval.

Day 3  
Thaw + Reveal.

Day 4  
Creature Speed + core-loop gate.

Day 5  
Great Frost + validated Survival Pressure + Hearth economy.

Day 6  
Per-copy ownership + Ice/creature jackpot Scale + all 11 existing meshes + copy-specific economy/Speed. **COMPLETE.**

Day 7  
Big-number Warmth + Hearth prominence/expansion + progression regions + Recommended Warmth + five functional Ice tiers. **COMPLETE.**

Day 8  
Persistence + offline thaw. **COMPLETE.**

Day 9  
Multiplayer + personal bases + one shared Ice field + exact-Ice rescue semantics. **IN PROGRESS.**

Day 10  
Production Great Frost + Special Ice + promoted Survival Pressure + Following/Riding mount integration.

Day 11  
Five-rarity production support + current 11-species preservation + remaining five species only after explicit approval.

Day 12  
Productionization/polish of Ancient / Black / Meteor and full five-tier pool integration.

Day 13  
10 Hearth levels + Recommended Warmth production balance.

Day 14  
Economy + Archive + feature lock.

Day 15  
World/fantasy presentation.

Day 16  
Creature production/finalization.

Day 17  
Five Hero Moments.

Day 18  
UI + shared-world onboarding.

Day 19  
Mobile + multiplayer QA.

Day 20  
Persistence + balance + exploit QA.

Day 21  
Regression + launch candidate.

## 37. Final Production Principle

Week 1 proved the game. Week 2 finishes the game. Week 3 makes people want the game.

Do not compensate for a weak core loop by adding more systems.

Canonical Survival Pressure remains only while it makes the Ice journey more memorable. If future testing shows enemy play becoming the destination instead of the obstacle, simplify the survival implementation rather than expanding combat progression.

The launch succeeds if the player remembers:

> "I saw something impossible in the Great Frost, risked going after it, everything went wrong, I barely got the Ice home, smashed it open, and what came out made me powerful enough to go even farther."

In multiplayer, an equally valid story is:

> "They froze with the huge Ice, I grabbed the exact one they dropped, and somehow I got it home."

Those experiences should drive every production decision.

