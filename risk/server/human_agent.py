"""HumanWebSocketAgent: bridges async WebSocket to sync game loop via asyncio.Queue."""

import asyncio
from typing import Any, Callable

from risk.engine.map_graph import MapGraph
from risk.models.actions import (
    AttackAction,
    BlitzAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.cards import Card, CardType
from risk.models.game_state import GameState
from risk.server.messages import RequestInputMessage


class HumanWebSocketAgent:
    """Human player agent that receives input via WebSocket.

    Each choose_* method sends a request_input message to the browser,
    then blocks the game thread waiting for the browser's response
    via an asyncio.Queue bridge.
    """

    def __init__(self, loop: asyncio.AbstractEventLoop) -> None:
        self._loop = loop
        self._input_queue: asyncio.Queue[dict[str, Any]] = asyncio.Queue()
        self._send_callback: Callable[[dict[str, Any]], None] | None = None
        self._map_graph: MapGraph | None = None

    def set_send_callback(self, callback: Callable[[dict[str, Any]], None]) -> None:
        """Register the function that sends messages to the browser."""
        self._send_callback = callback

    def set_map_graph(self, map_graph: MapGraph) -> None:
        """Store map graph reference for computing valid targets."""
        self._map_graph = map_graph

    def receive_input(self, data: dict[str, Any]) -> None:
        """Called from async WebSocket handler to provide input to the game thread."""
        self._loop.call_soon_threadsafe(self._input_queue.put_nowait, data)

    def _wait_for_input(self) -> dict[str, Any]:
        """Block the game thread until input arrives from the browser."""
        future = asyncio.run_coroutine_threadsafe(
            self._input_queue.get(), self._loop
        )
        return future.result()

    def _send(self, msg: dict[str, Any]) -> None:
        """Send a message to the browser via the registered callback."""
        if self._send_callback is not None:
            self._send_callback(msg)

    def choose_reinforcement_placement(
        self, state: GameState, armies: int
    ) -> ReinforcePlacementAction:
        """Request reinforcement placement from human player."""
        player_idx = state.current_player_index
        owned = [
            name for name, ts in state.territories.items()
            if ts.owner == player_idx
        ]

        msg = RequestInputMessage(
            input_type="choose_reinforcement_placement",
            valid_sources=sorted(owned),
            armies=armies,
        )
        self._send(msg.model_dump(mode="json"))

        data = self._wait_for_input()
        return ReinforcePlacementAction(placements=data["placements"])

    def choose_attack(self, state: GameState) -> AttackAction | None:
        """Request attack decision from human player."""
        mg = self._map_graph
        player_idx = state.current_player_index

        # Compute valid attack sources
        valid_sources: list[str] = []
        if mg is not None:
            for name, ts in state.territories.items():
                if ts.owner != player_idx or ts.armies < 2:
                    continue
                for neighbor in mg.neighbors(name):
                    if state.territories[neighbor].owner != player_idx:
                        valid_sources.append(name)
                        break

        msg = RequestInputMessage(
            input_type="choose_attack",
            valid_sources=sorted(valid_sources),
        )
        self._send(msg.model_dump(mode="json"))

        data = self._wait_for_input()
        if data.get("action") == "end_phase":
            return None

        return AttackAction(
            source=data["source"],
            target=data["target"],
            num_dice=data.get("num_dice") or data.get("dice", 3),
        )

    def choose_blitz(self, state: GameState) -> BlitzAction | None:
        """Human uses regular attacks with dice control, not blitz."""
        return None

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        """Request fortify decision from human player."""
        player_idx = state.current_player_index

        valid_sources = [
            name for name, ts in state.territories.items()
            if ts.owner == player_idx and ts.armies >= 2
        ]

        msg = RequestInputMessage(
            input_type="choose_fortify",
            valid_sources=sorted(valid_sources),
        )
        self._send(msg.model_dump(mode="json"))

        data = self._wait_for_input()
        if data.get("action") == "end_phase":
            return None

        return FortifyAction(
            source=data["source"],
            target=data["target"],
            armies=data["armies"],
        )

    def choose_card_trade(
        self, state: GameState, cards: list[Card], forced: bool
    ) -> TradeCardsAction | None:
        """Request card trade decision from human player."""
        cards_data = [
            {"territory": c.territory, "card_type": c.card_type.value}
            for c in cards
        ]

        msg = RequestInputMessage(
            input_type="choose_card_trade",
            forced=forced,
            cards=cards_data,
        )
        self._send(msg.model_dump(mode="json"))

        data = self._wait_for_input()
        if data.get("action") in ("skip", "end_phase"):
            return None

        # Parse cards from client data
        parsed_cards = []
        for card_data in data["cards"]:
            parsed_cards.append(Card(
                territory=card_data.get("territory"),
                card_type=CardType(card_data["card_type"]),
            ))
        return TradeCardsAction(cards=parsed_cards)

    def choose_defender_dice(
        self, state: GameState, territory: str, max_dice: int
    ) -> int:
        """Auto-defend with max dice (per user decision)."""
        return max_dice
