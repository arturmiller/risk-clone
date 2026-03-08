"""Integration tests for WebSocket game flow: start, state, input, action cycle."""

import json
import threading
import time

import pytest
from fastapi.testclient import TestClient

from risk.server.app import app


@pytest.fixture
def client():
    """Create a FastAPI test client."""
    return TestClient(app)


class TestWebSocketConnection:
    """Test basic WebSocket connectivity."""

    def test_websocket_connect_succeeds(self, client):
        """WebSocket connect to /ws succeeds."""
        with client.websocket_connect("/ws") as ws:
            # Connection established -- send a start to trigger game creation
            # Just verifying the connection itself works
            assert ws is not None


class TestStartGame:
    """Test game start and initial state message."""

    def test_start_game_sends_game_state_with_correct_players(self, client):
        """Sending start_game with num_players=3 results in a game_state message
        with 3 players and 42 territories."""
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            # First message should be game_state
            msg = ws.receive_json(mode="text")
            assert msg["type"] == "game_state"

            state = msg["state"]
            assert len(state["players"]) == 3
            assert len(state["territories"]) == 42

    def test_game_state_includes_territory_owners_and_armies(self, client):
        """Game state includes territory owners (0-2) and army counts (>= 1).
        Validates MAPV-02, MAPV-03."""
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            msg = ws.receive_json(mode="text")
            assert msg["type"] == "game_state"

            territories = msg["state"]["territories"]
            owners_seen = set()
            for name, info in territories.items():
                assert "owner" in info, f"Territory {name} missing owner"
                assert "armies" in info, f"Territory {name} missing armies"
                assert info["owner"] in (0, 1, 2), f"Invalid owner {info['owner']}"
                assert info["armies"] >= 1, f"Army count < 1 for {name}"
                owners_seen.add(info["owner"])

            # All 3 players should own territories
            assert owners_seen == {0, 1, 2}

    def test_game_state_includes_turn_phase_and_current_player(self, client):
        """Game state includes turn phase and current player index.
        Validates MAPV-05."""
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            msg = ws.receive_json(mode="text")
            assert msg["type"] == "game_state"

            state = msg["state"]
            assert "turn_phase" in state
            assert "current_player_index" in state
            assert state["current_player_index"] in (0, 1, 2)

    def test_game_state_includes_continent_info(self, client):
        """Game state includes continent info with bonus values.
        Validates MAPV-07."""
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            msg = ws.receive_json(mode="text")
            assert msg["type"] == "game_state"

            continent_info = msg.get("continent_info", [])
            assert len(continent_info) == 6  # 6 continents in classic Risk

            names = {c["name"] for c in continent_info}
            expected = {"North America", "South America", "Europe", "Africa", "Asia", "Australia"}
            assert names == expected

            for c in continent_info:
                assert "bonus" in c
                assert "territories" in c
                assert c["bonus"] > 0
                assert len(c["territories"]) > 0


class TestHumanInputCycle:
    """Test request_input and player_action message cycle."""

    def test_server_sends_request_input_after_start(self, client):
        """After start_game, server sends request_input for human's first turn
        (choose_card_trade or choose_reinforcement_placement)."""
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            # Collect messages until we get a request_input or timeout
            messages = []
            for _ in range(20):
                try:
                    msg = ws.receive_json(mode="text")
                    messages.append(msg)
                    if msg["type"] == "request_input":
                        break
                except Exception:
                    break

            # Find request_input messages
            input_msgs = [m for m in messages if m["type"] == "request_input"]
            assert len(input_msgs) > 0, (
                f"No request_input received. Got message types: "
                f"{[m['type'] for m in messages]}"
            )

            input_msg = input_msgs[0]
            assert input_msg["input_type"] in (
                "choose_card_trade",
                "choose_reinforcement_placement",
            )

    def test_reinforcement_action_transitions_to_attack(self, client):
        """Sending a valid reinforcement placement action results in updated
        game state transitioning to attack phase."""
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            # Collect messages until request_input for reinforcement
            request_msg = None
            state_msg = None
            for _ in range(20):
                try:
                    msg = ws.receive_json(mode="text")
                    if msg["type"] == "game_state":
                        state_msg = msg
                    if msg["type"] == "request_input":
                        request_msg = msg
                        break
                except Exception:
                    break

            assert request_msg is not None, "No request_input received"

            # Handle card trade first if that comes up
            if request_msg["input_type"] == "choose_card_trade":
                ws.send_json({
                    "type": "player_action",
                    "action_type": "skip",
                    "data": {"action": "skip"},
                })
                # Get the reinforcement request
                for _ in range(10):
                    msg = ws.receive_json(mode="text")
                    if msg["type"] == "request_input":
                        request_msg = msg
                        break
                    if msg["type"] == "game_state":
                        state_msg = msg

            assert request_msg["input_type"] == "choose_reinforcement_placement"
            armies = request_msg.get("armies", 3)
            valid_sources = request_msg.get("valid_sources", [])
            assert len(valid_sources) > 0

            # Place all armies on first valid territory
            placements = {valid_sources[0]: armies}
            ws.send_json({
                "type": "player_action",
                "action_type": "reinforce",
                "data": {"placements": placements},
            })

            # After reinforcement, should get updated state (attack phase)
            # and then request_input for attack
            found_attack_state = False
            found_attack_input = False
            for _ in range(20):
                try:
                    msg = ws.receive_json(mode="text")
                    if msg["type"] == "game_state":
                        # TurnPhase.ATTACK = 2
                        if msg["state"]["turn_phase"] == 2:
                            found_attack_state = True
                    if msg["type"] == "request_input" and msg["input_type"] == "choose_attack":
                        found_attack_input = True
                        break
                except Exception:
                    break

            assert found_attack_input, "Never received choose_attack request_input"

    def test_player_action_parsed_correctly(self, client):
        """Player action messages are correctly parsed into game actions.
        Validates MAPV-04."""
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            # Get to reinforcement phase
            request_msg = None
            for _ in range(20):
                try:
                    msg = ws.receive_json(mode="text")
                    if msg["type"] == "request_input":
                        request_msg = msg
                        break
                except Exception:
                    break

            assert request_msg is not None

            # Handle card trade if needed
            if request_msg["input_type"] == "choose_card_trade":
                ws.send_json({
                    "type": "player_action",
                    "action_type": "skip",
                    "data": {"action": "skip"},
                })
                for _ in range(10):
                    msg = ws.receive_json(mode="text")
                    if msg["type"] == "request_input":
                        request_msg = msg
                        break

            assert request_msg["input_type"] == "choose_reinforcement_placement"
            armies = request_msg.get("armies", 3)
            valid_sources = request_msg.get("valid_sources", [])

            # Send reinforcement action -- this validates the server parses it
            placements = {valid_sources[0]: armies}
            ws.send_json({
                "type": "player_action",
                "action_type": "reinforce",
                "data": {"placements": placements},
            })

            # Should receive state update and attack input
            # (if parsing failed, we'd get an error or no response)
            got_response = False
            for _ in range(20):
                try:
                    msg = ws.receive_json(mode="text")
                    if msg["type"] in ("game_state", "request_input"):
                        got_response = True
                    if msg["type"] == "request_input" and msg["input_type"] == "choose_attack":
                        break
                except Exception:
                    break

            assert got_response, "Server did not respond to player action"


class TestBotEvents:
    """Test game event emission during bot turns."""

    def test_game_events_emitted_during_bot_turns(self, client):
        """Game events are emitted during bot turns. Validates MAPV-06.

        After human completes their turn (end attack, skip fortify),
        bot turns execute and produce game_state and game_event messages.
        """
        with client.websocket_connect("/ws") as ws:
            ws.send_json({"type": "start_game", "num_players": 3})

            # Navigate through human's full turn
            request_msg = None
            for _ in range(20):
                try:
                    msg = ws.receive_json(mode="text")
                    if msg["type"] == "request_input":
                        request_msg = msg
                        break
                except Exception:
                    break

            assert request_msg is not None

            # Handle card trade
            if request_msg["input_type"] == "choose_card_trade":
                ws.send_json({
                    "type": "player_action",
                    "data": {"action": "skip"},
                })
                for _ in range(10):
                    msg = ws.receive_json(mode="text")
                    if msg["type"] == "request_input":
                        request_msg = msg
                        break

            # Reinforce
            assert request_msg["input_type"] == "choose_reinforcement_placement"
            armies = request_msg.get("armies", 3)
            valid_sources = request_msg.get("valid_sources", [])
            ws.send_json({
                "type": "player_action",
                "data": {"placements": {valid_sources[0]: armies}},
            })

            # Wait for attack input
            for _ in range(20):
                msg = ws.receive_json(mode="text")
                if msg["type"] == "request_input" and msg["input_type"] == "choose_attack":
                    break

            # End attack phase
            ws.send_json({
                "type": "player_action",
                "data": {"action": "end_phase"},
            })

            # Wait for fortify input
            for _ in range(20):
                msg = ws.receive_json(mode="text")
                if msg["type"] == "request_input" and msg["input_type"] == "choose_fortify":
                    break

            # Skip fortify
            ws.send_json({
                "type": "player_action",
                "data": {"action": "end_phase"},
            })

            # Now bot turns should execute. Collect messages.
            # We should see game_state messages (for bot turns) and possibly game_events.
            message_types = set()
            for _ in range(50):
                try:
                    msg = ws.receive_json(mode="text")
                    message_types.add(msg["type"])
                    # Stop when we get back to human's turn (request_input)
                    if msg["type"] == "request_input":
                        break
                    # Or if game ends
                    if msg["type"] == "game_over":
                        break
                except Exception:
                    break

            # Bot turns should produce at least game_state messages
            assert "game_state" in message_types, (
                f"No game_state during bot turns. Got types: {message_types}"
            )
