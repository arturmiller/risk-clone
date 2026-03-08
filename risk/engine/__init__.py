"""Risk game engine."""

from risk.engine.cards import create_deck, draw_card, execute_trade, get_trade_bonus, is_valid_set
from risk.engine.combat import CombatResult, execute_attack, execute_blitz, resolve_combat
from risk.engine.fortify import execute_fortify, validate_fortify
from risk.engine.reinforcements import calculate_reinforcements
from risk.engine.setup import STARTING_ARMIES, setup_game
from risk.engine.turn import (
    check_elimination,
    check_victory,
    execute_attack_phase,
    execute_fortify_phase,
    execute_reinforce_phase,
    execute_turn,
    force_trade_loop,
    transfer_cards,
)

__all__ = [
    "CombatResult",
    "STARTING_ARMIES",
    "calculate_reinforcements",
    "check_elimination",
    "check_victory",
    "create_deck",
    "draw_card",
    "execute_attack",
    "execute_attack_phase",
    "execute_blitz",
    "execute_fortify",
    "execute_fortify_phase",
    "execute_reinforce_phase",
    "execute_trade",
    "execute_turn",
    "force_trade_loop",
    "get_trade_bonus",
    "is_valid_set",
    "resolve_combat",
    "setup_game",
    "transfer_cards",
    "validate_fortify",
]
