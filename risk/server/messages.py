"""Pydantic models for WebSocket message protocol between server and browser client."""

from typing import Any, Literal

from pydantic import BaseModel, Field

from risk.engine.map_graph import MapGraph
from risk.models.game_state import GameState


# --- Server -> Client messages ---


class GameStateMessage(BaseModel):
    """Full game state snapshot sent to the browser."""

    type: Literal["game_state"] = "game_state"
    state: dict[str, Any]
    prompt: str | None = None
    continent_info: list[dict[str, Any]] = []


class RequestInputMessage(BaseModel):
    """Request human player input for a specific decision."""

    type: Literal["request_input"] = "request_input"
    input_type: str
    valid_sources: list[str] | None = None
    valid_targets: list[str] | None = None
    armies: int | None = None
    max_armies: int | None = None
    forced: bool | None = None
    cards: list[dict[str, Any]] | None = None
    max_dice: int | None = None


class GameEventMessage(BaseModel):
    """Game event notification (attack, conquest, elimination, etc.)."""

    type: Literal["game_event"] = "game_event"
    event: str
    details: dict[str, Any]


class GameOverMessage(BaseModel):
    """Game over notification with winner info."""

    type: Literal["game_over"] = "game_over"
    winner: int
    winner_name: str
    is_human_winner: bool


# --- Client -> Server messages ---


class StartGameMessage(BaseModel):
    """Client request to start a new game."""

    type: Literal["start_game"] = "start_game"
    num_players: int = Field(ge=2, le=6)
    difficulty: str = "easy"


class PlayerActionMessage(BaseModel):
    """Client action during gameplay."""

    type: Literal["player_action"] = "player_action"
    action_type: str
    data: dict[str, Any]


# Union types for dispatch
ServerMessage = GameStateMessage | RequestInputMessage | GameEventMessage | GameOverMessage
ClientMessage = StartGameMessage | PlayerActionMessage


# --- Helper functions ---


def state_to_message(
    state: GameState, map_graph: MapGraph, prompt: str | None
) -> dict[str, Any]:
    """Convert a GameState to a serialized GameStateMessage dict.

    Includes full state snapshot plus continent metadata from the map.
    """
    continent_info = []
    for continent_name in sorted(map_graph._continent_territories.keys()):
        continent_info.append({
            "name": continent_name,
            "bonus": map_graph.continent_bonus(continent_name),
            "territories": sorted(map_graph.continent_territories(continent_name)),
        })

    msg = GameStateMessage(
        state=state.model_dump(mode="json"),
        prompt=prompt,
        continent_info=continent_info,
    )
    return msg.model_dump(mode="json")
