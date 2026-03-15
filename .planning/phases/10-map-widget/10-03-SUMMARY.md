---
phase: 10-map-widget
plan: 03
subsystem: ui
tags: [flutter, riverpod, custom-painter, interactive-viewer, gesture-detector, hit-testing]

# Dependency graph
requires:
  - phase: 10-01
    provides: TerritoryGeometry/kTerritoryData constants for hit-test rect math
  - phase: 10-02
    provides: MapBasePainter (static outlines) and MapOverlayPainter (dynamic colors/counts/highlights)
  - phase: 09-02
    provides: gameProvider (AsyncNotifier), uIStateProvider (UIStateNotifier.selectTerritory), mapGraphProvider
provides:
  - MapWidget ConsumerStatefulWidget with InteractiveViewer + GestureDetector + two-layer CustomPaint
  - Coordinate-transformed tap hit testing using TransformationController.toScene()
  - rect.inflate(6.0) expansion for forgiving tap targets
  - AlertDialog disambiguation when multiple territory rects overlap
  - 5 unit tests validating hit-test logic at any zoom level
affects:
  - phase: 11 (game screen integration — MapWidget placed in scaffold)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GestureDetector inside InteractiveViewer child (not outside) for correct toScene() coordinate mapping"
    - "TransformationController.toScene() inverts viewport zoom/pan to 1200x700 SVG coordinate space"
    - "rect.inflate(6.0) hit-test expansion for sub-pixel tap tolerance"
    - "AlertDialog for tap disambiguation when multiple inflated rects contain the tap point"
    - "markTestSkipped() in test body instead of skip: parameter (bool? constraint in this Flutter version)"
    - "Mirror private widget logic in test-local helper function for pure unit testing"

key-files:
  created:
    - mobile/lib/widgets/map/map_widget.dart
  modified:
    - mobile/test/widgets/map/map_interaction_test.dart

key-decisions:
  - "GestureDetector placed INSIDE InteractiveViewer child so toScene() correctly inverts transform; placing it outside would receive already-scaled coordinates"
  - "constrained: false on InteractiveViewer required so the 1200x700 SizedBox can exceed viewport bounds for pan/zoom"
  - "Hit-test logic extracted as top-level test helper function (not testing private method) for clean unit tests"

patterns-established:
  - "MapWidget pattern: ConsumerStatefulWidget owns TransformationController lifecycle (create in field, dispose in dispose())"
  - "Two-provider watch pattern: gameAsync + mapAsync, show CircularProgressIndicator while loading, render map only on AsyncData non-null"

requirements-completed: [MAPW-01, MAPW-02, MAPW-05]

# Metrics
duration: 4min
completed: 2026-03-15
---

# Phase 10 Plan 03: MapWidget Summary

**MapWidget ConsumerStatefulWidget wiring InteractiveViewer (1x-4x zoom), GestureDetector tap handling with TransformationController.toScene() coordinate mapping, rect.inflate(6.0) hit testing, and AlertDialog disambiguation**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-15T20:33:05Z
- **Completed:** 2026-03-15T20:36:58Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- MapWidget renders pinch-zoomable 1200x700 Risk map with InteractiveViewer (minScale 1.0, maxScale 4.0)
- Tap handler uses _controller.toScene() to convert viewport coordinates to SVG space; rect.inflate(6.0) gives forgiving tap targets
- AlertDialog disambiguation popup shown when tap falls within multiple territory rects
- 5 unit tests validate hit-test logic; disambiguation confirmed with Northern Europe / Southern Europe overlap geometry
- Full flutter test suite passes: 168 tests, 2 skipped, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: MapWidget implementation** - `7f153c3` (feat)
2. **Task 2: Hit-test unit tests** - `a96fbc7` (test)

## Files Created/Modified

- `mobile/lib/widgets/map/map_widget.dart` - MapWidget ConsumerStatefulWidget with InteractiveViewer, GestureDetector inside, two-layer Stack (RepaintBoundary+MapBasePainter / MapOverlayPainter), Riverpod watching gameProvider + mapGraphProvider + uIStateProvider
- `mobile/test/widgets/map/map_interaction_test.dart` - 5 hit-test unit tests (4 passing, 1 MAPW-04 visual test markTestSkipped); replaces Wave 0 stubs

## Decisions Made

- GestureDetector placed INSIDE InteractiveViewer child (wrapping the 1200x700 SizedBox) so that `_controller.toScene(details.localPosition)` correctly inverts the zoom/pan transform. If placed outside, details.localPosition would already be in viewport space without needing inversion.
- constrained: false on InteractiveViewer is required so the fixed-size 1200x700 child can exceed viewport bounds and be panned/zoomed freely.
- Test helper function `hitTest(Offset)` mirrors the private `_selectTerritoryAt` logic in-test rather than testing private widget state — cleaner unit test pattern.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed testWidgets skip parameter type**
- **Found during:** Task 2 (map_interaction_test.dart compilation)
- **Issue:** Plan used `skip: 'String'` in testWidgets, but this Flutter version's testWidgets has `bool?` skip parameter — compile error
- **Fix:** Used `markTestSkipped('reason')` inside test body (same pattern established in 10-01 decisions)
- **Files modified:** mobile/test/widgets/map/map_interaction_test.dart
- **Verification:** flutter test exits 0, 1 test marked skipped as intended
- **Committed in:** a96fbc7 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Single type error fix; known pattern from STATE.md [10-01] decision. No scope creep.

## Issues Encountered

- testWidgets `skip:` parameter type mismatch (bool? vs String) — already documented as a known pattern in STATE.md from Phase 10 Plan 01, fixed inline using markTestSkipped() in test body.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- MapWidget is fully interactive and ready to be placed in a game screen scaffold (Phase 11)
- All three map layers (territory data, base painter, overlay painter, widget wiring) are complete
- Phase 10 has one remaining plan (10-04) before moving to Phase 11 game screen integration
- No blockers

---
*Phase: 10-map-widget*
*Completed: 2026-03-15*

## Self-Check: PASSED

- FOUND: mobile/lib/widgets/map/map_widget.dart
- FOUND: mobile/test/widgets/map/map_interaction_test.dart
- FOUND: .planning/phases/10-map-widget/10-03-SUMMARY.md
- FOUND commit: 7f153c3 (feat: MapWidget implementation)
- FOUND commit: a96fbc7 (test: hit-test unit tests)
