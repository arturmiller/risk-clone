---
phase: 04-easy-and-medium-bots
plan: "03"
subsystem: ui, api
tags: [websocket, pydantic, javascript, difficulty-selector]

# Dependency graph
requires:
  - phase: 04-easy-and-medium-bots
    provides: "04-01 MediumAgent implementation and 04-02 test stubs"
provides:
  - "StartGameMessage with difficulty field (default 'easy')"
  - "GameManager.setup() difficulty param selecting RandomAgent vs MediumAgent"
  - "app.py parsing difficulty from start_game WebSocket message"
  - "Browser difficulty dropdown (Easy/Medium) wired into start_game message"
affects: [04-easy-and-medium-bots, 05-hard-bot]

# Tech tracking
tech-stack:
  added: []
  patterns: [difficulty routed end-to-end via WebSocket message field]

key-files:
  created: []
  modified:
    - risk/server/messages.py
    - risk/server/game_manager.py
    - risk/server/app.py
    - risk/static/index.html
    - risk/static/app.js

key-decisions:
  - "difficulty field uses str (not Literal) in StartGameMessage for backwards compatibility -- old clients omitting the field still work with default 'easy'"
  - "_agents property on GameManager returns only bot agents (players 1+) for clean test assertions without exposing HumanWebSocketAgent"
  - "invalid difficulty values silently fall back to 'easy' via guard clause in setup()"

patterns-established:
  - "Browser form values flow through WebSocket JSON message fields to server setup params"

requirements-completed: [BOTS-01, BOTS-02]

# Metrics
duration: 4min
completed: 2026-03-09
---

# Phase 4 Plan 03: Difficulty Wiring Summary

**End-to-end difficulty selector from browser dropdown to MediumAgent/RandomAgent instantiation via WebSocket start_game message and GameManager.setup() difficulty param**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-09T20:03:00Z
- **Completed:** 2026-03-09T20:07:40Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- `StartGameMessage` now carries a `difficulty` field with default `"easy"` for full backwards compatibility
- `GameManager.setup()` accepts `difficulty` and instantiates `MediumAgent` or `RandomAgent` accordingly, with a guard for invalid values
- `app.py` extracts `difficulty` from the WebSocket message and passes it to `setup()`
- Browser setup screen now shows a Difficulty dropdown (Easy / Medium) that is included in the `start_game` WebSocket message
- All 3 `TestDifficultyWiring` tests now xpass; full 217-test suite green

## Task Commits

Each task was committed atomically:

1. **Task 1: Add difficulty to StartGameMessage and wire through server** - `a12a774` (feat)
2. **Task 2: Add difficulty selector to browser setup screen** - `a58b651` (feat)

**Plan metadata:** (final commit after SUMMARY)

## Files Created/Modified
- `risk/server/messages.py` - Added `difficulty: str = "easy"` to `StartGameMessage`
- `risk/server/game_manager.py` - Added `MediumAgent` import, `difficulty` param, `_agents` property, bot selection logic
- `risk/server/app.py` - Extract `difficulty` from start_game message, pass to `manager.setup()`
- `risk/static/index.html` - Difficulty `<select>` with Easy/Medium options added to setup form
- `risk/static/app.js` - `difficultySelect` DOM reference; difficulty included in `start_game` message

## Decisions Made
- Used `str` (not `Literal["easy", "medium"]`) for the `difficulty` field so old clients without the field still use the default and don't fail Pydantic validation
- Added `_agents` property returning only bot player entries (index 1+) to satisfy test assertions that check "all bot agents are of type X" without mixing in the `HumanWebSocketAgent` at index 0
- Invalid difficulty values silently normalized to `"easy"` -- no error raised, consistent with lenient server behavior

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added _agents property to fix test attribute mismatch**
- **Found during:** Task 1 (server wiring)
- **Issue:** Pre-written test stubs accessed `gm._agents` but `GameManager` only exposed `self.agents` (which includes the human at index 0). Tests would fail with AttributeError even after implementing difficulty.
- **Fix:** Added `_agents` property returning `{i: agent for i, agent in self.agents.items() if i != 0}` -- bot agents only
- **Files modified:** risk/server/game_manager.py
- **Verification:** All 3 TestDifficultyWiring tests xpass
- **Committed in:** a12a774 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Required to make tests pass. No scope creep.

## Issues Encountered
None beyond the `_agents` attribute mismatch above.

## Next Phase Readiness
- Full difficulty wiring complete: browser -> WebSocket -> GameManager -> agent instantiation
- BOTS-01 and BOTS-02 requirements satisfied
- Phase 4 plans 01-03 complete; ready for phase 4 integration verification if planned

---
*Phase: 04-easy-and-medium-bots*
*Completed: 2026-03-09*
