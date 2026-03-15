/// HardAgent: human-competitive bot. Dart port of risk/bots/hard.py.
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'dart:math' show min, max, Random;

import '../engine/actions.dart';
import '../engine/cards_engine.dart';
import '../engine/map_graph.dart';
import '../engine/models/cards.dart';
import '../engine/models/game_state.dart';
import 'player_agent.dart';

// ---------------------------------------------------------------------------
// File-scope constants and helpers (Isolate.run() compatible)
// ---------------------------------------------------------------------------

/// Precomputed attack probabilities from exact dice math (ties go to defender).
/// Key: "$attackerDice,$defenderDice" -> list of probabilities.
/// For 2-die comparisons: [p_attacker_wins_both, p_defender_wins_both, p_split]
/// For 1-die comparisons: [p_attacker_wins, p_defender_wins]
const Map<String, List<double>> attackProbabilities = {
  '1,1': [0.4167, 0.5833],
  '2,1': [0.5787, 0.4213],
  '3,1': [0.6597, 0.3403],
  '1,2': [0.2546, 0.7454],
  '2,2': [0.2276, 0.4483, 0.3241],
  '3,2': [0.3717, 0.2926, 0.3358],
};

/// Tunable weights for scoring.
const double continentProgressWeight = 3.0;
const double borderSecurityWeight = 2.0;
const double threatWeight = 1.5;
const int cardTimingThreshold = 4;
const double attackProbabilityThreshold = 0.6;

List<double> _lookupProb(int attackerDice, int defenderDice) =>
    attackProbabilities['$attackerDice,$defenderDice']!;

/// Estimate probability of attacker winning the territory.
/// Uses a geometric approximation from per-roll probabilities.
double _estimateWinProbability(int attackerArmies, int defenderArmies) {
  final att = attackerArmies - 1; // armies that can attack (leave 1 behind)
  final dfd = defenderArmies;

  if (att <= 0 || dfd <= 0) {
    return att <= 0 ? 0.0 : 1.0;
  }

  var a = att.toDouble();
  var d = dfd.toDouble();

  for (int i = 0; i < 50; i++) {
    if (a <= 0) return 0.0;
    if (d <= 0) return 1.0;

    final attDice = min(3, max(1, a.toInt()));
    final defDice = min(2, max(1, d.toInt()));
    final probs = _lookupProb(attDice, defDice);

    if (probs.length == 2) {
      // Single comparison: attacker wins or defender wins
      final pAttWin = probs[0];
      a -= (1 - pAttWin);
      d -= pAttWin;
    } else {
      // Two comparisons: [both_att_win, both_def_win, split]
      final pBothAtt = probs[0];
      final pBothDef = probs[1];
      final pSplit = probs[2];
      a -= 2 * pBothDef + pSplit;
      d -= 2 * pBothAtt + pSplit;
    }
  }

  if (d <= 0) return 1.0;
  if (a <= 0) return 0.0;
  return a / (a + d);
}

// ---------------------------------------------------------------------------
// HardAgent class
// ---------------------------------------------------------------------------

class HardAgent implements PlayerAgent {
  final MapGraph _mapGraph;
  final Random _rng;

  HardAgent({required MapGraph mapGraph, Random? rng})
      : _mapGraph = mapGraph,
        _rng = rng ?? Random();

  // ------------------------------------------------------------------
  // Private helpers
  // ------------------------------------------------------------------

  /// BSR: sum(enemy_adjacent_armies) / max(own_armies, 1).
  double _borderSecurityRatio(GameState state, String territory) {
    final ownArmies = state.territories[territory]?.armies ?? 1;
    final owner = state.territories[territory]?.owner ?? -1;
    final enemyAdjacent = _mapGraph
        .neighbors(territory)
        .where((n) => state.territories[n]?.owner != owner)
        .fold<int>(0, (sum, n) => sum + (state.territories[n]?.armies ?? 0));
    return enemyAdjacent / max(ownArmies, 1);
  }

  /// Score each opponent by total armies + continent threat.
  Map<int, double> _opponentThreatScores(GameState state) {
    final player = state.currentPlayerIndex;
    final threats = <int, double>{};

    for (final p in state.players) {
      if (p.index == player || !p.isAlive) continue;

      // Factor 1: total army count
      final total = state.territories.values
          .where((ts) => ts.owner == p.index)
          .fold<int>(0, (sum, ts) => sum + ts.armies);

      // Factor 2: continent threat
      double continentThreat = 0.0;
      for (final c in _mapGraph.continentNames) {
        final contTerrs = _mapGraph.continentTerritories(c);
        final owned =
            contTerrs.where((t) => state.territories[t]?.owner == p.index).length;
        final bonus = _mapGraph.continentBonus(c);
        if (owned >= contTerrs.length - 1) {
          continentThreat += bonus * 2;
        } else if (owned >= contTerrs.length * 0.7) {
          continentThreat += bonus.toDouble();
        }
      }

      threats[p.index] = total * 0.5 + continentThreat * threatWeight;
    }
    return threats;
  }

  /// Score each continent by fraction owned (with >50% boost).
  Map<String, double> _continentScores(GameState state) {
    final player = state.currentPlayerIndex;
    final scores = <String, double>{};
    for (final c in _mapGraph.continentNames) {
      final terrs = _mapGraph.continentTerritories(c);
      final total = terrs.length;
      if (total == 0) continue;
      final owned =
          terrs.where((t) => state.territories[t]?.owner == player).length;
      final fraction = owned / total;
      var score =
          fraction * _mapGraph.continentBonus(c) * continentProgressWeight;
      if (fraction > 0.5) score *= 1.5;
      scores[c] = score;
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

  /// True if all neighbors are owned by the same player as this territory.
  bool _isInterior(GameState state, String territory) {
    final owner = state.territories[territory]?.owner;
    return _mapGraph
        .neighbors(territory)
        .every((n) => state.territories[n]?.owner == owner);
  }

  /// Find best valid trade set, preferring territory bonus matches.
  TradeCardsAction? _bestTrade(GameState state, List<Card> cards) {
    final player = state.currentPlayerIndex;
    final owned = state.territories.entries
        .where((e) => e.value.owner == player)
        .map((e) => e.key)
        .toSet();

    List<Card>? bestSet;
    int bestBonus = -1;
    final n = cards.length;

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        for (int k = j + 1; k < n; k++) {
          final candidate = [cards[i], cards[j], cards[k]];
          if (isValidSet(candidate)) {
            final bonus = candidate
                .where((c) => c.territory != null && owned.contains(c.territory))
                .length;
            if (bonus > bestBonus) {
              bestBonus = bonus;
              bestSet = candidate;
            }
          }
        }
      }
    }

    if (bestSet == null) return null;
    return TradeCardsAction(cards: bestSet);
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

    final borders = _borderTerritories(state, owned);
    if (borders.isEmpty) {
      final ownedList = owned.toList();
      final target = ownedList[_rng.nextInt(ownedList.length)];
      return ReinforcePlacementAction(placements: {target: armies});
    }

    // Score each border: BSR * borderSecurityWeight + continentScore
    final contScores = _continentScores(state);

    double placementScore(String t) {
      final bsr = _borderSecurityRatio(state, t);
      final cont = _mapGraph.continentOf(t) ?? '';
      final contBonus = contScores[cont] ?? 0.0;
      return bsr * borderSecurityWeight + contBonus;
    }

    // Sort by score descending
    final ranked = List<String>.from(borders);
    ranked.sort((a, b) => placementScore(b).compareTo(placementScore(a)));

    // Concentrate on top 1-2
    if (ranked.length == 1 || armies <= 3) {
      return ReinforcePlacementAction(placements: {ranked[0]: armies});
    } else {
      final primary = max(1, armies * 2 ~/ 3);
      final secondary = armies - primary;
      final placements = <String, int>{ranked[0]: primary};
      if (secondary > 0) {
        placements[ranked[1]] = secondary;
      }
      return ReinforcePlacementAction(placements: placements);
    }
  }

  @override
  AttackChoice? chooseAttack(GameState state) {
    final player = state.currentPlayerIndex;
    final owned = state.territories.entries
        .where((e) => e.value.owner == player)
        .map((e) => e.key)
        .toSet();

    // Guard: need at least one territory with armies >= 3 AND army advantage
    bool hasViableAttack = false;
    outer:
    for (final entry in state.territories.entries) {
      if (entry.value.owner != player || entry.value.armies < 3) continue;
      for (final neighbor in _mapGraph.neighbors(entry.key)) {
        final nts = state.territories[neighbor];
        if (nts != null && nts.owner != player && entry.value.armies > nts.armies) {
          hasViableAttack = true;
          break outer;
        }
      }
    }
    if (!hasViableAttack) return null;

    // Build all attack candidates (armies >= 2)
    final candidates = <(String, String)>[];
    for (final entry in state.territories.entries) {
      if (entry.value.owner != player || entry.value.armies < 2) continue;
      for (final neighbor in _mapGraph.neighbors(entry.key)) {
        final nts = state.territories[neighbor];
        if (nts != null && nts.owner != player) {
          candidates.add((entry.key, neighbor));
        }
      }
    }
    if (candidates.isEmpty) return null;

    final threatScores = _opponentThreatScores(state);
    final contScores = _continentScores(state);

    int numDice(String source) =>
        (state.territories[source]!.armies - 1).clamp(1, 3);

    bool completesContinent(String target) {
      final cont = _mapGraph.continentOf(target);
      if (cont == null) return false;
      final contTerrs = _mapGraph.continentTerritories(cont);
      final others = contTerrs.difference({target});
      return others.every((t) => state.territories[t]?.owner == player);
    }

    bool blocksOpponentContinent(String target) {
      final targetOwner = state.territories[target]?.owner;
      if (targetOwner == null || targetOwner == player) return false;
      final cont = _mapGraph.continentOf(target);
      if (cont == null) return false;
      final contTerrs = _mapGraph.continentTerritories(cont);
      final opponentOwned = contTerrs
          .where((t) => state.territories[t]?.owner == targetOwner)
          .length;
      return opponentOwned >= contTerrs.length - 2 &&
          opponentOwned >= contTerrs.length * 0.5;
    }

    // Priority 1: continent-completing (allow even match)
    for (final (source, target) in candidates) {
      final src = state.territories[source]!.armies;
      final tgt = state.territories[target]!.armies;
      if (completesContinent(target) && src >= tgt) {
        return AttackAction(source: source, target: target, numDice: numDice(source));
      }
    }

    // Priority 2: block opponent continent completion
    final blockCandidates = candidates
        .where((c) => blocksOpponentContinent(c.$2))
        .toList();
    blockCandidates.sort((a, b) {
      final ta = threatScores[state.territories[a.$2]?.owner] ?? 0.0;
      final tb = threatScores[state.territories[b.$2]?.owner] ?? 0.0;
      return tb.compareTo(ta);
    });
    for (final (source, target) in blockCandidates) {
      final src = state.territories[source]!.armies;
      final tgt = state.territories[target]!.armies;
      if (src > tgt) {
        return AttackAction(source: source, target: target, numDice: numDice(source));
      }
    }

    // Priority 3: high-value attacks with >= 60% win probability
    final scoredAttacks = <(double, String, String)>[];
    for (final (source, target) in candidates) {
      final srcArmies = state.territories[source]!.armies;
      final tgtArmies = state.territories[target]!.armies;
      final winProb = _estimateWinProbability(srcArmies, tgtArmies);
      if (winProb < attackProbabilityThreshold) continue;
      final cont = _mapGraph.continentOf(target) ?? '';
      final contValue = contScores[cont] ?? 0.0;
      final score = winProb * 2.0 + contValue;
      scoredAttacks.add((score, source, target));
    }
    if (scoredAttacks.isNotEmpty) {
      scoredAttacks.sort((a, b) => b.$1.compareTo(a.$1));
      final (_, source, target) = scoredAttacks[0];
      return AttackAction(source: source, target: target, numDice: numDice(source));
    }

    // Priority 4: overwhelming force (3:1 ratio and src >= 4)
    for (final (source, target) in candidates) {
      final src = state.territories[source]!.armies;
      final tgt = state.territories[target]!.armies;
      if (src >= 3 * tgt && src >= 4) {
        return AttackAction(source: source, target: target, numDice: numDice(source));
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

    // Interior: all neighbors owned, armies >= 2
    final interior = owned.where((t) {
      final ts = state.territories[t]!;
      if (ts.armies < 2) return false;
      return _isInterior(state, t);
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

    // Find reachable borders
    final reachable = _mapGraph.connectedTerritories(source, owned);
    reachable.remove(source);
    final reachableBorders =
        borders.where((t) => reachable.contains(t)).toList();
    if (reachableBorders.isEmpty) return null;

    // Target = reachable border with HIGHEST BSR (most vulnerable)
    String target = reachableBorders.first;
    for (final t in reachableBorders) {
      if (_borderSecurityRatio(state, t) >
          _borderSecurityRatio(state, target)) {
        target = t;
      }
    }

    return FortifyAction(source: source, target: target, armies: armiesToMove);
  }

  @override
  TradeCardsAction? chooseCardTrade(GameState state, List<Card> hand,
      {required bool forced}) {
    if (forced) return _bestTrade(state, hand);

    if (hand.length < 3) return null;

    // Hold until 4 cards or high escalation
    if (hand.length >= cardTimingThreshold || state.tradeCount >= 4) {
      return _bestTrade(state, hand);
    }

    return null;
  }

  @override
  int chooseAdvanceArmies(
      GameState state, String source, String target, int min, int max) {
    final player = state.currentPlayerIndex;

    // If source is interior, advance all armies
    if (_isInterior(state, source)) return max;

    // Count enemy neighbors for target (excluding source)
    final targetEnemyNeighbors = _mapGraph
        .neighbors(target)
        .where((n) => n != source && state.territories[n]?.owner != player)
        .length;

    // Count enemy neighbors for source (excluding target)
    final sourceEnemyNeighbors = _mapGraph
        .neighbors(source)
        .where((n) => n != target && state.territories[n]?.owner != player)
        .length;

    if (targetEnemyNeighbors == 0 && sourceEnemyNeighbors > 0) {
      // Target is safe, keep armies on exposed source
      return min;
    }

    if (sourceEnemyNeighbors == 0) {
      // Source has no enemies (except through target), advance more
      return max;
    }

    // Both border enemies: split proportionally
    final totalExposure = targetEnemyNeighbors + sourceEnemyNeighbors;
    if (totalExposure == 0) {
      return max >= min ? (min + (max - min) ~/ 2) : min;
    }

    final targetRatio = targetEnemyNeighbors / totalExposure;
    final advance = (max * targetRatio).toInt();
    return advance.clamp(min, max);
  }
}
