"""Reinforcement calculation for Risk game."""

from risk.engine.map_graph import MapGraph
from risk.models.game_state import GameState


def calculate_reinforcements(
    state: GameState, map_graph: MapGraph, player_index: int
) -> int:
    """Calculate total reinforcement armies for a player.

    Base: max(territories_owned // 3, 3)
    Plus: bonus for each fully controlled continent.
    """
    player_territories = {
        name
        for name, ts in state.territories.items()
        if ts.owner == player_index
    }

    # Base reinforcements: territory count / 3, minimum 3
    base = max(len(player_territories) // 3, 3)

    # Continent bonuses
    bonus = 0
    for continent in map_graph._continent_bonuses:
        if map_graph.controls_continent(continent, player_territories):
            bonus += map_graph.continent_bonus(continent)

    return base + bonus
