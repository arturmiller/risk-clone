---
phase: 08-bot-agents
plan: 03
subsystem: testing
tags: [dart, flutter, isolate, simulation, win-rate, bots, statistical-testing]

# Dependency graph
requires:
  - phase: 08-01
    provides: EasyAgent, simulation.dart (runGame helper)
  - phase: 08-02
    provides: MediumAgent, HardAgent implementations
provides:
  - 500-game statistical validation confirming HardAgent ~80% win rate vs MediumAgent (BOTS-07 final criterion)
  - Isolate.run() boundary tests confirming GameState and MapGraph are sendable (BOTS-08 architecture)
  - Full Phase 8 test suite: 143 tests passing
affects:
  - 09-ui-and-game-notifier (isolate wrapping in GameNotifier)
  - Phase 12 (production simulation uses same runGame helper)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "dart:isolate Isolate.run() confirmed sendable with freezed GameState and MapGraph"
    - "500-game seeded simulation via runGame() with seeds 0-499 for reproducibility"
    - "Flutter test loads assets via File('assets/classic.json') when cwd is mobile/"

key-files:
  created:
    - mobile/test/bots/win_rate_test.dart
    - mobile/test/bots/isolate_test.dart
  modified: []

key-decisions:
  - "win_rate_test loads classic.json via File('assets/classic.json') — same pattern as golden_fixture_test (mobile/ is cwd)"
  - "Isolate.run() boundary confirmed: freezed GameState, MapGraph, and EasyAgent all pass without serialization workaround"
  - "win_rate_test uses group('win_rate') tag for selective skipping in CI"
  - "isolate_test uses minimal 4-territory inline MapData — no file I/O, sub-second runtime"

patterns-established:
  - "Statistical simulation tests: seeded loop 0..N-1, closeTo matcher, diagnostic print on failure"
  - "Isolate boundary tests: minimal inline MapData, setUp not setUpAll for fast reset"

requirements-completed: [BOTS-07, BOTS-08]

# Metrics
duration: 2min
completed: 2026-03-15
---

# Phase 8 Plan 03: Win Rate Validation and Isolate Boundary Tests Summary

**500-game seeded simulation confirms HardAgent ~80% win rate vs MediumAgent; Isolate.run() boundary confirmed for GameState, MapGraph, and EasyAgent — Phase 8 complete, 143/143 tests green**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-15T18:38:59Z
- **Completed:** 2026-03-15T18:41:31Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Implemented `win_rate_test.dart`: 500-game simulation (seeds 0-499) confirms HardAgent achieves ~80% vs MediumAgent — BOTS-07 statistical criterion met
- Implemented `isolate_test.dart`: GameState, MapGraph, and EasyAgent all pass `Isolate.run()` boundary cleanly — BOTS-08 architecture validated for Phase 9
- Full Phase 8 test suite: 143 tests passing in ~26 seconds

## Task Commits

Each task was committed atomically:

1. **Task 1: win_rate_test.dart — HardAgent statistical validation** - `176286d` (feat)
2. **Task 2: isolate_test.dart — Isolate.run() boundary validation** - `b24e830` (feat)

**Plan metadata:** (final docs commit follows)

## Files Created/Modified
- `mobile/test/bots/win_rate_test.dart` - 500-game seeded simulation; HardAgent win rate must be 75%-85%
- `mobile/test/bots/isolate_test.dart` - 4 tests: GameState boundary, MapGraph boundary, agent executes inside isolate, no-Flutter-imports assertion

## Decisions Made
- `File('assets/classic.json')` path used in win_rate_test (not `mobile/assets/classic.json`) — flutter test runs from `mobile/` directory, matching golden_fixture_test pattern
- `isolate_test.dart` uses minimal 4-territory inline MapData rather than loading classic.json — keeps test I/O-free and sub-second
- Both freezed GameState and MapGraph are directly sendable across Isolate.run() without JSON round-trip — no Phase 9 serialization workaround needed

## Deviations from Plan

None — plan executed exactly as written.

The plan included a note about falling back to JSON boundary if `Isolate.run()` throws `Invalid argument: is not a SendPort`. That fallback was not needed — freezed objects passed directly.

## Issues Encountered
- Minor: `--timeout 120` flag requires unit suffix in flutter test; corrected to `--timeout 120s`. No impact.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 8 complete: all 3 plans done, 143 tests green
- HardAgent win rate confirmed: ~80% vs MediumAgent over 500 seeded games
- Isolate architecture validated: GameState + MapGraph are sendable, agents are pure Dart
- Phase 9 (UI and GameNotifier) can wire `Isolate.run(() => runGame(...))` without serialization overhead
- No blockers

---
*Phase: 08-bot-agents*
*Completed: 2026-03-15*
