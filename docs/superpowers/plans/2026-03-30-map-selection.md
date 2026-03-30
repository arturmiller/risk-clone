# Map Selection & Polygon Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded rectangle-based map with polygon-based maps loaded from JSON, and add a map selection dropdown on the home screen.

**Architecture:** The editor exports maps as JSON with polygon paths per territory. We parse this into two structures: `MapGraph` (for game logic, unchanged) and `MapVisualData` (for rendering). `TerritoryGeometry` gains a `polygon` field; painters draw polygons instead of rectangles; hit testing uses point-in-polygon. A new family provider loads maps by asset name, and `GameConfig` carries the selected map name through to the providers.

**Tech Stack:** Flutter, Riverpod (code-gen), Freezed, CustomPainter

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `mobile/assets/original.json` | Create | Copy from `maps/original/map.json` |
| `mobile/pubspec.yaml` | Modify | Update asset declaration |
| `mobile/lib/widgets/map/territory_data.dart` | Modify | Add `polygon` to `TerritoryGeometry`, add `pointInPolygon` helper, remove hardcoded `kTerritoryData` |
| `mobile/lib/engine/models/map_schema.dart` | Modify | Add `TerritoryVisualData`, `MapVisualData` freezed classes |
| `mobile/lib/engine/models/map_schema.freezed.dart` | Regenerate | Freezed codegen |
| `mobile/lib/engine/models/map_schema.g.dart` | Regenerate | JSON codegen |
| `mobile/lib/providers/map_provider.dart` | Modify | Add family providers for mapGraph + visual data by map name |
| `mobile/lib/providers/map_provider.g.dart` | Regenerate | Riverpod codegen |
| `mobile/lib/widgets/map/map_base_painter.dart` | Modify | Draw polygons instead of rects |
| `mobile/lib/widgets/map/map_overlay_painter.dart` | Modify | Fill polygons with player colors |
| `mobile/lib/widgets/map/map_widget.dart` | Modify | Use dynamic territory data from provider |
| `mobile/lib/engine/models/game_config.dart` | Modify | Add `mapAsset` field |
| `mobile/lib/screens/home_screen.dart` | Modify | Add map dropdown |
| `mobile/lib/providers/game_provider.dart` | Modify | Pass map asset to provider |

---

### Task 1: Add Map Asset

**Files:**
- Create: `mobile/assets/original.json`
- Modify: `mobile/pubspec.yaml`

- [ ] **Step 1: Copy map JSON to assets**

Copy `maps/original/map.json` to `mobile/assets/original.json`.

- [ ] **Step 2: Update pubspec.yaml assets**

In `mobile/pubspec.yaml`, change the assets section:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/
```

Using directory-level asset declaration so all JSON files in `assets/` are included (supports future maps without pubspec edits).

- [ ] **Step 3: Commit**

```bash
git add mobile/assets/original.json mobile/pubspec.yaml
git commit -m "feat: add original map asset and use directory-level asset declaration"
```

---

### Task 2: Extend TerritoryGeometry with Polygon Support

**Files:**
- Modify: `mobile/lib/widgets/map/territory_data.dart`

- [ ] **Step 1: Add polygon field and point-in-polygon helper**

Replace the content of `territory_data.dart`:

```dart
import 'dart:ui';

/// Geometry for a single territory: polygon path, bounding rect, and label center.
class TerritoryGeometry {
  final List<Offset> polygon;
  final Rect rect;
  final Offset labelOffset;
  final Color? baseColor;

  TerritoryGeometry({
    required this.polygon,
    required this.labelOffset,
    this.baseColor,
  }) : rect = _boundingRect(polygon);

  static Rect _boundingRect(List<Offset> pts) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Path toPath() {
    final path = Path();
    if (polygon.isEmpty) return path;
    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(polygon[i].dx, polygon[i].dy);
    }
    path.close();
    return path;
  }
}

/// Six player colors, indexed 0-5.
const List<Color> kPlayerColors = [
  Color(0xFFE53935), // P0 - Red
  Color(0xFF1E88E5), // P1 - Blue
  Color(0xFF43A047), // P2 - Green
  Color(0xFFFDD835), // P3 - Yellow
  Color(0xFF8E24AA), // P4 - Purple
  Color(0xFFFF7043), // P5 - Orange
];

/// Ray-casting point-in-polygon test.
bool pointInPolygon(Offset point, List<Offset> polygon) {
  bool inside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].dx, yi = polygon[i].dy;
    final xj = polygon[j].dx, yj = polygon[j].dy;
    if (((yi > point.dy) != (yj > point.dy)) &&
        (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/widgets/map/territory_data.dart
git commit -m "feat: add polygon support to TerritoryGeometry with point-in-polygon"
```

---

### Task 3: Update Map Provider to Load New Format

**Files:**
- Modify: `mobile/lib/providers/map_provider.dart`
- Modify: `mobile/lib/widgets/map/territory_data.dart` (import)

- [ ] **Step 1: Rewrite map_provider.dart**

```dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../engine/map_graph.dart';
import '../engine/models/map_schema.dart';
import '../widgets/map/territory_data.dart';

part 'map_provider.g.dart';

/// Holds both graph data (for game logic) and visual data (for rendering).
class LoadedMap {
  final MapGraph graph;
  final Map<String, TerritoryGeometry> territoryData;
  final Size canvasSize;
  final String name;

  const LoadedMap({
    required this.graph,
    required this.territoryData,
    required this.canvasSize,
    required this.name,
  });
}

/// Available maps (asset filename without extension → display name).
const Map<String, String> kAvailableMaps = {
  'original': 'Classic (Original)',
};

@riverpod
Future<LoadedMap> loadedMap(Ref ref, {String mapAsset = 'original'}) async {
  final jsonString = await rootBundle.loadString('assets/$mapAsset.json');
  final raw = jsonDecode(jsonString) as Map<String, dynamic>;
  return _parseMap(raw);
}

/// Keep backwards-compatible mapGraphProvider for existing code.
@riverpod
Future<MapGraph> mapGraph(Ref ref, {String mapAsset = 'original'}) async {
  final loaded = await ref.watch(loadedMapProvider(mapAsset: mapAsset).future);
  return loaded.graph;
}

LoadedMap _parseMap(Map<String, dynamic> raw) {
  final name = raw['name'] as String? ?? 'Untitled';
  final canvasList = raw['canvasSize'] as List<dynamic>;
  final canvasSize = Size(
    (canvasList[0] as num).toDouble(),
    (canvasList[1] as num).toDouble(),
  );

  final rawTerritories = raw['territories'] as Map<String, dynamic>;
  final territoryNames = rawTerritories.keys.toList();

  // Parse visual data
  final territoryData = <String, TerritoryGeometry>{};
  for (final entry in rawTerritories.entries) {
    final data = entry.value as Map<String, dynamic>;
    final pathList = data['path'] as List<dynamic>;
    final polygon = pathList
        .map((p) => Offset(
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ))
        .toList();
    final labelPos = data['labelPosition'] as List<dynamic>;
    final colorStr = data['color'] as String?;
    Color? baseColor;
    if (colorStr != null) {
      final hex = colorStr.replaceFirst('#', '');
      baseColor = Color(int.parse('FF$hex', radix: 16));
    }
    territoryData[entry.key] = TerritoryGeometry(
      polygon: polygon,
      labelOffset: Offset(
        (labelPos[0] as num).toDouble(),
        (labelPos[1] as num).toDouble(),
      ),
      baseColor: baseColor,
    );
  }

  // Parse continents
  final rawContinents = raw['continents'] as List<dynamic>;
  final continents = rawContinents
      .map((c) => ContinentData(
            name: c['name'] as String,
            territories: (c['territories'] as List<dynamic>).cast<String>(),
            bonus: c['bonus'] as int,
          ))
      .toList();

  // Parse adjacencies
  final rawAdjacencies = raw['adjacencies'] as List<dynamic>;
  final adjacencies = rawAdjacencies
      .map((a) => (a as List<dynamic>).cast<String>())
      .toList();

  final mapData = MapData(
    name: name,
    territories: territoryNames,
    continents: continents,
    adjacencies: adjacencies,
  );

  return LoadedMap(
    graph: MapGraph(mapData),
    territoryData: territoryData,
    canvasSize: canvasSize,
    name: name,
  );
}
```

- [ ] **Step 2: Run codegen**

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/providers/map_provider.dart mobile/lib/providers/map_provider.g.dart
git commit -m "feat: map provider loads polygon-based map format with visual data"
```

---

### Task 4: Update MapBasePainter for Polygons

**Files:**
- Modify: `mobile/lib/widgets/map/map_base_painter.dart`

- [ ] **Step 1: Draw polygon paths instead of rects**

```dart
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'territory_data.dart';

class MapBasePainter extends CustomPainter {
  final Map<String, TerritoryGeometry> territoryData;
  final Size canvasSize;

  const MapBasePainter({
    required this.territoryData,
    this.canvasSize = const Size(1200, 700),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / canvasSize.width;
    final scaleY = size.height / canvasSize.height;
    canvas.scale(scaleX, scaleY);

    final borderPaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final entry in territoryData.entries) {
      final geom = entry.value;
      final path = geom.toPath();

      // Fill with territory base color or default gray
      final fillPaint = Paint()
        ..color = geom.baseColor ?? const Color(0xFFCFD8DC)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(MapBasePainter old) =>
      old.territoryData != territoryData;
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/widgets/map/map_base_painter.dart
git commit -m "feat: MapBasePainter draws polygon territories"
```

---

### Task 5: Update MapOverlayPainter for Polygons

**Files:**
- Modify: `mobile/lib/widgets/map/map_overlay_painter.dart`

- [ ] **Step 1: Replace rect drawing with polygon paths**

```dart
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../engine/models/game_state.dart';
import '../../engine/models/ui_state.dart';
import 'territory_data.dart';

class MapOverlayPainter extends CustomPainter {
  final GameState gameState;
  final UIState uiState;
  final Map<String, TerritoryGeometry> territoryData;
  final Size canvasSize;

  const MapOverlayPainter({
    required this.gameState,
    required this.uiState,
    required this.territoryData,
    this.canvasSize = const Size(1200, 700),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / canvasSize.width;
    final scaleY = size.height / canvasSize.height;
    canvas.scale(scaleX, scaleY);

    for (final entry in territoryData.entries) {
      final name = entry.key;
      final geom = entry.value;
      final ts = gameState.territories[name];
      if (ts == null) continue;

      final path = geom.toPath();

      // Fill with owner color (semi-transparent to show base color underneath)
      canvas.drawPath(
        path,
        Paint()
          ..color = kPlayerColors[ts.owner % kPlayerColors.length]
              .withValues(alpha: 0.55)
          ..style = PaintingStyle.fill,
      );

      // Selected attacker: thick border
      if (name == uiState.selectedTerritory) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF000000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );
      }

      // Valid target highlight
      if (uiState.validTargets.contains(name)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
      }

      // Army count label
      final proposed = uiState.proposedPlacements[name] ?? 0;
      final tp = TextPainter(
        text: TextSpan(
          text: '${ts.armies}${proposed > 0 ? ' +$proposed' : ''}',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
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

    // Draw arrow from attacker to target
    if (uiState.selectedTerritory != null && uiState.selectedTarget != null) {
      final sourceGeom = territoryData[uiState.selectedTerritory];
      final targetGeom = territoryData[uiState.selectedTarget];
      if (sourceGeom != null && targetGeom != null) {
        _drawArrow(canvas, sourceGeom.labelOffset, targetGeom.labelOffset);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to) {
    final arrowPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final arrowHeadPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.fill;

    final direction = (to - from);
    final distance = direction.distance;
    if (distance < 1) return;
    final unit = direction / distance;
    final shortenedFrom = from + unit * 12;
    final shortenedTo = to - unit * 12;

    canvas.drawLine(shortenedFrom, shortenedTo, arrowPaint);

    const headLength = 12.0;
    const headAngle = 0.45;
    final angle = math.atan2(unit.dy, unit.dx);
    final p1 = shortenedTo -
        Offset(
          headLength * math.cos(angle - headAngle),
          headLength * math.sin(angle - headAngle),
        );
    final p2 = shortenedTo -
        Offset(
          headLength * math.cos(angle + headAngle),
          headLength * math.sin(angle + headAngle),
        );

    final arrowPath = Path()
      ..moveTo(shortenedTo.dx, shortenedTo.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(arrowPath, arrowHeadPaint);
  }

  @override
  bool shouldRepaint(MapOverlayPainter old) =>
      old.gameState != gameState || old.uiState != uiState;
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/widgets/map/map_overlay_painter.dart
git commit -m "feat: MapOverlayPainter fills polygon territories with player colors"
```

---

### Task 6: Update MapWidget to Use Dynamic Map Data

**Files:**
- Modify: `mobile/lib/widgets/map/map_widget.dart`

- [ ] **Step 1: Replace hardcoded kTerritoryData with loaded map data**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/models/cards.dart';
import '../../engine/models/game_config.dart';
import '../../engine/models/game_state.dart';
import '../../engine/map_graph.dart';
import '../../providers/game_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/ui_provider.dart';
import 'map_base_painter.dart';
import 'map_overlay_painter.dart';
import 'territory_data.dart';

class MapWidget extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final String mapAsset;
  const MapWidget({
    super.key,
    this.gameMode = GameMode.vsBot,
    this.mapAsset = 'original',
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(
    TapUpDetails details,
    GameState gameState,
    MapGraph mapGraph,
    Map<String, TerritoryGeometry> territoryData,
  ) {
    _selectTerritoryAt(
        details.localPosition, gameState, mapGraph, territoryData);
  }

  void _selectTerritoryAt(
    Offset svgPoint,
    GameState gameState,
    MapGraph mapGraph,
    Map<String, TerritoryGeometry> territoryData,
  ) {
    final hits = <String>[];

    for (final entry in territoryData.entries) {
      if (pointInPolygon(svgPoint, entry.value.polygon)) {
        hits.add(entry.key);
      }
    }

    if (hits.isEmpty) {
      ref.read(uIStateProvider.notifier).clearSelection();
      return;
    }

    if (hits.length == 1) {
      final territory = hits.first;

      if (widget.gameMode == GameMode.vsBot &&
          gameState.currentPlayerIndex == 0 &&
          gameState.turnPhase == TurnPhase.reinforce) {
        final ts = gameState.territories[territory];
        if (ts != null && ts.owner == 0) {
          ref.read(uIStateProvider.notifier).addProposedArmy(territory);
        }
        return;
      }

      final uiState = ref.read(uIStateProvider);
      final currentSelection = uiState.selectedTerritory;

      if (currentSelection == territory) {
        ref.read(uIStateProvider.notifier).clearSelection();
      } else if (currentSelection != null &&
          uiState.validTargets.contains(territory) &&
          (gameState.turnPhase == TurnPhase.attack ||
              gameState.turnPhase == TurnPhase.fortify)) {
        ref.read(uIStateProvider.notifier).selectTarget(territory);
      } else {
        ref
            .read(uIStateProvider.notifier)
            .selectTerritory(territory, gameState, mapGraph);
      }
    } else {
      _showDisambiguationDialog(hits, gameState, mapGraph);
    }
  }

  void _showDisambiguationDialog(
    List<String> territories,
    GameState gameState,
    MapGraph mapGraph,
  ) {
    showDialog<void>(
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
                  Navigator.pop(ctx);
                  ref
                      .read(uIStateProvider.notifier)
                      .selectTerritory(name, gameState, mapGraph);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameProvider);
    final mapAsync =
        ref.watch(loadedMapProvider(mapAsset: widget.mapAsset));

    return gameAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Map error: $e')),
      data: (gameState) {
        if (gameState == null) {
          return const Center(child: Text('No active game'));
        }
        return mapAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Map load error: $e')),
          data: (loadedMap) {
            final uiState = ref.watch(uIStateProvider);
            final cs = loadedMap.canvasSize;
            return InteractiveViewer(
              transformationController: _controller,
              minScale: 0.5,
              maxScale: 4.0,
              constrained: false,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTap(
                    details, gameState, loadedMap.graph, loadedMap.territoryData),
                child: SizedBox(
                  width: cs.width,
                  height: cs.height,
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: MapBasePainter(
                            territoryData: loadedMap.territoryData,
                            canvasSize: cs,
                          ),
                          size: cs,
                          isComplex: true,
                          willChange: false,
                        ),
                      ),
                      CustomPaint(
                        painter: MapOverlayPainter(
                          gameState: gameState,
                          uiState: uiState,
                          territoryData: loadedMap.territoryData,
                          canvasSize: cs,
                        ),
                        size: cs,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/widgets/map/map_widget.dart
git commit -m "feat: MapWidget uses dynamically loaded polygon map data"
```

---

### Task 7: Add Map Selection to GameConfig and HomeScreen

**Files:**
- Modify: `mobile/lib/engine/models/game_config.dart`
- Modify: `mobile/lib/screens/home_screen.dart`

- [ ] **Step 1: Add mapAsset to GameConfig**

```dart
/// Configuration for starting a new game. Plain Dart class — no freezed needed
/// because GameConfig is never stored or compared for equality; it's a one-shot
/// parameter to GameNotifier.setupGame().
enum GameMode { vsBot, simulation }

enum Difficulty { easy, medium, hard }

class GameConfig {
  final int playerCount;
  final Difficulty difficulty;
  final GameMode gameMode;
  final String mapAsset;

  const GameConfig({
    required this.playerCount,
    required this.difficulty,
    this.gameMode = GameMode.vsBot,
    this.mapAsset = 'original',
  });
}
```

- [ ] **Step 2: Add map dropdown to SetupForm in home_screen.dart**

Add a `_mapAsset` state field and a `DropdownButton` to the form. Import `kAvailableMaps` from `map_provider.dart`.

In `_SetupFormState`, add:

```dart
String _mapAsset = 'original';
```

Add this widget block after the game mode SegmentedButton and its SizedBox(height: 16):

```dart
// Map selection
const Text('Map'),
const SizedBox(height: 8),
DropdownButton<String>(
  value: _mapAsset,
  isExpanded: true,
  items: kAvailableMaps.entries
      .map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value),
          ))
      .toList(),
  onChanged: (v) {
    if (v != null) setState(() => _mapAsset = v);
  },
),
const SizedBox(height: 32),
```

Remove the existing `const SizedBox(height: 32)` before the Start Game button (it's replaced by the one after the dropdown).

Update the `onPressed` call to include `mapAsset`:

```dart
onPressed: () => widget.onStart(GameConfig(
  playerCount: _playerCount,
  difficulty: _difficulty,
  gameMode: _gameMode,
  mapAsset: _mapAsset,
)),
```

Add import at the top:

```dart
import '../providers/map_provider.dart';
```

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/engine/models/game_config.dart mobile/lib/screens/home_screen.dart
git commit -m "feat: add map selection dropdown to home screen"
```

---

### Task 8: Wire GameProvider and GameScreen to Use Selected Map

**Files:**
- Modify: `mobile/lib/providers/game_provider.dart`
- Modify: `mobile/lib/screens/game_screen.dart`

- [ ] **Step 1: Update game_provider.dart to use mapAsset**

In `setupGame`, change the mapGraph read to use the config's mapAsset:

```dart
final mapGraph = await ref.read(mapGraphProvider(mapAsset: config.mapAsset).future);
```

In `runBotTurn`, read mapAsset from the stored config:

```dart
final mapGraph = await ref.read(mapGraphProvider(mapAsset: _gameConfig?.mapAsset ?? 'original').future);
```

In `humanMove`, same change:

```dart
final mapGraph = await ref.read(mapGraphProvider(mapAsset: _gameConfig?.mapAsset ?? 'original').future);
```

- [ ] **Step 2: Update game_screen.dart to pass mapAsset to MapWidget**

Read `mobile/lib/screens/game_screen.dart` and wherever `MapWidget` is instantiated, add the `mapAsset` parameter. The GameScreen needs to receive the mapAsset. Add a `mapAsset` field:

```dart
class GameScreen extends StatelessWidget {
  final GameMode gameMode;
  final String mapAsset;
  const GameScreen({
    super.key,
    this.gameMode = GameMode.vsBot,
    this.mapAsset = 'original',
  });
```

Pass it to MapWidget:

```dart
MapWidget(gameMode: gameMode, mapAsset: mapAsset)
```

- [ ] **Step 3: Update HomeScreen navigation to pass mapAsset**

In `home_screen.dart`, the `Navigator.of(context).push` calls for GameScreen need to pass the mapAsset from config:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => GameScreen(
      gameMode: config.gameMode,
      mapAsset: config.mapAsset,
    ),
  ),
);
```

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/providers/game_provider.dart mobile/lib/screens/game_screen.dart mobile/lib/screens/home_screen.dart
git commit -m "feat: wire map selection through game provider and screens"
```

---

### Task 9: Remove classic.json and Fix Tests

**Files:**
- Delete: `mobile/assets/classic.json`
- Modify: test files that reference `kTerritoryData` or `mapGraphProvider`

- [ ] **Step 1: Delete classic.json**

```bash
rm mobile/assets/classic.json
```

- [ ] **Step 2: Fix test files**

Tests that override `mapGraphProvider` now need to use the family variant:

```dart
mapGraphProvider(mapAsset: 'original').overrideWith((ref, {mapAsset}) => Future.value(_testMapGraph))
```

Or better, since tests construct MapGraph directly, they can override `loadedMapProvider` or keep overriding `mapGraphProvider` with the family syntax.

Tests that reference `kTerritoryData` (the removed constant) need to either:
- Build territory data from a test map JSON, or
- Create test `TerritoryGeometry` instances with simple polygon paths

Update `map_widget_test.dart`: Replace `kTerritoryData` references with test fixtures that use polygon-based `TerritoryGeometry`.

Update `map_interaction_test.dart`: Replace rect-based hit testing with polygon-based `pointInPolygon`.

- [ ] **Step 3: Run tests and fix any remaining issues**

```bash
cd mobile && flutter test
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "fix: remove classic.json, update tests for polygon map format"
```

---

### Task 10: Run Codegen and Final Verification

- [ ] **Step 1: Run build_runner for all generated files**

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run all tests**

```bash
cd mobile && flutter test
```

- [ ] **Step 3: Run the app**

```bash
cd mobile && flutter run
```

Verify:
- Home screen shows map dropdown with "Classic (Original)"
- Starting a game renders polygon-based territories
- Tapping territories selects them correctly
- Game plays normally (attack, fortify, etc.)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: regenerate code, verify polygon map rendering"
```
