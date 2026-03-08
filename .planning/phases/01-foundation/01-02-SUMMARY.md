---
phase: 01-foundation
plan: 02
subsystem: data
tags: [pydantic, game-state, setup, territory-distribution, army-placement]

# Dependency graph
requires:
  - phase: 01-foundation-01
    provides: "MapGraph, MapData, classic.json map data"
provides:
  - "GameState, TerritoryState, PlayerState Pydantic v2 models"
  - "setup_game function for territory distribution and army placement"
  - "STARTING_ARMIES config for 2-6 players"
  - "22 tests covering models, setup distribution, army counts, determinism"
affects: [02-game-engine, 03-web-ui, 04-bot-ai, 05-bot-hard]

# Tech tracking
tech-stack:
  added: []
  patterns: [pydantic-game-state, round-robin-distribution, seeded-rng]

key-files:
  created:
    - risk/models/game_state.py
    - risk/engine/setup.py
    - tests/test_game_state.py
    - tests/test_setup.py
  modified:
    - risk/models/__init__.py
    - risk/engine/__init__.py

key-decisions:
  - "Round-robin territory deal after shuffle ensures max 1 territory difference between players"
  - "Immutable TerritoryState rebuilt on army increment (Pydantic frozen-friendly pattern)"
  - "Optional seeded RNG parameter enables deterministic testing and replay"

patterns-established:
  - "GameState as single source of truth for all game data"
  - "setup_game accepts MapGraph + num_players, returns complete GameState"
  - "Seeded random.Random for deterministic test scenarios"

requirements-completed: [SETUP-02, SETUP-03]

# Metrics
duration: 2min
completed: 2026-03-08
---

# Phase 1 Plan 2: Game State and Setup Summary

**Pydantic game state models (GameState/TerritoryState/PlayerState) with round-robin territory distribution and classic Risk army placement for 2-6 players**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-08T06:48:17Z
- **Completed:** 2026-03-08T06:50:05Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Pydantic v2 models for complete game state: TerritoryState (owner + armies with ge=1 constraint), PlayerState (index, name, is_alive), GameState (territories dict, players list, turn tracking)
- setup_game function distributes 42 territories via shuffled round-robin (max 1 territory difference) and places armies with 1 per territory minimum plus random remainder distribution
- STARTING_ARMIES config matches classic Risk rules: 2p=40, 3p=35, 4p=30, 5p=25, 6p=20
- 22 new tests (8 model + 14 setup) all passing; full suite now 54 tests green

## Task Commits

Each task was committed atomically:

1. **Task 1: Game state Pydantic models and model tests** - `6e6f366` (feat)
2. **Task 2: Territory distribution, army placement, and setup tests** - `ab19441` (feat)

## Files Created/Modified
- `risk/models/game_state.py` - TerritoryState, PlayerState, GameState Pydantic v2 models
- `risk/engine/setup.py` - setup_game function with STARTING_ARMIES config
- `risk/models/__init__.py` - Updated exports for all model classes
- `risk/engine/__init__.py` - Updated exports for setup_game and STARTING_ARMIES
- `tests/test_game_state.py` - 8 tests: validation constraints, defaults, serialization roundtrip
- `tests/test_setup.py` - 14 tests: distribution balance, army totals, determinism, validation

## Decisions Made
- Round-robin territory deal after shuffle ensures max 1 territory difference between any two players for all player counts
- TerritoryState is rebuilt (not mutated) when incrementing armies, keeping Pydantic model immutability
- Optional seeded random.Random parameter on setup_game enables both deterministic tests and reproducible game replays

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 1 foundation complete: map data, graph queries, game state models, and setup logic all working
- Ready for Phase 2 game engine: GameState + MapGraph provide the full data layer
- 54 total tests provide regression safety for engine development

---
*Phase: 01-foundation*
*Completed: 2026-03-08*

## Self-Check: PASSED
- All 7 files verified present on disk
- Both task commits (6e6f366, ab19441) verified in git log
