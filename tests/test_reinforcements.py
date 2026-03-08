"""Tests for reinforcement calculation."""

import pytest

from risk.engine.reinforcements import calculate_reinforcements
from risk.models.game_state import GameState, PlayerState, TerritoryState


def _make_state(
    player_territories: list[str],
    all_territories: list[str],
    num_players: int = 2,
) -> GameState:
    """Create a GameState where player 0 owns given territories, player 1 owns the rest."""
    territories = {}
    for t in all_territories:
        if t in player_territories:
            territories[t] = TerritoryState(owner=0, armies=1)
        else:
            territories[t] = TerritoryState(owner=1, armies=1)
    players = [PlayerState(index=i, name=f"P{i}") for i in range(num_players)]
    return GameState(territories=territories, players=players)


def _pick_no_continent(map_graph, count: int) -> list[str]:
    """Pick N territories that do NOT complete any continent.

    Strategy: take first territory from each continent in rotation,
    never taking all territories from any single continent.
    """
    continent_lists = {
        c: sorted(map_graph.continent_territories(c))
        for c in map_graph._continent_bonuses
    }
    picked: list[str] = []
    idx = 0
    while len(picked) < count:
        for c_name in sorted(continent_lists.keys()):
            c_terrs = continent_lists[c_name]
            c_size = len(c_terrs)
            # Never take more than c_size - 1 from any continent
            already = sum(1 for t in picked if t in set(c_terrs))
            if already < c_size - 1 and idx < len(c_terrs) and len(picked) < count:
                picked.append(c_terrs[already])
        idx += 1
    return picked[:count]


class TestBaseReinforcements:
    """Test territory-count-based reinforcements (no continent bonuses)."""

    def test_two_territories_minimum_three(self, map_graph) -> None:
        """2 territories -> floor(2/3)=0 but minimum is 3."""
        terrs = _pick_no_continent(map_graph, 2)
        state = _make_state(terrs, map_graph.all_territories)
        assert calculate_reinforcements(state, map_graph, 0) == 3

    def test_nine_territories(self, map_graph) -> None:
        """9 territories -> floor(9/3) = 3."""
        terrs = _pick_no_continent(map_graph, 9)
        state = _make_state(terrs, map_graph.all_territories)
        result = calculate_reinforcements(state, map_graph, 0)
        assert result == 3

    def test_eleven_territories(self, map_graph) -> None:
        """11 territories -> floor(11/3) = 3, minimum 3."""
        terrs = _pick_no_continent(map_graph, 11)
        state = _make_state(terrs, map_graph.all_territories)
        result = calculate_reinforcements(state, map_graph, 0)
        assert result == 3

    def test_twelve_territories_base_four(self, map_graph) -> None:
        """12 territories -> floor(12/3) = 4."""
        terrs = _pick_no_continent(map_graph, 12)
        state = _make_state(terrs, map_graph.all_territories)
        result = calculate_reinforcements(state, map_graph, 0)
        assert result == 4

    def test_fifteen_territories(self, map_graph) -> None:
        """15 territories -> floor(15/3) = 5."""
        terrs = _pick_no_continent(map_graph, 15)
        state = _make_state(terrs, map_graph.all_territories)
        result = calculate_reinforcements(state, map_graph, 0)
        assert result == 5


class TestContinentBonuses:
    """Test continent control bonuses."""

    def test_australia_bonus(self, map_graph) -> None:
        """Controlling all of Australia gives +2 bonus."""
        australia_terrs = map_graph.continent_territories("Australia")
        # Give player some extra non-continent-completing territories
        other_terrs = [
            t for t in map_graph.all_territories
            if t not in australia_terrs
        ][:5]
        player_terrs = list(australia_terrs) + other_terrs
        state = _make_state(player_terrs, map_graph.all_territories)
        result = calculate_reinforcements(state, map_graph, 0)
        total_count = len(player_terrs)
        base = max(total_count // 3, 3)
        expected = base + 2  # Australia bonus
        assert result == expected

    def test_asia_bonus(self, map_graph) -> None:
        """Controlling all of Asia gives +7 bonus."""
        asia_terrs = map_graph.continent_territories("Asia")
        # Give player some extra territories
        other_terrs = [
            t for t in map_graph.all_territories
            if t not in asia_terrs
        ][:3]
        player_terrs = list(asia_terrs) + other_terrs
        state = _make_state(player_terrs, map_graph.all_territories)
        result = calculate_reinforcements(state, map_graph, 0)
        total_count = len(player_terrs)
        base = max(total_count // 3, 3)
        expected = base + 7  # Asia bonus
        assert result == expected

    def test_multiple_continents_stack(self, map_graph) -> None:
        """Bonuses from multiple continents stack."""
        australia_terrs = map_graph.continent_territories("Australia")
        sa_terrs = map_graph.continent_territories("South America")
        player_terrs = list(australia_terrs) + list(sa_terrs)
        state = _make_state(player_terrs, map_graph.all_territories)
        result = calculate_reinforcements(state, map_graph, 0)
        total_count = len(player_terrs)
        base = max(total_count // 3, 3)
        australia_bonus = map_graph.continent_bonus("Australia")
        sa_bonus = map_graph.continent_bonus("South America")
        expected = base + australia_bonus + sa_bonus
        assert result == expected

    def test_all_territories(self, map_graph) -> None:
        """Player owning all 42 territories gets base + all continent bonuses."""
        all_t = map_graph.all_territories
        state = _make_state(all_t, all_t, num_players=1)
        result = calculate_reinforcements(state, map_graph, 0)
        base = len(all_t) // 3  # 42 // 3 = 14
        total_bonus = sum(
            map_graph.continent_bonus(c)
            for c in map_graph._continent_bonuses
        )
        assert result == base + total_bonus
