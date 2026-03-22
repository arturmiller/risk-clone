import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as p;

import 'package:risk_mobile/objectbox.g.dart';
import 'package:risk_mobile/persistence/app_store.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/map_provider.dart';
import 'package:risk_mobile/providers/ui_provider.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/screens/game_screen.dart';

const String _minimalMapJson = '''
{
  "name": "Test",
  "territories": ["T1", "T2", "T3", "T4", "T5", "T6"],
  "continents": [
    {"name": "C1", "bonus": 1, "territories": ["T1", "T2", "T3"]},
    {"name": "C2", "bonus": 1, "territories": ["T4", "T5", "T6"]}
  ],
  "adjacencies": [
    ["T1", "T2"], ["T2", "T3"], ["T3", "T4"],
    ["T4", "T5"], ["T5", "T6"], ["T6", "T1"]
  ]
}
''';

MapGraph get _testMapGraph => MapGraph(
    MapData.fromJson(jsonDecode(_minimalMapJson) as Map<String, dynamic>));

/// GameState: player 0 in reinforce phase with 3 owned territories
GameState _makeReinforceState() {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reinforce flow', () {
    late Store store;
    late Directory tempDir;

    setUp(() {
      final name = 'reinforce_${DateTime.now().microsecondsSinceEpoch}';
      tempDir = Directory(p.join(Directory.systemTemp.path, 'obx_test_$name'));
      tempDir.createSync(recursive: true);
      store = Store(getObjectBoxModel(), directory: tempDir.path);
    });

    tearDown(() {
      store.close();
      tempDir.deleteSync(recursive: true);
    });

    testWidgets('initReinforce is called on initial game load', (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            mapGraphProvider
                .overrideWith((ref) => Future.value(_testMapGraph)),
            gameProvider.overrideWith(
                () => _FakeGameNotifier(fakeState: _makeReinforceState())),
          ],
          child: Builder(builder: (context) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(home: const GameScreen());
          }),
        ),
      );

      // First pump: widget tree builds, listener is registered
      await tester.pump();
      // Second pump: post-frame callback fires
      await tester.pump();
      // Third pump: async mapGraphProvider.future resolves, initReinforce called
      await tester.pump();
      // Extra settle for any remaining microtasks
      await tester.pumpAndSettle();

      final uiState = container.read(uIStateProvider);

      // Player 0 owns 3 territories + continent C1 bonus
      expect(uiState.pendingArmies, greaterThan(0),
          reason: 'initReinforce should set pendingArmies > 0');
    });

    testWidgets('pendingArmies shows in action panel text', (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            mapGraphProvider
                .overrideWith((ref) => Future.value(_testMapGraph)),
            gameProvider.overrideWith(
                () => _FakeGameNotifier(fakeState: _makeReinforceState())),
          ],
          child: const MaterialApp(home: GameScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Should show "Armies to place: 3"
      expect(find.textContaining('Armies to place:'), findsOneWidget);
    });
  });
}
