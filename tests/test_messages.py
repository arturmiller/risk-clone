"""Tests for WebSocket message protocol models."""

import pytest

from risk.models.cards import Card, CardType, TurnPhase
from risk.models.game_state import GameState, PlayerState, TerritoryState
from risk.server.messages import (
    GameEventMessage,
    GameOverMessage,
    GameStateMessage,
    PlayerActionMessage,
    RequestInputMessage,
    StartGameMessage,
    state_to_message,
)


@pytest.fixture
def simple_state() -> GameState:
    """Minimal GameState for testing."""
    return GameState(
        territories={
            "Alaska": TerritoryState(owner=0, armies=3),
            "Kamchatka": TerritoryState(owner=1, armies=2),
            "Northwest_Territory": TerritoryState(owner=0, armies=1),
        },
        players=[
            PlayerState(index=0, name="Human", is_alive=True),
            PlayerState(index=1, name="Bot 1", is_alive=True),
        ],
        current_player_index=0,
        turn_number=1,
        turn_phase=TurnPhase.ATTACK,
        trade_count=0,
        cards={0: [], 1: []},
        deck=[],
        conquered_this_turn=False,
    )


class TestGameStateMessage:
    def test_serializes_with_type(self, simple_state: GameState) -> None:
        msg = GameStateMessage(
            state=simple_state.model_dump(mode="json"),
            prompt="Your turn: Attack or End Phase",
            continent_info=[],
        )
        data = msg.model_dump(mode="json")
        assert data["type"] == "game_state"
        assert data["prompt"] == "Your turn: Attack or End Phase"

    def test_includes_territory_data(self, simple_state: GameState) -> None:
        msg = GameStateMessage(
            state=simple_state.model_dump(mode="json"),
            prompt=None,
            continent_info=[],
        )
        data = msg.model_dump(mode="json")
        assert "Alaska" in data["state"]["territories"]
        assert data["state"]["territories"]["Alaska"]["owner"] == 0
        assert data["state"]["territories"]["Alaska"]["armies"] == 3

    def test_includes_turn_info(self, simple_state: GameState) -> None:
        msg = GameStateMessage(
            state=simple_state.model_dump(mode="json"),
            prompt=None,
            continent_info=[],
        )
        data = msg.model_dump(mode="json")
        assert data["state"]["current_player_index"] == 0
        assert data["state"]["turn_number"] == 1


class TestRequestInputMessage:
    def test_serializes_with_type(self) -> None:
        msg = RequestInputMessage(
            input_type="choose_attack",
            valid_sources=["Alaska"],
            valid_targets=["Kamchatka"],
        )
        data = msg.model_dump(mode="json")
        assert data["type"] == "request_input"
        assert data["input_type"] == "choose_attack"

    def test_optional_fields(self) -> None:
        msg = RequestInputMessage(input_type="choose_fortify")
        data = msg.model_dump(mode="json")
        assert data["valid_sources"] is None
        assert data["valid_targets"] is None
        assert data["armies"] is None
        assert data["forced"] is None
        assert data["cards"] is None
        assert data["max_dice"] is None


class TestGameEventMessage:
    def test_attack_event(self) -> None:
        msg = GameEventMessage(
            event="attack",
            details={"source": "Alaska", "target": "Kamchatka", "attacker_dice": [6, 5], "defender_dice": [3]},
        )
        data = msg.model_dump(mode="json")
        assert data["type"] == "game_event"
        assert data["event"] == "attack"
        assert data["details"]["source"] == "Alaska"

    def test_conquest_event(self) -> None:
        msg = GameEventMessage(
            event="conquest",
            details={"territory": "Kamchatka", "attacker": 0},
        )
        data = msg.model_dump(mode="json")
        assert data["event"] == "conquest"

    def test_card_trade_event(self) -> None:
        msg = GameEventMessage(
            event="card_trade",
            details={"player": 0, "bonus": 4},
        )
        data = msg.model_dump(mode="json")
        assert data["event"] == "card_trade"

    def test_elimination_event(self) -> None:
        msg = GameEventMessage(
            event="elimination",
            details={"eliminated_player": 1, "by_player": 0},
        )
        data = msg.model_dump(mode="json")
        assert data["event"] == "elimination"

    def test_reinforcement_event(self) -> None:
        msg = GameEventMessage(
            event="reinforcement",
            details={"player": 0, "armies": 5},
        )
        data = msg.model_dump(mode="json")
        assert data["event"] == "reinforcement"


class TestGameOverMessage:
    def test_serializes_with_type(self) -> None:
        msg = GameOverMessage(
            winner=0,
            winner_name="Human",
            is_human_winner=True,
        )
        data = msg.model_dump(mode="json")
        assert data["type"] == "game_over"
        assert data["winner"] == 0
        assert data["is_human_winner"] is True


class TestStartGameMessage:
    def test_parses_from_dict(self) -> None:
        msg = StartGameMessage.model_validate(
            {"type": "start_game", "num_players": 4}
        )
        assert msg.type == "start_game"
        assert msg.num_players == 4


class TestPlayerActionMessage:
    def test_attack_action(self) -> None:
        msg = PlayerActionMessage.model_validate(
            {
                "type": "player_action",
                "action_type": "choose_attack",
                "data": {"source": "Alaska", "target": "Kamchatka", "num_dice": 3},
            }
        )
        assert msg.action_type == "choose_attack"
        assert msg.data["source"] == "Alaska"

    def test_fortify_action(self) -> None:
        msg = PlayerActionMessage.model_validate(
            {
                "type": "player_action",
                "action_type": "choose_fortify",
                "data": {"source": "Alaska", "target": "Northwest_Territory", "armies": 2},
            }
        )
        assert msg.action_type == "choose_fortify"

    def test_reinforce_action(self) -> None:
        msg = PlayerActionMessage.model_validate(
            {
                "type": "player_action",
                "action_type": "choose_reinforcement_placement",
                "data": {"placements": {"Alaska": 3, "Northwest_Territory": 2}},
            }
        )
        assert msg.action_type == "choose_reinforcement_placement"

    def test_card_trade_action(self) -> None:
        msg = PlayerActionMessage.model_validate(
            {
                "type": "player_action",
                "action_type": "choose_card_trade",
                "data": {"cards": [{"territory": "Alaska", "card_type": 1}]},
            }
        )
        assert msg.action_type == "choose_card_trade"

    def test_end_phase_action(self) -> None:
        msg = PlayerActionMessage.model_validate(
            {
                "type": "player_action",
                "action_type": "end_phase",
                "data": {},
            }
        )
        assert msg.action_type == "end_phase"


class TestStateToMessage:
    def test_converts_game_state(self, simple_state: GameState, map_graph) -> None:
        result = state_to_message(simple_state, map_graph, "Your turn")
        assert result["type"] == "game_state"
        assert result["prompt"] == "Your turn"
        assert "Alaska" in result["state"]["territories"]
        assert result["state"]["territories"]["Alaska"]["owner"] == 0
        assert result["state"]["territories"]["Alaska"]["armies"] == 3

    def test_includes_continent_info(self, simple_state: GameState, map_graph) -> None:
        result = state_to_message(simple_state, map_graph, None)
        assert "continent_info" in result
        assert len(result["continent_info"]) > 0
        # Check structure of continent info
        continent = result["continent_info"][0]
        assert "name" in continent
        assert "bonus" in continent
        assert "territories" in continent

    def test_continent_bonus_values(self, simple_state: GameState, map_graph) -> None:
        result = state_to_message(simple_state, map_graph, None)
        # Find North America in continent info
        na = next(
            (c for c in result["continent_info"] if c["name"] == "North America"),
            None,
        )
        assert na is not None
        assert na["bonus"] == 5
        assert "Alaska" in na["territories"]
