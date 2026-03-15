import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as path;
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/objectbox.g.dart';
import 'package:risk_mobile/persistence/app_store.dart';
import 'package:risk_mobile/persistence/save_slot.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/map_provider.dart';

/// Minimal 6-territory map sufficient for setupGame() with 2 players.
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

MapGraph get _testMapGraph =>
    MapGraph(MapData.fromJson(jsonDecode(_minimalMapJson) as Map<String, dynamic>));

/// Create a temporary ObjectBox store for testing.
Store _createTempStore(String testName) {
  final tempDir = Directory(
    path.join(Directory.systemTemp.path, 'obx_test_${testName}_${DateTime.now().microsecondsSinceEpoch}'),
  );
  tempDir.createSync(recursive: true);
  return Store(getObjectBoxModel(), directory: tempDir.path);
}

/// Build a ProviderContainer with storeProvider and mapGraphProvider overridden.
ProviderContainer _makeContainer(Store store, {MapGraph? mapGraph}) {
  final graph = mapGraph ?? _testMapGraph;
  return ProviderContainer(
    overrides: [
      storeProvider.overrideWithValue(store),
      mapGraphProvider.overrideWith((ref) => Future.value(graph)),
    ],
  );
}

void main() {
  // AppLifecycleListener requires WidgetsBinding to be initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameNotifier', () {
    late Store store;
    late Directory tempDir;

    setUp(() {
      final name = 'game_${DateTime.now().microsecondsSinceEpoch}';
      tempDir = Directory(
        path.join(Directory.systemTemp.path, 'obx_test_$name'),
      );
      tempDir.createSync(recursive: true);
      store = Store(getObjectBoxModel(), directory: tempDir.path);
    });

    tearDown(() {
      store.close();
      tempDir.deleteSync(recursive: true);
    });

    test('build returns null when no save slot exists', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final result = await container.read(gameProvider.future);
      expect(result, isNull);
    });

    test('build restores GameState when save slot exists', () async {
      // Arrange: pre-populate the store with a save slot
      final map = _testMapGraph;
      final initialState = _buildMinimalGameState(map);
      final json = jsonEncode(initialState.toJson());
      final slot = SaveSlot(
        gameStateJson: json,
        turnNumber: initialState.turnNumber,
        timestamp: '2026-01-01T00:00:00Z',
      );
      store.box<SaveSlot>().put(slot);

      final container = _makeContainer(store, mapGraph: map);
      addTearDown(container.dispose);

      final result = await container.read(gameProvider.future);
      expect(result, isNotNull);
      expect(result!.players.length, equals(2));
    });

    test('setupGame transitions to AsyncData with non-null state', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      // Ensure build completes first
      await container.read(gameProvider.future);

      final notifier = container.read(gameProvider.notifier);
      await notifier.setupGame(
        const GameConfig(playerCount: 2, difficulty: Difficulty.easy),
      );

      final gameState = await container.read(gameProvider.future);
      expect(gameState, isNotNull);
      expect(gameState!.players.length, equals(2));
    });

    test('runBotTurn updates state after bot executes', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      // Keep a subscription alive to prevent auto-disposal during Isolate.run
      final sub = container.listen(gameProvider, (prev, next) {});
      addTearDown(sub.close);

      await container.read(gameProvider.future);
      final notifier = container.read(gameProvider.notifier);

      await notifier.setupGame(
        const GameConfig(playerCount: 2, difficulty: Difficulty.easy),
      );
      final stateBeforeTurn = await container.read(gameProvider.future);
      expect(stateBeforeTurn, isNotNull);

      await notifier.runBotTurn();

      final stateAfterTurn = await container.read(gameProvider.future);
      // State should still be a valid GameState after one bot turn
      expect(stateAfterTurn, isNotNull);
    });

    test('saveNow writes to ObjectBox when state is non-null', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      await container.read(gameProvider.future);
      final notifier = container.read(gameProvider.notifier);
      await notifier.setupGame(
        const GameConfig(playerCount: 2, difficulty: Difficulty.easy),
      );
      await container.read(gameProvider.future);

      // Trigger save via the public test seam
      await notifier.saveNow();

      final slots = store.box<SaveSlot>().getAll();
      expect(slots, isNotEmpty);
      expect(slots.first.gameStateJson, isNotEmpty);
      expect(slots.first.turnNumber, isA<int>());
    });

    test('saveNow does nothing when state is null', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      // No setupGame called — state.value is null
      await container.read(gameProvider.future);
      final notifier = container.read(gameProvider.notifier);

      await notifier.saveNow();

      final slots = store.box<SaveSlot>().getAll();
      expect(slots, isEmpty);
    });

    test('clearSave sets state to AsyncData(null)', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      await container.read(gameProvider.future);
      final notifier = container.read(gameProvider.notifier);

      await notifier.setupGame(
        const GameConfig(playerCount: 2, difficulty: Difficulty.easy),
      );
      await container.read(gameProvider.future);

      await notifier.clearSave();

      final result = await container.read(gameProvider.future);
      expect(result, isNull);
    });
  });
}

/// Build a minimal valid GameState for a 2-player game on the test map.
GameState _buildMinimalGameState(MapGraph map) {
  final territories = <String, TerritoryState>{};
  final allT = map.allTerritories;
  for (int i = 0; i < allT.length; i++) {
    territories[allT[i]] = TerritoryState(owner: i % 2, armies: 3);
  }
  return GameState(
    territories: territories,
    players: [
      const PlayerState(index: 0, name: 'Player 1'),
      const PlayerState(index: 1, name: 'Player 2'),
    ],
  );
}
