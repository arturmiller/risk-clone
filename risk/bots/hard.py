"""HardAgent: human-competitive bot for Risk using multi-factor heuristic scoring.

Skeleton implementation -- all protocol methods delegate to simple fallback behavior
so the class is immediately usable in tests. Strategic logic to be filled in Plan 02.
"""

import random as _random
from typing import Any

from risk.engine.cards import is_valid_set
from risk.engine.map_graph import MapGraph
from risk.models.actions import (
    AttackAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.cards import Card
from risk.models.game_state import GameState


# Precomputed attack probabilities from exact dice math (ties go to defender).
# Key: (attacker_dice, defender_dice) -> tuple of probabilities.
# For 2-die comparisons: (p_attacker_wins_both, p_defender_wins_both, p_split)
# For 1-die comparisons: (p_attacker_wins, p_defender_wins)
ATTACK_PROBABILITIES: dict[tuple[int, int], tuple[float, ...]] = {
    (1, 1): (0.4167, 0.5833),
    (2, 1): (0.5787, 0.4213),
    (3, 1): (0.6597, 0.3403),
    (1, 2): (0.2546, 0.7454),
    (2, 2): (0.2276, 0.4483, 0.3241),
    (3, 2): (0.3717, 0.2926, 0.3358),
}

# Tunable weights for the scoring function (to be refined in Plan 02)
CONTINENT_PROGRESS_WEIGHT = 3.0
BORDER_SECURITY_WEIGHT = 2.0
THREAT_WEIGHT = 1.5
CARD_TIMING_THRESHOLD = 4
ATTACK_PROBABILITY_THRESHOLD = 0.6


class HardAgent:
    """Human-competitive Risk bot using multi-factor heuristic scoring.

    Implements the PlayerAgent protocol. Map graph is injected after construction
    via agent._map_graph = map_graph (same pattern as MediumAgent).

    This is a skeleton: each method uses simple fallback logic. Plan 02 replaces
    these with strategic implementations using ATTACK_PROBABILITIES and the
    scoring weights above.
    """

    def __init__(self, rng: _random.Random | None = None) -> None:
        self._rng = rng or _random.Random()
        self._map_graph: MapGraph | None = None

    # ------------------------------------------------------------------
    # Protocol methods (skeleton -- fallback behavior)
    # ------------------------------------------------------------------

    def choose_reinforcement_placement(
        self, state: GameState, armies: int
    ) -> ReinforcePlacementAction:
        """Place all armies on a random owned territory.

        Skeleton: will be replaced with border-security-ratio based placement.
        """
        player = state.current_player_index
        owned = [t for t, ts in state.territories.items() if ts.owner == player]
        if not owned:
            return ReinforcePlacementAction(placements={})
        target = self._rng.choice(owned)
        return ReinforcePlacementAction(placements={target: armies})

    def choose_attack(self, state: GameState) -> AttackAction | None:
        """Return None (no attacks).

        Skeleton: will be replaced with threat-aware attack selection.
        """
        return None

    def choose_blitz(self, state: GameState) -> Any:
        """Not used -- regular attacks for granular control."""
        return None

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        """Return None (no fortification).

        Skeleton: will be replaced with interior-to-border fortification.
        """
        return None

    def choose_card_trade(
        self, state: GameState, cards: list[Card], forced: bool
    ) -> TradeCardsAction | None:
        """Trade any valid set if forced, else None.

        Skeleton: will be replaced with strategic card timing.
        """
        if not forced:
            return None
        if len(cards) < 3:
            return None
        for i in range(len(cards)):
            for j in range(i + 1, len(cards)):
                for k in range(j + 1, len(cards)):
                    if is_valid_set([cards[i], cards[j], cards[k]]):
                        return TradeCardsAction(cards=[cards[i], cards[j], cards[k]])
        return None

    def choose_advance_armies(
        self, state: GameState, source: str, target: str, min_armies: int, max_armies: int
    ) -> int:
        """Return min_armies.

        Skeleton: will be replaced with context-aware advancement.
        """
        return min_armies

    def choose_defender_dice(
        self, state: GameState, territory: str, max_dice: int
    ) -> int:
        """Always roll max dice."""
        return max_dice
