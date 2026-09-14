# \+1 Sticky Charms System

# Charms System

## Feature Summary

Charms are permanent, collectible and equipable objects that provide passive gameplay bonuses.

Players can own multiple copies of the same Charm and equip those copies simultaneously. Charms and their quantities persist after Rebirth, death, world changes and rejoining the experience.

The system adds a long-term progression layer beyond Glues, Trails and Auras.

## Player Goals

- Collect every Charm.
- Acquire duplicate copies of valuable Charms.
- Build specialized loadouts.
- Improve progression through passive bonuses.
- Return regularly to inspect the rotating shop.
- Optimize loadouts using different bonus combinations.

## Acquisition Methods

Every Charm can be purchased using either:

- Wins.
- Robux through a Developer Product.

Both methods grant one permanent copy of the selected Charm.

The player does not need to pay both costs. Buying with Wins or Robux produces the same item and increases its owned quantity by one.

## Charm Inventory

The inventory contains two separated areas.

### Equipped Charms

- Displayed in a vertical column.
- Each equipment slot contains one Charm copy.
- Duplicate copies can occupy multiple slots.
- The same Charm icon may appear more than once.
- The player can only equip as many copies as they own.
- The initial equipment limit is 3 slots.
- Selecting an equipped Charm unequips that specific copy.

Example:

```
Equipped
[Slime Heart]
[Slime Heart]
[Lucky Coin]
```

### Available Charms

- Displayed horizontally or in a scrollable grid.
- Each Charm type appears only once in the grid.
- A quantity badge displays the number of unequipped copies.
- Selecting a Charm equips one available copy.
- When all slots are occupied, the player selects which equipped Charm to replace.

Example:

```
Slime Heart ×5
Equipped: 2
Available: 3
```

### Inventory Actions

- `Equip`: Equips one available copy.
- `Unequip`: Removes one selected copy.
- `Equip Best`: Calculates and equips the strongest available loadout.
- `Remove All`: Unequips every Charm.
- `Delete`: Not recommended for the initial version.
- `Lock`: Optional future feature that protects important copies.

`Equip Best` must account for duplicates and be calculated server-side.

## Charm Information Pop-up

Hovering over a Charm on PC—or tapping/holding it on mobile—displays an information card.

The pop-up contains:

- Charm name.
- Icon.
- Rarity.
- Bonus category.
- Effect per copy.
- Owned quantity.
- Equipped quantity.
- Combined equipped effect.
- Wins price.
- Robux price.
- Current status.

Example:

> **Slime Heart**  
> Epic Charm  
> +12% Stickiness per copy  
> Owned: 5  
> Equipped: 2  
> Active bonus: +24% Stickiness

The pop-up must reposition automatically to remain within the screen boundaries.

## Duplicate Rules

- Every purchase grants exactly one copy.
- Players can own unlimited copies unless a future inventory limit is introduced.
- Multiple copies can be equipped simultaneously.
- Equipped copies cannot exceed owned copies.
- Duplicate effects stack additively.
- Each equipped copy consumes one equipment slot.

Server validation:

```
EquippedCopies <= OwnedCopies
```

Example:

| Equipped Charm | Copies | Effect per copy | Combined effect |
| --- | --- | --- | --- |
| Slime Heart | 3 | +12% Stickiness | +36% Stickiness |
| Tiny Magnet | 2 | +5% Collection Range | +10% Collection Range |
| Eternal Moon | 2 | +35% AFK Rewards | +70% AFK Rewards |

## Bonus Categories

| Category | Effect |
| --- | --- |
| Stickiness | Increases Stickiness obtained from collected objects |
| Wins | Increases Wins received from Win Plates |
| Collection Range | Increases the distance from which objects can be collected |
| AFK Rewards | Increases Stickiness earned inside Rest Zones |
| Rebirth Bonus | Increases the multiplier granted by the next Rebirth |

### Rebirth Bonus Calculation

`Rebirth Bonus` modifies only the multiplier granted by the Rebirth action. It does not repeatedly multiply the player’s complete historical multiplier.

Example:

```
Base Rebirth reward: +2.0×
Equipped Rebirth Bonus: +12%
Final Rebirth reward: +2.24×
```

## Effect Stacking

Duplicate bonuses stack additively.

```
Copy 1: +12% Stickiness
Copy 2: +12% Stickiness
Copy 3: +12% Stickiness

Final bonus: +36% Stickiness
```

All Charm bonuses should be applied after the base reward has been calculated and before temporary paid boosts where possible.

Recommended order:

```
Base Reward
× Glue
× Rebirth Multiplier
× Charm Bonus
× Temporary Boost
× Game Pass
```

The exact order must remain centralized in the economy configuration to prevent different systems from calculating rewards differently.

## Equipment Limit

The initial limit is 3 equipped Charms.

With three slots, the maximum bonuses obtainable using three identical Mythic copies are:

| Category | Mythic per copy | Three equipped copies |
| --- | --- | --- |
| Stickiness | +20% | +60% |
| Wins | +18% | +54% |
| Collection Range | +30% | +90% |
| AFK Rewards | +35% | +105% |
| Rebirth Bonus | +12% | +36% |

If additional equipment slots are introduced, these values must be reviewed before release.

## Charms Shop

The shop displays a rotating selection of Charms.

Each offer shows:

- Charm icon.
- Name.
- Rarity.
- Bonus category.
- Exact effect per copy.
- Wins price.
- Robux price.
- Purchase buttons.
- Remaining restock time.
- Purchase status for the current rotation.

### Purchase Options

Every offer contains two alternative buttons:

```
Buy with Wins
Buy with Robux
```

Selecting either option grants one copy.

### Rotation Behavior

- Shop rotations are generated server-side.
- Every offer has one purchasable copy per rotation.
- After purchasing an offer, it changes to `Bought`.
- Purchasing it with one currency disables both buttons for that rotation.
- The same Charm can appear again in a future rotation.
- Buying it again grants another permanent copy.
- Restocking does not remove owned Charms.
- The shop must never display `Owned` as a final state because ownership does not prevent acquiring duplicates.

### Shop Refresh

- The shop refreshes automatically after a configured interval.
- An optional `Refresh Now` Developer Product may immediately generate another rotation.
- The interface must show the refresh price before opening the purchase prompt.
- A `Chances` button should display the exact probability of each rarity.
- Refreshing changes the offers but does not directly grant a Charm.
- Purchased offers must not be restored accidentally by reconnecting.

## Rarities

| Rarity | Recommended effect range | Robux price |
| --- | --- | --- |
| Common | 2–5% | R$11 |
| Rare | 4–10% | R$49 |
| Epic | 7–20% | R$199 |
| Mythic | 12–35% | R$399 |

The exact percentage depends on the bonus category.

## Data Structure

Owned Charms must use quantities instead of Boolean ownership values.

```
OwnedCharms = {
    StickySprout = 3,
    LuckyCoin = 1,
    SlimeHeart = 5,
}

EquippedCharms = {
    "SlimeHeart",
    "SlimeHeart",
    "LuckyCoin",
}
```

Recommended shop data:

```
CharmShop = {
    RotationId = "2026-09-08-001",
    ExpiresAt = 1788900000,

    Offers = {
        {
            CharmId = "SlimeHeart",
            Bought = true,
        },
        {
            CharmId = "LuckyCoin",
            Bought = false,
        },
    },
}
```

## Persistence

The following data must be saved:

- Owned quantity for every Charm.
- Equipped Charm in every slot.
- Number of unlocked equipment slots.
- Current shop rotation.
- Purchased offers within that rotation.
- Next restock timestamp.
- Developer Product receipt information where necessary.

Charms must persist through:

- Rebirth.
- Death.
- World teleportation.
- Leaving and rejoining.
- Server shutdown.
- Shop restocks.

## Server Authority

The server owns all Charm state.

The client may only request:

- Purchase with Wins.
- Purchase with Robux.
- Equip one copy.
- Unequip one copy.
- Equip Best.
- Remove All.
- Refresh the shop.

The server must validate:

- The `CharmId` exists.
- The shop currently offers the Charm.
- The offer has not already been purchased during that rotation.
- The player has sufficient Wins.
- The requested Developer Product matches the Charm.
- The receipt has not already been processed.
- The player owns enough copies to equip the requested amount.
- The equipment slot is valid.
- The player has not exceeded their slot limit.

## Robux Products

Because players can purchase the same Charm repeatedly, Robux purchases must use **Developer Products**, not Game Passes.

Each Charm definition requires:

```
{
    Id = "SlimeHeart",
    DisplayName = "Slime Heart",
    Category = "Stickiness",
    Rarity = "Epic",
    EffectPercent = 12,
    WinsPrice = 1500000000,
    DeveloperProductId = 0,
}
```

`MarketplaceService.ProcessReceipt` must grant exactly one copy and handle duplicate receipt delivery safely.

Prices shown in the interface must be retrieved dynamically from Roblox instead of being hard-coded.

## Analytics

Track at minimum:

- `CharmInventoryOpened`
- `CharmHovered`
- `CharmEquipped`
- `CharmUnequipped`
- `CharmEquipBestUsed`
- `CharmRemoveAllUsed`
- `CharmShopOpened`
- `CharmOfferViewed`
- `CharmPurchasedWithWins`
- `CharmPurchasePrompted`
- `CharmPurchasedWithRobux`
- `CharmPurchaseFailed`
- `CharmShopRefreshed`
- `CharmRestockViewed`

Recommended parameters:

```
CharmId
Category
Rarity
EffectPercent
OwnedQuantity
EquippedQuantity
Currency
Price
RotationId
PlayerLevel
PlayerRebirth
CurrentWorld
```

## Acceptance Criteria

- Players can purchase the same Charm multiple times.
- Wins and Robux purchases both grant one copy.
- Duplicate copies persist permanently.
- The inventory accurately displays owned, available and equipped quantities.
- Players cannot equip more copies than they own.
- Duplicate effects stack correctly.
- Every equipped copy consumes one slot.
- The shop permits one purchase per offer per rotation.
- Future rotations can sell additional copies.
- Developer Product receipts cannot grant duplicates accidentally.
- Charm state survives Rebirth and rejoining.
- The interface functions correctly on PC, mobile, tablet and console.

---

List of Items

| Item | Bonus Category | Rareza | Porcentaje de efecto | Costo en Wins | Costo en Robux | **Product ID** |
| --- | --- | --- | --- | --- | --- | --- |
| Sticky Sprout | Stickiness | Common | +2% | 5,000 | R$11 | 3712131184 |
| Mystic Sap | Stickiness | Rare | +7% | 250,000 | R$49 | 3712131222 |
| Slime Heart | Stickiness | Epic | +12% | 1.5B | R$199 | 3712131260 |
| Worldbinder Core | Stickiness | Mythic | +20% | 50B | R$399 | 3712131358 |
| Lucky Coin | Wins | Common | +3% | 6,000 | R$11 | 3712131387 |
| Golden Trophy | Wins | Rare | +6% | 300,000 | R$49 | 3712131426 |
| Victory Crown | Wins | Epic | +10% | 2B | R$199 | 3712131462 |
| Celestial Chalice | Wins | Mythic | +18% | 60B | R$399 | 3712131519 |
| Tiny Magnet | Collection Range | Common | +5% | 4,000 | R$29 | 3712131558 |
| Seeker Compass | Collection Range | Rare | +10% | 200,000 | R$79 | 3712131612 |
| Gravity Orb | Collection Range | Epic | +18% | 1B | R$199 | 3712131633 |
| Singularity Eye | Collection Range | Mythic | +30% | 40B | R$399 | 3712132435 |
| Cozy Pillow | AFK Rewards | Common | +5% | 5,000 | R$11 | 3712133250 |
| Dream Lantern | AFK Rewards | Rare | +10% | 250,000 | R$49 | 3712133291 |
| Timekeeper Hourglass | AFK Rewards | Epic | +20% | 1.5B | R$199 | 3712133336 |
| Eternal Moon | AFK Rewards | Mythic | +35% | 50B | R$399 | 3712133366 |
| Renewal Seed | Rebirth Bonus | Common | +2% | 10,000 | R$11 | 3712133403 |
| Phoenix Feather | Rebirth Bonus | Rare | +4% | 500,000 | R$49 | 3712133431 |
| Ouroboros Ring | Rebirth Bonus | Epic | +7% | 3B | R$199 | 3712133567 |
| Eternity Sigil | Rebirth Bonus | Mythic | +12% | 100B | R$399 | 3712133622 |



References  
+1 Speed Monkey Escape

+1 Dino Evolution
