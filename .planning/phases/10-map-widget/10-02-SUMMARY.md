---
phase: 10-map-widget
plan: 02
subsystem: ui
tags: [flutter, custom-painter, canvas, repaint-boundary, map-rendering]

# Dependency graph
requires:
  - phase: 10-01
    provides: territory_data.dart with TerritoryGeometry, kTerritoryData (42 entries), kPlayerColors
  - phase: 09-01
    provides: UIState model (selectedTerritory, validSources, validTargets)
  - phase: 07-01
    provides: GameState/TerritoryState models (territories map, owner, armies)

provides:
  - MapBasePainter: static territory outline painter (shouldRepaint=false, RepaintBoundary-safe)
  - MapOverlayPainter: dynamic owner colors, army counts, selection/source/target highlights
  - MAPW-03 widget tests: owner color and army count rendering verified

affects:
  - 10-03 (MapWidget composes these two painters in InteractiveViewer + RepaintBoundary stack)
  - 10-04 (tap hit-testing build on same painter coordinate space)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Two-layer CustomPainter split: static (base) vs dynamic (overlay) to exploit RepaintBoundary caching
    - Canvas scaling via canvas.scale(width/1200, height/700) before all drawing — normalizes SVG coordinate space
    - TextPainter for army count labels centered on labelOffset using width/height halving

key-files:
  created:
    - mobile/lib/widgets/map/map_base_painter.dart
    - mobile/lib/widgets/map/map_overlay_painter.dart
  modified:
    - mobile/test/widgets/map/map_widget_test.dart

key-decisions:
  - "MapBasePainter uses flutter/rendering.dart (not flutter/material.dart) — keeps painter layer-agnostic"
  - "MapOverlayPainter silently skips missing territory keys — no crash on partial GameState (test-friendly)"
  - "shouldRepaint on overlay checks object identity (!=) on freezed GameState/UIState — equality via freezed == operator"

patterns-established:
  - "Static painter (RepaintBoundary layer): no state params, shouldRepaint=false always"
  - "Dynamic painter: accept GameState + UIState, shouldRepaint delegates to freezed equality"
  - "Tint order: owner fill, then validSources yellow, then validTargets green, then selection white — explicit z-order"

requirements-completed: [MAPW-03, MAPW-04]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 10 Plan 02: Map Painters Summary

**Two-layer CustomPainter architecture: MapBasePainter (static grey outlines, RepaintBoundary-safe) + MapOverlayPainter (owner colors, army counts, selection/source/target highlights) using canvas.scale to normalize 1200x700 SVG coordinates**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T20:28:03Z
- **Completed:** 2026-03-15T20:31:05Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- MapBasePainter renders all 42 territory rects with grey fill + dark border, shouldRepaint always false
- MapOverlayPainter fills by owner color from kPlayerColors, draws army count text centered on labelOffset, overlays selection/source/target tints in correct z-order
- 4 new tests added to map_widget_test.dart (2 MAPW-03 widget render tests + 2 shouldRepaint unit tests); full suite 163 tests pass + 6 skipped

## Task Commits

Each task was committed atomically:

1. **Task 1: MapBasePainter static territory outlines** - `ca1cac6` (feat)
2. **Task 2: MapOverlayPainter + MAPW-03 test stubs** - `83aa33a` (feat)

**Plan metadata:** _(docs commit to follow)_

## Files Created/Modified
- `mobile/lib/widgets/map/map_base_painter.dart` - Static CustomPainter: grey fill + border rects for all 42 territories, shouldRepaint=false
- `mobile/lib/widgets/map/map_overlay_painter.dart` - Dynamic CustomPainter: owner color fill, army text, selection/source/target tints, shouldRepaint via freezed equality
- `mobile/test/widgets/map/map_widget_test.dart` - Filled 2 skipped MAPW-03 stubs + added 2 shouldRepaint unit tests (6 tests total, 1 still-skipped MAPW-01)

## Decisions Made
- MapBasePainter imports `flutter/rendering.dart` not `flutter/material.dart` — keeps painter layer-agnostic (no Material dependency in pure canvas code)
- MapOverlayPainter silently skips territories missing from `gameState.territories` — no crash on sparse GameState, useful for tests
- shouldRepaint delegates to freezed `!=` operator on GameState/UIState — correct equality semantics for value objects

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Both painters ready for composition in Plan 03 (MapWidget with InteractiveViewer + RepaintBoundary stack)
- MAPW-01 test stub remains skipped — will be filled when MapWidget widget is built in Plan 03
- Canvas coordinate space (0,0)-(1200,700) established consistently in both painters

---
*Phase: 10-map-widget*
*Completed: 2026-03-15*
