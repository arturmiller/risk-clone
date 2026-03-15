---
phase: 09-riverpod-providers-and-persistence
plan: 02
subsystem: providers
tags: [riverpod, objectbox, flutter, dart, isolate, game-state, persistence]

requires:
  - phase: 09-01
    provides: GameConfig, UIState freezed models and Wave 0 test stubs
  - phase: 08-bot-agents
    provides: EasyAgent, MediumAgent, HardAgent implementing PlayerAgent; executeTurn
  - phase: 06-objectbox-persistence
    provides: SaveSlot entity, openRiskStore, storeProvider

provides:
  - GameNotifier AsyncNotifier<GameState?> with ObjectBox lifecycle, auto-save, bot turn Isolate execution
  - UIStateNotifier Notifier<UIState> with territory selection and valid target computation
  - game_provider.g.dart and ui_provider.g.dart (build_runner generated)
  - 14 ProviderContainer unit tests (7 GameNotifier + 7 UIStateNotifier) — all green

affects:
  - 09-03 (validation)
  - 10-map-ui (consumes gameProvider and uIStateProvider)
  - 11-human-agent (wires HumanAgent to replace placeholder EasyAgent for player 0)

tech-stack:
  added: []
  patterns:
    - GameNotifier as single source of truth for game state using AsyncNotifier<GameState?>
    - mapGraph read BEFORE Isolate.run to avoid rootBundle inside isolate
    - ref.mounted guard after Isolate.run to handle provider auto-disposal
    - saveNow() public method as test seam for lifecycle-triggered _saveState()
    - TestWidgetsFlutterBinding.ensureInitialized() required for AppLifecycleListener in unit tests
    - Store(getObjectBoxModel(), directory: tempPath) for sync ObjectBox instantiation in tests
    - ProviderContainer with storeProvider.overrideWithValue + mapGraphProvider.overrideWith for isolation

key-files:
  created:
    - mobile/lib/providers/game_provider.dart
    - mobile/lib/providers/game_provider.g.dart
    - mobile/lib/providers/ui_provider.dart
    - mobile/lib/providers/ui_provider.g.dart
    - mobile/test/providers/game_notifier_test.dart
    - mobile/test/providers/ui_notifier_test.dart
  modified:
    - mobile/lib/providers/map_provider.dart (Riverpod 3.x Ref fix)
    - mobile/.gitignore (ignore libobjectbox.so and download/)

key-decisions:
  - "Generated provider names are gameProvider (not gameNotifierProvider) and uIStateProvider (not uIStateNotifierProvider) — Riverpod 3.x generator uses class name without 'Notifier' suffix"
  - "ref.mounted guard after Isolate.run is required — isAutoDispose: true provider can dispose during async Isolate.run gap in tests"
  - "saveNow() public method added as test seam — AppLifecycleListener cannot be triggered in unit tests (requires Flutter engine)"
  - "TestWidgetsFlutterBinding.ensureInitialized() required in game_notifier_test.dart — AppLifecycleListener requires WidgetsBinding"
  - "libobjectbox.so downloaded via objectbox install.sh into mobile/lib/ — added to .gitignore, not checked in"
  - "map_provider.dart updated from MapGraphRef to Ref — pre-existing bug, Riverpod 3.x does not generate named Ref subclasses for functional providers"

patterns-established:
  - "Provider isolation pattern: override storeProvider and mapGraphProvider via ProviderContainer(overrides: [...]) for unit tests"
  - "Subscription pattern: container.listen(gameProvider, ...) to prevent isAutoDispose during Isolate.run in tests"

requirements-completed: [SAVE-01, SAVE-02]

duration: 14min
completed: 2026-03-15
---

# Phase 9 Plan 02: GameNotifier and UIStateNotifier Summary

**GameNotifier AsyncNotifier with ObjectBox cold-start restore (SAVE-02) and auto-save lifecycle trigger (SAVE-01), plus UIStateNotifier with phase-aware territory selection — 14 ProviderContainer tests green**

## Performance

- **Duration:** 14 min
- **Started:** 2026-03-15T20:13:29Z
- **Completed:** 2026-03-15T20:27:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- GameNotifier (AsyncNotifier<GameState?>) with ObjectBox build() restore, lifecycle auto-save, setupGame via mapGraphProvider, runBotTurn via Isolate.run, clearSave
- UIStateNotifier (Notifier<UIState>) with territory selection, phase-aware validTargets (attack/fortify/reinforce), validSources computation
- build_runner generated game_provider.g.dart and ui_provider.g.dart
- 14 ProviderContainer tests: all green (7 GameNotifier + 7 UIStateNotifier)
- Full suite: 157 tests passing (143 pre-existing + 14 new)

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement GameNotifier and UIStateNotifier** - `0aa3af4` (feat)
2. **Task 2: Populate provider tests and make them green** - `0ab7244` (feat)

## Files Created/Modified
- `mobile/lib/providers/game_provider.dart` - GameNotifier AsyncNotifier<GameState?> with full lifecycle
- `mobile/lib/providers/game_provider.g.dart` - build_runner generated, provider name: gameProvider
- `mobile/lib/providers/ui_provider.dart` - UIStateNotifier Notifier<UIState> with selection logic
- `mobile/lib/providers/ui_provider.g.dart` - build_runner generated, provider name: uIStateProvider
- `mobile/test/providers/game_notifier_test.dart` - 7 ProviderContainer tests
- `mobile/test/providers/ui_notifier_test.dart` - 7 ProviderContainer tests
- `mobile/lib/providers/map_provider.dart` - Fixed MapGraphRef -> Ref (Riverpod 3.x pre-existing bug)
- `mobile/.gitignore` - Added libobjectbox.so and download/ exclusions

## Decisions Made
- Generated provider names are `gameProvider` and `uIStateProvider` (not the names listed in the plan) — Riverpod 3.x generator strips the "Notifier" suffix from class names for the provider variable
- `ref.mounted` guard added after `Isolate.run` to handle isAutoDispose provider cleanup during async gaps
- `saveNow()` public method added as test seam (cleaner than trying to trigger lifecycle callbacks)
- `TestWidgetsFlutterBinding.ensureInitialized()` required for AppLifecycleListener in unit test context

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed MapGraphRef undefined class in map_provider.dart**
- **Found during:** Task 1 (flutter analyze after build_runner)
- **Issue:** map_provider.dart used `MapGraphRef` which Riverpod 3.x no longer generates for functional providers (pre-existing issue)
- **Fix:** Changed parameter type from `MapGraphRef ref` to `Ref ref`
- **Files modified:** mobile/lib/providers/map_provider.dart
- **Verification:** flutter analyze lib/providers/ reports no issues
- **Committed in:** 0aa3af4 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - pre-existing bug in map_provider.dart)
**Impact on plan:** Required fix; map_provider.dart was broken before this plan. No scope creep.

## Issues Encountered
- ObjectBox native library (libobjectbox.so) not present for unit tests — resolved by running objectbox install.sh to download v5.1.0 into mobile/lib/; added to .gitignore
- `state.valueOrNull` does not exist in Riverpod 3.x — replaced with `state.value` (AsyncValue<T>.value returns T?)
- AppLifecycleListener requires WidgetsBinding — resolved with TestWidgetsFlutterBinding.ensureInitialized()
- Provider auto-disposal during Isolate.run gap — resolved with ref.mounted guard and container.listen subscription in test

## Next Phase Readiness
- GameNotifier and UIStateNotifier are complete and tested; ready for Phase 9 Plan 03 (validation/SUMMARY)
- Phase 10 (map UI) can consume gameProvider and uIStateProvider directly
- Phase 11 will replace the placeholder EasyAgent for player 0 with HumanAgent

---
*Phase: 09-riverpod-providers-and-persistence*
*Completed: 2026-03-15*
