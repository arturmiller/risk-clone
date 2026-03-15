---
phase: 10-map-widget
plan: "01"
subsystem: ui
tags: [flutter, dart, map, territory-geometry, player-colors, test-stubs]

# Dependency graph
requires:
  - phase: 09-providers-and-persistence
    provides: GameState.territories keys sourced from classic.json, which kTerritoryData must match
provides:
  - kTerritoryData: const Map<String, TerritoryGeometry> with all 42 territories and SVG-space Rects
  - kPlayerColors: const List<Color> with 6 player colors indexed 0-5
  - TerritoryGeometry: const class with Rect + Offset fields
  - Wave 0 test stubs for map widget (MAPW-01, MAPW-03) and interaction tests (MAPW-02, MAPW-04, MAPW-05)
affects:
  - 10-map-widget (plans 02, 03, 04): all downstream painters and hit-test code import kTerritoryData

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure dart:ui data file — no Flutter widget dependencies in territory_data.dart"
    - "markTestSkipped() in body instead of skip: 'string' — testWidgets skip parameter is bool? in this Flutter version"

key-files:
  created:
    - mobile/lib/widgets/map/territory_data.dart
    - mobile/test/widgets/map/map_widget_test.dart
    - mobile/test/widgets/map/map_interaction_test.dart
  modified: []

key-decisions:
  - "testWidgets skip parameter is bool? in Riverpod-era Flutter — use markTestSkipped() in body for skip-with-reason pattern"
  - "territory_data.dart uses dart:ui only (no flutter/material) — Color, Rect, Offset all available in dart:ui"

patterns-established:
  - "Wave 0 stub pattern: markTestSkipped('reason') in body so tests report as skipped (not failed) in CI"
  - "All territory geometry lives in territory_data.dart — downstream code imports kTerritoryData, no scattered constants"

requirements-completed:
  - MAPW-03

# Metrics
duration: 4min
completed: 2026-03-15
---

# Phase 10 Plan 01: Territory Data and Wave 0 Test Stubs Summary

**Static geometry foundation: 42 TerritoryGeometry constants (Rect + label Offset) and 6 kPlayerColors in a pure dart:ui file, plus Wave 0 test stubs that compile and skip cleanly**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-15T20:21:58Z
- **Completed:** 2026-03-15T20:25:25Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- `territory_data.dart` with `TerritoryGeometry` class, `kTerritoryData` (42 entries) and `kPlayerColors` (6 colors), pure `dart:ui` — no Flutter widget dependency
- Territory name keys match `classic.json` exactly (verified against canonical source)
- Two test stub files compile cleanly; 2 data-count assertions pass, 8 widget/interaction stubs report as skipped
- Full suite: 159 passing + 8 skipped, exit 0

## Task Commits

Each task was committed atomically:

1. **Task 1: Create territory_data.dart with all 42 TerritoryGeometry constants** - `91df6e4` (feat)
2. **Task 2: Create Wave 0 test stubs for map widget and interaction tests** - `68cad2c` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `mobile/lib/widgets/map/territory_data.dart` — TerritoryGeometry class, kTerritoryData map (42 territories, SVG viewBox 0 0 1200 700), kPlayerColors (6 colors)
- `mobile/test/widgets/map/map_widget_test.dart` — Wave 0 stubs for MAPW-01 and MAPW-03 + 2 immediate data-count assertions
- `mobile/test/widgets/map/map_interaction_test.dart` — Wave 0 stubs for MAPW-02, MAPW-04, MAPW-05

## Decisions Made
- `testWidgets` `skip` parameter is `bool?` (not `Object?`) in this Flutter version — used `markTestSkipped('reason')` in the test body instead of `skip: 'string'`. Plain `test()` calls also use `markTestSkipped` for consistency.
- `territory_data.dart` imports `dart:ui` only — `Color`, `Rect`, and `Offset` are all available without `flutter/material.dart`, keeping the file free of widget-layer dependencies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] testWidgets skip parameter type mismatch**
- **Found during:** Task 2 (Wave 0 test stubs)
- **Issue:** Plan template used `skip: 'string reason'` on `testWidgets` calls, but the Flutter version in this project has `skip: bool?` — compilation failed with "The argument type 'String' can't be assigned to the parameter type 'bool?'"
- **Fix:** Replaced `skip: '...'` with `markTestSkipped('...')` called inside the test body for all `testWidgets` calls. Applied to `test()` stubs as well for consistent skip-with-reason behavior.
- **Files modified:** `mobile/test/widgets/map/map_widget_test.dart`, `mobile/test/widgets/map/map_interaction_test.dart`
- **Verification:** `flutter test test/widgets/map/` exits 0: 2 passing, 8 skipped
- **Committed in:** `68cad2c` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — type mismatch in test stub pattern)
**Impact on plan:** Fix required for compilation; no scope creep.

## Issues Encountered
None beyond the auto-fixed skip parameter type mismatch above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `kTerritoryData` and `kPlayerColors` are ready for plan 10-02 (MapWidget + TerritoryPainter)
- `kTerritoryData` keys confirmed matching `classic.json` — no name drift risk
- Wave 0 stubs provide the test scaffolding; plan 10-02 will fill in MAPW-01 and MAPW-03 implementations
- Wave 0 stubs for MAPW-02 and MAPW-05 await plan 10-03 hit-test logic

---
*Phase: 10-map-widget*
*Completed: 2026-03-15*
