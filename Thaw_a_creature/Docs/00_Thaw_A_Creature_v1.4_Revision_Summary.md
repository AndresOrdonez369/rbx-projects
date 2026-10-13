# THAW A CREATURE

## v1.4 Canonical Scope Revision Summary

**Status:** Approved design revision during Day 14 systems work  
**Authority updated:** GDD v1.0 -> Technical v1.0 -> Constants v1.4 -> Development Plan v1.4  

## 1. Size-Scaled Grab Hold

Wilderness Ice is no longer claimed instantly.

- The player must continuously hold the Grab input.
- First-pass hold time scales only from visible Ice Scale.
- `0.75x Scale = 1.00 sec`.
- `5.00x Scale = 2.00 sec`.
- First-pass interpolation is linear and configuration-driven.
- Starting a hold does not reserve the Ice.
- Multiple players may hold the same Available Ice.
- The first valid completed hold accepted by the server wins.
- Releasing input, leaving valid range, being contest-ragdolled/knocked away, Freeze/death/reset, or the Ice becoming unavailable cancels and resets the hold.
- Tool Swing / Mounted Strike is unavailable during an active Grab Hold.
- Hidden rarity, CreatureID, region/tier, and Special status never alter the hold duration.

Design purpose: the Ice contest now has a real commitment window that other players can interrupt before ownership changes.

## 2. Carrier Commitment

After the Grab Hold completes and the Ice becomes `Carried`, the player enters a restricted carry state.

Allowed gameplay actions:
- move;
- jump;
- Ride / Unride the currently Equipped creature;
- intentionally Drop the Ice;
- complete the valid own-Pen deposit/placement interaction.

Rejected while carrying:
- Tool Swing / Mounted Strike;
- PvE or PvP attacks;
- Frost Sprite attacks;
- breakable interactions;
- another Grab;
- creature management;
- Sell;
- Hearth/Pen upgrades;
- reveal interactions;
- unrelated progression/ownership actions.

The server enforces this state; hiding UI alone is not sufficient.

## 3. Intentional Drop Ice

The previous launch rule that raw Ice could not be intentionally dropped is superseded.

A valid `DropIce`:
- releases the exact Ice at a safe grounded position near the carrier;
- preserves `IceInstanceID`, IceType, hidden CreatureID/Rarity, WeightMultiplier/Scale, Special metadata, and applicable origin/cycle metadata;
- clears owner and returns the Ice to `Available`;
- never rerolls or converts the Ice into Inventory;
- does not force Unride;
- removes the carry drain multiplier after the Drop succeeds.

Every reclaim requires a fresh full Grab Hold. Other players may begin immediately; the original dropper has a first-pass `0.75 sec` self-regrab lock before beginning a new hold on that same Ice.

## 4. Wilderness Contest - Mounted Rules

The universal Tool/Mounted Strike remains a narrow wilderness Ice-contest interaction rather than a general PvP system.

### Non-carrier target on foot

Valid wilderness hit -> `1.25 sec` ragdoll + readable knockback -> `1.75 sec` post-recovery contest immunity. Any active Grab Hold cancels.

### Non-carrier target while Riding

Valid wilderness hit:
- deals `25% of CreatureVitalityMax` to the Equipped creature;
- force-Unrides the target;
- ragdolls/knocks back the player;
- cancels active Grab Hold;
- leaves the creature Following if Vitality remains above zero;
- resolves normal Frosted/Orb behavior if Vitality reaches zero;
- does not auto-remount after recovery.

Only a validated PvP contest hit that forces the player off applies this `25%`. Manual/system Unride paths do not damage Vitality.

### Carrier on foot

The carrier cannot attack and is immune to player contest ragdoll/knockback.

### Carrier while Riding

A valid wilderness contest hit:
- does not ragdoll or knock back the carrier;
- does not force Unride while mount Vitality remains above zero;
- does not damage Warmth;
- never drops or steals the Ice;
- removes `25% of CreatureVitalityMax` from the Equipped mount;
- grants `1.75 sec` immediate target grace to prevent dog-pile burst.

At zero Vitality, the mount becomes Frosted, force-Unrides, and turns into the Frosted Companion Orb. The player continues home on foot with the **same carried Ice**.

A full-health mount therefore normally needs four separated valid player hits to reach zero.

## 5. Home Camp / Lobby Safe Zone

The shared Home Camp / Lobby remains an explicit Warmth-safe social zone.

- `CurrentWarmth` does not decrease anywhere inside it, including while carrying Ice.
- The Lobby itself does not refill CurrentWarmth or train MaxWarmth.
- Only the player's own Hearth/WarmZone refills CurrentWarmth, trains MaxWarmth, and restores a Frosted companion.
- Another player's WarmZone remains social-only.
- Player/mount contest effects are disabled throughout the Lobby.
- Normal regional wilderness drain resumes immediately after leaving the safe-zone boundary.

Design purpose: players can inspect other Pens/socialize without spending expedition Warmth.

## 6. Frosted Companion Orb

At Equipped-creature Vitality `0`:
- ownership and logical Equipped allocation remain unchanged;
- Riding is forced off and blocked;
- the creature becomes a small floating Frosted Orb/Wisp beside the player;
- movement returns to base WalkSpeed;
- the Orb is not targetable and takes no further Vitality damage;
- UI communicates `FROSTED - RETURN TO YOUR HEARTH`.

Own-WarmZone recovery restores full Vitality and rematerializes the exact Equipped creature. Freeze/death/reset recovery remains safe.

## 7. Pen + Thaw Rules Retained from v1.3

The approved Pen progression remains:

| Level | Capacity | Size | Cost |
|---|---:|---:|---:|
| 1 | 4 | 32x24 | Start |
| 2 | 5 | 32x28 | 150K |
| 3 | 6 | 32x32 | 2.5M |
| 4 | 7 | 32x36 | 10M |
| 5 | 8 | 32x40 | 40M |
| 6 | 9 | 32x44 | 150M |
| 7 | 10 | 32x48 | 750M |

Logical Pen slots remain bookkeeping only; creatures roam the shared unlocked Pen area. Player-chosen thaw placement remains session-only visual state with deterministic rejoin fallback and unlimited logical thawing.

## 8. Day-14 Coordination

Do **not** interrupt unrelated Day-14 Economy/Collection work. The approved mechanics are recorded as explicit `D14.5` launch-scope revisions to implement immediately after the current Day-14 systems boundary.

This revision does not authorize generic PvP combat, Player HP, weapon progression, permanent mount combat stats, creature combat progression, forced PvP Ice drops, or lobby griefing.
