---
phase: 11-screens-widgets-and-mobile-ux
plan: 03
subsystem: ui
tags: [flutter, riverpod, player-agent, human-turn, home-screen]

# Dependency graph
requires:
  - phase: 11-02
    provides: GameMode enum, gameLogProvider, LogEntry model
  - phase: 10-03
    provides: MapWidget, game provider foundation
provides:
  - HumanAgent: one-shot PlayerAgent adapter with named constructors
  - GameNotifier.humanMove(): main-isolate human turn execution
  - GameNotifier._advanceTurnIfBot(): auto-triggers bot after human turn
  - SetupForm: full game setup UI (player count, difficulty, game mode)
  - GameScreen placeholder stub
affects:
  - 11-04-action-panel
  - 11-05-game-screen
  - 11-06-game-screen-integration

# Tech tracking
tech-stack:
  added: []
  patterns:
    - One-shot agent pattern: HumanAgent wraps a single decision per instance, constructed fresh each humanMove() call
    - Human turn on main isolate: humanMove() never uses Isolate.run(); direct state mutation
    - Bot auto-advance: _advanceTurnIfBot() uses Future.microtask to avoid nested state mutations

key-files:
  created:
    - mobile/lib/bots/human_agent.dart
    - mobile/lib/screens/game_screen.dart
  modified:
    - mobile/lib/providers/game_provider.dart
    - mobile/lib/engine/turn.dart
    - mobile/lib/screens/home_screen.dart
    - mobile/test/providers/human_move_test.dart
    - mobile/test/screens/home_screen_test.dart

key-decisions:
  - "HumanAgent.skipFortify() == HumanAgent() (all nulls) — null FortifyAction means skip fortify"
  - "nextAlivePlayer() made public in turn.dart (was _nextAlivePlayer) — needed by game_provider.dart"
  - "SetupForm uses public name (no underscore) for testability in widget tests"
  - "GameScreen placeholder at lib/screens/game_screen.dart unblocks HomeScreen import without Plan 06"

patterns-established:
  - "Human turns: humanMove(action) executes on main isolate; bot turns: runBotTurn() uses Isolate.run()"
  - "After each human turn: _advanceTurnIfBot() auto-chains bot turns via Future.microtask"
  - "TDD: RED commit before implementation, GREEN on all 4 tests passing"

requirements-completed: [MOBX-01, MOBX-03]

# Metrics
duration: 25min
completed: 2026-03-16
---

# Phase 11 Plan 03: HumanAgent, humanMove(), and HomeScreen Setup Form Summary

**One-shot HumanAgent adapter + GameNotifier.humanMove() for main-isolate human turn execution + full HomeScreen setup form with player count slider and SegmentedButtons**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-16T20:30:00Z
- **Completed:** 2026-03-16T20:55:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- HumanAgent implements PlayerAgent with named constructors (.reinforce, .attack, .endAttack, .fortify, .skipFortify, .trade, .advance) — wraps a single decision per instance
- GameNotifier.humanMove() processes all turn phases on the main isolate; bot turns auto-chain via Future.microtask after human fortify
- HomeScreen upgraded from a single hardcoded button to a full setup form (Slider + two SegmentedButtons + Start button)
- GameScreen placeholder created so imports compile ahead of Plan 06 implementation
- 7 new tests pass (4 humanMove unit + 3 HomeScreen widget), 2 skipped (require full provider in Plan 06), full suite 180 pass / 19 skipped

## Task Commits

Each task was committed atomically:

1. **TDD RED: humanMove test stubs** - `46b2f49` (test)
2. **Task 1: HumanAgent + humanMove()** - `724db1e` (feat)
3. **Task 2: HomeScreen + GameScreen stub** - `21d9b4f` (feat)

_Note: TDD task had test commit (RED) then implementation commit (GREEN)_

## Files Created/Modified
- `mobile/lib/bots/human_agent.dart` - One-shot PlayerAgent adapter with named constructors for each action type
- `mobile/lib/providers/game_provider.dart` - Added humanMove(), _advanceTurnIfBot(), _isHumanTurn(); added imports for actions, cards, combat, cards_engine, game_log_provider, human_agent
- `mobile/lib/engine/turn.dart` - Made _nextAlivePlayer() public as nextAlivePlayer()
- `mobile/lib/screens/home_screen.dart` - Replaced _NewGamePrompt with SetupForm (StatefulWidget, player count/difficulty/game mode); navigation to GameScreen on start/resume
- `mobile/lib/screens/game_screen.dart` - Placeholder stub returning a Scaffold with coming-soon text
- `mobile/test/providers/human_move_test.dart` - 4 ProviderContainer tests for humanMove() across all 3 turn phases
- `mobile/test/screens/home_screen_test.dart` - 3 widget rendering tests for SetupForm (2 skipped pending Plan 06)

## Decisions Made
- nextAlivePlayer() made public: game_provider.dart needs to advance player index after human fortify phase; _nextAlivePlayer was private to turn.dart. Rule 1 auto-fix (blocked by private naming).
- SetupForm is public (no `_` prefix): plan explicitly requested testability in widget tests; private classes cannot be imported from test files.
- GameScreen placeholder uses ConsumerWidget stub: required for HomeScreen import to compile without error before Plan 06 implementation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing imports to game_provider.dart**
- **Found during:** Task 1 (implementing humanMove)
- **Issue:** TurnPhase from cards.dart, AttackAction/FortifyAction from actions.dart, executeBlitz/executeAttack from combat.dart, drawCard from cards_engine.dart, gameLogProvider from game_log_provider.dart — none were imported
- **Fix:** Added all required imports
- **Files modified:** mobile/lib/providers/game_provider.dart
- **Verification:** flutter test passes cleanly
- **Committed in:** 724db1e (Task 1 feat commit)

**2. [Rule 1 - Bug] Made _nextAlivePlayer() public**
- **Found during:** Task 1 (humanMove fortify phase needs to advance player)
- **Issue:** Plan says to make it public but it was still private with underscore prefix; game_provider.dart cannot call private functions from another file
- **Fix:** Renamed _nextAlivePlayer to nextAlivePlayer in turn.dart, updated the one internal call site
- **Files modified:** mobile/lib/engine/turn.dart
- **Verification:** All turn tests still pass
- **Committed in:** 724db1e (Task 1 feat commit)

---

**Total deviations:** 2 auto-fixed (1 missing imports, 1 visibility fix)
**Impact on plan:** Both necessary for compilation and correctness. No scope creep.

## Issues Encountered
- `dart:math` `Random` not imported but used by `executeBlitz/executeAttack` call sites — resolved by noting it was already imported at the top of game_provider.dart.
- Removed `reinforcements.dart` import after adding it — not needed directly in game_provider.dart (executeReinforcePhase handles it internally through turn.dart).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- humanMove() is fully implemented and tested — ActionPanel (Plan 04) can dispatch actions directly via `ref.read(gameProvider.notifier).humanMove(action)`
- SetupForm is rendering-tested and functional — GameScreen integration (Plan 06) can test the full flow
- GameScreen stub compiles cleanly — Plan 06 can replace its body without touching HomeScreen imports

---
*Phase: 11-screens-widgets-and-mobile-ux*
*Completed: 2026-03-16*
