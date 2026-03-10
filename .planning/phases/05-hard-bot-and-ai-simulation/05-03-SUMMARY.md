---
phase: 05-hard-bot-and-ai-simulation
plan: 03
subsystem: server, ui
tags: [simulation, ai-vs-ai, game-mode, websocket, bots]

# Dependency graph
requires:
  - phase: 05-01
    provides: HardAgent skeleton for hard difficulty bot creation
provides:
  - Simulation mode (game_mode="simulation") in GameManager with all-bot game loop
  - game_mode field on StartGameMessage for WebSocket protocol
  - Frontend game mode selector with "Watch AI Game" option
  - Hard difficulty option in difficulty dropdown
  - Human control hiding in simulation mode
affects: [05-04]

# Tech tracking
tech-stack:
  added: []
  patterns: [game_mode parameter threading through WebSocket -> GameManager -> game loop selection]

key-files:
  created: []
  modified:
    - risk/server/game_manager.py
    - risk/server/messages.py
    - risk/server/app.py
    - risk/static/index.html
    - risk/static/app.js
    - tests/test_simulation.py

key-decisions:
  - "Simulation loop (_run_simulation_loop) is separate method from _run_game_loop rather than conditional branches, for clarity"
  - "Bot naming in simulation mode uses 'Bot 1' through 'Bot N' (1-indexed) vs play mode 'Bot 1' through 'Bot N-1' (player 0 is 'You')"
  - "isSimulation flag in app.js controls UI state; request_input messages ignored as safety guard"

patterns-established:
  - "game_mode parameter: threaded from frontend select -> WebSocket message -> app.py -> GameManager.setup() -> game loop selection"

requirements-completed: [BOTS-04]

# Metrics
duration: 4min
completed: 2026-03-10
---

# Phase 5 Plan 3: AI Simulation Mode Summary

**AI-vs-AI simulation mode with all-bot game loop, frontend game mode selector, and hard difficulty support**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-10T19:59:28Z
- **Completed:** 2026-03-10T20:03:57Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- GameManager supports game_mode="simulation" creating all-bot games with no human agent
- Separate _run_simulation_loop runs complete games with bot-only turns and appropriate naming
- Frontend offers "Watch AI Game" mode with hidden human controls and neutral game-over messaging
- Hard difficulty added to both server validation and frontend dropdown
- All 5 simulation tests passing (removed xfail markers)

## Task Commits

Each task was committed atomically:

1. **Task 1: Server-side simulation mode** - `0ccdc7c` (feat)
2. **Task 2: Frontend simulation mode UI** - `352e2b2` (feat)

## Files Created/Modified
- `risk/server/game_manager.py` - Added game_mode parameter, HardAgent import, _run_simulation_loop method, all-bot agent creation
- `risk/server/messages.py` - Added game_mode field to StartGameMessage
- `risk/server/app.py` - Pass game_mode from WebSocket message to GameManager.setup()
- `risk/static/index.html` - Added game mode dropdown and hard difficulty option
- `risk/static/app.js` - Added isSimulation tracking, hide controls in simulation mode, neutral game-over text
- `tests/test_simulation.py` - Removed xfail markers, added hard difficulty test, fixed player name assertion path

## Decisions Made
- Simulation loop is a separate method (_run_simulation_loop) rather than adding conditionals to _run_game_loop, keeping both code paths clean and readable
- Bot naming in simulation uses 1-indexed "Bot 1" through "Bot N" since there is no human player
- request_input messages are silently ignored in simulation mode as a safety guard (they should never be sent, but belt-and-suspenders)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Pre-existing test failures in test_hard_agent.py (KeyError in _estimate_win_probability when defender armies reach 0 via float decrements) -- documented in deferred-items.md, out of scope for this plan (05-02 territory)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Simulation mode fully functional end-to-end
- HardAgent integration works (hard difficulty creates HardAgent instances)
- Ready for plan 05-04 (batch testing / AI tuning)

---
*Phase: 05-hard-bot-and-ai-simulation*
*Completed: 2026-03-10*
