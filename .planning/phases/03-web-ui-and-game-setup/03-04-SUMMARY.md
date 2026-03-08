---
phase: 03-web-ui-and-game-setup
plan: 04
subsystem: testing, ui, server
tags: [websocket, integration-test, fastapi, svg, javascript]

# Dependency graph
requires:
  - phase: 03-web-ui-and-game-setup
    provides: Server backend (03-01), SVG map and HTML/CSS (03-02), Frontend JS logic (03-03)
provides:
  - Integration tests for WebSocket game flow
  - End-to-end verified browser gameplay
  - Race-condition-free map rendering with message queuing
  - Intermediate state updates during attack/fortify phases
affects: [04-smart-bots, 05-polish]

# Tech tracking
tech-stack:
  added: []
  patterns: [message-queue-before-map-ready, intermediate-state-updates-per-phase]

key-files:
  created: [tests/test_server.py]
  modified: [risk/server/app.py, risk/server/game_manager.py, risk/server/human_agent.py, risk/static/app.js, risk/static/sidebar.js, tests/test_human_agent.py]

key-decisions:
  - "Queue WebSocket messages until SVG map loaded to prevent race condition"
  - "Send intermediate game_state before each attack/fortify request_input for real-time feedback"
  - "Player names set to 'You' and 'Bot N' for clarity"

patterns-established:
  - "Message queuing: buffer messages until DOM ready, then flush"
  - "Intermediate state: agent sends game_state before request_input for visual feedback"

requirements-completed: [SETUP-01, MAPV-02, MAPV-03, MAPV-04, MAPV-05, MAPV-06, MAPV-07]

# Metrics
duration: 8min
completed: 2026-03-08
---

# Phase 3 Plan 4: Integration Testing and End-to-End Wiring Summary

**WebSocket integration tests plus 4 bug fixes: map rendering race condition, intermediate attack state updates, event key mismatches for bot names, and player naming**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-08T12:30:00Z
- **Completed:** 2026-03-08T12:38:00Z
- **Tasks:** 2 (TDD task + human-verify with fixes)
- **Files modified:** 7

## Accomplishments
- 9 integration tests validating full WebSocket game flow (connect, start, state, input, action)
- Fixed race condition where game_state arrived before SVG map loaded (territories showed 0 armies, no colors)
- Added intermediate state updates so client sees attack/fortify results in real time
- Fixed event detail key mismatches causing bot names to display as "NaN"

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Integration tests** - `adaffef` (test)
2. **Task 1 (GREEN): Fix integration issues** - `9a43600` (feat)
3. **Task 2: Fix 4 reported bugs from human verification** - `1d758af` (fix)

## Files Created/Modified
- `tests/test_server.py` - Integration tests for WebSocket game flow
- `risk/server/app.py` - WebSocket endpoint with event loop capture
- `risk/server/game_manager.py` - Player name assignment ("You", "Bot N"), game loop
- `risk/server/human_agent.py` - Intermediate state_to_message before attack/fortify request_input
- `risk/static/app.js` - Message queuing until map ready, flush on SVG load
- `risk/static/sidebar.js` - Fixed formatGameEvent to use correct server event detail keys
- `tests/test_human_agent.py` - Updated test for intermediate state message

## Decisions Made
- Queue WebSocket messages until SVG map is fully loaded and replay them (prevents race condition)
- Send intermediate game_state updates before each attack/fortify request_input (enables real-time visual feedback)
- Use server-side player names ("You", "Bot 1", "Bot 2") rather than client hardcoded names
- Use Promise.all for map + adjacency data loading before flushing message queue

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed map rendering race condition**
- **Found during:** Task 2 (human verification)
- **Issue:** game_state messages arrived before SVG map was fetched and injected into DOM, so updateMap found no elements to color/label
- **Fix:** Added message queue in app.js that buffers all WebSocket messages until map is loaded, then replays them via flushMessageQueue()
- **Files modified:** risk/static/app.js
- **Verification:** All 216 tests pass; queued messages correctly render on map load
- **Committed in:** 1d758af

**2. [Rule 1 - Bug] Fixed bot names showing as "NaN"**
- **Found during:** Task 2 (human verification)
- **Issue:** sidebar.js formatGameEvent used `details.player` for conquest events but server sends `details.attacker`/`details.attacker_name`; similarly for elimination events
- **Fix:** Updated formatGameEvent to use correct server-side keys (attacker_name, by_player, eliminated_name)
- **Files modified:** risk/static/sidebar.js
- **Verification:** Event messages now use correct detail keys matching server GameEventMessage format
- **Committed in:** 1d758af

**3. [Rule 1 - Bug] Fixed missing intermediate state updates during attack phase**
- **Found during:** Task 2 (human verification)
- **Issue:** After each attack resolved, the client had no updated game_state so map didn't reflect combat results
- **Fix:** HumanWebSocketAgent.choose_attack and choose_fortify now send state_to_message before request_input
- **Files modified:** risk/server/human_agent.py
- **Verification:** Tests updated and passing; client now receives state before each attack/fortify decision
- **Committed in:** 1d758af

**4. [Rule 1 - Bug] Fixed player names displayed as generic "Player N"**
- **Found during:** Task 2 (human verification)
- **Issue:** Setup creates "Player 1", "Player 2", etc. which is unclear about who is human vs bot
- **Fix:** GameManager._run_game_loop renames players to "You" and "Bot N" before sending initial state
- **Files modified:** risk/server/game_manager.py, risk/static/app.js
- **Verification:** Player names now show "You" for human and "Bot 1", "Bot 2", etc. for bots
- **Committed in:** 1d758af

---

**Total deviations:** 4 auto-fixed (4 bugs found during human verification)
**Impact on plan:** All fixes necessary for correct gameplay. No scope creep.

## Issues Encountered
None beyond the 4 bugs found during human verification, all resolved.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Full game loop works end-to-end in browser
- All 7 phase requirements verified (SETUP-01, MAPV-02-07)
- Ready for Phase 4 (smart bots) and Phase 5 (polish)

---
*Phase: 03-web-ui-and-game-setup*
*Completed: 2026-03-08*

## Self-Check: PASSED

All 7 key files verified on disk. All 3 task commits (adaffef, 9a43600, 1d758af) verified in git history.
