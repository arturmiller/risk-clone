"""Territory distribution and initial army placement for Risk game setup."""

import random as _random

from risk.engine.map_graph import MapGraph
from risk.models.game_state import GameState, PlayerState, TerritoryState

# Classic Risk starting armies by player count.
STARTING_ARMIES: dict[int, int] = {
    2: 40,
    3: 35,
    4: 30,
    5: 25,
    6: 20,
}


def setup_game(
    map_graph: MapGraph,
    num_players: int,
    rng: _random.Random | None = None,
) -> GameState:
    """Set up a new Risk game: distribute territories and place armies.

    Args:
        map_graph: The map graph defining available territories.
        num_players: Number of players (2-6).
        rng: Optional random source for reproducibility.

    Returns:
        A fully initialized GameState.

    Raises:
        ValueError: If num_players is not between 2 and 6.
    """
    if num_players < 2 or num_players > 6:
        raise ValueError(
            f"Player count must be 2-6, got {num_players}"
        )

    if rng is None:
        rng = _random.Random()

    # Shuffle territories for random distribution
    territories = list(map_graph.all_territories)
    rng.shuffle(territories)

    # Round-robin deal: territory i goes to player i % num_players
    ownership: dict[int, list[str]] = {p: [] for p in range(num_players)}
    for i, territory in enumerate(territories):
        ownership[i % num_players].append(territory)

    # Build territory states: start with 1 army each
    territory_states: dict[str, TerritoryState] = {}
    for player_idx, owned in ownership.items():
        for territory in owned:
            territory_states[territory] = TerritoryState(
                owner=player_idx, armies=1
            )

    # Distribute remaining armies randomly among owned territories
    starting = STARTING_ARMIES[num_players]
    for player_idx, owned in ownership.items():
        remaining = starting - len(owned)
        for _ in range(remaining):
            target = rng.choice(owned)
            territory_states[target] = TerritoryState(
                owner=player_idx,
                armies=territory_states[target].armies + 1,
            )

    # Create players
    players = [
        PlayerState(index=i, name=f"Player {i + 1}")
        for i in range(num_players)
    ]

    return GameState(territories=territory_states, players=players)
