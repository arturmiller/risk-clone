# Phase 10: Map Widget — Research

**Researched:** 2026-03-15
**Domain:** Flutter CustomPainter map rendering, InteractiveViewer touch interaction, SVG path parsing, hit testing
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MAPW-01 | Interactive map widget with pinch-zoom (1x–4x) and pan | InteractiveViewer with TransformationController; coordinate transform via toScene() for hit testing |
| MAPW-02 | Tap territory to select (attack source/target, fortify source/target) | GestureDetector.onTapUp + path.contains(scenePosition) hit test; UIStateNotifier.selectTerritory already implements the selection logic |
| MAPW-03 | Territories colored by owning player with army counts displayed | CustomPainter reads GameState.territories[name].owner and .armies; player colors mapped by index |
| MAPW-04 | Territory highlighting (valid sources, valid targets, selected) | UIState.selectedTerritory, .validSources, .validTargets already populated by UIStateNotifier (Phase 9); MapPainter reads these from provider |
| MAPW-05 | Hit-test expansion for small territories on phone screens | 6dp padding on each territory rect; disambiguation popup (AlertDialog) when multiple expanded rects match a tap point |
</phase_requirements>

---

## Summary

The map widget is the highest-risk component in the mobile port. It requires correct integration of three independent Flutter systems — CustomPainter rendering, InteractiveViewer gesture handling, and SVG path parsing — plus careful handling of the coordinate transform between viewport and scene space under zoom.

The existing SVG (`risk/data/classic_map.svg`) uses simple axis-aligned rectangles for all 42 territories (`M x,y L x,y L x,y L x,y Z`), not complex polygon or bezier paths. This is a significant simplification: territory geometry can be stored as Dart `Rect` objects directly in code, eliminating the need for runtime SVG parsing entirely. The SVG viewBox is 1200x700 — all Flutter `Path` and `Rect` coordinates are in that space and must be scaled to the widget's render size.

The critical performance decision is the two-layer rendering architecture: a static base layer wrapped in `RepaintBoundary` (territories, continent labels, borders — painted once) and a dynamic overlay `CustomPainter` (army counts, selection highlights, valid-target tints — repaints on state changes). This prevents the documented Flutter perf regression where re-painting 42+ paths inside `InteractiveViewer` during pinch-zoom causes 80ms+ frame times on mid-range Android.

The UIState model and UIStateNotifier provider (Phase 9) are already in place and provide `selectedTerritory`, `validSources`, and `validTargets`. The MapPainter simply reads these and applies visual distinctions.

**Primary recommendation:** Store all 42 territory geometries as `Rect` constants in `territory_data.dart`, render the static layer inside `RepaintBoundary`, render the dynamic overlay as a second `CustomPainter`, and use `TransformationController.toScene()` to convert tap coordinates before hit-testing against expanded `Rect.inflate(6)` bounds.

---

## Standard Stack

### Core (already in pubspec.yaml)

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| flutter (widgets) | SDK | InteractiveViewer, GestureDetector, CustomPaint, CustomPainter, RepaintBoundary | All built-in; no new deps required |
| path_parsing | ^1.1.0 | Converts SVG path strings to dart:ui Path objects via PathProxy | Already in pubspec.yaml; needed only if we parse SVG paths at runtime |
| flutter_svg | ^2.2.4 | Render SVG as a widget | Already in pubspec.yaml; usable for the static background image |
| flutter_riverpod | ^3.3.1 | Provider access for GameState and UIState | Already wired; MapWidget will ref.watch both providers |

### No New Dependencies Required

All libraries needed for this phase are already declared in `pubspec.yaml`. No `pub add` commands needed.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Rect constants in Dart | Parse SVG at runtime | Parsing at runtime works but adds startup latency; since all territories are simple rects, Dart constants are faster and simpler |
| Rect constants in Dart | JSON config file | More flexible, but indirection buys nothing for a single fixed map |
| RepaintBoundary static layer | ui.PictureRecorder manual pre-rasterization | RepaintBoundary is simpler and lets the Flutter engine decide when to cache; PictureRecorder gives more control but more code |
| RepaintBoundary static layer | flutter_svg rendering the whole SVG | flutter_svg renders the SVG as a single widget; cannot independently update dynamic overlay without re-rendering entire SVG |
| 42 Rect constants | 42 Path objects | Path objects support `contains()` for arbitrary polygons; since all territories are rectangles, Rect.contains() is equivalent and cheaper |

---

## Architecture Patterns

### Recommended Widget Structure

```
InteractiveViewer(
  transformationController: _controller,   // TransformationController
  minScale: 1.0,
  maxScale: 4.0,
  child: GestureDetector(
    onTapUp: _handleTap,                  // convert coords then hit-test
    child: SizedBox(
      width: 1200,
      height: 700,
      child: Stack(
        children: [
          // Layer 1: Static — borders, territory shapes, continent labels
          RepaintBoundary(
            child: CustomPaint(
              painter: MapBasePainter(territoryData: _territoryData),
              size: const Size(1200, 700),
            ),
          ),
          // Layer 2: Dynamic — owner colors, army counts, highlights
          CustomPaint(
            painter: MapOverlayPainter(
              gameState: gameState,
              uiState: uiState,
              territoryData: _territoryData,
            ),
            size: const Size(1200, 700),
          ),
        ],
      ),
    ),
  ),
)
```

### Recommended File Structure

```
lib/widgets/map/
├── map_widget.dart          # StatefulWidget: InteractiveViewer + GestureDetector + layer stack
├── map_base_painter.dart    # CustomPainter: static territory outlines, borders (RepaintBoundary child)
├── map_overlay_painter.dart # CustomPainter: owner colors, army counts, highlights (repaints on state)
└── territory_data.dart      # 42 territory Rects + label positions (SVG 1200x700 coordinate space)
```

### Pattern 1: Territory Data as Dart Constants

**What:** All 42 territory rectangles and army-count label positions extracted from the SVG and stored as Dart constants in `territory_data.dart`. Keyed by territory name string (matching `GameState.territories` keys exactly).

**Why:** The SVG uses simple rectangles (`M x,y L x,y L x,y L x,y Z`). Extracting coordinates at authoring time is faster at runtime and avoids any parsing dependency. The coordinate space (SVG viewBox 1200x700) is preserved directly.

**Example:**
```dart
// territory_data.dart
// Source: risk/data/classic_map.svg viewBox="0 0 1200 700"

const Map<String, TerritoryGeometry> kTerritoryData = {
  'Alaska': TerritoryGeometry(
    rect: Rect.fromLTWH(30, 60, 60, 50),   // M 30,60 L 90,60 L 90,110 L 30,110 Z
    labelOffset: Offset(60, 85),
  ),
  'Northwest Territory': TerritoryGeometry(
    rect: Rect.fromLTWH(100, 45, 100, 50),
    labelOffset: Offset(150, 70),
  ),
  // ... all 42 territories
};

class TerritoryGeometry {
  final Rect rect;
  final Offset labelOffset;
  const TerritoryGeometry({required this.rect, required this.labelOffset});
}
```

### Pattern 2: Two-Layer CustomPainter (Static + Dynamic)

**What:** The map renders as two stacked CustomPaint widgets. Layer 1 (static base) is wrapped in RepaintBoundary so Flutter can cache its raster after the first paint. Layer 2 (dynamic overlay) repaints on every GameState or UIState change.

**Why:** Documented mitigation for Flutter issue #72066 — drawing 42+ paths inside InteractiveViewer during zoom causes frame drops. The static layer repaints exactly once (on first build). The dynamic layer only repaints when game state changes, which is infrequent (once per player action).

**Static layer paints:** territory outlines (grey border), territory fill (neutral grey background), continent labels.
**Dynamic layer paints:** territory fill (owner color), selection highlight (bright border or tint), valid-source tint (yellow), valid-target tint (green/red), army count text.

**Example:**
```dart
// map_overlay_painter.dart
class MapOverlayPainter extends CustomPainter {
  final GameState gameState;
  final UIState uiState;
  final Map<String, TerritoryGeometry> territoryData;

  static const List<Color> kPlayerColors = [
    Color(0xFFE53935), // P0: Red
    Color(0xFF1E88E5), // P1: Blue
    Color(0xFF43A047), // P2: Green
    Color(0xFFFDD835), // P3: Yellow
    Color(0xFF8E24AA), // P4: Purple
    Color(0xFFFF7043), // P5: Orange
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 1200;
    final scaleY = size.height / 700;
    canvas.scale(scaleX, scaleY);

    for (final entry in territoryData.entries) {
      final name = entry.key;
      final geom = entry.value;
      final ts = gameState.territories[name];
      if (ts == null) continue;

      // Fill with owner color
      final fillPaint = Paint()
        ..color = kPlayerColors[ts.owner % kPlayerColors.length]
        ..style = PaintingStyle.fill;
      canvas.drawRect(geom.rect, fillPaint);

      // Selection highlight
      if (name == uiState.selectedTerritory) {
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawRect(geom.rect, highlightPaint);
      }

      // Army count label
      final tp = TextPainter(
        text: TextSpan(
          text: '${ts.armies}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        geom.labelOffset - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(MapOverlayPainter old) =>
      old.gameState != gameState || old.uiState != uiState;
}
```

### Pattern 3: Coordinate Transform for Hit Testing Under Zoom

**What:** When a tap fires inside GestureDetector wrapping the InteractiveViewer child, `details.localPosition` is in the child's local space (the 1200x700 canvas). HOWEVER, if the GestureDetector wraps the InteractiveViewer (not the child), you must use `TransformationController.toScene()` to convert from viewport to scene coordinates.

**Correct widget nesting:** Place GestureDetector as the DIRECT child of InteractiveViewer (inside, not outside) OR use `_controller.toScene(details.localPosition)` if GestureDetector wraps InteractiveViewer.

**Critical detail:** The SVG coordinate space is 1200x700, but the widget may be rendered at a different pixel size. The MapOverlayPainter scales with `canvas.scale(scaleX, scaleY)`. For hit testing, the tap coordinates must be mapped to the same 1200x700 space before testing against the stored `Rect` values.

**Example (GestureDetector inside InteractiveViewer):**
```dart
// map_widget.dart — GestureDetector wraps InteractiveViewer:
void _handleTap(TapUpDetails details) {
  // Convert viewport coords to scene coords (unzoomed 1200x700 space)
  final scenePoint = _controller.toScene(details.localPosition);

  // Scale from rendered widget size to SVG coordinate space
  final renderBox = context.findRenderObject() as RenderBox;
  final svgX = scenePoint.dx / renderBox.size.width * 1200;
  final svgY = scenePoint.dy / renderBox.size.height * 700;
  final svgPoint = Offset(svgX, svgY);

  _selectTerritoryAt(svgPoint);
}

void _selectTerritoryAt(Offset svgPoint) {
  const hitPadding = 6.0; // 6dp expansion for small territories (MAPW-05)
  final hits = <String>[];

  for (final entry in kTerritoryData.entries) {
    if (entry.value.rect.inflate(hitPadding).contains(svgPoint)) {
      hits.add(entry.key);
    }
  }

  if (hits.isEmpty) return;
  if (hits.length == 1) {
    _selectTerritory(hits.first);
  } else {
    // Multiple expanded rects match — show disambiguation popup
    _showDisambiguationDialog(hits);
  }
}
```

### Pattern 4: Disambiguation Popup for Dense Territories

**What:** When a tap point falls within the expanded hit region of multiple territories, show an AlertDialog with a list of territory names for the user to choose from.

**When to use:** Dense regions (European territories, SE Asian territories) where 6dp expansion causes rectangle overlap. Expected to occur rarely on tablets, more frequently on small phones.

**Example:**
```dart
void _showDisambiguationDialog(List<String> territories) {
  showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Select territory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final name in territories)
            ListTile(
              title: Text(name),
              onTap: () {
                Navigator.pop(ctx, name);
                _selectTerritory(name);
              },
            ),
        ],
      ),
    ),
  );
}
```

### Anti-Patterns to Avoid

- **Parsing SVG at runtime inside build() or paint():** Path parsing in `paint()` is called every frame — catastrophic jank. Parse (or define) paths once at app startup.
- **Placing GestureDetector outside InteractiveViewer without using toScene():** Tap coordinates will be in viewport space, not scene space. Hit tests will be wrong at any zoom level > 1x.
- **Putting territory geometry in GameState or UIState:** Map geometry is static; it never changes during a game. It belongs in a const map, not in state providers.
- **Single-layer CustomPainter for both static and dynamic content:** Causes all 42 territory fills, borders, and labels to repaint on every army count change. Use two layers.
- **Using SvgPicture.asset() and relying on tap detection from flutter_svg:** flutter_svg does not expose per-element tap callbacks. You cannot get territory-level tap detection from the rendered SVG widget.
- **Forgetting canvas.scale() in the painter:** Without scaling, the 1200x700 SVG-space paths render at a fixed size regardless of the widget's actual render dimensions.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Zoom and pan gesture handling | Manual GestureDetector with scale + pan callbacks | `InteractiveViewer` (Flutter built-in) | InteractiveViewer handles inertia, edge clamping, min/max scale, and the TransformationController — all of this is complex to reproduce correctly |
| SVG path to Flutter Path conversion | Custom SVG parser | `path_parsing` (already in pubspec.yaml) via `writeSvgPathDataToPath` | SVG path grammar has many edge cases (relative coords, arc commands, implicit line-to, etc.) |
| Disambiguation popup | Custom overlay widget | `showDialog` with `AlertDialog` | Material AlertDialog handles dismiss on back, barrier tap, and accessibility for free |
| Player color assignment | Ad-hoc color mapping | const `kPlayerColors` list indexed by `owner` | Simple, testable, deterministic |

**Key insight:** For this specific SVG (simple rectangles), even `path_parsing` is optional — the geometry can be expressed as `Rect.fromLTWH()` constants matching the SVG path points exactly. The value of `path_parsing` only materializes if the map is later upgraded to complex polygon territories.

---

## Common Pitfalls

### Pitfall 1: Wrong Coordinate Space for Hit Testing Under Zoom

**What goes wrong:** Tap coordinates from `onTapUp(details)` are in the GestureDetector's local coordinate space. After pinch-zoom, the canvas is transformed — the same screen pixel corresponds to a different position in the 1200x700 SVG space. Hit tests using `details.localPosition` directly against territory `Rect` objects will fail at any zoom level other than 1x.

**Why it happens:** Developers test at 1x zoom (default), where viewport and scene coordinates are identical, and miss the bug. The bug manifests only after the user zooms in.

**How to avoid:** Always use `_controller.toScene(details.localPosition)` to convert to scene coordinates before hit testing. Confirm with a test at 2x and 4x zoom.

**Warning signs:** Territory selection works at normal zoom but stops working correctly after pinch-zoom. Tapping "near" a territory selects it at 1x but misses at 4x.

### Pitfall 2: shouldRepaint Returns False Permanently

**What goes wrong:** If `MapOverlayPainter.shouldRepaint()` always returns `false`, the overlay never repaints. Territory colors, army counts, and highlights will freeze on first paint and never update.

**Why it happens:** Developers paste a stub `shouldRepaint` that returns `false` as a performance optimization and forget to implement the equality check.

**How to avoid:** `shouldRepaint` must compare the incoming painter's `gameState` and `uiState` with the current values. Since `GameState` and `UIState` are both `@freezed` (with deep equality), `old.gameState != gameState || old.uiState != uiState` is correct and sufficient.

### Pitfall 3: RepaintBoundary Does Not Cache if Content Changes

**What goes wrong:** If any parameter passed to `MapBasePainter` (the static layer) changes — even an unused one — Flutter invalidates the RepaintBoundary cache and repaints. The static layer loses its performance benefit.

**Why it happens:** A common mistake is passing the full GameState to the base painter "just in case" even though it only draws static outlines.

**How to avoid:** `MapBasePainter` must accept ONLY the static territory geometry data (a const). It must not accept `GameState` or `UIState`. Its `shouldRepaint` should always return `false`.

### Pitfall 4: Army Count Label Clipping Inside Small Rectangles

**What goes wrong:** European and SE Asian territories have small rects (e.g. Iceland is 60x45, Japan is 60x70). A 2-digit army count label at 12sp may clip against the territory border.

**Why it happens:** The `TextPainter` size is computed at layout time; the label position is computed relative to the rect center without checking if the label fits.

**How to avoid:** Use a smaller font size (10sp) and test with 3-digit army counts (100+) on small territories. The `labelOffset` positions in `kTerritoryData` should be the visual center of the rect, not the geometric center, if the rect is wider than tall.

### Pitfall 5: InteractiveViewer and GestureDetector Gesture Competition

**What goes wrong:** Both InteractiveViewer and GestureDetector respond to touch events. A tap can be consumed by InteractiveViewer's scale recognizer and never reach the GestureDetector.

**Why it happens:** InteractiveViewer uses a Scale gesture recognizer that listens for all pointer events. If the GestureDetector is placed outside InteractiveViewer, a tap must not be ambiguous with a pinch.

**How to avoid:** Place GestureDetector as a direct child INSIDE InteractiveViewer (i.e., wrapping the actual canvas content). Taps (single-pointer) are passed through to child GestureDetectors; only multi-pointer scale gestures are consumed by InteractiveViewer.

### Pitfall 6: canvas.scale() Aspect Ratio Distortion

**What goes wrong:** The SVG viewBox is 1200x700 (approximately 17:10 ratio). If the widget is rendered in a square container (1:1 ratio) and canvas.scale() uses the same factor for both axes, territories will appear distorted.

**Why it happens:** Using a single scale factor `min(width / 1200, height / 700)` without centering the canvas on the remaining dimension causes the map to anchor to the top-left with dead space.

**How to avoid:** Use separate scaleX and scaleY OR use BoxFit.contain logic to compute a uniform scale and center the canvas with `canvas.translate()`. For simplicity, use separate `scaleX = size.width / 1200` and `scaleY = size.height / 700` — this stretches the map to fill the container, which is acceptable for rectangular territories.

---

## Code Examples

Verified patterns from official sources:

### SVG Rectangle to Dart Rect (from classic_map.svg)

```dart
// Source: risk/data/classic_map.svg — path d="M 30,60 L 90,60 L 90,110 L 30,110 Z"
// Parse: x1=30, y1=60, x2=90, y2=60, x3=90, y3=110, x4=30, y4=110
// => left=30, top=60, width=60, height=50
const alaskaRect = Rect.fromLTWH(30, 60, 60, 50);
```

### path_parsing Usage (if needed for non-rectangular paths)

```dart
// Source: https://pub.dev/packages/path_parsing
import 'package:path_parsing/path_parsing.dart';
import 'dart:ui' as ui;

class _FlutterPathProxy extends PathProxy {
  final ui.Path path = ui.Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(double x1, double y1, double x2, double y2,
               double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

ui.Path svgStringToPath(String svgPathData) {
  final proxy = _FlutterPathProxy();
  writeSvgPathDataToPath(svgPathData, proxy);
  return proxy.path;
}
```

### TransformationController.toScene() Usage

```dart
// Source: https://api.flutter.dev/flutter/widgets/TransformationController/toScene.html
final TransformationController _controller = TransformationController();

void _handleTap(TapUpDetails details) {
  // details.localPosition is in the GestureDetector's local space (viewport space)
  // toScene() inverts the zoom/pan transform to get the scene (canvas) point
  final scenePoint = _controller.toScene(details.localPosition);
  // scenePoint is now in the 1200x700 SVG coordinate space
  _selectTerritoryAt(scenePoint);
}
```

### RepaintBoundary for Static Layer

```dart
// Source: https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html
// The engine caches the raster of RepaintBoundary children that don't repaint.
RepaintBoundary(
  child: CustomPaint(
    painter: MapBasePainter(territoryData: kTerritoryData), // const data only
    size: const Size(1200, 700),
    isComplex: true,   // hint: complex path rendering, worth caching
    willChange: false, // hint: content is stable
  ),
)
```

### InteractiveViewer Setup

```dart
// Source: https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html
InteractiveViewer(
  transformationController: _controller,
  minScale: 1.0,
  maxScale: 4.0,
  constrained: false,  // child can be larger than viewport
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: _handleTap,
    child: SizedBox(
      width: 1200,
      height: 700,
      child: Stack(children: [_staticLayer, _dynamicLayer]),
    ),
  ),
)
```

---

## Existing Infrastructure (Already Built)

This section documents what Phase 10 inherits from prior phases — no re-building needed.

### UIState and UIStateNotifier (Phase 9)

`UIState` (in `mobile/lib/engine/models/ui_state.dart`) has:
- `String? selectedTerritory`
- `Set<String> validTargets`
- `Set<String> validSources`

`UIStateNotifier.selectTerritory(String name, GameState, MapGraph)` already computes:
- valid sources (owned, ≥2 armies)
- valid targets by phase (attack: adjacent enemy; fortify: BFS-connected friendly)

The MapWidget only needs to call `ref.read(uIStateProvider.notifier).selectTerritory(name, gameState, mapGraph)` on tap — the computation is already done.

Provider name is `uIStateProvider` (Riverpod 3.x generator strips Notifier suffix, preserving original casing).

### GameNotifier (Phase 9)

`gameProvider` exposes `AsyncValue<GameState?>`. The MapWidget watches `gameProvider` and handles the null/loading/error states before rendering the overlay.

### mapGraphProvider (Phase 9)

`mapGraphProvider` provides `Future<MapGraph>` — loaded once at startup from `assets/classic.json`. The MapWidget passes this to `UIStateNotifier.selectTerritory()`.

### Player Colors

Phase 10 defines `kPlayerColors` as a const list. This is new (no prior phase defined it). Six colors are needed (max 6 players). Color accessibility note: the project has `COLR-01` as a v2 requirement (Wong palette for colorblind mode); the default palette should use high-contrast colors but does not need to be the Wong palette yet.

---

## SVG Coordinate Reference

The SVG viewBox is `0 0 1200 700`. All territory rects in `kTerritoryData` use these coordinates. Complete data (all 42 territories):

| Territory | SVG Path (M x,y L x2,y L x2,y2 L x,y2 Z) | Rect(left, top, width, height) | Label Center |
|-----------|-------------------------------------------|-------------------------------|--------------|
| Alaska | M 30,60 L 90,60 L 90,110 L 30,110 Z | (30, 60, 60, 50) | (60, 85) |
| Northwest Territory | M 100,45 L 200,45 L 200,95 L 100,95 Z | (100, 45, 100, 50) | (150, 70) |
| Greenland | M 260,30 L 350,30 L 350,90 L 260,90 Z | (260, 30, 90, 60) | (305, 60) |
| Alberta | M 70,120 L 140,120 L 140,175 L 70,175 Z | (70, 120, 70, 55) | (105, 147) |
| Ontario | M 150,105 L 230,105 L 230,170 L 150,170 Z | (150, 105, 80, 65) | (190, 137) |
| Quebec | M 240,100 L 310,100 L 310,165 L 240,165 Z | (240, 100, 70, 65) | (275, 132) |
| Western United States | M 60,185 L 145,185 L 145,250 L 60,250 Z | (60, 185, 85, 65) | (102, 217) |
| Eastern United States | M 155,175 L 250,175 L 250,255 L 155,255 Z | (155, 175, 95, 80) | (202, 215) |
| Central America | M 100,260 L 185,260 L 185,325 L 100,325 Z | (100, 260, 85, 65) | (142, 292) |
| Venezuela | M 160,340 L 255,340 L 255,395 L 160,395 Z | (160, 340, 95, 55) | (207, 367) |
| Peru | M 145,405 L 220,405 L 220,475 L 145,475 Z | (145, 405, 75, 70) | (182, 440) |
| Brazil | M 230,390 L 320,390 L 320,470 L 230,470 Z | (230, 390, 90, 80) | (275, 430) |
| Argentina | M 170,485 L 260,485 L 260,570 L 170,570 Z | (170, 485, 90, 85) | (215, 527) |
| North Africa | M 400,295 L 510,295 L 510,375 L 400,375 Z | (400, 295, 110, 80) | (455, 335) |
| Egypt | M 520,285 L 610,285 L 610,350 L 520,350 Z | (520, 285, 90, 65) | (565, 317) |
| East Africa | M 545,360 L 630,360 L 630,445 L 545,445 Z | (545, 360, 85, 85) | (587, 402) |
| Congo | M 460,385 L 535,385 L 535,460 L 460,460 Z | (460, 385, 75, 75) | (497, 422) |
| South Africa | M 480,470 L 575,470 L 575,555 L 480,555 Z | (480, 470, 95, 85) | (527, 512) |
| Madagascar | M 620,470 L 680,470 L 680,540 L 620,540 Z | (620, 470, 60, 70) | (650, 505) |
| Iceland | M 400,65 L 460,65 L 460,110 L 400,110 Z | (400, 65, 60, 45) | (430, 87) |
| Scandinavia | M 500,60 L 575,60 L 575,125 L 500,125 Z | (500, 60, 75, 65) | (537, 92) |
| Ukraine | M 585,70 L 680,70 L 680,175 L 585,175 Z | (585, 70, 95, 105) | (632, 122) |
| Great Britain | M 405,125 L 475,125 L 475,185 L 405,185 Z | (405, 125, 70, 60) | (440, 155) |
| Northern Europe | M 485,135 L 575,135 L 575,195 L 485,195 Z | (485, 135, 90, 60) | (530, 165) |
| Southern Europe | M 490,205 L 580,205 L 580,270 L 490,270 Z | (490, 205, 90, 65) | (535, 237) |
| Western Europe | M 400,200 L 480,200 L 480,280 L 400,280 Z | (400, 200, 80, 80) | (440, 240) |
| Ural | M 700,60 L 770,60 L 770,140 L 700,140 Z | (700, 60, 70, 80) | (735, 100) |
| Siberia | M 780,45 L 850,45 L 850,125 L 780,125 Z | (780, 45, 70, 80) | (815, 85) |
| Yakutsk | M 860,40 L 945,40 L 945,100 L 860,100 Z | (860, 40, 85, 60) | (902, 70) |
| Kamchatka | M 955,35 L 1040,35 L 1040,105 L 955,105 Z | (955, 35, 85, 70) | (997, 70) |
| Irkutsk | M 870,110 L 950,110 L 950,170 L 870,170 Z | (870, 110, 80, 60) | (910, 140) |
| Mongolia | M 880,180 L 975,180 L 975,240 L 880,240 Z | (880, 180, 95, 60) | (927, 210) |
| Japan | M 1000,150 L 1060,150 L 1060,220 L 1000,220 Z | (1000, 150, 60, 70) | (1030, 185) |
| Afghanistan | M 700,150 L 790,150 L 790,215 L 700,215 Z | (700, 150, 90, 65) | (745, 182) |
| China | M 800,180 L 870,180 L 870,260 L 800,260 Z | (800, 180, 70, 80) | (835, 220) |
| Middle East | M 620,195 L 720,195 L 720,280 L 620,280 Z | (620, 195, 100, 85) | (670, 237) |
| India | M 750,225 L 830,225 L 830,310 L 750,310 Z | (750, 225, 80, 85) | (790, 267) |
| Siam | M 840,270 L 910,270 L 910,345 L 840,345 Z | (840, 270, 70, 75) | (875, 307) |
| Indonesia | M 880,385 L 960,385 L 960,445 L 880,445 Z | (880, 385, 80, 60) | (920, 415) |
| New Guinea | M 1000,380 L 1085,380 L 1085,430 L 1000,430 Z | (1000, 380, 85, 50) | (1042, 405) |
| Western Australia | M 900,460 L 985,460 L 985,540 L 900,540 Z | (900, 460, 85, 80) | (942, 500) |
| Eastern Australia | M 1010,445 L 1095,445 L 1095,540 L 1010,540 Z | (1010, 445, 85, 95) | (1052, 492) |

**Dense regions requiring disambiguation popup most often:**
- Europe cluster: Iceland/Great Britain/Western Europe/Northern Europe/Southern Europe are tightly packed 60-90 unit rects
- SE Asia: Siam/China/India/Afghanistan/Middle East cluster around 700-910 x-range, 150-345 y-range

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK) |
| Config file | pubspec.yaml (no separate config) |
| Quick run command | `cd /home/amiller/Repos/risk/mobile && flutter test test/widgets/map/ --no-pub` |
| Full suite command | `cd /home/amiller/Repos/risk/mobile && flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MAPW-01 | InteractiveViewer renders MapWidget at 1x–4x scale without overflow | Widget test | `flutter test test/widgets/map/map_widget_test.dart -x` | ❌ Wave 0 |
| MAPW-02 | Tap on territory rect calls UIStateNotifier.selectTerritory with correct name | Widget test | `flutter test test/widgets/map/map_widget_test.dart -x` | ❌ Wave 0 |
| MAPW-02 | Hit test at zoom 1x selects correct territory | Unit test | `flutter test test/widgets/map/territory_hit_test_test.dart -x` | ❌ Wave 0 |
| MAPW-02 | Hit test at zoom 2x selects correct territory | Unit test | `flutter test test/widgets/map/territory_hit_test_test.dart -x` | ❌ Wave 0 |
| MAPW-03 | Territory painted with owner's color (player 0 = red, player 1 = blue) | Golden test | `flutter test test/widgets/map/map_golden_test.dart -x` | ❌ Wave 0 |
| MAPW-04 | Selected territory shows highlight; valid targets show target tint | Golden test | `flutter test test/widgets/map/map_golden_test.dart -x` | ❌ Wave 0 |
| MAPW-05 | Tap 4dp outside tiny territory rect still selects it (expanded hit zone) | Unit test | `flutter test test/widgets/map/territory_hit_test_test.dart -x` | ❌ Wave 0 |
| MAPW-05 | Tap in overlap of two expanded rects triggers disambiguation callback | Unit test | `flutter test test/widgets/map/territory_hit_test_test.dart -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/widgets/map/ --no-pub`
- **Per wave merge:** `flutter test --no-pub` (full suite, currently 157 tests)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/widgets/map/map_widget_test.dart` — covers MAPW-01, MAPW-02 (widget integration)
- [ ] `test/widgets/map/territory_hit_test_test.dart` — covers MAPW-02 (zoom), MAPW-05 (expansion, disambiguation)
- [ ] `test/widgets/map/map_golden_test.dart` — covers MAPW-03, MAPW-04 (visual correctness)
- [ ] `test/widgets/map/` directory — does not yet exist

---

## Open Questions

1. **Player color for eliminated players**
   - What we know: `PlayerState.isAlive` tracks elimination status
   - What's unclear: Should eliminated territories show a greyed-out color, a neutral color, or the eliminator's color? (After conquest in Risk, territories go to the conquering player, so this should never happen — an eliminated player has zero territories)
   - Recommendation: Treat this as non-issue; if a player is eliminated they own no territories. No special color handling needed. Verify with game engine logic.

2. **Map aspect ratio handling on different screen sizes**
   - What we know: SVG is 1200x700; phones are typically 360-430dp wide
   - What's unclear: Should the map fill the full width (stretching the 17:10 aspect to phone's aspect), or maintain the 1200:700 ratio with letterboxing?
   - Recommendation: Use `InteractiveViewer` with `constrained: false` and a fixed SizedBox(1200, 700) child. The phone will show a portion of the map at 1x zoom, and users pinch-zoom/pan to the area they want. This matches how the web version works. The `minScale: 1.0` prevents zooming out further.

3. **Army count update animation**
   - What we know: Requirements specify counts display and update immediately on state change (MAPW-03)
   - What's unclear: Is an instant color/number update acceptable (no animation) or should a brief flash indicate the change?
   - Recommendation: No animation for v1.1 — instant update is explicitly what MAPW-03 specifies. Animations are v2 scope.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `path_drawing.parseSvgPathData()` (one-line SVG to Path) | `path_parsing.writeSvgPathDataToPath()` with custom PathProxy | path_drawing abandoned ~2022; path_parsing is its successor | Requires implementing a 5-method PathProxy wrapper; still straightforward |
| `ui.PictureRecorder` manual pre-rasterization | `RepaintBoundary` with `isComplex: true` / `willChange: false` hints | Flutter engine improvement ~2024 | RepaintBoundary approach is simpler; engine caches automatically |

---

## Sources

### Primary (HIGH confidence)

- [Flutter InteractiveViewer class](https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html) — minScale/maxScale/constrained parameters, TransformationController integration
- [TransformationController.toScene()](https://api.flutter.dev/flutter/widgets/TransformationController/toScene.html) — viewport-to-scene coordinate conversion signature and behavior
- [Flutter CustomPainter class](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html) — shouldRepaint contract, canvas operations
- [RepaintBoundary class](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html) — caching behavior and `isComplex`/`willChange` hints
- [dart:ui Path.contains()](https://api.flutter.dev/flutter/dart-ui/Path/contains.html) — hit detection method signature
- [path_parsing pub.dev example](https://pub.dev/packages/path_parsing/example) — `writeSvgPathDataToPath(String, PathProxy)` exact API
- [Flutter issue #72066](https://github.com/flutter/flutter/issues/72066) — documented CustomPainter + InteractiveViewer performance regression
- `risk/data/classic_map.svg` (local file) — all 42 territory SVG path strings and label positions verified directly

### Secondary (MEDIUM confidence)

- [Build interactive maps in Flutter with SVG — Appwriters](https://www.appwriters.dev/blog/flutter-interactive-svg-maps) — path-based hit detection pattern with path.contains()
- [Flutter Interactive Viewer — gladimdim.org](https://gladimdim.org/animating-interactiveviewer-in-flutter-or-how-to-animate-map-in-your-game) — TransformationController coordinate transform pattern in game map context
- [High-Performance Canvas Rendering — plugfox.dev](https://plugfox.dev/high-performance-canvas-rendering/) — RepaintBoundary + PictureRecorder comparison for complex CustomPainter scenes

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already in pubspec.yaml; Flutter built-ins verified against official API docs
- SVG geometry: HIGH — all 42 territory coordinates extracted directly from `risk/data/classic_map.svg` and verified by reading the file
- Architecture: HIGH — two-layer pattern verified against Flutter performance issue #72066 and official RepaintBoundary docs
- Hit-test transform: HIGH — TransformationController.toScene() confirmed from official Flutter API docs
- path_parsing API: HIGH — `writeSvgPathDataToPath(String, PathProxy)` confirmed from pub.dev example; PathProxy implementation is straightforward
- Pitfalls: HIGH — sourced from Flutter GitHub issues, official docs, and direct inspection of the SVG data

**Research date:** 2026-03-15
**Valid until:** 2026-06-15 (Flutter APIs are stable; RepaintBoundary behavior is not expected to change)
