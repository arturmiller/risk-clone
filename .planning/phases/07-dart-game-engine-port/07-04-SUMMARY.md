---
phase: 07-dart-game-engine-port
plan: 04
subsystem: engine
tags: [dart, turn-engine, fsm, player-agent, combat, cards, reinforcements, fortify]

# Dependency graph
requires:
  - phase: 07-dart-game-engine-port
    provides: combat.dart, cards_engine.dart, reinforcements.dart, fortify.dart, setup.dart, map_graph.dart, game_state models
provides:
  - PlayerAgent abstract class (bots/player_agent.dart) — contract for all player types
  - executeTurn FSM (engine/turn.dart) — top-level orchestrator calling all prior engine modules
  - checkVictory, checkElimination, transferCards pure functions
  - forceTradLoop — handles 5+ card forced trade loop with auto-fallback
  - Advance armies logic (Pitfall 8) — correct min/max bounds for AttackAction vs BlitzAction
  - 12 turn_test.dart tests covering FSM, elimination, card transfer, victory, forced trade, card draw
affects: [08-bot-agents, 09-riverpod-providers, phase-08, phase-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - PlayerAgent abstract class as dependency-injection seam between engine and bot implementations
    - FakeRandom.attackerWins() factory with [5,5,5,0,0] repeating pattern to make blitz deterministic in tests
    - String key pattern enforced: cards[playerIndex.toString()] throughout turn.dart
    - Sealed class switch for AttackChoice dispatch (AttackAction vs BlitzAction)

key-files:
  created:
    - mobile/lib/bots/player_agent.dart
    - mobile/lib/engine/turn.dart
    - (updated) mobile/test/engine/turn_test.dart
  modified: []

key-decisions:
  - "FakeRandom.attackerWins() uses [5,5,5,0,0] sequence so 3 attacker dice roll 6 and 1-2 defender dice roll 1 — attacker wins reliably without hardcoding combat internals"
  - "Test map uses 4 territories with A adjacent to both C and D — ensures blitz can eliminate both opponent territories from one source"
  - "MapData constructor requires name field — test must pass name: 'Test'"

patterns-established:
  - "PlayerAgent: all 5 methods (chooseReinforcementPlacement, chooseAttack, chooseFortify, chooseCardTrade, chooseAdvanceArmies) define the Phase 8 bot implementation contract"
  - "executeTurn takes Map<int, PlayerAgent> agents — indexed by player index, supporting multi-player games"
  - "Advance armies after BlitzAction: minArmies=targetNow (already moved), maxArmies=sourceNow+targetNow-1"
  - "Advance armies after AttackAction: minArmies=numDice, maxArmies=sourceNow+numDice-1"

requirements-completed: [DART-05]

# Metrics
duration: 35min
completed: 2026-03-15
---

# Phase 7 Plan 04: Turn FSM and PlayerAgent Interface Summary

**PlayerAgent abstract interface + turn.dart FSM that sequences REINFORCE→ATTACK→FORTIFY with elimination, card transfer, advance armies bounds (Pitfall 8), and victory detection — completing all six DART requirements**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-03-15T07:00:00Z
- **Completed:** 2026-03-15T07:35:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- PlayerAgent abstract class with 5 methods defines the Phase 8 bot implementation contract and Phase 9 human agent wiring point
- turn.dart fully orchestrates all prior engine modules (combat, cards_engine, reinforcements, fortify) under the agent abstraction
- Advance armies logic correctly handles both AttackAction (min=numDice) and BlitzAction (min=targetNow, already moved) — Pitfall 8 from plan
- Elimination flow: isAlive=false, cards transferred, forced trade if 5+ received, victory check within attack loop
- All 12 turn tests pass; full engine suite (72 tests) green

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PlayerAgent abstract class** - `2049bef` (feat)
2. **Task 2 RED: Add failing turn engine tests** - `1fc98fb` (test)
3. **Task 2 GREEN: Implement turn.dart and enable all turn tests** - `6e16045` (feat)

**Plan metadata:** (final docs commit — see below)

_Note: TDD task had RED commit (failing tests) then GREEN commit (implementation + passing tests)_

## Files Created/Modified
- `mobile/lib/bots/player_agent.dart` - Abstract PlayerAgent interface: 5 methods, zero Flutter imports
- `mobile/lib/engine/turn.dart` - Turn FSM: executeTurn, executeReinforcePhase, executeAttackPhase, executeFortifyPhase, checkVictory, checkElimination, transferCards, forceTradLoop, _nextAlivePlayer
- `mobile/test/engine/turn_test.dart` - 12 tests with FakePlayerAgent and FakeRandom.attackerWins()

## Decisions Made
- FakeRandom.attackerWins() uses [5,5,5,0,0] sequence: attacker dice roll 6, defender dice roll 1 — deterministic conquest without mocking combat internals
- Test map uses A adjacent to both C and D so BlitzAction can eliminate both opponent territories from one source
- MapData constructor requires name field (discovered during test compilation)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FakeRandom needed sequence-based implementation for attacker-wins pattern**
- **Found during:** Task 2 (GREEN phase — tests failing)
- **Issue:** Original FakeRandom(returnValue: 5) returned face=6 for ALL dice including defender; ties go to defender so attacker never won blitz
- **Fix:** Rewrote FakeRandom to take a sequence; added FakeRandom.attackerWins() factory with [5,5,5,0,0] repeating pattern
- **Files modified:** mobile/test/engine/turn_test.dart
- **Verification:** All 12 turn tests pass with attacker winning blitz deterministically
- **Committed in:** 6e16045 (Task 2 commit)

**2. [Rule 3 - Blocking] Test map needed A adjacent to D for two-territory elimination tests**
- **Found during:** Task 2 (first test run — adjacency error)
- **Issue:** Original map only had A adjacent to C; BlitzAction(A→D) threw ArgumentError not adjacent
- **Fix:** Added ['A', 'D'] adjacency to buildTestMap()
- **Files modified:** mobile/test/engine/turn_test.dart
- **Verification:** Elimination tests pass; player 1 correctly eliminated
- **Committed in:** 6e16045 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug in test helper, 1 blocking adjacency issue in test setup)
**Impact on plan:** Both fixes were in test infrastructure, not engine implementation. No scope creep.

## Issues Encountered
- MapData constructor requires `name` field (not documented in interfaces section of plan) — discovered immediately on first test compilation, fixed inline

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All DART requirements (DART-01 through DART-05) now have implementations and passing tests
- Phase 8 bot agents can implement PlayerAgent and call executeTurn — the contract is complete
- Phase 9 HumanAgent wires through Riverpod providers implementing PlayerAgent
- Full engine test suite: 72 tests, 0 failures

---
*Phase: 07-dart-game-engine-port*
*Completed: 2026-03-15*
