import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../engine/map_graph.dart';
import '../engine/models/cards.dart';
import '../engine/models/game_state.dart';
import '../engine/models/ui_state.dart';

part 'ui_provider.g.dart';

@Riverpod(keepAlive: true)
class UIStateNotifier extends _$UIStateNotifier {
  @override
  UIState build() {
    debugPrint('[UI_STATE] build() called — resetting to empty!');
    return UIState.empty();
  }

  /// Select a territory and compute valid targets and sources for the current phase.
  void selectTerritory(String name, GameState gameState, MapGraph mapGraph) {
    final playerIndex = gameState.currentPlayerIndex;

    // Compute valid sources: territories owned by current player with ≥2 armies
    final validSources = gameState.territories.entries
        .where(
          (e) =>
              e.value.owner == playerIndex &&
              e.value.armies >= 2,
        )
        .map((e) => e.key)
        .toSet();

    // Compute valid targets based on turn phase
    Set<String> validTargets;
    switch (gameState.turnPhase) {
      case TurnPhase.reinforce:
        // No targeting needed in reinforce phase
        validTargets = {};
        break;
      case TurnPhase.attack:
        // Adjacent enemy territories reachable from source (source must have ≥2 armies)
        final sourceArmies = gameState.territories[name]?.armies ?? 0;
        if (sourceArmies >= 2) {
          validTargets = mapGraph
              .neighbors(name)
              .where((t) {
                final ts = gameState.territories[t];
                return ts != null && ts.owner != playerIndex;
              })
              .toSet();
        } else {
          validTargets = {};
        }
        break;
      case TurnPhase.fortify:
        // Friendly connected territories (BFS over friendly subgraph), excluding self
        final friendlyTerritories = gameState.territories.entries
            .where((e) => e.value.owner == playerIndex)
            .map((e) => e.key)
            .toSet();
        final connected =
            mapGraph.connectedTerritories(name, friendlyTerritories);
        connected.remove(name);
        validTargets = connected;
        break;
    }

    state = UIState(
      selectedTerritory: name,
      validTargets: validTargets,
      validSources: validSources,
    );
  }

  /// Select a target territory (second click during attack/fortify).
  void selectTarget(String name) {
    state = state.copyWith(selectedTarget: name);
  }

  /// Initialize reinforce phase with available armies to place.
  void initReinforce(int armies) {
    debugPrint('[UI_STATE] initReinforce($armies) — pendingArmies was ${state.pendingArmies}');
    state = state.copyWith(pendingArmies: armies, proposedPlacements: {});
    debugPrint('[UI_STATE] initReinforce done — pendingArmies now ${state.pendingArmies}');
  }

  /// Add one proposed army to the given territory (decrement pendingArmies).
  void addProposedArmy(String territory) {
    if (state.pendingArmies <= 0) return;
    final newMap = Map<String, int>.of(state.proposedPlacements);
    newMap[territory] = (newMap[territory] ?? 0) + 1;
    state = state.copyWith(
      pendingArmies: state.pendingArmies - 1,
      proposedPlacements: newMap,
    );
  }

  /// Set pending advance state after conquest.
  void setPendingAdvance(String source, String target, int min, int max) {
    state = state.copyWith(
      advanceSource: source,
      advanceTarget: target,
      advanceMin: min,
      advanceMax: max,
    );
  }

  /// Clear pending advance state.
  void clearPendingAdvance() {
    state = state.copyWith(
      advanceSource: null,
      advanceTarget: null,
      advanceMin: 0,
      advanceMax: 0,
    );
  }

  /// Reset selection state. Preserves reinforce data (pendingArmies, proposedPlacements).
  void clearSelection() {
    state = state.copyWith(
      selectedTerritory: null,
      validTargets: {},
      validSources: {},
    );
  }

  /// Full reset including reinforce state. Called on phase transitions.
  void resetAll() {
    state = UIState.empty();
  }
}
