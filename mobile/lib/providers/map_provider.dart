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
