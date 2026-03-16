/// Turn execution engine: phase transitions, elimination, victory detection.
/// Pure Dart port of risk/engine/turn.py.
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'dart:math';

import 'actions.dart';
import 'cards_engine.dart';
import 'combat.dart';
import 'fortify.dart';
import 'map_graph.dart';
import 'models/cards.dart';
import 'models/game_state.dart';
import 'reinforcements.dart';
import '../bots/player_agent.dart';

/// Return winning player index if one player owns all territories, else null.
int? checkVictory(GameState state) {
  final owners = state.territories.values.map((ts) => ts.owner).toSet();
  if (owners.length == 1) {
    final owner = owners.first;
    if (state.players[owner].isAlive) {
      return owner;
    }
  }
  return null;
}

/// Return true if the player owns zero territories.
bool checkElimination(GameState state, int playerIndex) {
  for (final ts in state.territories.values) {
    if (ts.owner == playerIndex) return false;
  }
  return true;
}

/// Move all cards from one player to another. Returns new state.
GameState transferCards(GameState state, int fromPlayer, int toPlayer) {
  final newCards = Map<String, List<Card>>.of(
      state.cards.map((k, v) => MapEntry(k, List<Card>.of(v))));
  final fromKey = fromPlayer.toString();
  final toKey = toPlayer.toString();
  final transferred = List<Card>.of(newCards[fromKey] ?? []);
  newCards[fromKey] = [];
  newCards[toKey] = [...(newCards[toKey] ?? []), ...transferred];
  return state.copyWith(cards: newCards);
}

/// Find the first valid 3-card set in a hand. Returns indices or null.
List<int>? _findValidSetIndices(List<Card> cards) {
  final n = cards.length;
  for (int i = 0; i < n; i++) {
    for (int j = i + 1; j < n; j++) {
      for (int k = j + 1; k < n; k++) {
        if (isValidSet([cards[i], cards[j], cards[k]])) return [i, j, k];
      }
    }
  }
  return null;
}

/// Map selected cards back to their indices in the hand.
List<int> _cardsToIndices(List<Card> hand, List<Card> selected) {
  final indices = <int>[];
  final used = <int>{};
  for (final card in selected) {
    for (int i = 0; i < hand.length; i++) {
      if (!used.contains(i) && hand[i] == card) {
        indices.add(i);
        used.add(i);
        break;
      }
    }
  }
  indices.sort();
  return indices;
}

/// Apply territory bonus armies from card trading.
GameState _applyTerritoryBonus(GameState state, Map<String, int> territoryBonus) {
  if (territoryBonus.isEmpty) return state;
  final newTerritories = Map<String, TerritoryState>.of(state.territories);
  for (final entry in territoryBonus.entries) {
    final ts = newTerritories[entry.key]!;
    newTerritories[entry.key] =
        TerritoryState(owner: ts.owner, armies: ts.armies + entry.value);
  }
  return state.copyWith(territories: newTerritories);
}

/// Force trades while player has 5+ cards. Returns (state, totalBonus).
(GameState, int) forceTradLoop(
  GameState state,
  int playerIndex,
  PlayerAgent agent,
) {
  int totalBonus = 0;

  while ((state.cards[playerIndex.toString()] ?? []).length >= 5) {
    final hand = state.cards[playerIndex.toString()]!;
    final tradeAction =
        agent.chooseCardTrade(state, hand, forced: true);

    List<int> cardIndices;
    if (tradeAction == null) {
      // Agent must trade when forced — find a valid set automatically
      final indices = _findValidSetIndices(hand);
      if (indices == null) break; // No valid set (shouldn't happen with 5+ cards)
      cardIndices = indices;
    } else {
      cardIndices = _cardsToIndices(hand, tradeAction.cards);
    }

    final (newState, bonus, territoryBonus) =
        executeTrade(state, playerIndex, cardIndices);
    state = _applyTerritoryBonus(newState, territoryBonus);
    totalBonus += bonus;
  }

  return (state, totalBonus);
}

/// Execute the reinforcement phase for a player.
///
/// 1. Force card trades if player has 5+ cards
/// 2. Calculate reinforcements (base + continent + trade bonus)
/// 3. Optional voluntary trade if valid set available and < 5 cards
/// 4. Agent places armies
/// 5. Transition to ATTACK phase
GameState executeReinforcePhase(
  GameState state,
  MapGraph mapGraph,
  PlayerAgent agent,
  int playerIndex,
) {
  int tradeBonus = 0;

  // Step 1: Forced card trade if 5+ cards
  if ((state.cards[playerIndex.toString()] ?? []).length >= 5) {
    (state, tradeBonus) = forceTradLoop(state, playerIndex, agent);
  }

  // Step 2: Calculate base reinforcements
  final base = calculateReinforcements(state, mapGraph, playerIndex);
  int totalArmies = base + tradeBonus;

  // Step 3: Optional voluntary trade (if has valid set and < 5 cards)
  final hand = state.cards[playerIndex.toString()] ?? [];
  if (hand.length >= 3 && _findValidSetIndices(hand) != null) {
    final tradeAction =
        agent.chooseCardTrade(state, hand, forced: false);
    if (tradeAction != null) {
      final cardIndices = _cardsToIndices(hand, tradeAction.cards);
      final (newState, bonus, territoryBonus) =
          executeTrade(state, playerIndex, cardIndices);
      state = _applyTerritoryBonus(newState, territoryBonus);
      totalArmies += bonus;
    }
  }

  // Step 4: Agent places armies
  final placement = agent.chooseReinforcementPlacement(state, totalArmies);

  // Validate placements
  final placed = placement.placements.values.fold(0, (a, b) => a + b);
  if (placed != totalArmies) {
    throw ArgumentError(
        'Must place exactly $totalArmies armies, got $placed');
  }

  // Apply placements
  final newTerritories = Map<String, TerritoryState>.of(state.territories);
  for (final entry in placement.placements.entries) {
    final ts = newTerritories[entry.key];
    if (ts == null || ts.owner != playerIndex) {
      throw ArgumentError(
          "Cannot place armies on '${entry.key}' — not owned by player $playerIndex");
    }
    newTerritories[entry.key] =
        TerritoryState(owner: ts.owner, armies: ts.armies + entry.value);
  }

  return state.copyWith(
      territories: newTerritories, turnPhase: TurnPhase.attack);
}

/// Execute the attack phase. Returns (state, victoryAchieved).
(GameState, bool) executeAttackPhase(
  GameState state,
  MapGraph mapGraph,
  PlayerAgent agent,
  int playerIndex,
  Random rng,
) {
  while (true) {
    final choice = agent.chooseAttack(state);
    if (choice == null) break;

    bool conquered;

    if (choice is BlitzAction) {
      final (newState, _, c) =
          executeBlitz(state, mapGraph, choice, playerIndex, rng);
      state = newState;
      conquered = c;
    } else if (choice is AttackAction) {
      final (newState, _, c) =
          executeAttack(state, mapGraph, choice, playerIndex, rng);
      state = newState;
      conquered = c;
    } else {
      break;
    }

    if (conquered) {
      state = state.copyWith(conqueredThisTurn: true);

      // Determine advance armies bounds
      int minArmies;
      int maxArmies;
      int alreadyMoved;
      String src;
      String tgt;

      if (choice is BlitzAction) {
        src = choice.source;
        tgt = choice.target;
        final targetNow = state.territories[tgt]!.armies;
        final sourceNow = state.territories[src]!.armies;
        minArmies = targetNow; // already moved by executeBlitz
        maxArmies = sourceNow + targetNow - 1; // must leave 1 in source
        alreadyMoved = targetNow;
      } else {
        final a = choice as AttackAction;
        src = a.source;
        tgt = a.target;
        final sourceNow = state.territories[src]!.armies;
        minArmies = a.numDice; // must advance at least dice used
        // executeAttack already moved numDice armies into target
        maxArmies = sourceNow + a.numDice - 1; // must leave 1 in source
        alreadyMoved = a.numDice;
      }

      // Clamp max in case of edge cases
      if (maxArmies < minArmies) maxArmies = minArmies;

      // Ask the agent how many to advance
      final toAdvance = agent
          .chooseAdvanceArmies(state, src, tgt, minArmies, maxArmies)
          .clamp(minArmies, maxArmies);

      // Adjust territories for the chosen advance amount
      if (toAdvance != alreadyMoved) {
        final delta = toAdvance - alreadyMoved;
        final newTerr = Map<String, TerritoryState>.of(state.territories);
        newTerr[src] = TerritoryState(
            owner: newTerr[src]!.owner,
            armies: newTerr[src]!.armies - delta);
        newTerr[tgt] = TerritoryState(
            owner: newTerr[tgt]!.owner,
            armies: newTerr[tgt]!.armies + delta);
        state = state.copyWith(territories: newTerr);
      }

      // Check if any opponent was eliminated by this conquest
      int? eliminatedPlayer;
      for (final p in state.players) {
        if (p.index == playerIndex) continue;
        if (p.isAlive && checkElimination(state, p.index)) {
          eliminatedPlayer = p.index;
          break;
        }
      }

      if (eliminatedPlayer != null) {
        // Mark eliminated player as dead
        final newPlayers = List<PlayerState>.of(state.players);
        newPlayers[eliminatedPlayer] = PlayerState(
          index: eliminatedPlayer,
          name: state.players[eliminatedPlayer].name,
          isAlive: false,
        );
        state = state.copyWith(players: newPlayers);

        // Transfer cards
        state = transferCards(state, eliminatedPlayer, playerIndex);

        // Forced trade if 5+ cards after transfer
        if ((state.cards[playerIndex.toString()] ?? []).length >= 5) {
          (state, _) = forceTradLoop(state, playerIndex, agent);
        }

        // Check victory
        if (checkVictory(state) != null) {
          return (state, true);
        }
      }
    }
  }

  // End of attack phase: draw card if conquered this turn
  if (state.conqueredThisTurn) {
    state = drawCard(state, playerIndex);
  }

  state = state.copyWith(turnPhase: TurnPhase.fortify);
  return (state, false);
}

/// Execute the fortify phase.
GameState executeFortifyPhase(
  GameState state,
  MapGraph mapGraph,
  PlayerAgent agent,
  int playerIndex,
) {
  final action = agent.chooseFortify(state);
  if (action != null) {
    state = executeFortify(state, mapGraph, action, playerIndex);
  }
  return state;
}

/// Find the next alive player after currentPlayerIndex.
int nextAlivePlayer(GameState state) {
  final numPlayers = state.players.length;
  int idx = state.currentPlayerIndex;
  for (int i = 0; i < numPlayers; i++) {
    idx = (idx + 1) % numPlayers;
    if (state.players[idx].isAlive) return idx;
  }
  // Should not reach here if game is not over
  return state.currentPlayerIndex;
}

/// Execute a full turn for the current player.
///
/// Runs REINFORCE -> ATTACK -> FORTIFY, then advances to next alive player.
/// Returns (newState, victoryAchieved).
(GameState, bool) executeTurn(
  GameState state,
  MapGraph mapGraph,
  Map<int, PlayerAgent> agents,
  Random rng,
) {
  final playerIndex = state.currentPlayerIndex;
  final agent = agents[playerIndex]!;

  // Reset turn state
  state = state.copyWith(
    conqueredThisTurn: false,
    turnPhase: TurnPhase.reinforce,
  );

  // Phase 1: Reinforce
  state = executeReinforcePhase(state, mapGraph, agent, playerIndex);

  // Phase 2: Attack
  bool victory;
  (state, victory) = executeAttackPhase(state, mapGraph, agent, playerIndex, rng);
  if (victory) return (state, true);

  // Phase 3: Fortify
  state = executeFortifyPhase(state, mapGraph, agent, playerIndex);

  // Advance to next alive player
  final nextPlayer = nextAlivePlayer(state);
  state = state.copyWith(
    currentPlayerIndex: nextPlayer,
    turnNumber: state.turnNumber + 1,
  );

  return (state, false);
}
