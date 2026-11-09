# PROTOTYPE B — OBJECT ORGANIZATION
## Roblox Minimum Functional Fantasy Specification | v1.0

**Status:** PROPOSED FOR OWNER REVIEW; NOT IMPLEMENTED / NOT PLAYTESTED  
**Date:** 2026-11-06  
**Prototype code:** REST-B  
**Primary fantasy:** “I can turn a chaotic room into a neat, orderly one by putting objects where they belong.”  
**Reference products (inspiration only):** *Clean Everything*, *Clean The Library*  
**First-pass effort assumption:** 3–5 focused developer-days (6 hours/day); playtest recruitment/time separate.  
**Shared authority:** `05_Shared_Research_and_Playtest_Protocol_v1.0.md`. Separate from *Thaw a Creature*.

## 1. Decision this prototype must answer

**Does sorting and returning scattered items provide an enjoyable decision and a strong enough visual transformation to motivate voluntary replay, without money, collectibles or game progression?**

- **Hypothesis B-H1:** Recognizing the correct destination and snapping a messy object into place feels rewarding.
- **Hypothesis B-H2:** The content-authoring cost of new arrangements is acceptably low once pickup and slot systems are built.
- **Potential disconfirmation:** Moving each object feels like an unnecessary journey, destination rules are confusing, or the room reads as equally cluttered after completion.
- **Scope distinction:** This tests *order and classification*, not unconstrained interior decorating or a simulated housekeeping job.

## 2. Locked minimum scope (P0)

| Area | P0 requirement | Excluded |
|---|---|---|
| World | One readable shop/stockroom approx. 36 x 32 studs | New stores, neighborhoods, furniture catalogs |
| Objects | Exactly 12 items: 3 each from 4 visually distinct categories | Inventory sizes, prices, rare items, hundreds of props |
| Destinations | Four shelves/bins; three fixed snap slots per shelf | Free placement, physics stacking, building tools |
| Pickup | One object carried at a time; obvious pickup prompt | Throwing, object combat, carrying multiple |
| Placement | Correct-category destination accepts item and assigns an empty slot | Scoring penalties, selling, timed orders |
| Wrong placement | Soft rejection + clear category cue; item remains carried | Punishment, losing item, confusing reset |
| Progress | Accepted items placed / 12; visual room becomes ordered | Coins, XP, permanent collection |
| Completion | 12/12 -> short clean-room reveal -> replay / finish | Extra levels, rewards, achievements |
| Replay | Same room, reshuffle the 12 starting positions among prevalidated spawn nodes | Procedurally generated shop interiors |

**First-pass timing assumption:** 12 objects x ~5 seconds/object including pickup, pathing and placement = ~60 sec; aim 45–90 sec. Use layout adjustments if travel time dwarfs meaningful sorting.

## 3. Player-facing experience

**Entry:** The shop floor is visibly chaotic; colorful objects on the floor contrast with four tidy labeled shelf sections. Text: **“Put everything back on the right shelves.”** A `0/12 PLACED` counter is always readable.

**Identify:** Every object has a clear silhouette and category symbol. Every destination has the same icon/text cue, so the task does not depend on color recognition alone.

**Pick up:** Near an item, use `Pick up` through a `ProximityPrompt`. The model appears attached to a simple carry anchor. The held object does not physically shove the player or block the camera.

**Place:** At the destination shelf, trigger `Place`. If the item's category matches, the server selects the lowest available authored snap slot and places the item, with a short click/animation, outline or sound. If not, play a gentle error cue; do not put it into the wrong slot.

**Finish:** With all 12 items correctly placed, the floor is visibly clear and shelves appear orderly. Show `12/12` and equal prominence `Try another round` / `Finish`.

**Replay:** Choose one of three shuffled starting arrangements with the same categories and slots. The system must not create an unreachable prop or put an item under another part.

### Cross-platform input

Use server-handled ProximityPrompt events for pickup and place. Roblox automatically renders prompts for keyboard, gamepad, and touch, reducing custom input work. For narrow screens, prompts must not overlap excessively; show one closest actionable pickup, and one obvious placement prompt when near the target shelf. Avoid requiring drag-and-drop precision on mobile.

## 4. Art and level production brief

| Asset group | First-pass count | Readability requirement |
|---|---|---|
| Single room | 1 | Starting mess visible from entrance; short uncluttered walk paths |
| Category shelves | 4 | Big labels and symbols; no ambiguous category overlap |
| Prop models | 12, ideally 8–12 simple meshes assembled from reusable parts | Similar footprint; can all fit carried and in snap slots |
| Snap slots | 12 authored `Attachment`/marker positions | No clipping / shelf overlap with correct models |
| Spawn nodes | 12 per arrangement, at least 3 validated arrangements | No blocked doorways; items pickable |
| Carry anchor | 1 per character (hand or torso attachment) | Readable in first and third person |
| HUD | Counter, held category hint, placement prompt, finish choice | Works on touch screen |

**Example categories (first-pass content, not thematic commitments):** Books, Toys, Tools, and Food. Replace only if the new set preserves obvious distinctions and equal item counts. Do not use branded packaging or trademarks as shortcuts for understanding.

**Layout rule:** The room's before/after should read from the same camera spot. Floor mess becomes empty floor, and previously bare shelves become clearly organized. Avoid extra decorative clutter that conceals the transformation.

## 5. Data model and server-authoritative state

### Round state

`READY -> ACTIVE -> COMPLETE -> REPLAY_OFFERED -> RESETTING -> ACTIVE`

Per round, store `RoundId`, `PropStates[PropId] = {CategoryId, State, HolderUserId?, PlacedSlotId?}`, `Slots[SlotId] = {CategoryId, OccupantPropId?}`, `PlayerHeldProp`, `AcceptedPlacements`, `LayoutSeed`, and `StartedAt`.

**Prop lifecycle:** `Scattered -> Held -> Placed`; `Held -> Scattered` on deliberate drop/character removal. An item may never be held by two players or placed in two slots. P0 can disable voluntary drop if its existence is not needed for completing the task; death/leave must still release or reset safely.

### Authority for pickup and placement

**Pickup (`ProximityPrompt.Triggered` on prop):** Server validates ACTIVE round; original object belongs to this round; is `Scattered`; no item currently held; player's character is valid, alive, and <=10 studs from the object. Atomically mark `Held`, assign holder, disable old prompt, attach a non-colliding visual proxy with a server-authorized weld/attachment. If attachment fails, roll back ownership.

**Place (`ProximityPrompt.Triggered` on shelf):** Server validates ACTIVE round, player holds an actual item in this round, shelf is <=10 studs and correct category, at least one open snap slot exists. Reserve slot and mark prop `Placed` exactly once. Remove carry weld, anchor/snap the item to the authored slot on the server, increment `AcceptedPlacements`, and replicate state. The client may play cosmetic effects but cannot supply transform CFrames or decide valid slots.

**Wrong shelf:** Server rejects; sends clear UI feedback; **does not** consume held object or move it. Never allow negative inventory counts or ghost copies.

**Server-only reset:** Delete old carry constraints, remove old held visuals, reset all 12 props to validated spawn nodes, clear slot occupancy, create a new RoundId and counter, then reenable pickup. Late `Triggered` events from old round must not alter the new state.

### Scope simplification

P0 uses anchored/non-colliding placed props and deliberately simple carry visuals. A full physics placement system is **out of scope**; adding it would confound whether players enjoy organization with whether physics feels stable.

## 6. Suggested file structure

```
ReplicatedStorage/RestB/Config.lua
ReplicatedStorage/RestB/Remotes/RoomStateChanged
ReplicatedStorage/RestB/Remotes/InteractionRejected
ServerScriptService/RestB/RoundService.lua
ServerScriptService/RestB/PropStateService.lua
ServerScriptService/RestB/PlacementService.lua
StarterPlayer/StarterPlayerScripts/RestBClient.lua
Workspace/RestB_Arena/SpawnNodes/*
Workspace/RestB_Arena/Shelves/*
Workspace/RestB_Arena/Props/*
```

Use the `ProximityPrompt`'s `Triggered(player)` on the server rather than trusting a client-sent `PropId` from arbitrary UI. Still validate distance, state, category, and round. This is a small prototype: avoid inventing an expansive inventory framework.

## 7. Production sequence and cut plan

| Step | Focus | Exit test |
|---|---|---|
| B-01 | Graybox room, shelves, prop IDs, 12 slots | Before/after composition already legible |
| B-02 | Pickup one prop / simple server carry | Can't hold two, pickup from distance, or duplicate |
| B-03 | Correct/wrong placement + fixed slots | Atomic placement and clean rejection |
| B-04 | Full 12-prop content, progress and finish | One complete first round end-to-end |
| B-05 | Mobile prompts, replay shuffle, logs, QA | All tests pass including reset and narrow screens |

**Cut first:** three rearrangement seeds -> decorative labels / extra animation -> unique mesh variety. **Never cut:** category clarity, a proper correct-placement decision, visual room transformation, reliable carry cleanup, server state.

## 8. Acceptance suite (B-T01 to B-T13)

| ID | Scenario | PASS condition |
|---|---|---|
| B-T01 | First view | Mess and correct shelves recognizable without verbal tutorial |
| B-T02 | Pickup | Exactly one available item attaches; original floor item isn't duplicated |
| B-T03 | Wrong shelf | Rejected with clear feedback, still carrying the same item |
| B-T04 | Correct shelf | Exact item snaps to first free correct slot, count +1 once |
| B-T05 | Full shelf | No overwrite / cloning / loss; legitimate layout provides enough slots |
| B-T06 | Second pickup while carrying | Rejected, item state unchanged |
| B-T07 | Too far / invalid round | Trigger/replay exploit cannot move items or increase progress |
| B-T08 | Simultaneous requests | One authoritative transition per object, not duplicate placements |
| B-T09 | Character reset / leave | Carry constraints and state cleaned, no hovering stuck model |
| B-T10 | 12/12 finish | Single completion event, ordered room visibly better |
| B-T11 | Replay | All items, slots, prompts and counter reset under new round |
| B-T12 | Touchscreen | No prompt overlap prevents completion; no drag gesture requirement |
| B-T13 | Content variation | Alternate starting arrangement requires no new code |

## 9. Instrumentation and research decision

In addition to shared metrics, log **wrong-shelf attempts**, **average travel time per placement**, **time carrying an item without approaching any destination**, and **number of players who visually scan the room before choosing objects**. These reveal whether organization creates satisfying decisions or simply time-consuming trips.

**Advance only if:** sorting choices are understandable, the room looks unmistakably restored, replay is voluntary for a meaningful fraction of testers, and reorganizing the same content remains enjoyable. **Reconsider if:** confusion or traversal dominates, props are tedious to pick up, or making additional rooms requires more art than a small team can sustain.

## 10. Risks and AI guardrails

| Risk | Mitigation |
|---|---|
| Correct location unclear | Match category icon/text on item and destination; verify with newcomers |
| Carry physics unreliable | No free physics placement; use server-owned attachment and fixed snap slots |
| Shelves block prompts | Test from actual camera distances; enlarge prompt target volume without enlarging prop |
| Wrong shelf feels punitive | Keep item held, gentle correction, no timer loss |
| Replay has no novelty | Change seeded scatter layout first; **do not** jump to inventory or coins |
| Content authoring slows | Measure second layout creation time; simple category props over bespoke asset catalogs |

**Instructions to AI implementers:**

1. Use a separate Roblox test place. Do not touch *Thaw a Creature*, shared progression, or prior projects.
2. Do not implement drag-and-drop UI, inventories, money, object selling, multi-room levels, rebirth, or animation packages as unapproved embellishments.
3. Server owns which prop is carried, shelf category, occupied slot, and placement count. Never trust client CFrames.
4. Centralize first-pass counts and distances. Preserve full gameplay flow on narrow mobile screens.
5. A code review does not constitute Roblox Studio PASS. Explicitly report what was tested, which device, and remaining defects.
6. Obtain an explicit design decision before changing the fantasy from “put items in the right place” into decorating or construction.

## 11. Official API references

- https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
- https://create.roblox.com/docs/ui/proximity-prompts
- https://create.roblox.com/docs/reference/engine/classes/CollectionService
