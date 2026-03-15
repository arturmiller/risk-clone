import 'package:risk_mobile/engine/reinforcements.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/models/game_state.dart';

import 'package:flutter_test/flutter_test.dart';

/// Build a minimal MapGraph with 3 territories in "TestContinent" with bonus 5.
/// Territories: A, B, C — all connected in a chain A-B-C.
MapGraph _makeTestGraph() {
  const mapData = MapData(
    name: 'test',
    territories: ['A', 'B', 'C'],
    continents: [
      ContinentData(
        name: 'TestContinent',
        territories: ['A', 'B', 'C'],
        bonus: 5,
      ),
    ],
    adjacencies: [
      ['A', 'B'],
      ['B', 'C'],
    ],
  );
  return MapGraph(mapData);
}

/// Build a larger MapGraph with two continents for continent bonus tests.
/// NorthAmerica: A, B, C, D (bonus 5), SouthAmerica: E, F (bonus 2)
MapGraph _makeTwoContGraph() {
  const mapData = MapData(
    name: 'two-cont',
    territories: ['A', 'B', 'C', 'D', 'E', 'F'],
    continents: [
      ContinentData(
        name: 'NorthAmerica',
        territories: ['A', 'B', 'C', 'D'],
        bonus: 5,
      ),
      ContinentData(
        name: 'SouthAmerica',
        territories: ['E', 'F'],
        bonus: 2,
      ),
    ],
    adjacencies: [
      ['A', 'B'],
      ['B', 'C'],
      ['C', 'D'],
      ['D', 'E'],
      ['E', 'F'],
    ],
  );
  return MapGraph(mapData);
}

/// Build a GameState with territories T0..T(n-1) all owned by player 0.
GameState _makeStateWithTerritories(int count) {
  final territories = <String, TerritoryState>{};
  for (int i = 0; i < count; i++) {
    territories['T$i'] = const TerritoryState(owner: 0, armies: 3);
  }
  return GameState(
    territories: territories,
    players: [
      const PlayerState(index: 0, name: 'Alice'),
      const PlayerState(index: 1, name: 'Bob'),
    ],
  );
}

void main() {
  group('calculateReinforcements', () {
    test('calculateReinforcements: 9 territories → base 3 (minimum)', () {
      // 9 ~/ 3 = 3; max(3,3) = 3
      final graph = _makeTestGraph();
      final state = _makeStateWithTerritories(9);
      expect(calculateReinforcements(state, graph, 0), 3);
    });

    test('calculateReinforcements: 12 territories → base 4', () {
      // 12 ~/ 3 = 4; max(4,3) = 4
      final graph = _makeTestGraph();
      final state = _makeStateWithTerritories(12);
      expect(calculateReinforcements(state, graph, 0), 4);
    });

    test('calculateReinforcements: 11 territories → base 3 (floor division)',
        () {
      // 11 ~/ 3 = 3 (floor, not 3.66); max(3,3) = 3
      final graph = _makeTestGraph();
      final state = _makeStateWithTerritories(11);
      expect(calculateReinforcements(state, graph, 0), 3);
    });

    test(
        'calculateReinforcements: continent bonus added when player controls continent',
        () {
      // Player 0 owns A, B, C (TestContinent bonus 5) → 3 territories = base 3 + bonus 5 = 8
      final graph = _makeTestGraph();
      final state = GameState(
        territories: {
          'A': const TerritoryState(owner: 0, armies: 3),
          'B': const TerritoryState(owner: 0, armies: 3),
          'C': const TerritoryState(owner: 0, armies: 3),
        },
        players: [
          const PlayerState(index: 0, name: 'Alice'),
          const PlayerState(index: 1, name: 'Bob'),
        ],
      );
      // 3 territories ~/ 3 = 1, max(1,3) = 3; + 5 continent = 8
      expect(calculateReinforcements(state, graph, 0), 8);
    });

    test(
        'calculateReinforcements: no continent bonus when continent partially owned',
        () {
      // Player 0 owns A, B; player 1 owns C → no continent bonus
      final graph = _makeTestGraph();
      final state = GameState(
        territories: {
          'A': const TerritoryState(owner: 0, armies: 3),
          'B': const TerritoryState(owner: 0, armies: 3),
          'C': const TerritoryState(owner: 1, armies: 3),
        },
        players: [
          const PlayerState(index: 0, name: 'Alice'),
          const PlayerState(index: 1, name: 'Bob'),
        ],
      );
      // 2 territories ~/ 3 = 0, max(0,3) = 3; no continent bonus = 3
      expect(calculateReinforcements(state, graph, 0), 3);
    });
  });
}
