"""Tests for HardAgent (BOTS-03/BOTS-04 strategy behaviors and batch validation).

Covers reinforcement concentration, continent-completing attacks, opponent blocking,
card timing, threat assessment, army advancement, full-game integration, and
statistical batch validation (Hard vs Medium, Hard vs Random).
"""

import pathlib
import random

import pytest

from risk.bots.hard import HardAgent
from risk.engine.map_graph import MapGraph, load_map
from risk.engine.setup import setup_game
from risk.game import RandomAgent, run_game
from risk.models.game_state import GameState, TerritoryState, PlayerState
from risk.models.cards import TurnPhase

# ---------------------------------------------------------------------------
# Module-level shared fixtures
# ---------------------------------------------------------------------------

_DATA_DIR = pathlib.Path(__file__).resolve().parent.parent / "risk" / "data"
MAP_DATA = load_map(_DATA_DIR / "classic.json")
MAP_GRAPH = MapGraph(MAP_DATA)


@pytest.fixture
def map_graph():
    return MapGraph(load_map(_DATA_DIR / "classic.json"))


def _make_state(
    owner_map: dict[str, int],
    current_player: int = 0,
    num_players: int = 2,
    armies_map: dict[str, int] | None = None,
) -> GameState:
    """Build a minimal GameState from an owner map.

    Args:
        owner_map: dict mapping territory name to owner index.
        current_player: Which player's turn it is.
        num_players: Total number of players.
        armies_map: optional dict mapping territory name to army count.
    """
    if armies_map is None:
        armies_map = {}
    territories = {}
    for name in MAP_GRAPH.all_territories:
        owner = owner_map.get(name, 1 if current_player == 0 else 0)
        armies = armies_map.get(name, 3)
        territories[name] = TerritoryState(owner=owner, armies=armies)

    players = [
        PlayerState(index=i, name=f"Player {i}", is_alive=True)
        for i in range(num_players)
    ]
    return GameState(
        territories=territories,
        players=players,
        current_player_index=current_player,
        turn_number=1,
        turn_phase=TurnPhase.REINFORCE,
        cards={i: [] for i in range(num_players)},
        deck=[],
    )


# ---------------------------------------------------------------------------
# BOTS-03: HardAgent reinforce strategy
# ---------------------------------------------------------------------------

class TestHardReinforce:
    def test_concentrates_armies(self):
        """Verify all armies placed on 1-2 territories (not spread across many)."""
        # Give bot a mix of territories across multiple continents
        aus = MAP_GRAPH.continent_territories("Australia")
        sa = MAP_GRAPH.continent_territories("South America")
        owner_map = {t: 0 for t in aus | sa}
        state = _make_state(owner_map, current_player=0)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_reinforcement_placement(state, armies=10)

        # Hard bot should concentrate armies on 1-2 territories, not spread
        assert len(action.placements) <= 2, (
            f"Expected concentration on 1-2 territories, got {len(action.placements)}: "
            f"{action.placements}"
        )
        assert sum(action.placements.values()) == 10

    def test_prioritizes_vulnerable_borders(self):
        """Verify placement on territory with high enemy adjacency (vulnerable border)."""
        # Bot owns all of Australia; Indonesia borders Siam (enemy territory)
        aus = MAP_GRAPH.continent_territories("Australia")
        owner_map = {t: 0 for t in aus}
        # Make Indonesia have only 1 army (vulnerable) while Siam has 10
        armies_map = {t: 3 for t in aus}
        armies_map["Indonesia"] = 1
        armies_map["Siam"] = 10
        state = _make_state(owner_map, current_player=0, armies_map=armies_map)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_reinforcement_placement(state, armies=5)

        # Indonesia is the most vulnerable border -- should get reinforcements
        assert "Indonesia" in action.placements, (
            f"Expected reinforcement on vulnerable Indonesia, got {action.placements}"
        )


# ---------------------------------------------------------------------------
# BOTS-03: HardAgent attack strategy
# ---------------------------------------------------------------------------

class TestHardAttack:
    def test_prioritizes_continent_completion(self):
        """Verify attacks territory that completes a continent."""
        # Bot owns 3/4 of Australia with overwhelming force
        owner_map = {
            "Indonesia": 0,
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 1,
        }
        armies_map = {
            "Indonesia": 10,
            "New Guinea": 5,
            "Western Australia": 5,
            "Eastern Australia": 2,
        }
        state = _make_state(owner_map, current_player=0, armies_map=armies_map)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_attack(state)

        assert action is not None, "Should attack to complete continent"
        # The attack should target Eastern Australia to complete Australia
        assert action.target == "Eastern Australia", (
            f"Expected attack on Eastern Australia to complete continent, got {action.target}"
        )

    def test_blocks_opponent_continent(self):
        """Verify attacks to block opponent from completing their continent."""
        # Opponent owns 3/4 of South America; bot borders the remaining territory
        sa = MAP_GRAPH.continent_territories("South America")
        # Give opponent all SA except one territory that bot owns
        sa_list = sorted(sa)
        owner_map = {t: 1 for t in sa_list[:-1]}  # Opponent owns most of SA
        owner_map[sa_list[-1]] = 0  # Bot owns one SA territory
        # Give bot enough armies to attack
        armies_map = {sa_list[-1]: 8}
        for t in sa_list[:-1]:
            armies_map[t] = 2
        state = _make_state(owner_map, current_player=0, armies_map=armies_map)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_attack(state)

        assert action is not None, "Should attack to block opponent continent completion"
        # Target should be in South America
        assert action.target in sa, (
            f"Expected attack into South America to block opponent, got {action.target}"
        )

    def test_stops_when_armies_low(self):
        """Verify stops attacking before becoming defenseless."""
        # Bot owns a few territories, each with very low armies
        aus = MAP_GRAPH.continent_territories("Australia")
        owner_map = {t: 0 for t in aus}
        # All territories have just 2 armies -- attacking would leave them with 1
        armies_map = {t: 2 for t in aus}
        state = _make_state(owner_map, current_player=0, armies_map=armies_map)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_attack(state)

        # With only 2 armies per territory, smart bot should not attack
        # (would leave borders defenseless)
        assert action is None, (
            "Should not attack when armies are too low to risk losses"
        )


# ---------------------------------------------------------------------------
# BOTS-03: HardAgent card timing
# ---------------------------------------------------------------------------

class TestHardCardTiming:
    def test_holds_cards_when_safe(self):
        """Verify does NOT trade at 3 cards when escalation is low."""
        from risk.models.cards import Card, CardType

        state = _make_state({t: 0 for t in MAP_GRAPH.all_territories}, current_player=0)
        # Set low trade_count (low escalation)
        state = state.model_copy(update={"trade_count": 0})
        cards = [
            Card(territory="Alaska", card_type=CardType.INFANTRY),
            Card(territory="Alberta", card_type=CardType.INFANTRY),
            Card(territory="Central America", card_type=CardType.INFANTRY),
        ]

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_card_trade(state, cards, forced=False)

        # With only 3 cards and low escalation, should hold
        assert action is None, "Should hold cards when safe (3 cards, low escalation)"

    def test_trades_at_four_cards(self):
        """Verify trades when holding 4 cards."""
        from risk.models.cards import Card, CardType

        state = _make_state({t: 0 for t in MAP_GRAPH.all_territories}, current_player=0)
        cards = [
            Card(territory="Alaska", card_type=CardType.INFANTRY),
            Card(territory="Alberta", card_type=CardType.INFANTRY),
            Card(territory="Central America", card_type=CardType.INFANTRY),
            Card(territory="Eastern United States", card_type=CardType.CAVALRY),
        ]

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_card_trade(state, cards, forced=False)

        assert action is not None, "Should trade when holding 4 cards"
        assert len(action.cards) == 3

    def test_trades_when_forced(self):
        """Verify trades when forced=True."""
        from risk.models.cards import Card, CardType

        state = _make_state({t: 0 for t in MAP_GRAPH.all_territories}, current_player=0)
        cards = [
            Card(territory="Alaska", card_type=CardType.INFANTRY),
            Card(territory="Alberta", card_type=CardType.INFANTRY),
            Card(territory="Central America", card_type=CardType.INFANTRY),
        ]

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_card_trade(state, cards, forced=True)

        assert action is not None, "Must trade when forced"
        assert len(action.cards) == 3


# ---------------------------------------------------------------------------
# BOTS-03: HardAgent threat assessment
# ---------------------------------------------------------------------------

class TestHardThreat:
    def test_identifies_dangerous_opponent(self):
        """Verify threat scores rank opponents correctly."""
        # Player 1 has many armies and nearly controls a continent (dangerous)
        # Player 2 has few armies spread thin (less dangerous)
        sa = MAP_GRAPH.continent_territories("South America")
        owner_map = {}
        # Player 1 owns all of SA except Venezuela
        for t in sa:
            owner_map[t] = 1
        owner_map["Venezuela"] = 0  # Bot owns this, blocking player 1

        # Give player 2 a few scattered territories
        owner_map["Alaska"] = 2
        owner_map["Greenland"] = 2

        armies_map = {}
        for t in sa:
            armies_map[t] = 8  # Player 1 has strong armies
        armies_map["Alaska"] = 2
        armies_map["Greenland"] = 2

        state = _make_state(owner_map, current_player=0, num_players=3, armies_map=armies_map)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH

        # The agent should have a method to assess threats
        threats = agent._opponent_threat_scores(state)

        assert 1 in threats and 2 in threats, "Should score all opponents"
        assert threats[1] > threats[2], (
            f"Player 1 (continent-threat + armies) should rank higher: {threats}"
        )


# ---------------------------------------------------------------------------
# BOTS-03: HardAgent advance armies
# ---------------------------------------------------------------------------

class TestHardAdvance:
    def test_advances_more_into_exposed_territory(self):
        """Verify advances more armies when target borders enemies."""
        # Bot conquers a territory that borders enemies -- should advance more
        owner_map = {
            "Indonesia": 0,
            "Siam": 0,  # just conquered, borders enemies
        }
        armies_map = {"Indonesia": 8, "Siam": 1}
        state = _make_state(owner_map, current_player=0, armies_map=armies_map)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH

        result = agent.choose_advance_armies(
            state, source="Indonesia", target="Siam", min_armies=1, max_armies=7
        )

        # Target borders enemies, should advance more than minimum
        assert result > 1, (
            f"Should advance more than minimum into exposed territory, got {result}"
        )

    def test_advances_all_from_interior(self):
        """Verify advances max when source has no enemy neighbors."""
        # Bot conquers from an interior territory -- should advance all
        aus = MAP_GRAPH.continent_territories("Australia")
        owner_map = {t: 0 for t in aus}
        owner_map["Siam"] = 0  # Just conquered
        # Western Australia is interior (all neighbors owned)
        armies_map = {"Western Australia": 10, "Siam": 1}
        state = _make_state(owner_map, current_player=0, armies_map=armies_map)

        agent = HardAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH

        result = agent.choose_advance_armies(
            state, source="Western Australia", target="Eastern Australia",
            min_armies=1, max_armies=9
        )

        # Source is interior, should advance all armies
        assert result == 9, (
            f"Should advance all armies from interior territory, got {result}"
        )


# ---------------------------------------------------------------------------
# BOTS-03: HardAgent full game integration
# ---------------------------------------------------------------------------

class TestHardFullGame:
    def test_completes_game_without_crash(self):
        """Run 5 games with 4 players (1 Hard + 3 Random) with different seeds."""
        for seed in range(5):
            rng = random.Random(seed)
            agents = {
                0: HardAgent(rng=random.Random(seed * 10)),
                1: RandomAgent(rng=random.Random(seed * 10 + 1)),
                2: RandomAgent(rng=random.Random(seed * 10 + 2)),
                3: RandomAgent(rng=random.Random(seed * 10 + 3)),
            }
            final = run_game(MAP_GRAPH, agents, rng, max_turns=2000)
            winners = [p for p in final.players if p.is_alive]
            assert len(winners) == 1, f"Seed {seed}: game should produce exactly 1 winner"

    def test_hard_vs_random_wins(self):
        """Hard should beat RandomAgent most of the time (>70% of 20 games)."""
        hard_wins = 0
        num_games = 20

        for seed in range(num_games):
            rng = random.Random(seed)
            agents = {
                0: HardAgent(rng=random.Random(seed * 2)),
                1: RandomAgent(rng=random.Random(seed * 2 + 1)),
            }
            final = run_game(MAP_GRAPH, agents, rng, max_turns=2000)
            winner = next(p.index for p in final.players if p.is_alive)
            if winner == 0:
                hard_wins += 1

        print(f"\nHard vs Random: {hard_wins}/{num_games} wins ({hard_wins*100//num_games}%)")
        assert hard_wins >= 14, (
            f"Hard bot won only {hard_wins}/{num_games} games vs Random -- expected >= 70%"
        )


# ---------------------------------------------------------------------------
# BOTS-03: HardAgent batch testing
# ---------------------------------------------------------------------------

@pytest.mark.slow
class TestHardBatch:
    def test_hard_vs_medium_batch(self):
        """100-game batch: Hard wins >= 55% against Medium."""
        from risk.bots.medium import MediumAgent

        hard_wins = 0
        num_games = 100

        for seed in range(num_games):
            rng = random.Random(seed)
            agents = {
                0: HardAgent(rng=random.Random(seed * 2)),
                1: MediumAgent(rng=random.Random(seed * 2 + 1)),
            }
            final = run_game(MAP_GRAPH, agents, rng, max_turns=1000)
            winner = next(p.index for p in final.players if p.is_alive)
            if winner == 0:
                hard_wins += 1

        print(f"\nHard vs Medium batch: {hard_wins}/{num_games} wins ({hard_wins}%)")
        assert hard_wins >= 55, (
            f"Hard bot won only {hard_wins}/100 games vs Medium -- expected >= 55%"
        )
