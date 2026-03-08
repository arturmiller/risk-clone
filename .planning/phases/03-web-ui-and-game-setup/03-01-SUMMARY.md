---
phase: 03-web-ui-and-game-setup
plan: 01
subsystem: server
tags: [fastapi, websocket, pydantic, asyncio, threading]

requires:
  - phase: 02-game-engine
    provides: "PlayerAgent protocol, run_game loop, execute_turn, RandomAgent, GameState models"
provides:
  - "WebSocket message protocol (Pydantic models for all server/client messages)"
  - "HumanWebSocketAgent bridging async WebSocket to sync game loop via asyncio.Queue"
  - "GameManager running games in background threads with event emission"
  - "FastAPI app with WebSocket endpoint at /ws"
affects: [03-web-ui-and-game-setup, 04-bot-strategy]

tech-stack:
  added: [fastapi, uvicorn, httpx, pytest-asyncio]
  patterns: [asyncio-queue-bridge, thread-based-game-loop, state-diffing-events]

key-files:
  created:
    - risk/server/__init__.py
    - risk/server/messages.py
    - risk/server/human_agent.py
    - risk/server/game_manager.py
    - risk/server/app.py
    - tests/test_messages.py
    - tests/test_human_agent.py
  modified:
    - pyproject.toml

key-decisions:
  - "asyncio.Queue with run_coroutine_threadsafe for sync/async bridge between game thread and WebSocket"
  - "Turn-level event detection via state diffing rather than per-action hooks (avoids engine modification)"
  - "Human auto-defends with max dice and does not use blitz (per context decisions)"

patterns-established:
  - "Queue bridge pattern: sync game thread blocks on asyncio.Queue.get() via run_coroutine_threadsafe"
  - "Message protocol: Pydantic models with Literal type discriminator for dispatch"
  - "Event emission: compare old_state vs new_state after execute_turn to detect conquests/eliminations/trades"

requirements-completed: [SETUP-01, MAPV-02, MAPV-03, MAPV-05, MAPV-06]

duration: 4min
completed: 2026-03-08
---

# Phase 3 Plan 1: Server Backend Summary

**FastAPI WebSocket server with typed Pydantic message protocol and asyncio.Queue bridge connecting sync game loop to async browser communication**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T11:11:09Z
- **Completed:** 2026-03-08T11:15:26Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- WebSocket message protocol with 6 server-to-client and 2 client-to-server Pydantic message types
- HumanWebSocketAgent implementing all 6 PlayerAgent protocol methods via asyncio.Queue bridge
- GameManager creating human + bot agents and running game loop in background thread with event detection
- FastAPI app with WebSocket endpoint and static file serving
- 30 new tests passing, 207 total suite green

## Task Commits

Each task was committed atomically:

1. **Task 1: WebSocket message protocol (RED)** - `d3c10fa` (test)
2. **Task 1: WebSocket message protocol (GREEN)** - `752bb47` (feat)
3. **Task 2: HumanWebSocketAgent and GameManager (RED)** - `2844e78` (test)
4. **Task 2: HumanWebSocketAgent and GameManager (GREEN)** - `94a27e0` (feat)

_TDD tasks each had test + implementation commits_

## Files Created/Modified
- `risk/server/__init__.py` - Server package init
- `risk/server/messages.py` - Pydantic message models for WebSocket protocol (GameStateMessage, RequestInputMessage, GameEventMessage, GameOverMessage, StartGameMessage, PlayerActionMessage, state_to_message helper)
- `risk/server/human_agent.py` - HumanWebSocketAgent with asyncio.Queue bridge for all 6 PlayerAgent methods
- `risk/server/game_manager.py` - GameManager with background thread game loop, event detection via state diffing
- `risk/server/app.py` - FastAPI app with WebSocket /ws endpoint and static file mount
- `tests/test_messages.py` - 20 tests for message serialization/deserialization
- `tests/test_human_agent.py` - 10 tests for agent queue bridging and GameManager setup
- `pyproject.toml` - Added fastapi, uvicorn, httpx, pytest-asyncio dependencies

## Decisions Made
- Used asyncio.Queue with run_coroutine_threadsafe for the sync/async bridge (cleanest way to block game thread while waiting for WebSocket input)
- Turn-level event detection via state diffing after execute_turn rather than per-action hooks (avoids modifying the engine)
- Human auto-defends with max dice and never uses blitz per context decisions
- call_soon_threadsafe for receive_input to safely put data into queue from async context

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Server backend ready for frontend integration (Plan 03-02: SVG map and HTML layout)
- WebSocket message contract defined for client implementation
- GameManager ready to receive StartGame and PlayerAction messages from browser

## Self-Check: PASSED

All 7 created files verified present. All 4 task commits verified in git log.

---
*Phase: 03-web-ui-and-game-setup*
*Completed: 2026-03-08*
