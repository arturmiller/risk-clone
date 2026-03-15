/// Fortification logic for Risk: path validation and army movement.
/// Pure Dart port of risk/engine/fortify.py.
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'actions.dart';
import 'map_graph.dart';
import 'models/game_state.dart';

/// Validate a fortification action. Throws ArgumentError on invalid move.
void validateFortify(
  GameState state,
  MapGraph mapGraph,
  FortifyAction action,
  int playerIndex,
) {
  final sourceTs = state.territories[action.source];
  if (sourceTs == null) {
    throw ArgumentError("Source territory '${action.source}' not found");
  }

  final targetTs = state.territories[action.target];
  if (targetTs == null) {
    throw ArgumentError("Target territory '${action.target}' not found");
  }

  if (sourceTs.owner != playerIndex) {
    throw ArgumentError(
      "Player $playerIndex does not own source territory '${action.source}'",
    );
  }

  if (targetTs.owner != playerIndex) {
    throw ArgumentError(
      "Player $playerIndex does not own target territory '${action.target}'",
    );
  }

  // Check connected path through friendly territories
  final playerTerritories = state.territories.entries
      .where((e) => e.value.owner == playerIndex)
      .map((e) => e.key)
      .toSet();

  final reachable = mapGraph.connectedTerritories(action.source, playerTerritories);
  if (!reachable.contains(action.target)) {
    throw ArgumentError(
      "Target '${action.target}' is not reachable from source "
      "'${action.source}' through connected friendly path",
    );
  }

  // Must leave at least 1 army on source
  if (action.armies > sourceTs.armies - 1) {
    throw ArgumentError(
      "Cannot move ${action.armies} armies from '${action.source}' "
      "which has ${sourceTs.armies} (must leave at least 1)",
    );
  }
}

/// Execute a fortification: move armies from source to target.
///
/// Calls validateFortify first — throws on invalid move.
GameState executeFortify(
  GameState state,
  MapGraph mapGraph,
  FortifyAction action,
  int playerIndex,
) {
  validateFortify(state, mapGraph, action, playerIndex);

  final sourceTs = state.territories[action.source]!;
  final targetTs = state.territories[action.target]!;

  final newTerr = Map<String, TerritoryState>.of(state.territories);
  newTerr[action.source] = TerritoryState(
    owner: sourceTs.owner,
    armies: sourceTs.armies - action.armies,
  );
  newTerr[action.target] = TerritoryState(
    owner: targetTs.owner,
    armies: targetTs.armies + action.armies,
  );

  return state.copyWith(territories: newTerr);
}
