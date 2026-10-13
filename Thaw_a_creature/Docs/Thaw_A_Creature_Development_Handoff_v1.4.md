# THAW A CREATURE

## Development Handoff - v1.4

**Current checkpoint:** Systems Engineer is completing Day 14 Economy + Collection + Feature Lock.  
**New approved scope:** implement D14.5 immediately after the current Day-14 boundary; do not interrupt unrelated Day-14 work.  

## Canonical authority

1. `01_Thaw_A_Creature_Concise_GDD_Canonical_v1.0.md`
2. `02_Thaw_A_Creature_Technical_Implementation_3Week_v1.0.md`
3. `05_Thaw_A_Creature_Implementation_Constants_Canonical_v1.4.md`
4. `04_Thaw_A_Creature_Development_Plan_Canonical_v1.4.md`
5. Prototype v1.0 FINAL remains historical Week-1 evidence only.

## D14.5 implementation handoff

### A. Home Camp / Lobby Safe Zone

Server-authoritative zone. Inside it:
- no `CurrentWarmth` drain, even while carrying Ice;
- no passive refill/training;
- own WarmZone still refills/trains;
- visitor WarmZones do not;
- player/mount contest effects disabled.

### B. Frosted Companion Orb

At Equipped-creature Vitality `0`:
- keep exact `EquippedCreatureGUID`;
- force Unride and block Ride;
- replace follower/mount presentation with Frosted Orb/Wisp;
- no further creature Vitality damage while at 0;
- own WarmZone restores full Vitality and rematerializes the exact creature;
- visitor WarmZone does nothing;
- no persistence/allocation changes.

### C. Size-Scaled Grab Hold

Replace instant Ice claim.

First-pass constants:
```text
0.75x Scale -> 1.00 sec
5.00x Scale -> 2.00 sec
Interpolation -> Linear
```

Rules:
- hold start does not reserve Ice;
- multiple players may hold the same Available Ice;
- first valid completed hold accepted by server wins;
- cancel/reset on release, range loss, contest hit/ragdoll, Freeze, death/reset, Ice invalid/unavailable;
- active holder cannot Tool Swing / Mounted Strike;
- mounted holder is allowed;
- hidden rarity/CreatureID/tier/Special do not affect duration.

### D. Carrier Commitment + DropIce

After successful Grab, server allows only:
- move;
- jump;
- Ride/Unride;
- DropIce;
- valid own-Pen deposit/placement.

Reject attack, breakables, another Grab, creature management, Sell, upgrades, reveal, and unrelated progression interactions while carrying.

DropIce:
- exact Ice only, no reroll;
- safe grounded release near carrier;
- owner clears, state -> Available;
- preserves hidden reward/size/Special metadata;
- no forced Unride;
- original dropper regrab lock `0.75 sec`;
- every reclaim requires a new full Grab Hold.

### E. Wilderness Contest - Non-Carrier

On-foot target:
- ragdoll `1.25 sec` + configured knockback;
- active Grab Hold cancels;
- post-recovery contest immunity `1.75 sec`.

Mounted target:
- deal `0.25 * CreatureVitalityMax`;
- force Unride;
- ragdoll/knock back player;
- active Grab Hold cancels;
- creature -> Following if still above zero;
- Frosted/Orb if zero;
- no auto-remount.

The Vitality loss applies only to validated PvP forced knock-off, never manual/system Unride.

### F. Wilderness Contest - Carrier

Carrier cannot attack at all due Carrier Commitment.

On-foot carrier:
- immune to player contest ragdoll/knockback.

Mounted carrier:
- valid wilderness hit deals `0.25 * CreatureVitalityMax` to mount;
- no player ragdoll/knockback;
- no forced Unride while Vitality > 0;
- no Warmth damage;
- no Ice drop/steal/state change;
- immediate `1.75 sec` contest grace after successful damage;
- at zero -> Frosted -> force Unride -> Orb; exact Ice remains carried and player continues on foot.

No separate PvP mount HP. Use existing session CreatureVitality.

### G. Required multiplayer QA

Verify with 2-4 players:
- concurrent size-scaled Grab Holds;
- first valid completed hold wins;
- hit before completion cancels hold;
- completion before hit enters correct carrier target rule;
- Lobby player/mount contest immunity;
- Lobby zero Warmth drain;
- own vs visitor WarmZone behavior;
- mounted non-carrier knock-off = exactly 25% Max Vitality loss;
- mounted carrier hit = exactly 25% Max mount Vitality loss with no player ragdoll/forced drop;
- four separated full-health mount hits normally Frost;
- 1.25 sec ragdoll / 1.75 sec post-recovery immunity;
- mounted-carrier immediate 1.75 sec hit grace;
- carrier cannot Tool/Mounted Strike or attack Sprites/breakables;
- DropIce exact identity + 0.75 sec self-regrab lock + fresh hold;
- Frosted Orb recovery and reset/death behavior;
- no permanent ownership/persistence corruption.

## Other reconciled documentation

Pen levels remain 1-7 / capacity 4-10 / `32x24 -> 32x48` with Cash costs `Start / 150K / 2.5M / 10M / 40M / 150M / 750M`. Manual thaw placement remains session-only presentation state with deterministic rejoin fallback and no thaw-capacity limit.
