"""GameManager: creates and runs Risk games with human + bot players."""

import asyncio
import random
import time
import threading
from typing import Any, Callable, Awaitable

from risk.engine.cards import create_deck
from risk.engine.map_graph import MapGraph
from risk.engine.setup import setup_game
from risk.engine.turn import execute_turn
from risk.game import RandomAgent
from risk.models.cards import Card, TurnPhase
from risk.models.game_state import GameState, PlayerState
from risk.server.human_agent import HumanWebSocketAgent
from risk.server.messages import (
    GameEventMessage,
    GameOverMessage,
    GameStateMessage,
    state_to_message,
)


class GameManager:
    """Manages game lifecycle: setup, running in background thread, event emission."""

    BOT_DELAY: float = 0.5  # seconds between bot actions

    def __init__(self) -> None:
        self.agents: dict[int, Any] = {}
        self.human_agent: HumanWebSocketAgent | None = None
        self._map_graph: MapGraph | None = None
        self._cancel_flag = threading.Event()
        self._send_callback: Callable[[dict[str, Any]], None] | None = None
        self._game_thread: threading.Thread | None = None

    def setup(
        self,
        num_players: int,
        map_graph: MapGraph,
        send_callback: Callable[[dict[str, Any]], Any],
        loop: asyncio.AbstractEventLoop | None = None,
        bot_delay: float | None = None,
    ) -> None:
        """Create agents for a new game. Human is always player 0."""
        if loop is None:
            loop = asyncio.get_event_loop()
        self._map_graph = map_graph
        self._send_callback = send_callback
        self._cancel_flag.clear()
        if bot_delay is not None:
            self.BOT_DELAY = bot_delay

        rng = random.Random()

        # Create human agent for player 0
        human = HumanWebSocketAgent(loop)
        human.set_map_graph(map_graph)
        human.set_send_callback(self._send_sync)
        self.human_agent = human
        self.agents[0] = human

        # Create bot agents for remaining players
        for i in range(1, num_players):
            bot = RandomAgent(rng=random.Random())
            bot._map_graph = map_graph
            self.agents[i] = bot

    def _send_sync(self, msg: dict[str, Any]) -> None:
        """Synchronous send wrapper for use from game thread."""
        if self._send_callback is not None:
            self._send_callback(msg)

    def start_game(self) -> None:
        """Start the game loop in a background thread."""
        self._game_thread = threading.Thread(
            target=self._run_game_loop, daemon=True
        )
        self._game_thread.start()

    def _run_game_loop(self) -> None:
        """Run the game loop, emitting events and state updates."""
        mg = self._map_graph
        if mg is None:
            return

        num_players = len(self.agents)
        rng = random.Random()

        # Setup initial state
        state = setup_game(mg, num_players, rng)

        # Initialize deck
        deck = create_deck(mg.all_territories)
        rng.shuffle(deck)
        cards: dict[int, list[Card]] = {i: [] for i in range(num_players)}
        state = state.model_copy(update={"deck": deck, "cards": cards})

        # Update player names: human is "You", bots are "Bot 1", "Bot 2", etc.
        new_players = list(state.players)
        new_players[0] = new_players[0].model_copy(update={"name": "You"})
        for i in range(1, num_players):
            new_players[i] = new_players[i].model_copy(update={"name": f"Bot {i}"})
        state = state.model_copy(update={"players": new_players})

        # Send initial state
        self._send_sync(state_to_message(state, mg, "Game started!"))

        max_turns = 5000
        for _turn in range(max_turns):
            if self._cancel_flag.is_set():
                return

            old_state = state
            player_idx = state.current_player_index
            is_human = player_idx == 0

            # Send state update before turn
            if is_human:
                prompt = f"Your turn (Turn {state.turn_number + 1})"
                self._send_sync(state_to_message(state, mg, prompt))

            # Execute turn
            state, victory = execute_turn(state, mg, self.agents, rng)

            # Detect and emit events by diffing states
            self._emit_turn_events(old_state, state, player_idx)

            # Send updated state after turn
            if not victory:
                next_is_human = state.current_player_index == 0
                if next_is_human:
                    prompt = f"Your turn (Turn {state.turn_number + 1})"
                else:
                    prompt = f"{state.players[state.current_player_index].name}'s turn..."
                self._send_sync(state_to_message(state, mg, prompt))

            if victory:
                winner_idx = next(
                    p.index for p in state.players if p.is_alive
                )
                msg = GameOverMessage(
                    winner=winner_idx,
                    winner_name=state.players[winner_idx].name,
                    is_human_winner=(winner_idx == 0),
                )
                self._send_sync(msg.model_dump(mode="json"))
                return

            # Add delay for bot turns so human can see what's happening
            if not is_human:
                time.sleep(self.BOT_DELAY)

    def _emit_turn_events(
        self,
        old_state: GameState,
        new_state: GameState,
        player_idx: int,
    ) -> None:
        """Detect and emit game events by comparing old and new state."""
        player_name = old_state.players[player_idx].name

        # Detect territory ownership changes (conquests)
        for territory, new_ts in new_state.territories.items():
            old_ts = old_state.territories.get(territory)
            if old_ts is not None and old_ts.owner != new_ts.owner:
                event = GameEventMessage(
                    event="conquest",
                    details={
                        "territory": territory,
                        "attacker": new_ts.owner,
                        "attacker_name": new_state.players[new_ts.owner].name,
                        "defender": old_ts.owner,
                    },
                )
                self._send_sync(event.model_dump(mode="json"))

        # Detect eliminations
        for p in new_state.players:
            old_p = old_state.players[p.index]
            if old_p.is_alive and not p.is_alive:
                event = GameEventMessage(
                    event="elimination",
                    details={
                        "eliminated_player": p.index,
                        "eliminated_name": p.name,
                        "by_player": player_idx,
                    },
                )
                self._send_sync(event.model_dump(mode="json"))

        # Detect card trades (trade_count increased)
        if new_state.trade_count > old_state.trade_count:
            event = GameEventMessage(
                event="card_trade",
                details={
                    "player": player_idx,
                    "player_name": player_name,
                    "trades": new_state.trade_count - old_state.trade_count,
                },
            )
            self._send_sync(event.model_dump(mode="json"))

    def handle_player_action(self, data: dict[str, Any]) -> None:
        """Route player action data to the human agent's input queue.

        Merges the inner 'data' dict with 'action_type' so the agent
        can check both data fields and the action type.
        """
        if self.human_agent is not None:
            inner = dict(data.get("data", {}))
            action_type = data.get("action_type", "")
            # Map action_type to 'action' key so agent choose_* methods
            # can check data.get("action") consistently
            if "action" not in inner and action_type:
                inner["action"] = action_type
            self.human_agent.receive_input(inner)

    def cancel_game(self) -> None:
        """Signal the game loop to stop."""
        self._cancel_flag.set()
