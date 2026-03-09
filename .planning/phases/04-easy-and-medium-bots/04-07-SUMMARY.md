---
phase: 04-easy-and-medium-bots
plan: "07"
subsystem: engine, server, ui
tags: [risk, combat, advance-armies, websocket, pydantic]

requires:
  - phase: 04-easy-and-medium-bots
    provides: MediumAgent, HumanWebSocketAgent, game server

provides:
  - AdvanceArmiesAction model in actions.py
  - execute_attack accepts armies_to_move parameter
  - execute_attack_phase calls agent.choose_advance_armies after conquest
  - HumanWebSocketAgent.choose_advance_armies prompts browser via request_input
  - Bot agents return min_armies for choose_advance_armies
  - app.js handles choose_advance_armies input type with move-armies-prompt modal

affects:
  - Phase 05 (hard bot)
  - Any future agent implementing PlayerAgent protocol

tech-stack:
  added: []
  patterns:
    - "Agent protocol: choose_advance_armies(state, source, target, min_armies, max_armies) -> int"
    - "Delta adjustment in turn.py: engine commits num_dice armies, caller adjusts if player chose differently"
    - "RequestInputMessage reuse: armies=min_armies, max_armies=max_armies for advance armies prompt"

key-files:
  created: []
  modified:
    - risk/models/actions.py
    - risk/engine/combat.py
    - risk/engine/turn.py
    - risk/game.py
    - risk/bots/medium.py
    - risk/server/human_agent.py
    - risk/server/messages.py
    - risk/static/app.js
    - tests/test_turn.py

key-decisions:
  - "Bot agents (RandomAgent, MediumAgent) return min_armies from choose_advance_armies for conservative play"
  - "Delta approach in turn.py: execute_attack already committed num_dice armies; turn.py adjusts delta if agent chose differently"
  - "armies_to_move parameter defaults to None in execute_attack; None means use num_dice (backward compatible)"

patterns-established:
  - "Agent protocol extension: new method added to all agent types (RandomAgent, MediumAgent, HumanWebSocketAgent, SimpleAgent test fixture)"

requirements-completed:
  - BOTS-01
  - BOTS-02

duration: 2min
completed: 2026-03-09
---

# Phase 04 Plan 07: Advance Armies Prompt Summary

**Post-conquest advance prompt wired end-to-end: human sees modal to choose armies to move (min=dice used, max=source-1); bots auto-advance minimum; delta adjustment in turn.py reconciles engine's default num_dice commit with player's chosen count.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-09T21:21:17Z
- **Completed:** 2026-03-09T21:23:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added `AdvanceArmiesAction` model and wired `execute_attack` to accept `armies_to_move` parameter
- Added `choose_advance_armies` to all agent types (RandomAgent, MediumAgent, HumanWebSocketAgent, SimpleAgent test fixture)
- Added frontend modal handler in app.js for `choose_advance_armies` input type reusing the existing move-armies-prompt modal

## Task Commits

Each task was committed atomically:

1. **Task 1: Engine changes — AdvanceArmiesAction, combat.py armies_to_move, turn.py agent call** - `4be31aa` (feat)
2. **Task 2: Server and frontend — human agent choose_advance_armies + app.js handler** - `d86bdd1` (feat)

## Files Created/Modified
- `risk/models/actions.py` - Added AdvanceArmiesAction model
- `risk/engine/combat.py` - Added armies_to_move parameter to execute_attack
- `risk/engine/turn.py` - Added choose_advance_armies agent call and delta adjustment after conquest
- `risk/game.py` - Added choose_advance_armies to RandomAgent (returns min_armies)
- `risk/bots/medium.py` - Added choose_advance_armies to MediumAgent (returns min_armies)
- `risk/server/human_agent.py` - Added choose_advance_armies method to HumanWebSocketAgent
- `risk/server/messages.py` - Added max_armies field to RequestInputMessage
- `risk/static/app.js` - Added choose_advance_armies case to enableInputMode switch
- `tests/test_turn.py` - Added choose_advance_armies to SimpleAgent test fixture

## Decisions Made
- Bot agents return `min_armies` from `choose_advance_armies` for conservative (minimum advance) play
- Delta approach used in turn.py: `execute_attack` already moves `num_dice` armies; turn.py computes `delta = chosen - num_dice` and adjusts source/target territories accordingly
- `armies_to_move=None` default in `execute_attack` is backward compatible (blitz still works, tests still pass)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added choose_advance_armies to SimpleAgent test fixture**
- **Found during:** Task 1 (test verification)
- **Issue:** SimpleAgent in tests/test_turn.py missing choose_advance_armies method; 2 tests failed with AttributeError
- **Fix:** Added `choose_advance_armies(self, state, source, target, min_armies, max_armies) -> int` returning min_armies to SimpleAgent
- **Files modified:** tests/test_turn.py
- **Verification:** All 29 combat/turn tests pass after fix
- **Committed in:** 4be31aa (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical — test fixture method)
**Impact on plan:** Necessary fix for test correctness. No scope creep.

## Issues Encountered
- None beyond the auto-fixed test fixture method.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Advance armies prompt fully wired for human player; bots unaffected
- Phase 05 (hard bot) can implement choose_advance_armies with more sophisticated logic if desired
- Full test suite: 220 passed, 13 xpassed, 0 failures

---
*Phase: 04-easy-and-medium-bots*
*Completed: 2026-03-09*
