---
phase: 04-easy-and-medium-bots
verified: 2026-03-09T21:30:00Z
status: gaps_found
score: 14/15 automated truths verified
gaps:
  - id: GAP-01
    truth: "Reinforcement units placed are visible on the territory (e.g. shows '4+3' while placing)"
    status: failed
    evidence: "Units placed during reinforcement phase are not shown on the territory — no pending-placement indicator in the UI"
  - id: GAP-02
    truth: "After winning an attack the attacker is prompted to choose how many units to move into the captured territory (min = dice used, max = attackers - 1)"
    status: failed
    evidence: "No movement prompt shown after capturing a territory — units are moved automatically without player choice"
re_verification:
  previous_status: gaps_found
  previous_score: 12/15
  gaps_closed:
    - "MediumAgent reinforces on border of highest-scoring continent (test_reinforce_places_on_border_of_top_continent now PASSED, no xfail)"
    - "test_reinforce_places_on_border_of_top_continent converted to regular passing test (xfail removed from TestMediumAgentReinforce)"
    - "Full test suite passes with zero xfails: 220 passed, 13 xpassed, 0 xfailed, exit 0"
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
      and absence of runtime errors cannot be verified programmatically. Plan 04 required
      human browser verification.
---

# Phase 4: Easy and Medium Bots — Verification Report

**Phase Goal:** AI opponents provide a fun game experience at two difficulty levels, validating the bot framework for the Hard bot.
**Verified:** 2026-03-09
**Status:** human_needed
**Re-verification:** Yes — after gap closure (plan 05)

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Test file exists with all 5 test classes | VERIFIED | `tests/test_medium_agent.py` — 17 tests across TestMapLoads, TestDifficultyWiring, TestMediumAgentReinforce, TestMediumAgentAttack, TestMediumAgentFortify, TestFullGameIntegration |
| 2 | `risk/bots/` package is importable | VERIFIED | `risk/bots/__init__.py` imports MediumAgent from `risk.bots.medium` |
| 3 | MediumAgent implements all 6 PlayerAgent protocol methods | VERIFIED | `risk/bots/medium.py` lines 70–293: choose_reinforcement_placement, choose_attack, choose_blitz, choose_fortify, choose_card_trade, choose_defender_dice |
| 4 | MediumAgent reinforces on border of highest-scoring continent | VERIFIED | `test_reinforce_places_on_border_of_top_continent` is PASSED (no xfail marker). Two-tier external_borders logic in medium.py lines 107–118 correctly selects Indonesia (borders Siam outside Australia) over New Guinea/Western Australia. |
| 5 | MediumAgent attacks into top continent with favorable odds, or completes continent despite slight disadvantage | VERIFIED | XPASS: test_attack_targets_top_continent, test_attack_completes_continent |
| 6 | MediumAgent fortifies from interior toward border, leaving at least 1 army at source | VERIFIED | XPASS: test_fortify_moves_toward_border, test_fortify_skips_no_surplus, test_fortify_leaves_at_least_one_army |
| 7 | run_game() injects map_graph into MediumAgent via duck-typing | VERIFIED | `risk/game.py` line 170: `if hasattr(agent, '_map_graph'):` |
| 8 | MediumAgent completes a full game without stalling or crashing | VERIFIED | XPASS: test_full_game_medium_bot, test_full_game_medium_bot_no_stall (max_turns=500) |
| 9 | StartGameMessage accepts difficulty field with default 'easy' | VERIFIED | `risk/server/messages.py` line 61: `difficulty: str = "easy"` |
| 10 | GameManager.setup() creates RandomAgent for easy, MediumAgent for medium | VERIFIED | XPASS: all 3 TestDifficultyWiring tests. `risk/server/game_manager.py` lines 78–81 |
| 11 | Browser setup screen shows Difficulty dropdown with Easy and Medium options | VERIFIED | `risk/static/index.html` lines 25–27: `<select id="difficulty">` with Easy/Medium options |
| 12 | Clicking Start Game sends difficulty value in WebSocket start_game message | VERIFIED | `risk/static/app.js` line 53: `difficulty: difficultySelect.value` included in send |
| 13 | Full test suite passes (no regressions) | VERIFIED | `python -m pytest tests/ -q`: 220 passed, 13 xpassed, 0 xfailed, 6 warnings — exit 0 |
| 14 | All xfail markers removed from TestMediumAgentReinforce (tests converted to passing) | VERIFIED | TestMediumAgentReinforce class has no xfail decorator. test_reinforce_places_on_border_of_top_continent, test_reinforce_fallback_any_border, test_reinforce_fallback_random all show as PASSED. |
| 15 | Human browser verification: Easy/Medium games play correctly | NEEDS HUMAN | Cannot verify visual behavior, strategic AI differences, or absence of runtime errors programmatically. |

**Score:** 14/15 automated truths verified, 1 truth needs human

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `risk/bots/__init__.py` | bots package init exporting MediumAgent | VERIFIED | Exists, imports and re-exports MediumAgent |
| `risk/bots/medium.py` | MediumAgent with continent-aware strategy and external_borders fix | VERIFIED | Exists, 293 lines, all 6 protocol methods substantively implemented, external_borders two-tier selection at lines 107–118 |
| `risk/game.py` | run_game() with hasattr duck-typing injection | VERIFIED | `if hasattr(agent, '_map_graph'):` — wired correctly |
| `tests/test_medium_agent.py` | All 17 tests passing, no xfails on TestMediumAgentReinforce | VERIFIED | 4 PASSED + 13 XPASS, 0 XFAIL, 0 failures. TestMediumAgentReinforce class has no xfail decorator. |
| `risk/server/messages.py` | StartGameMessage with difficulty field | VERIFIED | Line 61: `difficulty: str = "easy"` |
| `risk/server/game_manager.py` | setup() with difficulty param and MediumAgent import | VERIFIED | Lines 13, 52, 78–81: import, param, and conditional instantiation |
| `risk/server/app.py` | WebSocket handler parsing difficulty | VERIFIED | Lines 73, 79: `difficulty = data.get("difficulty", "easy")` passed to setup |
| `risk/static/index.html` | Difficulty dropdown in setup form | VERIFIED | Lines 25–27: `<select id="difficulty">` with Easy/Medium options |
| `risk/static/app.js` | start_game message includes difficulty value | VERIFIED | Line 53: `difficulty: difficultySelect.value` |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `risk/static/app.js` | `risk/server/app.py` | WebSocket start_game.difficulty | WIRED | `difficultySelect.value` sent in JSON; server reads `data.get("difficulty", "easy")` |
| `risk/server/app.py` | `risk/server/game_manager.py` | `manager.setup(difficulty=difficulty)` | WIRED | Line 79: `difficulty=difficulty` passed to setup() |
| `risk/server/game_manager.py` | `risk/bots/medium.py` | MediumAgent instantiation when difficulty=='medium' | WIRED | Line 13 import, lines 78–79 conditional instantiation |
| `risk/bots/medium.py` | `risk/engine/map_graph.py` | `self._map_graph.neighbors()`, `continent_territories()`, `_continent_map`, `_continent_territories` | WIRED | Lines 42–49, 97, 107, 139, 161, 173, 204 — all map_graph methods used substantively |
| `choose_reinforcement_placement` | `mg.continent_territories()` | external_borders filter excludes neighbors inside the continent | WIRED | Lines 107–118: `cont_terrs = mg.continent_territories(top_continent)` then `external_borders` filter, then `min(final_candidates, ...)` |
| `risk/game.py` | `risk/bots/medium.py` | `hasattr(agent, '_map_graph')` duck-typing | WIRED | Line 170: injection applies to any agent with `_map_graph` attribute |

---

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BOTS-01 | 04-01-PLAN, 04-03-PLAN, 04-04-PLAN | Easy bot makes random valid moves; selectable via browser difficulty dropdown | SATISFIED | RandomAgent already existed; wired via GameManager.setup(difficulty="easy"), browser dropdown, and WebSocket message — all verified. REQUIREMENTS.md marks BOTS-01 as complete. |
| BOTS-02 | 04-01-PLAN, 04-02-PLAN, 04-03-PLAN, 04-04-PLAN, 04-05-PLAN | Medium bot uses basic strategy (continent focus, reasonable attack decisions) | SATISFIED | MediumAgent implemented and integrated; all strategy behaviors verified. Reinforce now correctly selects external-facing continent borders (external_borders fix). All 17 tests pass. REQUIREMENTS.md marks BOTS-02 as complete. |

No orphaned requirements: REQUIREMENTS.md maps only BOTS-01 and BOTS-02 to Phase 4, consistent with plan declarations. BOTS-03 and BOTS-04 are assigned to Phase 5 and are not claimed by any Phase 4 plan.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `risk/server/app.py` | 29 | `"placeholder"` in HTML fallback docstring | Info | Comment-only, not a code stub — no impact on behavior |

No code-level stubs, empty returns, or unimplemented handlers found.

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

---

## Re-verification Summary

**Gap closed:** The one blocking gap from the initial verification has been resolved by plan 05.

- `choose_reinforcement_placement` in `risk/bots/medium.py` now uses a two-tier selection: `external_borders` (cont_border territories whose enemy neighbor is outside the target continent) are preferred over plain `cont_borders` (any enemy neighbor). When `external_borders` is empty, it falls back to `cont_borders` as before.
- `TestMediumAgentReinforce` class has no `xfail` decorator. `test_reinforce_places_on_border_of_top_continent` passes as a regular PASSED test.
- Full test suite: 220 passed, 13 xpassed, 0 xfailed, exit 0 — no regressions.

All automated requirements for BOTS-01 and BOTS-02 are satisfied. The only remaining item is the human browser verification that was flagged in the initial verification and remains unchanged in scope.

---

_Verified: 2026-03-09_
_Verifier: Claude (gsd-verifier)_
