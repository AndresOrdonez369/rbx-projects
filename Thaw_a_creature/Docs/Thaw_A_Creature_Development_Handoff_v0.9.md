# Thaw A Creature - Chat/Codex Development Handoff - v0.9

**Purpose:** Continue development from the exact post-Day-5 checkpoint after the Jackpot Scale / Big-Number Progression design revision.

**Project:** `Thaw A Creature` - Roblox prototype / launch project  
**Primary workflow:** ChatGPT designs/reviews one task -> precise Codex prompt -> Codex edits repo -> Studio runtime test through Rojo -> cleanup -> commit -> next task.

---

# 1. Canonical Documents

Use these updated sources:

1. `01_Thaw_A_Creature_Concise_GDD_Canonical_v0.5.md`
2. `02_Thaw_A_Creature_Technical_Implementation_3Week_v0.5.md`
3. `03_Thaw_A_Creature_Bare_Minimum_Prototype_Technical_v0.9.md`
4. `04_Thaw_A_Creature_Development_Plan_Canonical_v0.9.md`
5. `05_Thaw_A_Creature_Implementation_Constants_Canonical_v0.9.md`

Authority order:
1. GDD - player-facing intent.
2. Prototype Technical Spec - current prototype behavior.
3. Launch Technical Spec - production architecture.
4. Constants - exact first-pass numbers/content constraints.
5. Development Plan - task order/gates.

Do not silently reconcile conflicts. A newer version of the same document supersedes the older version.

---

# 2. Product North Star

Core fantasy:

> Leave the Hearth, see mysterious Ice you desperately want, risk Warmth to retrieve it, bring it home, watch it thaw, CRACK -> CRACK -> SMASH, reveal a creature that changes progression, then go farther.

USP:

> **The collectible has a journey before it becomes a reward.**

The v0.9 revision strengthens this with a pre-reveal jackpot signal:

> **Ice can spawn at absurd scale. The one visible size roll survives the entire journey and becomes the exact size lineage of the revealed creature copy.**

Desired story:

> "I saw this impossible giant Ice, barely got it home, and it became a massive creature with insane value."

---

# 3. Current Checkpoint - D6-R05 Complete

Day 5 implementation is complete and runtime-verified. D6-R01 through D6-R05
are also complete and runtime-verified:

- WorldCycleService / Great Frost countdown
- Frost presentation
- Great Frost Ice field reset
- active Great Frost `10x` thaw boost
- Universal Survival Tool
- stationary Frost Sprite
- Guarded Ice encounters
- Equipped Creature Vitality / Frosted state
- minimal survival feedback
- Frost Sprite projectile collision fidelity fix
- Cash state + HUD
- 1-second aggregate Pen income
- Hearth upgrades

Survival Pressure Gate result:

**PASS**

Evidence: guarded Thick-Ice retrieval created a near-failure return with only 3 Warmth remaining; the player fought/rushed Sprites because of the Ice opportunity and cared most about the carried Ice + Warmth, not enemy farming.

Keep S01-S05 enabled. Do not expand enemy/combat scope automatically.

- CreatureGUID ownership is active.
- Authoritative Ice WeightMultiplier and Ice visual Scale lineage are active.
- Creature copies inherit the exact Ice Scale.
- The full 11-species prototype roster is configured; Epic and Legendary are active.
- Regular/Thick prototype pools are updated, and Sleipnir, IceSerpent, and
  Hraesvlgr are verified against live Studio models.

---

# 4. Current Economy State Before D6-R06

Current implementation before D6-R06 stat activation:

- Cash server-authoritative.
- Pen income currently ticks every 1 second.
- Existing rarity economy values were configured as:
  - Common 2/sec
  - Uncommon 5/sec
  - Rare 12/sec
  - Epic 20/sec
  - Legendary 28/sec
- Hearth currently has the initial small prototype levels from T08.

The D6-R06 target replaces the final source of Pen income and Equipped Speed
only when that task is implemented and verified:

- actual copy Pen income becomes species BaseIncome * size multiplier;
- actual Equipped Speed becomes species BaseSpeed * size multiplier;
- Hearth/Warmth are rebalanced into much larger numbers on Day 7.

Do not delete stable Day-5 behavior until its replacement task is implemented and verified.

---

# 5. New Canonical Jackpot Scale System

Every wilderness Ice gets exactly one server-authoritative `WeightMultiplier`.

Formula:

```text
ActualWeight = ReferenceWeight * WeightMultiplier
Scale = cbrt(ActualWeight / ReferenceWeight)
Scale = cbrt(WeightMultiplier)
```

Supported visual Scale:

```text
0.75x minimum
5.00x maximum
```

First-pass size bands:

```text
Small      8.0%   0.75-0.95x
Normal    72.0%   0.95-1.25x
Large     15.0%   1.25-1.75x
Huge       4.0%   1.75-2.50x
Colossal   0.9%   2.50-3.50x
Absurd     0.1%   3.50-5.00x
```

Within a band, bias toward the lower bound (`Random()^2` interpolation in WeightMultiplier space) so near-5x results are much rarer than merely entering the Absurd band.

The exact WeightMultiplier is inherited unchanged:

```text
wilderness Ice
-> carried Ice
-> deposited/thawing Ice
-> Ready Ice
-> reveal
-> creature copy
```

No second size roll at reveal.
A giant Ice must produce a giant creature copy relative to that species' base size.

Extreme size is intentionally absurd/social. A 3.5-5x creature may cover much of the screen or visually spill across Pen spaces. Keep gameplay allocation clean and visuals non-blocking.

---

# 6. Per-Copy Creature Architecture

The old species-count model is obsolete.

Target ownership:

```text
CreatureCopies = {
    [CreatureGUID] = {
        CreatureID,
        WeightMultiplier,
    }
}

PenSlots[1..4] = CreatureGUID or nil
EquippedCreatureGUID = CreatureGUID or nil
DiscoveredCreatures[CreatureID] = true
```

Derived:

```text
Scale = cbrt(WeightMultiplier)
FinalIncome
FinalSpeed
```

Inventory:

```text
all CreatureGUIDs
- Pen GUIDs
- Equipped GUID
```

Species discovery remains species-based.

Only the inherited size roll is approved randomized copy variation. Do not add random Damage/Defense/levels/affixes.

---

# 7. Size-Derived Stats

Every current prototype species now defines:

```text
ReferenceWeight
BaseVisualScale
BaseIncomePerSecond
BaseWalkSpeed
```

Approved D6-R06 target formulas (not active yet):

```text
IncomeMultiplier = Scale ^ 2
FinalIncome = max(1, round(BaseIncomePerSecond * IncomeMultiplier))

SpeedMultiplier = 1 + 0.15 * (Scale - 1)
FinalWalkSpeed = BaseWalkSpeed * SpeedMultiplier
```

At 5x visual Scale:
- Income ~= 25x species base.
- Speed ~= 1.60x species base.

Income is intentionally much more explosive than Speed. Until D6-R06, current
runtime Pen Income and Equipped WalkSpeed remain rarity-driven.

Creature presentation should expose:

```text
SPEED <value>
PEN $<value>/s
```

An Equipped copy displays its intrinsic Pen stat but earns zero while Equipped.

---

# 8. Creature Asset Status

The user reports **11 creature meshes are already complete**.

Do NOT recreate the old eight blockouts.

The completed D6-R00 audit identified the 11 live models, and D6-R05 recorded
the approved roster/baselines. Do not infer future changes from the separate
16-species launch roster.

---

# 9. Big-Number Warmth Direction

Warmth is now intentionally a satisfying large-number progression system.

First-pass revised constants:

```text
Starting MaxWarmth = 100
Base Warmth Drain = 4/sec
Carry Multiplier = 2.00x
Hearth refill = 50% of MaxWarmth/sec
Low = 35% MaxWarmth
Critical = 15% MaxWarmth
```

Regions:

```text
Snowfield        Regular   Recommended 100       Cold 1x
Frozen Pass      Thick     Recommended 1,000     Cold 10x
Ancient Expanse  Ancient   Recommended 10,000    Cold 100x
Black Ice Hollow Black     Recommended 100,000   Cold 1,000x
Meteor Reach     Meteor    Recommended 1,000,000 Cold 10,000x
```

Warmth drain:

```text
BaseDrain * RegionColdMultiplier * CarryMultiplier(if carrying)
```

Recommended Warmth is guidance only. Never gate entry.

---

# 10. Revised Hearth Direction

The Hearth keeps exactly the same progression function but must become visually central.

First-pass Day-7 expansion:

```text
Lv1  Start      +10 Warmth/sec
Lv2  $150       +50/sec
Lv3  $1,000     +250/sec
Lv4  $7,500     +1,250/sec
Lv5  $60,000    +6,250/sec
Lv6  $500,000   +31,250/sec
```

Presentation target:
- obvious fire/light/smoke/embers;
- visible WarmZone;
- `HEARTH LV. X`;
- `TRAINING +X WARMTH/s`;
- next cost / MAX.

No direct fixed MaxWarmth purchase. No cap.

---

# 11. Revised Day 6 Task Order

Use a NEW Codex conversation for each numbered task unless fixing/cleaning that exact task.

1. `D6-R00 - Audit the 11 Existing Creature Assets` - COMPLETE
2. `D6-R01 - Per-Copy Creature Ownership Migration` - COMPLETE
3. `D6-R02 - Authoritative Ice Weight + Scale Roll` - COMPLETE
4. `D6-R03 - Ice Visual Scaling Through Full Journey` - COMPLETE
5. `D6-R04 - Creature Size Inheritance` - COMPLETE
6. `D6-R05 - Configure All 11 Existing Creatures` - COMPLETE
7. `D6-R06 - Size-Based Income + Speed` - NEXT
8. `D6-R07 - GUID Pen / Equip / Inventory`
9. `D6-R08 - Copy-Specific Pen Income`
10. `D6-R09 - Creature Stat Presentation`
11. `D6-R10 - Jackpot Validation Gate`

Goal:

```text
giant Ice
-> risky retrieval
-> same-scale giant creature
-> unusually strong Income
-> noticeably better Speed
```

### D6-R05 Roster Result

**D6-R01 through D6-R05 = COMPLETE**

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

Current prototype pools are Regular `74/23/3/0/0` (6 eligible species) and
Thick `30/32/24/11/3` (9 eligible species). All 11 are obtainable across the
two pools; selection is rarity-first, then uniform among eligible species.

Runtime evidence: the 100,000-roll Regular smoke test returned
`74.11/22.90/3.00/0.00/0.00`, reaching 6/6 species; Thick returned
`29.63/32.18/24.16/11.02/3.01`, reaching 9/9. Sleipnir, IceSerpent, and
Hraesvlgr completed the live Ice -> carry -> deposit -> thaw -> reveal ->
CreatureGUID -> Pen -> Equip path.

All eleven live models lack a PrimaryPart and direct Root, and are simple
two-MeshPart models. Several have authored `GetScale()` values above 1.0.
Extreme 5x jackpot presentation remains intentional. BaseVisualScale is
metadata/reference; D6-R04 preserves authored model scale and applies copy
SizeScale relative to it, without double-applying BaseVisualScale.

---

# 12. Revised Day 7 Task Order

Day 7 is an implementation day, not QA-only.

1. `D7-R01 - Big-Number Warmth Rebalance`
2. `D7-R02 - Scalable Hearth Refill`
3. `D7-R03 - Hearth Progression Expansion`
4. `D7-R04 - Hearth Prominence Pass`
5. `D7-R05 - Expanded Progression Regions`
6. `D7-R06 - Recommended Warmth Signs`
7. `D7-R07 - Regional Cold Severity`
8. `D7-R08 - Ancient Ice`
9. `D7-R09 - Black Ice`
10. `D7-R10 - Meteor Ice` if stable/time permits
11. `D7-R11 - Regional Redistribution of the Active 11-Creature Roster`
12. `D7-R12 - Low-Warmth Feedback`
13. `D7-R13 - Progression Validation Gate`

Continue sanity testing inside every implementation task.

---

# 13. Workflow / Codex Settings

New implementation / architecture / nontrivial bug:

**Model:** GPT-5.6 Sol  
**Intelligence:** Medium  
**Skill:** `Reference/Skills/roblox-systems-scripter.md`  
**Codex conversation:** NEW for each numbered task

Cleanup after verified runtime:

**Model:** GPT-5.6 Terra  
**Intelligence:** Low  
**Skill:** none  
**Codex conversation:** SAME task conversation

Order:

1. ChatGPT gives one task prompt.
2. Codex implements; no commit.
3. Review diff/report.
4. Studio runtime test.
5. Fix/diagnose in same task conversation if needed.
6. Remove temporary diagnostics.
7. Sanity test.
8. Commit.
9. Confirm clean tree.
10. Next numbered task in NEW conversation.

Never trust Command Bar `require()` as proof of live state; test through actual gameplay/remotes/server lifecycle.

---

# 14. Immediate Next Step

> **D6-R06 - Size-Based Income + Speed**

D6-R05 is complete. Activate the approved species/size-derived Income and
Speed formulas without changing the existing roster, pools, GUID ownership, or
size lineage.
