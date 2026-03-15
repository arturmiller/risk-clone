import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/actions.dart';
import 'package:risk_mobile/engine/combat.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'dart:convert';

import '../helpers/fake_random.dart';

// Minimal 2-territory map for combat tests
const String _minimalMapJson = '''
{
  "name": "Test",
  "territories": ["Alaska", "Alberta", "Brazil"],
  "continents": [
    {"name": "NA", "bonus": 1, "territories": ["Alaska", "Alberta"]},
    {"name": "SA", "bonus": 1, "territories": ["Brazil"]}
  ],
  "adjacencies": [
    ["Alaska", "Alberta"]
  ]
}
''';

MapGraph get _testMap =>
    MapGraph(MapData.fromJson(jsonDecode(_minimalMapJson) as Map<String, dynamic>));

GameState _makeState({
  required String sourceTerritory,
  required int sourceOwner,
  required int sourceArmies,
  required String targetTerritory,
  required int targetOwner,
  required int targetArmies,
}) {
  return GameState(
    territories: {
      sourceTerritory: TerritoryState(owner: sourceOwner, armies: sourceArmies),
      targetTerritory: TerritoryState(owner: targetOwner, armies: targetArmies),
      'Brazil': TerritoryState(owner: 1, armies: 1),
    },
    players: [
      PlayerState(index: 0, name: 'Player 1'),
      PlayerState(index: 1, name: 'Player 2'),
    ],
  );
}

void main() {
  group('resolveCombat', () {
    test(
      'resolveCombat 3v2: attacker rolls [6,5,4] defender [3,2] → attacker_losses=0, defender_losses=2',
      () {
        // FakeRandom provides die faces in order: attacker [6,5,4], defender [3,2]
        final rng = FakeRandom([6, 5, 4, 3, 2]);
        final result = resolveCombat(3, 2, rng);
        expect(result.attackerLosses, equals(0));
        expect(result.defenderLosses, equals(2));
      },
    );

    test(
      'resolveCombat tie goes to defender: [4] vs [4] → attacker_losses=1, defender_losses=0',
      () {
        final rng = FakeRandom([4, 4]);
        final result = resolveCombat(1, 1, rng);
        expect(result.attackerLosses, equals(1));
        expect(result.defenderLosses, equals(0));
      },
    );

    test(
      'resolveCombat 1v1: [6] vs [5] → attacker_losses=0, defender_losses=1',
      () {
        final rng = FakeRandom([6, 5]);
        final result = resolveCombat(1, 1, rng);
        expect(result.attackerLosses, equals(0));
        expect(result.defenderLosses, equals(1));
      },
    );

    test(
      'resolveCombat 1v2: attacker [4] defender [5,3] → attacker_losses=1, defender_losses=0',
      () {
        // 1v2: only 1 pair compared (min of 1, 2 = 1)
        // attacker [4], defender [5,3] sorted desc → [5,3]
        // pair: 4 vs 5 → attacker loses
        final rng = FakeRandom([4, 5, 3]);
        final result = resolveCombat(1, 2, rng);
        expect(result.attackerLosses, equals(1));
        expect(result.defenderLosses, equals(0));
      },
    );
  });

  group('executeAttack', () {
    test(
      'executeAttack reduces territory armies correctly',
      () {
        final mapGraph = _testMap;
        final state = _makeState(
          sourceTerritory: 'Alaska',
          sourceOwner: 0,
          sourceArmies: 5,
          targetTerritory: 'Alberta',
          targetOwner: 1,
          targetArmies: 3,
        );
        // 2 attacker dice + 2 defender dice (min(2,3)=2)
        // Attacker [3,2] sorted desc, defender [1,1] sorted desc
        // Pair 1: 3 vs 1 → defender loses; Pair 2: 2 vs 1 → defender loses
        final rng = FakeRandom([3, 2, 1, 1]);
        final action =
            AttackAction(source: 'Alaska', target: 'Alberta', numDice: 2);
        final (newState, result, conquered) =
            executeAttack(state, mapGraph, action, 0, rng);

        expect(result.defenderLosses, equals(2));
        expect(result.attackerLosses, equals(0));
        expect(newState.territories['Alaska']!.armies, equals(5));
        expect(newState.territories['Alberta']!.armies, equals(1));
        expect(conquered, isFalse);
      },
    );

    test(
      'executeAttack conquers territory and sets owner',
      () {
        final mapGraph = _testMap;
        final state = _makeState(
          sourceTerritory: 'Alaska',
          sourceOwner: 0,
          sourceArmies: 5,
          targetTerritory: 'Alberta',
          targetOwner: 1,
          targetArmies: 1,
        );
        // Attacker [6] defender [1] → defender loses 1 → conquered
        final rng = FakeRandom([6, 1]);
        final action =
            AttackAction(source: 'Alaska', target: 'Alberta', numDice: 1);
        final (newState, result, conquered) =
            executeAttack(state, mapGraph, action, 0, rng);

        expect(conquered, isTrue);
        expect(newState.territories['Alberta']!.owner, equals(0));
        expect(newState.territories['Alberta']!.armies, equals(1)); // numDice moved
        expect(newState.territories['Alaska']!.armies, equals(4)); // 5 - 1 moved
        expect(newState.conqueredThisTurn, isTrue);
      },
    );

    test(
      'executeAttack validates: source not owned throws',
      () {
        final mapGraph = _testMap;
        final state = _makeState(
          sourceTerritory: 'Alaska',
          sourceOwner: 1, // owned by player 1, not 0
          sourceArmies: 5,
          targetTerritory: 'Alberta',
          targetOwner: 0,
          targetArmies: 2,
        );
        final action =
            AttackAction(source: 'Alaska', target: 'Alberta', numDice: 1);
        expect(
          () => executeAttack(state, mapGraph, action, 0, Random()),
          throwsArgumentError,
        );
      },
    );

    test(
      'executeAttack validates: attacking own territory throws',
      () {
        final mapGraph = _testMap;
        final state = _makeState(
          sourceTerritory: 'Alaska',
          sourceOwner: 0,
          sourceArmies: 5,
          targetTerritory: 'Alberta',
          targetOwner: 0, // same owner
          targetArmies: 2,
        );
        final action =
            AttackAction(source: 'Alaska', target: 'Alberta', numDice: 1);
        expect(
          () => executeAttack(state, mapGraph, action, 0, Random()),
          throwsArgumentError,
        );
      },
    );

    test(
      'executeAttack validates: non-adjacent territories throw',
      () {
        final mapGraph = _testMap;
        // Alaska and Brazil are not adjacent in test map
        final state = GameState(
          territories: {
            'Alaska': TerritoryState(owner: 0, armies: 5),
            'Alberta': TerritoryState(owner: 1, armies: 2),
            'Brazil': TerritoryState(owner: 1, armies: 2),
          },
          players: [
            PlayerState(index: 0, name: 'Player 1'),
            PlayerState(index: 1, name: 'Player 2'),
          ],
        );
        final action =
            AttackAction(source: 'Alaska', target: 'Brazil', numDice: 1);
        expect(
          () => executeAttack(state, mapGraph, action, 0, Random()),
          throwsArgumentError,
        );
      },
    );
  });

  group('executeBlitz', () {
    test(
      'executeBlitz loops until conquest',
      () {
        final mapGraph = _testMap;
        final state = _makeState(
          sourceTerritory: 'Alaska',
          sourceOwner: 0,
          sourceArmies: 10,
          targetTerritory: 'Alberta',
          targetOwner: 1,
          targetArmies: 2,
        );
        // Always roll 6 for attacker, 1 for defender → attacker always wins
        // Round 1: 3v2, attacker [6,6,6] defender [1,1] → 2 def losses → target 0 → conquered
        final rng = FakeRandom([6, 6, 6, 1, 1]);
        final action = BlitzAction(source: 'Alaska', target: 'Alberta');
        final (newState, results, conquered) =
            executeBlitz(state, mapGraph, action, 0, rng);

        expect(conquered, isTrue);
        expect(newState.territories['Alberta']!.owner, equals(0));
        expect(results, isNotEmpty);
      },
    );

    test(
      'executeBlitz stops when attacker reduced to 1 army',
      () {
        final mapGraph = _testMap;
        final state = _makeState(
          sourceTerritory: 'Alaska',
          sourceOwner: 0,
          sourceArmies: 2, // only 1 attacker die (min(3, 2-1)=1)
          targetTerritory: 'Alberta',
          targetOwner: 1,
          targetArmies: 10,
        );
        // 1 attacker die + 2 defender dice (min(2,10)=2) = 3 values
        // Attacker [1], defender [6,6] → attacker loses 1 → Alaska goes from 2 to 1 → stops
        final rng = FakeRandom([1, 6, 6]);
        final action = BlitzAction(source: 'Alaska', target: 'Alberta');
        final (newState, results, conquered) =
            executeBlitz(state, mapGraph, action, 0, rng);

        expect(conquered, isFalse);
        expect(newState.territories['Alaska']!.armies, equals(1));
        expect(results.length, equals(1));
      },
    );

    test(
      'executeBlitz conquest leaves minimum legal army (attacker >= 1)',
      () {
        final mapGraph = _testMap;
        final state = _makeState(
          sourceTerritory: 'Alaska',
          sourceOwner: 0,
          sourceArmies: 4,
          targetTerritory: 'Alberta',
          targetOwner: 1,
          targetArmies: 1,
        );
        // Attacker rolls 6, defender rolls 1 → conquered in first round
        // numDice=3, armiesToMove=3, source: 4 - 3 = 1
        final rng = FakeRandom([6, 6, 6, 1]);
        final action = BlitzAction(source: 'Alaska', target: 'Alberta');
        final (newState, results, conquered) =
            executeBlitz(state, mapGraph, action, 0, rng);

        expect(conquered, isTrue);
        expect(newState.territories['Alaska']!.armies, greaterThanOrEqualTo(1));
        expect(newState.territories['Alberta']!.armies, greaterThanOrEqualTo(1));
      },
    );
  });

  group('statistical', () {
    test(
      'statistical: 3v2 attacker-wins-both within 0.5% of 37.17% over 10000 trials',
      () {
        // Use 100000 trials for stable statistics (seed 42, within 0.5% tolerance)
        final rng = Random(42);
        int attackerWinsBoth = 0;
        const trials = 100000;

        for (int i = 0; i < trials; i++) {
          final result = resolveCombat(3, 2, rng);
          if (result.attackerLosses == 0 && result.defenderLosses == 2) {
            attackerWinsBoth++;
          }
        }

        final rate = attackerWinsBoth / trials;
        expect(rate, closeTo(0.3717, 0.005));
      },
    );

    test(
      'statistical: 3v2 defender-wins-both within 0.5% of 29.26% over 10000 trials',
      () {
        // Use 100000 trials for stable statistics (seed 42, within 0.5% tolerance)
        final rng = Random(42);
        int defenderWinsBoth = 0;
        const trials = 100000;

        for (int i = 0; i < trials; i++) {
          final result = resolveCombat(3, 2, rng);
          if (result.attackerLosses == 2 && result.defenderLosses == 0) {
            defenderWinsBoth++;
          }
        }

        final rate = defenderWinsBoth / trials;
        expect(rate, closeTo(0.2926, 0.005));
      },
    );
  });
}
