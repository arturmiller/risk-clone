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
import 'package:risk_mobile/providers/ui_provider.dart';
import 'package:risk_mobile/providers/simulation_provider.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/screens/game_screen.dart';
import 'package:risk_mobile/widgets/action_panel.dart';
import 'package:risk_mobile/widgets/continent_panel.dart';
import 'package:risk_mobile/widgets/simulation_control_bar.dart';
import 'package:risk_mobile/widgets/simulation_status_bar.dart';

// Minimal map for tests — 6 territories, 2 continents
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

/// Minimal GameState with 2 alive players in reinforce phase
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
    turnPhase: TurnPhase.reinforce,
    currentPlayerIndex: 0,
  );
}

Store _createTempStore(String testName) {
  final tempDir = Directory(
    path.join(Directory.systemTemp.path,
        'obx_gs_${testName}_${DateTime.now().microsecondsSinceEpoch}'),
  );
  tempDir.createSync(recursive: true);
  return Store(getObjectBoxModel(), directory: tempDir.path);
}

/// Fake GameNotifier that returns a fixed GameState
class _FakeGameNotifier extends GameNotifier {
  final GameState? fakeState;
  _FakeGameNotifier({this.fakeState});

  @override
  Future<GameState?> build() async => fakeState;

  @override
  Future<void> setupGame(config) async {}

  @override
  Future<void> clearSave() async {
    state = const AsyncData(null);
  }

  @override
  Future<void> humanMove(Object? action) async {}
}

Widget _buildGameScreen(
  Store store, {
  GameState? gameState,
  GameMode gameMode = GameMode.vsBot,
}) {
  return ProviderScope(
    overrides: [
      storeProvider.overrideWithValue(store),
      mapGraphProvider.overrideWith((ref, arg) => Future.value(_testMapGraph)),
      gameProvider.overrideWith(
          () => _FakeGameNotifier(fakeState: gameState ?? _makeGameState())),
    ],
    child: MaterialApp(home: GameScreen(gameMode: gameMode)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameScreen layout (MOBX-02)', () {
    late Store store;
    late Directory tempDir;

    setUp(() {
      final name = 'gs_${DateTime.now().microsecondsSinceEpoch}';
      tempDir = Directory(
          path.join(Directory.systemTemp.path, 'obx_test_$name'));
      tempDir.createSync(recursive: true);
      store = Store(getObjectBoxModel(), directory: tempDir.path);
    });

    tearDown(() {
      store.close();
      tempDir.deleteSync(recursive: true);
    });

    testWidgets('portrait layout: map above bottom panel, no overflow',
        (tester) async {
      // iPhone-like portrait: 375 logical pixels wide
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildGameScreen(store));
      await tester.pump();

      // ActionPanel should appear in the bottom panel
      expect(find.byType(ActionPanel), findsOneWidget);
      // No RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape layout (600dp+ width): map left, sidebar right',
        (tester) async {
      // Wide landscape: 800dp logical width, tall enough to avoid overflow
      tester.view.physicalSize = const Size(800 * 3, 600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildGameScreen(store));
      await tester.pump();

      // ContinentPanel should appear in the sidebar
      expect(find.byType(ContinentPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PopScope shows abandon dialog on back press', (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildGameScreen(store));
      await tester.pump();

      // Simulate system back button
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Abandon dialog should appear
      expect(find.text('Abandon game?'), findsOneWidget);
    });
  });

  group('GameScreen simulation mode (BOTS-09)', () {
    late Store store;
    late Directory tempDir;

    setUp(() {
      final name = 'gs_sim_${DateTime.now().microsecondsSinceEpoch}';
      tempDir = Directory(
          path.join(Directory.systemTemp.path, 'obx_test_$name'));
      tempDir.createSync(recursive: true);
      store = Store(getObjectBoxModel(), directory: tempDir.path);
    });

    tearDown(() {
      store.close();
      tempDir.deleteSync(recursive: true);
    });

    testWidgets(
        'portrait simulation renders SimulationStatusBar and SimulationControlBar',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _buildGameScreen(store, gameMode: GameMode.simulation));
      await tester.pump();

      expect(find.byType(SimulationStatusBar), findsOneWidget);
      expect(find.byType(SimulationControlBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('simulation mode does NOT render ActionPanel', (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _buildGameScreen(store, gameMode: GameMode.simulation));
      await tester.pump();

      expect(find.byType(ActionPanel), findsNothing);
    });

    testWidgets('vsBot mode still renders ActionPanel (no regression)',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(_buildGameScreen(store, gameMode: GameMode.vsBot));
      await tester.pump();

      expect(find.byType(ActionPanel), findsOneWidget);
      expect(find.byType(SimulationControlBar), findsNothing);
      expect(find.byType(SimulationStatusBar), findsNothing);
    });

    testWidgets(
        'landscape simulation renders StatusBar and ControlBar in sidebar',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 3, 600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _buildGameScreen(store, gameMode: GameMode.simulation));
      await tester.pump();

      expect(find.byType(SimulationStatusBar), findsOneWidget);
      expect(find.byType(SimulationControlBar), findsOneWidget);
      expect(find.byType(ActionPanel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'simulation PopScope shows stop confirmation (not abandon dialog)',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _buildGameScreen(store, gameMode: GameMode.simulation));
      await tester.pump();

      // Simulate system back button
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Should show simulation stop dialog, not abandon dialog
      expect(find.text('Stop Simulation'), findsOneWidget);
      expect(find.text('End this simulation and return to the home screen?'),
          findsOneWidget);
      expect(find.text('Abandon game?'), findsNothing);
    });
  });
}
