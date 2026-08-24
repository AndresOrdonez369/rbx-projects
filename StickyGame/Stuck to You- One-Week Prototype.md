# Stuck to You: One\-Week Prototype

### Experience Summary

**Genre:** One-verb progression/growth simulator  
**Target audience:** Roblox players ages 9–17  
**Prototype duration:** 3–5 minutes per run  
**Core fantasy:** Everything the player touches sticks to them, creating an increasingly enormous pile.

> **Touch smaller objects, grow your pile, and become big enough to absorb the giant object blocking your path.**

---

## Core Loop

> **Touch → Stick → Gain Stickiness → Absorb the blocker → Advance**

- Objects are collected automatically on contact.
- Every object immediately increases **stickiness**
- Collected objects visibly attach to the player.
- Larger objects require a higher Stickiness.
- Each zone ends with a giant collectible object blocking the route.

No pickup button, inventory, selling area, combat, or secondary interaction is required.

---

## Main Stat: **Stickiness**

**Stickiness** is the only player-facing progression stat.

Example HUD:

> **Stickyness: 420**  
> **BED: 420 / 500**

Although the visual fantasy is about growing a pile, “**Stickiness**” is easier to understand than Mass or Pile Size.

### Object States

- **Green text:** Enough stickiness
- **Red Text:** Not enough stickiness

Every object has a number on top of it, and it describes how much stickiness is required to pick it up.

---

## Progression Obstacles

Every obstacle must follow the same collection rule.

| Zone | Collectibles | Blocking object |
| --- | --- | --- |
| Toy Room | Blocks, crayons, toy cars | Toy Chest |
| Bedroom | Books, lamps, chairs | Bed |
| Kitchen | Cups, stools, appliances | Refrigerator |
| Neighborhood | Large household objects | Exterior landmark |

Once the player reaches the required Stickiness, they touch the blocker, absorb it, and immediately open the next area.

---

## Level Structure

The prototype uses one clear horizontal route:

> **Room 1: Toy Room → Room 2: Bedroom → Room 3: Kitchen → Room 4: Neighborhood **

Design requirements:

- Next blocker visible early in each zone
- Collectible trail/area leading toward it
- One pickup every 0.2–2 seconds
- Every collectible object respawns every 2 seconds. That way the player can farm in any spot.
- No branching paths or searching
- Approximately 30 seconds per zone
- If the player has enough stickiness, they can absorb the door/object blocking the next zone.

---

## Gratification

### Every Pickup

- Object visibly sticks
- Size number increases
- Pickup sound plays
- Orb of stuck objects expands
- Progress toward the blocker updates

### Every Zone

- Giant blocker becomes collectible
- Major attachment animation plays
- New object category unlocks
- Next area opens immediately

The player should visibly grow every 10–20 seconds.

---

## Long-Term Retention Direction

After the prototype, progression can expand through the **Sticky Collection**:

- Automatically record unique absorbed objects
- Complete themed collections
- Unlock permanent Sticky Forms
- Display largest collected landmarks
- Add new worlds with larger object scales

These systems must remain automatic and should not interrupt movement.

---

## How items are spawned

Every zone has a sort of “Room Manager”, and it ensures that each zone has a pool of certain objects that are spawned inside that zone.   
Every object has a certain stickiness that needs to be met before picking it up.

---

## Art assets

Due to time constraints, focus the art efforts on creating worlds that follow a specific theme, with assets that fit into that theme.

| World | Small Collectibles | Medium Collectibles | Large Collectibles | Landmark / Blockers |
| --- | --- | --- | --- | --- |
| 1. **Forest** | Flowers, mushrooms, sticks, acorns, crystals, small rocks | Bushes, logs, barrels, treasure chests, tree stumps, stone statues | Large trees, boulders, giant mushrooms, wagons, ancient pillars | **Giant Tree**, **Ancient Stone Gate**, **Forest Shrine** |
| 1. **Desert Ruins** | Pots, bones, coins, scarabs, small crystals, bricks | Sarcophagi, statues, treasure chests, obelisks, broken columns | Giant statues, stone gates, large obelisks, ruined towers | **Pharaoh Statue**, **Temple Gate**, **Ancient Pyramid Piece** |
| 1. **Volcano** | Coal, obsidian shards, fire crystals, skulls, volcanic rocks | Crystal clusters, lava rocks, mine carts, magma eggs, stone pillars | Giant crystals, lava boulders, ancient furnaces, magma statues | **Giant Lava Crystal**, **Volcanic Guardian Statue**, **Volcano Core** |

---

## How the Win System works

A Win is basically a currency that can be used to obtain upgrades. 

#### How to obtain a Win:

A win pedestal can be found after every cleared zone, and it has a visible number on top of it to indicate the amount of wins the player will receive if they step into it. When the player steps into it, they’re granted the amount of wins the pedestal displayed, and are teleported back to the lobby.

The more the player advances, the more wins the pedestals contain. (After clearing Zone 1, the player finds a Win Pedestal that awards 1 Win if they step over it. After clearing Zone 2, the Win Pedestal awards 3 wins. After clearing Zone 3, the Win Pedestal awards 10 wins, etc.)

####   
What the wins are used for

- Wins are used to unlock Sticky Wraps
- Wins are used to unlock new maps
- Wins can be used as a currency to unlock additional content in the future, like auras or trails.
- Wins do not reset after rebirth

---

## How Sticky Wraps work

The equipped **Sticky Wrap** determines how much Stickiness the player gains whenever they absorb an object.

| Sticky Wrap | Base gain per object | **Win Price** |
| --- | --- | --- |
| Basic Glue | +1 | 0 (already equipped) |
| Strong Glue | +3 | 3 Wins |
| Super Glue | +8 | 10 Wins |
| Cosmic Glue | +20 | 30 Wins |

### How to unlock: 

Purchase them using wins by stepping into the respective plate inside the lobby. When the player purchases any Sticky Wrap, it is equipped immediately.  
If the player wishes to change their equipped wrap, they need to step into one of the different plates inside the lobby once again.


Sticky Wraps are the equivalent of:

- Bodies in **+1 Muscle Evolution**
- Pickaxes in **+1 Pickaxe Swing Escape**

They should visibly change the player’s sticky coating, material, or attachment effect.

---

## How Trails work

The equipped trail affects multiple stats, such as the multiplier and movement speed.

| Trail | Multiplier addition | **Movement speed bonus** | **Win Price** |
| --- | --- | --- | --- |
| Basic trail | +1.5 | 10% | 15 wins |
| Green Trail | +2.0 | 15% | 30 Wins |
| Blue Trail | +2.5 | 20% | 50 Wins |
| Golden Trail | +4.0 | 30% | 75 Wins |

In addition to the stats the trail provides, it also has a visible effect any time the player moves, creating a visible short trail that disappears after X time.


Trails are bought via a button on the HUD that displays an additional screen, with each of them costing X amount of Wins.

---

## How Auras work

The equipped aura affects multiple stats, such as the multiplier, movement speed, and pickup radius. 

| Trail | Stickiness Multiplier | **Movement speed bonus** | **Pickup radius** | **Win Price** |
| --- | --- | --- | --- | --- |
| Green Aura | x1.5 | 10% | 5% | 20 wins |
| Blue Aura | x2.0 | 15% | 10% | 50 Wins |
| Purple Aura | x2.5 | 20% | 15% | 75 Wins |
| Golden Aura | x3.0 | 25% | 20% | 100 Wins |

In addition to the stats the aura provides, it also has a visible effect on the player, and it’s visible at any moment.

Auras are bought via a button on the HUD that displays an additional screen, with each of them costing X amount of Wins.

---

## How Rebirth Works

The player has a capped level depending on their current rebirth (Rebirth 0: Level 20, Rebirth 1: 25, etc.), and each rebirth unlocks a new ceiling for the level cap. 

The rebirth is unlocked when the player reaches the required Level.

Rebirthing:

- Resets Stickiness
- Resets Level to 1
- Grants a permanent `+0.5x` Stickiness multiplier
- Makes the next run faster
- Resets unlocked Sticky wraps
- Raises the level cap

---

## How Player Level Works

Level represents how far the player has progressed during the current Rebirth.

- Stickiness automatically fills the Level bar.
- Level does not use a separate XP source.
- Gaining Stickiness increases Level progress.
- Level resets to `1` after Rebirth.
- Reaching the current Level cap unlocks Rebirth.
- Every 5 (or X amount) levels, the player gains a small increase in movement speed and pickup radius.

---

## How the Stickiness Stat Is Affected

**Stickiness** determines which objects the player can collect.

Higher Stickiness allows larger objects and progression blockers to stick to the player. Stickiness also fills the Level bar and determines the player’s progress toward Rebirth.

### 1. Sticky Wrap

The equipped **Sticky Wrap** determines the player’s base Stickiness gain whenever they absorb an object.

| Sticky Wrap | Base gain per object |
| --- | --- |
| Basic Glue | +1 |
| Strong Glue | +3 |
| Super Glue | +8 |
| Cosmic Glue | +20 |

Sticky Wraps are the equivalent of:

- Bodies in **+1 Muscle Evolution**
- Pickaxes in **+1 Pickaxe Swing Escape**

They should visibly change the player’s sticky coating, material, or attachment effect.

---

### 2. Trail Multiplier Addition

The equipped **Trail** adds a fixed amount to the player’s base Stickiness multiplier.

The Trail value is **not multiplied independently**. Instead, it is added to the Rebirth multiplier.

| Trail | Multiplier addition | Movement speed |
| --- | --- | --- |
| No Trail | +0 | +0% |
| Basic Trail | +0.5 | +10% |
| Green Trail | +1.0 | +15% |
| Blue Trail | +1.5 | +20% |
| Golden Trail | +3.0 | +30% |

The movement-speed bonus helps the player collect objects faster but does not directly increase Stickiness gained per object.

---

### 3. Aura Multiplier

The equipped **Aura** multiplies the Stickiness gain after the Rebirth multiplier and Trail addition have been combined.

| Aura | Stickiness multiplier | Movement speed | Pickup radius |
| --- | --- | --- | --- |
| No Aura | 1.0x | +0% | +0% |
| Green Aura | 1.5x | +10% | +5% |
| Blue Aura | 2.0x | +15% | +10% |
| Purple Aura | 2.5x | +20% | +15% |
| Golden Aura | 3.0x | +25% | +20% |

Movement speed and pickup radius improve collection efficiency but do not directly change the formula.

---

### 4. Rebirth Multiplier

Each Rebirth permanently adds `+0.5x` to the player’s base Stickiness multiplier.

```
Rebirth Multiplier = 1 + (Rebirths × 0.5)
```

| Rebirths | Rebirth multiplier |
| --- | --- |
| 0 | 1.00x |
| 1 | 1.50x |
| 2 | 2.00x |
| 3 | 2.50x |
| 10 | 6.00x |

The Trail addition is added to this value.

---

### 5. Stickiness Gain Formula

```
Base Multiplier =
Rebirth Multiplier + Trail Addition
```

```
Stickiness Gain =
Sticky Wrap Base Gain
× Base Multiplier
× Aura Multiplier
```

Combined formula:

```
Stickiness Gain =
Sticky Wrap Base Gain
× [1 + (Rebirths × 0.5) + Trail Addition]
× Aura Multiplier
```

#### Example

The player has:

- Strong Glue: `+3`
- Rebirth 2: `2.0x`
- Blue Trail: `+2.5`
- Blue Aura: `2.0x`

```
Base Multiplier = 2.0 + 2.5
Base Multiplier = 4.5x

Stickiness Gain = 3 × 4.5 × 2.0
Stickiness Gain = 27 Stickiness per object
```

Decimal values should be stored internally, while the HUD may display rounded values.

---

### 6. Player Level

Level represents how far the player has progressed during the current Rebirth.

- Stickiness automatically fills the Level bar.
- Level does not use a separate XP source.
- Gaining Stickiness increases Level progress.
- Level resets to `1` after Rebirth.
- Reaching the current Level cap unlocks Rebirth.
- Every 5 (or X amount) levels, the player gains a small increase in movement speed and pickup radius.

---

### 7. Revised Progression Structure

#### Stickiness

Determines which objects the player can collect.

> Higher Stickiness allows larger objects to stick to the player.

#### Stickiness Gain

```
Sticky Wrap Base Gain
×
(Rebirth Multiplier + Trail Addition)
×
Aura Multiplier
```

Stickiness gain is affected by:

- Equipped Sticky Wrap
- Current Rebirth count
- Equipped Trail
- Equipped Aura

#### Level

Represents the player’s progress during the current Rebirth.

Stickiness automatically fills the Level bar, with no separate XP system.

#### Rebirth

Unlocked when the player reaches the required Level.

Rebirthing:

- Resets Stickiness
- Resets Level to `1`
- Resets unlocked Sticky Wraps
- Grants a permanent `+0.5x` Rebirth multiplier
- Raises the Level cap
- Makes future progression faster


---

## How the Rest Zone Works

The **Sticky Rest Zone** is an AFK area located in the lobby. While the player remains inside, lost objects automatically stick to them, granting **Stickiness** and filling the Level bar.

Rest Zones provide an alternative progression method for players who prefer to remain AFK. Higher-tier Rest Zones can eventually become more efficient than active collection for gaining Stickiness, rewarding players for unlocking stronger automation.

- Stickiness is granted once every `X` seconds.
- Sticky Wraps, Trails, Auras, and Rebirth bonuses affect the amount gained.
- The player can reach their current Level cap while AFK.
- Rebirth must still be activated manually.
- Rest Zones do not grant Wins, clear zones, or unlock maps.
- Moving outside the Rest Zone immediately stops automatic progression.

### Rest Zone Stickiness Formula

```
Normal Stickiness Gain =
Sticky Wrap Base Gain
× (Rebirth Multiplier + Trail Addition)
× Aura Multiplier
```

```
Rest Zone Gain per Tick =
Normal Stickiness Gain
× Rest Zone Multiplier
```

The player receives the calculated amount every `X` seconds while inside the Rest Zone.

### Rest Zone Progression

There are multiple Sticky Rest Zones. Each zone has an unlock requirement and provides a stronger Stickiness multiplier.

| Sticky Rest Zone | Rest Zone multiplier | Requirement |
| --- | --- | --- |
| Zone 1 | 1.00x | None |
| Zone 2 | 1.50x | Reach Rebirth 1 |
| Zone 3 | 3.00x | Reach Rebirth 5 |
| Zone 4 | 5.00x | Robux purchase |
| Zone 5 | 10.00x | Robux purchase |

This creates an automation progression loop:

> **Play actively → Earn Wins and Rebirths → Unlock stronger Rest Zones → Gain Stickiness faster while AFK → Return to Rebirth and progress again**

Active gameplay remains necessary for earning Wins and accessing permanent content, while Rest Zones provide the most efficient way to progress Stickiness and Levels later in the metagame.

---

## How the World Event System works

**World Events** are temporary server-wide modifiers that change the environment and provide bonuses to all players on the server.

### When Events Happen

Events can start in three ways:

- **Automatic Events:** Trigger randomly every **10–15 minutes** while a server is active.
- **Scheduled Events:** Trigger at specific times for updates, weekends, or special occasions.
- **Admin Events:** Developers can activate these manually for community events or Admin Abuse sessions.

For the initial version, use **Automatic Events** as the default system.

**Recommended duration:** `5 minutes`  
**Recommended cooldown:** `10–15 minutes` between events.

Only **one World Event** should normally be active at a time.

### Event Start

When an event begins:

- A server-wide announcement appears.
- A countdown shows how long the event will remain active.
- Sky, Lighting, particles, and environmental VFX change.
- The corresponding gameplay modifier becomes active immediately.
- Players already inside Rest Zones also receive the event bonus.

Example:

> **STICKY STORM!**  
> **2X STICKINESS — 5:00**

### Example Events

| Event | Effect | Color of the sky |
| --- | --- | --- |
| Sticky Storm | x2 Stickiness | Intense Green |
| Golden Goo | x2 Wins | Intense Gold |
| Super Sticky | x3 Stickiness | Intense Magenta |
| Object Rain | Increased object spawn rate | Aquamarine |
| Magnetic Madness | x2 Pickup Radius | Red |
| Hyper Speed | x2 Movement Speed | Rainbow (Changes color periodically) |

### Event Formulas

**Stickiness**

`Event Stickiness = Normal Stickiness Gain × Event Stickiness Multiplier`

**Wins**

`Final Wins = Base Wins × Permanent Win Multiplier × Event Win Multiplier`

**Pickup Radius**

`Final Pickup Radius = Base Radius × (1 + Aura Bonus) × Event Radius Multiplier`

**Movement Speed**

`Final Speed = Base Speed × (1 + Trail Bonus + Aura Bonus + Permanent Bonuses) × Event Speed Multiplier`

Any inactive event multiplier defaults to `1.0x`.

### Event End

When the timer reaches `0`:

- Gameplay modifiers are removed.
- Sky and Lighting return to the default world settings.
- Event VFX disappear.
- A short **“Event Ended”** notification appears.

Events do not reset player progress when they end.

### Design Rule

Events should temporarily make progression feel significantly faster without changing the core gameplay.

> **Same gameplay, temporarily much stronger rewards.**

The system should be data-driven so new events can be created mainly by changing the **name, duration, visuals, modifier type, and multiplier**.


---

## Moving Platform Challenge System

### Objective

Provide reusable skill-based obstacle sections that can be inserted into any existing zone without changing the game’s World, zone, blocker, or Win progression structure.

A zone may contain:

- No moving-platform challenge.
- One challenge.
- Multiple challenges with different configurations.

### Zone Integration

```
Zone
├── Geometry
├── Collectibles
├── Blockers
└── Challenges
    └── MovingPlatformChallenge
        ├── StartArea
        ├── EndArea
        ├── FailVolume
        └── Lanes
            ├── Lane1
            ├── Lane2
            └── Lane3
```

The challenge does not receive its own:

- `ZoneId`
- Win reward
- Finish pedestal
- Blocker progression
- Saved checkpoint

It remains part of its parent zone.

### Core Behavior

1. The player enters an existing zone.
2. The challenge appears as one section of that zone’s route.
3. The player crosses moving platforms to reach the remaining area.
4. Reaching the `EndArea` completes the physical challenge.
5. The player continues through the same zone normally.

The zone’s existing blocker and Win pedestal remain authoritative.

### Failure Behavior

If the player touches the challenge’s `FailVolume`:

- The player returns to the beginning of the current World.
- No checkpoint inside the challenge is saved.
- Stickiness, Wins, Wraps, Trails, Auras, Levels, and Rebirths are preserved.
- The challenge does not reset the player’s economy or progression.
- The server resolves the return position using the current World’s `StartZoneId`.

### Roblox Configuration

Suggested tags:

- `MovingPlatformChallenge`
- `MovingPlatform`
- `MovingPlatformFailVolume`
- `MovingPlatformEndArea`

### Challenge attributes:

- `ChallengeId`
- `Enabled`
- `DifficultyPreset`
- `ParentZoneId`

### Platform attributes:

- `LaneIndex`
- `Direction`
- `Speed`
- `TravelDistance`
- `Spacing`
- `PhaseOffset`

### Technical Architecture

`MovingPlatformService`:

- Discovers embedded challenges.
- Moves and recycles platforms.
- Detects failures.
- Validates successful crossings.
- Returns failed players to the World start.
- Records attempts and completion times.

`MovingPlatformController`:

- Handles visual smoothing.
- Displays movement indicators.
- Controls local sounds, effects, and camera feedback.

This structure allows the same challenge system to be inserted into Forest, Desert, or Lava zones while using different platform models, movement presets, and visual themes.

---

## Monetization

Monetization should accelerate the existing progression loop without introducing a separate paid progression system.

### Permanent Gamepasses

- **Permanent x2 Wins:** Permanently doubles Wins received from Win Pedestals. It appears as a button on the HUD, and as a giant trophy in the lobby. Both open the same purchase pop-up.  
- **Permanent Speed Boost:** Permanently increases player movement speed by X amount. It appears as a button on the HUD.

---

### Premium Rest Zones


- Unlocks access to higher-efficiency AFK Rest Zones.
- Multiple premium rest zones have different prices
- If the player has not bought a Premium Rest Zone, then it cannot be used. 
- When the player approaches any premium rest zone that’s not been purchased, a pop-up appears to confirm the purchase.
- The price of the premium rest zone should be visible over it.

---

### Premium Sticky Wraps


- The main difference with the standard Sticky Wraps is that these do not reset after performing a rebirth.
- These are a 1 time purchase
- They are equipped in the exact same way as the rest of Sticky Wraps
- When the player approaches any premium Sticky Wrap that hasn’t been purchased, a pop-up appears to confirm the purchase.
- The price of the Premium Sticky Wraps should be visible over it. Alongside the text to indicate how much stickiness is awarded.

---

### Double Win Plates


- An additional win plate that can be found at the side of each win plate at the end of each zone.
- These Double Win Plates have a different color.
- These Double Win Plates have their price visible above them. 
- The Double Win Plates are repeatable purchases.

- If the win plate found after completing zone 4 gives the player 10 Wins, a Double Win Plate can be found at the side, which gives 20 wins. 
- They work the exact same way as the normal Win Plate.

---

### Developer Products

Repeatable purchases can provide immediate progression:

- **Skip Rebirth:** Instantly completes the current Rebirth and grants its permanent multiplier; keep your current stats.   
- **Stickiness Packs:** Immediately grants a fixed amount of Stickiness. These can be found as a button in the HUD under the level bar. Each one has a different Robux Cost.  
- **Trails and Auras Robux cost: **Trails and auras should have the option to be able to be purchased with Robux, separate from the cost of Wins.  
- **Temporary Boosts:** Temporarily increase Stickiness or Win gain for X amount of minutes.

### Monetization Rule

Paid upgrades should make progression **faster or more convenient**, but should continue using the same core systems as free players.

> **Free players progress through collecting, Wins, upgrades, and Rebirths. Paying players accelerate those same loops.**

---

## UI and HUD Refs

+1 keyboard Escape

+1 Muscle Evolution 

+1 Pickaxe swing

+1 Monkey Escape

---

## Icon Refs

+1 keyboard Escape


---

## Thumbnail Refs

### Things to Keep in mind:

- The most popular Roblox Character is called Bacon Hair  

- The second most popular Roblox Character is the Noob  


- It’s incredibly important to add expressions to the characters, as seen in the references.

---

## Prototype Scope

### Include

- 3 - 5 linear zones
- Stickiness stat
- Rebirth system (Falta botón y mostrar info de UI)
- Win System (Podemos ganar wins, pero no tenemos donde gastarlas. Implementar Sticky wrap que se compran con wins)
- Sticky Wraps (Falta. Se hace hoy)
- Automatic object collection
- Collectible objects
- Visible attachment system
- 3 - 5 giant blockers
- Basic HUD and object requirements (Siguiente semana)
- Mobile controls
- Multiplayer object availability 
- Basic analytics (Siguiente semana)
- Rest zone (Falta definir, posiblemente siguiente semana)
- Leaderboards 

---

## Prototype Validation

The prototype succeeds when:

- Players collect their first object within 10 seconds.
- Players understand that collecting increases Size.
- Players understand why the blocker cannot yet be absorbed.
- Average time between pickups remains below three seconds.
- At least 70% reach the Bedroom.
- At least 40% complete the Neighborhood.
- Players remain motivated to see the next larger object.

## Final Product Rule

> **Everything collectible follows one rule: it sticks when the player is big enough.**

Any feature that complicates or interrupts that rule should remain outside the one-week prototype.


---

## Ideas sin validación

  
Rest Zone - Puede ser un threadmill que tiene varios canales, así el player se mueve de izquierda y derecha para agarrar más puntos.
