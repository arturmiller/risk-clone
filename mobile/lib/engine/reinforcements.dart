/// Reinforcement calculation for Risk game.
/// Pure Dart port of risk/engine/reinforcements.py.
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'dart:math';
import 'map_graph.dart';
import 'models/game_state.dart';

/// Calculate total reinforcement armies for a player.
///
/// Base: max(territories_owned ~/ 3, 3)
/// Plus: bonus for each fully controlled continent.
int calculateReinforcements(
  GameState state,
  MapGraph mapGraph,
  int playerIndex,
) {
  final playerTerritories = state.territories.entries
      .where((e) => e.value.owner == playerIndex)
      .map((e) => e.key)
      .toSet();

  // Base reinforcements: territory count / 3, minimum 3 (integer division)
  final base = max(playerTerritories.length ~/ 3, 3);

  // Continent bonuses
  int bonus = 0;
  for (final continent in mapGraph.continentNames) {
    if (mapGraph.controlsContinent(continent, playerTerritories)) {
      bonus += mapGraph.continentBonus(continent);
    }
  }

  return base + bonus;
}
