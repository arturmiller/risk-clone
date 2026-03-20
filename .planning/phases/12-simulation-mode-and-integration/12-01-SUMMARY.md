---
phase: 12-simulation-mode-and-integration
plan: 01
subsystem: providers
tags: [riverpod, simulation, isolate, stopwatch, bot-agents]

# Dependency graph
requires:
  - phase: 08-bot-agents
    provides: EasyAgent, MediumAgent, HardAgent bot implementations
  - phase: 09-riverpod-providers-and-persistence
    provides: GameNotifier, GameLog, MapGraph providers
provides:
  - SimulationNotifier provider with start/pause/resume/stop/setSpeed
  - SimulationSpeed enum (slow, fast, instant)
  - SimulationStatus enum (idle, running, paused, complete)
  - SimulationState ephemeral state class
  - buildSimulationAgents() top-level function
  - GameNotifier.updateState() method for simulation state injection
affects: [12-02-PLAN, 12-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [simulation-loop-with-isolate, stopwatch-instrumentation, ephemeral-state-class]

key-files:
  created:
    - mobile/lib/providers/simulation_provider.dart
    - mobile/lib/providers/simulation_provider.g.dart
    - mobile/test/providers/simulation_provider_test.dart
  modified:
    - mobile/lib/providers/game_provider.dart

key-decisions:
  - "SimulationNotifier is a separate provider (not extension of GameNotifier) — cleaner separation of simulation loop vs game state"
  - "buildSimulationAgents() duplicated agent construction (vs sharing _buildAgents) — top-level function for Isolate.run compatibility"
  - "GameNotifier.updateState() added for direct state injection — avoids _processing guard conflict with runBotTurn()"
  - "SimulationState is plain Dart (not freezed) — ephemeral one-shot, never serialized"

patterns-established:
  - "Simulation loop pattern: while(running) check-victory -> isolate.run(executeTurn) -> log -> delay -> repeat"
  - "Instant mode: single Isolate.run(runGame) for batch execution"

requirements-completed: [BOTS-09]

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 12 Plan 01: Simulation Provider Summary

**SimulationNotifier with start/pause/resume/stop/setSpeed driving all-bot simulation loop via Isolate.run with Stopwatch-instrumented per-turn timing**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-20T08:17:04Z
- **Completed:** 2026-03-20T08:22:39Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 4

## Accomplishments
- SimulationNotifier provider manages complete simulation lifecycle (idle -> running -> paused -> complete)
- Three speed modes: Slow (1000ms), Fast (200ms), Instant (batch in single Isolate)
- Stopwatch instrumentation on every Isolate.run call with per-turn timing logged to gameLogProvider
- Performance test validates average bot turn execution under 16ms on classic map
- 10 provider tests passing covering all lifecycle transitions, speed control, logging, victory detection, and performance

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Failing tests for SimulationNotifier** - `b8d27f2` (test)
2. **Task 1 GREEN: Implement SimulationNotifier with full lifecycle** - `8b4036d` (feat)

## Files Created/Modified
- `mobile/lib/providers/simulation_provider.dart` - SimulationNotifier, SimulationSpeed, SimulationStatus, SimulationState, buildSimulationAgents()
- `mobile/lib/providers/simulation_provider.g.dart` - Generated Riverpod provider code
- `mobile/lib/providers/game_provider.dart` - Added updateState() method for simulation state injection
- `mobile/test/providers/simulation_provider_test.dart` - 10 provider tests (lifecycle, speed, logging, victory, performance)

## Decisions Made
- SimulationNotifier as separate provider (not extending GameNotifier) for clean separation of concerns
- buildSimulationAgents() as top-level function (duplicates agent construction) for Isolate.run compatibility since _buildAgents is private to game_provider.dart
- GameNotifier.updateState() added as public method for direct state injection without triggering _processing guard or _advanceTurnIfBot
- Test for log entries uses instant mode (reliable completion) rather than fast mode (timing-sensitive)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added GameNotifier.updateState() method**
- **Found during:** Task 1 (GREEN phase)
- **Issue:** SimulationNotifier needs to update game state directly, but runBotTurn() has _processing guard and _advanceTurnIfBot that would conflict with simulation loop
- **Fix:** Added public updateState(GameState) method to GameNotifier for direct state injection
- **Files modified:** mobile/lib/providers/game_provider.dart
- **Verification:** All 10 simulation tests pass, existing game_notifier_test still passes
- **Committed in:** 8b4036d (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Essential for simulation provider to update game state. No scope creep.

## Issues Encountered
- Log entry test initially failed with fast mode (500ms wait insufficient for Isolate overhead) -- switched to instant mode for reliable test

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SimulationNotifier ready for UI widget integration in Plan 02 (SimulationControlBar, TerritoryInspector)
- GameScreen integration in Plan 03 depends on this provider
- All exports available: SimulationNotifier, SimulationSpeed, SimulationStatus, SimulationState, buildSimulationAgents

---
*Phase: 12-simulation-mode-and-integration*
*Completed: 2026-03-20*
