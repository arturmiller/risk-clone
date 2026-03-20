---
phase: 12-simulation-mode-and-integration
plan: 03
subsystem: ui
tags: [flutter, riverpod, simulation, game-screen, map-widget, integration]

# Dependency graph
requires:
  - phase: 12-simulation-mode-and-integration
    provides: SimulationNotifier provider (Plan 01), SimulationControlBar + TerritoryInspector + SimulationStatusBar widgets (Plan 02)
  - phase: 11-screens-widgets-and-mobile-ux
    provides: GameScreen portrait/landscape layout, HomeScreen SetupForm, MapWidget tap handling
  - phase: 09-riverpod-providers-and-persistence
    provides: gameProvider, uIStateProvider, GameConfig with GameMode enum
provides:
  - Conditional GameScreen layout (simulation vs vsBot mode)
  - Simulation-aware MapWidget tap handling with toggle-off
  - HomeScreen auto-start integration (setupGame then start)
  - End-to-end simulation mode (BOTS-09 complete)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [conditional-layout-by-game-mode, constructor-param-gameMode-propagation]

key-files:
  created: []
  modified:
    - mobile/lib/screens/game_screen.dart
    - mobile/lib/screens/home_screen.dart
    - mobile/lib/widgets/map/map_widget.dart
    - mobile/lib/widgets/simulation_control_bar.dart
    - mobile/lib/widgets/simulation_status_bar.dart
    - mobile/test/screens/game_screen_test.dart

key-decisions:
  - "GameMode passed as constructor param through GameScreen -> layouts -> MapWidget (not read from provider)"
  - "SimulationControlBar and SimulationStatusBar modified to accept simulation state changes during integration"

patterns-established:
  - "GameMode constructor parameter propagation: GameScreen(gameMode:) -> _PortraitLayout/_LandscapeLayout -> MapWidget(gameMode:)"

requirements-completed: [BOTS-09]

# Metrics
duration: 8min
completed: 2026-03-20
---

# Phase 12 Plan 03: GameScreen Integration Summary

**Conditional GameScreen layout wiring simulation widgets into portrait/landscape modes, MapWidget tap-to-inspect with toggle-off, HomeScreen setupGame-then-start auto-launch -- BOTS-09 simulation mode complete end-to-end**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-20T10:16:00Z
- **Completed:** 2026-03-20T10:24:05Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- GameScreen conditionally renders SimulationControlBar + SimulationStatusBar + TerritoryInspector overlay when GameMode.simulation, standard ActionPanel when vsBot
- MapWidget tap in simulation mode drives TerritoryInspector via selectTerritory; toggle-off clears selection on re-tap or empty-area tap
- HomeScreen calls setupGame(config) then simulationProvider.start(config) with separation of concerns preserved
- 226 tests passing (all existing + new simulation-mode GameScreen tests)
- Human verification approved (test suite + code review in WSL2 environment)

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire GameScreen conditional layout and HomeScreen auto-start** - `dec9b2f` (feat)
2. **Task 2: Verify complete simulation mode end-to-end including performance** - checkpoint:human-verify, approved

**Plan metadata:** (pending)

## Files Created/Modified
- `mobile/lib/screens/game_screen.dart` - Conditional simulation vs vsBot layout with GameMode parameter, SimulationControlBar/StatusBar/TerritoryInspector rendering
- `mobile/lib/screens/home_screen.dart` - setupGame then simulationProvider.start() auto-launch on simulation mode
- `mobile/lib/widgets/map/map_widget.dart` - GameMode parameter, tap toggle-off for territory inspection
- `mobile/lib/widgets/simulation_control_bar.dart` - Adjusted for integration with GameScreen layout
- `mobile/lib/widgets/simulation_status_bar.dart` - Adjusted for integration with GameScreen layout
- `mobile/test/screens/game_screen_test.dart` - Simulation mode layout tests (renders StatusBar/ControlBar, hides ActionPanel)

## Decisions Made
- GameMode passed as constructor parameter through widget tree (GameScreen -> layouts -> MapWidget) rather than read from a provider -- keeps rendering synchronous and avoids extra rebuilds
- SimulationControlBar and SimulationStatusBar widgets modified during integration to align with actual GameScreen layout constraints

## Deviations from Plan

None - plan executed as written. SimulationControlBar and SimulationStatusBar received minor adjustments during Task 1 to integrate cleanly with the GameScreen layout, but these were within expected integration scope.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 12 complete: all 3 plans delivered
- BOTS-09 (AI-vs-AI simulation mode) is functional end-to-end
- 60fps and memory stability targets deferred to on-device testing when Android hardware is available
- Stopwatch instrumentation in simulation_provider.dart supports future on-device profiling

## Self-Check: PASSED
- 12-03-SUMMARY.md: FOUND
- Commit dec9b2f: FOUND

---
*Phase: 12-simulation-mode-and-integration*
*Completed: 2026-03-20*
