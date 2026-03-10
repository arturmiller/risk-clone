"""HardAgent: human-competitive bot for Risk using multi-factor heuristic scoring.

Uses border security ratio, continent progress, opponent threat assessment,
probability-based attack decisions, strategic card timing, and context-aware
army advancement to play at human-competitive level.
"""

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


# Precomputed attack probabilities from exact dice math (ties go to defender).
# Key: (attacker_dice, defender_dice) -> tuple of probabilities.
# For 2-die comparisons: (p_attacker_wins_both, p_defender_wins_both, p_split)
# For 1-die comparisons: (p_attacker_wins, p_defender_wins)
ATTACK_PROBABILITIES: dict[tuple[int, int], tuple[float, ...]] = {
    (1, 1): (0.4167, 0.5833),
    (2, 1): (0.5787, 0.4213),
    (3, 1): (0.6597, 0.3403),
    (1, 2): (0.2546, 0.7454),
    (2, 2): (0.2276, 0.4483, 0.3241),
    (3, 2): (0.3717, 0.2926, 0.3358),
}

# Tunable weights for the scoring function
CONTINENT_PROGRESS_WEIGHT = 3.0
BORDER_SECURITY_WEIGHT = 2.0
THREAT_WEIGHT = 1.5
CARD_TIMING_THRESHOLD = 4
ATTACK_PROBABILITY_THRESHOLD = 0.6


def _estimate_win_probability(attacker_armies: int, defender_armies: int) -> float:
    """Estimate probability of attacker winning the territory.

    Uses a geometric approximation from per-roll probabilities. Simulates
    expected army losses per round to estimate overall win chance.
    """
    att = attacker_armies - 1  # armies that can attack (leave 1 behind)
    dfd = defender_armies

    if att <= 0 or dfd <= 0:
        return 0.0 if att <= 0 else 1.0

    # Simulate expected outcome over rounds
    a, d = float(att), float(dfd)
    for _ in range(50):  # max iterations
        if a <= 0:
            return 0.0
        if d <= 0:
            return 1.0

        att_dice = min(3, max(1, int(a)))
        def_dice = min(2, max(1, int(d)))
        key = (att_dice, def_dice)
        probs = ATTACK_PROBABILITIES[key]

        if len(probs) == 2:
            # Single comparison: attacker wins or defender wins
            p_att_win = probs[0]
            a -= (1 - p_att_win)
            d -= p_att_win
        else:
            # Two comparisons: (both_att_win, both_def_win, split)
            p_both_att = probs[0]
            p_both_def = probs[1]
            p_split = probs[2]
            a -= 2 * p_both_def + p_split
            d -= 2 * p_both_att + p_split

    # If we exhausted iterations, estimate from remaining
    if d <= 0:
        return 1.0
    if a <= 0:
        return 0.0
    return a / (a + d)


class HardAgent:
    """Human-competitive Risk bot using multi-factor heuristic scoring.

    Implements the PlayerAgent protocol. Map graph is injected after construction
    via agent._map_graph = map_graph (same pattern as MediumAgent).

    Strategy overview:
    - Reinforce: Concentrate all armies on 1-2 most vulnerable border territories
    - Attack: Multi-priority (continent-complete > block-opponent > high-value > favorable-odds)
    - Cards: Hold until 4 in hand or high escalation, trade best set
    - Advance: More into exposed territories, all-but-1 from interior
    - Fortify: Interior to most vulnerable border via connected path
    """

    def __init__(self, rng: _random.Random | None = None) -> None:
        self._rng = rng or _random.Random()
        self._map_graph: MapGraph | None = None

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _border_security_ratio(self, state: GameState, territory: str) -> float:
        """Calculate BSR: sum(enemy_adjacent_armies) / own_armies.

        Higher BSR = more vulnerable. BSR > 1.0 means territory is at risk.
        """
        mg = self._map_graph
        if mg is None:
            return 0.0
        own_armies = state.territories[territory].armies
        player = state.territories[territory].owner
        enemy_adjacent = sum(
            state.territories[n].armies
            for n in mg.neighbors(territory)
            if state.territories[n].owner != player
        )
        return enemy_adjacent / max(own_armies, 1)

    def _opponent_threat_scores(self, state: GameState) -> dict[int, float]:
        """Score each opponent by how threatening they are.

        Factors: total armies, continent control progress (near-complete continents).
        """
        mg = self._map_graph
        if mg is None:
            return {}
        player = state.current_player_index
        threats: dict[int, float] = {}

        for p in state.players:
            if p.index == player or not p.is_alive:
                continue

            # Factor 1: Total army count
            total = sum(
                ts.armies for ts in state.territories.values() if ts.owner == p.index
            )

            # Factor 2: Continent control (nearly complete continents are threatening)
            continent_threat = 0.0
            for cont_name, cont_terrs in mg._continent_territories.items():
                owned = sum(1 for t in cont_terrs if state.territories[t].owner == p.index)
                if owned >= len(cont_terrs) - 1:  # Missing only 1 territory
                    continent_threat += mg.continent_bonus(cont_name) * 2
                elif owned >= len(cont_terrs) * 0.7:
                    continent_threat += mg.continent_bonus(cont_name)

            threats[p.index] = total * 0.5 + continent_threat * THREAT_WEIGHT

        return threats

    def _continent_scores(self, state: GameState) -> dict[str, float]:
        """Score each continent by fraction owned, with exponential boost >50%."""
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
            fraction = owned / total
            score = fraction * mg.continent_bonus(continent) * CONTINENT_PROGRESS_WEIGHT
            # Exponential boost for continents >50% complete
            if fraction > 0.5:
                score *= 1.5
            scores[continent] = score
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

    def _is_interior(self, state: GameState, territory: str) -> bool:
        """True if all neighbors are owned by the same player."""
        mg = self._map_graph
        if mg is None:
            return False
        owner = state.territories[territory].owner
        return all(
            state.territories[n].owner == owner
            for n in mg.neighbors(territory)
        )

    def _best_trade(self, state: GameState, cards: list[Card]) -> TradeCardsAction | None:
        """Find best valid trade set, preferring territory bonus matches."""
        player = state.current_player_index
        owned = {t for t, ts in state.territories.items() if ts.owner == player}

        best_set: list[Card] | None = None
        best_bonus = -1

        for i in range(len(cards)):
            for j in range(i + 1, len(cards)):
                for k in range(j + 1, len(cards)):
                    candidate = [cards[i], cards[j], cards[k]]
                    if is_valid_set(candidate):
                        # Count territory bonus matches
                        bonus = sum(
                            1 for c in candidate
                            if c.territory is not None and c.territory in owned
                        )
                        if bonus > best_bonus:
                            best_bonus = bonus
                            best_set = candidate

        if best_set is None:
            return None
        return TradeCardsAction(cards=best_set)

    # ------------------------------------------------------------------
    # Protocol methods
    # ------------------------------------------------------------------

    def choose_reinforcement_placement(
        self, state: GameState, armies: int
    ) -> ReinforcePlacementAction:
        """Concentrate ALL armies on 1-2 most vulnerable border territories.

        Priority: highest BSR, preferring territories in highest-scoring continent.
        """
        mg = self._map_graph
        player = state.current_player_index
        owned = {t for t, ts in state.territories.items() if ts.owner == player}

        if not owned:
            return ReinforcePlacementAction(placements={})

        if mg is None:
            # Fallback: random owned territory
            target = self._rng.choice(list(owned))
            return ReinforcePlacementAction(placements={target: armies})

        borders = self._border_territories(state, owned)
        if not borders:
            # No border territories (shouldn't happen in a real game)
            target = self._rng.choice(list(owned))
            return ReinforcePlacementAction(placements={target: armies})

        # Score each border territory: BSR + continent priority bonus
        cont_scores = self._continent_scores(state)

        def _placement_score(t: str) -> float:
            bsr = self._border_security_ratio(state, t)
            # Add continent score bonus for the territory's continent
            cont = mg._continent_map.get(t, "")
            cont_bonus = cont_scores.get(cont, 0.0)
            return bsr * BORDER_SECURITY_WEIGHT + cont_bonus

        # Sort borders by score (most vulnerable + best continent first)
        ranked = sorted(borders, key=_placement_score, reverse=True)

        # Concentrate on top 1-2 territories
        if len(ranked) == 1 or armies <= 3:
            return ReinforcePlacementAction(placements={ranked[0]: armies})
        else:
            # Split: 2/3 on most vulnerable, 1/3 on second
            primary = max(1, armies * 2 // 3)
            secondary = armies - primary
            placements = {ranked[0]: primary}
            if secondary > 0:
                placements[ranked[1]] = secondary
            return ReinforcePlacementAction(placements=placements)

    def choose_attack(self, state: GameState) -> AttackAction | None:
        """Multi-priority attack selection.

        Priority ordering:
        1. Continent-completing attacks (even at slight disadvantage)
        2. Block opponent from completing their continent
        3. High-value attacks with >= 60% win probability
        4. Favorable odds attacks

        Stops when armies are too low or no good attacks remain.
        """
        mg = self._map_graph
        if mg is None:
            return None

        player = state.current_player_index
        owned = {t for t, ts in state.territories.items() if ts.owner == player}

        # Check if armies are too thin to attack: stop if no territory has
        # enough armies to mount a reasonable attack (need at least 3 to attack
        # with 2 dice, and should have army advantage)
        has_viable_attack = False
        for name, ts in state.territories.items():
            if ts.owner != player or ts.armies < 3:
                continue
            for neighbor in mg.neighbors(name):
                nts = state.territories[neighbor]
                if nts.owner != player and ts.armies > nts.armies:
                    has_viable_attack = True
                    break
            if has_viable_attack:
                break
        if not has_viable_attack:
            return None

        # Build all valid attack candidates
        candidates: list[tuple[str, str]] = []
        for name, ts in state.territories.items():
            if ts.owner != player or ts.armies < 2:
                continue
            for neighbor in mg.neighbors(name):
                if state.territories[neighbor].owner != player:
                    candidates.append((name, neighbor))

        if not candidates:
            return None

        threat_scores = self._opponent_threat_scores(state)
        cont_scores = self._continent_scores(state)

        def _num_dice(source: str) -> int:
            return min(3, state.territories[source].armies - 1)

        def _completes_continent(target: str) -> bool:
            cont = mg._continent_map.get(target)
            if cont is None:
                return False
            cont_terrs = mg.continent_territories(cont)
            other_terrs = cont_terrs - {target}
            return all(state.territories[t].owner == player for t in other_terrs)

        def _blocks_opponent_continent(target: str) -> bool:
            """True if taking this target prevents an opponent from completing a continent.

            An opponent nearly controls a continent if they own all territories
            in it except 1-2, and one of those missing territories belongs to us.
            Attacking one of their territories in that continent disrupts control.
            """
            target_owner = state.territories[target].owner
            if target_owner == player:
                return False
            cont = mg._continent_map.get(target)
            if cont is None:
                return False
            cont_terrs = mg.continent_territories(cont)
            # Count how many of this continent the target's owner has
            opponent_owned = sum(
                1 for t in cont_terrs
                if state.territories[t].owner == target_owner
            )
            # Opponent nearly controls this continent (owns all but 1-2)
            return opponent_owned >= len(cont_terrs) - 2 and opponent_owned >= len(cont_terrs) * 0.5

        # Priority 1: Continent-completing attacks (allow even match)
        for source, target in candidates:
            src = state.territories[source].armies
            tgt = state.territories[target].armies
            if _completes_continent(target) and src >= tgt:
                return AttackAction(source=source, target=target, num_dice=_num_dice(source))

        # Priority 2: Block opponent continent completion
        # Sort by opponent threat to prioritize blocking most dangerous opponent
        block_candidates = [
            (s, t) for s, t in candidates if _blocks_opponent_continent(t)
        ]
        # Sort by threat score of the target's owner (descending)
        block_candidates.sort(
            key=lambda x: threat_scores.get(state.territories[x[1]].owner, 0),
            reverse=True,
        )
        for source, target in block_candidates:
            src = state.territories[source].armies
            tgt = state.territories[target].armies
            if src > tgt:
                return AttackAction(source=source, target=target, num_dice=_num_dice(source))

        # Priority 3: High-value attacks with good probability
        scored_attacks: list[tuple[float, str, str]] = []
        for source, target in candidates:
            src_armies = state.territories[source].armies
            tgt_armies = state.territories[target].armies
            win_prob = _estimate_win_probability(src_armies, tgt_armies)
            if win_prob < ATTACK_PROBABILITY_THRESHOLD:
                continue

            # Score by continent value + probability
            cont = mg._continent_map.get(target, "")
            cont_value = cont_scores.get(cont, 0.0)
            score = win_prob * 2.0 + cont_value
            scored_attacks.append((score, source, target))

        if scored_attacks:
            scored_attacks.sort(reverse=True)
            _, source, target = scored_attacks[0]
            return AttackAction(source=source, target=target, num_dice=_num_dice(source))

        # Priority 4: Any attack with overwhelming force (3:1 ratio)
        for source, target in candidates:
            src = state.territories[source].armies
            tgt = state.territories[target].armies
            if src >= 3 * tgt and src >= 4:
                return AttackAction(source=source, target=target, num_dice=_num_dice(source))

        return None

    def choose_blitz(self, state: GameState) -> Any:
        """Not used -- regular attacks for granular control."""
        return None

    def choose_fortify(self, state: GameState) -> FortifyAction | None:
        """Move armies from interior (highest armies) to most vulnerable border.

        Uses connected path through friendly territory.
        """
        mg = self._map_graph
        if mg is None:
            return None

        player = state.current_player_index
        owned = {t for t, ts in state.territories.items() if ts.owner == player}

        # Interior: all neighbors owned, armies >= 2
        interior = [
            t for t in owned
            if state.territories[t].armies >= 2
            and self._is_interior(state, t)
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

        # Find reachable borders
        reachable = mg.connected_territories(source, owned)
        reachable.discard(source)
        reachable_borders = [t for t in borders if t in reachable]
        if not reachable_borders:
            return None

        # Target = reachable border with highest BSR (most vulnerable)
        target = max(
            reachable_borders,
            key=lambda t: self._border_security_ratio(state, t),
        )
        return FortifyAction(source=source, target=target, armies=armies_to_move)

    def choose_card_trade(
        self, state: GameState, cards: list[Card], forced: bool
    ) -> TradeCardsAction | None:
        """Strategic card timing: hold until 4 cards or high escalation.

        - Forced: always trade best set
        - 4+ cards: trade (5 would be forced anyway)
        - High escalation (trade_count >= 4, meaning 10+ armies): trade for value
        - Otherwise: hold cards
        """
        if forced:
            return self._best_trade(state, cards)

        if len(cards) < 3:
            return None

        # Hold until 4 cards or high escalation
        if len(cards) >= CARD_TIMING_THRESHOLD or state.trade_count >= 4:
            return self._best_trade(state, cards)

        return None

    def choose_advance_armies(
        self, state: GameState, source: str, target: str, min_armies: int, max_armies: int
    ) -> int:
        """Context-aware army advancement after conquest.

        - Source is interior (no enemy neighbors): advance all (max_armies)
        - Target borders many enemies: advance more
        - Both border enemies: split proportionally
        """
        mg = self._map_graph
        if mg is None:
            return min_armies

        player = state.current_player_index
        source_is_interior = self._is_interior(state, source)

        # If source is interior, advance all armies
        if source_is_interior:
            return max_armies

        # Count enemy neighbors for target
        target_enemy_neighbors = sum(
            1 for n in mg.neighbors(target)
            if n != source and state.territories[n].owner != player
        )

        # Count enemy neighbors for source
        source_enemy_neighbors = sum(
            1 for n in mg.neighbors(source)
            if n != target and state.territories[n].owner != player
        )

        if target_enemy_neighbors == 0 and source_enemy_neighbors > 0:
            # Target is safe, keep armies on exposed source
            return min_armies

        if source_enemy_neighbors == 0:
            # Source has no enemies (except through target), advance more
            return max_armies

        # Both border enemies: split proportionally to exposure
        total_exposure = target_enemy_neighbors + source_enemy_neighbors
        if total_exposure == 0:
            return max(min_armies, max_armies // 2)

        target_ratio = target_enemy_neighbors / total_exposure
        advance = max(min_armies, int(max_armies * target_ratio))
        return min(advance, max_armies)

    def choose_defender_dice(
        self, state: GameState, territory: str, max_dice: int
    ) -> int:
        """Always roll max dice."""
        return max_dice
