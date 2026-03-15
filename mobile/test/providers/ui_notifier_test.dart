import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/models/ui_state.dart';
import 'package:risk_mobile/providers/ui_provider.dart';

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
    ["T1", "T2"], ["T2", "T3"], ["T3", "T4"], ["T4", "T5"], ["T5", "T6"], ["T6", "T1"]
  ]
}
''';

MapGraph get _testMap =>
    MapGraph(MapData.fromJson(jsonDecode(_minimalMapJson) as Map<String, dynamic>));

/// Build a game state where player 0 owns T1/T3/T5 and player 1 owns T2/T4/T6.
GameState _buildGameState({TurnPhase phase = TurnPhase.attack}) {
  const territories = {
    'T1': TerritoryState(owner: 0, armies: 3),
    'T2': TerritoryState(owner: 1, armies: 2),
    'T3': TerritoryState(owner: 0, armies: 3),
    'T4': TerritoryState(owner: 1, armies: 2),
    'T5': TerritoryState(owner: 0, armies: 3),
    'T6': TerritoryState(owner: 1, armies: 2),
  };
  return GameState(
    territories: territories,
    players: [
      const PlayerState(index: 0, name: 'Player 1'),
      const PlayerState(index: 1, name: 'Player 2'),
    ],
    turnPhase: phase,
    currentPlayerIndex: 0,
  );
}

void main() {
  group('UIStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns UIState.empty()', () {
      final uiState = container.read(uIStateProvider);
      expect(uiState, equals(UIState.empty()));
      expect(uiState.selectedTerritory, isNull);
      expect(uiState.validTargets, isEmpty);
      expect(uiState.validSources, isEmpty);
    });

    test('selectTerritory updates selectedTerritory', () {
      final notifier = container.read(uIStateProvider.notifier);
      final gameState = _buildGameState();
      final map = _testMap;

      notifier.selectTerritory('T1', gameState, map);

      final uiState = container.read(uIStateProvider);
      expect(uiState.selectedTerritory, equals('T1'));
    });

    test('selectTerritory in attack phase computes valid targets as adjacent enemy territories', () {
      final notifier = container.read(uIStateProvider.notifier);
      final gameState = _buildGameState(phase: TurnPhase.attack);
      final map = _testMap;

      // T1 (owner 0, 3 armies) is adjacent to T2 (enemy) and T6 (enemy)
      notifier.selectTerritory('T1', gameState, map);

      final uiState = container.read(uIStateProvider);
      expect(uiState.validTargets, contains('T2'));
      expect(uiState.validTargets, contains('T6'));
      // T3 is adjacent... wait T1-T2, T2-T3, T6-T1. Let's check adjacency.
      // adjacencies: T1-T2, T2-T3, T3-T4, T4-T5, T5-T6, T6-T1
      // T1 neighbors: T2, T6. Both are enemy (owner 1).
      expect(uiState.validTargets, hasLength(2));
    });

    test('selectTerritory in reinforce phase returns empty targets', () {
      final notifier = container.read(uIStateProvider.notifier);
      final gameState = _buildGameState(phase: TurnPhase.reinforce);
      final map = _testMap;

      notifier.selectTerritory('T1', gameState, map);

      final uiState = container.read(uIStateProvider);
      expect(uiState.selectedTerritory, equals('T1'));
      expect(uiState.validTargets, isEmpty);
    });

    test('selectTerritory in fortify phase computes connected friendly territories', () {
      final notifier = container.read(uIStateProvider.notifier);
      final gameState = _buildGameState(phase: TurnPhase.fortify);
      final map = _testMap;

      // Player 0 owns T1, T3, T5. Adjacencies: T1-T2-T3-T4-T5-T6-T1.
      // Friendly subgraph for player 0: T1, T3, T5 — but they're not directly connected
      // (T1-T2(enemy)-T3, T3-T4(enemy)-T5, T5-T6(enemy)-T1). So no friendly connections.
      notifier.selectTerritory('T1', gameState, map);

      final uiState = container.read(uIStateProvider);
      // No friendly connections through enemy territories
      expect(uiState.validTargets, isEmpty);
    });

    test('selectTerritory computes validSources as player-owned territories with >=2 armies', () {
      final notifier = container.read(uIStateProvider.notifier);
      final gameState = _buildGameState();
      final map = _testMap;

      notifier.selectTerritory('T1', gameState, map);

      final uiState = container.read(uIStateProvider);
      // Player 0 owns T1, T3, T5 each with 3 armies (>= 2)
      expect(uiState.validSources, containsAll(['T1', 'T3', 'T5']));
      expect(uiState.validSources, isNot(contains('T2')));
      expect(uiState.validSources, isNot(contains('T4')));
      expect(uiState.validSources, isNot(contains('T6')));
    });

    test('clearSelection resets to UIState.empty()', () {
      final notifier = container.read(uIStateProvider.notifier);
      final gameState = _buildGameState();
      final map = _testMap;

      notifier.selectTerritory('T1', gameState, map);
      expect(container.read(uIStateProvider).selectedTerritory, equals('T1'));

      notifier.clearSelection();

      expect(container.read(uIStateProvider), equals(UIState.empty()));
    });
  });
}
