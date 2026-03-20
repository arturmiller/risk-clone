import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as path;
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/log_entry.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/turn.dart';
import 'package:risk_mobile/objectbox.g.dart';
import 'package:risk_mobile/persistence/app_store.dart';
import 'package:risk_mobile/providers/game_log_provider.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/map_provider.dart';
import 'package:risk_mobile/providers/simulation_provider.dart';

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

MapGraph get _testMapGraph => MapGraph(
      MapData.fromJson(jsonDecode(_minimalMapJson) as Map<String, dynamic>));

/// Build a ProviderContainer with all necessary overrides.
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimulationNotifier', () {
    late Store store;
    late Directory tempDir;

    setUp(() {
      final name = 'sim_${DateTime.now().microsecondsSinceEpoch}';
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

    test('initial state is idle with speed=fast', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final simState = container.read(simulationProvider);
      expect(simState.status, equals(SimulationStatus.idle));
      expect(simState.speed, equals(SimulationSpeed.fast));
      expect(simState.turnCount, equals(0));
    });

    test('start() transitions status from idle to running', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      // Keep subscriptions alive
      final sub = container.listen(gameProvider, (_, __) {});
      final simSub = container.listen(simulationProvider, (_, __) {});
      addTearDown(sub.close);
      addTearDown(simSub.close);

      // Setup game first (caller responsibility)
      await container.read(gameProvider.future);
      await container.read(gameProvider.notifier).setupGame(
            const GameConfig(
              playerCount: 4,
              difficulty: Difficulty.easy,
              gameMode: GameMode.simulation,
            ),
          );
      await container.read(gameProvider.future);

      final notifier = container.read(simulationProvider.notifier);
      notifier.start(const GameConfig(
        playerCount: 4,
        difficulty: Difficulty.easy,
        gameMode: GameMode.simulation,
      ));

      // Give the loop a moment to start
      await Future.delayed(const Duration(milliseconds: 50));

      final simState = container.read(simulationProvider);
      // Should be running (or complete if instant game finished)
      expect(
        simState.status,
        anyOf(SimulationStatus.running, SimulationStatus.complete),
      );

      // Stop to clean up the loop
      notifier.stop();
    });

    test('pause() transitions from running to paused, resume() back to running',
        () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final sub = container.listen(gameProvider, (_, __) {});
      final simSub = container.listen(simulationProvider, (_, __) {});
      addTearDown(sub.close);
      addTearDown(simSub.close);

      await container.read(gameProvider.future);
      await container.read(gameProvider.notifier).setupGame(
            const GameConfig(
              playerCount: 4,
              difficulty: Difficulty.easy,
              gameMode: GameMode.simulation,
            ),
          );
      await container.read(gameProvider.future);

      final notifier = container.read(simulationProvider.notifier);
      notifier.start(const GameConfig(
        playerCount: 4,
        difficulty: Difficulty.easy,
        gameMode: GameMode.simulation,
      ));

      // Allow loop to begin
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.pause();
      expect(container.read(simulationProvider).status,
          equals(SimulationStatus.paused));

      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 50));

      final afterResume = container.read(simulationProvider);
      expect(
        afterResume.status,
        anyOf(SimulationStatus.running, SimulationStatus.complete),
      );

      notifier.stop();
    });

    test('stop() transitions to idle and clears game state', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final sub = container.listen(gameProvider, (_, __) {});
      final simSub = container.listen(simulationProvider, (_, __) {});
      addTearDown(sub.close);
      addTearDown(simSub.close);

      await container.read(gameProvider.future);
      await container.read(gameProvider.notifier).setupGame(
            const GameConfig(
              playerCount: 4,
              difficulty: Difficulty.easy,
              gameMode: GameMode.simulation,
            ),
          );
      await container.read(gameProvider.future);

      final notifier = container.read(simulationProvider.notifier);
      notifier.start(const GameConfig(
        playerCount: 4,
        difficulty: Difficulty.easy,
        gameMode: GameMode.simulation,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.stop();

      final simState = container.read(simulationProvider);
      expect(simState.status, equals(SimulationStatus.idle));
      expect(simState.turnCount, equals(0));

      // Game state should be cleared
      final gameState = await container.read(gameProvider.future);
      expect(gameState, isNull);
    });

    test('setSpeed(slow) updates speed to slow', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final notifier = container.read(simulationProvider.notifier);
      notifier.setSpeed(SimulationSpeed.slow);

      final simState = container.read(simulationProvider);
      expect(simState.speed, equals(SimulationSpeed.slow));
    });

    test('setSpeed(instant) updates speed to instant', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final notifier = container.read(simulationProvider.notifier);
      notifier.setSpeed(SimulationSpeed.instant);

      final simState = container.read(simulationProvider);
      expect(simState.speed, equals(SimulationSpeed.instant));
    });

    test('turn completion adds log entry to gameLogProvider', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final sub = container.listen(gameProvider, (_, __) {});
      final simSub = container.listen(simulationProvider, (_, __) {});
      final logSub = container.listen(gameLogProvider, (_, __) {});
      addTearDown(sub.close);
      addTearDown(simSub.close);
      addTearDown(logSub.close);

      await container.read(gameProvider.future);
      await container.read(gameProvider.notifier).setupGame(
            const GameConfig(
              playerCount: 4,
              difficulty: Difficulty.easy,
              gameMode: GameMode.simulation,
            ),
          );
      await container.read(gameProvider.future);

      final notifier = container.read(simulationProvider.notifier);
      // Use instant mode so the simulation completes and definitely logs
      notifier.setSpeed(SimulationSpeed.instant);
      notifier.start(const GameConfig(
        playerCount: 4,
        difficulty: Difficulty.easy,
        gameMode: GameMode.simulation,
      ));

      // Wait for instant mode to complete
      await Future.delayed(const Duration(seconds: 5));

      final logs = container.read(gameLogProvider);
      expect(logs, isNotEmpty,
          reason: 'At least one log entry should be created during simulation');
    });

    test('victory detection transitions status to complete', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final sub = container.listen(gameProvider, (_, __) {});
      final simSub = container.listen(simulationProvider, (_, __) {});
      addTearDown(sub.close);
      addTearDown(simSub.close);

      await container.read(gameProvider.future);
      await container.read(gameProvider.notifier).setupGame(
            const GameConfig(
              playerCount: 4,
              difficulty: Difficulty.easy,
              gameMode: GameMode.simulation,
            ),
          );
      await container.read(gameProvider.future);

      final notifier = container.read(simulationProvider.notifier);
      // Use instant mode so it runs to completion quickly
      notifier.setSpeed(SimulationSpeed.instant);
      notifier.start(const GameConfig(
        playerCount: 4,
        difficulty: Difficulty.easy,
        gameMode: GameMode.simulation,
      ));

      // Wait for instant mode to complete
      await Future.delayed(const Duration(seconds: 5));

      final simState = container.read(simulationProvider);
      expect(simState.status, equals(SimulationStatus.complete));
    });

    test('stop() during running stops the loop', () async {
      final container = _makeContainer(store);
      addTearDown(container.dispose);

      final sub = container.listen(gameProvider, (_, __) {});
      final simSub = container.listen(simulationProvider, (_, __) {});
      addTearDown(sub.close);
      addTearDown(simSub.close);

      await container.read(gameProvider.future);
      await container.read(gameProvider.notifier).setupGame(
            const GameConfig(
              playerCount: 4,
              difficulty: Difficulty.easy,
              gameMode: GameMode.simulation,
            ),
          );
      await container.read(gameProvider.future);

      final notifier = container.read(simulationProvider.notifier);
      // Use slow mode so we can stop before completion
      notifier.setSpeed(SimulationSpeed.slow);
      notifier.start(const GameConfig(
        playerCount: 4,
        difficulty: Difficulty.easy,
        gameMode: GameMode.simulation,
      ));

      // Wait for a turn then stop
      await Future.delayed(const Duration(milliseconds: 100));
      notifier.stop();

      final turnCountAfterStop = container.read(simulationProvider).turnCount;

      // Wait and verify no more turns are executed
      await Future.delayed(const Duration(milliseconds: 300));
      final turnCountLater = container.read(simulationProvider).turnCount;
      expect(turnCountLater, equals(turnCountAfterStop),
          reason: 'No more turns should execute after stop');
    });

    test('bot turn execution completes under 16ms average', () {
      // Direct engine test — no provider overhead, no Isolate
      final mapJson = File('assets/classic.json').readAsStringSync();
      final mapData =
          MapData.fromJson(jsonDecode(mapJson) as Map<String, dynamic>);
      final mapGraph = MapGraph(mapData);

      // Setup a 4-player game
      var state = _buildGameStateForPerf(mapGraph, 4);
      final agents = buildSimulationAgents(state, mapGraph, Difficulty.easy);
      final rng = Random(42);

      // Run 50 turns
      final sw = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        final (newState, _) = executeTurn(state, mapGraph, agents, rng);
        state = newState;
        // Advance to next alive player if needed
        if (checkVictory(state) != null) break;
      }
      sw.stop();

      final turnsRun = state.turnNumber;
      if (turnsRun > 0) {
        final avgMs = sw.elapsedMilliseconds / turnsRun;
        expect(avgMs, lessThan(16),
            reason: 'Average turn should complete under 16ms');
      }
    });
  });
}

/// Build a game state for performance testing on the full classic map.
GameState _buildGameStateForPerf(MapGraph mapGraph, int playerCount) {
  final territories = <String, TerritoryState>{};
  final allT = mapGraph.allTerritories;
  for (int i = 0; i < allT.length; i++) {
    territories[allT[i]] =
        TerritoryState(owner: i % playerCount, armies: 3);
  }

  final players = <PlayerState>[
    for (int i = 0; i < playerCount; i++)
      PlayerState(index: i, name: 'Bot ${i + 1}'),
  ];

  // Initialize cards
  final cards = <String, List<dynamic>>{
    for (int i = 0; i < playerCount; i++) i.toString(): <dynamic>[],
  };

  return GameState(
    territories: territories,
    players: players,
    cards: {},
  );
}
