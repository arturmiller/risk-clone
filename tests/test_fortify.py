"""Tests for fortification: path validation, army movement, boundary cases."""

import pytest

from risk.engine.fortify import execute_fortify, validate_fortify
from risk.models.actions import FortifyAction
from risk.models.game_state import GameState, PlayerState, TerritoryState


class _FakeMapGraph:
    """Minimal fake implementing connected_territories for fortify tests."""

    def __init__(self, adjacencies: set[tuple[str, str]]) -> None:
        self._adj = adjacencies

    def are_adjacent(self, t1: str, t2: str) -> bool:
        return (t1, t2) in self._adj or (t2, t1) in self._adj

    def connected_territories(
        self, start: str, friendly_territories: set[str]
    ) -> set[str]:
        """BFS through friendly territories using adjacency."""
        if start not in friendly_territories:
            return set()
        visited = {start}
        queue = [start]
        while queue:
            current = queue.pop(0)
            for t in friendly_territories:
                if t not in visited and self.are_adjacent(current, t):
                    visited.add(t)
                    queue.append(t)
        return visited


def _make_state(
    territory_data: dict[str, tuple[int, int]],
) -> GameState:
    """Create state from {name: (owner, armies)} dict."""
    territories = {
        name: TerritoryState(owner=owner, armies=armies)
        for name, (owner, armies) in territory_data.items()
    }
    players = [
        PlayerState(index=0, name="P0"),
        PlayerState(index=1, name="P1"),
    ]
    return GameState(territories=territories, players=players)


# ---------------------------------------------------------------------------
# validate_fortify tests
# ---------------------------------------------------------------------------


class TestValidateFortify:
    """Tests for fortification validation."""

    def test_valid_fortify_adjacent(self) -> None:
        """Move armies between two adjacent friendly territories."""
        state = _make_state({"A": (0, 5), "B": (0, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=2)
        # Should not raise
        validate_fortify(state, mg, action, player_index=0)

    def test_valid_fortify_through_chain(self) -> None:
        """Move armies through a chain of 3+ friendly territories."""
        state = _make_state({"A": (0, 5), "B": (0, 3), "C": (0, 2)})
        mg = _FakeMapGraph({("A", "B"), ("B", "C")})
        action = FortifyAction(source="A", target="C", armies=2)
        # Should not raise -- A connected to C through B
        validate_fortify(state, mg, action, player_index=0)

    def test_fortify_blocked_by_enemy(self) -> None:
        """Two friendly territories connected only through enemy -> ValueError."""
        state = _make_state({"A": (0, 5), "B": (1, 3), "C": (0, 2)})
        mg = _FakeMapGraph({("A", "B"), ("B", "C")})
        action = FortifyAction(source="A", target="C", armies=2)
        with pytest.raises(ValueError, match="connected|reachable|path"):
            validate_fortify(state, mg, action, player_index=0)

    def test_fortify_source_not_owned(self) -> None:
        """Source owned by other player -> ValueError."""
        state = _make_state({"A": (1, 5), "B": (0, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=2)
        with pytest.raises(ValueError, match="own"):
            validate_fortify(state, mg, action, player_index=0)

    def test_fortify_target_not_owned(self) -> None:
        """Target owned by other player -> ValueError."""
        state = _make_state({"A": (0, 5), "B": (1, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=2)
        with pytest.raises(ValueError, match="own"):
            validate_fortify(state, mg, action, player_index=0)

    def test_fortify_too_many_armies(self) -> None:
        """Trying to move all armies (leaving 0) -> ValueError."""
        state = _make_state({"A": (0, 5), "B": (0, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=5)
        with pytest.raises(ValueError, match="arm"):
            validate_fortify(state, mg, action, player_index=0)

    def test_fortify_max_armies(self) -> None:
        """Moving source_armies - 1 is allowed, source has exactly 1."""
        state = _make_state({"A": (0, 5), "B": (0, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=4)
        # Should not raise
        validate_fortify(state, mg, action, player_index=0)


# ---------------------------------------------------------------------------
# execute_fortify tests
# ---------------------------------------------------------------------------


class TestExecuteFortify:
    """Tests for fortification execution."""

    def test_fortify_armies_correct(self) -> None:
        """After fortify, armies are correctly transferred."""
        state = _make_state({"A": (0, 5), "B": (0, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=2)
        new_state = execute_fortify(state, mg, action, player_index=0)
        assert new_state.territories["A"].armies == 3
        assert new_state.territories["B"].armies == 5

    def test_fortify_state_unchanged_on_error(self) -> None:
        """After ValueError, original state is unmodified."""
        state = _make_state({"A": (0, 5), "B": (1, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=2)
        original_a_armies = state.territories["A"].armies
        original_b_armies = state.territories["B"].armies
        with pytest.raises(ValueError):
            execute_fortify(state, mg, action, player_index=0)
        assert state.territories["A"].armies == original_a_armies
        assert state.territories["B"].armies == original_b_armies

    def test_fortify_max_leaves_one(self) -> None:
        """Moving max armies leaves source with exactly 1."""
        state = _make_state({"A": (0, 5), "B": (0, 3)})
        mg = _FakeMapGraph({("A", "B")})
        action = FortifyAction(source="A", target="B", armies=4)
        new_state = execute_fortify(state, mg, action, player_index=0)
        assert new_state.territories["A"].armies == 1
        assert new_state.territories["B"].armies == 7
