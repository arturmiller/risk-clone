import 'dart:math';

import 'map_graph.dart';
import 'models/game_state.dart';

/// Classic Risk starting armies by player count.
const Map<int, int> startingArmies = {
  2: 40,
  3: 35,
  4: 30,
  5: 25,
  6: 20,
};

/// Set up a new Risk game: distribute territories and place initial armies.
///
/// [mapGraph]: The map defining available territories.
/// [numPlayers]: Number of players (2–6).
/// [rng]: Optional random source for reproducibility.
///
/// Throws [ArgumentError] if [numPlayers] is not between 2 and 6.
GameState setupGame(MapGraph mapGraph, int numPlayers, {Random? rng}) {
  if (numPlayers < 2 || numPlayers > 6) {
    throw ArgumentError('Player count must be 2-6, got $numPlayers');
  }

  final random = rng ?? Random();

  // Shuffle territories for random distribution
  final territories = mapGraph.allTerritories..shuffle(random);

  // Round-robin deal: territory i goes to player i % numPlayers
  final ownership = <int, List<String>>{
    for (int p = 0; p < numPlayers; p++) p: [],
  };
  for (int i = 0; i < territories.length; i++) {
    ownership[i % numPlayers]!.add(territories[i]);
  }

  // Build territory states: start with 1 army each
  final territoryStates = <String, TerritoryState>{};
  for (final entry in ownership.entries) {
    for (final territory in entry.value) {
      territoryStates[territory] =
          TerritoryState(owner: entry.key, armies: 1);
    }
  }

  // Distribute remaining armies randomly among owned territories
  final starting = startingArmies[numPlayers]!;
  for (final entry in ownership.entries) {
    final owned = entry.value;
    final remaining = starting - owned.length;
    for (int i = 0; i < remaining; i++) {
      final target = owned[random.nextInt(owned.length)];
      final current = territoryStates[target]!;
      territoryStates[target] =
          TerritoryState(owner: current.owner, armies: current.armies + 1);
    }
  }

  // Create players
  final players = List.generate(
    numPlayers,
    (i) => PlayerState(index: i, name: 'Player ${i + 1}'),
  );

  return GameState(territories: territoryStates, players: players);
}
