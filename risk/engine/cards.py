"""Card system for Risk: deck creation, set validation, trading, drawing."""

from risk.models.cards import Card, CardType
from risk.models.game_state import GameState


# Escalation sequence per official Hasbro rules:
# 4, 6, 8, 10, 12, 15, then +5 for each subsequent trade
ESCALATION_SEQUENCE = [4, 6, 8, 10, 12, 15]


def get_trade_bonus(trade_count: int) -> int:
    """Get the army bonus for the Nth trade (0-indexed).

    First 6 trades follow the fixed sequence: 4, 6, 8, 10, 12, 15.
    After that, each trade adds 5 more: 20, 25, 30, ...
    """
    if trade_count < len(ESCALATION_SEQUENCE):
        return ESCALATION_SEQUENCE[trade_count]
    return 15 + 5 * (trade_count - len(ESCALATION_SEQUENCE) + 1)


def is_valid_set(cards: list[Card]) -> bool:
    """Check if exactly 3 cards form a valid trade set.

    Valid sets:
    - 3 of the same type (infantry/cavalry/artillery)
    - One of each type
    - Any 2 non-wild cards + 1 wild card
    - 2 wild cards + any 1 card
    """
    if len(cards) != 3:
        return False

    wild_count = sum(1 for c in cards if c.card_type == CardType.WILD)
    non_wild = [c for c in cards if c.card_type != CardType.WILD]

    # Any hand with 1+ wild is valid (wild substitutes for anything)
    if wild_count >= 1:
        return True

    # No wilds: check 3 matching or one-of-each
    types = {c.card_type for c in non_wild}
    if len(types) == 1:
        return True  # 3 matching
    if len(types) == 3:
        return True  # one of each

    return False


def create_deck(territory_names: list[str]) -> list[Card]:
    """Create the standard Risk deck: 42 territory cards + 2 wild cards.

    Territory cards cycle through INFANTRY, CAVALRY, ARTILLERY.
    The deck is returned unshuffled; caller should shuffle with their RNG.
    """
    card_types = [CardType.INFANTRY, CardType.CAVALRY, CardType.ARTILLERY]
    territory_cards = [
        Card(territory=name, card_type=card_types[i % 3])
        for i, name in enumerate(territory_names)
    ]
    wild_cards = [
        Card(territory=None, card_type=CardType.WILD),
        Card(territory=None, card_type=CardType.WILD),
    ]
    return territory_cards + wild_cards


def draw_card(state: GameState, player_index: int) -> GameState:
    """Draw the top card from the deck into a player's hand.

    Returns a new GameState. If deck is empty, returns state unchanged.
    """
    if not state.deck:
        # Ensure the player has an entry even if deck is empty
        if player_index not in state.cards:
            new_cards = dict(state.cards)
            new_cards[player_index] = []
            return state.model_copy(update={"cards": new_cards})
        return state

    new_deck = list(state.deck)
    drawn = new_deck.pop(0)

    new_cards = {k: list(v) for k, v in state.cards.items()}
    if player_index not in new_cards:
        new_cards[player_index] = []
    new_cards[player_index].append(drawn)

    return state.model_copy(update={"deck": new_deck, "cards": new_cards})


def execute_trade(
    state: GameState,
    player_index: int,
    card_indices: list[int],
) -> tuple[GameState, int, dict[str, int]]:
    """Execute a card trade for a player.

    Args:
        state: Current game state.
        player_index: Index of the trading player.
        card_indices: Indices into the player's hand (exactly 3).

    Returns:
        Tuple of (new_state, bonus_armies, territory_bonus_placements).
        territory_bonus_placements maps territory name -> 2 for each traded card
        whose territory is owned by the player.

    Raises:
        ValueError: If the selected cards don't form a valid set.
    """
    hand = list(state.cards.get(player_index, []))
    selected = [hand[i] for i in sorted(card_indices)]

    if not is_valid_set(selected):
        raise ValueError("Selected cards do not form a valid set")

    # Calculate bonus armies from escalation
    bonus = get_trade_bonus(state.trade_count)

    # Calculate territory bonuses (2 extra armies on owned territory shown on card)
    territory_bonus: dict[str, int] = {}
    for card in selected:
        if (
            card.territory is not None
            and card.territory in state.territories
            and state.territories[card.territory].owner == player_index
        ):
            territory_bonus[card.territory] = 2

    # Remove traded cards from hand (remove in reverse index order)
    new_hand = list(hand)
    for i in sorted(card_indices, reverse=True):
        new_hand.pop(i)

    new_cards = {k: list(v) for k, v in state.cards.items()}
    new_cards[player_index] = new_hand

    new_state = state.model_copy(
        update={
            "cards": new_cards,
            "trade_count": state.trade_count + 1,
        }
    )

    return new_state, bonus, territory_bonus
