---
phase: 08-bot-agents
plan: 02
subsystem: bots
tags: [dart, flutter, risk, bots, tdd, medium-agent, hard-agent, attack-probability, bsr]

# Dependency graph
requires:
  - phase: 08-bot-agents/08-01
    provides: EasyAgent reference implementation, PlayerAgent interface, MapGraph constructor-injection pattern
  - phase: 07-engine-dart
    provides: complete Dart engine (GameState, MapGraph, actions, cards_engine)

provides:
  - MediumAgent: continent-aware bot implementing PlayerAgent (BOTS-06)
  - HardAgent: human-competitive bot implementing PlayerAgent (BOTS-07)
  - attackProbabilities const at file scope in hard_agent.dart
  - 40 new unit tests (19 MediumAgent + 21 HardAgent)

affects:
  - 08-03-PLAN (win_rate_test uses HardAgent)
  - Phase 9 (HumanAgent wires same PlayerAgent interface)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Constructor-injected MapGraph (no late injection); both agents follow EasyAgent pattern
    - File-scope top-level functions for Isolate.run() compatibility (_estimateWinProbability, _lookupProb)
    - attackProbabilities as file-scope const with string key encoding ('attDice,defDice')
    - BSR (Border Security Ratio) for HardAgent territory scoring
    - TDD: RED (test stub) → GREEN (implementation) → commit each phase

key-files:
  created:
    - mobile/lib/bots/medium_agent.dart
    - mobile/lib/bots/hard_agent.dart
    - mobile/test/bots/medium_agent_test.dart
    - mobile/test/bots/hard_agent_test.dart
  modified: []

key-decisions:
  - "Test for first failing test had incorrect setup (T4 owned by player 0 made T3 non-border); fixed test setup to match intended scenario — deviation Rule 1"
  - "attackProbabilities and _estimateWinProbability placed at file scope, not class scope — Isolate.run() compatibility"
  - "FakeRandom not used in MediumAgent/HardAgent tests — deterministic behavior doesn't require RNG seeding (all choices are logical, not random)"

patterns-established:
  - "Both MediumAgent and HardAgent use only MapGraph public API (continentNames, continentTerritories, continentOf, continentBonus) — no private field access"
  - "HardAgent chooseAdvanceArmies: interior source → max; safe target with exposed source → min; no source enemies → max; both exposed → proportional"

requirements-completed:
  - BOTS-06
  - BOTS-07

# Metrics
duration: 7min
completed: 2026-03-15
---

# Phase 08 Plan 02: MediumAgent + HardAgent Ports Summary

**MediumAgent (continent-aware) and HardAgent (BSR-based, ~80% win rate) ported from Python to Dart with 40 unit tests — all 137 tests green**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-15T19:28:41Z
- **Completed:** 2026-03-15T19:35:58Z
- **Tasks:** 4 (RED/GREEN for MediumAgent, RED/GREEN for HardAgent)
- **Files modified:** 4

## Accomplishments
- MediumAgent: 5-method PlayerAgent using continent fraction scoring, external-border targeting, interior-to-weakest-border fortification
- HardAgent: 5-method PlayerAgent with BSR reinforcement concentration, multi-priority attack (continent-complete/block/probability/overwhelming), strategic card timing (hold until 4 or escalation), _estimateWinProbability geometric simulation
- attackProbabilities const at file scope with string keys for Isolate.run() compatibility
- 40 new tests — 19 MediumAgent, 21 HardAgent — all deterministic (no FakeRandom required)
- Full suite: 137/137 tests green; zero Flutter imports confirmed

## Task Commits

Each task was committed atomically:

1. **Task 1: MediumAgent RED (failing tests)** - `de5ad33` (test)
2. **Task 2: MediumAgent GREEN (implementation + test fix)** - `bb8c773` (feat)
3. **Task 3: HardAgent RED (failing tests)** - `943d835` (test)
4. **Task 4: HardAgent GREEN (implementation)** - `4afb383` (feat)

**Plan metadata:** `[docs commit]` (docs: complete plan)

## Files Created/Modified
- `/home/amiller/Repos/risk/mobile/lib/bots/medium_agent.dart` - MediumAgent class implementing PlayerAgent (BOTS-06)
- `/home/amiller/Repos/risk/mobile/lib/bots/hard_agent.dart` - HardAgent class + attackProbabilities const + _estimateWinProbability (BOTS-07)
- `/home/amiller/Repos/risk/mobile/test/bots/medium_agent_test.dart` - 19 unit tests covering all 5 PlayerAgent methods
- `/home/amiller/Repos/risk/mobile/test/bots/hard_agent_test.dart` - 21 unit tests covering BSR, card timing, advance armies, fortify

## Decisions Made
- Test for first failing case had incorrect setup (T4 owned by player 0 made T3 non-border); corrected test to match intended scenario (player 1 owns T4-T6). This is a test correctness fix, not a deviation.
- FakeRandom not used in MediumAgent/HardAgent tests — all agent decisions are deterministic logic (unlike EasyAgent which uses RNG for skipping and shuffling). Tests are cleaner without it.
- attackProbabilities and _estimateWinProbability at file scope per plan spec for Isolate.run() compatibility.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected test setup for first MediumAgent reinforcement test**
- **Found during:** Task 2 (MediumAgent GREEN phase)
- **Issue:** Test had player 0 owning T4, making T3 have no enemy neighbor (T3's neighbors T2 and T4 were both owned). `placements['T3']` was null because T3 was not a border.
- **Fix:** Changed player0Territories to `{'T1': 2, 'T2': 2, 'T3': 1}` with player1Territories `['T4', 'T5', 'T6']`. T3 now borders T4 (enemy) — correctly a border.
- **Files modified:** mobile/test/bots/medium_agent_test.dart
- **Verification:** All 19 MediumAgent tests pass.
- **Committed in:** bb8c773 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — test setup bug)
**Impact on plan:** Minor test fix only. No implementation changes required.

## Issues Encountered
- None beyond the test setup bug documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- MediumAgent and HardAgent complete — Plan 03 (win_rate_test.dart) can now run the 500-game simulation to validate HardAgent ~80% win rate vs MediumAgent
- All three bots (Easy, Medium, Hard) implement PlayerAgent — Phase 9 can wire HumanAgent to same interface

---
*Phase: 08-bot-agents*
*Completed: 2026-03-15*

## Self-Check: PASSED

- FOUND: mobile/lib/bots/medium_agent.dart
- FOUND: mobile/lib/bots/hard_agent.dart
- FOUND: mobile/test/bots/medium_agent_test.dart
- FOUND: mobile/test/bots/hard_agent_test.dart
- FOUND: .planning/phases/08-bot-agents/08-02-SUMMARY.md
- FOUND: de5ad33 (MediumAgent RED), bb8c773 (MediumAgent GREEN), 943d835 (HardAgent RED), 4afb383 (HardAgent GREEN)
