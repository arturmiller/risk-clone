---
phase: 02-game-engine
plan: 02
subsystem: engine
tags: [combat, dice, blitz, fortification, path-validation, pydantic]

# Dependency graph
requires:
  - phase: 02-game-engine
    provides: GameState with territories/players, AttackAction, BlitzAction, FortifyAction models, MapGraph with are_adjacent and connected_territories
provides:
  - CombatResult model for dice outcomes
  - resolve_combat function (dice pairing, ties to defender)
  - validate_attack and execute_attack for single combat rounds
  - execute_blitz for auto-resolve combat loops
  - validate_fortify and execute_fortify with connected-path validation
affects: [02-03-turn-engine, 04-bots, 05-ai]

# Tech tracking
tech-stack:
  added: []
  patterns: [dice pairing highest-first with zip, blitz loop with dynamic dice count, connected_territories for path validation]

key-files:
  created:
    - risk/engine/combat.py
    - risk/engine/fortify.py
    - tests/test_combat.py
    - tests/test_fortify.py
  modified:
    - risk/engine/__init__.py

key-decisions:
  - "CombatResult is a Pydantic BaseModel in combat.py (not cards.py) since it's combat-specific"
  - "Blitz reuses execute_attack in a loop rather than duplicating combat logic"
  - "Fortify uses map_graph.connected_territories for path validation, not just adjacency"

patterns-established:
  - "Combat validation pattern: validate_attack raises ValueError, execute_attack calls it first"
  - "Blitz pattern: loop with dynamic dice counts based on current army state"
  - "Fortify pattern: build player territory set, check connected component reachability"

requirements-completed: [ENGI-02, ENGI-03, ENGI-04]

# Metrics
duration: 3min
completed: 2026-03-08
---

# Phase 2 Plan 2: Combat Resolution and Fortification Summary

**Dice combat with highest-first pairing and ties-to-defender, blitz auto-resolve loop, and fortification with connected friendly-path validation via MapGraph**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-08T07:20:48Z
- **Completed:** 2026-03-08T07:23:50Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Combat resolution: dice sorted descending, paired highest-first, ties go to defender
- Attack validation catches wrong owner, friendly target, non-adjacent, insufficient armies
- Blitz loops combat until conquest or attacker at 1 army, deterministic with seeded RNG
- Fortification validates connected friendly path (not just adjacency), rejects enemy-blocked routes
- 24 new tests (14 combat + 10 fortify), full suite at 156 tests

## Task Commits

Each task was committed atomically (TDD: RED then GREEN):

1. **Task 1: Combat resolution tests (RED)** - `4ad01bf` (test)
2. **Task 1: Combat implementation (GREEN)** - `bce864a` (feat)
3. **Task 2: Fortification tests (RED)** - `194ba8b` (test)
4. **Task 2: Fortification + exports (GREEN)** - `6849dc0` (feat)

## Files Created/Modified
- `risk/engine/combat.py` - CombatResult model, resolve_combat, validate_attack, execute_attack, execute_blitz
- `risk/engine/fortify.py` - validate_fortify, execute_fortify with connected-path validation
- `risk/engine/__init__.py` - Updated exports for combat and fortify functions
- `tests/test_combat.py` - 14 tests: dice pairing, ties, validation, conquest, blitz
- `tests/test_fortify.py` - 10 tests: path validation, enemy blocking, army boundaries

## Decisions Made
- CombatResult placed in combat.py as a Pydantic BaseModel rather than cards.py -- combat-specific, not reused elsewhere
- Blitz implementation reuses execute_attack in a loop, dynamically calculating max dice each round
- Fortification path validation delegates entirely to MapGraph.connected_territories for correctness

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Combat and fortification modules ready for turn engine (Plan 03) orchestration
- All action processing complete: reinforce (Plan 01), attack/blitz (this plan), fortify (this plan)
- Turn engine can now focus on phase transitions and player turn flow

## Self-Check: PASSED

All 5 files verified. All 4 task commits (4ad01bf, bce864a, 194ba8b, 6849dc0) verified.

---
*Phase: 02-game-engine*
*Completed: 2026-03-08*
