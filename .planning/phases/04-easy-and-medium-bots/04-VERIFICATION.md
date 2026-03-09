---
phase: 04-easy-and-medium-bots
verified: 2026-03-09T22:00:00Z
status: human_needed
score: 17/17 automated truths verified
re_verification:
  previous_status: gaps_found
  previous_score: 14/15
  gaps_closed:
    - "GAP-01: renderArmyLabels(overlays) added to map.js; app.js calls it in 3 locations (placement confirm, confirm-reinforce click, input mode reset) — N+M staging display now live"
    - "GAP-02: choose_advance_armies wired end-to-end — AdvanceArmiesAction in actions.py, armies_to_move param in combat.py, agent call in turn.py, HumanWebSocketAgent sends request_input, app.js choose_advance_armies case shows move-armies-prompt modal, bots return min_armies"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Browser difficulty dropdown and Easy/Medium bot gameplay"
    expected: >
      Setup screen shows Difficulty dropdown with Easy and Medium options. Starting a game
      with Easy creates RandomAgent behavior (scattered attacks). Starting with Medium
      creates visibly continent-focused behavior (bots reinforce same area repeatedly,
      attack to complete continents). Full game runs to game-over screen with no JS
      console errors or server tracebacks.
    why_human: >
      Visual UI presence, qualitative strategic differences between Easy and Medium bots,
      and absence of runtime errors cannot be verified programmatically.
  - test: "Reinforcement staging labels show N+M format during placement"
    expected: >
      During the reinforce phase, after placing armies on a territory via the modal, the
      territory label on the SVG map updates immediately to show e.g. "4+3" (4 existing +
      3 staged). Placing more armies on a second territory updates that label too. After
      clicking Confirm Placements the labels revert to base counts immediately (before the
      server game_state arrives).
    why_human: >
      SVG DOM mutation during the reinforcement phase must be observed in a live browser;
      cannot be verified by static code analysis.
  - test: "Post-conquest advance armies modal appears for human player"
    expected: >
      After winning an attack that captures a territory, the "Move armies" modal appears
      with the label "Advance armies from [Source] into [Target] (min: N)". The input min
      is set to the number of dice used in the winning attack. The input max is set to
      source armies minus 1. After confirming a value, the map shows the chosen armies in
      the captured territory. Bots (Easy/Medium) do not pause for this prompt.
    why_human: >
      The modal appearance, correct min/max values, and resulting map update must be
      observed in a live browser session after a real conquest event.
---

# Phase 4: Easy and Medium Bots — Verification Report

**Phase Goal:** AI opponents provide a fun game experience at two difficulty levels, validating the bot framework for the Hard bot.
**Verified:** 2026-03-09
**Status:** human_needed (all automated checks pass; 3 items require browser testing)
**Re-verification:** Yes — after gap closure (plans 06 and 07)

---

## Re-verification Summary

Both gaps from the previous verification were closed by plans 06 and 07:

- **GAP-01 (Reinforcement staging display):** `renderArmyLabels(overlays)` added to `risk/static/map.js` (line 55). Three call sites wired in `risk/static/app.js`: after placement modal confirm (line 289), on confirm-reinforce click (line 490), and on reinforcement input mode reset (line 166).

- **GAP-02 (Post-conquest advance armies prompt):** `AdvanceArmiesAction` added to `risk/models/actions.py`. `execute_attack` in `risk/engine/combat.py` accepts `armies_to_move` parameter (default `None` falls back to `action.num_dice`). `execute_attack_phase` in `risk/engine/turn.py` calls `agent.choose_advance_armies` after conquest and applies a delta adjustment. `HumanWebSocketAgent.choose_advance_armies` sends `request_input` with `input_type='choose_advance_armies'`. `app.js` handles the `choose_advance_armies` case in `enableInputMode` using the existing move-armies-prompt modal. `RandomAgent` and `MediumAgent` both have `choose_advance_armies` returning `min_armies`.

Full test suite: **220 passed, 13 xpassed, 0 failures** — no regressions.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Test file exists with all test classes | VERIFIED | `tests/test_medium_agent.py` — 17 tests across 6 classes |
| 2 | `risk/bots/` package is importable | VERIFIED | `risk/bots/__init__.py` imports MediumAgent |
| 3 | MediumAgent implements all 6 PlayerAgent protocol methods | VERIFIED | `risk/bots/medium.py`: all 6 methods present, now 7 including choose_advance_armies |
| 4 | MediumAgent reinforces on border of highest-scoring continent | VERIFIED | Two-tier external_borders logic in medium.py lines 107–118; test_reinforce_places_on_border_of_top_continent PASSED |
| 5 | MediumAgent attacks into top continent with favorable odds | VERIFIED | XPASS: test_attack_targets_top_continent, test_attack_completes_continent |
| 6 | MediumAgent fortifies from interior toward border | VERIFIED | XPASS: test_fortify_moves_toward_border, test_fortify_skips_no_surplus, test_fortify_leaves_at_least_one_army |
| 7 | run_game() injects map_graph into MediumAgent via duck-typing | VERIFIED | `risk/game.py` line 170: `if hasattr(agent, '_map_graph'):` |
| 8 | MediumAgent completes a full game without stalling or crashing | VERIFIED | XPASS: test_full_game_medium_bot, test_full_game_medium_bot_no_stall |
| 9 | StartGameMessage accepts difficulty field with default 'easy' | VERIFIED | `risk/server/messages.py` line 61: `difficulty: str = "easy"` |
| 10 | GameManager.setup() creates RandomAgent for easy, MediumAgent for medium | VERIFIED | XPASS: all 3 TestDifficultyWiring tests; `risk/server/game_manager.py` lines 78–81 |
| 11 | Browser setup screen shows Difficulty dropdown | VERIFIED | `risk/static/index.html` lines 25–27: `<select id="difficulty">` with Easy/Medium options |
| 12 | Clicking Start Game sends difficulty value in WebSocket message | VERIFIED | `risk/static/app.js` line 53: `difficulty: difficultySelect.value` |
| 13 | Full test suite passes (no regressions) | VERIFIED | 220 passed, 13 xpassed, 0 xfailed, exit 0 |
| 14 | All xfail markers removed from TestMediumAgentReinforce | VERIFIED | No xfail decorator on TestMediumAgentReinforce; tests pass as PASSED |
| 15 | renderArmyLabels(overlays) added to map.js showing N+M staging format | VERIFIED | `risk/static/map.js` line 55: `function renderArmyLabels(overlays)` — shows "base+staged" when staged > 0 |
| 16 | app.js calls renderArmyLabels in 3 locations for staging feedback | VERIFIED | Lines 166 (input reset), 289 (after placement confirm), 490 (confirm-reinforce click) |
| 17 | choose_advance_armies wired end-to-end across engine, server, and frontend | VERIFIED | actions.py AdvanceArmiesAction; combat.py armies_to_move param; turn.py agent call + delta; human_agent.py sends request_input; app.js handles input_type='choose_advance_armies'; bots return min_armies |
| 18 | Human browser verification: Easy/Medium games, staging labels, and advance prompt work correctly | NEEDS HUMAN | Cannot verify visual behavior, runtime errors, or modal interaction programmatically |

**Score:** 17/17 automated truths verified, 1 truth (3 sub-tests) needs human

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `risk/bots/__init__.py` | bots package init exporting MediumAgent | VERIFIED | Exists, imports and re-exports MediumAgent |
| `risk/bots/medium.py` | MediumAgent with continent-aware strategy, external_borders fix, choose_advance_armies | VERIFIED | 299 lines; all 7 protocol methods implemented including choose_advance_armies at line 288 |
| `risk/game.py` | run_game() with hasattr duck-typing; RandomAgent.choose_advance_armies | VERIFIED | `if hasattr(agent, '_map_graph'):` at line 170; choose_advance_armies at line 139 returning min_armies |
| `tests/test_medium_agent.py` | All 17 tests passing, no xfails on TestMediumAgentReinforce | VERIFIED | 4 PASSED + 13 XPASS, 0 XFAIL, 0 failures |
| `risk/server/messages.py` | StartGameMessage with difficulty field; RequestInputMessage with max_armies | VERIFIED | Line 61: `difficulty: str = "easy"`; line 31: `max_armies: int | None = None` |
| `risk/server/game_manager.py` | setup() with difficulty param and MediumAgent import | VERIFIED | Lines 13, 52, 78–81 |
| `risk/server/app.py` | WebSocket handler parsing difficulty | VERIFIED | Lines 73, 79: `difficulty = data.get("difficulty", "easy")` passed to setup |
| `risk/server/human_agent.py` | choose_advance_armies sends request_input and waits | VERIFIED | Lines 117–140: method present, sends RequestInputMessage with input_type='choose_advance_armies', reads response |
| `risk/static/index.html` | Difficulty dropdown in setup form | VERIFIED | Lines 25–27: `<select id="difficulty">` with Easy/Medium options |
| `risk/static/app.js` | start_game difficulty; renderArmyLabels calls; choose_advance_armies handler | VERIFIED | Line 53 difficulty; lines 166/289/490 renderArmyLabels; lines 198–222 choose_advance_armies case |
| `risk/static/map.js` | renderArmyLabels(overlays) function | VERIFIED | Lines 55–70: substantive implementation reading gameState and overlays dict |
| `risk/models/actions.py` | AdvanceArmiesAction model | VERIFIED | Line 51: `class AdvanceArmiesAction(BaseModel)` |
| `risk/engine/combat.py` | execute_attack accepts armies_to_move parameter | VERIFIED | Line 81: `armies_to_move: int | None = None`; line 108: used in conquest block |
| `risk/engine/turn.py` | execute_attack_phase calls agent.choose_advance_armies after conquest | VERIFIED | Lines 216–235: call + delta adjustment logic |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `risk/static/app.js` | `risk/server/app.py` | WebSocket start_game.difficulty | WIRED | `difficultySelect.value` sent in JSON; server reads `data.get("difficulty", "easy")` |
| `risk/server/app.py` | `risk/server/game_manager.py` | `manager.setup(difficulty=difficulty)` | WIRED | Line 79: `difficulty=difficulty` passed to setup() |
| `risk/server/game_manager.py` | `risk/bots/medium.py` | MediumAgent instantiation when difficulty=='medium' | WIRED | Line 13 import, lines 78–79 conditional instantiation |
| `risk/bots/medium.py` | `risk/engine/map_graph.py` | continent_territories(), _map_graph methods | WIRED | External_borders two-tier selection at lines 107–118 |
| `risk/game.py` | `risk/bots/medium.py` | `hasattr(agent, '_map_graph')` duck-typing | WIRED | Line 170: injection applies to any agent with `_map_graph` attribute |
| `app.js placement confirm handler` | `renderArmyLabels (map.js)` | call after updating reinforcementPlacements | WIRED | Line 289: `renderArmyLabels(reinforcementPlacements)` after `reinforcementPlacements[territoryName] += count` |
| `confirmReinforceBtn click (app.js)` | `renderArmyLabels (map.js)` | call with empty overlay to clear staging | WIRED | Line 490: `renderArmyLabels({})` before `sendAction('reinforce', ...)` |
| `enableInputMode choose_reinforcement_placement (app.js)` | `renderArmyLabels (map.js)` | call on mode reset | WIRED | Line 166: `renderArmyLabels({})` after `reinforcementPlacements = {}` |
| `risk/engine/turn.py execute_attack_phase` | `agent.choose_advance_armies` | called after conquered=True | WIRED | Line 216: `armies_to_advance = agent.choose_advance_armies(state, action.source, action.target, min_armies, max_armies)` |
| `risk/engine/combat.py execute_attack` | `armies_to_move parameter` | caller passes chosen count; None falls back to num_dice | WIRED | Line 81 param, line 108: `armies_moved = armies_to_move if armies_to_move is not None else action.num_dice` |
| `risk/server/human_agent.py choose_advance_armies` | `risk/static/app.js choose_advance_armies handler` | RequestInputMessage with input_type='choose_advance_armies' | WIRED | human_agent.py lines 126–133 send; app.js lines 198–222 handle |

---

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BOTS-01 | 04-01, 04-03, 04-04, 04-06, 04-07 | Easy bot makes random valid moves; selectable via browser difficulty dropdown | SATISFIED | RandomAgent wired via GameManager.setup(difficulty="easy"), browser dropdown, WebSocket message, choose_advance_armies returning min_armies. REQUIREMENTS.md marks BOTS-01 Complete. |
| BOTS-02 | 04-01, 04-02, 04-03, 04-04, 04-05, 04-06, 04-07 | Medium bot uses basic strategy (continent focus, reasonable attack decisions) | SATISFIED | MediumAgent fully implemented with continent-aware reinforce (external_borders), attack, fortify, and choose_advance_armies. All 17 tests pass. REQUIREMENTS.md marks BOTS-02 Complete. |

No orphaned requirements: REQUIREMENTS.md maps only BOTS-01 and BOTS-02 to Phase 4. BOTS-03 and BOTS-04 are assigned to Phase 5 and unclaimed by any Phase 4 plan.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `risk/server/app.py` | 29 | `"placeholder"` in HTML fallback docstring | Info | Comment-only, not a code stub — no impact on behavior |

No code-level stubs, empty returns, or unimplemented handlers found in plans 06 or 07 artifacts.

---

## Human Verification Required

### 1. Browser Gameplay — Easy vs Medium Bot Behavior

**Test:** Start the server (`uvicorn risk.server.app:app --reload` from the project root), open http://localhost:8000, start a 3-player Easy game and observe bot turns for several rounds. Then start a 3-player Medium game and observe bot turns.

**Expected:**
- Setup screen shows Difficulty dropdown with "Easy" (default) and "Medium" options.
- Easy bots attack scattered targets with no apparent strategic pattern.
- Medium bots visibly cluster reinforcements in the same continent across turns, attack to complete or extend continent holdings, and fortify interior armies toward frontiers.
- No JavaScript console errors (F12 > Console) and no server tracebacks during play.
- A full game runs to completion, showing the game-over overlay with winner name.

**Why human:** Visual UI presence, qualitative strategic differences between Easy and Medium, and absence of runtime errors cannot be verified programmatically.

### 2. Reinforcement Staging Labels (GAP-01)

**Test:** Start a game with a human player. Enter the reinforcement phase. Click a territory to open the placement modal, enter a number of armies, and confirm.

**Expected:**
- After confirming the modal, the territory label on the SVG map immediately updates from "4" to "4+3" (or equivalent).
- Placing armies on additional territories updates each label independently.
- Clicking "Confirm Placements" reverts all labels to their base counts immediately, before the next server `game_state` arrives.

**Why human:** SVG DOM mutation during the reinforcement phase must be observed in a live browser. Static analysis confirms the code path exists but cannot confirm rendering behavior.

### 3. Post-Conquest Advance Armies Modal (GAP-02)

**Test:** Start a game with a human player. Attack an enemy territory with 3 dice and win the battle.

**Expected:**
- The "Move armies" modal appears with label "Advance armies from [Source] into [Target] (min: 3)".
- Input min is set to the number of dice used in the winning roll.
- Input max is set to the source territory's remaining armies minus 1.
- After confirming a value between min and max, the SVG map shows the chosen army count in the captured territory.
- Bot players (Easy or Medium) do not pause for this prompt — their turns continue without interruption.

**Why human:** The modal appearance, correct min/max values, and resulting map update depend on a real conquest event in a live browser session. Bot non-interruption also requires live observation.

---

_Verified: 2026-03-09_
_Verifier: Claude (gsd-verifier)_
