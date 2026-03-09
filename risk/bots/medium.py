"""MediumAgent: continent-aware bot for Risk."""

import random as _random
from typing import Any

from risk.engine.cards import is_valid_set
from risk.engine.map_graph import MapGraph
from risk.models.actions import (
    AttackAction,
    FortifyAction,
    ReinforcePlacementAction,
    TradeCardsAction,
)
from risk.models.cards import Card
from risk.models.game_state import GameState


class MediumAgent:
    """Continent-aware bot implementing the PlayerAgent protocol.

    Prioritizes completing continents: reinforces borders, attacks strategically,
    fortifies toward exposed borders. Card trading matches RandomAgent.

    map_graph is injected after construction via agent._map_graph = map_graph.
    """

    def __init__(self, rng: _random.Random | None = None) -> None:
        self._rng = rng or _random.Random()
        self._map_graph: MapGraph | None = None

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _continent_scores(self, state: GameState) -> dict[str, float]:
        """Score each continent by fraction of territories owned by current player."""
        mg = self._map_graph
        if mg is None:
            return {}
        player = state.current_player_index
        scores: dict[str, float] = {}
        for continent, territories in mg._continent_territories.items():
            total = len(territories)
            if total == 0:
                continue
            owned = sum(
                1 for t in territories if state.territories[t].owner == player
            )
            scores[continent] = owned / total
        return scores

    def _border_territories(self, state: GameState, owned: set[str]) -> list[str]:
        """Return owned territories that have at least one enemy neighbor."""
        mg = self._map_graph
        if mg is None:
            return []
        player = state.current_player_index
        return [
            t for t in owned
            if any(
                state.territories[n].owner != player
                for n in mg.neighbors(t)
            )
        ]

    # ------------------------------------------------------------------
    # Protocol methods
    # ------------------------------------------------------------------

    def choose_reinforcement_placement(
        self, state: GameState, armies: int
    ) -> ReinforcePlacementAction:
        """Place all armies on the most exposed border territory.

        Priority:
        1. Border territory of the highest-scoring continent.
        2. Any border territory.
        3. Random owned territory (no borders).
        """
        mg = self._map_graph
        player = state.current_player_index
        owned = {t for t, ts in state.territories.items() if ts.owner == player}

        if not owned:
            return ReinforcePlacementAction(placements={})

        # Attempt continent-aware placement
        if mg is not None:
            scores = self._continent_scores(state)
            if scores:
                # Find top continent (prefer higher bonus on score ties)
                top_continent = max(
                    scores,
                    key=lambda c: (scores[c], mg.continent_bonus(c)),
                )
                # Border territories the bot owns within that continent
                top_cont_owned = owned & mg.continent_territories(top_continent)
                cont_borders = [
                    t for t in top_cont_owned
                    if any(
                        state.territories[n].owner != player
                        for n in mg.neighbors(t)
                    )
                ]
                if cont_borders:
                    # Prefer territories that face outside the continent (cross-continent-facing)
                    cont_terrs = mg.continent_territories(top_continent)
                    external_borders = [
                        t for t in cont_borders
                        if any(
                            n not in cont_terrs
                            for n in mg.neighbors(t)
                            if state.territories[n].owner != player
                        )
                    ]
                    # Use external-facing borders if any exist, otherwise any continent border
                    final_candidates = external_borders if external_borders else cont_borders
                    target = min(final_candidates, key=lambda t: state.territories[t].armies)
                    return ReinforcePlacementAction(placements={target: armies})

            # Fallback: any border territory
            all_borders = self._border_territories(state, owned)
            if all_borders:
                target = min(all_borders, key=lambda t: state.territories[t].armies)
                return ReinforcePlacementAction(placements={target: armies})

        # Final fallback: random owned territory
        target = self._rng.choice(list(owned))
        return ReinforcePlacementAction(placements={target: armies})

    def choose_attack(self, state: GameState) -> AttackAction | None:
        """Attack with continent-aware priority ordering.

        Priority 1: Completes a continent (even slight disadvantage allowed).
        Priority 2: Target in highest-scoring continent, favorable odds.
        Priority 3: Blocks opponent from completing their continent.
        Priority 4: Any attack with favorable odds.
        """
        mg = self._map_graph
        if mg is None:
            return None

        player = state.current_player_index

        # Build all valid attack candidates
        candidates: list[tuple[str, str]] = []
        for name, ts in state.territories.items():
            if ts.owner != player or ts.armies < 2:
                continue
            for neighbor in mg.neighbors(name):
                nts = state.territories[neighbor]
                if nts.owner != player:
                    candidates.append((name, neighbor))

        if not candidates:
            return None

        scores = self._continent_scores(state)
        owned_set = {t for t, ts in state.territories.items() if ts.owner == player}

        top_continent: str | None = None
        if scores:
            top_continent = max(scores, key=lambda c: (scores[c], mg.continent_bonus(c)))

        def _makes_attack(source: str, target: str, num_dice: int) -> AttackAction:
            return AttackAction(source=source, target=target, num_dice=num_dice)

        def _num_dice(source: str) -> int:
            return min(3, state.territories[source].armies - 1)

        def _completes_continent(target: str) -> bool:
            cont = mg._continent_map.get(target)
            if cont is None:
                return False
            cont_terrs = mg.continent_territories(cont)
            # Bot would own all after taking target
            other_terrs = cont_terrs - {target}
            return all(state.territories[t].owner == player for t in other_terrs)

        def _opponent_almost_complete(target: str) -> bool:
            """True if an opponent owns all but target in target's continent."""
            cont = mg._continent_map.get(target)
            if cont is None:
                return False
            cont_terrs = mg.continent_territories(cont)
            other_terrs = cont_terrs - {target}
            if not other_terrs:
                return False
            owner_of_target = state.territories[target].owner
            return all(
                state.territories[t].owner == owner_of_target
                for t in other_terrs
            )

        # Priority 1: continent-completing attacks (allow up to 1 army disadvantage)
        for source, target in candidates:
            src_armies = state.territories[source].armies
            tgt_armies = state.territories[target].armies
            if _completes_continent(target) and src_armies >= tgt_armies:
                return _makes_attack(source, target, _num_dice(source))

        # Priority 2: favorable attack into top continent
        if top_continent is not None:
            top_cont_terrs = mg.continent_territories(top_continent)
            for source, target in candidates:
                if target in top_cont_terrs:
                    src_armies = state.territories[source].armies
                    tgt_armies = state.territories[target].armies
                    if src_armies > tgt_armies:
                        return _makes_attack(source, target, _num_dice(source))

        # Priority 3: blocking opponent continent completion
        for source, target in candidates:
            src_armies = state.territories[source].armies
            tgt_armies = state.territories[target].armies
            if _opponent_almost_complete(target) and src_armies > tgt_armies:
                return _makes_attack(source, target, _num_dice(source))

        # Priority 4: any favorable attack
        for source, target in candidates:
            src_armies = state.territories[source].armies
            tgt_armies = state.territories[target].armies
            if src_armies > tgt_armies:
                return _makes_attack(source, target, _num_dice(source))

        return None

    def choose_blitz(self, state: GameState) -> Any:
        """Not used — same as RandomAgent."""
        return None

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        """Fortify from interior to exposed border.

        Source: interior territory (all neighbors owned) with armies >= 2.
        Target: reachable border territory with fewest armies.
        """
        mg = self._map_graph
        if mg is None:
            return None

        player = state.current_player_index
        owned = {t for t, ts in state.territories.items() if ts.owner == player}

        # Interior: all neighbors are also owned by the bot
        interior = [
            t for t in owned
            if state.territories[t].armies >= 2
            and all(state.territories[n].owner == player for n in mg.neighbors(t))
        ]
        if not interior:
            return None

        borders = self._border_territories(state, owned)
        if not borders:
            return None

        # Source = interior territory with most armies
        source = max(interior, key=lambda t: state.territories[t].armies)
        armies_to_move = state.territories[source].armies - 1
        if armies_to_move < 1:
            return None

        # Reachable friendly territories from source
        reachable = mg.connected_territories(source, owned)
        reachable.discard(source)
        reachable_borders = [t for t in borders if t in reachable]
        if not reachable_borders:
            return None

        # Target = reachable border with fewest armies (most exposed)
        target = min(reachable_borders, key=lambda t: state.territories[t].armies)
        return FortifyAction(source=source, target=target, armies=armies_to_move)

    def choose_card_trade(
        self, state: GameState, cards: list[Card], forced: bool
    ) -> TradeCardsAction | None:
        """Trade any valid set if one exists — identical to RandomAgent."""
        if len(cards) < 3:
            return None
        for i in range(len(cards)):
            for j in range(i + 1, len(cards)):
                for k in range(j + 1, len(cards)):
                    if is_valid_set([cards[i], cards[j], cards[k]]):
                        return TradeCardsAction(cards=[cards[i], cards[j], cards[k]])
        return None

    def choose_advance_armies(
        self, state: GameState, source: str, target: str, min_armies: int, max_armies: int
    ) -> int:
        """Advance minimum armies into captured territory (conservative play)."""
        return min_armies

    def choose_defender_dice(
        self, state: GameState, territory: str, max_dice: int
    ) -> int:
        """Always roll max dice — same as RandomAgent."""
        return max_dice
