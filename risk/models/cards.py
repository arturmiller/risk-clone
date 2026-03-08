"""Card and turn phase models for Risk game."""

from enum import auto, Enum

from pydantic import BaseModel


class CardType(Enum):
    """Types of Risk territory cards."""

    INFANTRY = auto()
    CAVALRY = auto()
    ARTILLERY = auto()
    WILD = auto()


class TurnPhase(Enum):
    """Phases within a single player's turn."""

    REINFORCE = auto()
    ATTACK = auto()
    FORTIFY = auto()


class Card(BaseModel):
    """A Risk territory card (or wild card)."""

    territory: str | None
    card_type: CardType
