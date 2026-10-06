# THAW A CREATURE

## Development Plan - Prototype to 3-Week Public Launch - Canonical v0.9

**Production Window:** 3 weeks  
**Week 1:** Bare-Minimum Validation Prototype  
**Week 2:** Production Conversion + Full Launch Systems  
**Week 3:** Content Presentation + Hero Moments + QA + Launch Candidate  

### Revision notes

- Records `EXP-D5-GATE = PASS`; keeps the minimal approved survival layer active while forbidding unrelated combat expansion.
- Replaces the original Day-6 eight-blockout plan with the canonical jackpot/per-copy ownership revision and integration of all 11 already-completed creature meshes.
- Replaces Day-7 QA-only allocation with active big-number Warmth/Hearth/region/Ice expansion; task-level sanity testing remains mandatory.
- Moves per-copy data migration before persistence so Day 8 can save the correct CreatureGUID schema.
- Brings functional Ancient/Black (and Meteor if stable) progression forward rather than relying only on a fake aspirational Ice.

- Replaced Week-1 `P0-D5-T05` fixed `+30 sec` Thaw Surge behavior with **Great Frost Thaw Boost**: `10x` thaw speed only while Great Frost is active, including Ice deposited during the Frost; Day returns to `1x` and Frost-earned progress is preserved.
- Synchronized document authority and AI references to Bare-Minimum Prototype Technical Specification v0.9 and Implementation Constants v0.9.
- No Day-5 experiment scope change from Development Plan v0.6; this revision is a canonical-source synchronization pass.
- Added the Day-5 Survival Pressure Experiment after the core Great Frost P0 tasks and before the P1 economy tasks.
- Added a universal survival tool, stationary Frost Sprite, Guarded Ice encounters, temporary Equipped-creature Vitality/Frosted state, and minimal survival feedback as tightly scoped prototype experiments.
- Added an explicit Day-5 survival validation gate; breakable environment testing occurs only if the first survival gate passes.
- Kept material currencies, crafting, permanent creature death, Player HP, weapon progression, enemy drops, moving enemy AI, and pet combat AI out of the experiment.
- Added Day-7 survival regression/playtest checks and an End-of-Week-1 PASS/FAIL promotion decision so experimental combat does not become launch scope automatically.
- Removed the stale warning that Constants were not yet updated; all non-experimental canonical tasks use Constants v0.9.
- Added RegionConfig to Day 1 and synchronized no-drop/Freeze/Frost rules.
- Added Day-9 base topology, visitor Warmth rule, and private onboarding Ice.
- Expanded Day-10 wall-clock Frost and Special Ice lifecycle tasks.
- Moved creature production into a parallel post-prototype track; Day 16 is now finalization/integration.

---

## 1. Document Authority

When documents conflict, use this order:
1. Concise GDD v0.5 - player experience and design intent.
2. Bare-Minimum Prototype Technical Specification v0.9 - Week-1 prototype scope.
3. Launch Technical Implementation Specification v0.5 - final architecture and launch behavior.
4. Implementation Constants & Content Configuration v0.9 - exact numbers, content tables, and AI guardrails.
5. This Development Plan - implementation sequence.

The current launch-canonical model remains:

uncapped MaxWarmth + Hearth training rate + creature Speed + Pen thawing + Great Frost world resets.

Implementation must use the current Constants document immediately; no previous Warmth-Level constants are valid.

### Prototype Experimental Exception - Survival Pressure

Day 5 now contains an explicit user-approved prototype experiment identified by the `EXP` prefix.
Within those exact `EXP` tasks only, the prototype may temporarily test mechanics that are not yet launch-canonical:

- one universal swing tool;
- stationary Frost Sprites;
- Guarded Ice encounters;
- temporary Equipped-creature Vitality and a non-permanent Frosted state;
- minimal breakable environmental obstacles after the first experiment gate passes.

This is a test exception, not a silent launch-design revision.
The experiment does not automatically add combat, enemies, weapons, pet damage, gathering, or crafting to the public-launch scope.
If an `EXP` task conflicts with a launch exclusion, treat the `EXP` behavior as temporary prototype-only behavior until the End-of-Week-1 promotion decision.
No other genre convention may be inferred from the existence of the experiment.

## 2. AI / Developer Execution Rule

Every task should be implemented independently.
For each task:
1. Read the exact task.
2. Identify its priority and completion condition.
3. Consult the relevant Technical Specification.
4. Consult Implementation Constants v0.9 for exact values and content configuration.
5. Consult the GDD only when player-facing intent needs clarification.
6. Implement only the current task and strictly necessary dependencies.
7. Test it.
8. Fix failures.
9. Report:
files created/modified;
where they belong;
how to test;
expected successful result.
10. Stop.
Do not automatically proceed to the next task.
Do not introduce systems, currencies, libraries, progression tracks, remotes, or abstraction
layers that are not specified.

For `EXP` tasks:
- implement only the exact experiment described;
- keep all gameplay authority server-side;
- keep tunable experiment values in configuration rather than scattering them through code;
- do not build a generic combat, ability, item, crafting, or resource framework;
- do not add Player HP;
- do not add permanent creature loss;
- do not add weapon rarity, durability, upgrades, inventory, or multiple weapon classes;
- do not add enemy drops, combat XP, enemy levels, bosses, roaming/pathfinding AI, or pet combat AI;
- do not create Wood/Stone/material currencies or crafting during the first experiment;
- preserve the existing CRACK -> CRACK -> SMASH reveal flow unless a later approved task explicitly changes it.


## 3. Three-Week Production Rule

The build should remain playable every day.
The three major gates are:
Gate A - End of Day 4

The game must already be a game.

Retrieval -> Thaw -> Reveal -> Equip Speed -> Repeat must work.
Gate B - End of Week 1

Prototype validation.
Do not blindly continue if the retrieval fantasy is not compelling.
The Survival Pressure Experiment must also end with an explicit PASS, PARTIAL PASS, or FAIL decision.
A PASS/PARTIAL PASS requires canonical design and technical documents to be revised before productionizing the approved survival subset.
A FAIL means the experiment is removed/disabled rather than carried into Week 2 by inertia.
Gate C - End of Week 2

Feature lock.
All launch gameplay systems must exist.
Week 3 should not be used to invent major mechanics.


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

## 10. Day 6 - Jackpot / Per-Copy Metagame Foundation

Survival rule:
- `EXP-D5-GATE = PASS`;
- keep S01-S05 active;
- do not add new enemy types, weapon progression, resource currencies, crafting, pet attacks, or combat XP during this revision.

### D6-R00 - Audit the 11 Existing Creature Assets

**COMPLETE**

Read-only/content audit first.
Enumerate the exact 11 existing creature model IDs/names from live Studio
`Workspace.Creatures`.
Report current config coverage, model Root/PrimaryPart health, and scale safety.
Do not invent missing creature names from old planning docs.

**LIVE AUDIT COMPLETE**

- 11 direct-child Studio Models found: `BEAR`, `HRAESVLGR`, `ICESERPENT`,
  `MAMMOTH`, `NIDHOGG`, `PENGUIN`, `RABBIT`, `SEAL`, `SLEIPNIR`, `TROLL`, and
  `WOLF`.
- All 11 are now configured after D6-R05; Sleipnir, IceSerpent, and Hraesvlgr
  were additionally verified against their live Studio models.
- The models remain Studio-authored under `Workspace.Creatures`; model-contract
  normalization is not part of D6-R00.
- No creature stats, rarities, or Ice pools were invented during the audit.

Technical debt: the production creature asset source should eventually be
reproducible through source control/build tooling before launch and persistence
hardening. This does not block the per-copy ownership migration.

### D6-R01 - Per-Copy Creature Ownership Migration

**COMPLETE**

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

**COMPLETE**

At Ice spawn, server rolls exactly one WeightMultiplier using Constants v0.9.
Derive:

```text
Scale = cbrt(WeightMultiplier)
```

Maximum supported visual Scale = `5.0x`.
No rerolls during carry/deposit/reveal.

### D6-R03 - Ice Visual Scaling Through Full Journey

**COMPLETE**

Apply exact derived Scale to:
- wilderness Ice;
- carried Ice;
- deposited/thawing Ice;
- Ready/reveal Ice.

Extreme Ice must remain non-blocking to player traversal physics.

### D6-R04 - Creature Size Inheritance

**COMPLETE**

Reveal creates one CreatureGUID using the Ice's exact WeightMultiplier.
The resulting creature uses the same derived Scale relative to that species' base size.

### D6-R05 - Configure All 11 Existing Creatures

**COMPLETE**

Approved prototype allocation: Common — Penguin, Rabbit, Seal; Uncommon —
Wolf, Bear; Rare — Mammoth, Sleipnir; Epic — Troll, IceSerpent; Legendary —
Hraesvlgr, Nidhogg. Epic and Legendary are active Week-1 prototype content.

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

Current prototype pools: Regular `74/23/3/0/0` — Penguin/Rabbit/Seal,
Wolf/Bear, Mammoth; Thick `30/32/24/11/3` — Seal, Wolf/Bear,
Mammoth/Sleipnir, Troll/IceSerpent, Hraesvlgr/Nidhogg. Selection remains
rarity-first, then uniform among eligible species. Runtime validation reached
6/6 Regular (`74.11/22.90/3.00/0.00/0.00`) and 9/9 Thick
(`29.63/32.18/24.16/11.02/3.01`) eligible species in 100,000-roll smoke tests.
Sleipnir, IceSerpent, and Hraesvlgr completed live-model verification through
the Ice-to-Equip path.

### D6-R06 - Size-Based Income + Speed

**NEXT IMPLEMENTATION TASK**

These formulas are not active until this task is implemented and verified.

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


## 11. Day 7 - Big-Number Progression + World Expansion

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

### D7-R11 - Regional Redistribution of the Active 11-Creature Roster

Redistribute/expand the already-active 11-creature roster across future Ancient,
Black, and Meteor Ice according to explicit approved regional content mapping.
Do not fabricate assignments or final future-Ice rarity weights.

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

## 12. END-OF-WEEK-1 PROTOTYPE GATE

Do not automatically continue into launch production.
Proceed only if there is credible evidence that:
players want visible Ice;
retrieval itself creates tension;
near-failure produces retry desire;
thawing creates anticipation;
players find productive activity during thawing;
Warmth training feels valuable;
higher rarity feels obviously faster;
Great Frost refreshes interest;
reveal creates another-Ice desire;
players see something they want to reach later.
Most important qualitative test:

If players describe the game as "I barely got this crazy Ice home and then
it became a Mammoth," we have something.
If they describe it as:

"I hatch pets,"

the USP requires iteration before production expansion.


### 12A. Survival Pressure Experiment Promotion Decision

The Survival Pressure Experiment must now receive an explicit final prototype decision.

The original prototype can succeed even if the survival experiment FAILS.
A failed experiment is useful evidence if the canonical retrieval loop is compelling.

PASS when there is credible evidence that the approved survival subset:
- makes desirable Ice feel more dangerous and worth attempting;
- creates stronger Barely-Made-It-Home stories;
- keeps Ice/retrieval as the primary motivation;
- uses Warmth coherently as the player's survival resource;
- makes temporary creature danger emotionally meaningful without discouraging players from using valuable creatures;
- provides useful physical agency through the universal tool without becoming a separate grind;
- remains simple enough that the added production burden is justified by the improvement in player experience.

PARTIAL PASS when only a subset clearly helps.
Examples:
- Guarded Ice works, but creature Vitality distracts;
- the tool + breakables work, but hostile targeting does not;
- creature danger works, but breakables add nothing.

For PARTIAL PASS:
explicitly list the promoted subset and remove the rest.
Do not silently keep all experimental code.

FAIL when:
- enemies become the primary goal;
- players ask to farm enemies rather than retrieve Ice;
- survival mechanics make the game feel generic rather than more specifically Thaw A Creature;
- creature danger makes players avoid using their best creatures;
- the extra systems create complexity without materially improving retrieval stories;
- the core loop is less readable or less replayable.

If PASS/PARTIAL PASS:
1. record exactly which experimental mechanics are approved for promotion;
2. update the Concise GDD before treating them as launch design;
3. update the Bare-Minimum Prototype Technical Specification to record the validated behavior;
4. update the Launch Technical Implementation Specification before production architecture is built;
5. update Implementation Constants with exact production/prototype tuning values and AI guardrails;
6. revise this Development Plan again to schedule the promoted subset into Week 2 before feature lock;
7. only then productionize the promoted survival systems.

Passing the experiment does NOT automatically approve:
- material currencies;
- crafting;
- permanent creature death;
- Player HP;
- multiple weapons;
- weapon progression;
- enemy drops;
- combat XP;
- bosses;
- roaming enemy AI;
- pet combat AI.

Those remain separate design decisions requiring their own evidence.

If FAIL:
remove/disable experiment-specific gameplay and clean unused experiment-only code/configuration before Week 2.
Continue with the existing launch plan.


### 12B. Parallel Creature Production Track - Begins After Week-1 Gate

Creature art is the largest content bottleneck and must not be deferred until Day 16.

Once the Week-1 prototype passes the validation gate, final creature production begins in parallel with Week-2 engineering.

Rules:
preserve the Development Plan's coding priorities;
use standardized Root/scale/orientation from the blockout asset contract;
target roughly 2 production-ready creatures per available art day when practical;
prioritize Common/Uncommon readability first, then Rare/Legendary spectacle;
reuse simple animation/rig solutions;
do not add creature-specific gameplay abilities.

Milestone intent:
Days 8-10: begin final Common/Uncommon replacements;
Days 11-14: continue Rare/Legendary production while full configs are added;
End of Day 14: as many final creatures as possible should already be integrated; remaining blockouts must still be mechanically valid;
Day 16: finalization/integration/QA, not the first day production begins.

If creature production slips, simplify environment and animation before cutting the 16-creature launch target.

## WEEK 2 - PRODUCTION CONVERSION + FULL LAUNCH SYSTEMS

Conditional survival rule:
- this v0.6 plan does not assume survival/combat is launch scope;
- if the Week-1 survival decision is PASS/PARTIAL PASS, revise the canonical GDD/technical documents/constants and issue a new Development Plan revision before implementing production survival tasks;
- if the decision is FAIL, Week 2 proceeds exactly with the canonical schedule below.

Goal: Transform the validated prototype into the complete mechanical launch game.
By the end of Week 2:

all launch features must exist.
Art may still be unfinished.


## 13. Day 8 - Persistence Foundation

### L-D8-T01 - DataService

Create the only service allowed to communicate directly with persistent storage.
Responsibilities:
load;
defaults;
validation;
migration;
retries;
autosave;
disconnect save;
shutdown save;
session safety.


### L-D8-T02 - Persistent Schema

Implement:
```text
              1   DataVersion
              2   Cash
              3
              4   MaxWarmth
              5   HearthLevel
              6
              7   OwnedCreatures
              8   PenSlots
              9   EquippedCreature
             10   DiscoveredCreatures
             11
             12   ThawingIce
```


Optional pity state only if retained later.


### L-D8-T03 - Persistent Thaw Format

Use:
```text
              1   ThawID
              2   IceType
              3   IsSpecial
              4
              5   CreatureID
              6   Rarity
              7
              8   DepositedAtUnix
              9   BaseDurationSeconds
             10   BonusProgressSeconds
```


### L-D8-T04 - Load Failure Protection

Never overwrite legitimate data with an empty/default profile after a failed load.


### L-D8-T05 - Join Restore

On join:
load data;
restore creatures;
restore Pen;
restore Equipped;
calculate Speed;
calculate MaxWarmth;
CurrentWarmth = MaxWarmth;
restore ThawItems.


### L-D8-T06 - Offline Thawing

Calculate:

current Unix time - DepositedAtUnix + bonuses.
If complete:

return as READY TO CRACK.

Do not auto-grant creature.


### L-D8-T07 - Save / Rejoin Test

Repeatedly verify:
Cash;
Warmth;
Hearth;
creature counts;
Equipped;
Pen;
thawing Ice.


## 14. Day 9 - Multiplayer + Personal Bases

### L-D9-T01 - Raise Server Target

Initial target:
4 players/server

### L-D9-T02 - BaseService

Assign one personal base per player.
Use the canonical topology:
up to four personal plots side-by-side along one shared home-camp edge;
all plots face the same primary wilderness direction.

### L-D9-T03 - Base Ownership

Only owner can:
refill Current Warmth in that WarmZone;
train there;
upgrade Hearth;
deposit Ice;
manage Pen;
Equip;
Sell;
reveal Ice.
Another player's Hearth/WarmZone does not refill or train visitors.

### L-D9-T04 - Shared Wilderness

All players use the same normal wilderness Ice.

### L-D9-T05 - Shared Ice Contention

First valid server-side Grab wins.

### L-D9-T06 - Disconnect Cleanup

If player disconnects carrying normal Ice:
retrieval fails.
If carrying Special Ice:
use the canonical Special-Ice return/expiry rule.
Release/remove ownership safely.

### L-D9-T07 - Multiplayer Remote Validation

Audit all remotes for:
proximity;
ownership;
rate limiting;
state transitions.

### L-D9-T08 - Base Isolation Test

Player A must never manipulate:
Player B's Hearth;
Pen;
ThawItem;
creature;
reveal.
Player A must also not gain Warmth refill/training from Player B's WarmZone.

### L-D9-T09 - Private First-Time Onboarding Ice

Add one player-private Regular onboarding Ice at each base's authored OnboardingIceSpawnPoint.
Eligibility:
no discovered creatures;
no ThawingIce;
no carried Ice.
Rules:
normal Regular random reward;
private/not contestable;
unaffected by Great Frost;
may reappear after failure while eligibility remains true;
stops after successful deposit/reveal path begins.

### L-D9-T10 - Onboarding Depleted-Field Test

Join a server after nearby shared Regular Ice has been taken.
A brand-new player must still be able to begin the core loop immediately through their private onboarding Ice.

## 15. Day 10 - Production World Cycle

### L-D10-T01 - Wall-Clock Great Frost

Use canonical shared timing:
CycleEpochUnix = 0;
CycleIndex = floor((os.time() - Epoch) / CycleLength);
final GreatFrostDuration seconds of each cycle are Great Frost.
Expose:
CycleIndex;
CurrentPhase;
NextTransitionUnix;
TimeRemaining.

### L-D10-T02 - Server Boot / Synchronization

Servers should share a consistent cycle rhythm.
If booting during Day:
populate current normal field immediately.
If booting during Great Frost:
wait for next Day to populate.
Do not retroactively grant Thaw Surge or Special Ice on a mid-Frost boot.
Track LastProcessedFrostCycle to prevent duplicate processing.

### L-D10-T03 - Online Thaw Surge

Only active players present at an actual observed Day -> Great Frost transition receive the bonus.
Offline thawing continues normally without Surge.

### L-D10-T04 - Production Ice Field Reset

Great Frost becomes the canonical wilderness refresh mechanism.
During the 15-second Frost transition:
disable new GrabIce confirmations;
remove available/unclaimed shared Ice;
preserve carried Ice;
preserve Pen/Ready Ice;
repopulate the new field;
re-enable GrabIce when Day resumes.
Private onboarding Ice is excluded from this shared reset.

### L-D10-T05 - Special-Ice Cadence

Implement:
every configured X observed Great Frost cycles.
Exact X belongs in Constants.

### L-D10-T06 - Special Ice Roll Profile

Special Ice:
visibly special;
guarantees high-value opportunity;
uses increased rarity;
keeps exact creature hidden.
Do not hardcode Legendary unless Constants specify it.

### L-D10-T07 - Special Ice Lifecycle

Store OriginCycleIndex + OriginSpawnPointID.
If unclaimed:
remove at next Great Frost like other shared field Ice.
If carrier fails/disconnects before deposit:
return to origin only while the originating opportunity is still current;
otherwise remove it.
Successful deposit consumes it normally.
Carried Special Ice still survives Great Frost like any carried Ice.

### L-D10-T08 - Server-Wide Special Ice Event

Send appropriate event for presentation.
Do not expose exact reward.

## 16. Day 11 - 16 Creatures + 4 Rarities

### L-D11-T01 - Add Legendary Rarity

Add:

**Legendary**
with Speed/value/reveal configuration.


### L-D11-T02 - Full 16-Creature Config

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

### L-D11-T03 - Add Remaining 5 Launch Creatures

Eleven creature meshes already exist before this phase. Add/finalize only the remaining five needed to reach the current 16-species launch target. Production-quality polish can continue into Week 3, but gameplay configs must exist now.

L-D11-T03A - Canonical Silhouette Profiles
Assign all 16 creatures to the reusable SilhouetteProfile IDs defined in Constants.
Do not create one guaranteed exact silhouette per species unless the profile mapping explicitly allows it.


### L-D11-T04 - Full Ownership Support

Verify all 16:
Inventory;
Pen;
Equip;
Sell;
Archive.


### L-D11-T05 - Full Speed Progression

Verify:

species base traversal + inherited size Scale must create clearly different individual copy speeds across the full rarity/content progression. Legendary content should still feel aspirational, but rarity alone no longer hardcodes final WalkSpeed.


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


### F-D16-T18 - Pen / Follower Compatibility

Verify every final creature works in both contexts.


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

get Ice -> return -> thaw -> reveal -> Equip.
Avoid tutorial walls.


F-D18-T06A - First-Time Onboarding Ice Readability
Ensure the private onboarding Regular Ice is immediately visible from the new player's base and reads as the obvious first action without text-heavy tutorial UI.

### F-D18-T07 - First Great Frost Timing

Ensure the player encounters one sufficiently early to understand the world's rhythm.


### F-D18-T08 - Early Aspirational Content

Ensure first session exposes something extraordinary beyond current reach.


## 24. Day 19 - Mobile + Multiplayer QA

### F-D19-T01 - Mobile Grab Interaction


### F-D19-T02 - Mobile Deposit


### F-D19-T03 - Mobile Crack Inputs


### F-D19-T04 - Mobile Inventory / Equip / Sell


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

join depleted server -> private Regular Ice -> deposit -> no duplicate onboarding Ice.

Special Failure Edge Case

claim Special Ice -> fail before/after superseding Frost -> correct return/removal.

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

follower polish;
enhanced Great Frost presentation;
Special Ice presentation;
reveal polish.
Skipping these does not mean prototype failure.


## 28. Scope Protection - What to Cut First

Survival experiment status:
The Day-5 `EXP` systems are not protected launch scope in this v0.6 plan.
They become production obligations only if the End-of-Week-1 promotion decision approves a specific subset and the canonical documents are revised.
Unapproved materials/crafting/permanent creature death remain outside scope regardless of whether another survival element passes.

If production falls behind, cut or simplify in this order:
Cut First
complex Terrain;
environmental decoration;
unique art for all 10 Hearth levels;
Pen creature roaming;
follower animation polish;
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
creature Speed;
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


## 33. Week 1 Completion Definition

Week 1 succeeds when the prototype proves:

retrieval -> anticipation -> reveal -> progression -> another retrieval
even if presentation is ugly.

The Survival Pressure Experiment must also be concluded with documented evidence and an explicit PASS, PARTIAL PASS, or FAIL.
The experiment itself does not need to pass for Week 1 to succeed.
If it passes, the approved subset must clearly make the retrieval story stronger rather than replacing it.


## 34. Week 2 Completion Definition

Week 2 succeeds when:

the complete launch game exists mechanically.
Required:
persistence;
offline thawing;
multiplayer;
16 creature species target;
per-copy CreatureGUID ownership with inherited Scale;
configured rarity/content tiers;
5 Ice types;
10 Hearth levels;
permanent Warmth training;
full Speed progression;
Pen economy;
Inventory;
Sell;
Archive;

synchronized Great Frost;
Thaw Surge;
Special Ice.

If the survival experiment was promoted after Week 1:
additional Week-2 production requirements must come from the subsequent revised canonical plan.
Do not infer them from prototype code alone.


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
Great Frost + survival-pressure experiment + Hearth economy.
Day 6
Per-copy ownership + Ice/creature jackpot Scale + integrate all 11 existing meshes + copy-specific economy/Speed.

Day 7
Big-number Warmth + Hearth prominence/expansion + progression regions + Recommended Warmth + additional functional Ice types.
Day 8
Persistence + offline thaw.
Day 9
Multiplayer + bases.
Day 10
Production Great Frost + Special Ice.
Day 11
16 creatures + Legendary.
Day 12
Ancient / Black / Meteor.
Day 13
10 Hearth levels + Recommended Warmth.
Day 14
Economy + Archive + feature lock.
Day 15
World/fantasy presentation.
Day 16
Creature production.
Day 17
Five Hero Moments.
Day 18
UI + onboarding.
Day 19
Mobile + multiplayer QA.
Day 20
Persistence + balance + exploit QA.
Day 21 - Regression + launch candidate.


## 37. Final Production Principle

Week 1 proves the game. Week 2 finishes the game. Week 3 makes people
want the game.
The project should never reach Day 18 while a fundamental loop still does not work.
And the most important protection throughout all three weeks remains:

Do not compensate for a weak core loop by adding more systems.
Experimental survival pressure survives only if it makes the Ice journey more memorable; cut it if combat becomes the destination instead of the obstacle.
The launch succeeds if the player remembers:

"I saw something impossible in the Great Frost, risked going after it, barely
got it home, smashed it open, and what came out made me powerful
enough to go even farther."
That experience should drive every production decision.
