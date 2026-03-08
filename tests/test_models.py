"""Tests for Phase 2 models: cards, actions, extended GameState, and PlayerAgent."""

import pytest
from pydantic import ValidationError

from risk.models.cards import Card, CardType, TurnPhase
from risk.models.actions import (
    AttackAction,
    BlitzAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.game_state import GameState, PlayerState, TerritoryState


# --- CardType and TurnPhase enums ---


class TestCardType:
    def test_has_infantry(self) -> None:
        assert CardType.INFANTRY is not None

    def test_has_cavalry(self) -> None:
        assert CardType.CAVALRY is not None

    def test_has_artillery(self) -> None:
        assert CardType.ARTILLERY is not None

    def test_has_wild(self) -> None:
        assert CardType.WILD is not None

    def test_four_values(self) -> None:
        assert len(CardType) == 4


class TestTurnPhase:
    def test_has_reinforce(self) -> None:
        assert TurnPhase.REINFORCE is not None

    def test_has_attack(self) -> None:
        assert TurnPhase.ATTACK is not None

    def test_has_fortify(self) -> None:
        assert TurnPhase.FORTIFY is not None

    def test_three_values(self) -> None:
        assert len(TurnPhase) == 3


# --- Card model ---


class TestCard:
    def test_territory_card(self) -> None:
        card = Card(territory="Alaska", card_type=CardType.INFANTRY)
        assert card.territory == "Alaska"
        assert card.card_type == CardType.INFANTRY

    def test_wild_card_no_territory(self) -> None:
        card = Card(territory=None, card_type=CardType.WILD)
        assert card.territory is None
        assert card.card_type == CardType.WILD

    def test_roundtrip_serialization(self) -> None:
        card = Card(territory="Brazil", card_type=CardType.CAVALRY)
        data = card.model_dump()
        restored = Card.model_validate(data)
        assert restored == card

    def test_wild_roundtrip(self) -> None:
        card = Card(territory=None, card_type=CardType.WILD)
        data = card.model_dump()
        restored = Card.model_validate(data)
        assert restored == card


# --- Action models ---


class TestAttackAction:
    def test_valid_attack(self) -> None:
        action = AttackAction(source="Alaska", target="Kamchatka", num_dice=3)
        assert action.source == "Alaska"
        assert action.target == "Kamchatka"
        assert action.num_dice == 3

    def test_num_dice_min(self) -> None:
        action = AttackAction(source="A", target="B", num_dice=1)
        assert action.num_dice == 1

    def test_num_dice_too_low(self) -> None:
        with pytest.raises(ValidationError):
            AttackAction(source="A", target="B", num_dice=0)

    def test_num_dice_too_high(self) -> None:
        with pytest.raises(ValidationError):
            AttackAction(source="A", target="B", num_dice=4)

    def test_roundtrip(self) -> None:
        action = AttackAction(source="A", target="B", num_dice=2)
        assert AttackAction.model_validate(action.model_dump()) == action


class TestBlitzAction:
    def test_valid_blitz(self) -> None:
        action = BlitzAction(source="Alaska", target="Kamchatka")
        assert action.source == "Alaska"
        assert action.target == "Kamchatka"


class TestFortifyAction:
    def test_valid_fortify(self) -> None:
        action = FortifyAction(source="A", target="B", armies=5)
        assert action.armies == 5

    def test_armies_min(self) -> None:
        action = FortifyAction(source="A", target="B", armies=1)
        assert action.armies == 1

    def test_armies_zero_invalid(self) -> None:
        with pytest.raises(ValidationError):
            FortifyAction(source="A", target="B", armies=0)

    def test_roundtrip(self) -> None:
        action = FortifyAction(source="A", target="B", armies=3)
        assert FortifyAction.model_validate(action.model_dump()) == action


class TestTradeCardsAction:
    def test_valid_trade(self) -> None:
        cards = [
            Card(territory="A", card_type=CardType.INFANTRY),
            Card(territory="B", card_type=CardType.INFANTRY),
            Card(territory="C", card_type=CardType.INFANTRY),
        ]
        action = TradeCardsAction(cards=cards)
        assert len(action.cards) == 3

    def test_wrong_count_two(self) -> None:
        cards = [
            Card(territory="A", card_type=CardType.INFANTRY),
            Card(territory="B", card_type=CardType.INFANTRY),
        ]
        with pytest.raises(ValidationError):
            TradeCardsAction(cards=cards)

    def test_wrong_count_four(self) -> None:
        cards = [
            Card(territory="A", card_type=CardType.INFANTRY),
            Card(territory="B", card_type=CardType.INFANTRY),
            Card(territory="C", card_type=CardType.INFANTRY),
            Card(territory="D", card_type=CardType.INFANTRY),
        ]
        with pytest.raises(ValidationError):
            TradeCardsAction(cards=cards)


class TestReinforcePlacementAction:
    def test_valid_placement(self) -> None:
        action = ReinforcePlacementAction(placements={"Alaska": 3, "Brazil": 2})
        assert action.placements["Alaska"] == 3

    def test_roundtrip(self) -> None:
        action = ReinforcePlacementAction(placements={"A": 1, "B": 2})
        assert ReinforcePlacementAction.model_validate(action.model_dump()) == action


# --- Extended GameState ---


class TestExtendedGameState:
    def test_backwards_compatible(self) -> None:
        """Phase 1 code can still create GameState without new fields."""
        state = GameState(
            territories={"Alaska": TerritoryState(owner=0, armies=3)},
            players=[PlayerState(index=0, name="P1")],
        )
        assert state.current_player_index == 0
        assert state.turn_number == 0

    def test_new_fields_defaults(self) -> None:
        state = GameState(
            territories={"Alaska": TerritoryState(owner=0, armies=3)},
            players=[PlayerState(index=0, name="P1")],
        )
        assert state.turn_phase == TurnPhase.REINFORCE
        assert state.trade_count == 0
        assert state.cards == {}
        assert state.deck == []
        assert state.conquered_this_turn is False

    def test_new_fields_explicit(self) -> None:
        cards = {0: [Card(territory="Alaska", card_type=CardType.INFANTRY)]}
        deck = [Card(territory=None, card_type=CardType.WILD)]
        state = GameState(
            territories={"Alaska": TerritoryState(owner=0, armies=3)},
            players=[PlayerState(index=0, name="P1")],
            turn_phase=TurnPhase.ATTACK,
            trade_count=2,
            cards=cards,
            deck=deck,
            conquered_this_turn=True,
        )
        assert state.turn_phase == TurnPhase.ATTACK
        assert state.trade_count == 2
        assert len(state.cards[0]) == 1
        assert len(state.deck) == 1
        assert state.conquered_this_turn is True

    def test_extended_roundtrip(self) -> None:
        cards = {0: [Card(territory="Brazil", card_type=CardType.CAVALRY)]}
        state = GameState(
            territories={"Alaska": TerritoryState(owner=0, armies=3)},
            players=[PlayerState(index=0, name="P1")],
            turn_phase=TurnPhase.FORTIFY,
            trade_count=5,
            cards=cards,
            deck=[],
            conquered_this_turn=True,
        )
        data = state.model_dump()
        restored = GameState.model_validate(data)
        assert restored == state


# --- PlayerAgent protocol ---


class TestPlayerAgentProtocol:
    def test_protocol_exists(self) -> None:
        from risk.player import PlayerAgent
        assert PlayerAgent is not None

    def test_protocol_has_methods(self) -> None:
        from risk.player import PlayerAgent
        # Protocol should define these methods
        assert hasattr(PlayerAgent, "choose_reinforcement_placement")
        assert hasattr(PlayerAgent, "choose_attack")
        assert hasattr(PlayerAgent, "choose_fortify")
        assert hasattr(PlayerAgent, "choose_card_trade")
        assert hasattr(PlayerAgent, "choose_blitz")
        assert hasattr(PlayerAgent, "choose_defender_dice")
