"""Tests for HumanWebSocketAgent and GameManager."""

import asyncio
from typing import Any
from unittest.mock import AsyncMock

import pytest
import pytest_asyncio

from risk.models.actions import (
    AttackAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.cards import Card, CardType, TurnPhase
from risk.models.game_state import GameState, PlayerState, TerritoryState
from risk.server.human_agent import HumanWebSocketAgent
from risk.server.game_manager import GameManager


@pytest.fixture
def two_player_state(map_graph) -> GameState:
    """A game state with 2 players, human owns some territories."""
    territories = {}
    all_terrs = map_graph.all_territories
    for i, t in enumerate(all_terrs):
        if i < len(all_terrs) // 2:
            territories[t] = TerritoryState(owner=0, armies=3)
        else:
            territories[t] = TerritoryState(owner=1, armies=2)
    return GameState(
        territories=territories,
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


class TestHumanWebSocketAgentChooseAttack:
    @pytest.mark.asyncio
    async def test_blocks_until_input_returns_attack(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        sent: list[dict] = []
        agent.set_send_callback(lambda msg: sent.append(msg))

        # Put input into queue from another task
        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input(
                {"source": "Alaska", "target": "Kamchatka", "num_dice": 3}
            )

        asyncio.ensure_future(provide_input())
        result = await asyncio.to_thread(
            agent.choose_attack, two_player_state
        )
        assert isinstance(result, AttackAction)
        assert result.source == "Alaska"
        assert result.target == "Kamchatka"

    @pytest.mark.asyncio
    async def test_returns_none_for_end_phase(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        agent.set_send_callback(lambda msg: None)

        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input({"action": "end_phase"})

        asyncio.ensure_future(provide_input())
        result = await asyncio.to_thread(
            agent.choose_attack, two_player_state
        )
        assert result is None

    @pytest.mark.asyncio
    async def test_sends_request_input(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        sent: list[dict] = []
        agent.set_send_callback(lambda msg: sent.append(msg))

        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input({"action": "end_phase"})

        asyncio.ensure_future(provide_input())
        await asyncio.to_thread(agent.choose_attack, two_player_state)
        assert len(sent) >= 1
        assert sent[0]["type"] == "request_input"
        assert sent[0]["input_type"] == "choose_attack"
        assert "valid_sources" in sent[0]


class TestHumanWebSocketAgentChooseReinforcement:
    @pytest.mark.asyncio
    async def test_blocks_until_input_returns_placement(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        agent.set_send_callback(lambda msg: None)

        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input({"placements": {"Alaska": 3, "Greenland": 2}})

        asyncio.ensure_future(provide_input())
        result = await asyncio.to_thread(
            agent.choose_reinforcement_placement, two_player_state, 5
        )
        assert isinstance(result, ReinforcePlacementAction)
        assert result.placements["Alaska"] == 3


class TestHumanWebSocketAgentChooseFortify:
    @pytest.mark.asyncio
    async def test_blocks_until_input_returns_fortify(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        agent.set_send_callback(lambda msg: None)

        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input(
                {"source": "Alaska", "target": "Greenland", "armies": 2}
            )

        asyncio.ensure_future(provide_input())
        result = await asyncio.to_thread(
            agent.choose_fortify, two_player_state
        )
        assert isinstance(result, FortifyAction)
        assert result.armies == 2

    @pytest.mark.asyncio
    async def test_returns_none_for_skip(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        agent.set_send_callback(lambda msg: None)

        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input({"action": "end_phase"})

        asyncio.ensure_future(provide_input())
        result = await asyncio.to_thread(
            agent.choose_fortify, two_player_state
        )
        assert result is None


class TestHumanWebSocketAgentChooseCardTrade:
    @pytest.mark.asyncio
    async def test_blocks_until_input_returns_trade(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        agent.set_send_callback(lambda msg: None)

        cards = [
            Card(territory="Alaska", card_type=CardType.INFANTRY),
            Card(territory="Kamchatka", card_type=CardType.CAVALRY),
            Card(territory="Greenland", card_type=CardType.ARTILLERY),
        ]

        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input({
                "cards": [
                    {"territory": "Alaska", "card_type": 1},
                    {"territory": "Kamchatka", "card_type": 2},
                    {"territory": "Greenland", "card_type": 3},
                ]
            })

        asyncio.ensure_future(provide_input())
        result = await asyncio.to_thread(
            agent.choose_card_trade, two_player_state, cards, True
        )
        assert isinstance(result, TradeCardsAction)
        assert len(result.cards) == 3

    @pytest.mark.asyncio
    async def test_returns_none_for_skip(
        self, two_player_state: GameState, map_graph
    ) -> None:
        loop = asyncio.get_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        agent.set_send_callback(lambda msg: None)

        cards = [
            Card(territory="Alaska", card_type=CardType.INFANTRY),
            Card(territory="Kamchatka", card_type=CardType.CAVALRY),
            Card(territory="Greenland", card_type=CardType.ARTILLERY),
        ]

        async def provide_input() -> None:
            await asyncio.sleep(0.05)
            agent.receive_input({"action": "skip"})

        asyncio.ensure_future(provide_input())
        result = await asyncio.to_thread(
            agent.choose_card_trade, two_player_state, cards, False
        )
        assert result is None


class TestHumanWebSocketAgentDefenderDice:
    def test_returns_max_dice_always(self, two_player_state: GameState, map_graph) -> None:
        loop = asyncio.new_event_loop()
        agent = HumanWebSocketAgent(loop)
        agent.set_map_graph(map_graph)
        result = agent.choose_defender_dice(two_player_state, "Alaska", 2)
        assert result == 2
        loop.close()


class TestGameManagerSetup:
    @pytest.mark.asyncio
    async def test_creates_correct_number_of_players(self, map_graph) -> None:
        manager = GameManager()
        send_mock = AsyncMock()
        manager.setup(num_players=4, map_graph=map_graph, send_callback=send_mock)
        assert len(manager.agents) == 4
        assert isinstance(manager.agents[0], HumanWebSocketAgent)
        # Bots are RandomAgent (indexes 1-3)
        from risk.game import RandomAgent
        for i in range(1, 4):
            assert isinstance(manager.agents[i], RandomAgent)
