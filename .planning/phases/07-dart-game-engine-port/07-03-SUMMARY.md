---
phase: 07-dart-game-engine-port
plan: 03
subsystem: testing
tags: [dart, flutter, cards, reinforcements, fortify, tdd, game-engine]

# Dependency graph
requires:
  - phase: 07-01
    provides: Test infrastructure, FakeRandom, freezed models, MapGraph, actions.dart

provides:
  - cards_engine.dart: isValidSet, createDeck, drawCard, executeTrade, getTradeBonus
  - reinforcements.dart: calculateReinforcements using MapGraph.continentNames
  - fortify.dart: validateFortify, executeFortify using MapGraph.connectedTerritories BFS
  - 28 passing tests across all three engine modules

affects: [07-04, 07-05, phase-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Dart record return type (GameState, int, Map<String, int>) for executeTrade tuple
    - String key pattern for cards map: cards[playerIndex.toString()] throughout
    - Integer division with ~/ operator (not /) for base reinforcement calculation
    - Immutable map copy pattern: Map<String, T>.of(state.x) before mutation
    - Fake MapGraph built from inline MapData for isolated tests (no JSON fixture needed)

key-files:
  created:
    - mobile/lib/engine/cards_engine.dart
    - mobile/lib/engine/reinforcements.dart
    - mobile/lib/engine/fortify.dart
  modified:
    - mobile/lib/engine/map_graph.dart (added continentNames getter)
    - mobile/test/engine/cards_engine_test.dart
    - mobile/test/engine/reinforcements_test.dart
    - mobile/test/engine/fortify_test.dart

key-decisions:
  - "Dart records used for executeTrade return value: (GameState, int, Map<String,int>) — avoids ad-hoc class"
  - "continentNames getter added to map_graph.dart now (planned for Plan 02) — blocked reinforcements, Rule 3 auto-fix"
  - "Fake MapGraph constructed inline from MapData in tests — no real classic.json needed for unit tests"
  - "ArgumentError used instead of Exception for invalid inputs — more idiomatic Dart for precondition violations"

patterns-established:
  - "String key pattern: all cards map access uses playerIndex.toString() as key"
  - "Deck recycle: traded cards only returned to deck when state.deck.isEmpty — never on every trade"
  - "Escalation: _escalationSequence const list [4,6,8,10,12,15] + formula for tradeCount>=6"
  - "BFS fortify path: connectedTerritories(source, playerFriendlySet) validates reachability"

requirements-completed: [DART-02, DART-03, DART-04]

# Metrics
duration: 4min
completed: 2026-03-15
---

# Phase 7 Plan 03: Stateless Rule Modules Summary

**Three pure-Dart rule modules (cards, reinforcements, fortify) ported from Python with 28 passing TDD tests, enforcing correct deck recycle condition, integer division, and BFS path validation**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-15T06:48:55Z
- **Completed:** 2026-03-15T06:52:49Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- cards_engine.dart: full card system with isValidSet (5 cases), createDeck (44 cards), drawCard (String key), executeTrade (recycle-only-when-empty), getTradeBonus (escalation sequence)
- reinforcements.dart: calculateReinforcements using integer division `~/`, iterating continentNames, with continent bonus accumulation
- fortify.dart: validateFortify/executeFortify using BFS connectedTerritories check, enforcing leave-1-army constraint
- 28 tests across all three modules pass; zero Flutter imports in engine files

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement cards_engine.dart, enable cards tests** - `f551273` (feat)
2. **Task 2: Implement reinforcements.dart and fortify.dart, enable their tests** - `16ca09d` (feat)

**Plan metadata:** (docs commit — see state updates)

_Note: TDD pattern applied — implementation written with tests simultaneously_

## Files Created/Modified
- `mobile/lib/engine/cards_engine.dart` - Card system: isValidSet, createDeck, drawCard, executeTrade, getTradeBonus
- `mobile/lib/engine/reinforcements.dart` - calculateReinforcements with continent bonuses
- `mobile/lib/engine/fortify.dart` - validateFortify + executeFortify with BFS path check
- `mobile/lib/engine/map_graph.dart` - Added `List<String> get continentNames` getter
- `mobile/test/engine/cards_engine_test.dart` - 15 tests: all card operations including recycle edge case
- `mobile/test/engine/reinforcements_test.dart` - 5 tests: base calc (9/11/12 territories), continent bonus on/off
- `mobile/test/engine/fortify_test.dart` - 8 tests: connected/disconnected path, ownership, army limits

## Decisions Made
- Used Dart records `(GameState, int, Map<String,int>)` as executeTrade return type — avoids needing an ad-hoc result class, matches Python tuple return
- Added `continentNames` getter to map_graph.dart immediately (Rule 3 — blocking issue) — Plan 02 was supposed to add it but hasn't run yet; 1-line change with no side effects
- Used `ArgumentError` for precondition violations (invalid card set, invalid fortify) — more idiomatic Dart than bare `Exception`
- Fake MapGraph constructed inline from `const MapData(...)` objects — no JSON fixture or file loading needed for unit tests

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `continentNames` getter to map_graph.dart**
- **Found during:** Task 2 (reinforcements.dart implementation)
- **Issue:** reinforcements.dart needs `mapGraph.continentNames` to iterate continents; Plan 02 was supposed to add this getter but Plan 02 hasn't run yet
- **Fix:** Added 1-line getter `List<String> get continentNames => _continentBonuses.keys.toList();` to map_graph.dart
- **Files modified:** mobile/lib/engine/map_graph.dart
- **Verification:** Tests pass; grep confirms getter exists
- **Committed in:** `16ca09d` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking — missing getter from future plan)
**Impact on plan:** Required for Task 2 to compile. No scope creep — exactly the 1 line that Plan 02 planned to add.

## Issues Encountered
None — all tasks executed cleanly on first attempt.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Three rule modules complete and tested: cards_engine, reinforcements, fortify
- map_graph.dart already has continentNames (Plan 02 can skip adding it)
- Plan 04 (turn orchestration) can now import all three modules
- Plan 02 (combat + setup) can proceed independently — no blocking dependencies

---
*Phase: 07-dart-game-engine-port*
*Completed: 2026-03-15*
