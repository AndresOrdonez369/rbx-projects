# THAW A CREATURE

## Concise Game Design Document - Canonical v1.0

**Platform:** Roblox  
**Genre:** Creature Collection / Expedition / Progression  
**Setting:** Stylized frozen fantasy with Norse framing  
**Launch Target:** 3-week production  
**Launch Content Target:** 20 creatures, 5 Ice types, 5 rarities, 10 Hearth levels, 7 Pen levels / 4-10 active Pen creatures  

### Revision notes

- Adds a **size-scaled Grab Hold** for wilderness Ice: `1.00 sec` at `0.75x Scale` to `2.00 sec` at `5.00x Scale`, first-pass linear and configuration-driven. Starting a hold does not reserve the Ice; the first valid completed hold accepted by the server wins.
- Adds **Carrier Commitment**: after a successful Grab, the carrier may only move, jump, Ride/Unride, intentionally Drop the exact Ice, or complete the valid home deposit/placement interaction. Tool/Mounted Strike, combat, breakables, upgrades, inventory management, Sell, reveal, and other gameplay interactions are disabled while carrying.
- Supersedes the old no-intentional-drop rule with an explicit **Drop Ice** action. Dropped Ice preserves exact identity/reward/size/Special metadata, returns to shared `Available` state, and must be reclaimed through a fresh Grab Hold. The original dropper has a short first-pass `0.75 sec` self-regrab lock.
- Refines **Wilderness Contest Knockback** for mounted play: a mounted non-carrier who is successfully knocked off loses `25%` of `CreatureVitalityMax`; a mounted carrier is not ragdolled or forced off by PvP while the mount still has Vitality, but valid wilderness hits damage the mount by the same `25%`. At zero Vitality the mount becomes Frosted, forces Unride, and the carrier continues home on foot with the exact Ice.
- Adds a shared **Home Camp / Lobby Safe Zone**: CurrentWarmth does not drain anywhere inside the lobby, including while carrying Ice. Warmth still increases only inside the player's own Hearth/WarmZone; another player's WarmZone remains social-only.
- Adds the **Frosted Companion Orb** presentation: a Frosted/Downed Equipped creature remains logically Equipped, becomes a small floating frozen orb/wisp beside the player, and rematerializes only after recovery at the owner's own WarmZone or normal failure recovery.
- Promotes the approved seven-level Pen progression: Lv1-7 capacity `4 -> 10`, fixed width `32`, depth `24 -> 48`, shared-area creature roaming, and direct Cash upgrades.
- Approves player-chosen thaw-Ice placement inside the Pen for the current session, with server-authoritative overlap/bounds validation and deterministic auto-layout fallback after rejoin; thaw capacity remains unlimited.
- Raises the launch creature target from 16 to **20 species**, organized as four signature creatures per region.
- Broadens creature sourcing beyond Norse mythology while keeping Norse/Great-Frost framing: real animals, extinct animals, worldwide folklore/myth, Norse creatures, and original fantasy are all allowed when regionally coherent.
- Locks region-exclusive normal Ice families and the principle: **farther = greater fantasy/economic band, not guaranteed rarity**.
- Rebalances all launch BaseIncome values into overlapping regional economic bands while preserving controlled creature Speed progression and the existing per-copy size formulas.
- Locks the first-pass 10-level Hearth costs/training rates and the longer Warmth progression target from minutes into hours.
- Updates Recommended Warmth, regional cold multipliers, and Frost Sprite Warmth damage to the new progression curve.
- Keeps Special Ice but standardizes its eligible-region rarity profile to 90% Rare / 10% Legendary.
- Allows the nine new launch species to use functional placeholder meshes until final creature assets are produced/audited.
- Makes selling intentionally secondary: inventory cleanup plus a small consolation payout, not a primary economy strategy; Frozen Archive expands to 20 species.


- Promotes rideable Equipped creatures into launch scope: every creature can be ridden, and when unmounted it keeps follower behavior.
- Separates base selection (`Equip/Unequip`) from exploration state (`Ride/Unride`).
- Locks creature `FinalWalkSpeed` to the Riding state; unmounted players move at base WalkSpeed while the Equipped creature follows.
- Adds one universal mounted survival strike that is mechanically identical to the on-foot survival attack and does not create creature combat progression.

- Records the successful End-of-Week-1 prototype gate and promotes the complete validated Survival Pressure package into launch design.
- Makes survival explicitly support retrieval rather than becoming a separate combat-progression game.
- Extends Frost Sprite guardian encounters across all five geographic Ice tiers with region-scaled Warmth damage.
- Locks every spawned Ice opportunity as one shared server object visible/contestable by all players.
- Replaces deletion/origin-return failure behavior with exact-Ice drop-and-rescue on Freeze, death, reset/respawn, or disconnect.
- Removes the private onboarding-Ice exception; onboarding now points players toward the shared Ice field.
- Rescue/relay remains valid multiplayer behavior, and the newer Carrier Commitment rule additionally allows intentional DropIce without reroll or direct trading.

### v0.5 Revision - Jackpot Scale + Big-Number Progression

The v0.5 revision promotes per-copy size jackpots, big-number Warmth progression, stronger Hearth presentation, and expanded Day 6-7 content as canonical design.

## 1. High Concept

A supernatural winter known as The Great Frost has trapped creatures throughout a vast frozen
wilderness.
Players leave the safety of their Hearth, spot mysterious creatures trapped inside Ice, and risk
their Warmth to physically bring those Ice blocks home before freezing.
Recovered Ice thaws over time inside the player's Pen. Once ready, the player:

**CRACK -> CRACK -> SMASH**
to awaken the creature inside.
Creatures can then generate money, be sold, or be Equipped as the player's active traversal creature. An Equipped creature follows while unmounted and can be ridden during exploration; Riding applies that copy's dramatically faster `FinalWalkSpeed`, allowing increasingly dangerous expeditions deeper into the frozen world.


## 2. Core Fantasy

"How far into the Great Frost will I go for what is trapped inside?"
The game should make the player feel like an increasingly powerful frozen-wilderness explorer.
Early game:

A nearby Ice block feels dangerous to retrieve.
Late game:

The player races through previously threatening regions **riding** a mythical creature, searching for enormous supernatural Ice deep in the wilderness. If they Unride, that same Equipped creature continues following them.

## 3. Unique Selling Proposition

The collectible has a journey before it becomes a reward.
Players do not simply buy or hatch creatures.
They:

SEE IT
-> WANT IT
-> RISK THE EXPEDITION
-> BRING IT HOME
-> WATCH IT THAW
-> SMASH IT OPEN
The Ice itself becomes desirable before the player knows exactly what is inside.
The player should form a story around important creatures:

"I saw this enormous Ice incredibly far away, barely made it home before
freezing, waited for it to thaw, and it turned into a Mammoth."
If the game feels like:

"Find object -> wait -> get pet"
the USP has failed.
The retrieval itself must be memorable.


## 4. Internal Tagline

See it. Risk it. Bring it home. Watch it thaw. Smash it open.

## 5. Core Emotional Pillars

```text
               Pillar                           Player Feeling
               [Mystery] Mystery                        What is trapped inside that Ice?
               [Risk] Risk                           Can I get it home before I freeze?
               [Anticipation] Anticipation                   It's almost ready...
               [Payoff] Payoff                         What am I about to awaken?
               [Ownership] Ownership                      Look at everything I've brought
                                                home.
               [Power] Power                          I'm dramatically faster than I used
                                                to be.
               [Progression] Progression                   I can finally reach what I saw
                                                earlier.
               [Spectacle] Spectacle                      Something huge is happening in this
                                                world.
```


## 6. Epicness Philosophy

Epicness should come from:

scale + presentation + consequence
around systems we are already building.
It should not require adding unnecessary mechanics.
When the game needs more epicness, first ask:

"Which existing moment needs to feel bigger?"
rather than:

"What new system should we add?"

## 7. Core Gameplay Loop


```text
            1   LEAVE THE HEARTH
            2           v
            3   SEARCH THE FROZEN WILDERNESS
            4           v
            5   SPOT A DESIRABLE ICE
            6           v
            7   RISK WARMTH TO REACH IT
            8           v
            9   CARRY IT HOME
           10           v
           11   PLACE IT IN YOUR PEN
           12           v
           13   ICE THAWS OVER TIME
           14           v
           15   KEEP EXPLORING / TRAIN WARMTH / MANAGE CREATURES
           16           v
           17   THE GREAT FROST / NIGHT RESET
           18           v
           19   NEW ICE APPEARS + THAWING ACCELERATES
           20           v
           21   ICE BECOMES READY
           22           v
           23   CRACK -> CRACK -> SMASH
           24           v
           25   AWAKEN CREATURE
           26           v
           27   PEN / EQUIP / SELL
           28           v
           29   EARN -> IMPROVE HEARTH -> TRAIN MORE WARMTH
           30           v
           31   MOVE FASTER + SURVIVE LONGER
           32           v
           33   REACH STRANGER ICE
```


The end of one goal should create the next one.

The reward should advertise the next reward.

## 8. Setting - The Great Frost

The world is a stylized frozen fantasy with strong Norse-inspired framing, not a historical Viking simulator or a lore-heavy adaptation of one mythology.

The visual language may use:
- auroras;
- runestones;
- carved wood;
- braziers and Hearths;
- snowy mountains;
- magical frost;
- ancient ruins;
- supernatural Ice;
- strange creatures from nature, prehistory, folklore, mythology, and original fantasy.

Norse is the world's framing language, **not a hard creature taxonomy**.
Launch creatures may draw from:
- recognizable real animals;
- extinct animals;
- Norse mythology;
- worldwide folklore/myth;
- original fantasy.

Creature selection is governed by regional fantasy cohesion and immediate collectible desirability, not historical/mythological accuracy. Avoid random "mythology soup": the roster should still feel like one coherent Great Frost collection.

The setting exists to make the existing mechanics feel larger and more coherent.

Thaw A Creature is **not a combat-progression game**. The player is not being promised:
- raids;
- historical simulation;
- mythology quest chains;
- weapon collection/progression;
- enemy farming as a primary loop.

The launch game **does** include a deliberately narrow survival layer: one universal survival tool, stationary Frost Sprites, Guarded Ice, temporary Equipped-creature danger, and breakable route obstacles. These systems exist only to make the Ice journey more dangerous, physical, and memorable.

The fantasy remains:

> familiar, ancient, supernatural, and impossible creatures awakening from an endless magical winter.

## 9. World Structure

The launch world is one continuous frozen wilderness.
Progression moves outward through:

```text
Warm Hearth -> Regular -> Thick -> Ancient -> Black -> Meteor
```

Each region becomes:
- colder;
- stranger;
- more visually supernatural;
- more valuable;
- harder to retrieve Ice from;
- more dangerous when Frost Sprites are present.

There are no portals or separate worlds.
Players should always understand:

> farther = more dangerous = more exciting possibilities.

### Shared wilderness rule

Every spawned wilderness Ice opportunity is one authoritative server object shared by all players. There are no per-player copies of Regular, Thick, Ancient, Black, Meteor, or Special Ice.

If multiple players want the same Ice, the first valid completed Grab Hold accepted by the server wins.

Launch multiplayer home layout:
- up to four personal bases are grouped side-by-side along one shared home-camp edge;
- all bases face the same primary wilderness direction;
- the shared Home Camp / Lobby is a **Warmth-safe social zone**: `CurrentWarmth` does not decrease anywhere inside it, including while carrying Ice;
- the Lobby does **not** automatically refill Warmth or train `MaxWarmth`; those benefits still require the player's **own** Hearth/WarmZone;
- another player's Hearth/WarmZone does not refill Current Warmth, train Maximum Warmth, or restore the visitor's Frosted companion;
- player Tool/Mounted-Strike contest knockback has no effect inside the Home Camp / Lobby.

This lets players inspect neighboring Pens and socialize without paying an expedition-survival tax, while preserving the Hearth as the only place that refills/trains Warmth. The wilderness begins outside the safe-zone boundary; normal regional drain resumes immediately on exit.

## 10. Creature Fantasy Escalation

Creature progression should feel increasingly extraordinary without making distance a guarantee of higher rarity.

**Snowfield / Regular**  
Familiar frozen wildlife.

**Frozen Pass / Thick**  
Larger and more impressive frozen-fantasy beasts.

**Ancient Expanse / Ancient**  
Prehistoric / primordial creatures from another age.

**Black Ice Hollow / Black**  
Supernatural, uncanny, or ominous creatures.

**Meteor Reach / Meteor**  
Impossible, mythic, or reality-bending creatures.

The core content rule is:

> **Region = what kind of fantasy you can discover. Rarity = how exceptional your roll was within that fantasy.**

And:

> **Farther Ice does not guarantee a better rarity. It guarantees a more extraordinary creature fantasy.**

A Common creature from Meteor should still feel more fantastical than a Common creature from Snowfield, while a Legendary from Black can remain more economically valuable than early Meteor results.

## 11. No Hard Area Gates

Regions do not require specific Warmth, Heater, or creature levels.
Instead, each area has:

[Risk] Recommended Warmth
A player can always attempt an area early.
That allows moments like:

"I'm definitely underprepared...but maybe I can make it."
Recommended Warmth is guidance, not permission.


## 12. Warmth

Warmth represents expedition endurance.
The player has:

**Current Warmth**  
Drains while outside the safe Hearth area.

**Maximum Warmth**  
Permanent, uncapped progression.

Warmth is intentionally a **big-number progression stat**. Early values may be in the hundreds, while deeper progression may require thousands, tens of thousands, hundreds of thousands, or more. Watching the number climb should feel satisfying rather than clinically precise.

Different regions apply dramatically stronger cold severity. Frost Sprite hits in those regions remove a configured amount of Current Warmth that scales with the region's progression tier.

If Current Warmth reaches zero:

**FROZEN**

The player returns home. Permanent progression is preserved.

If the player was carrying a shared Ice, that exact Ice is released into the shared world at the last valid carrier position. Its hidden reward and size lineage do not reroll, and any player may attempt to recover it.

## 13. Permanent Warmth Training

While inside their own heated base area, the player continuously trains:

**Maximum Warmth**

Warmth has:
- no maximum;
- no Warmth XP;
- no training currency;
- no hard training cap.

The displayed gain should be deliberately gratifying. The player should see large values rising rapidly as the Hearth improves.

The fantasy remains simple:

> Stay beside your Hearth -> become more resistant to the cold -> attempt more absurd regions.

## 14. Hearth / Heater Progression

The Heater system is presented within the fantasy as the player's increasingly powerful **Hearth**.
Cash upgrades it.

A better Hearth means:
- Maximum Warmth trains dramatically faster;
- deeper Recommended Warmth targets become realistically reachable;
- the home base visibly communicates progression.

The Hearth does not determine a maximum Warmth value and does not directly grant a fixed Warmth level.

The Hearth must receive strong presentation because it is one of the game's main progression engines. Without changing its function, it should read as an important landmark through:
- strong fire/light/smoke/embers;
- a visible WarmZone treatment;
- `HEARTH LV. X`;
- visible `+Warmth/sec` training rate;
- next upgrade cost or `MAX` state.

The player should immediately understand:

> "Standing here is permanently making me stronger."

## 15. Equipped Creature = Traversal Companion / Mount

Players Equip one specific CreatureGUID through their own base/Pen management flow. That creature remains the single active Equipped creature and has two exploration presentation states:

```text
FOLLOWING <-> RIDING
```

**Following**
- the creature keeps the existing lightweight follower behavior;
- the player moves on foot at base WalkSpeed `16`;
- the creature remains Equipped, earns no Pen income, and keeps its session Vitality/Frosted state;
- the player may Ride it during exploration.

**Riding**
- the player rides that exact creature copy;
- movement uses the copy's `FinalWalkSpeed`;
- the player may Unride during exploration and return to follower state;
- Ride/Unride is allowed while carrying Ice and does not change Ice ownership or drop the Ice.

Every creature is mountable, even when the result is strange, tiny, or absurdly oversized. The existing authored Seat on each creature is the default rider anchor. Species-specific rider poses, camera framing, and mount animations are welcome presentation polish, but they must not create species-specific traversal powers.

Speed is determined by the **individual creature copy**, not rarity alone. Each species has a base traversal identity, and the inherited size roll modifies that copy's final mounted Speed.

This creates two simultaneous progression questions:
- Which species is naturally better for traversal?
- Did I roll an unusually large copy with an exceptional Speed modifier?

Size may strongly improve Speed, but it must scale more gently than Pen Income so even a `5x` visual jackpot does not destroy Warmth/distance gameplay.

The emotional requirement remains:

> "WHOA. I'm fast now."

Creature Speed serves two purposes:

**Progression**  
Ride farther before Warmth runs out.

**Compression**  
Previously solved terrain becomes much faster to cross during future attempts.

## 16. Speed Must Be Obvious

Speed jumps should be large enough that players do not need a stat panel to feel them, while the exact final Speed is still displayed on the creature for comparison.

A creature's final **mounted** Speed comes from:

```text
Species Base Speed
x
Size-Derived Speed Multiplier
```

When the Equipped creature is only Following, player movement returns to base WalkSpeed `16`.

Movement presentation can reinforce mounted Speed through:
- faster run animation;
- subtle FOV response;
- snow trails;
- rarity/size-specific effects.

Actual server-authoritative movement speed must change. Presentation cannot substitute for the real stat.

## 17. Carrying Ice

Players may carry:

**one Ice at a time.**

A successful size-scaled Grab Hold transitions the exact shared Ice into `Carried` state and places the player into **Carrier Commitment**.

While carrying Ice:
- Warmth drains faster outside the Home Camp / Lobby Safe Zone;
- carrying does **not** reduce movement Speed;
- the carried Ice remains visually obvious;
- the same authoritative Ice identity continues through the journey;
- the player may move and jump;
- the player may Ride/Unride their currently Equipped creature;
- the player may intentionally **Drop Ice**;
- the player may complete the valid own-Pen deposit/placement interaction.

All other gameplay actions are disabled while carrying. In particular, a carrier cannot:
- use Tool Swing or Mounted Strike;
- attack players, player mounts, Frost Sprites, or breakables;
- Grab another Ice;
- Equip/Unequip or otherwise manage creatures;
- Sell;
- upgrade the Hearth or Pen;
- start another thaw-placement interaction;
- begin or advance a reveal;
- use another gameplay interaction that changes progression, ownership, or combat state.

Normal camera/settings/menu controls are not part of this gameplay restriction.

The tension becomes:

> I won the Ice. Now can I get it home before the cold, the wilderness, or another player takes my mount away?

### Intentional Drop Ice

The carrier may intentionally relinquish the exact Ice.

On a valid Drop:
- preserve `IceInstanceID`, IceType, hidden CreatureID/Rarity, WeightMultiplier/Scale, Special metadata, and applicable origin/cycle metadata;
- place the Ice at a valid safe grounded position near the carrier;
- clear owner;
- set `State = Available`;
- do not reroll anything;
- do not convert raw Ice into Inventory;
- do not force Unride.

Any player may then attempt a fresh Grab Hold. The original dropper has a short first-pass self-regrab lock of `0.75 sec` so Drop cannot be used as an instant combat-mode toggle.

A carry therefore ends through exactly one of:
- successful own-Pen deposit/placement;
- intentional Drop Ice; or
- genuine carrier failure: Freeze, character death, Reset Character/respawn, or disconnect.

Failure release and intentional Drop both preserve the exact Ice and return it to shared world competition.

## 18. Freezing

At zero Warmth:

**FROZEN**

The player:
- releases the carried Ice into the shared world at the last valid carrier position;
- returns to their own Hearth;
- restores Current Warmth to Maximum Warmth;
- retains all permanent progression;
- can immediately try again.

A released Ice preserves its exact `IceInstanceID`, hidden reward, rarity, WeightMultiplier/Scale, IceType, and Special metadata if any.

Failure costs:

> time and opportunity

rather than permanent progression or automatic destruction of the Ice opportunity.

Another player may recover the dropped Ice before the original player returns. That is valid multiplayer gameplay.

Higher creature Speed naturally makes future reattempts faster.

## 19. Ice Progression

Launch progression contains:
1. Regular Ice
2. Thick Ice
3. Ancient Ice
4. Black Ice
5. Meteor Ice

Different Ice types can have different:
- creature pools;
- rarity distributions;
- thaw times;
- base visual size;
- reference weight;
- effects;
- Recommended Warmth context.

Every wilderness Ice also receives an independent **size/weight jackpot roll** when it spawns.

Each Ice type has a base/reference size. The roll is converted to visible Scale through:

```text
Scale = cbrt(ActualWeight / ReferenceWeight)
```

The formula creates the size variation. Visual Scale is not rolled separately afterward.

The current design intentionally supports extreme rolls up to **5.0x visual Scale**. A near-maximum Ice may be absurdly large, visible from far away, overlap surrounding scenery, and become an immediate social/aspirational event.

Size is visible before retrieval but does not reveal the exact hidden creature or rarity.
Going farther must unlock new creature possibilities, not merely better percentages.

## 20. Seeing Ice

Players should often see desirable content before they can comfortably retrieve it.
This is intentional.

A player should occasionally stand at home or in an early zone and see:
- an enormous Ice formation;
- a freakishly oversized random Ice roll;
- strange runes;
- a giant obscured silhouette;
- a distant supernatural glow;

and think:

> "I NEED that one."

Visible aspiration is a core progression tool.

Size adds a new pre-reveal jackpot signal:

```text
Ice Type
+ Distance
+ Visible Scale
= desirability before the player knows the exact reward
```

A giant Ice is a promise that the resulting creature copy will preserve the same size multiplier after reveal.


### Size-scaled Grab Hold

Wilderness Ice is **not claimed instantly**.

A player must continuously hold the Grab interaction before ownership changes. The first-pass hold duration depends only on the Ice's already-visible Scale:

```text
Minimum supported Scale = 0.75x -> 1.00 sec hold
Maximum supported Scale = 5.00x -> 2.00 sec hold
```

First-pass interpolation is linear and configuration-driven:

```text
NormalizedScale = clamp((Scale - 0.75) / (5.00 - 0.75), 0, 1)
GrabHoldSeconds = lerp(1.00, 2.00, NormalizedScale)
```

Starting a hold does **not** reserve the Ice. Multiple players may attempt the same `Available` Ice, and the first valid completed hold accepted by the server wins.

A Grab Hold resets if the player releases the input, leaves valid interaction range, is ragdolled/knocked away, freezes, dies/resets, or the Ice becomes unavailable/invalid. Previous hold progress does not resume.

While actively holding to Grab, the player cannot use Tool Swing or Mounted Strike. Mounted players may perform the same hold from Riding state; the Ice uses the same duration for every player regardless of mount/species/rarity/Speed.

Hold duration must never depend on hidden CreatureID, hidden rarity, region tier, or Special status. Visible Ice Scale is the only reward-lineage input.

## 20A. Canonical Survival Pressure

Week-1 testing validated Survival Pressure as part of the launch experience.

The approved survival package is intentionally narrow:
- one universal survival attack input with two presentations: on-foot tool swing and Mounted Strike;
- stationary Frost Sprites;
- Guarded Ice encounters;
- Frost Sprite hits reduce `CurrentWarmth`; there is no Player HP;
- session-only Vitality for the currently Equipped creature;
- Frosted/Downed at zero creature Vitality;
- Frosted/Downed immediately forces Unride if necessary, blocks Ride, and never removes ownership;
- own-Hearth recovery restores the creature and makes Riding available again;
- Frosted/Downed companion presentation uses a small floating Frosted Orb/Wisp while the creature remains logically Equipped;
- wilderness-only player contest knockback creates a brief pre-Grab opening around desirable shared Ice;
- mounted contest hits can damage the Equipped creature's existing session Vitality without creating mount-specific combat stats;
- Carrier Commitment prevents the Ice carrier from attacking or using unrelated gameplay interactions during the return journey;
- a mounted carrier may have the mount damaged by wilderness contest hits, but the player is not ragdolled and PvP never forces the Ice to drop;
- minimal survival feedback;
- small breakable route obstacles that create route-time choices.

The player should still talk about the Ice and the return trip more than the enemies.

Desired feeling:

> "I wanted that Ice, everything went wrong, and I barely got it home."

Not:

> "Where do I farm monsters?"

### Frosted Companion presentation

At zero Equipped-creature Vitality, the creature is **temporarily downed, never lost**. The creature remains the player's logical `EquippedCreatureGUID`, but its follower/mount model transitions into a small floating frozen orb/wisp beside the player.

While Frosted:
- force Unride if necessary;
- Riding remains unavailable;
- the player uses base WalkSpeed;
- the Frosted Orb follows as presentation only;
- the creature cannot take further Vitality damage while already at zero;
- ownership and Pen/Inventory allocation do not change.

Entering the owner's **own** Hearth/WarmZone restores full creature Vitality, clears Frosted, cracks/thaws the orb, and rematerializes the same Equipped creature. Another player's WarmZone does nothing. Freeze/death/reset recovery may also restore normally as already defined.

The required communication is:

> **FROSTED - RETURN TO YOUR HEARTH**

### Wilderness Contest Knockback

The universal survival Tool also supports a deliberately narrow multiplayer contest around **unclaimed wilderness Ice**. This is not general PvP combat.

Before an Ice has been successfully Grabbed, an eligible player may hit another eligible player with the same Tool Swing / Mounted Strike to create a short positional opening.

General contest rules:
- attacker and target must both be server-confirmed in wilderness contest space at hit resolution;
- Home Camp / Lobby is a complete player-hit Safe Zone;
- a carrying attacker cannot use Tool Swing or Mounted Strike at all because Carrier Commitment is active;
- a player in active Grab Hold cannot attack until that hold is cancelled/completed;
- contest effects deal no Player HP, CurrentWarmth, Cash, ownership, Inventory, Pen, or Ice-state damage;
- PvP never directly forces a carried Ice to drop;
- attack reach, cooldown, mount presentation, and validity never scale from CreatureID, rarity, Scale, WeightMultiplier, `FinalWalkSpeed`, current velocity, or mount visual mass;
- no contact/trample/body-collision damage exists.

**On-foot target, not carrying Ice**

A valid hit causes:
- short ragdoll;
- strong readable knockback;
- the active Grab Hold, if any, cancels and resets;
- `1.25 sec` first-pass ragdoll duration;
- `1.75 sec` first-pass post-recovery immunity from another player contest effect.

**Mounted target, not carrying Ice**

A valid hit:
- force-Unrides the target;
- leaves the exact Equipped creature safely in `Following` state unless it reaches zero Vitality;
- ragdolls and knocks back only the player;
- cancels any active Grab Hold;
- removes `25% of CreatureVitalityMax` from the Equipped creature;
- at zero Vitality, transitions the creature to Frosted/Downed and the Frosted Companion Orb presentation;
- never auto-remounts the player after recovery.

The `25%` loss occurs only because a validated **PvP contest hit** forced the mounted player off. Manual Unride, Seat repair, respawn cleanup, or Frosted's own forced-Unride must never apply this damage.

**On-foot carrier**

The carrier cannot attack and is immune to player contest ragdoll/knockback. Other players cannot damage an absent/unridden mount through this rule.

**Mounted carrier**

A valid wilderness contest hit does **not** ragdoll the carrier, knock the carrier back, force Unride, damage Warmth, or drop the Ice. Instead it removes `25% of CreatureVitalityMax` from the current Equipped mount and grants the target the configured PvP hit grace.

If the mount reaches zero Vitality:
- it becomes Frosted/Downed;
- force Unride;
- show the Frosted Companion Orb;
- the player continues carrying the exact Ice **on foot**;
- the Ice remains owned/carried and is never dropped by this PvP consequence.

A full-health mount therefore normally requires four separated `25%` contest hits to Frost. The target grace prevents simultaneous dog-piling from collapsing those hits into one frame.

The intended multiplayer story is:

```text
spot desirable Ice
-> fight for position
-> commit to the size-scaled Grab Hold
-> interrupt a rival before completion
-> one player completes the Hold and becomes carrier
-> carrier cannot retaliate
-> pursuers may hinder a mounted carrier by damaging the mount
-> if the mount Frosts, the carrier runs the rest of the journey on foot
-> PvP never directly steals/drops the Ice
```

### Regional Frost Sprite threat

Every geographic Ice tier supports Frost Sprite guardian encounters.
Not every individual Ice must be guarded; authored/configured unguarded opportunities may remain so players can choose among risk profiles.

First-pass Warmth damage per successful Frost Sprite hit:

| Region | Main Ice | Recommended Warmth | Warmth Damage |
|---|---|---:|---:|
| Snowfield | Regular | 100 | 10 |
| Frozen Pass | Thick | 1,000 | 100 |
| Ancient Expanse | Ancient | 40,000 | 4,000 |
| Black Ice Hollow | Black | 2,500,000 | 250,000 |
| Meteor Reach | Meteor | 80,000,000 | 8,000,000 |

The threat is based on location/region, not the player's MaxWarmth. This lets old threats become naturally weaker as the player grows.


### Mounted survival attack

Riding does not create a second combat progression system. The same player-controlled survival attack is expressed differently by state:

```text
On foot -> tool swing
Riding  -> Mounted Strike
```

Mounted Strike has the same gameplay damage/effect, cooldown, valid targets, and server validation as the on-foot attack. When the player is **not carrying Ice**, it may hit Frost Sprites, approved breakable route obstacles, and valid wilderness contest player targets under the rules above. Carrier Commitment disables Mounted Strike entirely while carrying Ice. It does not scale from species, rarity, Scale, WeightMultiplier, or mount Speed.

The hit is resolved from a standardized ground/front mount combat origin so giant mounts can interact with threats below the rider. A giant Nidhogg therefore does not gain extra attack range or damage. There is no trample/contact damage. Species-specific bite/stomp/kick/swipe/headbutt animation is presentation only. Giant mounts should receive camera/target readability support so nearby Sprites are not hidden by the mount itself.

## 20B. Shared Ice Failure / Rescue Contract

Every spawned Ice is the same world opportunity for every player in that server.

On successful completion of the authoritative Grab Hold:

```text
Available -> Carried
OwnerUserID = carrier
Carrier Commitment begins
```

On Freeze, character death, Reset Character/respawn, or disconnect before deposit:

```text
Carried
-> restore the exact Ice at the last valid carrier position
-> OwnerUserID = nil
-> Available
-> first valid completed Grab Hold accepted by the server wins again
```

No reward, rarity, size, or identity reroll occurs.

Intentional Drop uses the same identity-preserving shared-world principle but is **not** failure: the carrier deliberately relinquishes the exact Ice at a valid safe grounded position, owner clears, state becomes `Available`, and all players must use a new full Grab Hold to reclaim it. The original dropper cannot begin a new Grab Hold on that same Ice for the configured short self-regrab lock.

If the exact failure position is invalid, use the last valid grounded/safe carrier position; authored origin is the final fallback.

There are no private onboarding Ice copies. Onboarding may guide a player toward a suitable shared Regular Ice, but it must never duplicate the shared field.

## 21. Silhouette Rule

Ice should give clues without reliably revealing the exact creature.
Information progresses through:

distant vague shape
-> closer identifying features
-> clearer silhouette during thaw
-> almost recognizable form
-> final exact reveal
Mystery must survive until the Smash.

Launch uses a small reusable silhouette-profile set rather than one exact silhouette per species. Multiple species intentionally share profiles so the outline remains a clue rather than a guaranteed answer. Exact mappings live in Implementation Constants.


## 21A. One Size Roll - Full Journey

The server creates one authoritative size/weight roll when wilderness Ice spawns.
That roll survives the entire journey:

```text
Wilderness Ice
-> Carried Ice
-> Deposited / Thawing Ice
-> Ready Ice
-> CRACK -> CRACK -> SMASH
-> Revealed Creature Copy
```

There is no second creature-size reroll at reveal.
A gigantic Ice should not reveal a tiny version of its creature.

The same multiplier applies to each object's own base/reference size, so different Ice types and species remain visually distinct while sharing the jackpot magnitude.

Size initially does **not** change:
- hidden rarity odds;
- thaw duration;
- carry Warmth multiplier;
- Great Frost rules;
- guardian count.

Those remain separate balance systems unless explicitly revised later.


## 21B. Jackpot Scale Philosophy

Scale should be allowed to become intentionally ridiculous.
The rarest outcomes may reach approximately **5x visual Scale**.

At the top end:
- a creature may dominate the player's screen;
- a Pen creature may visually spill into neighboring Pen space;
- other players should notice it immediately;
- the result should naturally create screenshots, stories, and social comparison.

Gameplay allocation remains clean even when visuals overlap. Four Pen positions remain four logical income positions.

The purpose is not realism. The purpose is a jackpot moment that is readable before and after reveal.


## 22. Pen = Player's Home Story

The Pen is not merely an income interface.
It should visually communicate:

everything the player has brought back from the wilderness.
Inside the Pen can be:
creatures wandering;
ordinary Ice thawing;
giant unusual Ice;
Black or Meteor Ice pulsing;
Ice almost ready to reveal.
The Pen becomes a:

living trophy room + anticipation space.
Another player should be able to look at it and understand:

"This player has done things I haven't."

## 23. Pen Creature Capacity + Upgrades

The Pen has seven normal-Cash progression levels. Capacity increases by exactly one active earning creature per level while the enclosure expands only along local +Z:

| Pen Level | Active Creature Capacity | Width X | Depth Z |
|---|---:|---:|---:|
| 1 | 4 | 32 | 24 |
| 2 | 5 | 32 | 28 |
| 3 | 6 | 32 | 32 |
| 4 | 7 | 32 | 36 |
| 5 | 8 | 32 | 40 |
| 6 | 9 | 32 | 44 |
| 7 | 10 | 32 | 48 |

Logical server slots may still track which CreatureGUIDs are active and earning, but **players never see physical creature slots**. Active Pen creatures roam the entire currently unlocked Pen area as lightweight presentation. Duplicates are allowed.

The Pen front/gate and X width remain fixed. Each upgrade adds `+4 Z` depth and `+1` active earning-creature capacity.

## 24. Pen Thawing / Player Placement

There is no dedicated Thaw Machine. Successfully retrieved Ice is placed directly inside the player's Pen and its thaw timer begins automatically. Thawing Ice consumes **zero** creature capacity.

For launch presentation, the carrier chooses a valid thaw position inside the current Pen footprint using a placement ghost and mouse/touch input. Server validation rejects overlap with other thawing Ice and reserved fence/gate/banner space. Roaming creature visuals do not block placement and should avoid placed Ice afterward.

Exact manual placement coordinates are session-only and are not required to persist. After rejoin, existing thawing Ice may use deterministic valid auto-layout positions. This presentation rule never creates a thaw-capacity limit.


## 25. Unlimited Thawing

There is no gameplay limit on simultaneous thawing Ice.
Players may accumulate multiple retrieved Ice blocks in their Pen.
The natural limitation is:

one retrieval per expedition.
There are no:
Thaw Slot upgrades;
incubator purchases;
storage expansions.
If large quantities eventually become visually awkward, that should be solved through
presentation rather than progression restrictions.


## 26. Thaw Time

Different Ice types can require different amounts of time to thaw.
Thaw duration depends primarily on:

Ice Type
rather than hidden creature rarity.
Players should not be able to determine:

"Long timer = Legendary."

The exact reward remains uncertain.


## 27. Offline Thawing

Thawing continues normally while the player is offline.
A player may return later and find:

**READY TO CRACK**
Ice waiting in their Pen.
Offline:

thawing progresses normally.
Online:

Night events can accelerate thawing.
This allows offline progress without making leaving the game the fastest strategy.


## 28. Visual Thawing

Ice becomes progressively more interesting as it thaws.
Example:

opaque frost
-> partial clearing
-> visible movement/silhouette
-> major cracks
-> READY TO CRACK
The player should repeatedly walk past Ice and think:

"That thing is almost ready."

## 29. Thawing Is Passive

The player cannot repeatedly tap to eliminate Thaw Time.

The timer exists to create:

anticipation + overlapping goals.
While waiting, the player can:
explore;
retrieve more Ice;
train Warmth;
manage creatures;
sell;
inspect the Archive;
wait for the next Great Frost.


## 30. Crack -> Crack -> Smash

When thawing completes:

**READY TO CRACK**
The player performs:

CRACK
CRACK
SMASH
There is:
no failure;
no timing grade;
no combo;
no accuracy requirement.
The interaction exists for tactile anticipation and payoff.


## 31. The Great Frost / Night Cycle

The world periodically enters:

Night / The Great Frost

This is a recurring server-wide transformation.
It is not a punishment.
Players are not required to return home.
Instead, it represents:

the magical frost reshaping the wilderness.

## 32. Great Frost Reset

When the Great Frost occurs:
- available/unclaimed shared wilderness Ice resets;
- new shared Ice is distributed;
- carried Ice remains safe;
- Pen Ice remains safe;
- Guarded-Ice encounters are cleared/rebuilt with the refreshed field;
- currently thawing Ice receives the configured launch/prototype thaw acceleration behavior.

If an Ice was being carried when the Frost began and its carrier fails during that already-running Frost transition, that exact dropped Ice survives the current transition. It becomes shared/available subject to the normal Great Frost Grab lock. A **future** Great Frost may remove it if it remains unclaimed.

The mechanical action may be simple.
The presentation should feel significant.

## 33. Great Frost Thaw Surge

Each Great Frost gives active Pen Ice:

a significant burst of thaw progress.
This creates a natural reason to remain online.
The player waiting for an Ice to finish can think:

"One more Frost and this might be ready."

## 34. Special Ice

Every configurable X Great Frost cycles, a:

**Special Ice**

appears somewhere in the shared wilderness.

It should be visually unmistakable and desirable.
Special Ice guarantees a **Rare-or-Legendary** opportunity while keeping the exact creature hidden.

First-pass rarity profile for every eligible Special Ice region:

```text
Rare        90%
Legendary   10%
```

Eligible regional outcomes:

```text
Ancient   -> Mammoth / Tyrannosaurus
Black     -> Manticore / Hraesvlgr
Meteor    -> Kirin / Nidhogg
```

Special Ice does not reveal the exact creature before thawing.
Players still have to:

```text
see it -> reach it -> retrieve it -> survive the return -> thaw it -> smash it open
```

Special Ice uses the same universal shared-Ice ownership/failure rules as every other Ice type.

If its carrier freezes, dies, resets/respawns, or disconnects before deposit, the **same Special Ice** drops at the last valid carrier position with its exact hidden reward, WeightMultiplier/Scale, and Special metadata preserved. Ownership clears and any player may rescue it.

If it remains unclaimed, a later Great Frost may remove it as part of the shared field.

## 35. Social Aspiration

Multiplayer does not require PvP or enemy farming to create social motivation.
Players should visibly advertise progression and create shared stories.

Examples:
- an advanced player races past at enormous Speed;
- someone carries a huge Meteor Ice toward camp;
- a carrier freezes and nearby players sprint for the exact dropped Ice;
- one player rescues another player's failed retrieval and completes the run;
- a neighboring Pen contains creatures you have never seen;
- a Legendary reveal creates visible effects;
an advanced player rides an enormous creature across the shared wilderness;
- everyone sees a Special Ice appear during the Great Frost.

The desired new-player reaction is:

> "How do I become THAT player?"

## 36. The Five Hero Moments

These moments are canonical production targets.
Hero Moment 1 - The First Great Frost
Timing: Early game, ideally within the first few minutes.
The sky changes.
Aurora intensifies.
Wind rises.
The wilderness transforms.

New Ice appears.
Something large or unusual may emerge in the distance.
Desired reaction:

"Wait... WHAT just happened?"

Hero Moment 2 - The Impossible-Looking Ice
Very early, the player sees something dramatically beyond their current capability.
A huge silhouette.
Strange runes.
An enormous piece of Ice.
The player cannot comfortably retrieve it yet.
Desired reaction:

"I NEED that."
This establishes long-term aspiration before the player has earned it.


Hero Moment 3 - The Barely-Made-It-Home Run
This is the recurring USP moment.
The player carries something valuable toward home.
Warmth gets dangerously low.
Presentation escalates:

frost -> stronger wind -> warning audio -> Hearth visible ahead.
They cross into safety with almost nothing remaining.
Desired reaction:

"HOLY SHIT, I MADE IT."
This moment must be memorable.


Hero Moment 4 - The Legendary Smash

A valuable Ice has been visible in the Pen for some time.
It becomes ready.

CRACK
CRACK
SMASH
The reveal gets disproportionate presentation:
explosive Ice break;
strong camera response;
sound sting;
runic/rarity VFX;
creature animation/pose;
major rarity treatment.
Desired reaction:

"NO WAY. I GOT IT."

Hero Moment 5 - Becoming the Endgame Player
The player equips a powerful mythical creature.
Their Speed increases dramatically.
They cross areas that once felt enormous in seconds.
A newer player watches them race past.
Desired internal reaction:

"I've become powerful."
Desired observer reaction:

"How do I become THAT guy?"

## 37. Hero Moment Progression Arc

Together, the Hero Moments form:

WORLD IS EPIC
First Great Frost
v
I WANT THAT
Impossible Ice
v
I SURVIVED THAT
Dangerous retrieval
v
I GOT THAT
Legendary Smash
v
I AM THAT
Endgame power fantasy
This emotional progression is a core part of the game.


## 38. Creature Roster - Launch Target

The launch target is **20 species**, organized as four signature creatures per geographic region.

| Region | Creature | Rarity | Base Income/s | Base Speed |
|---|---|---|---:|---:|
| Snowfield / Regular | Penguin | Common | $10 | 22 |
|  | Rabbit | Common | $12 | 26 |
|  | Seal | Common | $15 | 20 |
|  | Wolf | Uncommon | $30 | 31 |
| Frozen Pass / Thick | White Stag | Common | $100 | 34 |
|  | Bear | Uncommon | $200 | 26 |
|  | Sleipnir | Rare | $500 | 39 |
|  | Troll | Epic | $3,000 | 35 |
| Ancient Expanse / Ancient | Sabertooth | Common | $1,000 | 37 |
|  | Mammoth | Rare | $2,500 | 30 |
|  | IceSerpent | Epic | $7,500 | 44 |
|  | Tyrannosaurus | Legendary | $30,000 | 33 |
| Black Ice Hollow / Black | Giant Spider | Common | $10,000 | 40 |
|  | Dreadmare | Uncommon | $25,000 | 48 |
|  | Manticore | Rare | $60,000 | 44 |
|  | Hraesvlgr | Legendary | $300,000 | 50 |
| Meteor Reach / Meteor | Griffin | Common | $100,000 | 49 |
|  | Kirin | Rare | $250,000 | 52 |
|  | Phoenix | Epic | $600,000 | 50 |
|  | Nidhogg | Legendary | $3,000,000 | 46 |

The nine new launch creatures may use functional placeholder meshes during Day 11. Final asset-specific `ReferenceWeight`, `BaseVisualScale`, silhouette polish, proportions, and production models are finalized from the actual assets rather than invented in advance.

The rarity ladder remains:

```text
Common -> Uncommon -> Rare -> Epic -> Legendary
```

### Normal geographic Ice families

Normal Ice families are **region-exclusive**, not cumulative inheritance from earlier regions.

```text
REGULAR
80% Common   -> Penguin / Rabbit / Seal (uniform within Common)
20% Uncommon -> Wolf

THICK
60% Common   -> White Stag
25% Uncommon -> Bear
11% Rare     -> Sleipnir
 4% Epic     -> Troll

ANCIENT
60% Common    -> Sabertooth
25% Rare      -> Mammoth
11% Epic      -> IceSerpent
 4% Legendary -> Tyrannosaurus

BLACK
60% Common    -> Giant Spider
25% Uncommon  -> Dreadmare
11% Rare      -> Manticore
 4% Legendary -> Hraesvlgr

METEOR
60% Common    -> Griffin
25% Rare      -> Kirin
11% Epic      -> Phoenix
 4% Legendary -> Nidhogg
```

The advanced regions intentionally use comparable `60 / 25 / 11 / 4` opportunity bands even when the rarity labels represented by those slots differ.

### Economic identity

Income uses overlapping regional bands:
- the expected economy rises dramatically with each region;
- the previous region's apex can beat the next region's early results;
- the next region's upper results overtake it at equal Scale;
- an exceptional size roll may break the normal hierarchy.

Speed remains comparatively controlled because it directly changes expedition survival.

## 39. Creature Ownership States

Owned creatures are now **individual copies** rather than interchangeable species counts.

Each copy has a unique identity and at minimum preserves:
- CreatureGUID;
- CreatureID / species;
- inherited WeightMultiplier / SizeRoll.

From that data the game derives:
- visual Scale;
- final Pen Income;
- final Equipped Speed.

Owned copies may be:

**In Pen**  
Generate that copy's passive Cash value.

**Equipped**  
The selected active creature. It follows while unmounted and becomes the player's mount while Riding. It earns no Pen income.

**In Inventory**  
Owned but inactive.

Species discovery remains species-based. Owning or selling differently sized copies does not change whether the species has been discovered.

## 40. New Creature Routing

After reveal, the server creates a unique creature copy using the exact size roll inherited from the Ice.

If the Pen has room:
- assign that CreatureGUID to the first free active Pen position.

If the Pen is full:
- the CreatureGUID remains in Inventory.

Avoid unnecessary post-reveal menus.
The emotional high should not immediately become administrative work.

## 41. Equipped Creature

Players may Equip one individual creature copy.

If Equipped from the Pen:
- its Pen slot becomes empty;
- that copy stops generating Pen income;
- the exact copy keeps its Scale and stats;
- it begins in Following state at its inherited size;
- the player can Ride/Unride that same copy anywhere during exploration;
- Riding uses its own final Movement Speed; Following uses the player's base WalkSpeed.

Ride/Unride never reallocates the creature, never sends it back to Pen, and never changes economy ownership. Joining/respawning returns the Equipped creature to Following rather than restoring an old Riding state.

For readability, creature presentation should expose at least:

```text
SPEED <value>
PEN $<value>/s
```

`PEN $/s` is the copy's intrinsic Pen Income stat even while Equipped; it does not mean an Equipped creature is actively earning.

## 42. Selling

Creatures may be sold from valid owned states, but selling is intentionally **not** a meaningful progression engine.

Design role:

> **Sell = inventory cleanup + small consolation payout.**

Selling operates on a specific CreatureGUID because copies are no longer interchangeable.

The ownership decision becomes:

```text
Pen       = meaningful recurring Cash
Equip     = traversal Speed
Inventory = reserve / comparison
Sell      = cleanup + small bonus
```

Selling does not remove Frozen Archive discovery.
Exact SellValue numbers are a Day-14 balance decision and must remain low enough that selling does not compete with keeping strong Pen creatures. Size does not automatically receive the full `Scale^2` Pen-income multiplier when sold unless a later explicit balance revision approves it.

## 43. Frozen Archive

The Frozen Archive tracks species discovery, not individual copies.

Launch completion target:

```text
X / 20
```

Undiscovered entries appear as:
- silhouette / ???

Discovered entries show:
- creature;
- rarity;
- identity.

Individual copy Scale/Income/Speed belong to Inventory/Pen/Equipped presentation rather than Archive completion.
Selling all owned copies never reverses discovery.

The Archive should function as an advertisement for what remains undiscovered.

## 44. Economy

Launch has one currency:

**Cash**

Primary source:
- individual Pen creature income.

Secondary/minor source:
- low-value creature selling for inventory cleanup.

Primary sink:
- Hearth upgrades.

Pen income is copy-specific. Each species supplies BaseIncome and the creature's inherited Scale modifies the final value.
The rarity-only fixed-income model is superseded by this system.

The launch economy follows overlapping regional value bands rather than strict replacement. A jackpot from the previous region can remain economically relevant after the player reaches the next region, especially with a strong size roll.

No additional currencies are required at launch.

## 45. Recursive Progression

```text
Retrieve visually desirable Ice
        v
Awaken a unique creature copy
        v
Compare Size / Income / Speed
        v
Pen copies -> Cash
        v
Cash -> Better Hearth
        v
Better Hearth -> Much Faster Warmth Training
        v
More Warmth -> Survive Harsher Regions
        +
Better Equipped Copy -> Ride Farther / Cross Distance Faster
        v
Reach Stranger / Larger / Rarer Ice
        v
Chance at another jackpot copy
```

The systems should continually feed one another.

A rare gigantic copy should feel capable of compressing earlier progression in a memorable way without making deeper regions permanently trivial.

## 46. Productive Waiting


The player should rarely feel they are merely waiting.
While an Ice thaws, they can:
retrieve another;
permanently train Warmth;
earn Cash;
upgrade their Hearth;
manage creatures;
inspect their collection;
prepare for the next Great Frost.

Something should almost always be progressing.

## 47. Session Rhythm

A healthy session naturally alternates between:
Expedition
Retrieve something valuable.
Home
Deposit it, train, manage and watch Ice thaw.
Great Frost
Wilderness refreshes and Pen Ice accelerates.
Reveal
Smash ready Ice open.
Progression
Creature, Cash, Warmth or Speed improves.
Then:

something farther away becomes attractive.

## 48. Motivation to Go Farther

The player should repeatedly encounter:

something they want before they can comfortably obtain it.
Motivation comes from:
inaccessible-looking Ice;
undiscovered Archive silhouettes;
creatures seen on other players;
Special Ice;
strange later environments;
increasingly mythic creature possibilities.
The desired question is:

"What is out there that I still haven't seen?"

## 49. Motivation to Return

Launch does not depend on:
Daily Quests;
login streaks;
daily reward calendars.
Return motivation comes from unfinished progression:
Ice continuing to thaw offline;
missing Archive creatures;
unfinished Warmth progression;
desired Hearth upgrade;
regions the player still cannot comfortably reach;
future Great Frost cycles;
Special Ice opportunities.
A returning player may immediately discover:

something they brought home yesterday is now READY TO CRACK.

## 50. First Minutes

The opening should communicate the entire fantasy with minimal explanation.

**First expedition**  
Player sees nearby mysterious **shared** Regular Ice.  
Leaves safety.  
Warmth begins draining.  
Retrieves Ice.  
Returns home.  
Places it in the Pen.

**At home**  
Ice begins thawing.  
Player discovers Warmth training.  
Player can retrieve another Ice or remain briefly at home.

**First reveal**  
The first successfully recovered Ice becomes ready quickly enough to teach:

**CRACK -> CRACK -> SMASH**

Creature revealed.  
Equip teaches:

> better creature = faster movement.

**Early spectacle**  
Within the first few minutes, the player should also witness their first Great Frost and ideally see one aspirational Ice far beyond their current capability.

The player should know very early:

> the world gets much crazier than this.

### Multiplayer onboarding reliability

Onboarding must use the same shared Ice field as everyone else.

There is no private or duplicated onboarding Ice.
The onboarding layer may:
- point/highlight a suitable available shared Regular Ice;
- explain that another player may claim a shared opportunity first;
- point to another available Regular if the first one is taken;
- communicate the next Great Frost/world refresh if no suitable Regular opportunity is currently available.

This preserves the rule:

> Script the learning opportunity. Never script the excitement.

## 51. Prototype Purpose

The Week-1 prototype has completed its validation purpose.

It validated:
- the retrieval-first USP;
- big-number Warmth progression;
- Hearth acceleration;
- per-copy creature size jackpots;
- visible aspiration through deeper Ice tiers;
- Great Frost opportunity/reset behavior;
- the complete Survival Pressure package as a retrieval enhancer.

The Survival Pressure result is **PASS** and the full approved package S01-S06 is promoted into launch scope.

Persistence/offline thawing and multiplayer were intentionally production-phase requirements rather than Week-1 validation targets. Day 8 persistence is now complete and Day 9 multiplayer/personal-base work is in progress.

## 52. Prototype Success Questions

The prototype must answer:

- Does the player voluntarily seek another Ice after a reveal?
- Is retrieving Ice exciting rather than merely functional?
- Does low-Warmth return create tension?
- Does thawing create anticipation rather than annoyance?
- Does the player naturally find productive things to do while waiting?
- Does watching big-number Warmth growth feel satisfying?
- Does a better Hearth feel dramatically more productive?
- Does a better individual creature copy feel meaningfully faster/more valuable?
- Does visible Ice Scale create route-changing `I NEED THAT` moments?
- Does a giant Ice fulfilling its promise with a giant creature create a jackpot story?
- Do duplicate species remain desirable because individual copies differ?
- Do Recommended Warmth signs create informed risk-taking rather than hard gating?
- Does the Great Frost create a `one more cycle` feeling?

Most importantly:

> "I saw this absurdly huge Ice, barely got it home, and it became an enormous creature that completely changed my progression."

is stronger evidence than:

> "You hatch pets."

## 53. Bare-Minimum 3-Week Launch

Target:
- 20 creature species total target, four signature creatures per region;
- individual CreatureGUID copies;
- one inherited size/weight roll per copy;
- up to 5x visual Scale jackpots;
- 5 Ice types;
- one shared authoritative Ice field per server;
- shared carrier-failure drops/rescue/relay;
- multiple progression regions;
- Recommended Warmth signage;
- large-number uncapped Warmth;
- Hearth training progression;
- species BaseIncome/BaseSpeed with size-derived final stats;
- 7 Pen levels with 4-10 active Pen creatures;
- 1-second aggregate Pen income;
- unlimited Pen thawing;
- offline thaw progress;
- Great Frost cycle;
- Great Frost thaw acceleration;
- Special Ice;
- one universal survival tool;
- stationary Frost Sprites across all region tiers;
- Guarded Ice;
- region-scaled Sprite Warmth damage;
- Equipped-creature Vitality/Frosted state;
- breakable route obstacles;
- 1 Equipped creature with Following/Riding states;
- Ride/Unride during exploration;
- mounted traversal using copy-specific FinalWalkSpeed;
- Inventory;
- Sell;
- Frozen Archive;
- 1 currency;
- persistence;
- multiplayer;
- one continuous world;
- hero-moment presentation.

## 54. Explicitly Not Required for Launch

Do not add unless testing proves otherwise:
- pickaxes/mining systems;
- creature-specific traversal abilities;
- bosses;
- roaming/pathfinding/chase enemy AI;
- multiple weapon classes;
- general PvP combat beyond the approved wilderness pre-Grab contest knockback;
- weapon rarity, durability, upgrades, or inventory;
- combos, blocking, heavy attacks, or stamina;
- combat XP, enemy levels, enemy drops, or enemy currency;
- autonomous pet combat AI or independent creature combat;
- Player HP;
- permanent creature death;
- Wood/Stone/material currencies;
- crafting or recipe systems;
- separate Speed training;
- literal treadmill gameplay;
- Luck stat progression;
- extra currencies;
- hunger;
- prestige/rebirth;
- Daily Quests;
- login calendar;
- unrelated randomized per-copy combat stats;
- Thaw Slot upgrades;
- separate Thaw Machine;
- tap-to-reduce-Thaw-Time;
- complicated quest/lore systems.

**Approved per-copy exception:** variation from the single inherited Ice size/weight roll is canonical. It may modify visual Scale, Pen Income, and Equipped Speed. It does not authorize randomized Damage, Defense, levels, skills, or arbitrary affixes.

**Approved survival/mount exception:** the validated narrow Survival Pressure package is launch-canonical, and the player's one universal survival attack may be presented as a tool swing on foot or a mechanically identical Mounted Strike while Riding. This does not authorize autonomous pet combat, creature Damage stats, or mount-specific combat progression.

Survival supports retrieval. It is not a separate progression economy.

## 55. Scope Priority

If production becomes constrained, protect:
1. Dangerous retrieval
Warmth + Ice + return trip + freeze/reset.
2. Creature desirability
Strong silhouettes and appealing creatures.
3. Thaw / Smash
Anticipation and reveal payoff.
4. Progression
Warmth training + Hearth + Speed.
5. The Five Hero Moments
Especially Great Frost, dangerous return and major reveal.
6. Night / Special Ice

7. Persistence / Multiplayer reliability
Cut environmental complexity and secondary presentation before adding new gameplay
systems.

## 56. USP Filter

Before adding any launch feature, ask whether it strengthens at least one of:

1. I saw something I desperately wanted.2. I barely managed to bring it
home.3. I couldn't wait to discover what was inside.
If it does not meaningfully strengthen one of those and adds production cost:

it probably does not belong in the three-week launch.

## 57. Core Design Rules

The verb should be boringly simple. The consequence should be spectacular.

Script the learning opportunities. Never script the excitement.

The reward should advertise the next reward.

Better Hearth = faster Warmth progression.

Better creature = obviously faster traversal.

More Warmth = more expedition endurance.

Farther wilderness = stranger possibilities and stronger environmental threat.

All spawned Ice = one shared server opportunity.

Ice claim = size-scaled hold, not instant pickup; first valid completed hold wins.

Carrier Commitment = move / jump / Ride-Unride / Drop / home deposit only.

Intentional Drop and carrier failure both preserve the exact Ice and return it to the shared world; no reroll.

The Great Frost creates opportunity, not punishment.

Survival pressure must make the Ice journey more memorable, not replace it with enemy farming.

Waiting should happen while another form of progression is available.

No hard gate where a recommendation can create a risk decision instead.

Do not add another system when an existing system can create the desired feeling.

When the game needs more epicness, make an existing moment bigger before adding another mechanic.

## 58. Canonical Experience Identity

Thaw A Creature is the game where you see enormous mysterious Ice deep inside a supernatural frozen wilderness, decide whether you're strong enough to risk the trip, push through cold and authored survival threats, race the Ice home before your Warmth runs out, watch it thaw among the creatures you've already awakened, and finally smash it open to discover what was trapped inside.

In multiplayer, that Ice is real shared world state: another player can beat you to it, watch you carry it, rescue it if you fail, or race you toward a dropped opportunity.

Progression should continually transform:

> "I can't reach that."

into:

> "I can get that now."

and eventually:

> "I am the player other people see racing toward the impossible Ice."

That is the experience the rest of the project should now protect.
