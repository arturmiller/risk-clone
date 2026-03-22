import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../bots/easy_agent.dart';
import '../bots/hard_agent.dart';
import '../bots/medium_agent.dart';
import '../bots/player_agent.dart';
import '../engine/map_graph.dart';
import '../engine/models/game_config.dart';
import '../engine/models/game_state.dart';
import '../engine/simulation.dart';
import '../engine/turn.dart';
import '../utils/compute.dart';
import 'game_log_provider.dart';
import 'game_provider.dart';
import 'map_provider.dart';

part 'simulation_provider.g.dart';

/// Speed presets for the simulation loop.
enum SimulationSpeed {
  /// 1000ms delay between turns.
  slow,

  /// 200ms delay between turns.
  fast,

  /// Batch all turns in a single isolate — no per-turn delay.
  instant,
}

/// Lifecycle status for the simulation.
enum SimulationStatus {
  idle,
  running,
  paused,
  complete,
}

/// Ephemeral state for the simulation loop. Not persisted.
class SimulationState {
  final SimulationStatus status;
  final SimulationSpeed speed;
  final int turnCount;
  final String? error;

  const SimulationState({
    this.status = SimulationStatus.idle,
    this.speed = SimulationSpeed.fast,
    this.turnCount = 0,
    this.error,
  });

  SimulationState copyWith({
    SimulationStatus? status,
    SimulationSpeed? speed,
    int? turnCount,
    String? error,
  }) {
    return SimulationState(
      status: status ?? this.status,
      speed: speed ?? this.speed,
      turnCount: turnCount ?? this.turnCount,
      error: error ?? this.error,
    );
  }
}

/// Build all-bot agents for simulation mode. All players use the same difficulty.
/// Top-level function for Isolate.run() compatibility.
Map<int, PlayerAgent> buildSimulationAgents(
  GameState state,
  MapGraph mapGraph,
  Difficulty difficulty,
) {
  return {
    for (int i = 0; i < state.players.length; i++)
      i: _makeBot(difficulty, mapGraph),
  };
}

PlayerAgent _makeBot(Difficulty d, MapGraph mg) => switch (d) {
      Difficulty.easy => EasyAgent(mapGraph: mg),
      Difficulty.medium => MediumAgent(mapGraph: mg),
      Difficulty.hard => HardAgent(mapGraph: mg),
    };

@Riverpod(keepAlive: true)
class SimulationNotifier extends _$SimulationNotifier {
  GameConfig? _config;

  @override
  SimulationState build() => const SimulationState();

  /// Start the simulation loop. Caller must have already called
  /// gameProvider.notifier.setupGame() before calling this.
  void start(GameConfig config) {
    if (state.status == SimulationStatus.running) return;
    _config = config;
    state = state.copyWith(status: SimulationStatus.running, turnCount: 0);
    _runLoop();
  }

  /// Pause the simulation. The loop checks status each iteration.
  void pause() {
    if (state.status != SimulationStatus.running) return;
    state = state.copyWith(status: SimulationStatus.paused);
  }

  /// Resume the simulation after pause.
  void resume() {
    if (state.status != SimulationStatus.paused) return;
    state = state.copyWith(status: SimulationStatus.running);
    _runLoop();
  }

  /// Stop the simulation and clear game state.
  void stop() {
    state = const SimulationState(); // reset to idle defaults
    _config = null;
    ref.read(gameProvider.notifier).clearSave();
    ref.read(gameLogProvider.notifier).clear();
  }

  /// Update the simulation speed.
  void setSpeed(SimulationSpeed speed) {
    state = state.copyWith(speed: speed);
  }

  /// Main simulation loop. Runs turns until paused, stopped, or victory.
  Future<void> _runLoop() async {
    while (state.status == SimulationStatus.running) {
      if (state.speed == SimulationSpeed.instant) {
        await _runInstant();
        return;
      }

      // Read current game state
      final current = ref.read(gameProvider).value;
      if (current == null) return;

      // Check victory before executing next turn
      final winner = checkVictory(current);
      if (winner != null) {
        final playerName = current.players[winner].name;
        ref.read(gameLogProvider.notifier).add(
              'Simulation Complete: $playerName wins!',
            );
        state = state.copyWith(status: SimulationStatus.complete);
        return;
      }

      // Execute one turn in an isolate
      final mapGraph = await ref.read(mapGraphProvider.future);
      if (!ref.mounted) return;
      if (state.status != SimulationStatus.running) return;

      final difficulty = _config?.difficulty ?? Difficulty.easy;
      final turnNumber = state.turnCount;

      final sw = Stopwatch()..start();
      final newState = await runCompute(() {
        final agents = buildSimulationAgents(current, mapGraph, difficulty);
        final (nextState, _) = executeTurn(current, mapGraph, agents, Random());
        return nextState;
      });
      sw.stop();

      if (!ref.mounted) return;
      if (state.status != SimulationStatus.running) return;

      // Update game state
      ref.read(gameProvider.notifier).updateState(newState);

      // Generate rich log by diffing before/after state
      final playerIdx = current.currentPlayerIndex;
      final playerName = current.players[playerIdx].name;
      final log = ref.read(gameLogProvider.notifier);

      // Count territories before and after
      final oldCount = current.territories.values.where((t) => t.owner == playerIdx).length;
      final newCount = newState.territories.values.where((t) => t.owner == playerIdx).length;
      final conquered = newCount - oldCount;

      // Count total armies before and after
      final oldArmies = current.territories.values.where((t) => t.owner == playerIdx).fold(0, (a, t) => a + t.armies);
      final newArmies = newState.territories.values.where((t) => t.owner == playerIdx).fold(0, (a, t) => a + t.armies);

      // Check which players were eliminated
      final eliminated = <String>[];
      for (final p in newState.players) {
        if (p.isAlive) continue;
        if (current.players[p.index].isAlive) {
          eliminated.add(p.name);
        }
      }

      // Build log message
      final parts = <String>['T${turnNumber + 1} $playerName:'];
      if (conquered > 0) {
        parts.add('+$conquered territory${conquered > 1 ? 's' : ''}');
      } else if (conquered < 0) {
        parts.add('${conquered} territory${conquered < -1 ? 's' : ''}');
      }
      parts.add('${newCount} terr, ${newArmies} armies');
      if (eliminated.isNotEmpty) {
        parts.add('eliminated ${eliminated.join(', ')}!');
      }
      log.add(parts.join(' | '));

      state = state.copyWith(turnCount: turnNumber + 1);

      // Delay based on speed
      final delayMs = state.speed == SimulationSpeed.slow ? 1000 : 200;
      await Future.delayed(Duration(milliseconds: delayMs));

      if (!ref.mounted) return;
      // Loop continues — status check is at top of while
    }
  }

  /// Run the entire game in a single isolate (Instant mode).
  Future<void> _runInstant() async {
    final current = ref.read(gameProvider).value;
    if (current == null) return;

    final mapGraph = await ref.read(mapGraphProvider.future);
    if (!ref.mounted) return;
    if (state.status != SimulationStatus.running) return;

    final difficulty = _config?.difficulty ?? Difficulty.easy;

    final sw = Stopwatch()..start();
    final finalState = await runCompute(() {
      final agents =
          buildSimulationAgents(current, mapGraph, difficulty);
      return runGame(mapGraph, agents, Random());
    });
    sw.stop();

    if (!ref.mounted) return;

    // Update game state with final result
    ref.read(gameProvider.notifier).updateState(finalState);

    // Determine winner and turn count
    final winner = checkVictory(finalState);
    final turnCount = finalState.turnNumber;
    final totalMs = sw.elapsedMilliseconds;
    final avgMs = turnCount > 0
        ? (totalMs / turnCount).toStringAsFixed(1)
        : '0.0';

    final winnerName =
        winner != null ? finalState.players[winner].name : 'Unknown';

    ref.read(gameLogProvider.notifier).add(
          'Instant complete: ${totalMs}ms total, ${avgMs}ms/turn avg',
        );
    ref.read(gameLogProvider.notifier).add(
          'Simulation Complete (Instant): $winnerName wins! ($turnCount turns, ${avgMs}ms/turn)',
        );

    state = state.copyWith(
      status: SimulationStatus.complete,
      turnCount: turnCount,
    );
  }
}
