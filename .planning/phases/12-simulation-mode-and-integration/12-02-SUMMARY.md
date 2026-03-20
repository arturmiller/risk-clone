---
phase: 12-simulation-mode-and-integration
plan: 02
subsystem: ui
tags: [flutter, riverpod, material3, simulation, widgets]

# Dependency graph
requires:
  - phase: 12-simulation-mode-and-integration
    provides: SimulationNotifier provider with speed/status/turnCount state
  - phase: 09-riverpod-providers-and-persistence
    provides: GameNotifier, UIStateNotifier, MapGraph providers
  - phase: 10-map-widget
    provides: kPlayerColors, TerritoryGeometry in territory_data.dart
provides:
  - SimulationControlBar widget (speed selector + play/pause + stop)
  - TerritoryInspector widget (territory detail card overlay)
  - SimulationStatusBar widget (turn/player/phase status display)
affects: [12-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [overrideWithValue-for-sync-provider-tests, mapGraphProvider-for-continent-lookup]

key-files:
  created:
    - mobile/lib/widgets/simulation_control_bar.dart
    - mobile/lib/widgets/territory_inspector.dart
    - mobile/lib/widgets/simulation_status_bar.dart
    - mobile/test/widgets/simulation_control_bar_test.dart
    - mobile/test/widgets/territory_inspector_test.dart
    - mobile/test/widgets/simulation_status_bar_test.dart
  modified: []

key-decisions:
  - "TerritoryInspector uses mapGraphProvider.continentOf() for continent lookup (not TerritoryGeometry) since TerritoryGeometry has no continent field"
  - "SimulationStatusBar phase label capitalized via string manipulation (not enum extension)"

patterns-established:
  - "overrideWithValue for sync Riverpod providers (simulationProvider, uIStateProvider) in widget tests"
  - "FakeGameNotifier pattern for async GameNotifier override in widget tests"

requirements-completed: [BOTS-09]

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 12 Plan 02: Simulation Widgets Summary

**Three simulation-mode widgets: SimulationControlBar with speed/play/stop controls, TerritoryInspector for territory detail overlay, SimulationStatusBar for turn/player/phase display -- 16 widget tests passing**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-20T08:24:40Z
- **Completed:** 2026-03-20T08:29:24Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- SimulationControlBar with SegmentedButton speed selector (Slow/Fast/Instant default Fast), play/pause toggle, destructive stop button with AlertDialog confirmation
- TerritoryInspector shows territory name, owner with color dot, army count, and continent name when a territory is selected; hides when none selected
- SimulationStatusBar shows turn number, current player with color dot, phase label, plus pause and instant-mode variants
- 16 widget tests covering all interaction states and visual contracts

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SimulationControlBar widget** - `2587b27` (feat)
2. **Task 2: Create TerritoryInspector and SimulationStatusBar widgets** - `bb3c393` (feat)

## Files Created/Modified
- `mobile/lib/widgets/simulation_control_bar.dart` - Speed selector + Play/Pause + Stop controls for simulation mode
- `mobile/lib/widgets/territory_inspector.dart` - Territory detail card overlay with name, owner, armies, continent
- `mobile/lib/widgets/simulation_status_bar.dart` - Turn/player/phase status display bar (48px, surfaceContainerHighest)
- `mobile/test/widgets/simulation_control_bar_test.dart` - 7 widget tests for control bar states and interactions
- `mobile/test/widgets/territory_inspector_test.dart` - 4 widget tests for inspector visibility and content
- `mobile/test/widgets/simulation_status_bar_test.dart` - 5 widget tests for status bar states and variants

## Decisions Made
- TerritoryInspector uses `mapGraphProvider.continentOf()` for continent lookup since `TerritoryGeometry` does not have a `continent` field (plan assumed `TerritoryDatum` with continent, but actual class is `TerritoryGeometry` without it)
- SimulationStatusBar capitalizes phase label via string manipulation rather than adding an enum extension

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used mapGraphProvider instead of kTerritoryData for continent lookup**
- **Found during:** Task 2 (TerritoryInspector implementation)
- **Issue:** Plan specified `kTerritoryData[territoryName]?.continent` but `TerritoryGeometry` class has no `continent` field; only `rect` and `labelOffset`
- **Fix:** Used `ref.watch(mapGraphProvider).value?.continentOf(selectedTerritory)` which correctly looks up continent via MapGraph's `_continentByTerritory` map
- **Files modified:** mobile/lib/widgets/territory_inspector.dart
- **Verification:** Test confirms "North America" shown for Alaska
- **Committed in:** bb3c393 (Task 2 commit)

**2. [Rule 1 - Bug] Used AsyncValue.value instead of valueOrNull**
- **Found during:** Task 2 (TerritoryInspector implementation)
- **Issue:** `valueOrNull` getter does not exist on `AsyncValue<MapGraph>` in this Riverpod version
- **Fix:** Used `.value` which returns null when async state is loading/error
- **Files modified:** mobile/lib/widgets/territory_inspector.dart
- **Verification:** All tests pass with `.value` accessor
- **Committed in:** bb3c393 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs from plan assumptions vs actual API)
**Impact on plan:** Both fixes necessary for compilation. No scope creep.

## Issues Encountered
- `Card` name collision between Flutter Material and `risk_mobile/engine/models/cards.dart` in test file -- resolved by removing unnecessary cards.dart import from territory_inspector_test.dart
- `find.byIcon(Icons.stop)` returns `Icon` widget not `IconButton` -- used `find.ancestor()` pattern to locate parent `IconButton` for onPressed assertions

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All three simulation widgets ready for GameScreen integration in Plan 03
- Widgets depend on simulationProvider (Plan 01), gameProvider, uIStateProvider, and mapGraphProvider
- GameScreen conditional layout (SimulationControlBar + SimulationStatusBar instead of ActionPanel) is next

---
*Phase: 12-simulation-mode-and-integration*
*Completed: 2026-03-20*
