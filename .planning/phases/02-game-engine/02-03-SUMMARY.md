---
phase: 02-game-engine
plan: 03
subsystem: engine
tags: [turn-engine, game-loop, elimination, victory, random-bot, risk-game]

# Dependency graph
requires:
  - phase: 02-game-engine
    provides: GameState, PlayerAgent, reinforcements, cards, combat, fortify modules
provides:
  - Turn execution engine (REINFORCE->ATTACK->FORTIFY phase transitions)
  - Elimination handling with card transfer and forced trade cascade
  - Victory detection on last-opponent elimination
  - RandomAgent implementing full PlayerAgent protocol
  - run_game orchestrating complete game from setup to victory
affects: [03-web-ui, 04-bots, 05-ai]

# Tech tracking
tech-stack:
  added: []
  patterns: [turn phase FSM, advantage-based attack selection, map_graph injection into agents]

key-files:
  created:
    - risk/engine/turn.py
    - risk/game.py
    - tests/test_turn.py
    - tests/test_full_game.py
  modified:
    - risk/engine/__init__.py

key-decisions:
  - "RandomAgent uses advantage-based attack selection (strongest territory vs weakest neighbor) for game completion"
  - "RandomAgent receives map_graph via injection from run_game rather than constructor parameter"
  - "max_turns=5000 safety valve prevents infinite loops in game runner"
  - "Card trade always accepted by RandomAgent when valid set available (not probabilistic)"

patterns-established:
  - "Turn FSM pattern: execute_turn resets state, runs 3 phases sequentially, advances player"
  - "Elimination cascade: mark dead -> transfer cards -> force trade if 5+ -> check victory"
  - "Agent injection: run_game sets _map_graph on agents before game loop"

requirements-completed: [ENGI-08, ENGI-09]

# Metrics
duration: 6min
completed: 2026-03-08
---

# Phase 2 Plan 3: Turn Engine and Game Runner Summary

**Turn execution FSM with elimination/card-transfer cascade, victory detection, RandomAgent bot, and full game runner completing 2-6 player games in ~200 turns**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-08T07:26:18Z
- **Completed:** 2026-03-08T07:32:32Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Turn engine orchestrating REINFORCE->ATTACK->FORTIFY with correct phase transitions and player advancement
- Elimination handling: dead marking, card transfer, forced trade cascade when eliminator reaches 5+ cards
- Victory detected immediately when last opponent eliminated (one player owns all 42 territories)
- RandomAgent with advantage-based attack strategy enables complete game simulation
- Full game completes deterministically with seeded RNG across 2, 3, and 6 player configurations
- 21 new tests (15 turn + 6 full game), total suite at 177 tests

## Task Commits

Each task was committed atomically (TDD: RED then GREEN):

1. **Task 1: Turn engine tests (RED)** - `36703fa` (test)
2. **Task 1: Turn engine implementation (GREEN)** - `d2a53c5` (feat)
3. **Task 2: Full game tests (RED)** - `cb3a348` (test)
4. **Task 2: Game runner + exports (GREEN)** - `8e10a77` (feat)

## Files Created/Modified
- `risk/engine/turn.py` - Turn execution: check_victory, check_elimination, transfer_cards, force_trade_loop, execute_reinforce/attack/fortify_phase, execute_turn
- `risk/game.py` - RandomAgent (PlayerAgent implementation), run_game (full game loop)
- `risk/engine/__init__.py` - Updated exports for all turn engine functions
- `tests/test_turn.py` - 15 tests: phase transitions, elimination, card transfer, victory, player advancement
- `tests/test_full_game.py` - 6 tests: 2/3/6 players, determinism, loser state, card accounting

## Decisions Made
- RandomAgent uses advantage-based attack (strongest vs weakest neighbor) rather than pure random -- pure random caused games to stalemate past 1000 turns
- RandomAgent always trades cards when valid set available -- probabilistic trading slowed game convergence
- map_graph injected into RandomAgent by run_game rather than passed in constructor -- matches plan interface `RandomAgent(rng=...)` while still enabling adjacency queries
- max_turns default set to 5000 as safety valve

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test_card_earned_on_conquest setup**
- **Found during:** Task 1 (turn engine tests)
- **Issue:** Test gave player 1 only 1 territory, so conquest triggered elimination and victory rather than testing card draw
- **Fix:** Gave player 1 two territories so conquest doesn't trigger elimination
- **Files modified:** tests/test_turn.py
- **Verification:** Test correctly verifies card drawn after conquest without triggering victory
- **Committed in:** d2a53c5 (Task 1 GREEN commit)

**2. [Rule 1 - Bug] Tuned RandomAgent attack strategy for game completion**
- **Found during:** Task 2 (game runner)
- **Issue:** Original 70/30 random attack with single-roll dice caused games to stalemate (territory counts oscillated without convergence)
- **Fix:** Changed to advantage-based attack (strongest territory attacks weakest neighbor), reduced stop probability to 10%, and always trade cards when valid set available
- **Files modified:** risk/game.py
- **Verification:** 3-player game completes in ~196 turns, all player counts (2/3/6) tested
- **Committed in:** 8e10a77 (Task 2 GREEN commit)

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes necessary for correct test behavior and game completion. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete game engine ready: all Phase 2 modules (reinforcements, cards, combat, fortify, turn, game) integrated
- PlayerAgent protocol proven end-to-end via RandomAgent
- run_game provides the foundation for Phase 4 bot development and Phase 5 AI training
- Seeded RNG determinism enables reproducible bot evaluation

---
## Self-Check: PASSED

All files verified. All 4 task commits verified.

---
*Phase: 02-game-engine*
*Completed: 2026-03-08*
