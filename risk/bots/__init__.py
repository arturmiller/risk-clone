"""Bot agent implementations for Risk.

Easy bot: RandomAgent (risk.game.RandomAgent) -- no changes needed.
Medium bot: MediumAgent -- continent-aware strategy.
Hard bot: HardAgent -- human-competitive multi-factor heuristic scoring.
"""

from risk.bots.hard import HardAgent
from risk.bots.medium import MediumAgent

__all__ = ["HardAgent", "MediumAgent"]
