"""Combat resolution for Risk: single roll, attack execution, and blitz."""

import random

from pydantic import BaseModel

from risk.models.actions import AttackAction, BlitzAction
from risk.models.game_state import GameState, TerritoryState


class CombatResult(BaseModel):
    """Outcome of a single combat round."""

    attacker_losses: int
    defender_losses: int


def resolve_combat(
    attacker_dice: int, defender_dice: int, rng: random.Random
) -> CombatResult:
    """Roll dice and resolve a single round of combat.

    Dice are sorted descending and paired highest-first.
    Ties go to the defender.
    """
    attacker_rolls = sorted([rng.randint(1, 6) for _ in range(attacker_dice)], reverse=True)
    defender_rolls = sorted([rng.randint(1, 6) for _ in range(defender_dice)], reverse=True)

    attacker_losses = 0
    defender_losses = 0

    for a_die, d_die in zip(attacker_rolls, defender_rolls):
        if a_die > d_die:
            defender_losses += 1
        else:
            # Tie goes to defender
            attacker_losses += 1

    return CombatResult(attacker_losses=attacker_losses, defender_losses=defender_losses)


def validate_attack(
    state: GameState,
    map_graph: object,
    action: AttackAction,
    player_index: int,
) -> None:
    """Validate an attack action. Raises ValueError on invalid attack."""
    source_ts = state.territories[action.source]
    target_ts = state.territories[action.target]

    if source_ts.owner != player_index:
        raise ValueError(
            f"Player {player_index} does not own source territory '{action.source}'"
        )

    if target_ts.owner == player_index:
        raise ValueError(
            f"Cannot attack own/friendly territory '{action.target}'"
        )

    if not map_graph.are_adjacent(action.source, action.target):  # type: ignore[union-attr]
        raise ValueError(
            f"Territories '{action.source}' and '{action.target}' are not adjacent"
        )

    if source_ts.armies < action.num_dice + 1:
        raise ValueError(
            f"Source '{action.source}' has {source_ts.armies} armies but needs "
            f"at least {action.num_dice + 1} to attack with {action.num_dice} dice"
        )


def execute_attack(
    state: GameState,
    map_graph: object,
    action: AttackAction,
    player_index: int,
    rng: random.Random,
    defender_dice: int | None = None,
) -> tuple[GameState, CombatResult, bool]:
    """Execute a single attack round. Returns (new_state, result, conquered)."""
    validate_attack(state, map_graph, action, player_index)

    target_ts = state.territories[action.target]
    if defender_dice is None:
        defender_dice = min(2, target_ts.armies)

    result = resolve_combat(action.num_dice, defender_dice, rng)

    # Apply losses
    new_territories = dict(state.territories)
    source_ts = state.territories[action.source]

    new_source_armies = source_ts.armies - result.attacker_losses
    new_target_armies = target_ts.armies - result.defender_losses

    conquered = new_target_armies <= 0

    if conquered:
        # Territory conquered: transfer ownership, move armies
        armies_moved = action.num_dice
        new_source_armies -= armies_moved
        new_territories[action.source] = TerritoryState(
            owner=source_ts.owner, armies=new_source_armies
        )
        new_territories[action.target] = TerritoryState(
            owner=player_index, armies=armies_moved
        )
    else:
        new_territories[action.source] = TerritoryState(
            owner=source_ts.owner, armies=new_source_armies
        )
        new_territories[action.target] = TerritoryState(
            owner=target_ts.owner, armies=new_target_armies
        )

    update: dict = {"territories": new_territories}
    if conquered:
        update["conquered_this_turn"] = True

    new_state = state.model_copy(update=update)
    return new_state, result, conquered


def execute_blitz(
    state: GameState,
    map_graph: object,
    action: BlitzAction,
    player_index: int,
    rng: random.Random,
) -> tuple[GameState, list[CombatResult], bool]:
    """Auto-resolve attack: loop until conquest or attacker has 1 army."""
    # Validate basic preconditions
    source_ts = state.territories[action.source]
    target_ts = state.territories[action.target]

    if source_ts.owner != player_index:
        raise ValueError(
            f"Player {player_index} does not own source territory '{action.source}'"
        )
    if target_ts.owner == player_index:
        raise ValueError(
            f"Cannot attack own/friendly territory '{action.target}'"
        )
    if not map_graph.are_adjacent(action.source, action.target):  # type: ignore[union-attr]
        raise ValueError(
            f"Territories '{action.source}' and '{action.target}' are not adjacent"
        )
    if source_ts.armies < 2:
        raise ValueError(
            f"Source '{action.source}' needs at least 2 armies to attack"
        )

    current_state = state
    all_results: list[CombatResult] = []

    while True:
        src = current_state.territories[action.source]
        tgt = current_state.territories[action.target]

        attacker_dice = min(3, src.armies - 1)
        defender_dice = min(2, tgt.armies)

        if attacker_dice < 1:
            break

        attack_action = AttackAction(
            source=action.source, target=action.target, num_dice=attacker_dice
        )
        current_state, result, conquered = execute_attack(
            current_state, map_graph, attack_action, player_index, rng, defender_dice
        )
        all_results.append(result)

        if conquered:
            return current_state, all_results, True

        # Check if attacker reduced to 1
        if current_state.territories[action.source].armies <= 1:
            return current_state, all_results, False

    return current_state, all_results, False
