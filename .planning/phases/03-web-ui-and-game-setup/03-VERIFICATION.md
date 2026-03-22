---
phase: 03-web-ui-and-game-setup
verified: 2026-03-08T13:00:00Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Start a game with 3 players and verify SVG map renders with territory colors and army counts"
    expected: "42 territories visible, colored by owning player (3 colors), army count numbers on each territory"
    why_human: "SVG rendering quality, visual layout, and readability cannot be verified programmatically"
  - test: "Click a territory during reinforcement phase and place armies via the modal"
    expected: "Modal appears with number input, armies are placed, remaining counter decrements, map updates"
    why_human: "Click interaction, modal UX, and real-time visual feedback require human observation"
  - test: "During attack phase, click source territory then enemy neighbor"
    expected: "Source highlights, valid enemy targets glow with thicker borders, invalid territories dim, attack executes on second click"
    why_human: "Visual highlight/dim feedback and click-click interaction flow need human verification"
  - test: "Watch bot turns execute after ending your turn"
    expected: "Bot turns play with ~500ms delays, map updates show territory changes, game log shows bot actions"
    why_human: "Real-time animation timing and visual updates during bot turns cannot be tested programmatically"
  - test: "Verify game over screen appears when game ends and New Game button works"
    expected: "Victory/Defeat overlay appears, New Game returns to setup screen"
    why_human: "End-to-end game completion takes many turns; overlay appearance is visual"
---

# Phase 3: Web UI and Game Setup Verification Report

**Phase Goal:** A human player can set up and play a complete game of Risk in a web browser
**Verified:** 2026-03-08T13:00:00Z
**Status:** human_needed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player can select number of players (2-6) and start a new game from the browser | VERIFIED | index.html has `#setup-screen` with `<select>` options 2-6 and `#start-btn`; app.js sends `start_game` message on click; WebSocket endpoint in app.py handles it; integration test `test_server.py` validates the flow |
| 2 | SVG map displays all territories colored by owner with army counts visible | VERIFIED | classic_map.svg has 42 `data-territory` paths and 42 `data-army-label` text elements matching classic.json exactly; map.js `updateMap()` sets fill color from `PLAYER_COLORS[info.owner]` and updates label textContent |
| 3 | Player can click territories to perform game actions (attack source/target, fortify) | VERIFIED | map.js attaches click handlers to `[data-territory]` elements calling `handleTerritoryClick()`; app.js implements `handleAttackClick()` (source then target, client-side adjacency check, dice selector) and `handleFortifyClick()` (source then friendly target with army modal); `sendAction()` sends `player_action` over WebSocket |
| 4 | Current turn phase and active player clearly indicated; game log shows events | VERIFIED | sidebar.js `updateSidebar()` updates `#phase-stepper` steps with active/completed classes, `#player-name` and `#player-color-indicator`; `appendGameLog()` formats conquest/elimination/card_trade/reinforcement events; `showBanner()` displays phase prompt during human turns |
| 5 | Continent bonus information visible on/near the map | VERIFIED | sidebar.js `updateContinentInfo()` counts human-owned territories per continent and displays X/Y counts with bonus values; server `state_to_message()` includes `continent_info` with name, bonus, territories; index.html has `#continent-info` section with `data-continent` list items |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `risk/server/messages.py` | Pydantic message models | VERIFIED | 99 lines, 6 message types (GameState, RequestInput, GameEvent, GameOver, StartGame, PlayerAction), state_to_message helper, Literal type discriminators |
| `risk/server/human_agent.py` | HumanWebSocketAgent with queue bridge | VERIFIED | 180 lines, implements all 6 PlayerAgent methods, asyncio.Queue bridge via run_coroutine_threadsafe, intermediate state updates before attack/fortify |
| `risk/server/game_manager.py` | Game lifecycle management | VERIFIED | 222 lines, setup with human + bot agents, background thread game loop via threading.Thread, state diffing event emission, bot delay, cancel flag |
| `risk/server/app.py` | FastAPI with WebSocket endpoint | VERIFIED | 105 lines, WebSocket /ws endpoint, /api/map SVG route, /api/map-data JSON route, static file mount, root route |
| `risk/static/app.js` | WebSocket client and game state management | VERIFIED | 493 lines, WebSocket connect, message routing (game_state/request_input/game_event/game_over), input mode switching, reinforcement/attack/fortify/card_trade handlers, message queuing until map ready |
| `risk/static/map.js` | SVG map loading and interaction | VERIFIED | 126 lines (min 80 required), loadMap via fetch, updateMap colors/labels, highlight/dim classes, client-side adjacency target computation |
| `risk/static/sidebar.js` | Sidebar rendering | VERIFIED | 151 lines (min 60 required), phase stepper, continent bonuses with territory counts, game log with formatted events, action button visibility, banner show/hide |
| `risk/static/index.html` | HTML layout with setup and game board | VERIFIED | 129 lines, setup-screen with player count + start button, game-board with 75/25 map/sidebar, phase stepper, continent info, game log, dice controls, modals, game over overlay |
| `risk/static/style.css` | Styling with player colors and interactions | VERIFIED | 454 lines, 6 player colors, territory states (selected, valid-target, dimmed), dark theme, phase stepper, game log, modals |
| `risk/data/classic_map.svg` | SVG with 42 territory regions | VERIFIED | 241 lines, all 42 territories with data-territory attributes, 42 army labels with data-army-label attributes, all names match classic.json exactly |
| `tests/test_messages.py` | Message serialization tests | VERIFIED | 243 lines |
| `tests/test_human_agent.py` | Agent queue bridging tests | VERIFIED | 263 lines |
| `tests/test_server.py` | Integration tests | VERIFIED | 357 lines (min 50 required), WebSocket connect, start_game, state validation, input/action cycle |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `human_agent.py` | `risk/player.py` | Implements PlayerAgent protocol | WIRED | All 6 methods present: choose_attack, choose_fortify, choose_reinforcement_placement, choose_card_trade, choose_defender_dice, choose_blitz |
| `game_manager.py` | `risk/engine/turn.py` | Calls execute_turn in background thread | WIRED | Line 125: `state, victory = execute_turn(state, mg, self.agents, rng)` inside `_run_game_loop()` running in `threading.Thread` |
| `app.py` | `game_manager.py` | WebSocket endpoint delegates to GameManager | WIRED | Line 62: `manager = GameManager()`, line 79: `manager.start_game()`, line 82: `manager.handle_player_action(data)` |
| `app.js` | `app.py` | WebSocket connection to /ws | WIRED | Line 43: `new WebSocket(protocol + '//' + window.location.host + '/ws')` |
| `map.js` | `classic_map.svg` | Loads SVG, updates territory fills and labels | WIRED | Line 10: `fetch('/api/map')`, line 39-49: queries `[data-territory]` and `[data-army-label]` elements |
| `app.js` | `messages.py` | JSON messages matching server types | WIRED | Handles game_state, request_input, game_event, game_over; sends start_game, player_action |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| SETUP-01 | 03-01, 03-03, 03-04 | Player can select number of players (2-6) | SATISFIED | HTML select with options 2-6, StartGameMessage with validation ge=2 le=6, integration test confirms |
| MAPV-02 | 03-01, 03-02, 03-03 | Territories colored by owning player | SATISFIED | map.js updateMap sets fill from PLAYER_COLORS[owner], 6 distinct colors defined |
| MAPV-03 | 03-01, 03-02, 03-03 | Army count displayed on each territory | SATISFIED | SVG has 42 data-army-label text elements, map.js sets label.textContent = info.armies |
| MAPV-04 | 03-03, 03-04 | Territories clickable for game actions | SATISFIED | map.js attaches click handlers, app.js routes clicks through handleAttackClick/handleFortifyClick/handleReinforcementClick |
| MAPV-05 | 03-01, 03-03 | Current turn phase and active player indicated | SATISFIED | sidebar.js updates phase stepper with active/completed classes, shows player name and color |
| MAPV-06 | 03-01, 03-03, 03-04 | Game log shows event history | SATISFIED | sidebar.js appendGameLog formats conquest/elimination/card_trade/reinforcement/attack events, auto-scrolls |
| MAPV-07 | 03-02, 03-03 | Continent bonus information displayed | SATISFIED | sidebar.js updateContinentInfo shows per-continent bonus values and human's territory count (X/Y) |

No orphaned requirements found -- all 7 requirement IDs (SETUP-01, MAPV-02 through MAPV-07) are claimed by plans and have implementation evidence.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `risk/server/app.py` | 104-105 | `except Exception: pass` in `_schedule_send` | Info | Silently swallows send errors; acceptable for connection-closed scenarios but could hide bugs during development |

No TODOs, FIXMEs, placeholders, empty implementations, or stub handlers found across all phase files.

### Human Verification Required

### 1. SVG Map Visual Rendering

**Test:** Start server (`python -m uvicorn risk.server.app:app --reload --port 8000`), open http://localhost:8000, select 3 players, click Start Game.
**Expected:** 42 territories appear as colored regions (3 distinct colors for 3 players), army count numbers visible on each territory, map fills ~75% of viewport width.
**Why human:** SVG path rendering, territory readability, color contrast, and layout proportions cannot be verified programmatically.

### 2. Click-Click Attack Interaction

**Test:** During attack phase, click an owned territory with 2+ armies.
**Expected:** Source territory highlights with thicker border/glow. Enemy neighbors glow as valid targets. Non-adjacent and friendly territories dim. Clicking a valid target executes the attack with selected dice count.
**Why human:** Visual highlight/dim feedback, CSS interaction states, and click responsiveness need human observation.

### 3. Reinforcement Placement Flow

**Test:** During reinforce phase, click an owned territory.
**Expected:** Modal appears with number input (1 to remaining armies). After confirming, remaining counter updates in banner. After placing all armies, phase transitions to Attack.
**Why human:** Modal UX, counter updates, and phase transition flow require visual verification.

### 4. Bot Turn Visibility

**Test:** End your turn (attack + fortify phases) and observe bot turns.
**Expected:** Bot turns execute with ~500ms delays between each. Map colors and army counts update visibly. Game log shows bot conquests and events.
**Why human:** Real-time animation timing, progressive map updates, and game log scrolling behavior need human eyes.

### 5. End-to-End Game Completion

**Test:** Play or observe until game ends (or use a 2-player game for faster completion).
**Expected:** Game over overlay appears with Victory/Defeat message and winner name. "New Game" button returns to setup screen cleanly.
**Why human:** Full game lifecycle completion requires extended play; overlay appearance is visual.

### Test Results

- `pytest tests/test_messages.py tests/test_human_agent.py tests/test_server.py -x --timeout=30` -- **39 passed**
- `pytest tests/ --timeout=30` -- **216 passed**, 8 warnings (CancelledError in cleanup threads, non-blocking)

### Gaps Summary

No automated verification gaps found. All 5 observable truths are verified through code analysis: artifacts exist, are substantive (well beyond minimum line counts), and are properly wired together. All 7 requirement IDs are satisfied with implementation evidence.

The phase status is **human_needed** because the goal "A human player can set up and play a complete game of Risk in a web browser" inherently requires human verification of visual rendering, click interactions, real-time bot turn updates, and the complete gameplay loop. Automated checks confirm all code is in place and wired correctly, but the visual and interactive experience must be confirmed by a human tester.

---

_Verified: 2026-03-08T13:00:00Z_
_Verifier: Claude (gsd-verifier)_
