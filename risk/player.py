"""Player agent protocol for Risk game."""

from typing import Protocol

from risk.models.cards import Card
from risk.models.actions import (
    AttackAction,
    BlitzAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.game_state import GameState


class PlayerAgent(Protocol):
    """Interface for human and bot players.

    Each method represents a decision point in the game.
    Implementations must provide all methods.
    """

    def choose_reinforcement_placement(
        self, state: GameState, armies: int
    ) -> ReinforcePlacementAction:
        """Choose where to place reinforcement armies."""
        ...

    def choose_attack(self, state: GameState) -> AttackAction | None:
        """Choose an attack action, or None to end the attack phase."""
        ...

    def choose_blitz(self, state: GameState) -> BlitzAction | None:
        """Choose a blitz attack, or None to skip."""
        ...

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        """Choose a fortify action, or None to skip."""
        ...

    def choose_card_trade(
        self, state: GameState, cards: list[Card], forced: bool
    ) -> TradeCardsAction | None:
        """Choose cards to trade, or None if not forced."""
        ...

    def choose_defender_dice(
        self, state: GameState, territory: str, max_dice: int
    ) -> int:
        """Choose number of defender dice to roll."""
        ...
