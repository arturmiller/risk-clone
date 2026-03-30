import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/ui_state.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/map_provider.dart';
import 'package:risk_mobile/providers/ui_provider.dart';
import 'package:risk_mobile/widgets/territory_inspector.dart';

import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';

import 'dart:convert';

class FakeGameNotifier extends GameNotifier {
  final GameState fakeState;
  FakeGameNotifier(this.fakeState);

  @override
  Future<GameState?> build() async => fakeState;
}

GameState _makeState() {
  return const GameState(
    territories: {
      'Alaska': TerritoryState(owner: 0, armies: 5),
      'Alberta': TerritoryState(owner: 1, armies: 3),
    },
    players: [
      PlayerState(index: 0, name: 'Player 1'),
      PlayerState(index: 1, name: 'Player 2'),
    ],
  );
}

/// Embedded minimal map for territory inspector tests.
/// Uses the same territory names as the tests expect (Alaska, Alberta).
const String _testMapJson = '''
{
  "name": "TestMap",
  "territories": ["Alaska", "Alberta"],
  "continents": [
    {"name": "North America", "bonus": 5, "territories": ["Alaska", "Alberta"]}
  ],
  "adjacencies": [
    ["Alaska", "Alberta"]
  ]
}
''';

MapGraph _loadMapGraph() {
  final json = jsonDecode(_testMapJson) as Map<String, dynamic>;
  return MapGraph(MapData.fromJson(json));
}

Widget _wrap({
  required UIState uiState,
  required GameState gameState,
  required MapGraph mapGraph,
}) {
  return ProviderScope(
    overrides: [
      uIStateProvider.overrideWithValue(uiState),
      gameProvider.overrideWith(() => FakeGameNotifier(gameState)),
      mapGraphProvider.overrideWith((ref, arg) => mapGraph),
    ],
    child: const MaterialApp(
      home: Scaffold(body: TerritoryInspector()),
    ),
  );
}

void main() {
  late MapGraph mapGraph;

  setUpAll(() {
    mapGraph = _loadMapGraph();
  });

  group('TerritoryInspector', () {
    testWidgets('renders SizedBox.shrink when no territory selected',
        (tester) async {
      await tester.pumpWidget(_wrap(
        uiState: UIState.empty(),
        gameState: _makeState(),
        mapGraph: mapGraph,
      ));
      await tester.pump();
      // Should not find any Card widget
      expect(find.byType(Card), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows territory name, owner name, army count when selected',
        (tester) async {
      await tester.pumpWidget(_wrap(
        uiState: const UIState(selectedTerritory: 'Alaska'),
        gameState: _makeState(),
        mapGraph: mapGraph,
      ));
      await tester.pump();
      expect(find.text('Alaska'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Armies: 5'), findsOneWidget);
    });

    testWidgets('shows correct player color dot', (tester) async {
      // Select Alberta owned by Player 2 (index 1 = Blue)
      await tester.pumpWidget(_wrap(
        uiState: const UIState(selectedTerritory: 'Alberta'),
        gameState: _makeState(),
        mapGraph: mapGraph,
      ));
      await tester.pump();
      expect(find.text('Player 2'), findsOneWidget);
      // Find the color dot container
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(Card),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        ),
      );
      final decoration = dot.decoration as BoxDecoration;
      // Player 2 (index 1) = Blue = 0xFF1E88E5
      expect(decoration.color, const Color(0xFF1E88E5));
    });

    testWidgets('shows continent name', (tester) async {
      await tester.pumpWidget(_wrap(
        uiState: const UIState(selectedTerritory: 'Alaska'),
        gameState: _makeState(),
        mapGraph: mapGraph,
      ));
      await tester.pump();
      expect(find.text('North America'), findsOneWidget);
    });
  });
}
