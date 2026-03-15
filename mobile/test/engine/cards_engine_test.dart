import 'package:risk_mobile/engine/cards_engine.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_state.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to build a minimal GameState for card tests
  GameState _makeState({
    Map<String, TerritoryState>? territories,
    List<PlayerState>? players,
    int tradeCount = 0,
    Map<String, List<Card>>? cards,
    List<Card>? deck,
  }) {
    return GameState(
      territories: territories ?? {},
      players: players ?? [
        const PlayerState(index: 0, name: 'Alice'),
        const PlayerState(index: 1, name: 'Bob'),
      ],
      tradeCount: tradeCount,
      cards: cards ?? {},
      deck: deck ?? [],
    );
  }

  group('isValidSet', () {
    test('isValidSet: 3 matching infantry → valid', () {
      final cards = [
        const Card(territory: 'A', cardType: CardType.infantry),
        const Card(territory: 'B', cardType: CardType.infantry),
        const Card(territory: 'C', cardType: CardType.infantry),
      ];
      expect(isValidSet(cards), isTrue);
    });

    test('isValidSet: one of each type → valid', () {
      final cards = [
        const Card(territory: 'A', cardType: CardType.infantry),
        const Card(territory: 'B', cardType: CardType.cavalry),
        const Card(territory: 'C', cardType: CardType.artillery),
      ];
      expect(isValidSet(cards), isTrue);
    });

    test('isValidSet: 2 matching + 1 different → invalid', () {
      final cards = [
        const Card(territory: 'A', cardType: CardType.infantry),
        const Card(territory: 'B', cardType: CardType.infantry),
        const Card(territory: 'C', cardType: CardType.cavalry),
      ];
      expect(isValidSet(cards), isFalse);
    });

    test('isValidSet: 1 wild + any 2 → valid', () {
      final cards = [
        const Card(territory: null, cardType: CardType.wild),
        const Card(territory: 'B', cardType: CardType.infantry),
        const Card(territory: 'C', cardType: CardType.infantry),
      ];
      expect(isValidSet(cards), isTrue);
    });

    test('isValidSet: 2 wilds + any 1 → valid', () {
      final cards = [
        const Card(territory: null, cardType: CardType.wild),
        const Card(territory: null, cardType: CardType.wild),
        const Card(territory: 'C', cardType: CardType.cavalry),
      ];
      expect(isValidSet(cards), isTrue);
    });

    test('isValidSet: fewer than 3 cards → invalid', () {
      final cards = [
        const Card(territory: 'A', cardType: CardType.infantry),
        const Card(territory: 'B', cardType: CardType.infantry),
      ];
      expect(isValidSet(cards), isFalse);
    });
  });

  group('createDeck', () {
    test('createDeck: 42 territory cards + 2 wild cards = 44 total', () {
      final names = List.generate(42, (i) => 'T$i');
      final deck = createDeck(names);
      expect(deck.length, 44);
      expect(deck.where((c) => c.cardType == CardType.wild).length, 2);
      expect(deck.where((c) => c.cardType != CardType.wild).length, 42);
    });

    test('createDeck: types cycle infantry/cavalry/artillery', () {
      final names = ['A', 'B', 'C', 'D'];
      final deck = createDeck(names);
      expect(deck[0].cardType, CardType.infantry);
      expect(deck[1].cardType, CardType.cavalry);
      expect(deck[2].cardType, CardType.artillery);
      expect(deck[3].cardType, CardType.infantry);
    });
  });

  group('drawCard', () {
    test('drawCard: top card moves from deck to player hand', () {
      final topCard = const Card(territory: 'A', cardType: CardType.infantry);
      final state = _makeState(
        deck: [topCard, const Card(territory: 'B', cardType: CardType.cavalry)],
      );
      final newState = drawCard(state, 0);
      expect(newState.deck.length, 1);
      expect(newState.cards['0'], [topCard]);
    });

    test('drawCard: empty deck returns state unchanged', () {
      final state = _makeState(deck: []);
      final newState = drawCard(state, 0);
      expect(newState.deck.isEmpty, isTrue);
      // Player hand entry exists even if empty
      expect(newState.cards.containsKey('0'), isTrue);
      expect(newState.cards['0'], isEmpty);
    });
  });

  group('executeTrade', () {
    test('executeTrade: removes 3 cards from hand, increments tradeCount', () {
      final hand = [
        const Card(territory: 'A', cardType: CardType.infantry),
        const Card(territory: 'B', cardType: CardType.cavalry),
        const Card(territory: 'C', cardType: CardType.artillery),
        const Card(territory: 'D', cardType: CardType.infantry),
      ];
      final state = _makeState(
        cards: {'0': hand},
        deck: [const Card(territory: 'E', cardType: CardType.cavalry)],
      );
      final (newState, bonus, _) = executeTrade(state, 0, [0, 1, 2]);
      expect(newState.cards['0']!.length, 1);
      expect(newState.cards['0']![0].territory, 'D');
      expect(newState.tradeCount, 1);
      expect(bonus, 4); // tradeCount=0 → 4
    });

    test('executeTrade: only recycles into deck when deck is empty', () {
      final hand = [
        const Card(territory: 'A', cardType: CardType.infantry),
        const Card(territory: 'B', cardType: CardType.cavalry),
        const Card(territory: 'C', cardType: CardType.artillery),
      ];
      // Non-empty deck: traded cards should NOT be recycled
      final stateWithDeck = _makeState(
        cards: {'0': hand},
        deck: [const Card(territory: 'Z', cardType: CardType.wild)],
      );
      final (newStateWithDeck, _, __) = executeTrade(stateWithDeck, 0, [0, 1, 2]);
      expect(newStateWithDeck.deck.length, 1);
      expect(newStateWithDeck.deck[0].territory, 'Z');

      // Empty deck: traded cards SHOULD be recycled
      final stateEmptyDeck = _makeState(
        cards: {'0': List.from(hand)},
        deck: [],
      );
      final (newStateEmptyDeck, _, ___) = executeTrade(stateEmptyDeck, 0, [0, 1, 2]);
      expect(newStateEmptyDeck.deck.length, 3);
    });

    test(
        'executeTrade: territory bonus adds 2 armies when player owns card territory',
        () {
      final hand = [
        const Card(territory: 'Alaska', cardType: CardType.infantry),
        const Card(territory: 'Brazil', cardType: CardType.cavalry),
        const Card(territory: 'China', cardType: CardType.artillery),
      ];
      final state = _makeState(
        territories: {
          'Alaska': const TerritoryState(owner: 0, armies: 5),
          'Brazil': const TerritoryState(owner: 1, armies: 3), // owned by player 1
          'China': const TerritoryState(owner: 0, armies: 2),
        },
        cards: {'0': hand},
        deck: [const Card(territory: 'X', cardType: CardType.infantry)],
      );
      final (_, __, territoryBonus) = executeTrade(state, 0, [0, 1, 2]);
      expect(territoryBonus['Alaska'], 2);
      expect(territoryBonus.containsKey('Brazil'), isFalse); // not owned by player 0
      expect(territoryBonus['China'], 2);
    });
  });

  group('getTradeBonus', () {
    test('getTradeBonus: sequence [4,6,8,10,12,15] for trades 0-5', () {
      expect(getTradeBonus(0), 4);
      expect(getTradeBonus(1), 6);
      expect(getTradeBonus(2), 8);
      expect(getTradeBonus(3), 10);
      expect(getTradeBonus(4), 12);
      expect(getTradeBonus(5), 15);
    });

    test('getTradeBonus: trade 6 = 20, trade 7 = 25 (continuing +5)', () {
      expect(getTradeBonus(6), 20);
      expect(getTradeBonus(7), 25);
    });
  });
}
