# Repository Guidelines

## Project Structure & Module Organization

This is a Rojo-managed Roblox experience. `default.project.json` maps Roblox services to `Src/ReplicatedStorage`, `Src/ServerStorage`, `Src/ServerScriptService`, and `Src/StarterPlayerScripts`. Keep shared configuration and client-safe modules under `ReplicatedStorage`; keep authoritative gameplay services under `ServerScriptService`; reserve `ServerStorage` for server-only models and data; place client controllers under `StarterPlayerScripts`.

`Docs/` contains the canonical game design, prototype, launch architecture, development plan, and implementation constants in Markdown and PDF form. Treat the Markdown files as the searchable source of truth. Generated place/model files and `build/` or `dist/` outputs are intentionally ignored.

## Build, Test, and Development Commands

- `rokit install` installs the pinned toolchain from `rokit.toml` (currently Rojo 7.7.0).
- `rojo serve default.project.json` starts live synchronization with Roblox Studio.
- `rojo build default.project.json -o build/ThawACreature.rbxlx` creates a local Studio place for inspection or handoff.

Run commands from the repository root. No package manager, formatter, linter, or automated test runner is configured yet; do not document or depend on one without adding its configuration.

## Coding Style & Naming Conventions

Write idiomatic Luau with four-space indentation and one responsibility per module. Use `PascalCase` for ModuleScripts, services, controllers, and public config keys (`IceService`, `WorldCycleConfig`); use `camelCase` for locals and functions; use `UPPER_SNAKE_CASE` for file-local constants. Keep balance values in configuration modules, not embedded in services or controllers. Gameplay truth, reward rolls, persistence, and request validation must remain server-side.

## Testing Guidelines

Validate changes in Roblox Studio using Play mode and Start Server/Players when multiplayer behavior is involved. Test the complete affected loop, including failure paths such as death, reset, disconnect, duplicate requests, and invalid distance. Follow the regression scenarios in `Docs/04_Thaw_A_Creature_Development_Plan_Canonical_v0.5.md`; report manual test steps and results with the task summary. Add automated tests alongside the relevant module if a test framework is introduced later, using `*.spec.luau` names.

## Commit Guidelines

Use short, imperative, scoped subjects, for example `Add server-side ice claim validation`. Keep commits focused.

## Task Workflow

1. Read the exact current task in the Development Plan.
2. Read the relevant Prototype or Launch Technical Specification.
3. Consult Implementation Constants for exact values.
4. Consult the GDD when player-facing intent needs clarification.
5. Inspect existing implementation before modifying files.
6. Implement only the requested task and strictly necessary dependencies.
7. Test and validate the task.
8. Fix errors caused by the task and validate the fixes.
9. Report files created or modified, validation results, and Roblox Studio verification steps. Clearly distinguish completed checks from steps the user still needs to run.
10. **STOP and wait for user approval. Never automatically continue to the next Development Plan task.**

## Design Authority

Use the latest version of each canonical document. Resolve conflicts in this order: Concise GDD, relevant Prototype or Launch Technical Specification, Implementation Constants, then Development Plan. Their responsibilities are:

- **Concise GDD:** player experience and design intent.
- **Prototype Technical Specification:** Week-1 prototype behavior and scope.
- **Launch Technical Specification:** production/launch architecture and behavior.
- **Implementation Constants:** exact first-pass values and AI guardrails.
- **Development Plan:** implementation order.

Do not invent missing mechanics. Resolve ambiguity according to its impact:

- Purely technical, behavior-preserving decision: use the smallest robust implementation.
- Tunable number already represented in config: use canonical config.
- Unresolved decision with a player-facing gameplay consequence: stop and ask instead of inventing behavior.

## Advisory Skill References

`Docs/` remains the canonical source of truth for Thaw A Creature. `Reference/Skills/` contains advisory expertise only. If a Skill conflicts with the GDD, Technical Specifications, Implementation Constants, Development Plan, current task scope, or an explicit user decision, canonical project material wins.

Never add or change a game feature merely because a Skill recommends it. Consult only the relevant Skill reference when it materially helps the current task; do not read all Skill references for every task. Skills may improve execution quality, but may not independently redesign the game.

Route advisory reference use as follows:

- **`roblox-systems-scripter.md`:** Luau architecture; server/client authority; remotes; request validation/security; Roblox services/modules; DataStore/persistence.
- **`level-designer.md`:** greyboxing; routes; spawn placement; distance; line of sight; spatial readability; aspiration framing.
- **`game-designer.md`:** core-loop evaluation; player decisions; risk/reward; prototype/playtest interpretation; gameplay clarity.
- **`economy-designer.md`:** Cash economy; Pen income; Hearth costs; sources/sinks; progression pacing; economy balancing.
- **`roblox-experience-designer.md`:** Roblox-specific UX; onboarding; retention; social presentation; monetization; launch/product concerns.
- **`technical-artist.md`:** creature and Ice asset production; model hierarchy and asset contracts; VFX implementation; performance-conscious visuals; art pipeline and technical presentation.

Generic recommendations from these references—such as Daily Rewards, guaranteed rewards, extra currencies, monetization features, progression systems, quests, additional mechanics, or genre conventions—must not be implemented unless the canonical Thaw A Creature documents explicitly require or approve them.

## Scope Protection

Do not independently add combat, enemies, quests, extra currencies, Luck, stamina, hunger, prestige/rebirth, separate Speed progression, creature Warmth bonuses, limited Thaw Slots, a dedicated Thaw Machine, individual Ice respawn timers, randomized per-copy creature stats, creature-specific traversal abilities, or speculative reusable frameworks.

Preserve the canonical loop:

`SEE → WANT → RISK → BRING HOME → THAW → CRACK → CRACK → SMASH → PROGRESS`

Week 1 exists to validate the game rather than finish it. Protect dangerous retrieval, anticipation, reveal payoff, meaningful Equipped Speed, Great Frost, and immediate desire for another expedition.
