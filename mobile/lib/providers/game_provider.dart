import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../bots/easy_agent.dart';
import '../bots/hard_agent.dart';
import '../bots/medium_agent.dart';
import '../bots/player_agent.dart';
import '../engine/map_graph.dart';
import '../engine/models/game_config.dart';
import '../engine/models/game_state.dart';
import '../engine/setup.dart' as engine_setup;
import '../engine/turn.dart';
import '../persistence/app_store.dart';
import '../persistence/save_slot.dart';
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

      state = AsyncData(newState);
    } finally {
      _processing = false;
    }
  }

  /// Clear the save slot and reset to null game state.
  Future<void> clearSave() async {
    final store = ref.read(storeProvider);
    store.box<SaveSlot>().removeAll();
    state = const AsyncData(null);
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
