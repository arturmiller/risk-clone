import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/cards.dart';

void main() {
  group('TerritoryState', () {
    test('copyWith changes owner and armies independently', () {
      const ts = TerritoryState(owner: 0, armies: 3);

      final changed = ts.copyWith(owner: 1);
      expect(changed.owner, equals(1));
      expect(changed.armies, equals(3)); // unchanged

      final armyChange = ts.copyWith(armies: 5);
      expect(armyChange.owner, equals(0)); // unchanged
      expect(armyChange.armies, equals(5));
    });

    test('equality holds for same values', () {
      const ts1 = TerritoryState(owner: 2, armies: 7);
      const ts2 = TerritoryState(owner: 2, armies: 7);
      expect(ts1, equals(ts2));
    });
  });

  group('PlayerState', () {
    test('equality holds for same values', () {
      const p1 = PlayerState(index: 0, name: 'Alice');
      const p2 = PlayerState(index: 0, name: 'Alice');
      expect(p1, equals(p2));
    });

    test('isAlive defaults to true', () {
      const p = PlayerState(index: 0, name: 'Bob');
      expect(p.isAlive, isTrue);
    });
  });

  group('GameState', () {
    test('JSON round-trip produces equal object', () {
      final state = GameState(
        territories: {
          'Alaska': const TerritoryState(owner: 0, armies: 3),
          'Brazil': const TerritoryState(owner: 1, armies: 2),
        },
        players: const [
          PlayerState(index: 0, name: 'Alice'),
          PlayerState(index: 1, name: 'Bob'),
        ],
        currentPlayerIndex: 0,
        turnNumber: 1,
        turnPhase: TurnPhase.reinforce,
        tradeCount: 0,
        cards: {},
        deck: [],
        conqueredThisTurn: false,
      );

      final json = state.toJson();
      final jsonString = jsonEncode(json);
      final decoded = GameState.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);

      expect(decoded, equals(state));
    });
  });
}
