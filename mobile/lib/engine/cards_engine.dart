/// Card system for Risk: deck creation, set validation, trading, drawing.
/// Pure Dart port of risk/engine/cards.py.
/// Zero Flutter imports — runs in isolates and pure-Dart tests.

import 'models/game_state.dart';
import 'models/cards.dart';

/// Escalation sequence per official Hasbro rules:
/// 4, 6, 8, 10, 12, 15, then +5 for each subsequent trade.
const List<int> _escalationSequence = [4, 6, 8, 10, 12, 15];

/// Get the army bonus for the Nth trade (0-indexed).
///
/// First 6 trades follow the fixed sequence: 4, 6, 8, 10, 12, 15.
/// After that, each trade adds 5 more: 20, 25, 30, ...
int getTradeBonus(int tradeCount) {
  if (tradeCount < _escalationSequence.length) {
    return _escalationSequence[tradeCount];
  }
  return 15 + 5 * (tradeCount - _escalationSequence.length + 1);
}

/// Check if exactly 3 cards form a valid trade set.
///
/// Valid sets:
/// - 3 of the same type (infantry/cavalry/artillery)
/// - One of each type
/// - Any 2 non-wild cards + 1 wild card
/// - 2 wild cards + any 1 card
bool isValidSet(List<Card> cards) {
  if (cards.length != 3) return false;

  final wildCount = cards.where((c) => c.cardType == CardType.wild).length;

  // Any hand with 1+ wild is valid (wild substitutes for anything)
  if (wildCount >= 1) return true;

  // No wilds: check 3 matching or one-of-each
  final types = cards.map((c) => c.cardType).toSet();
  if (types.length == 1) return true; // 3 matching
  if (types.length == 3) return true; // one of each

  return false;
}

/// Create the standard Risk deck: 42 territory cards + 2 wild cards.
///
/// Territory cards cycle through infantry/cavalry/artillery.
/// The deck is returned unshuffled; caller should shuffle with their RNG.
List<Card> createDeck(List<String> territoryNames) {
  const cardTypes = [CardType.infantry, CardType.cavalry, CardType.artillery];
  final territoryCards = territoryNames.indexed
      .map((e) => Card(territory: e.$2, cardType: cardTypes[e.$1 % 3]))
      .toList();
  final wildCards = [
    const Card(territory: null, cardType: CardType.wild),
    const Card(territory: null, cardType: CardType.wild),
  ];
  return [...territoryCards, ...wildCards];
}

/// Draw the top card from the deck into a player's hand.
///
/// Returns a new GameState. If deck is empty, returns state with player's
/// hand entry initialized (even if empty).
GameState drawCard(GameState state, int playerIndex) {
  final key = playerIndex.toString();

  if (state.deck.isEmpty) {
    // Ensure the player has an entry even if deck is empty
    if (!state.cards.containsKey(key)) {
      final newCards = Map<String, List<Card>>.of(state.cards);
      newCards[key] = [];
      return state.copyWith(cards: newCards);
    }
    return state;
  }

  final newDeck = List<Card>.of(state.deck);
  final drawn = newDeck.removeAt(0);

  final newCards = Map<String, List<Card>>.of(state.cards);
  newCards[key] = [...(newCards[key] ?? []), drawn];

  return state.copyWith(deck: newDeck, cards: newCards);
}

/// Execute a card trade for a player.
///
/// Args:
///   state: Current game state.
///   playerIndex: Index of the trading player.
///   cardIndices: Indices into the player's hand (exactly 3).
///
/// Returns:
///   Record of (newState, bonusArmies, territoryBonusPlacements).
///   territoryBonusPlacements maps territory name -> 2 for each traded card
///   whose territory is owned by the player.
///
/// Throws:
///   ArgumentError if the selected cards don't form a valid set.
(GameState, int, Map<String, int>) executeTrade(
  GameState state,
  int playerIndex,
  List<int> cardIndices,
) {
  final key = playerIndex.toString();
  final hand = List<Card>.of(state.cards[key] ?? []);
  final sortedIndices = List<int>.of(cardIndices)..sort();
  final selected = sortedIndices.map((i) => hand[i]).toList();

  if (!isValidSet(selected)) {
    throw ArgumentError('Selected cards do not form a valid set');
  }

  // Calculate bonus armies from escalation
  final bonus = getTradeBonus(state.tradeCount);

  // Calculate territory bonuses (2 extra armies on owned territory shown on card)
  final territoryBonus = <String, int>{};
  for (final card in selected) {
    if (card.territory != null &&
        state.territories.containsKey(card.territory) &&
        state.territories[card.territory]!.owner == playerIndex) {
      territoryBonus[card.territory!] = 2;
    }
  }

  // Remove traded cards from hand (remove in reverse index order)
  final newHand = List<Card>.of(hand);
  final reverseSorted = List<int>.of(cardIndices)..sort((a, b) => b - a);
  for (final i in reverseSorted) {
    newHand.removeAt(i);
  }

  final newCards = Map<String, List<Card>>.of(state.cards);
  newCards[key] = newHand;

  // Recycle traded cards back into the deck only when deck is empty
  // (prevents unbounded army growth while ensuring cards don't permanently run out)
  final newDeck = state.deck.isEmpty ? List<Card>.of(selected) : List<Card>.of(state.deck);

  final newState = state.copyWith(
    cards: newCards,
    deck: newDeck,
    tradeCount: state.tradeCount + 1,
  );

  return (newState, bonus, territoryBonus);
}
