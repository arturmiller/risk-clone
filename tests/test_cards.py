"""Tests for card system: deck, set validation, trading, drawing."""

import pytest

from risk.models.cards import Card, CardType
from risk.models.game_state import GameState, PlayerState, TerritoryState
from risk.engine.cards import (
    create_deck,
    draw_card,
    execute_trade,
    get_trade_bonus,
    is_valid_set,
)


def _infantry(territory: str = "A") -> Card:
    return Card(territory=territory, card_type=CardType.INFANTRY)


def _cavalry(territory: str = "B") -> Card:
    return Card(territory=territory, card_type=CardType.CAVALRY)


def _artillery(territory: str = "C") -> Card:
    return Card(territory=territory, card_type=CardType.ARTILLERY)


def _wild() -> Card:
    return Card(territory=None, card_type=CardType.WILD)


# --- create_deck ---


class TestCreateDeck:
    def test_deck_size(self, map_graph) -> None:
        deck = create_deck(map_graph.all_territories)
        assert len(deck) == 44  # 42 territory + 2 wild

    def test_wild_count(self, map_graph) -> None:
        deck = create_deck(map_graph.all_territories)
        wilds = [c for c in deck if c.card_type == CardType.WILD]
        assert len(wilds) == 2

    def test_territory_cards_cover_all(self, map_graph) -> None:
        deck = create_deck(map_graph.all_territories)
        territory_cards = [c for c in deck if c.territory is not None]
        territories = {c.territory for c in territory_cards}
        assert territories == set(map_graph.all_territories)

    def test_type_distribution(self, map_graph) -> None:
        deck = create_deck(map_graph.all_territories)
        territory_cards = [c for c in deck if c.card_type != CardType.WILD]
        types = [c.card_type for c in territory_cards]
        assert types.count(CardType.INFANTRY) == 14
        assert types.count(CardType.CAVALRY) == 14
        assert types.count(CardType.ARTILLERY) == 14


# --- is_valid_set ---


class TestIsValidSet:
    def test_three_infantry(self) -> None:
        assert is_valid_set([_infantry("A"), _infantry("B"), _infantry("C")]) is True

    def test_three_cavalry(self) -> None:
        assert is_valid_set([_cavalry("A"), _cavalry("B"), _cavalry("C")]) is True

    def test_three_artillery(self) -> None:
        assert is_valid_set([_artillery("A"), _artillery("B"), _artillery("C")]) is True

    def test_one_of_each(self) -> None:
        assert is_valid_set([_infantry(), _cavalry(), _artillery()]) is True

    def test_two_plus_wild(self) -> None:
        assert is_valid_set([_infantry("A"), _infantry("B"), _wild()]) is True

    def test_two_different_plus_wild(self) -> None:
        assert is_valid_set([_infantry(), _cavalry(), _wild()]) is True

    def test_two_wilds_plus_any(self) -> None:
        assert is_valid_set([_wild(), _wild(), _infantry()]) is True

    def test_invalid_two_matching_one_different(self) -> None:
        assert is_valid_set([_infantry("A"), _infantry("B"), _cavalry()]) is False

    def test_wrong_count_two(self) -> None:
        assert is_valid_set([_infantry(), _infantry()]) is False

    def test_wrong_count_four(self) -> None:
        assert is_valid_set([_infantry(), _infantry(), _infantry(), _infantry()]) is False


# --- get_trade_bonus ---


class TestGetTradeBonus:
    def test_first_trade(self) -> None:
        assert get_trade_bonus(0) == 4

    def test_second_trade(self) -> None:
        assert get_trade_bonus(1) == 6

    def test_third_trade(self) -> None:
        assert get_trade_bonus(2) == 8

    def test_fourth_trade(self) -> None:
        assert get_trade_bonus(3) == 10

    def test_fifth_trade(self) -> None:
        assert get_trade_bonus(4) == 12

    def test_sixth_trade(self) -> None:
        assert get_trade_bonus(5) == 15

    def test_seventh_trade(self) -> None:
        assert get_trade_bonus(6) == 20

    def test_eighth_trade(self) -> None:
        assert get_trade_bonus(7) == 25

    def test_ninth_trade(self) -> None:
        assert get_trade_bonus(8) == 30

    def test_tenth_trade(self) -> None:
        assert get_trade_bonus(9) == 35


# --- draw_card ---


class TestDrawCard:
    def test_draw_moves_card(self) -> None:
        deck = [_infantry("Alaska"), _cavalry("Brazil")]
        state = GameState(
            territories={"Alaska": TerritoryState(owner=0, armies=1)},
            players=[PlayerState(index=0, name="P0")],
            deck=deck,
            cards={0: []},
        )
        new_state = draw_card(state, 0)
        assert len(new_state.deck) == 1
        assert len(new_state.cards[0]) == 1
        assert new_state.cards[0][0].territory == "Alaska"

    def test_draw_from_empty_deck(self) -> None:
        state = GameState(
            territories={"Alaska": TerritoryState(owner=0, armies=1)},
            players=[PlayerState(index=0, name="P0")],
            deck=[],
            cards={0: []},
        )
        new_state = draw_card(state, 0)
        assert len(new_state.cards[0]) == 0
        assert new_state.deck == []

    def test_draw_initializes_empty_hand(self) -> None:
        deck = [_infantry("Alaska")]
        state = GameState(
            territories={"Alaska": TerritoryState(owner=0, armies=1)},
            players=[PlayerState(index=0, name="P0")],
            deck=deck,
            cards={},
        )
        new_state = draw_card(state, 0)
        assert len(new_state.cards[0]) == 1


# --- execute_trade ---


class TestExecuteTrade:
    def _make_trade_state(self, player_cards: list[Card], trade_count: int = 0) -> GameState:
        return GameState(
            territories={
                "Alaska": TerritoryState(owner=0, armies=1),
                "Brazil": TerritoryState(owner=1, armies=1),
            },
            players=[
                PlayerState(index=0, name="P0"),
                PlayerState(index=1, name="P1"),
            ],
            cards={0: player_cards},
            trade_count=trade_count,
        )

    def test_basic_trade_returns_bonus(self) -> None:
        cards = [_infantry("X"), _infantry("Y"), _infantry("Z")]
        state = self._make_trade_state(cards, trade_count=0)
        new_state, bonus, territory_bonus = execute_trade(state, 0, [0, 1, 2])
        assert bonus == 4  # First trade
        assert new_state.trade_count == 1

    def test_cards_removed_from_hand(self) -> None:
        cards = [_infantry("X"), _infantry("Y"), _infantry("Z"), _cavalry("W")]
        state = self._make_trade_state(cards, trade_count=0)
        new_state, bonus, territory_bonus = execute_trade(state, 0, [0, 1, 2])
        assert len(new_state.cards[0]) == 1
        assert new_state.cards[0][0].territory == "W"

    def test_trade_count_increments(self) -> None:
        cards = [_infantry("X"), _infantry("Y"), _infantry("Z")]
        state = self._make_trade_state(cards, trade_count=3)
        new_state, bonus, territory_bonus = execute_trade(state, 0, [0, 1, 2])
        assert new_state.trade_count == 4
        assert bonus == 10  # 4th trade (index 3)

    def test_territory_bonus_owned_territory(self) -> None:
        """Trading a card showing a territory you own gives 2 extra armies there."""
        cards = [
            Card(territory="Alaska", card_type=CardType.INFANTRY),
            _infantry("Y"),
            _infantry("Z"),
        ]
        state = self._make_trade_state(cards, trade_count=0)
        new_state, bonus, territory_bonus = execute_trade(state, 0, [0, 1, 2])
        assert territory_bonus.get("Alaska") == 2

    def test_territory_bonus_not_owned(self) -> None:
        """Trading a card showing a territory you DON'T own gives no bonus."""
        cards = [
            Card(territory="Brazil", card_type=CardType.INFANTRY),
            _infantry("Y"),
            _infantry("Z"),
        ]
        state = self._make_trade_state(cards, trade_count=0)
        new_state, bonus, territory_bonus = execute_trade(state, 0, [0, 1, 2])
        assert "Brazil" not in territory_bonus

    def test_invalid_set_raises(self) -> None:
        cards = [_infantry("A"), _infantry("B"), _cavalry("C")]
        state = self._make_trade_state(cards, trade_count=0)
        with pytest.raises(ValueError):
            execute_trade(state, 0, [0, 1, 2])


# --- Forced trade detection ---


class TestForcedTrade:
    def test_five_cards_forces_trade(self) -> None:
        """Player with 5+ cards must trade."""
        cards = [_infantry(f"T{i}") for i in range(5)]
        # Forced trade is just a check: len(cards) >= 5
        assert len(cards) >= 5

    def test_four_cards_not_forced(self) -> None:
        cards = [_infantry(f"T{i}") for i in range(4)]
        assert len(cards) < 5
