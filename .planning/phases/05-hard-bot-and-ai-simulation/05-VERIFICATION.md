---
phase: 05-hard-bot-and-ai-simulation
verified: 2026-03-14T00:00:00Z
status: gaps_found
score: 8/10 must-haves verified
gaps:
  - truth: "Simulation game runs to completion and shows game_over"
    status: failed
    reason: "Uncommitted changes to risk/engine/cards.py (card recycling via non-seeded random.shuffle) cause unbounded army growth, making 2-player bot-only games never reach victory within any practical turn limit. The working tree has these changes active despite SUMMARY claiming they were reverted in commit 60ffc2b."
    artifacts:
      - path: "risk/engine/cards.py"
        issue: "Uncommitted change: traded cards recycled back into deck via random.shuffle (lines 143-145). Causes army count to grow unboundedly. Should be either properly reverted to HEAD or committed with seeded RNG fix."
      - path: "risk/engine/turn.py"
        issue: "Uncommitted change: BlitzAction support added. Depends on cards.py fix. Also present in working tree despite claimed revert."
    missing:
      - "Revert risk/engine/cards.py to HEAD (git checkout -- risk/engine/cards.py) OR fix the card recycling to use seeded RNG and verify game completion"
      - "Revert risk/engine/turn.py to HEAD (git checkout -- risk/engine/turn.py) OR commit and verify it works correctly with the card fix"
      - "Verify tests/test_simulation.py::TestSimulationCompletion passes after fix"
  - truth: "Hard bot wins >= 55% of 1v1 games against Medium bot in 100-game batch"
    status: partial
    reason: "The batch test (TestHardBatch) is marked @pytest.mark.slow and passes when run (SUMMARY reports 80/100 wins). However, the broken cards.py state means the CURRENT codebase behavior may differ from what was validated. Test was run against a clean working tree state. Marking as partial because the underlying engine inconsistency introduces uncertainty."
    artifacts:
      - path: "risk/engine/cards.py"
        issue: "Same uncommitted card recycling change affects batch game behavior (though 1000-turn cap makes batch tests complete before stagnation)"
    missing:
      - "Resolve working tree state (revert or commit engine changes) and re-run batch test to confirm results hold"
human_verification:
  - test: "Play vs Hard bots in browser"
    expected: "Hard bot reinforces borders, attacks strategically, times card trades"
    why_human: "Strategic quality of play cannot be verified programmatically"
  - test: "Watch AI Game simulation mode in browser"
    expected: "Human controls hidden, all players named Bot N, map updates each turn, game_over overlay shown at end"
    why_human: "End-to-end browser behavior with visual confirmation required"
  - test: "Difficulty dropdown shows Hard option"
    expected: "Easy, Medium, Hard options present in select element"
    why_human: "Already confirmed by static HTML inspection (Hard option present), but browser render verification is standard"
---

# Phase 5: Hard Bot and AI Simulation — Verification Report

**Phase Goal:** The Hard bot plays at human-competitive level, delivering the project's core value, and users can watch bot-only games
**Verified:** 2026-03-14
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | HardAgent class exists and satisfies PlayerAgent protocol | VERIFIED | `risk/bots/hard.py` has all 7 protocol methods: `choose_reinforcement_placement`, `choose_attack`, `choose_blitz`, `choose_fortify`, `choose_card_trade`, `choose_advance_armies`, `choose_defender_dice` |
| 2 | Hard bot demonstrates observable strategic play (continent completion, border concentration, card timing, threat assessment) | VERIFIED | Full multi-factor implementation in `hard.py`: `_continent_scores`, `_border_security_ratio`, `_opponent_threat_scores`, `_best_trade`. All 14 unit tests pass. |
| 3 | Hard bot wins against Medium bots significantly more often than chance | PARTIAL | SUMMARY reports 80/100 (80%) in batch test. TestHardBatch passes when run. However, working tree has broken engine changes that were not actually reverted, creating uncertainty about current behavior. |
| 4 | HardAgent concentrates reinforcements on vulnerable border territories | VERIFIED | `choose_reinforcement_placement` ranks by BSR * BORDER_SECURITY_WEIGHT + continent score; concentrates on top 1-2 territories. `TestHardReinforce` passes. |
| 5 | HardAgent attacks with multi-priority ordering | VERIFIED | `choose_attack` implements 4-priority chain: continent-complete > block-opponent > high-value > overwhelming force. `TestHardAttack` passes. |
| 6 | HardAgent holds cards until 4 in hand or high escalation | VERIFIED | `choose_card_trade` holds at <4 cards when `trade_count < 4`. `TestHardCardTiming` passes. |
| 7 | User can select 'Watch AI Game' mode from the setup screen | VERIFIED | `index.html` line 31-34: `<select id="game-mode">` with `play` and `simulation` options. `app.js` line 61-64 reads `gameModeSelect.value` and sends `game_mode` in WebSocket message. |
| 8 | In simulation mode, all players are bots (no human agent) | VERIFIED | `game_manager.py` lines 86-90: `if game_mode == "simulation"` sets `human_agent = None` and creates bots for all players. `TestSimulationMode` (3 tests) passes. |
| 9 | Simulation game runs to completion and shows game_over | FAILED | `TestSimulationCompletion` (2 tests) fail: `test_simulation_game_completes` and `test_simulation_emits_game_over` both time out after 30s without receiving `game_over`. Root cause: uncommitted `risk/engine/cards.py` change causes card recycling with non-seeded `random.shuffle`, producing unbounded army growth. Games send 10,000+ messages but never conclude. |
| 10 | Map and game log update in real-time during simulation | VERIFIED | `_run_simulation_loop` sends `state_to_message` and `_emit_turn_events` each turn. `app.js` processes `game_state` and `game_event` messages identically in simulation mode. |

**Score:** 8/10 truths verified (1 failed, 1 partial)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `risk/bots/hard.py` | Full HardAgent with multi-factor scoring (min 200 lines) | VERIFIED | 549 lines. Exports `HardAgent`. Imports `is_valid_set`, `MapGraph`, all action models. |
| `risk/bots/__init__.py` | HardAgent export | VERIFIED | Exports `HardAgent` and `MediumAgent`. |
| `tests/test_hard_agent.py` | Passing unit tests for all HardAgent strategy methods | VERIFIED | 14 tests across `TestHardReinforce`, `TestHardAttack`, `TestHardCardTiming`, `TestHardThreat`, `TestHardAdvance`, `TestHardFullGame`. All pass in 4.51s. `TestHardBatch` marked `@pytest.mark.slow`. |
| `tests/test_simulation.py` | Passing simulation mode tests | PARTIAL | 3/5 tests pass (`TestSimulationMode`). 2 fail (`TestSimulationCompletion`). |
| `risk/server/game_manager.py` | Simulation mode via `game_mode` parameter | VERIFIED | `setup()` accepts `game_mode` (line 55). `_run_simulation_loop()` method exists (line 193). `start_game()` dispatches to it when `game_mode == "simulation"` (lines 112-115). |
| `risk/server/messages.py` | `game_mode` field on `StartGameMessage` | VERIFIED | Line 64: `game_mode: str = "play"` |
| `risk/server/app.py` | `game_mode` passthrough | VERIFIED | Line 74: `game_mode = data.get("game_mode", "play")`. Line 81: `game_mode=game_mode` passed to `setup()`. |
| `risk/static/index.html` | Game mode selector with `game-mode` id | VERIFIED | Lines 31-34: `<select id="game-mode">` with `play` and `simulation` options. Hard difficulty option at line 29. |
| `risk/static/app.js` | Simulation mode UI logic | VERIFIED | `isSimulation` variable (line 17). `gameModeSelect` DOM reference (line 36). Controls hidden when `isSimulation` (lines 69-73). `request_input` ignored in simulation (line 138). Game-over shows winner name in simulation (lines 564-565). |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `risk/bots/hard.py` | `risk/player.py` | `class HardAgent` with all 7 protocol methods | VERIFIED | All protocol methods implemented. |
| `risk/bots/hard.py` | `risk/engine/cards.py` | `from risk.engine.cards import is_valid_set` | VERIFIED | Line 11 of `hard.py`. Used in `_best_trade` method. |
| `risk/bots/hard.py` | `risk/engine/map_graph.py` | `self._map_graph` queries | VERIFIED | `_continent_territories`, `neighbors`, `continent_bonus`, `connected_territories`, `_continent_map` all used. |
| `tests/test_hard_agent.py` | `risk/bots/hard.py` | `from risk.bots.hard import HardAgent` | VERIFIED | Line 13. Used throughout all test classes. |
| `tests/test_hard_agent.py` | `risk/game.py` | `run_game` for batch testing | VERIFIED | Line 16. Used in `TestHardFullGame` and `TestHardBatch`. |
| `risk/static/app.js` | `risk/server/app.py` | WebSocket `start_game` message with `game_mode` field | VERIFIED | `app.js` line 64 sends `game_mode: gameMode`. `app.py` line 74 reads `data.get("game_mode", "play")`. |
| `risk/server/app.py` | `risk/server/game_manager.py` | `game_mode=game_mode` passed to `setup()` | VERIFIED | `app.py` line 81. |
| `risk/server/game_manager.py` | `risk/bots/hard.py` | `HardAgent` creation for `difficulty='hard'` | VERIFIED | `game_manager.py` line 13 imports `HardAgent`. Line 77 creates it when `difficulty == "hard"`. |
| `risk/server/game_manager.py` | all-bot agents in simulation | `game_mode == "simulation"` branch | VERIFIED | Lines 86-90 create bots for all players without `HumanWebSocketAgent`. |

---

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BOTS-03 | 05-01, 05-02, 05-04 | Hard bot plays at human-competitive level (threat assessment, army concentration, card timing, continent control) | VERIFIED | `risk/bots/hard.py` implements all 4 named behaviors. 14 unit tests pass. Batch: 80/100 wins vs Medium (reported). Engine inconsistency (dirty working tree) is a risk but tests currently pass against working tree state. |
| BOTS-04 | 05-01, 05-03, 05-04 | AI-vs-AI simulation mode (watch bots play without human player) | PARTIAL | Server + frontend wiring complete and verified. `TestSimulationMode` passes. `TestSimulationCompletion` fails because games never conclude due to uncommitted `cards.py` changes causing unbounded army growth. |

**No orphaned requirements:** REQUIREMENTS.md maps only BOTS-03 and BOTS-04 to Phase 5. Both are claimed by plans. No unmapped phase-5 requirements exist.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `risk/engine/cards.py` | 143-145 | Uncommitted card recycling change uses `random.shuffle` (non-seeded global RNG) | BLOCKER | Causes unbounded army growth in simulation mode; breaks `TestSimulationCompletion`. Contradicts SUMMARY claim of revert. |
| `risk/engine/turn.py` | multiple | Uncommitted BlitzAction support; depends on cards.py fix | WARNING | Creates code inconsistency. Tests pass because they don't exercise blitz paths through simulation, but the working tree is inconsistent with documented intent. |

---

## Human Verification Required

### 1. Hard Bot Strategic Play Quality

**Test:** Start server (`python -m uvicorn risk.server.app:app --reload --port 8000`), select 2 players, difficulty Hard, mode Play vs Bots, start game. Play several turns.
**Expected:** Bot reinforces border territories (not random), attacks when it has advantage, works toward continent control, times card trades (holds at 3 cards, trades at 4+).
**Why human:** Strategic quality of play cannot be verified from unit tests alone.

### 2. AI-vs-AI Simulation Mode (after engine fix)

**Test:** After resolving the cards.py working tree issue, select 3 players, any difficulty, Watch AI Game mode. Start game.
**Expected:** Human controls (dice panel, action buttons) are hidden. All players named "Bot 1", "Bot 2", "Bot 3". Map updates each turn. Game log shows attacks and conquests. Game ends with game_over overlay showing "Game Over - Bot N wins!".
**Why human:** End-to-end browser rendering and visual confirmation needed.

### 3. Difficulty Dropdown Hard Option

**Test:** Open setup screen in browser.
**Expected:** Difficulty dropdown shows Easy, Medium, Hard options.
**Why human:** Static HTML already verified; browser render confirmation is standard.

---

## Gaps Summary

**Root cause: Working tree inconsistency.** The SUMMARY for Plan 05-04 documents that `risk/engine/cards.py` and `risk/engine/turn.py` were "reverted" before committing. Commit `60ffc2b` is described as containing this revert. However, `git show --stat 60ffc2b` reveals the commit only touched `tests/test_hard_agent.py` and `.planning/.../deferred-items.md` — it did NOT touch the engine files. Both `risk/engine/cards.py` and `risk/engine/turn.py` remain in a modified state in the working tree with the problematic changes active.

**Impact:** The card recycling change in `cards.py` causes traded cards to be shuffled back into the deck using a non-seeded `random.shuffle`, which (combined with the escalating trade bonus) produces rapid army accumulation. 2-player bot games running in the `_run_simulation_loop` never reach the 5000-turn cap within reasonable test timeouts because the game engine produces pathological states. This causes `TestSimulationCompletion::test_simulation_game_completes` and `test_simulation_emits_game_over` to time out and fail.

**What is working correctly:**
- All HardAgent strategy implementation (14 unit tests pass)
- Full server-side simulation mode wiring (GameManager, messages.py, app.py)
- Full frontend simulation mode (index.html, app.js)
- TestSimulationMode (agent creation, bot naming) passes

**What needs to be fixed:**
- Either revert `risk/engine/cards.py` and `risk/engine/turn.py` to HEAD, or commit them with proper fixes (seeded RNG, verification of game completion)
- After fix: verify `TestSimulationCompletion` passes

---

_Verified: 2026-03-14_
_Verifier: Claude (gsd-verifier)_
