import 'package:risk_mobile/engine/fortify.dart';
import 'package:risk_mobile/engine/actions.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/models/game_state.dart';

import 'package:flutter_test/flutter_test.dart';

/// Build a minimal MapGraph: A-B-C connected chain; D is isolated.
/// All 4 territories in "TestContinent" with bonus 5.
MapGraph _makeTestGraph() {
  const mapData = MapData(
    name: 'test',
    territories: ['A', 'B', 'C', 'D'],
    continents: [
      ContinentData(
        name: 'TestContinent',
        territories: ['A', 'B', 'C', 'D'],
        bonus: 5,
      ),
    ],
    adjacencies: [
      ['A', 'B'],
      ['B', 'C'],
      // D is isolated (not adjacent to anyone)
    ],
  );
  return MapGraph(mapData);
}

/// Build a game state where player 0 owns A, B, C with varying armies.
GameState _makeState({
  int aArmies = 5,
  int bArmies = 3,
  int cArmies = 4,
  int? dOwner,
  int dArmies = 3,
}) {
  return GameState(
    territories: {
      'A': TerritoryState(owner: 0, armies: aArmies),
      'B': TerritoryState(owner: 0, armies: bArmies),
      'C': TerritoryState(owner: 0, armies: cArmies),
      'D': TerritoryState(owner: dOwner ?? 1, armies: dArmies),
    },
    players: [
      const PlayerState(index: 0, name: 'Alice'),
      const PlayerState(index: 1, name: 'Bob'),
    ],
  );
}

void main() {
  group('validateFortify', () {
    test('validateFortify: connected path allows move', () {
      final graph = _makeTestGraph();
      final state = _makeState();
      // A → C through B (all owned by player 0)
      final action = const FortifyAction(source: 'A', target: 'C', armies: 2);
      // Should not throw
      expect(() => validateFortify(state, graph, action, 0), returnsNormally);
    });

    test('validateFortify: disconnected path throws', () {
      final graph = _makeTestGraph();
      final state = _makeState();
      // D is isolated from A (and owned by player 1)
      // Even if we make D owned by player 0, it is not connected to A
      final stateWithD = GameState(
        territories: {
          'A': const TerritoryState(owner: 0, armies: 5),
          'B': const TerritoryState(owner: 1, armies: 3), // enemy blocks path
          'C': const TerritoryState(owner: 0, armies: 4),
          'D': const TerritoryState(owner: 0, armies: 3),
        },
        players: state.players,
      );
      // A cannot reach D because B (enemy) breaks the path
      final action = const FortifyAction(source: 'A', target: 'D', armies: 2);
      expect(
        () => validateFortify(stateWithD, graph, action, 0),
        throwsArgumentError,
      );
    });

    test('validateFortify: source not owned throws', () {
      final graph = _makeTestGraph();
      // D is owned by player 1
      final state = _makeState();
      final action = const FortifyAction(source: 'D', target: 'C', armies: 1);
      expect(
        () => validateFortify(state, graph, action, 0),
        throwsArgumentError,
      );
    });

    test('validateFortify: target not owned throws', () {
      final graph = _makeTestGraph();
      // D is owned by player 1
      final state = _makeState();
      final action = const FortifyAction(source: 'A', target: 'D', armies: 1);
      expect(
        () => validateFortify(state, graph, action, 0),
        throwsArgumentError,
      );
    });

    test('validateFortify: moving all armies (leaving 0) throws', () {
      final graph = _makeTestGraph();
      final state = _makeState(aArmies: 3);
      // Trying to move 3 armies from A (which has 3) — must leave at least 1
      final action = const FortifyAction(source: 'A', target: 'B', armies: 3);
      expect(
        () => validateFortify(state, graph, action, 0),
        throwsArgumentError,
      );
    });
  });

  group('executeFortify', () {
    test('executeFortify: armies deducted from source, added to target', () {
      final graph = _makeTestGraph();
      final state = _makeState(aArmies: 5, bArmies: 3);
      final action = const FortifyAction(source: 'A', target: 'B', armies: 2);
      final newState = executeFortify(state, graph, action, 0);
      expect(newState.territories['A']!.armies, 3);
      expect(newState.territories['B']!.armies, 5);
    });

    test('executeFortify: source army count = original - moved', () {
      final graph = _makeTestGraph();
      final state = _makeState(aArmies: 8, cArmies: 1);
      // A → C through B (all player 0)
      final action = const FortifyAction(source: 'A', target: 'C', armies: 4);
      final newState = executeFortify(state, graph, action, 0);
      expect(newState.territories['A']!.armies, 4); // 8 - 4
    });

    test('executeFortify: target army count = original + moved', () {
      final graph = _makeTestGraph();
      final state = _makeState(aArmies: 8, cArmies: 1);
      final action = const FortifyAction(source: 'A', target: 'C', armies: 4);
      final newState = executeFortify(state, graph, action, 0);
      expect(newState.territories['C']!.armies, 5); // 1 + 4
    });
  });
}
