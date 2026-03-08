"""Tests for turn execution engine: phase transitions, elimination, victory."""

import random

import pytest

from risk.engine.cards import create_deck, is_valid_set
from risk.engine.map_graph import MapGraph, load_map
from risk.engine.reinforcements import calculate_reinforcements
from risk.engine.setup import setup_game
from risk.models.actions import (
    AttackAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.cards import Card, CardType, TurnPhase
from risk.models.game_state import GameState, PlayerState, TerritoryState
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent.parent / "risk" / "data"


def _load_map_graph() -> MapGraph:
    map_data = load_map(DATA_DIR / "classic.json")
    return MapGraph(map_data)


# ---------------------------------------------------------------------------
# Simple test agent that implements PlayerAgent protocol
# ---------------------------------------------------------------------------
class SimpleAgent:
    """Minimal agent for turn engine tests -- behaviour injected via callbacks."""

    def __init__(
        self,
        *,
        reinforce_fn=None,
        attack_fn=None,
        fortify_fn=None,
        card_trade_fn=None,
    ):
        self._reinforce_fn = reinforce_fn
        self._attack_fn = attack_fn
        self._fortify_fn = fortify_fn
        self._card_trade_fn = card_trade_fn

    def choose_reinforcement_placement(
        self, state: GameState, armies: int
    ) -> ReinforcePlacementAction:
        if self._reinforce_fn:
            return self._reinforce_fn(state, armies)
        # Default: put all armies on the first owned territory
        player_idx = state.current_player_index
        owned = [
            n for n, ts in state.territories.items() if ts.owner == player_idx
        ]
        return ReinforcePlacementAction(placements={owned[0]: armies})

    def choose_attack(self, state: GameState) -> AttackAction | None:
        if self._attack_fn:
            return self._attack_fn(state)
        return None  # skip attacks

    def choose_blitz(self, state: GameState):
        return None

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        if self._fortify_fn:
            return self._fortify_fn(state)
        return None

    def choose_card_trade(
        self, state: GameState, cards: list[Card], forced: bool
    ) -> TradeCardsAction | None:
        if self._card_trade_fn:
            return self._card_trade_fn(state, cards, forced)
        return None

    def choose_defender_dice(
        self, state: GameState, territory: str, max_dice: int
    ) -> int:
        return min(2, max_dice)


# ---------------------------------------------------------------------------
# Helper: build a minimal 2-player state on the classic map
# ---------------------------------------------------------------------------
def _two_player_state(mg: MapGraph, p0_territories: list[str] | None = None) -> GameState:
    """Build a state where player 0 owns p0_territories and player 1 owns the rest."""
    all_t = mg.all_territories
    if p0_territories is None:
        p0_territories = all_t[:21]
    p1_territories = [t for t in all_t if t not in p0_territories]

    territories = {}
    for t in p0_territories:
        territories[t] = TerritoryState(owner=0, armies=5)
    for t in p1_territories:
        territories[t] = TerritoryState(owner=1, armies=5)

    return GameState(
        territories=territories,
        players=[
            PlayerState(index=0, name="P0"),
            PlayerState(index=1, name="P1"),
        ],
        current_player_index=0,
        turn_number=0,
        turn_phase=TurnPhase.REINFORCE,
        cards={0: [], 1: []},
        deck=create_deck(all_t),
    )


# ===== Phase transition & reinforcement tests =============================

class TestReinforcePhase:
    def test_reinforce_places_correct_armies(self):
        """Player gets N reinforcements and places them all."""
        mg = _load_map_graph()
        state = _two_player_state(mg)
        agent = SimpleAgent()

        from risk.engine.turn import execute_reinforce_phase

        new_state = execute_reinforce_phase(state, mg, agent, 0)

        # Should have moved to ATTACK phase
        assert new_state.turn_phase == TurnPhase.ATTACK

        # Total armies should have increased by the reinforcement amount
        old_armies = sum(
            ts.armies for n, ts in state.territories.items() if ts.owner == 0
        )
        new_armies = sum(
            ts.armies for n, ts in new_state.territories.items() if ts.owner == 0
        )
        expected_reinforcements = calculate_reinforcements(state, mg, 0)
        assert new_armies == old_armies + expected_reinforcements

    def test_reinforce_forced_trade_at_5_cards(self):
        """Player with 5+ cards must trade before placing."""
        mg = _load_map_graph()
        state = _two_player_state(mg)

        # Give player 0 five cards (a valid set + 2 extras)
        five_cards = [
            Card(territory=None, card_type=CardType.INFANTRY),
            Card(territory=None, card_type=CardType.INFANTRY),
            Card(territory=None, card_type=CardType.INFANTRY),
            Card(territory=None, card_type=CardType.CAVALRY),
            Card(territory=None, card_type=CardType.ARTILLERY),
        ]
        new_cards = dict(state.cards)
        new_cards[0] = five_cards
        state = state.model_copy(update={"cards": new_cards})

        traded = False

        def trade_fn(st, cards, forced):
            nonlocal traded
            if forced and len(cards) >= 5:
                traded = True
                # Trade first 3
                return TradeCardsAction(cards=cards[:3])
            return None

        agent = SimpleAgent(card_trade_fn=trade_fn)

        from risk.engine.turn import execute_reinforce_phase

        new_state = execute_reinforce_phase(state, mg, agent, 0)

        assert traded
        # Player should have fewer cards after trade
        assert len(new_state.cards[0]) < 5


# ===== Attack phase tests =================================================

class TestAttackPhase:
    def test_attack_phase_skip(self):
        """Agent returns None immediately, phase completes."""
        mg = _load_map_graph()
        state = _two_player_state(mg)
        state = state.model_copy(update={"turn_phase": TurnPhase.ATTACK})
        agent = SimpleAgent()  # default: returns None for attack

        from risk.engine.turn import execute_attack_phase

        new_state, victory = execute_attack_phase(
            state, mg, agent, 0, random.Random(42)
        )
        assert not victory
        assert new_state.turn_phase == TurnPhase.FORTIFY

    def test_attack_conquest_sets_flag(self):
        """After winning a territory, conquered_this_turn is True."""
        mg = _load_map_graph()
        all_t = mg.all_territories

        # Give player 0 many armies on one territory, player 1 only 1 on neighbor
        adj = mg.neighbors(all_t[0])
        target = [a for a in adj if a != all_t[0]][0]

        territories = {}
        for t in all_t:
            territories[t] = TerritoryState(owner=0, armies=5)
        # Give target to player 1 with 1 army
        territories[target] = TerritoryState(owner=1, armies=1)

        state = GameState(
            territories=territories,
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1"),
            ],
            current_player_index=0,
            turn_phase=TurnPhase.ATTACK,
            cards={0: [], 1: []},
            deck=create_deck(all_t),
        )

        attack_count = [0]

        def attack_fn(st):
            attack_count[0] += 1
            if attack_count[0] == 1:
                return AttackAction(source=all_t[0], target=target, num_dice=3)
            return None

        agent = SimpleAgent(attack_fn=attack_fn)

        from risk.engine.turn import execute_attack_phase

        # Use a fixed seed that guarantees attacker wins against 1 army
        new_state, victory = execute_attack_phase(
            state, mg, agent, 0, random.Random(1)
        )
        assert new_state.conquered_this_turn

    def test_card_earned_on_conquest(self):
        """After attack phase with conquest, player has 1 more card."""
        mg = _load_map_graph()
        all_t = mg.all_territories

        adj = mg.neighbors(all_t[0])
        target = [a for a in adj if a != all_t[0]][0]

        territories = {}
        for t in all_t:
            territories[t] = TerritoryState(owner=0, armies=10)
        territories[target] = TerritoryState(owner=1, armies=1)

        deck = create_deck(all_t)
        state = GameState(
            territories=territories,
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1"),
            ],
            current_player_index=0,
            turn_phase=TurnPhase.ATTACK,
            cards={0: [], 1: []},
            deck=deck,
        )

        cards_before = len(state.cards.get(0, []))
        attack_count = [0]

        def attack_fn(st):
            attack_count[0] += 1
            if attack_count[0] == 1:
                return AttackAction(source=all_t[0], target=target, num_dice=3)
            return None

        agent = SimpleAgent(attack_fn=attack_fn)

        from risk.engine.turn import execute_attack_phase

        new_state, _ = execute_attack_phase(
            state, mg, agent, 0, random.Random(1)
        )

        cards_after = len(new_state.cards.get(0, []))
        assert cards_after == cards_before + 1

    def test_no_card_without_conquest(self):
        """Attack phase without conquest: no card earned."""
        mg = _load_map_graph()
        state = _two_player_state(mg)
        state = state.model_copy(
            update={"turn_phase": TurnPhase.ATTACK, "conquered_this_turn": False}
        )
        agent = SimpleAgent()  # skips attack

        from risk.engine.turn import execute_attack_phase

        cards_before = len(state.cards.get(0, []))
        new_state, _ = execute_attack_phase(
            state, mg, agent, 0, random.Random(42)
        )
        cards_after = len(new_state.cards.get(0, []))
        assert cards_after == cards_before


# ===== Elimination tests ==================================================

class TestElimination:
    def test_elimination_marks_dead(self):
        """Player with 0 territories marked is_alive=False."""
        from risk.engine.turn import check_elimination

        mg = _load_map_graph()
        all_t = mg.all_territories

        # Player 1 owns nothing
        territories = {t: TerritoryState(owner=0, armies=5) for t in all_t}
        state = GameState(
            territories=territories,
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1"),
            ],
        )
        assert check_elimination(state, 1) is True
        assert check_elimination(state, 0) is False

    def test_elimination_card_transfer(self):
        """Eliminated player's cards go to eliminator."""
        from risk.engine.turn import transfer_cards

        mg = _load_map_graph()
        all_t = mg.all_territories

        victim_cards = [
            Card(territory=all_t[0], card_type=CardType.INFANTRY),
            Card(territory=all_t[1], card_type=CardType.CAVALRY),
        ]

        state = GameState(
            territories={t: TerritoryState(owner=0, armies=5) for t in all_t},
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1"),
            ],
            cards={0: [], 1: victim_cards},
        )

        new_state = transfer_cards(state, from_player=1, to_player=0)
        assert len(new_state.cards[0]) == 2
        assert len(new_state.cards[1]) == 0

    def test_elimination_forced_trade_cascade(self):
        """Eliminator gets cards pushing to 5+, must trade immediately."""
        from risk.engine.turn import force_trade_loop

        mg = _load_map_graph()
        all_t = mg.all_territories

        # Eliminator already has 3 cards, gets 3 more = 6 -> forced trade
        eliminator_cards = [
            Card(territory=None, card_type=CardType.INFANTRY),
            Card(territory=None, card_type=CardType.CAVALRY),
            Card(territory=None, card_type=CardType.ARTILLERY),
            Card(territory=None, card_type=CardType.INFANTRY),
            Card(territory=None, card_type=CardType.INFANTRY),
            Card(territory=None, card_type=CardType.INFANTRY),
        ]

        state = GameState(
            territories={t: TerritoryState(owner=0, armies=5) for t in all_t},
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1"),
            ],
            cards={0: eliminator_cards, 1: []},
        )

        def trade_fn(st, cards, forced):
            if forced:
                return TradeCardsAction(cards=cards[:3])
            return None

        agent = SimpleAgent(card_trade_fn=trade_fn)
        new_state, bonus = force_trade_loop(state, 0, agent)

        assert len(new_state.cards[0]) < 5
        assert bonus > 0


# ===== Victory tests =====================================================

class TestVictory:
    def test_victory_detection(self):
        """One player owns all territories -> check_victory returns index."""
        from risk.engine.turn import check_victory

        mg = _load_map_graph()
        all_t = mg.all_territories

        state = GameState(
            territories={t: TerritoryState(owner=0, armies=1) for t in all_t},
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1", is_alive=False),
            ],
        )
        assert check_victory(state) == 0

    def test_no_victory_multiple_owners(self):
        """Multiple territory owners -> no victory."""
        from risk.engine.turn import check_victory

        mg = _load_map_graph()
        state = _two_player_state(mg)
        assert check_victory(state) is None

    def test_victory_after_elimination(self):
        """Eliminating last opponent triggers victory."""
        from risk.engine.turn import check_victory

        mg = _load_map_graph()
        all_t = mg.all_territories

        # 3-player game: only player 0 alive and owns everything
        state = GameState(
            territories={t: TerritoryState(owner=0, armies=1) for t in all_t},
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1", is_alive=False),
                PlayerState(index=2, name="P2", is_alive=False),
            ],
        )
        assert check_victory(state) == 0


# ===== Turn execution tests ===============================================

class TestTurnExecution:
    def test_next_player_skips_dead(self):
        """Dead players skipped in turn order."""
        from risk.engine.turn import execute_turn

        mg = _load_map_graph()
        all_t = mg.all_territories

        # 3-player: player 1 is dead, so after player 0's turn -> player 2
        p0_t = all_t[:21]
        p2_t = all_t[21:]

        territories = {}
        for t in p0_t:
            territories[t] = TerritoryState(owner=0, armies=5)
        for t in p2_t:
            territories[t] = TerritoryState(owner=2, armies=5)

        state = GameState(
            territories=territories,
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1", is_alive=False),
                PlayerState(index=2, name="P2"),
            ],
            current_player_index=0,
            cards={0: [], 1: [], 2: []},
            deck=create_deck(all_t),
        )

        agents = {
            0: SimpleAgent(),
            2: SimpleAgent(),
        }

        new_state, victory = execute_turn(state, mg, agents, random.Random(42))
        assert not victory
        assert new_state.current_player_index == 2

    def test_turn_advances_player(self):
        """After turn, current_player_index moves to next alive player."""
        from risk.engine.turn import execute_turn

        mg = _load_map_graph()
        state = _two_player_state(mg)

        agents = {0: SimpleAgent(), 1: SimpleAgent()}
        new_state, victory = execute_turn(state, mg, agents, random.Random(42))

        assert not victory
        assert new_state.current_player_index == 1

    def test_turn_increments_number(self):
        """turn_number increases by 1 each turn."""
        from risk.engine.turn import execute_turn

        mg = _load_map_graph()
        state = _two_player_state(mg)

        agents = {0: SimpleAgent(), 1: SimpleAgent()}
        new_state, _ = execute_turn(state, mg, agents, random.Random(42))

        assert new_state.turn_number == state.turn_number + 1
