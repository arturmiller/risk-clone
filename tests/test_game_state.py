"""Tests for game state Pydantic models."""

import pytest
from pydantic import ValidationError

from risk.models.game_state import GameState, PlayerState, TerritoryState


class TestTerritoryState:
    def test_territory_state_valid(self) -> None:
        ts = TerritoryState(owner=0, armies=3)
        assert ts.owner == 0
        assert ts.armies == 3

    def test_territory_state_rejects_zero_armies(self) -> None:
        with pytest.raises(ValidationError):
            TerritoryState(owner=0, armies=0)

    def test_territory_state_rejects_negative_armies(self) -> None:
        with pytest.raises(ValidationError):
            TerritoryState(owner=0, armies=-1)


class TestPlayerState:
    def test_player_state_defaults(self) -> None:
        ps = PlayerState(index=0, name="Alice")
        assert ps.is_alive is True

    def test_player_state_explicit(self) -> None:
        ps = PlayerState(index=1, name="Bob", is_alive=False)
        assert ps.index == 1
        assert ps.name == "Bob"
        assert ps.is_alive is False


class TestGameState:
    def test_game_state_creation(self) -> None:
        territories = {
            "Alaska": TerritoryState(owner=0, armies=2),
            "Kamchatka": TerritoryState(owner=1, armies=1),
        }
        players = [
            PlayerState(index=0, name="Alice"),
            PlayerState(index=1, name="Bob"),
        ]
        gs = GameState(territories=territories, players=players)
        assert gs.current_player_index == 0
        assert gs.turn_number == 0
        assert len(gs.territories) == 2
        assert len(gs.players) == 2

    def test_game_state_serialization_roundtrip(self) -> None:
        territories = {
            "Alaska": TerritoryState(owner=0, armies=2),
            "Kamchatka": TerritoryState(owner=1, armies=1),
        }
        players = [
            PlayerState(index=0, name="Alice"),
            PlayerState(index=1, name="Bob"),
        ]
        gs = GameState(
            territories=territories,
            players=players,
            current_player_index=1,
            turn_number=5,
        )
        data = gs.model_dump()
        restored = GameState.model_validate(data)
        assert restored == gs

    def test_game_state_empty_territories(self) -> None:
        players = [PlayerState(index=0, name="Alice")]
        gs = GameState(territories={}, players=players)
        assert gs.territories == {}
