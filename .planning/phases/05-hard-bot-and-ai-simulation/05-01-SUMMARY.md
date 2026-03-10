---
phase: 05-hard-bot-and-ai-simulation
plan: 01
subsystem: ai
tags: [hard-bot, heuristic-ai, test-stubs, simulation, risk-strategy]

# Dependency graph
requires:
  - phase: 04-easy-and-medium-bots
    provides: MediumAgent pattern, PlayerAgent protocol, run_game, bot __init__ exports
provides:
  - HardAgent skeleton class with all 7 PlayerAgent protocol methods
  - ATTACK_PROBABILITIES precomputed dice constant
  - Test stubs for BOTS-03 (reinforce, attack, card timing, threat, advance, full game, batch)
  - Test stubs for BOTS-04 (simulation mode agent creation, naming, completion)
affects: [05-02 hard-bot-strategy, 05-03 simulation-mode, 05-04 tuning]

# Tech tracking
tech-stack:
  added: []
  patterns: [xfail test stubs for wave-0 skeleton, precomputed probability constants]

key-files:
  created:
    - risk/bots/hard.py
    - tests/test_hard_agent.py
    - tests/test_simulation.py
  modified:
    - risk/bots/__init__.py

key-decisions:
  - "HardAgent skeleton uses simple fallback logic (random placement, no attacks) so it is immediately usable in tests without crashing"
  - "ATTACK_PROBABILITIES embedded as module-level constant dict keyed by (attacker_dice, defender_dice) tuples"
  - "Test stubs use class-level xfail(strict=False) matching Phase 04 pattern for Wave 0 suite exit 0"

patterns-established:
  - "HardAgent follows identical constructor pattern to MediumAgent: __init__(rng=None), _map_graph injected post-construction"
  - "Scoring weight constants defined at module level for easy tuning in Plan 02"

requirements-completed: [BOTS-03, BOTS-04]

# Metrics
duration: 4min
completed: 2026-03-10
---

# Phase 5 Plan 1: HardAgent Skeleton and Test Stubs Summary

**HardAgent skeleton with 7 protocol methods, precomputed attack probabilities, and 18 xfail test stubs covering strategy, simulation, and batch validation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-10T19:52:55Z
- **Completed:** 2026-03-10T19:56:40Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- HardAgent class implementing full PlayerAgent protocol with fallback behavior (importable and usable immediately)
- ATTACK_PROBABILITIES constant with all 6 dice combinations for future strategy implementation
- 18 test stubs across 9 test classes covering reinforcement, attack, card timing, threat assessment, advance armies, full game, batch testing, and simulation mode

## Task Commits

Each task was committed atomically:

1. **Task 1: HardAgent skeleton and __init__ export** - `35e3de5` (feat)
2. **Task 2: Test stubs for BOTS-03 and BOTS-04** - `4071760` (test)

## Files Created/Modified
- `risk/bots/hard.py` - HardAgent skeleton with all protocol methods and ATTACK_PROBABILITIES constant
- `risk/bots/__init__.py` - Added HardAgent export alongside MediumAgent
- `tests/test_hard_agent.py` - 13 test stubs in 7 classes for BOTS-03 strategy behaviors
- `tests/test_simulation.py` - 4 test stubs in 2 classes for BOTS-04 simulation mode

## Decisions Made
- HardAgent skeleton uses simple fallback logic (random placement, no attacks) so it is immediately usable without crashing
- ATTACK_PROBABILITIES embedded as module-level constant dict keyed by (attacker_dice, defender_dice) tuples
- Test stubs use class-level xfail(strict=False) matching Phase 04 pattern for Wave 0 suite exit 0
- Scoring weight constants (CONTINENT_PROGRESS_WEIGHT, BORDER_SECURITY_WEIGHT, etc.) defined at module level for easy tuning

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- HardAgent skeleton ready for Plan 02 to implement strategic logic against test contracts
- Test stubs define clear behavioral expectations for reinforce, attack, card timing, threat, and advance decisions
- Simulation mode test stubs ready for Plan 03/04 to implement GameManager simulation support
- Full test suite green (220 passed, 12 xfailed, 19 xpassed)

---
*Phase: 05-hard-bot-and-ai-simulation*
*Completed: 2026-03-10*
