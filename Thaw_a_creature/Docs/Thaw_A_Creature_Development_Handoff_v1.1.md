# Thaw A Creature - Chat/Codex Development Handoff - v1.1

**Purpose:** Continue production from the exact post-Week-1 checkpoint while an engineer has completed Day 8 and is actively implementing Day 9.

**Project:** `Thaw A Creature` - Roblox prototype / launch project  
**Primary workflow:** ChatGPT designs/reviews one numbered task -> precise Codex/engineer implementation -> Studio runtime test -> cleanup -> commit -> next task.

---

# 1. Canonical Documents

Use these sources:

1. `01_Thaw_A_Creature_Concise_GDD_Canonical_v0.7.md`
2. `02_Thaw_A_Creature_Technical_Implementation_3Week_v0.7.md`
3. `05_Thaw_A_Creature_Implementation_Constants_Canonical_v1.1.md`
4. `04_Thaw_A_Creature_Development_Plan_Canonical_v1.1.md`
5. `03_Thaw_A_Creature_Bare_Minimum_Prototype_Technical_v1.0_FINAL.md`

Production authority order:
1. GDD - player-facing intent.
2. Launch Technical - production behavior/architecture.
3. Constants - exact first-pass numbers/content constraints.
4. Development Plan - task order/gates.
5. Prototype FINAL - historical Week-1 behavior/validation evidence.

Do not silently reconcile conflicts. A newer version of the same document supersedes the older version.

---

# 2. Product North Star

Core fantasy:

> Leave the Hearth, see mysterious shared Ice you desperately want, risk Warmth and authored survival pressure to retrieve it, bring it home, watch it thaw, CRACK -> CRACK -> SMASH, reveal a creature, Equip it, **ride it farther**, and repeat.

USP:

> **The collectible has a journey before it becomes a reward.**

Survival rule:

> **The enemies/obstacles exist to make the Ice journey memorable. Combat is never the destination.**

Multiplayer rule:

> **Every spawned Ice is one real shared world opportunity. If a carrier fails, that exact Ice remains in the world for someone else to rescue.**

---

# 3. Current Production Checkpoint

Week 1: **COMPLETE / PASS**  
D7-R13 progression validation: **PASS**  
Survival Pressure final decision: **PASS / FULL PROMOTION S01-S06**  
Day 8 persistence: **COMPLETE**  
Day 9 multiplayer + personal bases: **IN PROGRESS / engineer-owned**  
Mount launch decision: **APPROVED / schedule into Day 10 before feature lock**

Important concurrency rule:
- Studio/cloud state may be ahead of the local Git checkout while the engineer works.
- Before broad server/architecture changes, confirm branch/worktree/topology and avoid overwriting engineer-owned D8/D9 work.
- Do not ask cleanup tasks to touch `ServerBootstrap`, `BaseService`, `DataService`, `CreatureService`, `IceService`, or other engineer-owned systems unless the current task explicitly requires it.

---

# 4. Validated Week-1 Core

The following are runtime-validated:
- Warmth drain/refill/training/freeze;
- one-Ice retrieval and Pen deposit;
- multiple simultaneous thawing;
- CRACK -> CRACK -> SMASH;
- per-copy CreatureGUID ownership;
- one inherited WeightMultiplier through Ice -> creature;
- up to 5x visual Scale jackpots;
- copy-specific Income + Speed;
- 11 integrated creature species;
- five functional geographic Ice tiers;
- big-number regional Warmth progression;
- Hearth progression/prominence;
- Recommended Warmth signs;
- Great Frost prototype loop;
- low/critical Warmth presentation;
- Survival Pressure.

---

# 5. Current 11-Species Baseline

```text
Penguin      Common      RefKg 25     Visual 1.0000   Income 2    Speed 22
Rabbit       Common      RefKg 4      Visual 1.0000   Income 2    Speed 26
Seal         Common      RefKg 180    Visual 1.0000   Income 3    Speed 20
Wolf         Uncommon    RefKg 65     Visual 1.0000   Income 5    Speed 31
Bear         Uncommon    RefKg 500    Visual 1.0000   Income 7    Speed 26
Mammoth      Rare        RefKg 6000   Visual 1.4373   Income 15   Speed 30
Sleipnir     Rare        RefKg 900    Visual 1.4798   Income 10   Speed 39
Troll        Epic        RefKg 1200   Visual 1.4798   Income 24   Speed 35
IceSerpent   Epic        RefKg 3000   Visual 2.2605   Income 20   Speed 44
Hraesvlgr    Legendary   RefKg 5000   Visual 1.7404   Income 32   Speed 50
Nidhogg      Legendary   RefKg 8000   Visual 2.1523   Income 40   Speed 46
```

Copy formulas:

```text
Scale = cbrt(WeightMultiplier)
FinalIncome = max(1, round(BaseIncomePerSecond * Scale^2))
FinalWalkSpeed = BaseWalkSpeed * (1 + 0.15*(Scale - 1))
```

Frosted movement baseline: 16.

---

# 6. Current Five-Tier Ice Pools

Rarity order: `Common / Uncommon / Rare / Epic / Legendary`.

```text
Regular  74 / 23 / 3  / 0  / 0
  C Penguin,Rabbit,Seal
  U Wolf,Bear
  R Mammoth

Thick    30 / 35 / 25 / 10 / 0
  C Seal
  U Wolf,Bear
  R Mammoth,Sleipnir
  E Troll

Ancient  0 / 30 / 45 / 25 / 0
  U Bear
  R Mammoth,Sleipnir
  E Troll,IceSerpent

Black    0 / 10 / 35 / 40 / 15
  U Wolf
  R Mammoth,Sleipnir
  E Troll,IceSerpent
  L Hraesvlgr

Meteor   0 / 0 / 20 / 55 / 25
  R Mammoth,Sleipnir
  E Troll,IceSerpent
  L Hraesvlgr,Nidhogg
```

Nidhogg is Meteor-only in normal geographic Ice.
Hraesvlgr begins Black.
IceSerpent begins Ancient.

---

# 7. Big-Number Warmth / Regions

```text
Region             Recommended   Cold x   Sprite hit
Snowfield          100           1        10
Frozen Pass        1,000         10       100
Ancient Expanse    10,000        100      1,000
Black Ice Hollow   100,000       1,000    10,000
Meteor Reach       1,000,000     10,000   100,000
```

Warmth:

```text
Starting MaxWarmth = 100
Base drain = 4/sec
Carry multiplier = 2.00x
Hearth refill = 50% MaxWarmth/sec
Low = 35%
Critical = 15%
```

Hearth prototype levels:

```text
Lv1 Start      +10/sec
Lv2 $150       +50/sec
Lv3 $1,000     +250/sec
Lv4 $7,500     +1,250/sec
Lv5 $60,000    +6,250/sec
Lv6 $500,000   +31,250/sec
```

---

# 8. Survival Pressure - Launch Canonical

Full promoted package:
- one universal simple swing tool;
- stationary Frost Sprites;
- Guarded Ice across all five region tiers;
- Frost Sprite player hits reduce CurrentWarmth only;
- region-based Warmth damage: `10 / 100 / 1,000 / 10,000 / 100,000`;
- no Player HP;
- session-only Equipped-creature Vitality;
- Frosted/Downed at zero Vitality;
- no permanent creature loss;
- Frosted suppresses Equipped Speed;
- own-Hearth recovery;
- minimal readable survival feedback;
- breakable route obstacles using the same universal tool.

Still forbidden without later explicit approval:
- multiple weapons / weapon progression;
- enemy drops/currency/XP/levels;
- bosses;
- roaming/pathfinding/chase AI;
- autonomous pet combat AI / independent creature combat progression;
- material currencies;
- crafting/resource farming.

---

# 9. Mounted Equipped Creatures - Launch Canonical

Every creature is mountable. Every current creature mesh already has an authored Seat; use it as the default rider anchor.

Ownership/allocation:
- one `EquippedCreatureGUID`;
- Equip/Unequip remains own-base/Pen management;
- Equipped copy earns zero Pen income whether Following or Riding.

Runtime:
```text
None -> no Equipped creature
Following <-> Riding -> one Equipped creature
```

Following:
- preserve lightweight follower behavior;
- player WalkSpeed = 16;
- creature remains targetable by canonical survival rules.

Riding:
- use the same Equipped copy/Scale;
- movement = copy `FinalWalkSpeed`;
- Ride/Unride works during exploration, including while carrying Ice;
- Ride/Unride never drops Ice or changes Pen/Inventory ownership.

Persistence:
- do not persist `IsRiding` / MountState;
- join/respawn with an Equipped creature starts Following.

Frosted:
- if Riding and Vitality reaches 0, force Unride;
- block Ride while Frosted;
- own-Hearth recovery restores Vitality and makes Riding available again.

Mounted survival attack:
- one attack input;
- on foot = tool swing;
- Riding = Mounted Strike;
- same damage/effect, cooldown, target categories, server validation, and effective range;
- mounted hit validation originates near mount ground/front, not rider Seat height;
- no damage/range scaling by species, rarity, Scale, WeightMultiplier, or Speed;
- no trample/contact damage;
- custom bite/stomp/kick/swipe/headbutt animations are presentation only;
- giant mounts may use scale-aware camera/target indication for readability, never auto-attack.

Do not build a generic vehicle framework, mount stamina/fuel, mount combat stats, or creature-specific traversal powers.

---

# 10. Universal Shared-Ice Contract

Every spawned Ice is one shared authoritative server object for all players.
No private per-player Ice copies.

First valid server-side Grab wins.

Carrier failure includes:
- Freeze;
- character death;
- Reset Character/respawn;
- disconnect.

On failure:

```text
same IceInstanceID
same IceType
same CreatureID/Rarity
same WeightMultiplier/Scale
same Special metadata
-> drop at last valid safe carrier position
-> OwnerUserID = nil
-> State = Available
-> any player may rescue
```

No reroll.
No intentional DropIce request.
Rescue/relay is allowed.

Great Frost:
- carried Ice survives;
- if carrier fails during the already-running transition, the dropped Ice survives that current transition;
- a future Frost may clear it if still unclaimed;
- guardians/breakables refresh with the shared field.

Onboarding:
- no private onboarding Ice;
- guide/retarget toward shared Regular Ice;
- if none exists, communicate/wait for shared refresh.

---

# 11. Persistence Boundary

Persist:
- Cash;
- MaxWarmth;
- HearthLevel;
- CreatureCopies;
- PenSlots;
- EquippedCreatureGUID;
- DiscoveredCreatures;
- deposited ThawItems including WeightMultiplier.

Do NOT persist:
- CurrentWarmth;
- carried/dropped wilderness Ice;
- Sprite state;
- tool cooldown;
- breakable current state;
- Equipped-creature current Vitality;
- Frosted/Downed;
- MountState / IsRiding;
- mount Seat/presentation state;
- current encounter target.

Day 8 is complete. Audit this boundary only; do not rewrite stable persistence without a failing requirement.

---

# 12. Day 9 Immediate Requirements

Engineer is currently working Day 9.

D9 must ultimately prove:
- four-player base assignment/isolation;
- one shared Ice field;
- first-valid Grab contention;
- universal exact-Ice failure drop/rescue;
- no private onboarding Ice copies;
- own-Hearth-only Warmth training/refill and creature recovery;
- multiplayer-safe server validation;
- shared Frost Sprite world state;
- per-player Warmth/creature-damage application.

If the engineer's existing D9 implementation currently follows older private-onboarding or delete-on-failure behavior, update only those affected paths; do not restart the whole day.

---

# 13. Next Production Boundary

After Day 9 is stable:
1. integrate promoted Survival Pressure with production Great Frost/shared-world lifecycle;
2. lock regional Sprite Warmth damage;
3. verify Guarded Ice across Regular/Thick/Ancient/Black/Meteor;
4. verify breakable-route lifecycle;
5. productionize Following/Riding for every creature;
6. add Ride/Unride + mounted Speed gating;
7. add mechanically identical Mounted Strike + giant-mount readability;
8. run multiplayer survival/mount regression;
9. continue Day 10+ production schedule.

Do not broaden combat scope while doing this.

---

# 14. Workflow / Model Guidance

For new implementation/architecture/nontrivial bugs:
- **Model:** GPT-5.6 Sol
- **Intelligence:** Medium
- **Skill/reference:** `roblox-systems-scripter` when available/appropriate
- **Conversation:** new conversation for each numbered task

For cleanup after verified Studio runtime:
- **Model:** GPT-5.6 Terra
- **Intelligence:** Low
- **Skill:** none
- **Conversation:** same task conversation

Task loop:

```text
implementation
-> review
-> Studio runtime
-> cleanup
-> sanity
-> commit only owned files
-> clean/understood working tree
-> next numbered task
```

With concurrent engineering, never use broad staging (`git add -A`) without first checking ownership/status.

---

# 15. Non-Negotiable Product Rules

- The collectible has a journey before it becomes a reward.
- Carrying Ice increases Warmth drain; it does not reduce WalkSpeed.
- Failure costs time/opportunity, not permanent progression.
- Great Frost is opportunity/world refresh, not punishment.
- Reveal remains exactly `CRACK -> CRACK -> SMASH`.
- All spawned Ice is shared server state.
- Carrier failure preserves the exact Ice and enables rescue.
- Warmth is the player's survival resource; no Player HP.
- Every creature is mountable; mounted attack is the player's same survival attack, not pet combat progression.
- Survival exists to strengthen retrieval, not replace it.
- No permanent creature loss.
- Do not infer systems from genre convention.
