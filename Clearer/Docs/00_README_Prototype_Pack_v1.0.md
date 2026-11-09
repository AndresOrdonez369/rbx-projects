# RESTORING A VISIBLE MESS
## Four Independent Roblox Prototype Specifications — v1.0

**Prepared:** 2026-11-06  
**Status:** Proposed design for owner review. Not implemented or playtested.  
**Owner decision required:** Choose which prototype to authorize, or authorize an ordered set of experiments.  
**Relationship to Thaw a Creature:** None. These are separate research prototypes, not changes to its canonical design, code, progression, or development plan.

## What this pack contains

| Code | Standalone specification | Core player fantasy | Assumed P0 effort |
|---|---|---|---|
| A | `01_Environmental_Clearing_Prototype_v1.0.md` | I can make an overwhelming mess disappear | 2–3 developer-days |
| B | `02_Object_Organization_Prototype_v1.0.md` | I can turn a chaotic space into something orderly | 3–5 developer-days |
| C | `03_Restoration_Reveal_Prototype_v1.0.md` | I can uncover something surprising by restoring it | 3–5 developer-days |
| D | `04_Precision_Washing_Prototype_v1.0.md` | I can precisely wash grime from a dirty object | 6–10+ developer-days; stop/go technical spike |
| Shared | `05_Shared_Research_and_Playtest_Protocol_v1.0.md` | Apples-to-apples validation | Shared method, not a fifth game |

**A developer-day is an estimate of six focused engineering hours, not an observed competitor build time.** Budgets exclude public-launch polish, marketing, monetization, production art, retention economies, and large-scale QA. No development time is guaranteed.

## Scope discipline

Each prototype is **one task and a replay button**, with a target initial playthrough of **45–90 seconds** (tuning hypothesis). One tester per instance is sufficient for P0; server authority still applies. There are **no currency systems, upgrades, persistence, inventory collections, monetization, AI-generated content pipelines, cross-game integration, trading, or live events**.

All numeric values in these documents are labeled **first-pass experiment assumptions**. Changing them after real playtesting is expected; doing so should not turn a prototype into a production game without an explicit decision.

## Read order

1. Read `05_Shared_Research_and_Playtest_Protocol_v1.0.md` to understand success metrics and comparison fairness.
2. Read the individual specs A–D, each with user experience, systems, authority, work plan, fallback, QA, and stop/go gate.
3. Choose one to implement. Prototype A is the lowest engineering-risk first test; C tests anticipation; B tests sorting; D is a high-risk fidelity benchmark.
4. Record observed results in the shared scorecard *before* planning expansions.

## Authority and status

- Each spec is a **proposal**, not owner-approved scope or a claim that Roblox Studio work exists.
- For gameplay and acceptance, the relevant individual spec governs that prototype. The shared protocol governs comparison and telemetry definitions.
- Where estimates, implementation approaches, or numerical targets conflict, obtain owner approval and record the revision; **do not let an AI coding assistant silently resolve the conflict**.
- Do not import designs, assets, cash systems, creatures, or code from *Thaw a Creature* without a separate authorized request.

## Technical sources

Official API documentation (checked 2026-11-06):

- Roblox raycasting: https://create.roblox.com/docs/workspace/raycasting
- ProximityPrompt: https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
- CollectionService: https://create.roblox.com/docs/reference/engine/classes/CollectionService
- Cross-platform input: https://create.roblox.com/docs/reference/engine/classes/ContextActionService
- EditableImage technical constraints (optional, prototype D only): https://create.roblox.com/docs/reference/engine/classes/EditableImage

## File formats

Every specification and the shared testing protocol is provided in editable Markdown and a readable PDF. The `.zip` archive includes all files. Markdown is the preferred implementation handoff format to Claude Code / Codex; PDFs are for human review.
