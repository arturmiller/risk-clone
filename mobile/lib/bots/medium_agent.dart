/// MediumAgent: continent-aware bot. Dart port of risk/bots/medium.py.
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'dart:math';

import '../engine/actions.dart';
import '../engine/cards_engine.dart';
import '../engine/map_graph.dart';
import '../engine/models/cards.dart';
import '../engine/models/game_state.dart';
import 'player_agent.dart';

class MediumAgent implements PlayerAgent {
  final MapGraph _mapGraph;
  final Random _rng;

  MediumAgent({required MapGraph mapGraph, Random? rng})
      : _mapGraph = mapGraph,
        _rng = rng ?? Random();

  // ------------------------------------------------------------------
  // Private helpers
  // ------------------------------------------------------------------

  /// Score each continent by fraction of territories owned by current player.
  Map<String, double> _continentScores(GameState state) {
    final player = state.currentPlayerIndex;
    final scores = <String, double>{};
    for (final c in _mapGraph.continentNames) {
      final terrs = _mapGraph.continentTerritories(c);
      final total = terrs.length;
      if (total == 0) continue;
      final owned =
          terrs.where((t) => state.territories[t]?.owner == player).length;
      scores[c] = owned / total;
    }
    return scores;
  }

  /// Return owned territories that have at least one enemy neighbor.
  List<String> _borderTerritories(GameState state, Set<String> owned) {
    final player = state.currentPlayerIndex;
    return owned
        .where((t) => _mapGraph
            .neighbors(t)
            .any((n) => state.territories[n]?.owner != player))
        .toList();
  }

  // ------------------------------------------------------------------
  // PlayerAgent methods
  // ------------------------------------------------------------------

  @override
  ReinforcePlacementAction chooseReinforcementPlacement(
      GameState state, int armies) {
    final player = state.currentPlayerIndex;
    final owned = state.territories.entries
        .where((e) => e.value.owner == player)
        .map((e) => e.key)
        .toSet();

    if (owned.isEmpty) {
      return const ReinforcePlacementAction(placements: {});
    }

    final scores = _continentScores(state);
    if (scores.isNotEmpty) {
      // Find top continent (prefer higher bonus on score ties)
      final topContinent = scores.keys.reduce((a, b) {
        final sa = scores[a]!;
        final sb = scores[b]!;
        if (sa != sb) return sa > sb ? a : b;
        return _mapGraph.continentBonus(a) >= _mapGraph.continentBonus(b)
            ? a
            : b;
      });

      // Border territories the bot owns within that continent
      final topContOwned =
          owned.intersection(_mapGraph.continentTerritories(topContinent));
      final contBorders = topContOwned.where((t) => _mapGraph
          .neighbors(t)
          .any((n) => state.territories[n]?.owner != player)).toList();

      if (contBorders.isNotEmpty) {
        // Prefer external-facing borders (neighbor outside continent is enemy)
        final contTerrs = _mapGraph.continentTerritories(topContinent);
        final externalBorders = contBorders.where((t) => _mapGraph
            .neighbors(t)
            .any((n) =>
                !contTerrs.contains(n) &&
                state.territories[n]?.owner != player)).toList();

        final finalCandidates =
            externalBorders.isNotEmpty ? externalBorders : contBorders;
        // Place all on weakest (fewest armies)
        String target = finalCandidates.first;
        for (final t in finalCandidates) {
          if ((state.territories[t]?.armies ?? 0) <
              (state.territories[target]?.armies ?? 0)) {
            target = t;
          }
        }
        return ReinforcePlacementAction(placements: {target: armies});
      }
    }

    // Fallback: any border territory with fewest armies
    final allBorders = _borderTerritories(state, owned);
    if (allBorders.isNotEmpty) {
      String target = allBorders.first;
      for (final t in allBorders) {
        if ((state.territories[t]?.armies ?? 0) <
            (state.territories[target]?.armies ?? 0)) {
          target = t;
        }
      }
      return ReinforcePlacementAction(placements: {target: armies});
    }

    // Final fallback: random owned territory
    final ownedList = owned.toList();
    final target = ownedList[_rng.nextInt(ownedList.length)];
    return ReinforcePlacementAction(placements: {target: armies});
  }

  @override
  AttackChoice? chooseAttack(GameState state) {
    final player = state.currentPlayerIndex;

    // Build all valid attack candidates
    final candidates = <(String, String)>[];
    for (final entry in state.territories.entries) {
      final name = entry.key;
      final ts = entry.value;
      if (ts.owner != player || ts.armies < 2) continue;
      for (final neighbor in _mapGraph.neighbors(name)) {
        final nts = state.territories[neighbor];
        if (nts != null && nts.owner != player) {
          candidates.add((name, neighbor));
        }
      }
    }

    if (candidates.isEmpty) return null;

    final scores = _continentScores(state);
    String? topContinent;
    if (scores.isNotEmpty) {
      topContinent = scores.keys.reduce((a, b) {
        final sa = scores[a]!;
        final sb = scores[b]!;
        if (sa != sb) return sa > sb ? a : b;
        return _mapGraph.continentBonus(a) >= _mapGraph.continentBonus(b)
            ? a
            : b;
      });
    }

    int numDice(String source) =>
        (state.territories[source]!.armies - 1).clamp(1, 3);

    bool completesContinent(String target) {
      final cont = _mapGraph.continentOf(target);
      if (cont == null) return false;
      final contTerrs = _mapGraph.continentTerritories(cont);
      final others = contTerrs.difference({target});
      return others.every((t) => state.territories[t]?.owner == player);
    }

    bool opponentAlmostComplete(String target) {
      final cont = _mapGraph.continentOf(target);
      if (cont == null) return false;
      final contTerrs = _mapGraph.continentTerritories(cont);
      final others = contTerrs.difference({target});
      if (others.isEmpty) return false;
      final targetOwner = state.territories[target]?.owner;
      if (targetOwner == null) return false;
      return others.every((t) => state.territories[t]?.owner == targetOwner);
    }

    // Priority 1: continent-completing attacks (src >= tgt)
    for (final (source, target) in candidates) {
      final srcArmies = state.territories[source]!.armies;
      final tgtArmies = state.territories[target]!.armies;
      if (completesContinent(target) && srcArmies >= tgtArmies) {
        return AttackAction(
            source: source, target: target, numDice: numDice(source));
      }
    }

    // Priority 2: favorable attack into top continent
    if (topContinent != null) {
      final topContTerrs = _mapGraph.continentTerritories(topContinent);
      for (final (source, target) in candidates) {
        if (topContTerrs.contains(target)) {
          final srcArmies = state.territories[source]!.armies;
          final tgtArmies = state.territories[target]!.armies;
          if (srcArmies > tgtArmies) {
            return AttackAction(
                source: source, target: target, numDice: numDice(source));
          }
        }
      }
    }

    // Priority 3: blocking opponent continent completion
    for (final (source, target) in candidates) {
      final srcArmies = state.territories[source]!.armies;
      final tgtArmies = state.territories[target]!.armies;
      if (opponentAlmostComplete(target) && srcArmies > tgtArmies) {
        return AttackAction(
            source: source, target: target, numDice: numDice(source));
      }
    }

    // Priority 4: any favorable attack
    for (final (source, target) in candidates) {
      final srcArmies = state.territories[source]!.armies;
      final tgtArmies = state.territories[target]!.armies;
      if (srcArmies > tgtArmies) {
        return AttackAction(
            source: source, target: target, numDice: numDice(source));
      }
    }

    return null;
  }

  @override
  FortifyAction? chooseFortify(GameState state) {
    final player = state.currentPlayerIndex;
    final owned = state.territories.entries
        .where((e) => e.value.owner == player)
        .map((e) => e.key)
        .toSet();

    // Interior: all neighbors are also owned by the bot
    final interior = owned.where((t) {
      final ts = state.territories[t]!;
      if (ts.armies < 2) return false;
      return _mapGraph
          .neighbors(t)
          .every((n) => state.territories[n]?.owner == player);
    }).toList();

    if (interior.isEmpty) return null;

    final borders = _borderTerritories(state, owned);
    if (borders.isEmpty) return null;

    // Source = interior territory with most armies
    String source = interior.first;
    for (final t in interior) {
      if ((state.territories[t]?.armies ?? 0) >
          (state.territories[source]?.armies ?? 0)) {
        source = t;
      }
    }

    final armiesToMove = state.territories[source]!.armies - 1;
    if (armiesToMove < 1) return null;

    // Reachable friendly territories from source
    final reachable = _mapGraph.connectedTerritories(source, owned);
    reachable.remove(source);
    final reachableBorders = borders.where((t) => reachable.contains(t)).toList();
    if (reachableBorders.isEmpty) return null;

    // Target = reachable border with fewest armies (most exposed)
    String target = reachableBorders.first;
    for (final t in reachableBorders) {
      if ((state.territories[t]?.armies ?? 0) <
          (state.territories[target]?.armies ?? 0)) {
        target = t;
      }
    }

    return FortifyAction(source: source, target: target, armies: armiesToMove);
  }

  @override
  TradeCardsAction? chooseCardTrade(GameState state, List<Card> hand,
      {required bool forced}) {
    if (hand.length < 3) return null;
    final n = hand.length;
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        for (int k = j + 1; k < n; k++) {
          if (isValidSet([hand[i], hand[j], hand[k]])) {
            return TradeCardsAction(cards: [hand[i], hand[j], hand[k]]);
          }
        }
      }
    }
    return null;
  }

  @override
  int chooseAdvanceArmies(
      GameState state, String source, String target, int min, int max) {
    return min;
  }
}
