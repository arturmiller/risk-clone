"""Pydantic models for Risk game state."""

from pydantic import BaseModel, Field


class TerritoryState(BaseModel):
    """State of a single territory: who owns it and how many armies."""

    owner: int
    armies: int = Field(ge=1)


class PlayerState(BaseModel):
    """State of a single player."""

    index: int
    name: str
    is_alive: bool = True


class GameState(BaseModel):
    """Complete game state: all territories, players, and turn info."""

    territories: dict[str, TerritoryState]
    players: list[PlayerState]
    current_player_index: int = 0
    turn_number: int = 0
