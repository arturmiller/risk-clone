import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/widgets/continent_panel.dart';
import 'package:risk_mobile/providers/map_provider.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'dart:convert';

/// Minimal map JSON with 6 continents matching classic Risk layout.
const String _fakeMapJson = '''
{
  "name": "TestMap",
  "territories": [
    "Alaska", "Ontario", "Brazil", "Egypt", "Ukraine", "India",
    "Indonesia", "T8", "T9", "T10", "T11", "T12"
  ],
  "continents": [
    {"name": "North America", "bonus": 5, "territories": ["Alaska", "Ontario"]},
    {"name": "South America", "bonus": 2, "territories": ["Brazil"]},
    {"name": "Africa", "bonus": 3, "territories": ["Egypt"]},
    {"name": "Europe", "bonus": 5, "territories": ["Ukraine"]},
    {"name": "Asia", "bonus": 7, "territories": ["India"]},
    {"name": "Australia", "bonus": 2, "territories": ["Indonesia"]}
  ],
  "adjacencies": [
    ["Alaska", "Ontario"], ["Ontario", "Brazil"], ["Brazil", "Egypt"],
    ["Egypt", "Ukraine"], ["Ukraine", "India"], ["India", "Indonesia"]
  ]
}
''';

MapGraph get _fakeMapGraph =>
    MapGraph(MapData.fromJson(jsonDecode(_fakeMapJson) as Map<String, dynamic>));

/// GameState where player 0 controls all of North America.
GameState _makeGameState({bool controlsNorthAmerica = false}) {
  return GameState(
    territories: {
      'Alaska': TerritoryState(owner: controlsNorthAmerica ? 0 : 1, armies: 3),
      'Ontario': TerritoryState(owner: controlsNorthAmerica ? 0 : 1, armies: 2),
      'Brazil': const TerritoryState(owner: 1, armies: 1),
      'Egypt': const TerritoryState(owner: 1, armies: 1),
      'Ukraine': const TerritoryState(owner: 1, armies: 1),
      'India': const TerritoryState(owner: 1, armies: 1),
      'Indonesia': const TerritoryState(owner: 1, armies: 1),
    },
    players: const [
      PlayerState(index: 0, name: 'Player 1', isAlive: true),
      PlayerState(index: 1, name: 'Bot 1', isAlive: true),
    ],
    currentPlayerIndex: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContinentPanel (MOBX-05)', () {
    testWidgets('renders all continent names', (tester) async {
      final fakeMap = _fakeMapGraph;
      final fakeState = _makeGameState();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mapGraphProvider.overrideWith((ref) => Future.value(fakeMap)),
            gameProvider.overrideWith(() => _FakeGameNotifier(fakeState)),
          ],
          child: const MaterialApp(home: Scaffold(body: ContinentPanel())),
        ),
      );
      await tester.pump(); // allow async providers to settle

      expect(find.text('North America'), findsOneWidget);
      expect(find.text('South America'), findsOneWidget);
      expect(find.text('Africa'), findsOneWidget);
      expect(find.text('Europe'), findsOneWidget);
      expect(find.text('Asia'), findsOneWidget);
      expect(find.text('Australia'), findsOneWidget);
    });

    testWidgets('renders continent bonus values', (tester) async {
      final fakeMap = _fakeMapGraph;
      final fakeState = _makeGameState();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mapGraphProvider.overrideWith((ref) => Future.value(fakeMap)),
            gameProvider.overrideWith(() => _FakeGameNotifier(fakeState)),
          ],
          child: const MaterialApp(home: Scaffold(body: ContinentPanel())),
        ),
      );
      await tester.pump();

      // North America bonus = 5
      expect(find.text('+5'), findsAtLeastNWidgets(1));
      // Australia bonus = 2
      expect(find.text('+2'), findsAtLeastNWidgets(1));
    });

    testWidgets('highlights controlled continent for current player', (tester) async {
      final fakeMap = _fakeMapGraph;
      // Player 0 controls North America (owns Alaska + Ontario)
      final fakeState = _makeGameState(controlsNorthAmerica: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mapGraphProvider.overrideWith((ref) => Future.value(fakeMap)),
            gameProvider.overrideWith(() => _FakeGameNotifier(fakeState)),
          ],
          child: const MaterialApp(home: Scaffold(body: ContinentPanel())),
        ),
      );
      await tester.pump();

      // Star icon appears for the controlled continent
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}

/// Fake GameNotifier that returns a fixed GameState without needing ObjectBox.
class _FakeGameNotifier extends GameNotifier {
  final GameState _fixedState;
  _FakeGameNotifier(this._fixedState);

  @override
  Future<GameState?> build() async => _fixedState;
}
