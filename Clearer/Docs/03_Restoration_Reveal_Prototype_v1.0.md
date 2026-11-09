# PROTOTYPE C — RESTORATION WITH A REVEAL
## Roblox Minimum Functional Fantasy Specification | v1.0

**Status:** PROPOSED FOR OWNER REVIEW; NOT IMPLEMENTED / NOT PLAYTESTED  
**Date:** 2026-11-06  
**Prototype code:** REST-C  
**Primary fantasy:** “Every section I restore lets me discover more of a hidden, surprising result.”  
**Reference products (inspiration only):** *Clean a Painting* and adjacent find-the-hidden-object experiences  
**First-pass effort assumption:** 3–5 focused developer-days (6 hours/day).  
**Shared authority:** `05_Shared_Research_and_Playtest_Protocol_v1.0.md`. Separate from *Thaw a Creature*.

## 1. Research decision

**Does progressive uncovering of an unknown result make a simple cleaning action intrinsically replayable, even with no inventory, rarity, cash or permanent collection?**

- **Hypothesis C-H1:** Players experience noticeable curiosity during restoration and voluntarily start another reveal.
- **Hypothesis C-H2:** New reveal outcomes are less expensive to produce than new 3D locations or mechanisms.
- **Falsification:** Players can guess every result immediately, clean only to finish rather than enjoying the act, or lose interest after seeing all three outcomes.
- **Important confound:** This prototype contains anticipation absent from A. To isolate its benefit later, optionally A/B test **known vs hidden result using the same restoration interaction**, but do not build that second condition without approval.

## 2. P0 scope lock

| Component | Minimum requirement | Explicit exclusion |
|---|---|---|
| World | One small neutral gallery/workstation facing a large panel | Home base, multiple rooms, travel |
| Hidden content | Three original, rights-cleared illustrations at the same aspect ratio | Rarity tiers, branded images, UGC library, infinite generation |
| Cleaning surface | One 3:2 panel with **6 x 4 = 24 opaque cover tiles** | Real paint simulation, continuous pixel erase, fluid physics |
| Per tile | 2 accepted actions: dirty -> partly clear -> revealed | Brush/pressure tiers, consumable soap |
| Interaction | Aim/tap tile; immediate localized uncovering | Purchasable cleaners, auto-cleaning |
| Result selection | Server selects one of 3 equally weighted outcomes at start | Client reroll, hidden monetary odds |
| Progress | Accepted cleaning steps / 48; 0–100% | Coins, XP, collection completion |
| Completion | Full picture visible, gentle reveal celebration, replay/finish | Save to gallery, trading, rarity announcements |
| Replay | Reselect outcome, reset 24 tiles, same panel | New buildings, quest lines |

**First-pass tuning assumptions:** 24 tiles x 2 hits = 48 accepted actions; <=5 accepted actions/sec; <=12 studs to panel; 45–90 sec target including navigation and reading. A raw 48-action sequence can take much less; if measured rounds finish too quickly, change tile feel and movement gently, not add artificial waiting or a grind economy.

**Content requirement:** Prepare 3 original illustrations with visually different large silhouettes/compositions. Avoid trademarks and copyrighted characters. Don't describe the results with names visible before completion; the experience must preserve genuine curiosity without deceptive reward promises.

## 3. Moment-to-moment experience

**Spawn:** A framed panel is almost completely concealed by an opaque, obviously cleanable grime covering. Header: **“Restore the picture. What is underneath?”** A counter shows `0% REVEALED`. The three possible outcomes are **not** previewed.

**Clean:** The player points at a tile and holds/taps the cleaning input. On first valid hit, the cover fades to a still-obscuring partial state (e.g., cracked or slightly transparent). On second valid hit, the tile vanishes, exposing exactly that portion of the final illustration. Sound and particle feedback communicate an accepted action.

**Curiosity:** A revealed portion should be recognizable as part of a larger image, but the whole result is initially uncertain. Do not show the artwork in a thumbnail, nameplate, UI banner, folder label in-world, or immediate full preview. Note: a determined client can inspect replicated assets; the prototype has **no valuable hidden rewards**, so it does not claim cheat-proof secrecy.

**Final reveal:** At 48/48 accepted actions, all cover tiles are gone. Animate a short, non-flashing result presentation, followed by equally prominent **“Try another picture”** and **“Finish”** choices. Don't tell players that one outcome is rare or special.

**Replay:** Same workstation, fresh immutable `RoundId`, newly chosen result, reset tiles. With only three results, outcomes may repeat. Do not hide repeats or silently skew probabilities to manufacture anticipation. Record repeats in the test notes.

### Mobile input

Prefer a simple clickable 3D panel with queryable thin cover tiles or a correctly placed `SurfaceGui`, using either a center reticle + Clean touch button or large directly tappable cover cells. Choose **one** pattern for P0, test it on narrow screens, and avoid requiring two simultaneous pinch/drag gestures. The panel should fill enough of the viewport for individual tiles to be confidently targeted.

## 4. Visual design and asset list

| Asset | Quantity | Notes |
|---|---|---|
| Gallery / workbench room | 1 | Neutral background emphasizes before/after |
| Reveal frame/panel | 1, 3:2 aspect ratio | One consistent size for all results |
| Original reveal artwork | 3 | Equal visual importance, rights-cleared, similar detail density |
| Cover tiles | 24 (6 columns x 4 rows) | Opaque starting coverage; distinct partial-clean feedback |
| Cleaner/brush | 1 | Can be a simple effect with no elaborate arm animation |
| HUD | 1 progress number + result/replay UI | Large type and touch targets |
| Sound/VFX | Brief tile clean, result finish | Low intensity, avoid bright flashing |

**Visual rule:** Progress must be *local* and visually attributable. A random percentage increase without visible uncovered artwork fails the core fantasy. Avoid transparent gaps between untouched tiles that reveal the full image early. Test how much of the image becomes identifiable after 25%, 50%, and 75% cleanup.

## 5. Technical and authority contract

### Data

`RoundState = { RoundId, State, ResultId, TileRemainingHits[1..24], AcceptedHits, StartedAt, ConfigVersion }`. The server chooses `ResultId` once at round start from a config list and does not reroll after the first action. `Progress01 = AcceptedHits / 48`.

### Request

`RevealTileRequest(RoundId, TileId)` is a **request**, not proof of interaction. Server validates:

1. Sender's active round and exact RoundId; reject old or completed rounds.
2. TileId is within `[1,24]`, belongs to the player's active panel, and has remaining hits.
3. Character is alive and near panel (`<=12 studs`), facing the target surface, and the target is unobstructed from the player's viewpoint or approved proxy.
4. Action rate <=5 accepted hits/sec. A replay packet cannot finish an already complete tile.
5. Decrement tile state **once**, increment accepted hits once, replicate new tile status.
6. At 48 accepted hits, clear all tile presentation, mark COMPLETE once and present result.

**Client presentation:** Cover tiles can be separate lightweight parts, each initially opaque, with appearance determined by their replicated state. The underlying illustration can be placed via a `SurfaceGui` with an image asset. A screen-space canvas or a `SurfaceGui` is acceptable, but do not depend on a custom shader or image-editing engine. Use local animation only as cosmetic anticipation of server-accepted state; authoritative percent stays server-driven.

**Visual secrecy caveat:** If the result image asset is replicated to the client at start, technically sophisticated players can discover it before uncovering. For this **noncompetitive, non-monetized experiment** that is acceptable. Do not reuse this design for paid blind-box drops without a fresh security, policy and odds-disclosure review.

**Reset:** Server issues fresh RoundId, clears tiles and result UI, and selects one new preauthored ResultId. Late tile requests from earlier round are discarded. No DataStore; result ownership does not exist.

## 6. Suggested implementation layout

```
ReplicatedStorage/RestC/Config.lua
ReplicatedStorage/RestC/Remotes/RevealTileRequest
ReplicatedStorage/RestC/Remotes/TileStateChanged
ReplicatedStorage/RestC/Remotes/RoundStateChanged
ServerScriptService/RestC/RoundService.lua
ServerScriptService/RestC/TileRevealService.lua
ServerScriptService/RestC/ActionGuards.lua
StarterPlayer/StarterPlayerScripts/RestCClient.lua
Workspace/RestC_Arena/RevealPanel/TileProxies/*
Workspace/RestC_Arena/RevealPanel/PictureSurface
```

**No custom EditableImage is required for P0.** The 24-tile approach intentionally tests the experience without buying the engineering complexity of true smooth strokes.

## 7. Time-boxed build sequence

| Step | Focus | Exit criterion |
|---|---|---|
| C-01 | Gallery, panel, 24 cover nodes, 1 original picture | At least one tile cleanly reveals local picture portion |
| C-02 | Server tile states and input validation | No invalid tile, distance, spam, or duplicate progress |
| C-03 | 3 outcome images, random server selection, finish | End-to-end reveal and accurate result selection |
| C-04 | Mobile target sizes, feedback and replay reset | Second round works; clear difference between result/cover |
| C-05 | Instrumentation, 25/50/75% readability check and QA | Acceptance suite passes without adding systems |

**If late, cut:** decorative room geometry -> unnecessary per-tile particles -> additional result art beyond the required 3 only with owner approval. **Do not cut:** partial uncovering, three possible outcomes, real 100% transformation, replay, server authority, mobile controls.

## 8. QA acceptance suite (C-T01 to C-T14)

| ID | Test | PASS condition |
|---|---|---|
| C-T01 | Enter | Panel is genuinely obscured and progress starts 0% |
| C-T02 | First cleaning action | Only targeted cover tile partially clears |
| C-T03 | Second valid hit | Tile completely uncovers the matching artwork portion |
| C-T04 | Different tile | Other tiles remain obscured and independent |
| C-T05 | Invalid ID, distance, occlusion | No progress; server rejects request |
| C-T06 | Burst spam / repeated cleared tile | Cannot double count or skip required hits |
| C-T07 | Partial image clarity | At 25%, 50%, 75% progress, only cleaned regions reveal the result |
| C-T08 | Outcome selection | All 3 authored images can be selected across seeded QA rounds |
| C-T09 | No reroll | ResultId remains stable throughout a round and on invalid actions |
| C-T10 | Completion | Exact 48 accepted hits -> one final reveal event, 100% |
| C-T11 | Replay | New round ID, fully obscured surface, no old tile state |
| C-T12 | Stale request | Pre-replay tile message cannot mutate fresh round |
| C-T13 | Mobile play | Every tile targetable; no accidental camera/GUI dead zone |
| C-T14 | Rights and presentation | Only original licensed art; no deceptive rare-reward claims |

## 9. Measurement and next decision

In addition to shared metrics, record: **fraction of players who guess the hidden result before 25/50/75%**, first moment of visible excitement, whether participants clean beyond the moment they recognize the image, and whether outcome repetition harms the desire to replay.

To isolate the value of curiosity after P0, an optional controlled variant can display the identity of the result before cleaning. Keep the same tile interaction, same visuals and same participants protocol while rotating order. That tests *revelation versus pure restoration* more directly than comparing C to A alone.

**Proceed only if:** cleaning itself remains tolerable; uncertainty adds observed engagement; producing three original outcomes was manageable; and testers voluntarily start a second result. **Stop or revise if:** people recognize the picture too early, dislike the tile-by-tile approximation, or only want a collectible reward after the interaction.

## 10. Risks and implementer guardrails

| Risk | Mitigation |
|---|---|
| Flat image reveal feels like a click puzzle | Smooth tile transition and add subtle cleaning motion; no currency shortcut |
| Surprise disappears after first play | Three genuinely distinct images; log repeat-result reaction |
| Clients read replicated results early | Accept for no-value P0; do not imply anti-cheat secrecy |
| One screen size makes tiles too small | Scale panel and interaction proxies; phone QA is a hard gate |
| Tile and artwork alignment wrong | Lock 3:2 aspect and row/column mapping; test edges and corners |
| Assets legally questionable | Use original works or rights-cleared images only |

**AI guardrails:** Build only 24 fixed tiles / 3 equal-probability outcomes. Do not invent rare odds, collectible economies, image generation, secret trading, result storage, extra buildings, or a full painting editor. Keep server authoritative for tile acceptance. Explicitly mark any Roblox Studio or mobile behavior **NOT TESTED** until observed. Do not modify *Thaw a Creature*. Treat every numeric value as an experiment config, not an inferred market fact.

## 11. Technical references

- https://create.roblox.com/docs/workspace/raycasting
- https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
- https://create.roblox.com/docs/reference/engine/classes/CollectionService
- https://create.roblox.com/docs/reference/engine/classes/EditableImage (alternative only; not P0)
