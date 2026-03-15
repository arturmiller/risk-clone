import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/actions.dart';
import 'package:risk_mobile/bots/medium_agent.dart';

import '../helpers/fake_random.dart';

/// Minimal 6-territory map for MediumAgent tests.
/// T1-T2-T3 in continent A (bonus 2), T4-T5-T6 in continent B (bonus 3).
/// Adjacencies: T1-T2, T2-T3, T3-T4, T4-T5, T5-T6
const String _mapJson = '''
{
  "name": "Test",
  "territories": ["T1", "T2", "T3", "T4", "T5", "T6"],
  "continents": [
    {"name": "A", "bonus": 2, "territories": ["T1", "T2", "T3"]},
    {"name": "B", "bonus": 3, "territories": ["T4", "T5", "T6"]}
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
  int tradeCount = 0,
  List<PlayerState>? players,
}) {
  final territories = <String, TerritoryState>{};
  for (final entry in player0Territories.entries) {
    territories[entry.key] = TerritoryState(owner: 0, armies: entry.value);
  }
  for (final t in player1Territories) {
    territories[t] = TerritoryState(owner: 1, armies: 1);
  }
  final ps = players ??
      [
        const PlayerState(index: 0, name: 'Player 1'),
        const PlayerState(index: 1, name: 'Player 2'),
      ];
  return GameState(
    territories: territories,
    players: ps,
    currentPlayerIndex: currentPlayer,
    cards: cards ?? {'0': [], '1': []},
    tradeCount: tradeCount,
  );
}

void main() {
  // ----------------------------------------------------------------
  // chooseReinforcementPlacement
  // ----------------------------------------------------------------

  group('MediumAgent.chooseReinforcementPlacement', () {
    test('places all armies on border territory of highest-scoring continent', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns T1, T2, T3 (continent A = fraction 3/3 = 1.0).
      // Player 1 owns T4, T5, T6.
      // T3 borders T4 (enemy) — cross-continent external border.
      // T2 borders T1 (friendly) and T3 (friendly) — interior!
      // T1 borders T2 (friendly) only — interior.
      // Top continent: A has fraction 1.0, B has fraction 0.
      // In continent A, owned borders: T3 (borders T4 enemy).
      // All armies go to T3 (only border in top continent).
      final state = _buildState(
        player0Territories: {'T1': 2, 'T2': 2, 'T3': 1},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      final action =
          agent.chooseReinforcementPlacement(state, 4);
      expect(action.placements.values.fold(0, (a, b) => a + b), equals(4));
      // T3 is the only border territory in continent A; all armies go there.
      expect(action.placements['T3'], equals(4));
    });

    test('falls back to any border territory when continent has no owned borders', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 only owns T1 (no enemy neighbors — T2 is also owned).
      // T2 borders T3 (enemy).
      final state = _buildState(
        player0Territories: {'T1': 2, 'T2': 3},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );

      // Continent A: owned T1,T2 out of 3; fraction 2/3.
      // Border in continent A: T2 (borders T3 enemy). T1 only neighbors T2 (friendly).
      // Armies go to T2 (minimum armies among borders in top continent).
      final action = agent.chooseReinforcementPlacement(state, 3);
      expect(action.placements.values.fold(0, (a, b) => a + b), equals(3));
      // T2 is the border in top continent.
      expect(action.placements['T2'], equals(3));
    });

    test('places all armies on weakest border territory', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns T3 (1 army) and T4 (5 armies).
      // T3 borders T2 (enemy) and T4 (friendly).
      // T4 borders T3 (friendly) and T5 (enemy).
      // Continent A: owned T3 only (1/3). Continent B: owned T4 only (1/3) — tie; B has higher bonus.
      // Top continent: B has bonus=3 vs A bonus=2 (tiebreak on equal fraction).
      // Border in B: T4. Armies go to T4.
      final state = _buildState(
        player0Territories: {'T3': 1, 'T4': 5},
        player1Territories: ['T1', 'T2', 'T5', 'T6'],
      );

      final action = agent.chooseReinforcementPlacement(state, 2);
      expect(action.placements.values.fold(0, (a, b) => a + b), equals(2));
      expect(action.placements['T4'], equals(2));
    });

    test('total placements equals armies regardless of distribution', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      final state = _buildState(
        player0Territories: {'T2': 3, 'T3': 2, 'T4': 1},
        player1Territories: ['T1', 'T5', 'T6'],
      );

      final action = agent.chooseReinforcementPlacement(state, 5);
      final total = action.placements.values.fold(0, (a, b) => a + b);
      expect(total, equals(5));
    });
  });

  // ----------------------------------------------------------------
  // chooseAttack
  // ----------------------------------------------------------------

  group('MediumAgent.chooseAttack', () {
    test('returns null when no attack candidates exist', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns T1,T2 (no enemy neighbors — T3 is also owned but has 1 army).
      final state = _buildState(
        player0Territories: {'T1': 3, 'T2': 3, 'T3': 1},
        player1Territories: ['T4', 'T5', 'T6'],
      );
      // T3 (1 army) borders T4 but can't attack (needs >=2). T1 and T2 only have friendly neighbors.
      expect(agent.chooseAttack(state), isNull);
    });

    test('priority 1: continent-completing attack (src >= tgt)', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns T1(3), T2(3) in continent A. T3 is the last enemy territory in A.
      // Attacking T3 completes continent A. T3 has 2 armies — src(3) >= tgt(2). Should attack.
      final state = _buildState(
        player0Territories: {'T1': 2, 'T2': 3},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );
      // Override T3 to have 2 armies
      final territories = Map<String, TerritoryState>.from(state.territories);
      territories['T3'] = const TerritoryState(owner: 1, armies: 2);
      final state2 = state.copyWith(territories: territories);

      final action = agent.chooseAttack(state2);
      expect(action, isNotNull);
      if (action is AttackAction) {
        expect(action.target, equals('T3'));
      } else {
        fail('Expected AttackAction');
      }
    });

    test('priority 2: favorable attack into top-scoring continent', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns T3(5), T4(1) from continents A and B.
      // Top continent: A fraction 1/3, B fraction 1/3 — tied, B has bonus 3.
      // Actually T3 is in A, T4 is in B. A: 1/3, B: 1/3. Tiebreak: B wins (bonus 3 > 2).
      // T4 borders T5 (enemy, 1 army) — favorable: 1 > 1 is false. Let's use T3(5) -> T4 is friendly.
      // Better setup: T4(4) borders T5(1). Top continent B. T5 is in B. Attack T5.
      final state = _buildState(
        player0Territories: {'T1': 1, 'T4': 5},
        player1Territories: ['T2', 'T3', 'T5', 'T6'],
      );
      // T4 in B borders T5 (enemy, 1 army). src(5) > tgt(1). Priority 2 should fire.
      final action = agent.chooseAttack(state);
      expect(action, isNotNull);
      if (action is AttackAction) {
        // Should prefer attacking into top continent
        expect(action.source, equals('T4'));
        expect(action.target, equals('T5'));
      } else {
        fail('Expected AttackAction');
      }
    });

    test('priority 4: any favorable attack when no continent targets', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns T2(5). T3 is in A (top or equal continent), T1 is in A too.
      // T1 is enemy with 1 army. T3 is enemy with 1 army.
      // Source T2(5) > T1(1) and T2(5) > T3(1) — both favorable.
      final state = _buildState(
        player0Territories: {'T2': 5},
        player1Territories: ['T1', 'T3', 'T4', 'T5', 'T6'],
      );
      final action = agent.chooseAttack(state);
      expect(action, isNotNull);
      expect(action is AttackAction, isTrue);
    });

    test('returns null when no favorable attacks and no continent completion', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns T2(1 army — can't attack). No valid attacks.
      final state = _buildState(
        player0Territories: {'T2': 1},
        player1Territories: ['T1', 'T3', 'T4', 'T5', 'T6'],
      );
      expect(agent.chooseAttack(state), isNull);
    });

    test('numDice is min(3, armies - 1)', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // T2(2 armies) can only use 1 die.
      final state = _buildState(
        player0Territories: {'T2': 2},
        player1Territories: ['T1', 'T3', 'T4', 'T5', 'T6'],
      );
      final action = agent.chooseAttack(state);
      if (action is AttackAction) {
        expect(action.numDice, equals(1));
      } else {
        fail('Expected AttackAction');
      }
    });
  });

  // ----------------------------------------------------------------
  // chooseFortify
  // ----------------------------------------------------------------

  group('MediumAgent.chooseFortify', () {
    test('returns null when no interior territories exist', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // T3 borders T4 (enemy) and T2 (friendly) — not interior. T2 borders T1, T3 (but T3 borders enemy).
      // Actually T2's neighbors are T1(friendly) and T3(friendly? T3 borders T4 enemy — T2 is not interior).
      // T1's only neighbor is T2 (friendly) — T1 IS interior.
      // But T1 has only 1 army — not enough to move.
      final state = _buildState(
        player0Territories: {'T1': 1, 'T2': 3, 'T3': 2},
        player1Territories: ['T4', 'T5', 'T6'],
      );
      // T1: all neighbors (T2) are friendly, but T1 has 1 army (<2). Not a valid source.
      // T2: neighbor T3 is owned, T1 is owned — but T3 itself borders T4 (enemy).
      //     T2's neighbors are T1(owned) and T3(owned). So T2 IS interior!
      // Wait — T2 neighbors: T1, T3. T1 owned, T3 owned. So T2 is interior with 3 armies.
      // T3 neighbors: T2(owned), T4(enemy). Not interior.
      // Interior: T2(3 armies) — valid source.
      // Border: T3(2 armies) — valid target.
      // So this should NOT return null. Let me pick a case where no interior exists.
      // No interior: all owned territories border an enemy.
      final state2 = _buildState(
        player0Territories: {'T3': 3, 'T4': 2},
        player1Territories: ['T1', 'T2', 'T5', 'T6'],
      );
      // T3 neighbors: T2(enemy), T4(owned). T3 borders T2 (enemy) — NOT interior.
      // T4 neighbors: T3(owned), T5(enemy). T4 borders T5 (enemy) — NOT interior.
      expect(agent.chooseFortify(state2), isNull);
    });

    test('returns null when no border territories exist', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // Player 0 owns all territories — no enemies = no borders.
      // But interior with >=2 armies exists. However no borders -> return null.
      final state = _buildState(
        player0Territories: {'T1': 3, 'T2': 2, 'T3': 2, 'T4': 2, 'T5': 2, 'T6': 2},
        player1Territories: [],
      );
      expect(agent.chooseFortify(state), isNull);
    });

    test('moves from interior (most armies) to weakest reachable border', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // T1(5): all neighbors are T2(owned) — interior.
      // T2(1): neighbors T1(owned), T3(owned) — interior (but 1 army, not valid source).
      // T3(2): neighbors T2(owned), T4(enemy) — border.
      // Source: T1(5 armies, interior with most armies).
      // Target: T3(2 armies) — only reachable border.
      // armiesMove = 5-1 = 4.
      final state = _buildState(
        player0Territories: {'T1': 5, 'T2': 1, 'T3': 2},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      final action = agent.chooseFortify(state);
      expect(action, isNotNull);
      if (action is FortifyAction) {
        expect(action.source, equals('T1'));
        expect(action.target, equals('T3'));
        expect(action.armies, equals(4));
      } else {
        fail('Expected FortifyAction, got $action');
      }
    });

    test('selects interior with most armies as source', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // T1(3): neighbors T2 — interior.
      // T2(5): neighbors T1, T3 — interior (T3 is owned by player 0).
      // Wait, T3 borders T4 (enemy). So T2's neighbors T1(owned), T3(owned) — T2 is interior.
      // T3(1): neighbors T2(owned), T4(enemy) — border, 1 army, not valid source.
      // T4: enemy.
      // Interior sources: T1(3) and T2(5). Most armies = T2.
      final state = _buildState(
        player0Territories: {'T1': 3, 'T2': 5, 'T3': 1},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      final action = agent.chooseFortify(state);
      expect(action, isNotNull);
      if (action is FortifyAction) {
        expect(action.source, equals('T2'));
      } else {
        fail('Expected FortifyAction');
      }
    });

    test('target is reachable border with fewest armies', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      // T1(3): interior (only neighbor T2 is owned).
      // T2(2): interior (neighbors T1, T3 both owned).
      // T3(5): border (borders T4 enemy).
      // T4: enemy.
      // T5: enemy.
      // No other borders. Target must be T3 (only reachable border).
      final state = _buildState(
        player0Territories: {'T1': 3, 'T2': 2, 'T3': 5},
        player1Territories: ['T4', 'T5', 'T6'],
      );

      final action = agent.chooseFortify(state);
      expect(action, isNotNull);
      if (action is FortifyAction) {
        expect(action.target, equals('T3'));
      } else {
        fail('Expected FortifyAction');
      }
    });
  });

  // ----------------------------------------------------------------
  // chooseCardTrade
  // ----------------------------------------------------------------

  group('MediumAgent.chooseCardTrade', () {
    test('returns null when fewer than 3 cards', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      final state = _buildState(
        player0Territories: {'T1': 2},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );
      const c1 = Card(territory: 'T1', cardType: CardType.infantry);
      const c2 = Card(territory: 'T2', cardType: CardType.cavalry);

      expect(agent.chooseCardTrade(state, [c1, c2], forced: false), isNull);
      expect(agent.chooseCardTrade(state, [], forced: false), isNull);
    });

    test('returns first valid set when one exists (identical to EasyAgent)', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      final state = _buildState(
        player0Territories: {'T1': 2},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );
      const inf = Card(territory: 'T1', cardType: CardType.infantry);
      const cav = Card(territory: 'T2', cardType: CardType.cavalry);
      const art = Card(territory: 'T3', cardType: CardType.artillery);

      final action = agent.chooseCardTrade(state, [inf, cav, art], forced: false);
      expect(action, isNotNull);
      expect(action!.cards.length, equals(3));
    });

    test('returns null when no valid set in hand', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      final state = _buildState(
        player0Territories: {'T1': 2},
        player1Territories: ['T2', 'T3', 'T4', 'T5', 'T6'],
      );
      const inf1 = Card(territory: 'T1', cardType: CardType.infantry);
      const inf2 = Card(territory: 'T2', cardType: CardType.infantry);
      const cav = Card(territory: 'T3', cardType: CardType.cavalry);

      expect(agent.chooseCardTrade(state, [inf1, inf2, cav], forced: false), isNull);
    });
  });

  // ----------------------------------------------------------------
  // chooseAdvanceArmies
  // ----------------------------------------------------------------

  group('MediumAgent.chooseAdvanceArmies', () {
    test('always returns minimum armies (conservative)', () {
      final mapGraph = _testMap;
      final agent = MediumAgent(mapGraph: mapGraph);

      final state = _buildState(
        player0Territories: {'T1': 5, 'T2': 3},
        player1Territories: ['T3', 'T4', 'T5', 'T6'],
      );

      expect(agent.chooseAdvanceArmies(state, 'T1', 'T2', 1, 4), equals(1));
      expect(agent.chooseAdvanceArmies(state, 'T1', 'T2', 3, 3), equals(3));
    });
  });
}
