"""Test stubs for MediumAgent (BOTS-01 wiring, BOTS-02 unit strategy, integration).

Wave 0: All MediumAgent tests are marked xfail until plan 02 and 03 implement the agent.
test_map_loads confirms test infrastructure is working.
"""

import json
import pathlib
import random

import pytest

from risk.engine.map_graph import MapGraph, load_map
from risk.models.game_state import GameState, TerritoryState, PlayerState
from risk.models.cards import TurnPhase


# ---------------------------------------------------------------------------
# Module-level shared fixtures
# ---------------------------------------------------------------------------

_DATA_DIR = pathlib.Path(__file__).resolve().parent.parent / "risk" / "data"
MAP_DATA = load_map(_DATA_DIR / "classic.json")
MAP_GRAPH = MapGraph(MAP_DATA)


def _make_state(owner_map: dict[str, int], current_player: int = 0, num_players: int = 2) -> GameState:
    """Build a minimal GameState from an owner map.

    Args:
        owner_map: dict mapping territory name to owner index (0-based).
        current_player: Which player's turn it is.
        num_players: Total number of players.
    """
    territories = {
        name: TerritoryState(owner=owner, armies=3)
        for name, owner in owner_map.items()
    }
    # Any territories not in owner_map get assigned to player 1 (the opponent)
    for t in MAP_GRAPH.all_territories:
        if t not in territories:
            territories[t] = TerritoryState(owner=1 if current_player == 0 else 0, armies=1)

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
# Sanity check: ensure test infrastructure works (NOT xfail)
# ---------------------------------------------------------------------------

class TestMapLoads:
    def test_map_loads(self):
        """Confirm classic.json loads and the map has expected territory count."""
        assert len(MAP_GRAPH.all_territories) == 42
        aus = MAP_GRAPH.continent_territories("Australia")
        assert len(aus) == 4


# ---------------------------------------------------------------------------
# BOTS-01: Difficulty wiring (GameManager creates correct agent type)
# ---------------------------------------------------------------------------

@pytest.mark.xfail(reason="MediumAgent not yet implemented", strict=False)
class TestDifficultyWiring:
    def test_easy_creates_random_agent(self):
        """GameManager.setup(difficulty='easy') creates RandomAgent instances for bot slots."""
        from risk.game import RandomAgent
        from risk.server.game_manager import GameManager

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=2,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
            difficulty="easy",
        )
        # All bot agents should be RandomAgent
        for agent in gm._agents.values():
            assert isinstance(agent, RandomAgent), (
                f"Expected RandomAgent, got {type(agent)}"
            )

    def test_medium_creates_medium_agent(self):
        """GameManager.setup(difficulty='medium') creates MediumAgent instances for bot slots."""
        from risk.bots.medium import MediumAgent
        from risk.server.game_manager import GameManager

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=2,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
            difficulty="medium",
        )
        # All bot agents should be MediumAgent
        for agent in gm._agents.values():
            assert isinstance(agent, MediumAgent), (
                f"Expected MediumAgent, got {type(agent)}"
            )

    def test_default_difficulty_is_easy(self):
        """GameManager.setup() without difficulty arg creates RandomAgent (backwards compat)."""
        from risk.game import RandomAgent
        from risk.server.game_manager import GameManager

        sent = []
        gm = GameManager()
        gm.setup(
            num_players=2,
            map_graph=MAP_GRAPH,
            send_callback=lambda msg: sent.append(msg),
        )
        # Default should be RandomAgent (easy difficulty)
        for agent in gm._agents.values():
            assert isinstance(agent, RandomAgent), (
                f"Expected RandomAgent by default, got {type(agent)}"
            )


# ---------------------------------------------------------------------------
# BOTS-02: MediumAgent reinforce strategy
# ---------------------------------------------------------------------------

class TestMediumAgentReinforce:
    def test_reinforce_places_on_border_of_top_continent(self):
        """Given bot owns 3/4 of Australia, all armies placed on an Australia border territory."""
        from risk.bots.medium import MediumAgent

        # Bot owns Indonesia (border), New Guinea, Western Australia; opponent owns Eastern Australia
        # Indonesia borders Siam (outside Australia) so it is the Australia border
        owner_map = {
            "Indonesia": 0,
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 1,
        }
        state = _make_state(owner_map, current_player=0)

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_reinforcement_placement(state, armies=3)

        # Indonesia is the only Australia territory that borders outside Australia
        # The action should place at least some armies on a border territory of Australia
        aus_territories = MAP_GRAPH.continent_territories("Australia")
        bot_aus = {t for t, ts in state.territories.items() if ts.owner == 0 and t in aus_territories}
        # Find which Australia-owned territories border outside
        aus_borders = {
            t for t in bot_aus
            if any(n not in aus_territories for n in MAP_GRAPH.neighbors(t))
        }
        assert aus_borders, "Test setup error: bot should have at least one Australia border"

        placed_territories = set(action.placements.keys())
        # All placements should be on Australia border territories
        assert placed_territories.issubset(aus_borders | bot_aus), (
            f"Expected placement on Australia territories, got {placed_territories}"
        )
        # At least one placement on a border territory
        assert placed_territories & aus_borders, (
            f"Expected at least one placement on Australia border, got {placed_territories}"
        )

    def test_reinforce_fallback_any_border(self):
        """Given bot owns all of Australia (no external border among Australia), falls back to any owned border territory."""
        from risk.bots.medium import MediumAgent

        # Bot owns all of Australia; Indonesia borders Siam which is owned by opponent
        owner_map = {
            "Indonesia": 0,
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 0,
        }
        state = _make_state(owner_map, current_player=0)

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_reinforcement_placement(state, armies=3)

        # Should place on any owned territory that borders an enemy
        bot_owned = {t for t, ts in state.territories.items() if ts.owner == 0}
        border_territories = {
            t for t in bot_owned
            if any(state.territories[n].owner != 0 for n in MAP_GRAPH.neighbors(t))
        }
        assert border_territories, "Test setup: bot should have some border territories"

        placed_territories = set(action.placements.keys())
        assert placed_territories.issubset(bot_owned), (
            f"Placements must be on owned territories, got {placed_territories}"
        )
        assert placed_territories & border_territories, (
            f"Fallback should prefer border territories, got {placed_territories}"
        )

    def test_reinforce_fallback_random(self):
        """Given bot has no borders (owns a fully enclosed set), falls back to any owned territory (no crash)."""
        from risk.bots.medium import MediumAgent

        # Give bot all 42 territories to simulate no borders
        owner_map = {t: 0 for t in MAP_GRAPH.all_territories}
        state = _make_state(owner_map, current_player=0)

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        # Should not crash even with no enemy neighbors
        action = agent.choose_reinforcement_placement(state, armies=5)

        assert action is not None
        total_placed = sum(action.placements.values())
        assert total_placed == 5, f"Should place all 5 armies, placed {total_placed}"


# ---------------------------------------------------------------------------
# BOTS-02: MediumAgent attack strategy
# ---------------------------------------------------------------------------

@pytest.mark.xfail(reason="MediumAgent not yet implemented", strict=False)
class TestMediumAgentAttack:
    def test_attack_targets_top_continent(self):
        """Given a favorable attack into top-scored continent, returns AttackAction targeting that continent."""
        from risk.bots.medium import MediumAgent

        # Bot owns 3/4 of Australia with many armies; should want to complete it
        owner_map = {
            "Indonesia": 0,       # borders Siam (opponent)
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 1,  # target to complete Australia
        }
        # Give Indonesia lots of armies
        state = _make_state(owner_map, current_player=0)
        territories = dict(state.territories)
        territories["Indonesia"] = TerritoryState(owner=0, armies=10)
        territories["Eastern Australia"] = TerritoryState(owner=1, armies=1)
        state = state.model_copy(update={"territories": territories})

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_attack(state)

        # Should attack towards completing Australia or a favorable target
        assert action is not None, "Should attack when favorable options exist"
        assert action.num_dice >= 1

    def test_attack_skips_unfavorable(self):
        """Given only unfavorable attacks (bot armies <= defender), returns None."""
        from risk.bots.medium import MediumAgent

        # Give bot only 1-army territories; cannot attack (need >= 2)
        owner_map = {t: 0 for t in MAP_GRAPH.continent_territories("Australia")}
        state = _make_state(owner_map, current_player=0)
        territories = dict(state.territories)
        # All bot territories have exactly 1 army
        for t in owner_map:
            territories[t] = TerritoryState(owner=0, armies=1)
        state = state.model_copy(update={"territories": territories})

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_attack(state)

        assert action is None, "Should not attack when no territory has >= 2 armies"

    def test_attack_completes_continent(self):
        """If attacking would complete a continent, returns that AttackAction even with slight disadvantage."""
        from risk.bots.medium import MediumAgent

        # Bot owns 3/4 of Australia; Indonesia has 3 armies, Eastern Australia has 2 (slight disadvantage)
        owner_map = {
            "Indonesia": 0,
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 1,
        }
        state = _make_state(owner_map, current_player=0)
        territories = dict(state.territories)
        territories["Indonesia"] = TerritoryState(owner=0, armies=3)
        territories["Eastern Australia"] = TerritoryState(owner=1, armies=2)
        state = state.model_copy(update={"territories": territories})

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_attack(state)

        # Should still attack because it completes the continent bonus
        assert action is not None, (
            "Should prioritize continent-completing attacks even with small disadvantage"
        )

    def test_attack_returns_none_when_no_options(self):
        """Given state where bot has no territories with >= 2 armies, returns None."""
        from risk.bots.medium import MediumAgent

        # All bot territories have exactly 1 army
        all_territories = MAP_GRAPH.all_territories
        owner_map = {t: (0 if i % 2 == 0 else 1) for i, t in enumerate(all_territories)}
        state = _make_state(owner_map, current_player=0)
        territories = dict(state.territories)
        for t, ts in territories.items():
            if ts.owner == 0:
                territories[t] = TerritoryState(owner=0, armies=1)
        state = state.model_copy(update={"territories": territories})

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_attack(state)

        assert action is None, "Should return None when no territories have >= 2 armies"


# ---------------------------------------------------------------------------
# BOTS-02: MediumAgent fortify strategy
# ---------------------------------------------------------------------------

@pytest.mark.xfail(reason="MediumAgent not yet implemented", strict=False)
class TestMediumAgentFortify:
    def test_fortify_moves_toward_border(self):
        """Given an interior territory with surplus and a reachable border, returns FortifyAction."""
        from risk.bots.medium import MediumAgent

        # Bot owns all of Australia (Indonesia is border to Siam)
        # New Guinea is interior (borders Eastern Australia which bot owns)
        # Eastern Australia is also interior
        # Western Australia is interior
        # Indonesia is the border (borders Siam)
        owner_map = {
            "Indonesia": 0,
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 0,
        }
        state = _make_state(owner_map, current_player=0)
        territories = dict(state.territories)
        # Give Western Australia (interior) lots of armies, Indonesia (border) only 1
        territories["Western Australia"] = TerritoryState(owner=0, armies=5)
        territories["Indonesia"] = TerritoryState(owner=0, armies=1)
        territories["Eastern Australia"] = TerritoryState(owner=0, armies=1)
        territories["New Guinea"] = TerritoryState(owner=0, armies=1)
        state = state.model_copy(update={"territories": territories})

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_fortify(state)

        assert action is not None, "Should fortify to move armies toward the border"
        # Should leave at least 1 army at source
        src_armies = state.territories[action.source].armies
        assert action.armies == src_armies - 1, (
            f"Should move all but 1 army, got armies_to_move={action.armies} "
            f"from source with {src_armies}"
        )

    def test_fortify_skips_no_surplus(self):
        """Given no interior territory has more than 1 army, returns None."""
        from risk.bots.medium import MediumAgent

        # All bot territories have exactly 1 army
        owner_map = {
            "Indonesia": 0,
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 0,
        }
        state = _make_state(owner_map, current_player=0)
        territories = dict(state.territories)
        for t in owner_map:
            territories[t] = TerritoryState(owner=0, armies=1)
        state = state.model_copy(update={"territories": territories})

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_fortify(state)

        assert action is None, "Should not fortify when no territory has surplus armies"

    def test_fortify_leaves_at_least_one_army(self):
        """armies_to_move == source.armies - 1 (never 0 armies left)."""
        from risk.bots.medium import MediumAgent

        owner_map = {
            "Indonesia": 0,
            "New Guinea": 0,
            "Western Australia": 0,
            "Eastern Australia": 0,
        }
        state = _make_state(owner_map, current_player=0)
        territories = dict(state.territories)
        # Give Eastern Australia many armies (interior, connected to border via chain)
        territories["Eastern Australia"] = TerritoryState(owner=0, armies=8)
        territories["Western Australia"] = TerritoryState(owner=0, armies=1)
        territories["Indonesia"] = TerritoryState(owner=0, armies=1)
        territories["New Guinea"] = TerritoryState(owner=0, armies=1)
        state = state.model_copy(update={"territories": territories})

        agent = MediumAgent(rng=random.Random(42))
        agent._map_graph = MAP_GRAPH
        action = agent.choose_fortify(state)

        if action is not None:
            src_armies = state.territories[action.source].armies
            assert action.armies <= src_armies - 1, (
                f"Must leave at least 1 army at source: moved {action.armies} from {src_armies}"
            )
            assert action.armies >= 1, "Must move at least 1 army"


# ---------------------------------------------------------------------------
# Full-game integration tests
# ---------------------------------------------------------------------------

@pytest.mark.xfail(reason="MediumAgent not yet implemented", strict=False)
class TestFullGameIntegration:
    def test_full_game_easy_bot(self):
        """run_game() with all RandomAgents completes without exception (2-player, seeded RNG)."""
        from risk.game import RandomAgent, run_game

        rng = random.Random(42)
        agents = {i: RandomAgent(rng=random.Random(i)) for i in range(2)}

        final = run_game(MAP_GRAPH, agents, rng)

        winners = [p for p in final.players if p.is_alive]
        assert len(winners) == 1

    def test_full_game_medium_bot(self):
        """run_game() with 1 MediumAgent + 1 RandomAgent completes without exception."""
        from risk.bots.medium import MediumAgent
        from risk.game import RandomAgent, run_game

        rng = random.Random(42)
        medium = MediumAgent(rng=random.Random(0))
        random_agent = RandomAgent(rng=random.Random(1))
        agents = {0: medium, 1: random_agent}

        final = run_game(MAP_GRAPH, agents, rng)

        winners = [p for p in final.players if p.is_alive]
        assert len(winners) == 1

    def test_full_game_medium_bot_no_stall(self):
        """Same as test_full_game_medium_bot but max_turns=500 (guards against infinite loops)."""
        from risk.bots.medium import MediumAgent
        from risk.game import RandomAgent, run_game

        rng = random.Random(42)
        medium = MediumAgent(rng=random.Random(0))
        random_agent = RandomAgent(rng=random.Random(1))
        agents = {0: medium, 1: random_agent}

        # Should complete well within 500 turns
        final = run_game(MAP_GRAPH, agents, rng, max_turns=500)

        winners = [p for p in final.players if p.is_alive]
        assert len(winners) == 1
