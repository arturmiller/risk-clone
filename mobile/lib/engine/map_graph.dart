import 'dart:collection';
import 'models/map_schema.dart';

/// Pure-Dart port of risk/engine/map_graph.py (NetworkX replaced with BFS).
/// Zero Flutter imports — runs in isolates and pure-Dart tests.
class MapGraph {
  final Map<String, Set<String>> _adjacency = {};
  final Map<String, String> _continentByTerritory = {};
  final Map<String, Set<String>> _continentTerritories = {};
  final Map<String, int> _continentBonuses = {};

  MapGraph(MapData mapData) {
    // Initialize adjacency set for every territory
    for (final t in mapData.territories) {
      _adjacency[t] = {};
    }
    // Add bidirectional edges from adjacency pairs
    for (final edge in mapData.adjacencies) {
      _adjacency[edge[0]]!.add(edge[1]);
      _adjacency[edge[1]]!.add(edge[0]);
    }
    // Build continent lookups
    for (final continent in mapData.continents) {
      _continentTerritories[continent.name] = Set.from(continent.territories);
      _continentBonuses[continent.name] = continent.bonus;
      for (final t in continent.territories) {
        _continentByTerritory[t] = continent.name;
      }
    }
  }

  List<String> get allTerritories => _adjacency.keys.toList();

  bool areAdjacent(String t1, String t2) =>
      _adjacency[t1]?.contains(t2) ?? false;

  List<String> neighbors(String territory) =>
      _adjacency[territory]?.toList() ?? [];

  /// BFS over friendly-only subgraph. Direct port of NetworkX connected_component.
  Set<String> connectedTerritories(String start, Set<String> friendly) {
    if (!friendly.contains(start)) return {};
    final visited = <String>{start};
    final queue = Queue<String>()..add(start);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final neighbor in _adjacency[current] ?? <String>{}) {
        if (friendly.contains(neighbor) && !visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
    return visited;
  }

  Set<String> continentTerritories(String continent) =>
      _continentTerritories[continent] ?? {};

  bool controlsContinent(String continent, Set<String> playerTerritories) =>
      (_continentTerritories[continent] ?? {})
          .every(playerTerritories.contains);

  int continentBonus(String continent) => _continentBonuses[continent] ?? 0;

  String? continentOf(String territory) => _continentByTerritory[territory];

  List<String> get continentNames => _continentBonuses.keys.toList();
}
