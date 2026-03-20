# Phase 12: Simulation Mode and Integration - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire up AI-vs-AI simulation mode through the complete Flutter stack: a pausable turn loop with configurable speed, viewer-only UI replacing human action controls, territory inspection overlay, and end-to-end integration validated by tests and performance checks. All bot agents, game engine, and map widget are already built — this phase connects them into a watchable simulation experience.

</domain>

<decisions>
## Implementation Decisions

### Simulation Loop Architecture
- Claude's discretion on whether to extend GameNotifier or create separate SimulationNotifier — pick best fit for existing provider architecture
- Claude's discretion on isolate strategy: one isolate per turn (reusing runBotTurn()) for Slow/Fast, batch in single isolate for Instant
- Claude's discretion on Instant mode progress updates (yield every N turns vs spinner-only)
- All simulation bots use the same difficulty — single difficulty selector on SetupForm (already exists), no mixed difficulties

### Speed Control Behavior
- Default speed: Always Fast (per UI-SPEC)
- Speed changes take effect after current turn completes (not mid-turn)
- Claude's discretion on whether to allow switching from Instant back to Slow/Fast, or lock controls during Instant mode

### Territory Inspection
- TerritoryInspector auto-updates in place when inspected territory changes (owner, army count) — does NOT auto-dismiss
- Territory inspection works anytime (running or paused), not paused-only
- Claude's discretion on whether to show enhanced continent progress (X/Y territories + bonus) or basic info per UI-SPEC

### Simulation Lifecycle
- Stop button shows confirmation dialog: "End this simulation and return to the home screen?" — simulation pauses while dialog is shown
- Simulation state is ephemeral — NOT persisted via ObjectBox, lost on app close
- Claude's discretion on GameOverDialog: whether to add "New Simulation" button or reuse existing Home + New Game buttons
- Claude's discretion on error recovery: auto-pause + snackbar (UI-SPEC) vs auto-stop + navigate home

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### UI Design Contract
- `.planning/phases/12-simulation-mode-and-integration/12-UI-SPEC.md` — Complete visual/interaction contract: layout contracts (portrait/landscape), component inventory (SimulationControlBar, TerritoryInspector, SimulationStatusBar), state contracts, copywriting, spacing scale

### Game Engine & Simulation
- `mobile/lib/engine/simulation.dart` — Existing batch game loop (runGame function) — reference for Instant mode; needs adaptation for pausable per-turn execution
- `mobile/lib/engine/turn.dart` — executeTurn() function used by both human and bot turns; core loop primitive
- `mobile/lib/engine/models/game_config.dart` — GameMode.simulation enum and GameConfig class already defined

### Providers & State
- `mobile/lib/providers/game_provider.dart` — GameNotifier with runBotTurn() (Isolate.run pattern), _advanceTurnIfBot(), setupGame(); primary integration point for simulation loop
- `mobile/lib/providers/ui_provider.dart` — UIState with selectedTerritory, validSources, validTargets; used by TerritoryInspector
- `mobile/lib/providers/game_log_provider.dart` — GameLog notifier for ephemeral log entries; must receive bot action logs during simulation

### Screens & Widgets
- `mobile/lib/screens/game_screen.dart` — GameScreen with _PortraitLayout/_LandscapeLayout; conditional rendering point for simulation UI
- `mobile/lib/screens/home_screen.dart` — SetupForm with GameMode.simulation toggle already built
- `mobile/lib/widgets/action_panel.dart` — ActionPanel that gets replaced by SimulationControlBar in simulation mode

### Requirements
- `.planning/REQUIREMENTS.md` — BOTS-09: AI-vs-AI simulation mode (all bots, no human player)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GameMode.simulation` enum variant: Already defined in game_config.dart, wired through SetupForm
- `SetupForm`: Already has simulation mode toggle via SegmentedButton — no changes needed
- `simulation.dart runGame()`: Full batch game loop — directly usable for Instant mode
- `GameNotifier.runBotTurn()`: Single-turn isolate execution — reusable for Slow/Fast per-turn loop
- `GameOverDialog`: Existing dialog with Home + New Game buttons — reusable for simulation completion
- `GameLogWidget`: Auto-scrolling log — works as-is for simulation events
- `ContinentPanel`: Continent bonus display — no changes needed
- `MapWidget`: Interactive map with territory tap — tap wires to TerritoryInspector instead of action in simulation mode

### Established Patterns
- Riverpod 3.x with AsyncNotifier (generated providers: gameProvider, uIStateProvider)
- `ref.mounted` guard after Isolate.run() for auto-dispose safety
- `Future.microtask()` for avoiding nested state mutations in provider callbacks
- `_processing` flag in GameNotifier to prevent concurrent turn execution
- LayoutBuilder at 600dp breakpoint for portrait/landscape
- freezed for immutable state with value equality (shouldRepaint delegates)

### Integration Points
- GameScreen: Conditional layout swap — watch gameMode to show SimulationControlBar vs ActionPanel
- GameNotifier: Add simulation loop control methods (start/pause/stop with speed parameter)
- UIState: selectedTerritory already drives map highlighting — TerritoryInspector reads same state
- GameLog: Add log entries during simulation bot turns (currently only logged during human move flow)
- MapWidget tap handler: Route to TerritoryInspector instead of attack/fortify selection when gameMode == simulation

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. UI-SPEC provides complete visual contract.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 12-simulation-mode-and-integration*
*Context gathered: 2026-03-20*
