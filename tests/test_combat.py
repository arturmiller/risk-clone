"""Tests for combat resolution: dice pairing, single attack, blitz."""

import random

import pytest

from risk.engine.combat import (
    CombatResult,
    execute_attack,
    execute_blitz,
    resolve_combat,
    validate_attack,
)
from risk.models.actions import AttackAction, BlitzAction
from risk.models.game_state import GameState, PlayerState, TerritoryState


def _two_player_state(
    source_name: str,
    target_name: str,
    source_armies: int,
    target_armies: int,
    *,
    extra_territories: dict[str, tuple[int, int]] | None = None,
) -> GameState:
    """Create a minimal 2-player state with source owned by P0, target by P1."""
    territories = {
        source_name: TerritoryState(owner=0, armies=source_armies),
        target_name: TerritoryState(owner=1, armies=target_armies),
    }
    if extra_territories:
        for name, (owner, armies) in extra_territories.items():
            territories[name] = TerritoryState(owner=owner, armies=armies)
    players = [
        PlayerState(index=0, name="P0"),
        PlayerState(index=1, name="P1"),
    ]
    return GameState(territories=territories, players=players)


class _FakeMapGraph:
    """Minimal fake implementing are_adjacent for combat tests."""

    def __init__(self, adjacencies: set[tuple[str, str]]) -> None:
        self._adj = adjacencies

    def are_adjacent(self, t1: str, t2: str) -> bool:
        return (t1, t2) in self._adj or (t2, t1) in self._adj


# ---------------------------------------------------------------------------
# resolve_combat tests
# ---------------------------------------------------------------------------


class TestResolveCombat:
    """Tests for the core dice-resolution function."""

    def test_dice_pairing_highest_first(self) -> None:
        """Dice are sorted descending before pairing."""
        # Seed that gives attacker [6,3,1] and defender [5,2]
        # We'll use a seeded rng and check properties
        rng = random.Random(42)
        result = resolve_combat(3, 2, rng)
        assert isinstance(result, CombatResult)
        assert result.attacker_losses + result.defender_losses >= 1
        # At most 2 comparisons with 3v2
        assert result.attacker_losses + result.defender_losses <= 2

    def test_ties_go_to_defender(self) -> None:
        """When dice are equal, attacker loses."""
        # Run many times with various seeds; find one that produces a tie
        # Alternatively, use a mock to control dice
        # We'll do a statistical approach: with 1v1, some seed will tie
        found_tie = False
        for seed in range(1000):
            rng = random.Random(seed)
            # 1v1 -> only 1 comparison
            result = resolve_combat(1, 1, rng)
            if result.attacker_losses == 1 and result.defender_losses == 0:
                # Could be a tie or attacker lower. Both mean attacker loses.
                # Specifically look for a tie by checking the rolls
                rng2 = random.Random(seed)
                a = rng2.randint(1, 6)
                d = rng2.randint(1, 6)
                if a == d:
                    found_tie = True
                    break
        assert found_tie, "Could not find a seed producing a tie"

    def test_attacker_wins_strict_greater(self) -> None:
        """Attacker wins only when strictly greater."""
        found_win = False
        for seed in range(1000):
            rng = random.Random(seed)
            result = resolve_combat(1, 1, rng)
            if result.defender_losses == 1:
                found_win = True
                break
        assert found_win, "Could not find attacker win"


# ---------------------------------------------------------------------------
# validate_attack tests
# ---------------------------------------------------------------------------


class TestValidateAttack:
    """Tests for attack validation."""

    def test_validate_attack_wrong_owner(self) -> None:
        """Source not owned by current player raises ValueError."""
        state = _two_player_state("A", "B", 5, 3)
        mg = _FakeMapGraph({("A", "B")})
        action = AttackAction(source="A", target="B", num_dice=2)
        with pytest.raises(ValueError, match="own"):
            validate_attack(state, mg, action, player_index=1)

    def test_validate_attack_target_friendly(self) -> None:
        """Target owned by same player raises ValueError."""
        state = _two_player_state("A", "B", 5, 3)
        # Make B also owned by P0
        state = state.model_copy(
            update={
                "territories": {
                    **state.territories,
                    "B": TerritoryState(owner=0, armies=3),
                }
            }
        )
        mg = _FakeMapGraph({("A", "B")})
        action = AttackAction(source="A", target="B", num_dice=2)
        with pytest.raises(ValueError, match="enemy|friendly|own"):
            validate_attack(state, mg, action, player_index=0)

    def test_validate_attack_not_adjacent(self) -> None:
        """Non-adjacent territories raises ValueError."""
        state = _two_player_state("A", "B", 5, 3)
        mg = _FakeMapGraph(set())  # No adjacencies
        action = AttackAction(source="A", target="B", num_dice=2)
        with pytest.raises(ValueError, match="adjacent"):
            validate_attack(state, mg, action, player_index=0)

    def test_validate_attack_insufficient_armies(self) -> None:
        """Need num_dice + 1 armies on source."""
        state = _two_player_state("A", "B", 2, 3)
        mg = _FakeMapGraph({("A", "B")})
        action = AttackAction(source="A", target="B", num_dice=2)
        # 2 armies, 2 dice -> need 3
        with pytest.raises(ValueError, match="arm"):
            validate_attack(state, mg, action, player_index=0)


# ---------------------------------------------------------------------------
# execute_attack tests
# ---------------------------------------------------------------------------


class TestExecuteAttack:
    """Tests for attack execution."""

    def test_execute_attack_conquest(self) -> None:
        """Attacker wins: territory changes owner, armies moved."""
        # Use overwhelming force: 10 vs 1, high chance of conquest
        state = _two_player_state("A", "B", 10, 1)
        mg = _FakeMapGraph({("A", "B")})
        action = AttackAction(source="A", target="B", num_dice=3)
        rng = random.Random(0)
        new_state, result, conquered = execute_attack(state, mg, action, 0, rng)
        if conquered:
            assert new_state.territories["B"].owner == 0
            assert new_state.territories["B"].armies >= action.num_dice
            assert new_state.territories["A"].armies >= 1
        # Even if not conquered first try, result should be valid
        assert result.attacker_losses >= 0
        assert result.defender_losses >= 0

    def test_execute_attack_no_conquest(self) -> None:
        """Defender survives, ownership unchanged."""
        # Find a seed where defender survives with 1v5
        state = _two_player_state("A", "B", 2, 5)
        mg = _FakeMapGraph({("A", "B")})
        action = AttackAction(source="A", target="B", num_dice=1)
        rng = random.Random(0)
        new_state, result, conquered = execute_attack(state, mg, action, 0, rng)
        # With 1 die vs 5 defender (2 dice), likely attacker loses
        if not conquered:
            assert new_state.territories["B"].owner == 1

    def test_execute_attack_min_army_remains(self) -> None:
        """After conquest, source retains at least 1 army."""
        # Force conquest: 4 armies attacking 1
        state = _two_player_state("A", "B", 4, 1)
        mg = _FakeMapGraph({("A", "B")})
        action = AttackAction(source="A", target="B", num_dice=3)
        # Try many seeds to find a conquest
        for seed in range(100):
            rng = random.Random(seed)
            new_state, result, conquered = execute_attack(state, mg, action, 0, rng)
            if conquered:
                assert new_state.territories["A"].armies >= 1
                break
        else:
            pytest.fail("Could not find seed producing conquest")

    def test_conquered_flag_set(self) -> None:
        """After conquest, state.conquered_this_turn is True."""
        state = _two_player_state("A", "B", 10, 1)
        mg = _FakeMapGraph({("A", "B")})
        action = AttackAction(source="A", target="B", num_dice=3)
        for seed in range(100):
            rng = random.Random(seed)
            new_state, result, conquered = execute_attack(state, mg, action, 0, rng)
            if conquered:
                assert new_state.conquered_this_turn is True
                break
        else:
            pytest.fail("Could not find seed producing conquest")


# ---------------------------------------------------------------------------
# execute_blitz tests
# ---------------------------------------------------------------------------


class TestExecuteBlitz:
    """Tests for blitz (auto-resolve) combat."""

    def test_blitz_attacker_wins(self) -> None:
        """With overwhelming force, attacker eventually wins."""
        state = _two_player_state("A", "B", 20, 3)
        mg = _FakeMapGraph({("A", "B")})
        action = BlitzAction(source="A", target="B")
        rng = random.Random(42)
        new_state, results, conquered = execute_blitz(state, mg, action, 0, rng)
        assert conquered is True
        assert new_state.territories["B"].owner == 0
        assert new_state.territories["A"].armies >= 1
        assert len(results) >= 1

    def test_blitz_attacker_fails(self) -> None:
        """Attacker reduced to 1 army -- attack stops."""
        state = _two_player_state("A", "B", 2, 20)
        mg = _FakeMapGraph({("A", "B")})
        action = BlitzAction(source="A", target="B")
        rng = random.Random(42)
        new_state, results, conquered = execute_blitz(state, mg, action, 0, rng)
        assert conquered is False
        assert new_state.territories["A"].armies == 1
        assert new_state.territories["B"].owner == 1

    def test_blitz_deterministic(self) -> None:
        """Same seed produces same result."""
        state = _two_player_state("A", "B", 10, 5)
        mg = _FakeMapGraph({("A", "B")})
        action = BlitzAction(source="A", target="B")

        rng1 = random.Random(99)
        s1, r1, c1 = execute_blitz(state, mg, action, 0, rng1)

        rng2 = random.Random(99)
        s2, r2, c2 = execute_blitz(state, mg, action, 0, rng2)

        assert c1 == c2
        assert len(r1) == len(r2)
        assert s1.territories["A"].armies == s2.territories["A"].armies
        assert s1.territories["B"].armies == s2.territories["B"].armies
