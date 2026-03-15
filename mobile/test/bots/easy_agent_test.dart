// ignore_for_file: unused_import
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/actions.dart';
import 'package:risk_mobile/bots/easy_agent.dart';

import '../helpers/fake_random.dart';

/// Minimal 6-territory map for EasyAgent tests.
/// T1-T2-T3 in continent A, T4-T5-T6 in continent B.
/// Adjacencies: T1-T2, T2-T3, T3-T4, T4-T5, T5-T6
const String _mapJson = '''
{
  "name": "Test",
  "territories": ["T1", "T2", "T3", "T4", "T5", "T6"],
  "continents": [
    {"name": "A", "bonus": 2, "territories": ["T1", "T2", "T3"]},
    {"name": "B", "bonus": 2, "territories": ["T4", "T5", "T6"]}
  ],
  "adjacencies": [
    ["T1", "T2"], ["T2", "T3"], ["T3", "T4"], ["T4", "T5"], ["T5", "T6"]
  ]
}
''';

MapGraph get _testMap =>
    MapGraph(MapData.fromJson(jsonDecode(_mapJson) as Map<String, dynamic>));

/// Build a GameState where player 0 owns territories with given armies,
/// and player 1 owns the remaining territories (with 1 army each).
GameState _buildState({
  required Map<String, int> player0Territories,
  required List<String> player1Territories,
  int currentPlayer = 0,
  Map<String, List<Card>>? cards,
}) {
  final territories = <String, TerritoryState>{};
  for (final entry in player0Territories.entries) {
    territories[entry.key] = TerritoryState(owner: 0, armies: entry.value);
  }
  for (final t in player1Territories) {
    territories[t] = TerritoryState(owner: 1, armies: 1);
  }
  final players = [
    const PlayerState(index: 0, name: 'Player 1'),
    const PlayerState(index: 1, name: 'Player 2'),
  ];
  return GameState(
    territories: territories,
    players: players,
    currentPlayerIndex: currentPlayer,
    cards: cards ?? {'0': [], '1': []},
  );
}

void main() {
  group('EasyAgent.chooseReinforcementPlacement', () {
    test('places all armies on owned territories', () {
      final mapGraph = _testMap;
      // Use FakeRandom with values [1,2,3] (nextInt returns 0,1,2)
      // nextInt(3) selects from [T1,T2,T3] — deterministic placement
      final rng = FakeRandom([1, 2, 1, 3, 1]);
      final agent = EasyAgent(mapGraph: mapGraph, rng: rng);

      final state = _buildState(
        player0Territories: {'T1': 3, 'T2': 2, 'T3': 2},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      final action = agent.chooseReinforcementPlacement(state, 4);

      // All placed territories must be owned by player 0
      for (final key in action.placements.keys) {
        expect(state.territories[key]!.owner, equals(0),
            reason: '$key must be owned by player 0');
      }

      // Sum must equal 4
      final total = action.placements.values.fold(0, (a, b) => a + b);
      expect(total, equals(4));
    });

    test('distributes armies one-at-a-time to owned territories', () {
      final mapGraph = _testMap;
      // FakeRandom with 5 values: each nextInt(2) picks from [T1, T2]
      final rng = FakeRandom([1, 2, 1, 2, 1]);
      final agent = EasyAgent(mapGraph: mapGraph, rng: rng);

      final state = _buildState(
        player0Territories: {'T1': 1, 'T2': 1},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );

      final action = agent.chooseReinforcementPlacement(state, 3);
      final total = action.placements.values.fold(0, (a, b) => a + b);
      expect(total, equals(3));

      // Only T1 and T2 may appear
      for (final key in action.placements.keys) {
        expect(['T1', 'T2'].contains(key), isTrue,
            reason: 'Only owned territories should be placed on');
      }
    });

    test('places all armies on single owned territory when player owns one', () {
      final mapGraph = _testMap;
      final rng = FakeRandom([1, 1, 1, 1, 1]);
      final agent = EasyAgent(mapGraph: mapGraph, rng: rng);

      final state = _buildState(
        player0Territories: {'T1': 2},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );

      final action = agent.chooseReinforcementPlacement(state, 5);
      expect(action.placements['T1'], equals(5));
    });
  });

  group('EasyAgent.chooseAttack', () {
    test('returns null when player has no territories with armies >= 2', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1, 1]));

      final state = _buildState(
        player0Territories: {'T1': 1, 'T2': 1},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );

      expect(agent.chooseAttack(state), isNull);
    });

    test('returns null when all neighbors are friendly', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1, 1]));

      // Player 0 owns T1, T2, T3 (all connected), player 1 owns T4, T5, T6
      // But T3-T4 is the only cross-continent edge; let's set T3 to 1 army
      // so player 0 has no attack options
      final state = _buildState(
        player0Territories: {'T1': 3, 'T2': 3, 'T3': 1},
        player1Territories: ['T4', 'T5', 'T6'],
        // T3 borders T4 (enemy), but T3 only has 1 army — cannot attack
        // T1 and T2 border only friendly territories
      );

      // T3 has 1 army so can't attack; T1 neighbors only T2 (friendly); T2 neighbors T1,T3 (both friendly)
      expect(agent.chooseAttack(state), isNull);
    });

    test('returns valid AttackAction: source owner == player, armies >= 2, target is enemy neighbor', () {
      final mapGraph = _testMap;
      // FakeRandom: shuffle uses nextInt, then pick attack
      // Values [1,1,1,1] — adequate for shuffle of small list + stop check
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1, 1, 1, 1, 1, 1, 1, 1]));

      // Player 0 owns T1 (5 armies) and T2 (1 army); player 1 owns T3..T6
      // T1 borders T2 (friendly), T2 borders T1, T3 — T1 can't attack (only T2 neighbor is friendly)
      // Give T2 enough armies
      final state = _buildState(
        player0Territories: {'T1': 1, 'T2': 5},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );

      final action = agent.chooseAttack(state);
      // Should attack: T2 (5 armies) -> T3 (enemy)
      expect(action, isNotNull);
      if (action is AttackAction) {
        expect(state.territories[action.source]!.owner, equals(0));
        expect(state.territories[action.source]!.armies, greaterThanOrEqualTo(2));
        expect(mapGraph.neighbors(action.source).contains(action.target), isTrue);
        expect(state.territories[action.target]!.owner, isNot(equals(0)));
        expect(action.numDice, equals(3)); // min(3, 5-1) = 3
      } else {
        fail('Expected AttackAction, got $action');
      }
    });

    test('numDice is capped at 3 and at most source.armies - 1', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1, 1, 1, 1, 1, 1]));

      // T2 has 2 armies — only 1 die
      final state = _buildState(
        player0Territories: {'T1': 1, 'T2': 2},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );

      final action = agent.chooseAttack(state);
      if (action is AttackAction) {
        expect(action.numDice, equals(1)); // min(3, 2-1) = 1
      } else {
        fail('Expected AttackAction');
      }
    });
  });

  group('EasyAgent.chooseFortify', () {
    test('returns null when no source has armies >= 2', () {
      final mapGraph = _testMap;
      // nextInt(2) == 0 triggers fortify attempt; but no sources available
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1, 1, 1]));

      final state = _buildState(
        player0Territories: {'T1': 1, 'T2': 1, 'T3': 1},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      // nextInt(2) with value 1 returns 0 (1-1), which == 0 => fortify attempt
      // But all player 0 territories have 1 army, so returns null
      expect(agent.chooseFortify(state), isNull);
    });

    test('returns null 50% of the time when nextInt(2) == 1', () {
      final mapGraph = _testMap;
      // FakeRandom([2,...]) -> nextInt(2) = 2-1 = 1, so skip fortify
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([2, 2, 2]));

      final state = _buildState(
        player0Territories: {'T1': 5, 'T2': 1, 'T3': 1},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      expect(agent.chooseFortify(state), isNull);
    });

    test('returns valid FortifyAction when conditions are met', () {
      final mapGraph = _testMap;
      // nextInt(2) = 0 (value=1) => do fortify
      // nextInt(2) = 0 => picks T1 as source (index 0 of [T1] sorted)
      // nextInt(1) = 0 => picks T2 as target (index 0 of reachable set)
      // nextInt(4) = 0 => armies = 1
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1, 1, 1, 1, 1]));

      final state = _buildState(
        player0Territories: {'T1': 5, 'T2': 2, 'T3': 2},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      final action = agent.chooseFortify(state);
      expect(action, isNotNull);
      if (action is FortifyAction) {
        // Source must be owned by player 0
        expect(state.territories[action.source]!.owner, equals(0));
        // Source must have >= 2 armies
        expect(state.territories[action.source]!.armies, greaterThanOrEqualTo(2));
        // Target must be different from source
        expect(action.target, isNot(equals(action.source)));
        // Target must be owned by player 0
        expect(state.territories[action.target]!.owner, equals(0));
        // Armies must be >= 1 and <= source.armies - 1
        expect(action.armies, greaterThanOrEqualTo(1));
        expect(action.armies, lessThanOrEqualTo(state.territories[action.source]!.armies - 1));
      } else {
        fail('Expected FortifyAction, got $action');
      }
    });

    test('target is reachable through friendly territory (connectedTerritories)', () {
      final mapGraph = _testMap;
      // Player 0 owns T1, T2, T3 which are connected: T1-T2-T3
      // Player 1 owns T4, T5, T6
      // T3 borders T4 (enemy) — not reachable for fortify
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1, 1, 1, 1, 1, 1, 1]));

      final state = _buildState(
        player0Territories: {'T1': 5, 'T2': 2, 'T3': 2},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      final action = agent.chooseFortify(state);
      if (action != null) {
        final ownedSet = state.territories.entries
            .where((e) => e.value.owner == 0)
            .map((e) => e.key)
            .toSet();
        final reachable = mapGraph.connectedTerritories(action.source, ownedSet);
        expect(reachable.contains(action.target), isTrue,
            reason: 'Target must be reachable through friendly territory');
      }
    });
  });

  group('EasyAgent.chooseCardTrade', () {
    test('returns null when hand has fewer than 3 cards', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1]));

      final state = _buildState(
        player0Territories: {'T1': 3},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );

      const card1 = Card(territory: 'T1', cardType: CardType.infantry);
      const card2 = Card(territory: 'T2', cardType: CardType.cavalry);

      expect(agent.chooseCardTrade(state, [card1, card2], forced: false), isNull);
      expect(agent.chooseCardTrade(state, [], forced: false), isNull);
      expect(agent.chooseCardTrade(state, [card1], forced: true), isNull);
    });

    test('returns first valid TradeCardsAction when valid set exists', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1]));

      final state = _buildState(
        player0Territories: {'T1': 3},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );

      // One of each type = valid set
      const infantry = Card(territory: 'T1', cardType: CardType.infantry);
      const cavalry = Card(territory: 'T2', cardType: CardType.cavalry);
      const artillery = Card(territory: 'T3', cardType: CardType.artillery);

      final action = agent.chooseCardTrade(state, [infantry, cavalry, artillery], forced: false);
      expect(action, isNotNull);
      expect(action!.cards.length, equals(3));
    });

    test('returns null when no valid set exists in hand', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1]));

      final state = _buildState(
        player0Territories: {'T1': 3},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );

      // Two infantry + one cavalry = NOT a valid set (not 3-of-same, not one-each)
      const inf1 = Card(territory: 'T1', cardType: CardType.infantry);
      const inf2 = Card(territory: 'T2', cardType: CardType.infantry);
      const cav = Card(territory: 'T3', cardType: CardType.cavalry);

      final action = agent.chooseCardTrade(state, [inf1, inf2, cav], forced: false);
      expect(action, isNull);
    });

    test('returns valid set when hand has 3 matching cards', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1]));

      final state = _buildState(
        player0Territories: {'T1': 3},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );

      const inf1 = Card(territory: 'T1', cardType: CardType.infantry);
      const inf2 = Card(territory: 'T2', cardType: CardType.infantry);
      const inf3 = Card(territory: 'T3', cardType: CardType.infantry);

      final action = agent.chooseCardTrade(state, [inf1, inf2, inf3], forced: false);
      expect(action, isNotNull);
    });
  });

  group('EasyAgent.chooseAdvanceArmies', () {
    test('always returns minimum (conservative advance)', () {
      final mapGraph = _testMap;
      final agent = EasyAgent(mapGraph: mapGraph, rng: FakeRandom([1]));

      final state = _buildState(
        player0Territories: {'T1': 5, 'T2': 3},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );

      expect(agent.chooseAdvanceArmies(state, 'T1', 'T2', 1, 4), equals(1));
      expect(agent.chooseAdvanceArmies(state, 'T1', 'T2', 3, 4), equals(3));
      expect(agent.chooseAdvanceArmies(state, 'T1', 'T2', 2, 2), equals(2));
    });
  });
}
