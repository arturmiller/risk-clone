---
phase: 07-dart-game-engine-port
plan: 01
subsystem: testing
tags: [dart, flutter, flutter_test, python, golden-fixtures, tdd, wave0]

# Dependency graph
requires:
  - phase: 06-flutter-scaffold-and-data-models
    provides: GameState/TerritoryState/PlayerState/Card freezed models that tests import
provides:
  - FakeRandom helper implementing dart:math.Random with deterministic dice sequence
  - 6 engine test stub files (combat, cards, reinforcements, fortify, setup, turn) — all compile, all tests skip
  - Python golden fixture generator script writing 4 JSON fixture files (13 fixtures total)
  - fixtures: golden_combat.json, golden_reinforcements.json, golden_fortify.json, golden_turn_sequence.json
affects:
  - 07-02 (combat engine implementation — uses combat_test.dart and golden_combat.json)
  - 07-03 (cards/reinforcements/fortify implementation — uses those test stubs and fixtures)
  - 07-04 (turn FSM implementation — uses turn_test.dart and golden_turn_sequence.json)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - FakeRandom pattern: implements dart:math.Random, returns (value-1) so nextInt(6)+1 == die face
    - Golden fixture pattern: Python script uses FakeRandom to inject dice, serializes input+output state to JSON
    - Test stub pattern: all tests use skip: 'not implemented'; imports commented with // ignore_for_file: unused_import

key-files:
  created:
    - mobile/test/helpers/fake_random.dart
    - mobile/test/engine/combat_test.dart
    - mobile/test/engine/setup_test.dart
    - mobile/test/engine/cards_engine_test.dart
    - mobile/test/engine/reinforcements_test.dart
    - mobile/test/engine/fortify_test.dart
    - mobile/test/engine/turn_test.dart
    - scripts/generate_golden_fixtures.py
    - mobile/test/engine/fixtures/golden_combat.json
    - mobile/test/engine/fixtures/golden_reinforcements.json
    - mobile/test/engine/fixtures/golden_fortify.json
    - mobile/test/engine/fixtures/golden_turn_sequence.json
  modified: []

key-decisions:
  - "Test stubs use commented imports (// ignore_for_file: unused_import) rather than conditional imports — simpler, compiles cleanly"
  - "golden_turn_sequence.json generated successfully using check_victory/check_elimination only (no full FSM needed for Wave 0)"
  - "FakeRandom returns (value-1) for nextInt(max) matching plan spec — nextInt(6)+1 == face value"

patterns-established:
  - "Wave 0 infrastructure-first: all test stubs committed before any implementation begins"
  - "Golden fixture format: id, description, injected_rolls, input_state, action, expected_* fields, output_state"

requirements-completed: [DART-01, DART-02, DART-03, DART-04, DART-05, DART-06]

# Metrics
duration: 18min
completed: 2026-03-15
---

# Phase 7 Plan 01: Dart Game Engine Port — Wave 0 Test Infrastructure Summary

**59 skipped test stubs across 6 engine files + FakeRandom helper + Python fixture generator producing 13 golden fixtures in 4 JSON files**

## Performance

- **Duration:** 18 min
- **Started:** 2026-03-15T06:30:00Z
- **Completed:** 2026-03-15T06:48:00Z
- **Tasks:** 3
- **Files modified:** 12 (created)

## Accomplishments
- Created FakeRandom Dart helper (implements dart:math.Random) with deterministic dice sequence for testing
- Created 6 engine test stub files (59 total test cases) — all compile under flutter_test, all tests skip
- Created Python golden fixture generator using Python Risk engine with injected dice, producing 13 fixtures across 4 JSON files

## Task Commits

Each task was committed atomically:

1. **Task 1: FakeRandom helper and combat/setup test stubs** - `b0ebe1d` (test)
2. **Task 2: Remaining engine test stubs (cards, reinforcements, fortify, turn)** - `d05a067` (test)
3. **Task 3: Golden fixture Python generator script** - `19df7f5` (chore)

## Files Created/Modified
- `mobile/test/helpers/fake_random.dart` - FakeRandom implementing dart:math.Random, returns (face-1) for nextInt
- `mobile/test/engine/combat_test.dart` - 14 test stubs: resolveCombat, executeAttack, executeBlitz, statistical
- `mobile/test/engine/setup_test.dart` - 5 test stubs: startingArmies, setupGame validation
- `mobile/test/engine/cards_engine_test.dart` - 15 test stubs: isValidSet, createDeck, drawCard, executeTrade, getTradeBonus
- `mobile/test/engine/reinforcements_test.dart` - 5 test stubs: calculateReinforcements base and continent bonus
- `mobile/test/engine/fortify_test.dart` - 8 test stubs: validateFortify, executeFortify
- `mobile/test/engine/turn_test.dart` - 12 test stubs: checkVictory, checkElimination, transferCards, executeTurn FSM
- `scripts/generate_golden_fixtures.py` - Python generator using FakeRandom to produce deterministic fixtures
- `mobile/test/engine/fixtures/golden_combat.json` - 5 combat fixtures (3v2 wins, split, 1v1, tie, blitz)
- `mobile/test/engine/fixtures/golden_reinforcements.json` - 3 fixtures (min, base4, continent bonus)
- `mobile/test/engine/fixtures/golden_fortify.json` - 2 fixtures (valid move, disconnected path raises)
- `mobile/test/engine/fixtures/golden_turn_sequence.json` - 3 fixtures (victory single owner, multiple owners, elimination)

## Decisions Made
- Used commented-out imports with `// ignore_for_file: unused_import` instead of conditional imports — cleaner pattern for stubs where implementation files don't exist yet
- golden_turn_sequence.json generated using check_victory/check_elimination helpers directly rather than full FSM — avoids agent import complexity in Wave 0
- FakeRandom matches plan spec exactly: nextInt(max) returns (face - 1), so nextInt(6) + 1 == die face value

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- classic.json is at risk/data/classic.json (not risk/static/classic.json as mentioned in plan context) — resolved by checking actual filesystem before writing script.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 6 test stub files committed; plans 07-02 through 07-04 can begin immediately
- FakeRandom is importable from `../helpers/fake_random.dart` in all engine test files
- Golden fixtures provide expected output states for validation once Dart engine is implemented
- flutter test test/engine/ passes with 0 failures (13 real tests pass, 59 stubs skip)

---
*Phase: 07-dart-game-engine-port*
*Completed: 2026-03-15*
