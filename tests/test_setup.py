"""Tests for game setup: territory distribution and army placement."""

import random

import pytest

from risk.engine.map_graph import MapGraph
from risk.engine.setup import STARTING_ARMIES, setup_game
from risk.models.game_state import GameState


class TestTerritoryDistribution:
    def test_territory_distribution_2_players(self, map_graph: MapGraph) -> None:
        gs = setup_game(map_graph, 2, rng=random.Random(42))
        counts = [0, 0]
        for ts in gs.territories.values():
            counts[ts.owner] += 1
        assert counts == [21, 21]

    def test_territory_distribution_3_players(self, map_graph: MapGraph) -> None:
        gs = setup_game(map_graph, 3, rng=random.Random(42))
        counts = [0, 0, 0]
        for ts in gs.territories.values():
            counts[ts.owner] += 1
        assert counts == [14, 14, 14]

    def test_territory_distribution_4_players(self, map_graph: MapGraph) -> None:
        gs = setup_game(map_graph, 4, rng=random.Random(42))
        counts = [0] * 4
        for ts in gs.territories.values():
            counts[ts.owner] += 1
        # 42 / 4 = 10 r 2, so two players get 11, two get 10
        assert sorted(counts) == [10, 10, 11, 11]

    def test_territory_distribution_5_players(self, map_graph: MapGraph) -> None:
        gs = setup_game(map_graph, 5, rng=random.Random(42))
        counts = [0] * 5
        for ts in gs.territories.values():
            counts[ts.owner] += 1
        # 42 / 5 = 8 r 2, so two players get 9, three get 8
        assert sorted(counts) == [8, 8, 8, 9, 9]

    def test_territory_distribution_6_players(self, map_graph: MapGraph) -> None:
        gs = setup_game(map_graph, 6, rng=random.Random(42))
        counts = [0] * 6
        for ts in gs.territories.values():
            counts[ts.owner] += 1
        assert counts == [7, 7, 7, 7, 7, 7]

    def test_territory_counts_differ_by_at_most_one(
        self, map_graph: MapGraph
    ) -> None:
        for num_players in range(2, 7):
            gs = setup_game(map_graph, num_players, rng=random.Random(99))
            counts = [0] * num_players
            for ts in gs.territories.values():
                counts[ts.owner] += 1
            assert max(counts) - min(counts) <= 1, (
                f"Imbalanced distribution for {num_players} players: {counts}"
            )


class TestArmyPlacement:
    def test_army_counts_per_player(self, map_graph: MapGraph) -> None:
        for num_players in range(2, 7):
            gs = setup_game(map_graph, num_players, rng=random.Random(42))
            expected = STARTING_ARMIES[num_players]
            for player_idx in range(num_players):
                total = sum(
                    ts.armies
                    for ts in gs.territories.values()
                    if ts.owner == player_idx
                )
                assert total == expected, (
                    f"Player {player_idx} has {total} armies, "
                    f"expected {expected} for {num_players} players"
                )

    def test_every_territory_has_minimum_one_army(
        self, map_graph: MapGraph
    ) -> None:
        for num_players in range(2, 7):
            gs = setup_game(map_graph, num_players, rng=random.Random(42))
            for name, ts in gs.territories.items():
                assert ts.armies >= 1, (
                    f"{name} has {ts.armies} armies"
                )

    def test_all_territories_assigned(self, map_graph: MapGraph) -> None:
        gs = setup_game(map_graph, 3, rng=random.Random(42))
        assert len(gs.territories) == 42
        assert set(gs.territories.keys()) == set(map_graph.all_territories)


class TestSetupDeterminism:
    def test_deterministic_with_seed(self, map_graph: MapGraph) -> None:
        gs1 = setup_game(map_graph, 3, rng=random.Random(42))
        gs2 = setup_game(map_graph, 3, rng=random.Random(42))
        assert gs1 == gs2

    def test_different_seeds_produce_different_results(
        self, map_graph: MapGraph
    ) -> None:
        gs1 = setup_game(map_graph, 3, rng=random.Random(42))
        gs2 = setup_game(map_graph, 3, rng=random.Random(99))
        assert gs1 != gs2


class TestSetupValidation:
    def test_invalid_player_count_too_low(self, map_graph: MapGraph) -> None:
        with pytest.raises(ValueError):
            setup_game(map_graph, 1)

    def test_invalid_player_count_zero(self, map_graph: MapGraph) -> None:
        with pytest.raises(ValueError):
            setup_game(map_graph, 0)

    def test_invalid_player_count_too_high(self, map_graph: MapGraph) -> None:
        with pytest.raises(ValueError):
            setup_game(map_graph, 7)
