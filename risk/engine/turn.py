"""Turn execution engine: phase transitions, elimination, victory detection."""

import random as _random

from risk.engine.cards import draw_card, execute_trade, is_valid_set
from risk.engine.combat import execute_attack
from risk.engine.fortify import execute_fortify
from risk.engine.map_graph import MapGraph
from risk.engine.reinforcements import calculate_reinforcements
from risk.models.actions import AttackAction, TradeCardsAction
from risk.models.cards import Card, TurnPhase
from risk.models.game_state import GameState, PlayerState, TerritoryState


def check_victory(state: GameState) -> int | None:
    """Return winning player index if one player owns all territories, else None."""
    owners = {ts.owner for ts in state.territories.values()}
    if len(owners) == 1:
        owner = next(iter(owners))
        # Verify the player is alive
        if state.players[owner].is_alive:
            return owner
    return None


def check_elimination(state: GameState, player_index: int) -> bool:
    """Return True if the player owns zero territories."""
    for ts in state.territories.values():
        if ts.owner == player_index:
            return False
    return True


def transfer_cards(
    state: GameState, from_player: int, to_player: int
) -> GameState:
    """Move all cards from one player to another. Returns new state."""
    new_cards = {k: list(v) for k, v in state.cards.items()}
    transferred = list(new_cards.get(from_player, []))
    new_cards[from_player] = []

    if to_player not in new_cards:
        new_cards[to_player] = []
    new_cards[to_player] = list(new_cards[to_player]) + transferred

    return state.model_copy(update={"cards": new_cards})


def _find_valid_set_indices(cards: list[Card]) -> list[int] | None:
    """Find the first valid 3-card set in a hand. Returns indices or None."""
    n = len(cards)
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                if is_valid_set([cards[i], cards[j], cards[k]]):
                    return [i, j, k]
    return None


def force_trade_loop(
    state: GameState,
    player_index: int,
    agent: object,
) -> tuple[GameState, int]:
    """Force trades while player has 5+ cards. Returns (state, total_bonus)."""
    total_bonus = 0

    while len(state.cards.get(player_index, [])) >= 5:
        hand = state.cards[player_index]
        trade_action = agent.choose_card_trade(state, hand, forced=True)  # type: ignore[union-attr]

        if trade_action is None:
            # Agent must trade when forced -- find a valid set automatically
            indices = _find_valid_set_indices(hand)
            if indices is None:
                break  # No valid set possible (shouldn't happen with 5+ cards)
            card_indices = indices
        else:
            # Map the TradeCardsAction cards back to hand indices
            card_indices = _cards_to_indices(hand, trade_action.cards)

        state, bonus, territory_bonus = execute_trade(
            state, player_index, card_indices
        )
        total_bonus += bonus

        # Apply territory bonus placements
        state = _apply_territory_bonus(state, territory_bonus)

    return state, total_bonus


def _cards_to_indices(hand: list[Card], selected: list[Card]) -> list[int]:
    """Map selected cards back to their indices in the hand."""
    indices = []
    used = set()
    for card in selected:
        for i, h in enumerate(hand):
            if i not in used and h == card:
                indices.append(i)
                used.add(i)
                break
    return sorted(indices)


def _apply_territory_bonus(
    state: GameState, territory_bonus: dict[str, int]
) -> GameState:
    """Apply territory bonus armies from card trading."""
    if not territory_bonus:
        return state
    new_territories = dict(state.territories)
    for territory, bonus in territory_bonus.items():
        ts = new_territories[territory]
        new_territories[territory] = TerritoryState(
            owner=ts.owner, armies=ts.armies + bonus
        )
    return state.model_copy(update={"territories": new_territories})


def execute_reinforce_phase(
    state: GameState,
    map_graph: MapGraph,
    agent: object,
    player_index: int,
) -> GameState:
    """Execute the reinforcement phase for a player.

    1. Force card trades if player has 5+ cards
    2. Calculate reinforcements (base + continent + trade bonus)
    3. Apply territory bonuses from trades
    4. Agent places remaining armies
    5. Transition to ATTACK phase
    """
    trade_bonus = 0

    # Step 1: Forced card trade if 5+ cards
    if len(state.cards.get(player_index, [])) >= 5:
        state, trade_bonus = force_trade_loop(state, player_index, agent)

    # Step 2: Calculate base reinforcements
    base = calculate_reinforcements(state, map_graph, player_index)
    total_armies = base + trade_bonus

    # Step 3: Optional voluntary trade (if has valid set and < 5 cards)
    hand = state.cards.get(player_index, [])
    if len(hand) >= 3 and _find_valid_set_indices(hand) is not None:
        trade_action = agent.choose_card_trade(state, hand, forced=False)  # type: ignore[union-attr]
        if trade_action is not None:
            card_indices = _cards_to_indices(hand, trade_action.cards)
            state, bonus, territory_bonus = execute_trade(
                state, player_index, card_indices
            )
            total_armies += bonus
            state = _apply_territory_bonus(state, territory_bonus)

    # Step 4: Agent places armies
    placement = agent.choose_reinforcement_placement(state, total_armies)  # type: ignore[union-attr]

    # Validate placements
    placed = sum(placement.placements.values())
    if placed != total_armies:
        raise ValueError(
            f"Must place exactly {total_armies} armies, got {placed}"
        )

    # Apply placements
    new_territories = dict(state.territories)
    for territory, armies in placement.placements.items():
        ts = new_territories[territory]
        if ts.owner != player_index:
            raise ValueError(
                f"Cannot place armies on '{territory}' -- not owned by player {player_index}"
            )
        new_territories[territory] = TerritoryState(
            owner=ts.owner, armies=ts.armies + armies
        )

    state = state.model_copy(
        update={"territories": new_territories, "turn_phase": TurnPhase.ATTACK}
    )
    return state


def execute_attack_phase(
    state: GameState,
    map_graph: MapGraph,
    agent: object,
    player_index: int,
    rng: _random.Random,
) -> tuple[GameState, bool]:
    """Execute the attack phase. Returns (state, victory_achieved)."""
    while True:
        action = agent.choose_attack(state)  # type: ignore[union-attr]
        if action is None:
            break

        state, _result, conquered = execute_attack(
            state, map_graph, action, player_index, rng
        )

        if conquered:
            state = state.model_copy(update={"conquered_this_turn": True})

            # Check if defender was eliminated
            target_prev_owner = None
            # We need to figure out who used to own the target
            # The target now belongs to the attacker; find who lost it
            # We can check which player lost territories
            for p in state.players:
                if p.index == player_index:
                    continue
                if p.is_alive and check_elimination(state, p.index):
                    target_prev_owner = p.index
                    break

            if target_prev_owner is not None:
                # Mark eliminated player as dead
                new_players = list(state.players)
                new_players[target_prev_owner] = PlayerState(
                    index=target_prev_owner,
                    name=state.players[target_prev_owner].name,
                    is_alive=False,
                )
                state = state.model_copy(update={"players": new_players})

                # Transfer cards
                state = transfer_cards(
                    state, from_player=target_prev_owner, to_player=player_index
                )

                # Forced trade if 5+ cards after transfer
                if len(state.cards.get(player_index, [])) >= 5:
                    state, _bonus = force_trade_loop(
                        state, player_index, agent
                    )

                # Check victory
                if check_victory(state) is not None:
                    return state, True

    # End of attack phase: draw card if conquered this turn
    if state.conquered_this_turn:
        state = draw_card(state, player_index)

    state = state.model_copy(update={"turn_phase": TurnPhase.FORTIFY})
    return state, False


def execute_fortify_phase(
    state: GameState,
    map_graph: MapGraph,
    agent: object,
    player_index: int,
) -> GameState:
    """Execute the fortify phase."""
    action = agent.choose_fortify(state)  # type: ignore[union-attr]
    if action is not None:
        state = execute_fortify(state, map_graph, action, player_index)
    return state


def _next_alive_player(state: GameState) -> int:
    """Find the next alive player after current_player_index."""
    num_players = len(state.players)
    idx = state.current_player_index
    for _ in range(num_players):
        idx = (idx + 1) % num_players
        if state.players[idx].is_alive:
            return idx
    # Should not reach here if game is not over
    return state.current_player_index


def execute_turn(
    state: GameState,
    map_graph: MapGraph,
    agents: dict[int, object],
    rng: _random.Random,
) -> tuple[GameState, bool]:
    """Execute a full turn for the current player.

    Runs REINFORCE -> ATTACK -> FORTIFY, then advances to next alive player.
    Returns (new_state, victory_achieved).
    """
    player_index = state.current_player_index
    agent = agents[player_index]

    # Reset turn state
    state = state.model_copy(
        update={
            "conquered_this_turn": False,
            "turn_phase": TurnPhase.REINFORCE,
        }
    )

    # Phase 1: Reinforce
    state = execute_reinforce_phase(state, map_graph, agent, player_index)

    # Phase 2: Attack
    state, victory = execute_attack_phase(
        state, map_graph, agent, player_index, rng
    )
    if victory:
        return state, True

    # Phase 3: Fortify
    state = execute_fortify_phase(state, map_graph, agent, player_index)

    # Advance to next alive player
    next_player = _next_alive_player(state)
    state = state.model_copy(
        update={
            "current_player_index": next_player,
            "turn_number": state.turn_number + 1,
        }
    )

    return state, False
