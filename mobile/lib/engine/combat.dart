import 'dart:math';

import 'actions.dart';
import 'map_graph.dart';
import 'models/game_state.dart';

/// Outcome of a single combat round.
class CombatResult {
  final int attackerLosses;
  final int defenderLosses;
  const CombatResult(
      {required this.attackerLosses, required this.defenderLosses});
}

/// Roll dice and resolve a single round of combat.
///
/// Dice are sorted descending and paired highest-first.
/// Ties go to the defender (attacker loses on tie).
CombatResult resolveCombat(
    int attackerDice, int defenderDice, Random rng) {
  final attackerRolls =
      List.generate(attackerDice, (_) => rng.nextInt(6) + 1)
        ..sort((a, b) => b.compareTo(a));
  final defenderRolls =
      List.generate(defenderDice, (_) => rng.nextInt(6) + 1)
        ..sort((a, b) => b.compareTo(a));

  int attackerLosses = 0;
  int defenderLosses = 0;

  final pairs = attackerRolls.length < defenderRolls.length
      ? attackerRolls.length
      : defenderRolls.length;

  for (int i = 0; i < pairs; i++) {
    if (attackerRolls[i] > defenderRolls[i]) {
      defenderLosses++;
    } else {
      // Tie goes to defender
      attackerLosses++;
    }
  }

  return CombatResult(
      attackerLosses: attackerLosses, defenderLosses: defenderLosses);
}

/// Validate an attack action. Throws [ArgumentError] on invalid attack.
void validateAttack(
    GameState state, MapGraph mapGraph, AttackAction action, int playerIndex) {
  final sourceTs = state.territories[action.source]!;
  final targetTs = state.territories[action.target]!;

  if (sourceTs.owner != playerIndex) {
    throw ArgumentError(
        'Player $playerIndex does not own source territory \'${action.source}\'');
  }

  if (targetTs.owner == playerIndex) {
    throw ArgumentError(
        'Cannot attack own/friendly territory \'${action.target}\'');
  }

  if (!mapGraph.areAdjacent(action.source, action.target)) {
    throw ArgumentError(
        'Territories \'${action.source}\' and \'${action.target}\' are not adjacent');
  }

  if (sourceTs.armies < action.numDice + 1) {
    throw ArgumentError(
        'Source \'${action.source}\' has ${sourceTs.armies} armies but needs '
        'at least ${action.numDice + 1} to attack with ${action.numDice} dice');
  }
}

/// Execute a single attack round.
///
/// Returns (newState, result, conquered).
///
/// [armiesToMove]: armies to advance into conquered territory.
/// Defaults to action.numDice (minimum per Risk rules).
(GameState, CombatResult, bool) executeAttack(
  GameState state,
  MapGraph mapGraph,
  AttackAction action,
  int playerIndex,
  Random rng, {
  int? defenderDice,
  int? armiesToMove,
}) {
  validateAttack(state, mapGraph, action, playerIndex);

  final targetTs = state.territories[action.target]!;
  final resolvedDefenderDice = defenderDice ?? (targetTs.armies < 2 ? 1 : 2);

  final result = resolveCombat(action.numDice, resolvedDefenderDice, rng);

  final sourceTs = state.territories[action.source]!;
  final newTerritories =
      Map<String, TerritoryState>.of(state.territories);

  int newSourceArmies = sourceTs.armies - result.attackerLosses;
  int newTargetArmies = targetTs.armies - result.defenderLosses;

  final conquered = newTargetArmies <= 0;

  if (conquered) {
    final armiesMoved = armiesToMove ?? action.numDice;
    newSourceArmies -= armiesMoved;
    newTerritories[action.source] =
        TerritoryState(owner: sourceTs.owner, armies: newSourceArmies);
    newTerritories[action.target] =
        TerritoryState(owner: playerIndex, armies: armiesMoved);
  } else {
    newTerritories[action.source] =
        TerritoryState(owner: sourceTs.owner, armies: newSourceArmies);
    newTerritories[action.target] =
        TerritoryState(owner: targetTs.owner, armies: newTargetArmies);
  }

  final newState = conquered
      ? state.copyWith(
          territories: newTerritories, conqueredThisTurn: true)
      : state.copyWith(territories: newTerritories);

  return (newState, result, conquered);
}

/// Auto-resolve attack: loop until conquest or attacker has 1 army.
///
/// Returns (newState, allResults, conquered).
(GameState, List<CombatResult>, bool) executeBlitz(
  GameState state,
  MapGraph mapGraph,
  BlitzAction action,
  int playerIndex,
  Random rng,
) {
  // Validate basic preconditions
  final sourceTs = state.territories[action.source]!;
  final targetTs = state.territories[action.target]!;

  if (sourceTs.owner != playerIndex) {
    throw ArgumentError(
        'Player $playerIndex does not own source territory \'${action.source}\'');
  }
  if (targetTs.owner == playerIndex) {
    throw ArgumentError(
        'Cannot attack own/friendly territory \'${action.target}\'');
  }
  if (!mapGraph.areAdjacent(action.source, action.target)) {
    throw ArgumentError(
        'Territories \'${action.source}\' and \'${action.target}\' are not adjacent');
  }
  if (sourceTs.armies < 2) {
    throw ArgumentError(
        'Source \'${action.source}\' needs at least 2 armies to attack');
  }

  GameState currentState = state;
  final allResults = <CombatResult>[];

  while (true) {
    final src = currentState.territories[action.source]!;
    final tgt = currentState.territories[action.target]!;

    final attackerDice = src.armies - 1 < 3 ? src.armies - 1 : 3;
    final defenderDice = tgt.armies < 2 ? tgt.armies : 2;

    if (attackerDice < 1) break;

    final attackAction = AttackAction(
        source: action.source,
        target: action.target,
        numDice: attackerDice);

    final (newState, result, conquered) = executeAttack(
        currentState, mapGraph, attackAction, playerIndex, rng,
        defenderDice: defenderDice);

    currentState = newState;
    allResults.add(result);

    if (conquered) {
      return (currentState, allResults, true);
    }

    if (currentState.territories[action.source]!.armies <= 1) {
      return (currentState, allResults, false);
    }
  }

  return (currentState, allResults, false);
}
