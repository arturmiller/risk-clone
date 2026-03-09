---
phase: 04-easy-and-medium-bots
plan: "02"
subsystem: bots
tags: [python, bots, medium-agent, tdd, continent-strategy, risk]

# Dependency graph
requires:
  - phase: 04-easy-and-medium-bots
    provides: risk/bots/__init__.py skeleton, test stubs for MediumAgent (plan 01)
  - phase: 03-web-ui-and-game-setup
    provides: run_game, RandomAgent, MapGraph, GameState, execute_turn

provides:
  - risk/bots/medium.py — MediumAgent with continent-aware strategy (all 6 protocol methods)
  - run_game() in risk/game.py uses hasattr duck-typing for map_graph injection

affects: [04-03-plan, 05-hard-bot]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MediumAgent computes continent scores per turn from GameState — no mutable turn-level state on self"
    - "hasattr duck-typing injection in run_game() future-proofs for any agent with _map_graph attribute"
    - "Continent-completing attacks taken even at slight disadvantage (src >= tgt) for strategic value"
    - "choose_fortify uses connected_territories for reachability, not raw adjacency"

key-files:
  created:
    - risk/bots/medium.py
  modified:
    - risk/game.py

key-decisions:
  - "MediumAgent never mutates per-turn state on self; all strategy computed fresh from GameState each call"
  - "run_game() changed from isinstance(agent, RandomAgent) to hasattr(agent, '_map_graph') for duck-typing injection"
  - "Continent-completing attacks accepted if src.armies >= tgt.armies (rather than strictly greater), matching plan behavior spec"
  - "Interior fortify source requires ALL neighbors owned — strict interior definition avoids moving armies off borders"

patterns-established:
  - "All 6 PlayerAgent protocol methods implemented; no ABC inheritance — structural Protocol"
  - "_border_territories helper shared between reinforce and fortify to avoid duplication"

requirements-completed: [BOTS-02]

# Metrics
duration: 2min
completed: 2026-03-09
---

# Phase 4 Plan 02: Easy and Medium Bots - MediumAgent Summary

**MediumAgent continent-aware Risk bot with 4-priority attack selection, concentrated border reinforcement, and interior-to-border fortification — all 13 unit and integration tests passing**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-09T20:02:14Z
- **Completed:** 2026-03-09T20:04:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created `risk/bots/medium.py` with full MediumAgent implementation (all 6 protocol methods)
- Updated `run_game()` in `risk/game.py` to use `hasattr(agent, '_map_graph')` duck-typing injection
- All 13 MediumAgent unit and integration tests now pass (XPASS), full suite remains green at 217 passed

## Task Commits

Each task was committed atomically:

1. **Task 1: Create MediumAgent implementation** - `c0b19e6` (feat)
2. **Task 2: Update run_game() duck-typing injection** - `8c4680d` (feat)

**Plan metadata:** (docs commit — pending)

## Files Created/Modified
- `risk/bots/medium.py` - MediumAgent: continent-aware bot implementing PlayerAgent protocol; reinforces border of top continent, attacks with 4-level priority, fortifies interior surplus toward exposed borders
- `risk/game.py` - Changed `isinstance(agent, RandomAgent)` to `hasattr(agent, '_map_graph')` in run_game() injection loop

## Decisions Made
- Used `hasattr(agent, '_map_graph')` not `isinstance(agent, MediumAgent)` in `run_game()` — future-proofs for HardAgent without any further changes to game.py
- Continent-completing attacks accepted when `src.armies >= tgt.armies` (not strictly greater) — tolerate equal force for strategic continent bonus
- Interior territories defined as "all neighbors are owned" for fortify source — prevents accidentally stripping border defenders
- `_continent_scores()` returns fresh computation per call, never cached on `self` — avoids stale state between turns

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- MediumAgent fully implemented and tested; plan 03 can now wire GameManager difficulty selection
- `from risk.bots import MediumAgent` works cleanly
- `from risk.bots.medium import MediumAgent` works cleanly
- TestDifficultyWiring tests remain xfail until plan 03 wires GameManager

---
*Phase: 04-easy-and-medium-bots*
*Completed: 2026-03-09*
