---
phase: 11-screens-widgets-and-mobile-ux
plan: "05"
subsystem: mobile-widgets
tags: [flutter, riverpod, widgets, continent-panel, game-over-dialog, tdd]
dependency_graph:
  requires: [11-03]
  provides: [ContinentPanel, GameOverDialog]
  affects: [mobile/lib/widgets/]
tech_stack:
  added: []
  patterns: [ConsumerWidget, AsyncValue.when, AlertDialog, ListView]
key_files:
  created:
    - mobile/lib/widgets/continent_panel.dart
    - mobile/lib/widgets/game_over_dialog.dart
  modified:
    - mobile/test/widgets/continent_panel_test.dart
    - mobile/test/widgets/game_over_dialog_test.dart
decisions:
  - GameOverDialog uses a shared _handleDismiss method for both Home and New Game buttons — both paths call clearSave() + gameLog.clear() then popUntil(first route)
  - Test 3 for GameOverDialog (Home navigation popUntil) remains skipped — Navigator.popUntil behavior requires multi-route setup complex to unit test; verified in Plan 06 checkpoint
metrics:
  duration: ~15 minutes
  tasks_completed: 2
  files_created: 2
  files_modified: 2
  completed_date: "2026-03-16"
---

# Phase 11 Plan 05: ContinentPanel and GameOverDialog Summary

**One-liner:** ContinentPanel (Riverpod-wired continent bonus display with player-controlled star indicators) and GameOverDialog (winner modal with clearSave + gameLog.clear on dismiss).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | ContinentPanel widget (TDD) | d49c4f5 | `continent_panel.dart`, `continent_panel_test.dart` |
| 2 | GameOverDialog widget (TDD) | 83a8b66 | `game_over_dialog.dart`, `game_over_dialog_test.dart` |

## What Was Built

### ContinentPanel

`mobile/lib/widgets/continent_panel.dart` — A `ConsumerWidget` that:

- Watches `mapGraphProvider` (AsyncValue) and `gameProvider` to render continent rows
- Uses `mapGraph.continentNames`, `continentBonus()`, and `controlsContinent()` for data
- Renders a `ListView` with each continent showing name, `+N` bonus text, and a star `Icon` when the current player controls it
- Uses `kPlayerColors[playerIdx]` to color the star icon by player

### GameOverDialog

`mobile/lib/widgets/game_over_dialog.dart` — A `ConsumerWidget` that:

- Takes a `PlayerState winner` parameter
- Shows `"${winner.name} wins!"` and "Congratulations!" (player 0) or "Better luck next time." (any other)
- Both Home and New Game buttons call `gameProvider.notifier.clearSave()` + `gameLogProvider.notifier.clear()` then `Navigator.popUntil((route) => route.isFirst)`

## Test Results

```
ContinentPanel (MOBX-05): 3/3 pass
  - renders all continent names
  - renders continent bonus values
  - highlights controlled continent (star icon)

GameOverDialog (MOBX-06): 2/2 pass, 1 skip
  - shows winner name and congratulations
  - New Game button triggers clearSave()
  - Home button navigation: SKIPPED (popUntil tested in Plan 06 checkpoint)

Full suite: 190 pass, 9 skip — no regressions
```

## Deviations from Plan

None — plan executed exactly as written.

The test file already had pre-written real tests (not `markTestSkipped` stubs) for `continent_panel_test.dart`. The RED phase was confirmed by compilation failure (widget file missing). For `game_over_dialog_test.dart`, the stubs were replaced with real tests per the plan.

## Decisions Made

1. **Shared dismiss handler:** Both "Home" and "New Game" buttons in `GameOverDialog` share a single `_handleDismiss()` method — the behavior is identical (clear state + pop to root). This is cleaner than two identical `onPressed` lambdas.

2. **Home navigation test skipped:** `Navigator.popUntil` behavior requires wrapping in a multi-route `Navigator` setup which is complex for unit tests. The plan explicitly notes this can remain skipped for Plan 06 checkpoint verification.

## Self-Check: PASSED

- FOUND: `mobile/lib/widgets/continent_panel.dart`
- FOUND: `mobile/lib/widgets/game_over_dialog.dart`
- FOUND: `.planning/phases/11-screens-widgets-and-mobile-ux/11-05-SUMMARY.md`
- FOUND commit b839b45: test(11-05) ContinentPanel RED
- FOUND commit d49c4f5: feat(11-05) ContinentPanel implementation
- FOUND commit 1e21c2f: test(11-05) GameOverDialog RED
- FOUND commit 83a8b66: feat(11-05) GameOverDialog implementation
