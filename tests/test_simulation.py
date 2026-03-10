"""Tests for AI-vs-AI simulation mode (BOTS-04).

Verifies GameManager creates all-bot games in simulation mode,
player names are 'Bot N' (no 'You'), and games run to completion.
"""

import pathlib
import time

import pytest

from risk.engine.map_graph import MapGraph, load_map

# ---------------------------------------------------------------------------
# Module-level shared fixtures
# ---------------------------------------------------------------------------

_DATA_DIR = pathlib.Path(__file__).resolve().parent.parent / "risk" / "data"
MAP_DATA = load_map(_DATA_DIR / "classic.json")
MAP_GRAPH = MapGraph(MAP_DATA)


# ---------------------------------------------------------------------------
# BOTS-04: Simulation mode agent creation
# ---------------------------------------------------------------------------

class TestSimulationMode:
    def test_simulation_creates_all_bot_agents(self):
        """GameManager in simulation mode has no human agent."""
        from risk.server.game_manager import GameManager

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=3,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
            difficulty="medium",
            game_mode="simulation",
        )

        # In simulation mode, human_agent should be None
        assert gm.human_agent is None, "Simulation mode should not create a human agent"

        # All agents should be bot agents (not HumanWebSocketAgent)
        from risk.server.human_agent import HumanWebSocketAgent
        for idx, agent in gm.agents.items():
            assert not isinstance(agent, HumanWebSocketAgent), (
                f"Player {idx} should be a bot in simulation mode, got {type(agent)}"
            )

    def test_simulation_hard_difficulty(self):
        """GameManager in simulation mode with hard difficulty creates HardAgents."""
        from risk.server.game_manager import GameManager
        from risk.bots.hard import HardAgent

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=3,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
            difficulty="hard",
            game_mode="simulation",
        )

        assert gm.human_agent is None
        for idx, agent in gm.agents.items():
            assert isinstance(agent, HardAgent), (
                f"Player {idx} should be HardAgent, got {type(agent)}"
            )

    def test_simulation_names_all_bots(self):
        """All player names are 'Bot N', not 'You'."""
        from risk.server.game_manager import GameManager

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=3,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
            difficulty="easy",
            game_mode="simulation",
            bot_delay=0.0,
        )

        gm.start_game()

        # Wait briefly for game to start and send initial state
        time.sleep(1)

        # Find game_state messages
        state_msgs = [m for m in sent if m.get("type") == "game_state"]
        assert len(state_msgs) > 0, "Should have sent at least one game_state message"

        # Check player names -- none should be "You"
        first_state = state_msgs[0]
        players = first_state["state"]["players"]
        for p in players:
            name = p.get("name", "")
            assert name != "You", (
                f"Simulation mode should not have 'You' as player name, got: {name}"
            )
            assert name.startswith("Bot"), (
                f"All simulation players should be named 'Bot N', got: {name}"
            )

        gm.cancel_game()


# ---------------------------------------------------------------------------
# BOTS-04: Simulation game completion
# ---------------------------------------------------------------------------

class TestSimulationCompletion:
    def test_simulation_game_completes(self):
        """A simulation game runs to game_over."""
        from risk.server.game_manager import GameManager

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=2,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
            bot_delay=0.0,
            difficulty="easy",
            game_mode="simulation",
        )

        gm.start_game()

        # Wait for game to complete
        timeout = 30  # seconds
        start = time.time()
        while time.time() - start < timeout:
            game_over_msgs = [m for m in sent if m.get("type") == "game_over"]
            if game_over_msgs:
                break
            time.sleep(0.1)

        game_over_msgs = [m for m in sent if m.get("type") == "game_over"]
        assert len(game_over_msgs) == 1, (
            f"Expected exactly 1 game_over message, got {len(game_over_msgs)}"
        )

        gm.cancel_game()

    def test_simulation_emits_game_over(self):
        """Verify game_over message sent via callback with correct structure."""
        from risk.server.game_manager import GameManager

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=2,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
            bot_delay=0.0,
            difficulty="easy",
            game_mode="simulation",
        )

        gm.start_game()

        timeout = 30
        start = time.time()
        while time.time() - start < timeout:
            game_over_msgs = [m for m in sent if m.get("type") == "game_over"]
            if game_over_msgs:
                break
            time.sleep(0.1)

        game_over_msgs = [m for m in sent if m.get("type") == "game_over"]
        assert len(game_over_msgs) >= 1, "Should emit game_over message"

        msg = game_over_msgs[0]
        assert "winner" in msg, "game_over should include winner index"
        assert "winner_name" in msg, "game_over should include winner name"
        assert msg["is_human_winner"] is False, "Simulation winner should not be human"

        gm.cancel_game()
