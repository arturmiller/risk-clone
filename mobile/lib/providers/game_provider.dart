import 'dart:async';
import 'dart:convert';
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
import '../engine/reinforcements.dart';
import '../engine/map_graph.dart';
import '../engine/models/cards.dart';
import '../engine/models/game_config.dart';
import '../engine/models/game_state.dart';
import '../engine/setup.dart' as engine_setup;
import '../utils/compute.dart';
import '../engine/turn.dart';
import '../persistence/app_store.dart';
import '../persistence/persistence.dart' as persistence;
import 'game_log_provider.dart';
import 'map_provider.dart';
import 'ui_provider.dart';

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

    // Try to restore saved game
    final store = ref.read(storeProvider);
    final json = persistence.loadGameState(store);
    if (json == null) return null;
    return GameState.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// Save current state. Called on app lifecycle hide.
  Future<void> _saveState() async {
    final current = state.value;
    if (current == null) return;

    final store = ref.read(storeProvider);
    persistence.saveGameState(
      store,
      jsonEncode(current.toJson()),
      current.turnNumber,
    );
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
    debugPrint('[runBotTurn] called, _processing=$_processing');
    if (_processing) return;
    final current = state.value;
    if (current == null) return;

    _processing = true;
    try {
      debugPrint('[runBotTurn] executing turn for player ${current.currentPlayerIndex}');
      // Read mapGraph BEFORE entering Isolate.run
      final mapGraph = await ref.read(mapGraphProvider.future);
      final config = _gameConfig;

      final newState = await runCompute(() {
        final agents = _buildAgents(current, mapGraph, config);
        final (nextState, _) = executeTurn(current, mapGraph, agents, Random());
        return nextState;
      });

      // Guard against provider disposal during async gap
      if (ref.mounted) {
        debugPrint('[runBotTurn] done, next player=${newState.currentPlayerIndex} phase=${newState.turnPhase}');
        state = AsyncData(newState);
        _advanceTurnIfBot();
      }
    } finally {
      _processing = false;
    }
  }

  /// Direct state update for simulation mode (no save, no bot advance).
  void updateState(GameState newState) {
    state = AsyncData(newState);
  }

  /// Clear saved game data and reset to null game state.
  Future<void> clearSave() async {
    final store = ref.read(storeProvider);
    persistence.clearGameState(store);
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
    debugPrint('[humanMove] action=$action processing=$_processing');
    if (_processing) {
      debugPrint('[humanMove] BLOCKED: _processing is true');
      return;
    }
    final current = state.value;
    if (current == null) {
      debugPrint('[humanMove] BLOCKED: state is null');
      return;
    }
    if (!_isHumanTurn(current)) {
      debugPrint('[humanMove] BLOCKED: not human turn (player=${current.currentPlayerIndex})');
      return;
    }
    debugPrint('[humanMove] proceeding: phase=${current.turnPhase} player=${current.currentPlayerIndex}');

    _processing = true;
    try {
      final mapGraph = await ref.read(mapGraphProvider.future);
      final log = ref.read(gameLogProvider.notifier);

      GameState newState;
      try {
      switch (current.turnPhase) {
        case TurnPhase.reinforce:
          if (action is TradeCardsAction) {
            // Trade cards for bonus armies during reinforce
            final hand = current.cards['0'] ?? [];
            final cardIndices = action.cards
                .map((c) => hand.indexWhere((h) =>
                    h.cardType == c.cardType && h.territory == c.territory))
                .toList();
            final (newS, bonus, territoryBonus) =
                executeTrade(current, 0, cardIndices);
            // Apply territory bonus (2 extra armies on owned traded territories)
            var traded = newS;
            for (final entry in territoryBonus.entries) {
              final ts = traded.territories[entry.key]!;
              final newT = Map<String, TerritoryState>.of(traded.territories);
              newT[entry.key] = TerritoryState(owner: ts.owner, armies: ts.armies + entry.value);
              traded = traded.copyWith(territories: newT);
            }
            newState = traded;
            // Add trade bonus to current pending armies
            final currentPending = ref.read(uIStateProvider).pendingArmies;
            ref.read(uIStateProvider.notifier).initReinforce(currentPending + bonus);
            log.add('Traded cards for +$bonus armies.');
            // Stay in reinforce — don't advance phase
            break;
          }
          final placement = action as ReinforcePlacementAction;
          // Apply placements directly (card trades already handled separately)
          final placed = placement.placements.values.fold(0, (a, b) => a + b);
          final expected = ref.read(uIStateProvider).pendingArmies +
              placement.placements.values.fold(0, (a, b) => a + b);
          // Validate: all placed armies should match what UI tracked
          if (placed == 0) {
            throw ArgumentError('Must place armies, got 0');
          }
          final newTerritories = Map<String, TerritoryState>.of(current.territories);
          for (final entry in placement.placements.entries) {
            final ts = newTerritories[entry.key]!;
            if (ts.owner != 0) {
              throw ArgumentError('Cannot place on enemy territory ${entry.key}');
            }
            newTerritories[entry.key] = TerritoryState(
              owner: ts.owner,
              armies: ts.armies + entry.value,
            );
          }
          newState = current.copyWith(
            territories: newTerritories,
            turnPhase: TurnPhase.attack,
          );
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
            var afterConquest = conquered ? s.copyWith(conqueredThisTurn: true) : s;
            if (conquered) {
              afterConquest = _checkEliminations(afterConquest, 0, log);
              log.add('Blitz! You conquered ${action.target}.');
              final sourceArmies = afterConquest.territories[action.source]!.armies;
              final targetArmies = afterConquest.territories[action.target]!.armies;
              ref.read(uIStateProvider.notifier).setPendingAdvance(
                action.source,
                action.target,
                targetArmies,
                targetArmies + (sourceArmies > 1 ? sourceArmies - 1 : 0),
              );
            }
            newState = afterConquest;
          } else if (action is AttackAction) {
            // Execute attack — default moves numDice armies on conquest
            final (s, _, conquered) =
                executeAttack(current, mapGraph, action, 0, Random());
            if (conquered) {
              var afterConquest = _checkEliminations(
                  s.copyWith(conqueredThisTurn: true), 0, log);
              newState = afterConquest;
              log.add('You conquered ${action.target}!');
              // Always show advance panel so the user sees the conquest result
              final sourceArmies = s.territories[action.source]!.armies;
              final movedAlready = action.numDice;
              final maxExtra = sourceArmies > 1 ? sourceArmies - 1 : 0;
              ref.read(uIStateProvider.notifier).setPendingAdvance(
                action.source,
                action.target,
                movedAlready,
                movedAlready + maxExtra,
              );
            } else {
              newState = s;
            }
          } else if (action is AdvanceArmiesAction) {
            // Move additional armies after conquest
            final src = current.territories[action.source]!;
            final tgt = current.territories[action.target]!;
            final extraToMove = action.armies;
            if (extraToMove > 0 && src.armies > extraToMove) {
              final newTerritories =
                  Map<String, TerritoryState>.of(current.territories);
              newTerritories[action.source] =
                  TerritoryState(owner: src.owner, armies: src.armies - extraToMove);
              newTerritories[action.target] =
                  TerritoryState(owner: tgt.owner, armies: tgt.armies + extraToMove);
              newState = current.copyWith(territories: newTerritories);
            } else {
              newState = current;
            }
            ref.read(uIStateProvider.notifier).clearPendingAdvance();
            // Select conquered territory as source for chaining attacks
            final afterAdvance = newState;
            ref.read(uIStateProvider.notifier).selectTerritory(
              action.target, afterAdvance, mapGraph);
            log.add('Moved ${action.armies} extra armies to ${action.target}.');
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

      } on ArgumentError catch (e) {
        // Invalid action (stale UI state) — log and ignore
        debugPrint('[humanMove] Invalid action ignored: $e');
        return;
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

  /// Check if any opponent was eliminated after a human conquest.
  /// Marks them dead and transfers their cards.
  GameState _checkEliminations(GameState s, int playerIndex, dynamic log) {
    for (final p in s.players) {
      if (p.index == playerIndex || !p.isAlive) continue;
      if (checkElimination(s, p.index)) {
        final newPlayers = List<PlayerState>.of(s.players);
        newPlayers[p.index] = PlayerState(
          index: p.index,
          name: p.name,
          isAlive: false,
        );
        s = s.copyWith(players: newPlayers);
        s = transferCards(s, p.index, playerIndex);
        log.add('${p.name} eliminated!');
      }
    }
    return s;
  }

  /// If the current player is a bot (not player 0), trigger runBotTurn().
  /// Called automatically after humanMove() advances to the next player.
  /// Stops if game is over (human eliminated or only one player alive).
  void _advanceTurnIfBot() {
    final current = state.value;
    if (current == null) return;
    // Stop bot loop if game is over
    final alive = current.players.where((p) => p.isAlive).toList();
    if (alive.length <= 1 || !current.players[0].isAlive) return;
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
