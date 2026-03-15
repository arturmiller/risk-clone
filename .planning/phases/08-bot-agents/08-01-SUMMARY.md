---
phase: 08-bot-agents
plan: 01
subsystem: testing
tags: [dart, flutter, bots, tdd, random-agent, simulation]

# Dependency graph
requires:
  - phase: 07-dart-game-engine
    provides: "executeTurn, PlayerAgent interface, MapGraph, GameState, FakeRandom"

provides:
  - "EasyAgent: Dart port of Python RandomAgent with constructor-injected MapGraph"
  - "simulation.dart: runGame() helper for win rate tests and Phase 12 simulation mode"
  - "5 test stub files: easy_agent_test (green), medium/hard/win_rate/isolate (empty, compile-clean)"

affects:
  - 08-02 (MediumAgent — uses EasyAgent pattern and simulation.dart)
  - 08-03 (win_rate_test and isolate_test stubs become real)
  - phase-12 (simulation mode imports runGame)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "EasyAgent constructor-injection pattern: EasyAgent({required MapGraph mapGraph, Random? rng})"
    - "nextInt(2)==1 for 50% skip (replaces Python rng.random() < 0.5 for FakeRandom compatibility)"
    - "nextInt(100)<15 for 15% abort (replaces Python rng.random() < 0.15 for FakeRandom compatibility)"
    - "TDD: RED commit (failing tests) then GREEN commit (implementation) in same plan"

key-files:
  created:
    - mobile/lib/bots/easy_agent.dart
    - mobile/lib/engine/simulation.dart
    - mobile/test/bots/easy_agent_test.dart
    - mobile/test/bots/medium_agent_test.dart
    - mobile/test/bots/hard_agent_test.dart
    - mobile/test/bots/win_rate_test.dart
    - mobile/test/bots/isolate_test.dart
  modified: []

key-decisions:
  - "EasyAgent uses nextInt(2)==1 for 50% fortify skip — Python rng.random() replaced for FakeRandom compatibility (FakeRandom throws on nextDouble)"
  - "EasyAgent uses nextInt(100)<15 for 15% attack abort — same reason as above"
  - "simulation.dart uses Fisher-Yates shuffle inline (not List.shuffle) to use the provided rng parameter"

patterns-established:
  - "Bot constructor pattern: Bot({required MapGraph mapGraph, Random? rng}) — zero Flutter imports"
  - "FakeRandom-safe API: use nextInt() variants only, never nextDouble() or nextBool() in bot logic"

requirements-completed: [BOTS-05]

# Metrics
duration: 4min
completed: 2026-03-15
---

# Phase 8 Plan 01: EasyAgent + Test Stubs + Simulation Helper Summary

**EasyAgent (RandomAgent Dart port) with constructor-injected MapGraph, runGame() simulation helper, and Wave-0 test stubs — 16 new tests pass, 97/97 total green**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-15T18:22:34Z
- **Completed:** 2026-03-15T18:26:00Z
- **Tasks:** 2 (TDD RED + GREEN)
- **Files modified:** 7

## Accomplishments

- EasyAgent implements all 5 PlayerAgent methods with constructor-injected MapGraph/Random
- simulation.dart runGame() drives full game loop from setup to victory (or throws StateError at maxTurns)
- 5 test stub files created for Wave-0 Nyquist compliance (4 stubs empty but compile-clean)
- 16 EasyAgent unit tests cover all correctness invariants (placement, attack validity, fortify connectivity, card trade logic)
- Full suite stays green: 97/97 tests pass (81 prior + 16 new)

## Task Commits

TDD commits:

1. **RED: Test stubs + failing easy_agent_test** - `30d1449` (test)
2. **GREEN: easy_agent.dart + simulation.dart** - `8498eb0` (feat)

**Plan metadata:** _(this commit)_

## Files Created/Modified

- `mobile/lib/bots/easy_agent.dart` - EasyAgent implementing PlayerAgent (RandomAgent port)
- `mobile/lib/engine/simulation.dart` - runGame() full-game helper
- `mobile/test/bots/easy_agent_test.dart` - 16 unit tests (all pass)
- `mobile/test/bots/medium_agent_test.dart` - stub (Plan 02)
- `mobile/test/bots/hard_agent_test.dart` - stub (Plan 02)
- `mobile/test/bots/win_rate_test.dart` - stub (Plan 03)
- `mobile/test/bots/isolate_test.dart` - stub (Plan 03)

## Decisions Made

- `nextInt(2)==1` replaces Python's `rng.random() < 0.5` for fortify skip — FakeRandom throws UnimplementedError on nextDouble(), so nextInt-based equivalent required
- `nextInt(100)<15` replaces Python's `rng.random() < 0.15` for attack abort — same reason
- Fisher-Yates shuffle implemented inline in simulation.dart using the provided `rng` parameter (List.shuffle doesn't accept an external rng in all Dart versions)

## Deviations from Plan

None — plan executed exactly as written. The nextInt(2) and nextInt(100) replacements for Python's rng.random() were explicitly documented in the plan's implementation notes.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- EasyAgent is validated and ready to use as a baseline agent in win rate simulations
- simulation.dart runGame() is ready for Plan 03 win rate tests and Phase 12 simulation mode
- MediumAgent (Plan 02) can follow the same constructor-injection pattern
- Stub test files are ready to be filled in (Plans 02 and 03)

---
*Phase: 08-bot-agents*
*Completed: 2026-03-15*
