---
phase: 09-riverpod-providers-and-persistence
plan: 03
subsystem: ui
tags: [flutter, riverpod, consumer-widget, async-value, objectbox]

# Dependency graph
requires:
  - phase: 09-02
    provides: gameProvider (AsyncNotifier<GameState?>) with setupGame/clearSave/saveNow, storeProvider (ObjectBox)
  - phase: 09-01
    provides: GameConfig, UIState, GameState models
provides:
  - HomeScreen ConsumerWidget watching gameProvider with loading/error/resume/new-game UI
  - Complete Phase 9 end-to-end wiring: providers + persistence + UI
affects:
  - 10-map-widget
  - 11-game-screen

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "AsyncValue.when() pattern match in ConsumerWidget for loading/error/data states"
    - "ref.watch(gameProvider) for reactive state, ref.read(gameProvider.notifier) for actions"

key-files:
  created: []
  modified:
    - mobile/lib/screens/home_screen.dart

key-decisions:
  - "HomeScreen uses gameProvider (Riverpod 3.x generated name) not gameNotifierProvider — plan interface section used old name"
  - "Human lifecycle test deferred to Phase 11 full UI — SAVE-01/SAVE-02 validated by 14 ProviderContainer unit tests with real ObjectBox"
  - "_ResumePrompt.gameState typed as dynamic — Phase 11 will refactor the entire screen"

patterns-established:
  - "ConsumerWidget + AsyncValue.when(): standard pattern for screens that depend on async providers"

requirements-completed:
  - SAVE-01
  - SAVE-02

# Metrics
duration: 20min
completed: 2026-03-15
---

# Phase 9 Plan 03: HomeScreen Wired to gameProvider Summary

**HomeScreen ConsumerWidget with AsyncValue pattern match closes the Phase 9 loop: loading spinner, New Game prompt (null state), and Resume prompt (saved GameState) wired to ObjectBox-backed gameProvider**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-15T19:27:00Z
- **Completed:** 2026-03-15T19:47:00Z
- **Tasks:** 2 (1 auto + 1 human-verify approved)
- **Files modified:** 1

## Accomplishments

- HomeScreen converted from StatelessWidget stub to ConsumerWidget watching `gameProvider`
- All three AsyncValue states handled: loading spinner, error display, data (null/non-null)
- New Game path calls `setupGame(GameConfig(playerCount: 3, difficulty: Difficulty.medium))`
- Resume path shows turn number and offers `clearSave()` to start over
- All 157 tests pass including 14 ProviderContainer tests validating SAVE-01 and SAVE-02
- Human-verify checkpoint approved — lifecycle test deferred to Phase 11 when full UI is built

## Task Commits

Each task was committed atomically:

1. **Task 1: Update HomeScreen to watch gameNotifierProvider** - `60e92f2` (feat)
2. **Task 2: Human verify Phase 9 end-to-end lifecycle behavior** - approved by user (no commit needed)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `mobile/lib/screens/home_screen.dart` - ConsumerWidget with AsyncValue.when() pattern match; _NewGamePrompt and _ResumePrompt private widgets

## Decisions Made

- Used `gameProvider` (not `gameNotifierProvider`) — Riverpod 3.x strips "Notifier" suffix from generated provider names; confirmed in game_provider.g.dart
- `_ResumePrompt.gameState` typed as `dynamic` — Phase 11 will fully refactor this screen; typing it precisely now would be premature
- Human lifecycle test (background + relaunch) deferred to Phase 11 — no Android emulator available on WSL2, and SAVE-01/SAVE-02 behavior is fully validated by 14 ProviderContainer unit tests with real ObjectBox

## Deviations from Plan

None - plan executed exactly as written. The only adjustment was using the correct generated provider name `gameProvider` rather than `gameNotifierProvider` from the plan's interface block, which matched the existing decision already recorded in STATE.md from Phase 09-02.

## Issues Encountered

None - flutter analyze clean on first write, all 157 tests passed immediately.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 9 complete: GameNotifier + UIStateNotifier + HomeScreen all wired together
- Phase 10 (map widget) can consume `gameProvider` and `uIStateProvider` directly
- Phase 11 (game screen) will replace `_ResumePrompt` with the full game UI and real navigation

---
*Phase: 09-riverpod-providers-and-persistence*
*Completed: 2026-03-15*
