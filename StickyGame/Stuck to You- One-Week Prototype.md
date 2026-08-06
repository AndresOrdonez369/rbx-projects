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
- 

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

## How the Win System works

A Win is basically a currency that can be used to obtain upgrades. 

#### How to obtain a Win:

A win pedestal can be found after every cleared zone, and it has a visible number on top of it to indicate the amount of wins the player will receive if they step into it. When the player steps into it, they’re granted the amount of wins the pedestal displayed, and are teleported back to the lobby.

**Claiming a pedestal does not reset Stickiness.** The player keeps their Stickiness, Level and equipped Sticky Wrap; only Rebirth resets those. What the pedestal does reset is the cleared-zone state, so the route has to be walked again before the same pedestal pays out a second time.

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
| Quantum Glue | +50 | 75 Wins |
| Nova Glue | +120 | 150 Wins |
| Galaxy Glue | +300 | 300 Wins |
| Infinity Glue | +750 | 600 Wins |

> Los cuatro últimos se añadieron el 2026-08-06 para llenar las ocho placas del lobby. Cada peldaño multiplica la ganancia por ~2,5 (la misma pendiente que traían los cuatro primeros) y cuesta el doble que el anterior, así que comprar el siguiente vale lo mismo que todo lo comprado hasta entonces. Son valores de arranque: viven en `GameConfig.StickyWraps` y se ajustan con playtest.

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
| Basic Trail | +1.5 | +10% |
| Green Trail | +2.0 | +15% |
| Blue Trail | +2.5 | +20% |
| Golden Trail | +4.0 | +30% |

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

## UI and HUD Refs

+1 keyboard Escape

+1 Muscle Evolution 

+1 Pickaxe swing

+1 Monkey Escape

---

## Prototype Scope

### Include

- 3 - 5 linear zones
- One Size stat
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
