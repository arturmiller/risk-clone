/// simulation.dart: Full game loop helper for win rate testing and Phase 12.
/// Pure Dart port of risk/game.py run_game().
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'dart:math';

import 'cards_engine.dart';
import 'map_graph.dart';
import 'models/cards.dart';
import 'models/game_state.dart';
import 'setup.dart';
import 'turn.dart';
import '../bots/player_agent.dart';

/// Run a complete game of Risk from setup to victory.
///
/// [mapGraph]: The map graph for the game.
/// [agents]: Map from player index to PlayerAgent instances.
/// [rng]: Random source for game mechanics (dice, card draw).
/// [maxTurns]: Safety valve to prevent infinite loops (default: 5000).
///
/// Returns the final GameState when one player achieves victory.
///
/// Throws [StateError] if the game doesn't complete within [maxTurns].
GameState runGame(
  MapGraph mapGraph,
  Map<int, PlayerAgent> agents,
  Random rng, {
  int maxTurns = 5000,
}) {
  final numPlayers = agents.length;

  // Setup initial state
  GameState state = setupGame(mapGraph, numPlayers, rng: rng);

  // Initialize deck
  final deck = createDeck(mapGraph.allTerritories);

  // Fisher-Yates shuffle using the provided rng
  for (int i = deck.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = deck[i];
    deck[i] = deck[j];
    deck[j] = tmp;
  }

  // Initialize cards map: each player starts with empty hand
  final cards = <String, List<Card>>{
    for (int i = 0; i < numPlayers; i++) i.toString(): <Card>[],
  };

  state = state.copyWith(deck: deck, cards: cards);

  // Game loop
  for (int turn = 0; turn < maxTurns; turn++) {
    bool victory;
    (state, victory) = executeTurn(state, mapGraph, agents, rng);
    if (victory) return state;
  }

  throw StateError('Game did not complete within $maxTurns turns');
}
