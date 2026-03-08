"""Risk game engine."""

from risk.engine.cards import create_deck, draw_card, execute_trade, get_trade_bonus, is_valid_set
from risk.engine.combat import CombatResult, execute_attack, execute_blitz, resolve_combat
from risk.engine.fortify import execute_fortify, validate_fortify
from risk.engine.reinforcements import calculate_reinforcements
from risk.engine.setup import STARTING_ARMIES, setup_game

__all__ = [
    "CombatResult",
    "STARTING_ARMIES",
    "calculate_reinforcements",
    "create_deck",
    "draw_card",
    "execute_attack",
    "execute_blitz",
    "execute_fortify",
    "execute_trade",
    "get_trade_bonus",
    "is_valid_set",
    "resolve_combat",
    "setup_game",
    "validate_fortify",
]
