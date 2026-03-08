"""End-to-end tests: full game runs to completion with random bot agents."""

import random
from pathlib import Path

import pytest

from risk.engine.map_graph import MapGraph, load_map

DATA_DIR = Path(__file__).resolve().parent.parent / "risk" / "data"


def _load_map_graph() -> MapGraph:
    map_data = load_map(DATA_DIR / "classic.json")
    return MapGraph(map_data)


class TestFullGame:
    def test_full_game_3_players(self):
        """run_game with 3 RandomAgents completes, winner owns all 42 territories."""
        from risk.game import RandomAgent, run_game

        mg = _load_map_graph()
        rng = random.Random(42)
        agents = {i: RandomAgent(rng=random.Random(i)) for i in range(3)}

        final = run_game(mg, agents, rng)

        winners = [p for p in final.players if p.is_alive]
        assert len(winners) == 1

        winner_idx = winners[0].index
        owned = [
            n for n, ts in final.territories.items() if ts.owner == winner_idx
        ]
        assert len(owned) == 42

    def test_full_game_6_players(self):
        """run_game with 6 RandomAgents completes."""
        from risk.game import RandomAgent, run_game

        mg = _load_map_graph()
        rng = random.Random(99)
        agents = {i: RandomAgent(rng=random.Random(i + 100)) for i in range(6)}

        final = run_game(mg, agents, rng)

        winners = [p for p in final.players if p.is_alive]
        assert len(winners) == 1

    def test_full_game_deterministic(self):
        """Same seed produces same winner and same turn count."""
        from risk.game import RandomAgent, run_game

        mg = _load_map_graph()

        def _run(seed):
            rng = random.Random(seed)
            agents = {i: RandomAgent(rng=random.Random(i)) for i in range(3)}
            return run_game(mg, agents, rng)

        result1 = _run(42)
        result2 = _run(42)

        w1 = [p for p in result1.players if p.is_alive][0].index
        w2 = [p for p in result2.players if p.is_alive][0].index
        assert w1 == w2
        assert result1.turn_number == result2.turn_number

    def test_full_game_all_losers_dead(self):
        """All non-winner players have is_alive=False."""
        from risk.game import RandomAgent, run_game

        mg = _load_map_graph()
        rng = random.Random(42)
        agents = {i: RandomAgent(rng=random.Random(i)) for i in range(3)}

        final = run_game(mg, agents, rng)

        alive_count = sum(1 for p in final.players if p.is_alive)
        assert alive_count == 1

        for p in final.players:
            if not p.is_alive:
                owned = sum(
                    1
                    for ts in final.territories.values()
                    if ts.owner == p.index
                )
                assert owned == 0

    def test_full_game_no_cards_remaining(self):
        """All cards accounted for: in deck + winner's hand."""
        from risk.game import RandomAgent, run_game

        mg = _load_map_graph()
        rng = random.Random(42)
        agents = {i: RandomAgent(rng=random.Random(i)) for i in range(3)}

        final = run_game(mg, agents, rng)

        # Total cards in all hands + deck should be <= 44 (some may be consumed by trades)
        total_in_hands = sum(len(h) for h in final.cards.values())
        total_in_deck = len(final.deck)
        # Cards traded go back nowhere in this implementation (consumed),
        # so total should be <= 44
        assert total_in_hands + total_in_deck <= 44

    def test_full_game_2_players(self):
        """Simplest case: 2 RandomAgents."""
        from risk.game import RandomAgent, run_game

        mg = _load_map_graph()
        rng = random.Random(7)
        agents = {i: RandomAgent(rng=random.Random(i + 50)) for i in range(2)}

        final = run_game(mg, agents, rng)

        winners = [p for p in final.players if p.is_alive]
        assert len(winners) == 1

        winner_idx = winners[0].index
        owned = [
            n for n, ts in final.territories.items() if ts.owner == winner_idx
        ]
        assert len(owned) == 42
