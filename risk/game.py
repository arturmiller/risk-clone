"""Game runner: full game loop from setup to victory."""

import random as _random
from typing import Any

from risk.engine.cards import create_deck, is_valid_set
from risk.engine.map_graph import MapGraph
from risk.engine.setup import setup_game
from risk.engine.turn import execute_turn
from risk.models.actions import (
    AttackAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.cards import Card
from risk.models.game_state import GameState


class RandomAgent:
    """A simple agent that makes valid random moves using a seeded RNG.

    Implements the PlayerAgent protocol for testing and simulation.
    The map_graph is injected by run_game before the game loop starts.
    """

    def __init__(self, rng: _random.Random | None = None) -> None:
        self._rng = rng or _random.Random()
        self._map_graph: MapGraph | None = None

    def choose_reinforcement_placement(
        self, state: GameState, armies: int
    ) -> ReinforcePlacementAction:
        """Distribute armies randomly among owned territories."""
        player_idx = state.current_player_index
        owned = [
            n for n, ts in state.territories.items() if ts.owner == player_idx
        ]
        placements: dict[str, int] = {}
        for _ in range(armies):
            t = self._rng.choice(owned)
            placements[t] = placements.get(t, 0) + 1
        return ReinforcePlacementAction(placements=placements)

    def choose_attack(self, state: GameState) -> AttackAction | None:
        """Attack from strongest territories against weakest neighbors."""
        mg = self._map_graph
        if mg is None:
            return None

        player_idx = state.current_player_index

        # Collect all valid attack options: (source, target, advantage)
        options: list[tuple[str, str, int]] = []
        for name, ts in state.territories.items():
            if ts.owner != player_idx or ts.armies < 2:
                continue
            for neighbor in mg.neighbors(name):
                nts = state.territories[neighbor]
                if nts.owner != player_idx:
                    advantage = ts.armies - nts.armies
                    options.append((name, neighbor, advantage))

        if not options:
            return None

        # Sort by advantage (most favorable first), with randomness for ties
        self._rng.shuffle(options)
        options.sort(key=lambda x: x[2], reverse=True)

        # Only stop if we have no good attacks (all disadvantaged) -- 15% stop
        best_advantage = options[0][2]
        if best_advantage <= 0 and self._rng.random() < 0.15:
            return None

        # Pick from top advantageous attacks
        source, target, _ = options[0]
        src_armies = state.territories[source].armies
        num_dice = min(3, src_armies - 1)
        return AttackAction(source=source, target=target, num_dice=num_dice)

    def choose_blitz(self, state: GameState) -> Any:
        """Not used -- regular attacks for granular testing."""
        return None

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        """50% chance to fortify between random connected friendly territories."""
        if self._rng.random() < 0.5:
            return None

        mg = self._map_graph
        if mg is None:
            return None

        player_idx = state.current_player_index
        sources = [
            n
            for n, ts in state.territories.items()
            if ts.owner == player_idx and ts.armies >= 2
        ]
        if not sources:
            return None

        source = self._rng.choice(sources)

        # Find connected friendly territories
        player_territories = {
            n
            for n, ts in state.territories.items()
            if ts.owner == player_idx
        }
        reachable = mg.connected_territories(source, player_territories)
        reachable.discard(source)

        if not reachable:
            return None

        target = self._rng.choice(list(reachable))
        armies = self._rng.randint(1, state.territories[source].armies - 1)

        return FortifyAction(source=source, target=target, armies=armies)

    def choose_card_trade(
        self, state: GameState, cards: list[Card], forced: bool
    ) -> TradeCardsAction | None:
        """Always trade if forced or if a valid set exists."""
        if len(cards) < 3:
            return None

        for i in range(len(cards)):
            for j in range(i + 1, len(cards)):
                for k in range(j + 1, len(cards)):
                    if is_valid_set([cards[i], cards[j], cards[k]]):
                        return TradeCardsAction(
                            cards=[cards[i], cards[j], cards[k]]
                        )
        return None

    def choose_defender_dice(
        self, state: GameState, territory: str, max_dice: int
    ) -> int:
        """Always roll max dice."""
        return max_dice


def run_game(
    map_graph: MapGraph,
    agents: dict[int, object],
    rng: _random.Random,
    max_turns: int = 5000,
) -> GameState:
    """Run a complete game of Risk from setup to victory.

    Args:
        map_graph: The map graph for the game.
        agents: Dict mapping player index to PlayerAgent instances.
        rng: Random source for game mechanics (dice, card draw).
        max_turns: Safety valve to prevent infinite loops.

    Returns:
        Final GameState with exactly 1 alive player owning all territories.

    Raises:
        RuntimeError: If game doesn't complete within max_turns.
    """
    num_players = len(agents)

    # Inject map_graph into any agent that accepts it (duck-typing, future-proofs for Hard bot)
    for agent in agents.values():
        if hasattr(agent, '_map_graph'):
            agent._map_graph = map_graph

    # Setup initial state
    state = setup_game(map_graph, num_players, rng)

    # Initialize deck
    deck = create_deck(map_graph.all_territories)
    rng.shuffle(deck)

    # Initialize cards and deck on state
    cards: dict[int, list[Card]] = {i: [] for i in range(num_players)}
    state = state.model_copy(update={"deck": deck, "cards": cards})

    # Game loop
    for _ in range(max_turns):
        state, victory = execute_turn(state, map_graph, agents, rng)
        if victory:
            return state

    raise RuntimeError(f"Game did not complete within {max_turns} turns")
