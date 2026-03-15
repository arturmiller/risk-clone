/// EasyAgent: Dart port of Python's RandomAgent from risk/game.py.
/// Makes valid random moves using a seeded RNG.
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'dart:math';

import '../engine/actions.dart';
import '../engine/cards_engine.dart';
import '../engine/map_graph.dart';
import '../engine/models/cards.dart';
import '../engine/models/game_state.dart';
import 'player_agent.dart';

class EasyAgent implements PlayerAgent {
  final MapGraph _mapGraph;
  final Random _rng;

  /// Constructor-injected MapGraph and optional RNG.
  EasyAgent({required MapGraph mapGraph, Random? rng})
      : _mapGraph = mapGraph,
        _rng = rng ?? Random();

  /// Distribute [armies] randomly among owned territories, one-at-a-time.
  @override
  ReinforcePlacementAction chooseReinforcementPlacement(
      GameState state, int armies) {
    final playerIdx = state.currentPlayerIndex;
    final owned = state.territories.entries
        .where((e) => e.value.owner == playerIdx)
        .map((e) => e.key)
        .toList();

    final placements = <String, int>{};
    for (int i = 0; i < armies; i++) {
      final t = owned[_rng.nextInt(owned.length)];
      placements[t] = (placements[t] ?? 0) + 1;
    }
    return ReinforcePlacementAction(placements: placements);
  }

  /// Attack from strongest territories against weakest neighbors.
  /// Returns null when no valid attacks exist.
  @override
  AttackChoice? chooseAttack(GameState state) {
    final playerIdx = state.currentPlayerIndex;

    // Collect all valid attack options: (source, target, advantage)
    final options = <(String, String, int)>[];
    for (final entry in state.territories.entries) {
      final name = entry.key;
      final ts = entry.value;
      if (ts.owner != playerIdx || ts.armies < 2) continue;
      for (final neighbor in _mapGraph.neighbors(name)) {
        final nts = state.territories[neighbor]!;
        if (nts.owner != playerIdx) {
          final advantage = ts.armies - nts.armies;
          options.add((name, neighbor, advantage));
        }
      }
    }

    if (options.isEmpty) return null;

    // Shuffle for randomness among ties, then sort by advantage descending.
    // List.shuffle accepts a Random — direct Dart port of Python's rng.shuffle.
    options.shuffle(_rng);
    options.sort((a, b) => b.$3.compareTo(a.$3));

    final bestAdvantage = options[0].$3;

    // Only stop if all options are disadvantaged — 15% chance to stop.
    // Python: rng.random() < 0.15. Dart: use nextInt(100) < 15 (equivalent).
    // Note: FakeRandom doesn't support nextDouble(); using nextInt(100) instead.
    if (bestAdvantage <= 0 && _rng.nextInt(100) < 15) {
      return null;
    }

    final (source, target, _) = options[0];
    final srcArmies = state.territories[source]!.armies;
    final numDice = srcArmies - 1 < 3 ? srcArmies - 1 : 3;
    return AttackAction(source: source, target: target, numDice: numDice);
  }

  /// 50% chance to skip fortify; otherwise move armies between connected
  /// friendly territories.
  ///
  /// Note: Python uses rng.random() < 0.5 for the skip check. FakeRandom
  /// only supports nextInt(). Using nextInt(2) == 1 as equivalent (50% skip).
  @override
  FortifyAction? chooseFortify(GameState state) {
    // 50% chance to skip: nextInt(2) == 1 means skip
    if (_rng.nextInt(2) == 1) return null;

    final playerIdx = state.currentPlayerIndex;
    final sources = state.territories.entries
        .where((e) => e.value.owner == playerIdx && e.value.armies >= 2)
        .map((e) => e.key)
        .toList();

    if (sources.isEmpty) return null;

    final source = sources[_rng.nextInt(sources.length)];

    // Find all friendly territories reachable from source
    final playerTerritories = state.territories.entries
        .where((e) => e.value.owner == playerIdx)
        .map((e) => e.key)
        .toSet();
    final reachable =
        _mapGraph.connectedTerritories(source, playerTerritories);
    reachable.remove(source);

    if (reachable.isEmpty) return null;

    final reachableList = reachable.toList();
    final target = reachableList[_rng.nextInt(reachableList.length)];
    final maxArmies = state.territories[source]!.armies - 1;
    // nextInt(maxArmies) gives 0..(maxArmies-1); +1 for range 1..maxArmies
    final armies = _rng.nextInt(maxArmies) + 1;

    return FortifyAction(source: source, target: target, armies: armies);
  }

  /// Return the first valid 3-card trade set, or null if none exists.
  @override
  TradeCardsAction? chooseCardTrade(
      GameState state, List<Card> hand, {required bool forced}) {
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

  /// Advance minimum armies (conservative strategy).
  @override
  int chooseAdvanceArmies(
      GameState state, String source, String target, int min, int max) {
    return min;
  }
}
