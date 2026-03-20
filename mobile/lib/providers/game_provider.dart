import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../bots/easy_agent.dart';
import '../bots/hard_agent.dart';
import '../bots/human_agent.dart';
import '../bots/medium_agent.dart';
import '../bots/player_agent.dart';
import '../engine/actions.dart';
import '../engine/cards_engine.dart';
import '../engine/combat.dart';
import '../engine/map_graph.dart';
import '../engine/models/cards.dart';
import '../engine/models/game_config.dart';
import '../engine/models/game_state.dart';
import '../engine/setup.dart' as engine_setup;
import '../engine/turn.dart';
import '../persistence/app_store.dart';
import '../persistence/save_slot.dart';
import 'game_log_provider.dart';
import 'map_provider.dart';

part 'game_provider.g.dart';

@riverpod
class GameNotifier extends _$GameNotifier {
  AppLifecycleListener? _lifecycleListener;
  bool _processing = false;
  GameConfig? _gameConfig;

  @override
  Future<GameState?> build() async {
    // Register lifecycle listener to save on app hide
    _lifecycleListener = AppLifecycleListener(
      onHide: _saveState,
    );
    ref.onDispose(() {
      _lifecycleListener?.dispose();
    });

    // Try to restore from ObjectBox
    final store = ref.read(storeProvider);
    final box = store.box<SaveSlot>();
    final slots = box.getAll();
    if (slots.isEmpty) {
      return null;
    }
    final slot = slots.first;
    return GameState.fromJson(
      jsonDecode(slot.gameStateJson) as Map<String, dynamic>,
    );
  }

  /// Save current state to ObjectBox. Called on app lifecycle hide.
  Future<void> _saveState() async {
    final current = state.value;
    if (current == null) return;

    final store = ref.read(storeProvider);
    final box = store.box<SaveSlot>();
    final existing = box.getAll();

    final slot = existing.isNotEmpty
        ? existing.first
        : SaveSlot();

    slot.gameStateJson = jsonEncode(current.toJson());
    slot.turnNumber = current.turnNumber;
    slot.timestamp = DateTime.now().toIso8601String();

    box.put(slot);
  }

  /// Public seam for testing: directly triggers the save.
  Future<void> saveNow() => _saveState();

  /// Set up a new game from config.
  Future<void> setupGame(GameConfig config) async {
    _gameConfig = config;
    state = const AsyncLoading();
    final mapGraph = await ref.read(mapGraphProvider.future);
    state = await AsyncValue.guard(() async {
      return engine_setup.setupGame(mapGraph, config.playerCount, rng: Random());
    });
  }

  /// Run one bot turn in an Isolate.
  Future<void> runBotTurn() async {
    if (_processing) return;
    final current = state.value;
    if (current == null) return;

    _processing = true;
    try {
      // Read mapGraph BEFORE entering Isolate.run
      final mapGraph = await ref.read(mapGraphProvider.future);
      final config = _gameConfig;

      final newState = await Isolate.run(() {
        final agents = _buildAgents(current, mapGraph, config);
        final (nextState, _) = executeTurn(current, mapGraph, agents, Random());
        return nextState;
      });

      // Guard against provider disposal during async gap
      if (ref.mounted) {
        state = AsyncData(newState);
      }
    } finally {
      _processing = false;
    }
  }

  /// Direct state update for simulation mode (no save, no bot advance).
  void updateState(GameState newState) {
    state = AsyncData(newState);
  }

  /// Clear the save slot and reset to null game state.
  Future<void> clearSave() async {
    final store = ref.read(storeProvider);
    store.box<SaveSlot>().removeAll();
    state = const AsyncData(null);
  }

  /// Whether the current player (player 0) is a human.
  bool _isHumanTurn(GameState gs) => gs.currentPlayerIndex == 0;

  /// Execute a single human action for the current turn phase.
  ///
  /// For reinforce: pass ReinforcePlacementAction.
  /// For attack: pass AttackAction, BlitzAction, or null (end attacks).
  /// For fortify: pass FortifyAction or null (skip).
  /// Never enters Isolate.run() — executes on main isolate.
  Future<void> humanMove(Object? action) async {
    if (_processing) return;
    final current = state.value;
    if (current == null) return;
    if (!_isHumanTurn(current)) return;

    _processing = true;
    try {
      final mapGraph = await ref.read(mapGraphProvider.future);
      final log = ref.read(gameLogProvider.notifier);

      GameState newState;
      switch (current.turnPhase) {
        case TurnPhase.reinforce:
          final placement = action as ReinforcePlacementAction;
          newState = executeReinforcePhase(
              current, mapGraph, HumanAgent.reinforce(placement), 0);
          log.add('You placed armies.');

        case TurnPhase.attack:
          if (action == null) {
            // End attack — draw card if conquered, transition to fortify
            GameState s = current;
            if (s.conqueredThisTurn) s = drawCard(s, 0);
            newState = s.copyWith(turnPhase: TurnPhase.fortify);
            log.add('You ended your attack.');
          } else if (action is BlitzAction) {
            final (s, _, conquered) =
                executeBlitz(current, mapGraph, action, 0, Random());
            newState = conquered ? s.copyWith(conqueredThisTurn: true) : s;
            if (conquered) log.add('Blitz! You conquered ${action.target}.');
          } else if (action is AttackAction) {
            final (s, _, conquered) =
                executeAttack(current, mapGraph, action, 0, Random());
            newState = conquered ? s.copyWith(conqueredThisTurn: true) : s;
            if (conquered) log.add('You conquered ${action.target}!');
          } else {
            return;
          }

        case TurnPhase.fortify:
          final fortifyAction = action as FortifyAction?;
          final agent = fortifyAction != null
              ? HumanAgent.fortify(fortifyAction)
              : const HumanAgent.skipFortify();
          GameState s = executeFortifyPhase(current, mapGraph, agent, 0);
          // Advance to next player
          final nextPlayer = nextAlivePlayer(s);
          newState = s.copyWith(
            currentPlayerIndex: nextPlayer,
            turnNumber: s.turnNumber + 1,
            conqueredThisTurn: false,
            turnPhase: TurnPhase.reinforce,
          );
          log.add('Turn ${newState.turnNumber}: next player.');
      }

      if (ref.mounted) {
        state = AsyncData(newState);
        _saveState();
        _advanceTurnIfBot();
      }
    } finally {
      _processing = false;
    }
  }

  /// If the current player is a bot (not player 0), trigger runBotTurn().
  /// Called automatically after humanMove() advances to the next player.
  void _advanceTurnIfBot() {
    final current = state.value;
    if (current == null) return;
    if (!_isHumanTurn(current)) {
      // Use Future.microtask to avoid nested state mutations
      Future.microtask(runBotTurn);
    }
  }
}

/// Build agent map outside the class so Isolate.run can capture it cleanly.
Map<int, PlayerAgent> _buildAgents(
  GameState state,
  MapGraph mapGraph,
  GameConfig? config,
) {
  return {
    for (int i = 0; i < state.players.length; i++)
      i: _makeAgentForIndex(i, mapGraph, config),
  };
}

PlayerAgent _makeAgentForIndex(
  int playerIndex,
  MapGraph mapGraph,
  GameConfig? config,
) {
  if (playerIndex == 0) {
    return EasyAgent(mapGraph: mapGraph);
  }
  final difficulty = config?.difficulty ?? Difficulty.easy;
  switch (difficulty) {
    case Difficulty.easy:
      return EasyAgent(mapGraph: mapGraph);
    case Difficulty.medium:
      return MediumAgent(mapGraph: mapGraph);
    case Difficulty.hard:
      return HardAgent(mapGraph: mapGraph);
  }
}
