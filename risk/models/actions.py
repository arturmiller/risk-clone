"""Action models for player moves in Risk."""

from pydantic import BaseModel, Field, field_validator

from risk.models.cards import Card


class AttackAction(BaseModel):
    """A single attack from source to target with N dice."""

    source: str
    target: str
    num_dice: int = Field(ge=1, le=3)


class BlitzAction(BaseModel):
    """Auto-resolve attack from source to target."""

    source: str
    target: str


class FortifyAction(BaseModel):
    """Move armies from source to target during fortify phase."""

    source: str
    target: str
    armies: int = Field(ge=1)


class TradeCardsAction(BaseModel):
    """Trade exactly 3 cards for bonus armies."""

    cards: list[Card]

    @field_validator("cards")
    @classmethod
    def must_be_exactly_three(cls, v: list[Card]) -> list[Card]:
        if len(v) != 3:
            msg = f"Must trade exactly 3 cards, got {len(v)}"
            raise ValueError(msg)
        return v


class ReinforcePlacementAction(BaseModel):
    """Place reinforcement armies on owned territories."""

    placements: dict[str, int]


class AdvanceArmiesAction(BaseModel):
    """How many armies to advance into a just-conquered territory."""

    armies: int = Field(ge=1)
