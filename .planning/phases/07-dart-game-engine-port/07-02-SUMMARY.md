---
phase: 07-dart-game-engine-port
plan: 02
subsystem: testing
tags: [dart, flutter, combat, dice, game-engine, tdd]

# Dependency graph
requires:
  - phase: 07-01
    provides: FakeRandom helper and test stubs for combat/setup
provides:
  - MapGraph.continentNames getter
  - actions.dart sealed class hierarchy (AttackChoice, AttackAction, BlitzAction, FortifyAction, ReinforcePlacementAction, TradeCardsAction)
  - combat.dart: CombatResult, resolveCombat, validateAttack, executeAttack, executeBlitz
  - setup.dart: startingArmies const, setupGame function
affects: [07-03, 07-04, reinforcements, turn]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dart 3.x records for multi-return: (GameState, CombatResult, bool)"
    - "Map.of() copy-then-mutate-then-copyWith for immutable GameState updates"
    - "FakeRandom(List<int> faces) with nextInt(6)+1 == face value for deterministic dice tests"
    - "Statistical tests use 100000 trials with seeded Random(42) for stable 0.5% tolerance"
    - "Sealed class hierarchy for AttackChoice — no const constructors on subclasses"

key-files:
  created:
    - mobile/lib/engine/actions.dart
    - mobile/lib/engine/combat.dart
    - mobile/lib/engine/setup.dart
    - mobile/test/engine/combat_test.dart
    - mobile/test/engine/setup_test.dart
  modified:
    - mobile/lib/engine/map_graph.dart

key-decisions:
  - "Statistical tests use 100000 trials (not 10000) — 10k with seed 42 gave 0.3659 vs 0.3717 target, outside 0.5% tolerance; 100k converges reliably"
  - "AttackAction/BlitzAction drop const constructors — sealed superclass has no const constructor, Dart disallows const on subclass"
  - "validateAttack throws ArgumentError (not ValueError) — idiomatic Dart uses ArgumentError for invalid argument preconditions"

patterns-established:
  - "Pattern 1: All engine files zero Flutter imports — verified with grep before commit"
  - "Pattern 2: FakeRandom provides exact die-face values in list; nextInt(max) returns (face-1)"

requirements-completed: [DART-01, DART-06]

# Metrics
duration: ~20min
completed: 2026-03-15
---

# Phase 7 Plan 02: Combat Engine and Setup Summary

**Dart port of combat engine (dice resolution, attack, blitz) and game setup with FakeRandom-controlled tests and 100k-trial statistical validation**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-15T06:30:00Z
- **Completed:** 2026-03-15T06:52:33Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- MapGraph.continentNames getter (1 line) enables reinforcements.dart continent iteration
- actions.dart sealed hierarchy: AttackChoice / AttackAction / BlitzAction + FortifyAction, ReinforcePlacementAction, TradeCardsAction
- combat.dart: full DART-01 + DART-06 implementation — resolveCombat (descending sort, tie→defender), validateAttack (4 preconditions), executeAttack (conquest + ownership transfer), executeBlitz (loop to conquest or 1-army stop)
- setup.dart: startingArmies const map, setupGame with round-robin territory deal and random army distribution
- 27 tests passing across map_graph, combat, and setup suites (0 skipped, 0 failures)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add continentNames to MapGraph, create actions.dart sealed hierarchy** - `520c5fc` (feat)
2. **Task 2: Implement combat.dart and setup.dart, enable combat tests** - `b3baa32` (feat)

## Files Created/Modified
- `mobile/lib/engine/map_graph.dart` - Added `continentNames` getter (1 line)
- `mobile/lib/engine/actions.dart` - Sealed AttackChoice hierarchy and all action data classes
- `mobile/lib/engine/combat.dart` - CombatResult, resolveCombat, validateAttack, executeAttack, executeBlitz
- `mobile/lib/engine/setup.dart` - startingArmies const, setupGame with round-robin + random army distribution
- `mobile/test/engine/combat_test.dart` - 14 tests: FakeRandom-controlled, validation, blitz lifecycle, 100k statistical
- `mobile/test/engine/setup_test.dart` - 5 tests: army counts, territory ownership, invalid player count

## Decisions Made
- **100k statistical trials**: 10k with seed 42 produced 0.3659 vs 0.3717 target (0.0058 > 0.005 tolerance). Increased to 100k for reliable convergence within tolerance.
- **ArgumentError not ValueError**: Dart idiom for invalid argument preconditions is `ArgumentError`; Python uses `ValueError`. Translation uses the idiomatic Dart exception type.
- **No const constructors on AttackAction/BlitzAction**: Dart prohibits `const` on subclasses when the sealed superclass has no `const` constructor. Removed `const` from constructors.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dart sealed class const constructor incompatibility**
- **Found during:** Task 2 (test compilation)
- **Issue:** `const AttackAction(...)` and `const BlitzAction(...)` fail to compile — sealed superclass `AttackChoice` has no const constructor
- **Fix:** Removed `const` keyword from AttackAction and BlitzAction constructors in actions.dart
- **Files modified:** mobile/lib/engine/actions.dart
- **Verification:** Compilation succeeds, tests pass
- **Committed in:** 520c5fc (Task 1 commit, retroactively part of that file)

**2. [Rule 1 - Bug] Statistical test tolerance too tight for 10k trials**
- **Found during:** Task 2 (statistical test failure)
- **Issue:** 10000 trials with seed 42 yielded attacker-wins-both rate of 0.3659 vs expected 0.3717, difference 0.0058 > tolerance 0.005
- **Fix:** Increased trial count to 100000; at that scale seed 42 converges within 0.5% of theoretical
- **Files modified:** mobile/test/engine/combat_test.dart
- **Verification:** Both statistical tests pass with 100k trials
- **Committed in:** b3baa32 (Task 2 commit)

**3. [Rule 1 - Bug] FakeRandom dice count mismatch in test fixtures**
- **Found during:** Task 2 (executeAttack and executeBlitz test failures)
- **Issue:** Test fixtures provided insufficient values for FakeRandom — executeAttack calls min(2, armies) defender dice (2 for armies>=2), not 1; executeBlitz with 2-army attacker calls min(2, 10)=2 defender dice
- **Fix:** Updated FakeRandom lists in test cases to provide correct number of die values
- **Files modified:** mobile/test/engine/combat_test.dart
- **Verification:** All FakeRandom-controlled tests pass without StateError
- **Committed in:** b3baa32 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)
**Impact on plan:** All fixes were test-fixture and Dart language correctness. No scope creep, no architectural changes.

## Issues Encountered
- Dart `List.generate` with `..sort()` (cascade) correctly returns the list in-place; confirmed idiomatic pattern works for descending dice sort.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- combat.dart and setup.dart are the foundational layer; turn.dart (Plan 03) and reinforcements.dart (Plan 04) depend on these
- All action types defined and ready for consumption by turn.dart
- MapGraph.continentNames available for reinforcements bonus calculation
- Zero Flutter imports in all engine files — safe for isolate execution

---
*Phase: 07-dart-game-engine-port*
*Completed: 2026-03-15*
