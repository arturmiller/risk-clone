"""Fortification logic for Risk: path validation and army movement."""

from risk.models.actions import FortifyAction
from risk.models.game_state import GameState, TerritoryState


def validate_fortify(
    state: GameState,
    map_graph: object,
    action: FortifyAction,
    player_index: int,
) -> None:
    """Validate a fortification action. Raises ValueError on invalid move."""
    source_ts = state.territories[action.source]
    target_ts = state.territories[action.target]

    if source_ts.owner != player_index:
        raise ValueError(
            f"Player {player_index} does not own source territory '{action.source}'"
        )

    if target_ts.owner != player_index:
        raise ValueError(
            f"Player {player_index} does not own target territory '{action.target}'"
        )

    # Check connected path through friendly territories
    player_territories = {
        name
        for name, ts in state.territories.items()
        if ts.owner == player_index
    }
    reachable = map_graph.connected_territories(action.source, player_territories)  # type: ignore[union-attr]
    if action.target not in reachable:
        raise ValueError(
            f"Target '{action.target}' is not reachable from source "
            f"'{action.source}' through connected friendly path"
        )

    # Must leave at least 1 army on source
    if action.armies > source_ts.armies - 1:
        raise ValueError(
            f"Cannot move {action.armies} armies from '{action.source}' "
            f"which has {source_ts.armies} (must leave at least 1)"
        )


def execute_fortify(
    state: GameState,
    map_graph: object,
    action: FortifyAction,
    player_index: int,
) -> GameState:
    """Execute a fortification: move armies from source to target."""
    validate_fortify(state, map_graph, action, player_index)

    source_ts = state.territories[action.source]
    target_ts = state.territories[action.target]

    new_territories = dict(state.territories)
    new_territories[action.source] = TerritoryState(
        owner=source_ts.owner, armies=source_ts.armies - action.armies
    )
    new_territories[action.target] = TerritoryState(
        owner=target_ts.owner, armies=target_ts.armies + action.armies
    )

    return state.model_copy(update={"territories": new_territories})
