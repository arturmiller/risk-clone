import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../engine/map_graph.dart';
import '../engine/models/cards.dart';
import '../engine/models/game_state.dart';
import '../engine/models/ui_state.dart';

part 'ui_provider.g.dart';

@riverpod
class UIStateNotifier extends _$UIStateNotifier {
  @override
  UIState build() {
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

  /// Reset selection state.
  void clearSelection() {
    state = UIState.empty();
  }
}
