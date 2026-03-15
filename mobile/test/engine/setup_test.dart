import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/setup.dart';

// Embed a small subset of classic Risk map for testing (still has 42 territories)
// We use a minimal 6-territory map for speed, but verify the real logic
const String _minimalMapJson = '''
{
  "name": "Test",
  "territories": [
    "T1", "T2", "T3", "T4", "T5", "T6"
  ],
  "continents": [
    {"name": "C1", "bonus": 1, "territories": ["T1", "T2", "T3"]},
    {"name": "C2", "bonus": 1, "territories": ["T4", "T5", "T6"]}
  ],
  "adjacencies": [
    ["T1", "T2"], ["T2", "T3"], ["T4", "T5"], ["T5", "T6"]
  ]
}
''';

MapGraph get _testMap =>
    MapGraph(MapData.fromJson(jsonDecode(_minimalMapJson) as Map<String, dynamic>));

void main() {
  group('startingArmies', () {
    test(
      'startingArmies: 2 players = 40, 3 players = 35, ..., 6 players = 20',
      () {
        expect(startingArmies[2], equals(40));
        expect(startingArmies[3], equals(35));
        expect(startingArmies[4], equals(30));
        expect(startingArmies[5], equals(25));
        expect(startingArmies[6], equals(20));
      },
    );
  });

  group('setupGame', () {
    test(
      'setupGame: all territories owned, 0 unowned',
      () {
        final mapGraph = _testMap;
        final state = setupGame(mapGraph, 2, rng: Random(1));
        final territories = mapGraph.allTerritories;

        for (final t in territories) {
          expect(state.territories.containsKey(t), isTrue,
              reason: 'Territory $t should be in game state');
          expect(state.territories[t]!.armies, greaterThanOrEqualTo(1),
              reason: 'Territory $t should have at least 1 army');
        }
        expect(state.territories.length, equals(territories.length));
      },
    );

    test(
      'setupGame: player count determines army distribution total',
      () {
        final mapGraph = _testMap;
        // With 2 players: each gets startingArmies[2] = 40 armies total
        // But our test map only has 6 territories, so total armies = 2 * 40 = 80
        // However we have only 6 territories to distribute
        // Each player gets 3 territories + 37 extra = 40 per player
        // total armies on map = 80
        final state = setupGame(mapGraph, 2, rng: Random(1));
        int totalArmies = 0;
        for (final ts in state.territories.values) {
          totalArmies += ts.armies;
        }
        expect(totalArmies, equals(startingArmies[2]! * 2));

        final state3 = setupGame(mapGraph, 3, rng: Random(1));
        int totalArmies3 = 0;
        for (final ts in state3.territories.values) {
          totalArmies3 += ts.armies;
        }
        expect(totalArmies3, equals(startingArmies[3]! * 3));
      },
    );

    test(
      'setupGame: invalid player count < 2 throws',
      () {
        final mapGraph = _testMap;
        expect(
          () => setupGame(mapGraph, 1),
          throwsArgumentError,
        );
      },
    );

    test(
      'setupGame: invalid player count > 6 throws',
      () {
        final mapGraph = _testMap;
        expect(
          () => setupGame(mapGraph, 7),
          throwsArgumentError,
        );
      },
    );
  });
}
