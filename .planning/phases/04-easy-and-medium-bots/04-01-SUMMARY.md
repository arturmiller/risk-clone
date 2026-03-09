---
phase: 04-easy-and-medium-bots
plan: "01"
subsystem: testing
tags: [pytest, tdd, bots, medium-agent, xfail, wave0]

# Dependency graph
requires:
  - phase: 03-web-ui-and-game-setup
    provides: GameManager, run_game, RandomAgent, MapGraph, GameState
provides:
  - risk/bots package skeleton with MediumAgent forward import
  - tests/test_medium_agent.py with 17 test stubs (Wave 0 scaffold)
  - xfail test stubs for BOTS-01 (difficulty wiring) and BOTS-02 (strategy)
affects: [04-02-plan, 04-03-plan]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave 0 TDD scaffold: xfail(strict=False) stubs run before implementation exists"
    - "Module-level MAP_GRAPH shared across test classes using load_map + MapGraph"
    - "_make_state helper builds minimal GameState from owner_map dict for unit tests"

key-files:
  created:
    - risk/bots/__init__.py
    - tests/test_medium_agent.py
  modified: []

key-decisions:
  - "risk/bots/__init__.py contains forward import of MediumAgent that will fail until plan 02 — expected for Wave 0"
  - "xfail(strict=False) chosen over raise NotImplementedError so test suite exits 0 before implementation"
  - "test_full_game_easy_bot marked xfail but xpasses (only uses RandomAgent) — strict=False so this is acceptable"
  - "Module-level MAP_GRAPH fixture loads real classic.json once per test session — fast enough (< 1s)"

patterns-established:
  - "Wave 0 scaffold pattern: test stubs exist before any implementation code"
  - "All MediumAgent unit tests build GameState manually using _make_state helper"
  - "Real MapGraph used everywhere — no mocking of map data"

requirements-completed: [BOTS-01, BOTS-02]

# Metrics
duration: 2min
completed: 2026-03-09
---

# Phase 4 Plan 01: Easy and Medium Bots - Wave 0 Test Scaffold Summary

**risk/bots package skeleton and 17 xfail test stubs covering all BOTS-01 and BOTS-02 behaviors before any MediumAgent implementation**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-09T19:58:15Z
- **Completed:** 2026-03-09T20:00:26Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created `risk/bots/__init__.py` package skeleton with forward import of MediumAgent
- Created `tests/test_medium_agent.py` with 17 test stubs across 5 test classes
- All MediumAgent-dependent tests are marked xfail(strict=False) so Wave 0 suite exits 0
- test_map_loads sanity check passes immediately confirming test infrastructure

## Task Commits

Each task was committed atomically:

1. **Task 1: Create risk/bots package skeleton** - `ccbf670` (chore)
2. **Task 2: Write test stubs in tests/test_medium_agent.py** - `126e0b3` (test)

**Plan metadata:** (docs commit — pending)

## Files Created/Modified
- `risk/bots/__init__.py` - Bot package init with forward import of MediumAgent; will fail to import until plan 02 creates medium.py
- `tests/test_medium_agent.py` - 17 test stubs: TestDifficultyWiring (3), TestMediumAgentReinforce (3), TestMediumAgentAttack (4), TestMediumAgentFortify (3), TestFullGameIntegration (3), plus test_map_loads

## Decisions Made
- Used `xfail(strict=False)` at class level rather than per-method to reduce repetition; allows xpass for test_full_game_easy_bot which only needs RandomAgent
- Module-level MAP_GRAPH loaded once via load_map + MapGraph; fast enough (< 1s) to share across all test classes
- `_make_state` helper fills unspecified territories with opponent-owned 1-army territories so unit tests don't need to enumerate all 42

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `test_full_game_easy_bot` shows as XPASS (unexpectedly passes) because it only uses RandomAgent which already exists. With strict=False this is harmless — overall exit code remains 0. Plans 02 and 03 will convert this to a normal PASSED test when the file is finalized.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Wave 0 scaffold complete; plans 02 and 03 can now implement MediumAgent and server wiring against these tests
- When plans 02+03 complete, re-run `python -m pytest tests/test_medium_agent.py -v` to verify all xfail convert to PASSED

---
*Phase: 04-easy-and-medium-bots*
*Completed: 2026-03-09*
