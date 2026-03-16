import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import 'package:risk_mobile/objectbox.g.dart';
import 'package:risk_mobile/persistence/app_store.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/map_provider.dart';
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/screens/home_screen.dart';
import 'package:risk_mobile/screens/game_screen.dart';

// Minimal map for tests
const String _minimalMapJson = '''
{
  "name": "Test",
  "territories": ["T1", "T2", "T3", "T4", "T5", "T6"],
  "continents": [
    {"name": "C1", "bonus": 1, "territories": ["T1", "T2", "T3"]},
    {"name": "C2", "bonus": 1, "territories": ["T4", "T5", "T6"]}
  ],
  "adjacencies": [
    ["T1", "T2"], ["T2", "T3"], ["T3", "T4"], ["T4", "T5"], ["T5", "T6"], ["T6", "T1"]
  ]
}
''';

MapGraph get _testMapGraph => MapGraph(
    MapData.fromJson(jsonDecode(_minimalMapJson) as Map<String, dynamic>));

/// Minimal GameState with 2 alive players
GameState _makeGameState() {
  return GameState(
    territories: {
      'T1': const TerritoryState(owner: 0, armies: 3),
      'T2': const TerritoryState(owner: 0, armies: 2),
      'T3': const TerritoryState(owner: 0, armies: 1),
      'T4': const TerritoryState(owner: 1, armies: 2),
      'T5': const TerritoryState(owner: 1, armies: 2),
      'T6': const TerritoryState(owner: 1, armies: 2),
    },
    players: const [
      PlayerState(index: 0, name: 'Player 1', isAlive: true),
      PlayerState(index: 1, name: 'Bot 1', isAlive: true),
    ],
    turnNumber: 5,
  );
}

/// Fake GameNotifier that records setupGame() calls
class _FakeGameNotifier extends GameNotifier {
  final GameState? initialState;
  bool setupGameCalled = false;
  GameConfig? setupConfig;

  _FakeGameNotifier({this.initialState});

  @override
  Future<GameState?> build() async => initialState;

  @override
  Future<void> setupGame(GameConfig config) async {
    setupGameCalled = true;
    setupConfig = config;
    // Simulate state transition so HomeScreen navigates
    state = AsyncData(_makeGameState());
  }

  @override
  Future<void> clearSave() async {
    state = const AsyncData(null);
  }

  @override
  Future<void> humanMove(Object? action) async {}
}

Store _createTempStore(String testName) {
  final tempDir = Directory(
    path.join(Directory.systemTemp.path,
        'obx_hs_${testName}_${DateTime.now().microsecondsSinceEpoch}'),
  );
  tempDir.createSync(recursive: true);
  return Store(getObjectBoxModel(), directory: tempDir.path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen setup form (MOBX-01)', () {
    Widget buildForm() {
      return MaterialApp(
        home: Scaffold(
          body: SetupForm(onStart: (_) {}),
        ),
      );
    }

    testWidgets('renders player count selector', (tester) async {
      await tester.pumpWidget(buildForm());
      // Slider widget should be present
      expect(find.byType(Slider), findsOneWidget);
      // Default label "Players: 3" should appear
      expect(find.text('Players: 3'), findsOneWidget);
    });

    testWidgets('renders difficulty selector', (tester) async {
      await tester.pumpWidget(buildForm());
      // SegmentedButton with Difficulty values
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('renders game mode selector', (tester) async {
      await tester.pumpWidget(buildForm());
      // SegmentedButton with GameMode values
      expect(find.text('vs Bots'), findsOneWidget);
      expect(find.text('Simulation'), findsOneWidget);
    });

    testWidgets('tapping Start calls setupGame with chosen config',
        (tester) async {
      late Store store;
      late Directory tempDir;
      final name = 'hs_start_${DateTime.now().microsecondsSinceEpoch}';
      tempDir = Directory(
          path.join(Directory.systemTemp.path, 'obx_test_$name'));
      tempDir.createSync(recursive: true);
      store = Store(getObjectBoxModel(), directory: tempDir.path);

      final fakeNotifier = _FakeGameNotifier(initialState: null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            mapGraphProvider.overrideWith((ref) => Future.value(_testMapGraph)),
            gameProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump(); // settle async providers

      // Start Game button should be visible (no game in progress)
      expect(find.text('Start Game'), findsOneWidget);

      // Tap Start Game
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // setupGame should have been called
      expect(fakeNotifier.setupGameCalled, isTrue);

      // GameScreen should have been pushed
      expect(find.byType(GameScreen), findsOneWidget);

      store.close();
      tempDir.deleteSync(recursive: true);
    });

    testWidgets('Resume button navigates to GameScreen when game in progress',
        (tester) async {
      late Store store;
      late Directory tempDir;
      final name = 'hs_resume_${DateTime.now().microsecondsSinceEpoch}';
      tempDir = Directory(
          path.join(Directory.systemTemp.path, 'obx_test_$name'));
      tempDir.createSync(recursive: true);
      store = Store(getObjectBoxModel(), directory: tempDir.path);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            mapGraphProvider.overrideWith((ref) => Future.value(_testMapGraph)),
            gameProvider.overrideWith(
                () => _FakeGameNotifier(initialState: _makeGameState())),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump(); // settle async providers

      // Resume button should be visible (game in progress)
      expect(find.text('Resume'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      // GameScreen should have been pushed
      expect(find.byType(GameScreen), findsOneWidget);

      store.close();
      tempDir.deleteSync(recursive: true);
    });
  });
}
