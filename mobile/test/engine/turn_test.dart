import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/turn.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/actions.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/bots/player_agent.dart';

/// A simple fake random that always returns values deterministically.
/// Returns [value % max] for nextInt.
class FakeRandom implements Random {
  int _callCount = 0;
  final int returnValue; // nextInt(max) returns min(returnValue, max-1)

  FakeRandom({this.returnValue = 6}); // defaults to high roll (attacker wins)

  @override
  int nextInt(int max) {
    _callCount++;
    return returnValue < max ? returnValue : max - 1;
  }

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;
}

/// A configurable fake PlayerAgent for testing.
class FakePlayerAgent extends PlayerAgent {
  AttackChoice? Function(GameState)? attackFn;
  FortifyAction? Function(GameState)? fortifyFn;
  TradeCardsAction? Function(GameState, List<Card>, bool)? cardTradeFn;
  int Function(GameState, String, String, int, int)? advanceFn;
  ReinforcePlacementAction Function(GameState, int)? reinforceFn;

  FakePlayerAgent({
    this.attackFn,
    this.fortifyFn,
    this.cardTradeFn,
    this.advanceFn,
    this.reinforceFn,
  });

  @override
  AttackChoice? chooseAttack(GameState state) =>
      attackFn?.call(state);

  @override
  FortifyAction? chooseFortify(GameState state) =>
      fortifyFn?.call(state);

  @override
  TradeCardsAction? chooseCardTrade(GameState state, List<Card> hand,
          {required bool forced}) =>
      cardTradeFn?.call(state, hand, forced);

  @override
  int chooseAdvanceArmies(GameState state, String source, String target,
          int min, int max) =>
      advanceFn?.call(state, source, target, min, max) ?? min;

  @override
  ReinforcePlacementAction chooseReinforcementPlacement(
          GameState state, int armies) =>
      reinforceFn?.call(state, armies) ??
      ReinforcePlacementAction(placements: {});
}

/// Build a minimal 2-player MapGraph with 4 territories.
/// A-B are adjacent, C-D are adjacent; AB vs CD owned by each player.
/// A-C are also adjacent so player 0 can attack player 1.
MapGraph buildTestMap() {
  final mapData = MapData(
    name: 'Test',
    territories: ['A', 'B', 'C', 'D'],
    adjacencies: [
      ['A', 'B'],
      ['C', 'D'],
      ['A', 'C'], // cross-player adjacency
    ],
    continents: [
      ContinentData(name: 'North', territories: ['A', 'B'], bonus: 2),
      ContinentData(name: 'South', territories: ['C', 'D'], bonus: 2),
    ],
  );
  return MapGraph(mapData);
}

/// Build a minimal GameState for 2-player testing.
GameState buildTestState({
  int currentPlayer = 0,
  Map<String, TerritoryState>? territories,
  List<PlayerState>? players,
  Map<String, List<Card>>? cards,
  List<Card>? deck,
  bool conqueredThisTurn = false,
  int turnNumber = 0,
}) {
  return GameState(
    territories: territories ??
        {
          'A': TerritoryState(owner: 0, armies: 5),
          'B': TerritoryState(owner: 0, armies: 3),
          'C': TerritoryState(owner: 1, armies: 1),
          'D': TerritoryState(owner: 1, armies: 2),
        },
    players: players ??
        [
          PlayerState(index: 0, name: 'Player 0'),
          PlayerState(index: 1, name: 'Player 1'),
        ],
    currentPlayerIndex: currentPlayer,
    cards: cards ?? {},
    deck: deck ?? [],
    conqueredThisTurn: conqueredThisTurn,
    turnNumber: turnNumber,
  );
}

void main() {
  group('checkVictory', () {
    test(
      'checkVictory: single owner with all territories returns player index',
      () {
        final state = buildTestState(
          territories: {
            'A': TerritoryState(owner: 0, armies: 5),
            'B': TerritoryState(owner: 0, armies: 3),
            'C': TerritoryState(owner: 0, armies: 2),
            'D': TerritoryState(owner: 0, armies: 1),
          },
        );
        expect(checkVictory(state), equals(0));
      },
    );

    test(
      'checkVictory: multiple owners returns null',
      () {
        final state = buildTestState();
        expect(checkVictory(state), isNull);
      },
    );
  });

  group('checkElimination', () {
    test(
      'checkElimination: player with zero territories returns true',
      () {
        // All territories owned by player 0
        final state = buildTestState(
          territories: {
            'A': TerritoryState(owner: 0, armies: 5),
            'B': TerritoryState(owner: 0, armies: 3),
            'C': TerritoryState(owner: 0, armies: 2),
            'D': TerritoryState(owner: 0, armies: 1),
          },
        );
        expect(checkElimination(state, 1), isTrue);
      },
    );

    test(
      'checkElimination: player with territories returns false',
      () {
        final state = buildTestState();
        expect(checkElimination(state, 0), isFalse);
        expect(checkElimination(state, 1), isFalse);
      },
    );
  });

  group('transferCards', () {
    test(
      'transferCards: all cards move from dead player to conqueror',
      () {
        final infantry = const Card(
            territory: 'C', cardType: CardType.infantry);
        final cavalry = const Card(
            territory: 'D', cardType: CardType.cavalry);
        final state = buildTestState(
          cards: {
            '0': [const Card(territory: 'A', cardType: CardType.infantry)],
            '1': [infantry, cavalry],
          },
        );
        final newState = transferCards(state, 1, 0);
        expect(newState.cards['1'], isEmpty);
        expect(newState.cards['0'], hasLength(3));
        expect(newState.cards['0'], containsAll([infantry, cavalry]));
      },
    );
  });

  group('executeTurn fsm', () {
    test(
      'executeTurn fsm: turn starts in REINFORCE, transitions to ATTACK, then FORTIFY',
      () {
        final mapGraph = buildTestMap();
        final rng = FakeRandom(returnValue: 5); // attacker always wins

        // Track phases seen
        final phases = <TurnPhase>[];

        final agent = FakePlayerAgent(
          reinforceFn: (state, armies) {
            phases.add(state.turnPhase);
            return ReinforcePlacementAction(placements: {'A': armies});
          },
          attackFn: (state) {
            phases.add(state.turnPhase);
            return null; // skip attacks
          },
          fortifyFn: (state) {
            phases.add(state.turnPhase);
            return null;
          },
        );

        final state = buildTestState();
        final agents = {0: agent, 1: FakePlayerAgent()};
        executeTurn(state, mapGraph, agents, FakeRandom());

        expect(phases, containsAllInOrder([
          TurnPhase.reinforce,
          TurnPhase.attack,
          TurnPhase.fortify,
        ]));
      },
    );

    test(
      'executeTurn rotation: next player is next alive in circular order',
      () {
        final mapGraph = buildTestMap();

        final agent = FakePlayerAgent(
          reinforceFn: (state, armies) =>
              ReinforcePlacementAction(placements: {'A': armies}),
          attackFn: (_) => null,
          fortifyFn: (_) => null,
        );

        final state = buildTestState(currentPlayer: 0, turnNumber: 5);
        final agents = {0: agent, 1: FakePlayerAgent()};
        final (newState, _) = executeTurn(state, mapGraph, agents, FakeRandom());

        expect(newState.currentPlayerIndex, equals(1));
        expect(newState.turnNumber, equals(6));
      },
    );

    test(
      'executeTurn elimination: conquered player marked isAlive=false',
      () {
        final mapGraph = buildTestMap();
        // Give player 0 overwhelming armies so they always win
        final state = buildTestState(
          territories: {
            'A': TerritoryState(owner: 0, armies: 10),
            'B': TerritoryState(owner: 0, armies: 5),
            'C': TerritoryState(owner: 1, armies: 1),
            'D': TerritoryState(owner: 1, armies: 1),
          },
        );

        int attackCount = 0;
        final agent = FakePlayerAgent(
          reinforceFn: (state, armies) =>
              ReinforcePlacementAction(placements: {'A': armies}),
          attackFn: (state) {
            attackCount++;
            // Attack C then D then stop
            if (state.territories['C']!.owner == 1 && attackCount <= 5) {
              return BlitzAction(source: 'A', target: 'C');
            }
            if (state.territories['D']!.owner == 1 && attackCount <= 10) {
              return BlitzAction(source: 'A', target: 'D');
            }
            return null;
          },
          fortifyFn: (_) => null,
          advanceFn: (state, src, tgt, min, max) => min,
        );

        final agents = {0: agent, 1: FakePlayerAgent()};
        final rng = FakeRandom(returnValue: 5); // attacker always wins (6 > any def)
        final (newState, victory) = executeTurn(state, mapGraph, agents, rng);

        expect(newState.players[1].isAlive, isFalse);
        expect(victory, isTrue); // player 0 owns all territories
      },
    );

    test(
      'executeTurn elimination: conquered player cards transferred to attacker',
      () {
        final mapGraph = buildTestMap();
        final infantry = const Card(territory: 'C', cardType: CardType.infantry);
        final state = buildTestState(
          territories: {
            'A': TerritoryState(owner: 0, armies: 10),
            'B': TerritoryState(owner: 0, armies: 5),
            'C': TerritoryState(owner: 1, armies: 1),
            'D': TerritoryState(owner: 1, armies: 1),
          },
          cards: {
            '1': [infantry],
          },
        );

        int attackCount = 0;
        final agent = FakePlayerAgent(
          reinforceFn: (state, armies) =>
              ReinforcePlacementAction(placements: {'A': armies}),
          attackFn: (state) {
            attackCount++;
            if (state.territories['C']!.owner == 1 && attackCount <= 5) {
              return BlitzAction(source: 'A', target: 'C');
            }
            if (state.territories['D']!.owner == 1 && attackCount <= 10) {
              return BlitzAction(source: 'A', target: 'D');
            }
            return null;
          },
          fortifyFn: (_) => null,
          advanceFn: (state, src, tgt, min, max) => min,
        );

        final agents = {0: agent, 1: FakePlayerAgent()};
        final rng = FakeRandom(returnValue: 5);
        final (newState, _) = executeTurn(state, mapGraph, agents, rng);

        expect(newState.cards['1'] ?? [], isEmpty);
        expect(newState.cards['0'], contains(infantry));
      },
    );

    test(
      'executeTurn forced_trade: player with 5+ cards must trade before placing armies',
      () {
        final mapGraph = buildTestMap();
        // Give player 0 five cards (3 infantry + 1 cavalry + 1 artillery = valid sets)
        final hand = [
          const Card(territory: 'A', cardType: CardType.infantry),
          const Card(territory: 'B', cardType: CardType.infantry),
          const Card(territory: null, cardType: CardType.wild),
          const Card(territory: 'C', cardType: CardType.cavalry),
          const Card(territory: 'D', cardType: CardType.artillery),
        ];

        int armiesReceived = -1;
        final agent = FakePlayerAgent(
          reinforceFn: (state, armies) {
            armiesReceived = armies;
            return ReinforcePlacementAction(placements: {'A': armies});
          },
          attackFn: (_) => null,
          fortifyFn: (_) => null,
          cardTradeFn: (state, hand, forced) {
            if (forced) {
              // Trade the first valid set (indices 0,1,2)
              return TradeCardsAction(cards: [hand[0], hand[1], hand[2]]);
            }
            return null;
          },
        );

        final state = buildTestState(cards: {'0': List.of(hand)});
        final agents = {0: agent, 1: FakePlayerAgent()};
        final (newState, _) = executeTurn(state, mapGraph, agents, FakeRandom());

        // Player received armies = base (3 from 2 territories ~/ 3 = 0, min 3)
        // + trade bonus (first trade = 4)
        expect(armiesReceived, greaterThan(3));
        // Hand should be reduced (3 cards removed)
        expect((newState.cards['0'] ?? []).length, lessThan(hand.length));
      },
    );

    test(
      'executeTurn victory: detecting single owner returns true from executeTurn',
      () {
        final mapGraph = buildTestMap();
        // Player 0 almost wins — only needs C
        final state = buildTestState(
          territories: {
            'A': TerritoryState(owner: 0, armies: 10),
            'B': TerritoryState(owner: 0, armies: 5),
            'C': TerritoryState(owner: 1, armies: 1),
            'D': TerritoryState(owner: 0, armies: 3), // already owned
          },
          players: [
            PlayerState(index: 0, name: 'Player 0'),
            PlayerState(index: 1, name: 'Player 1', isAlive: true),
          ],
        );

        final agent = FakePlayerAgent(
          reinforceFn: (state, armies) =>
              ReinforcePlacementAction(placements: {'A': armies}),
          attackFn: (state) {
            if (state.territories['C']!.owner == 1) {
              return BlitzAction(source: 'A', target: 'C');
            }
            return null;
          },
          fortifyFn: (_) => null,
          advanceFn: (state, src, tgt, min, max) => min,
        );

        final agents = {0: agent, 1: FakePlayerAgent()};
        final rng = FakeRandom(returnValue: 5);
        final (_, victory) = executeTurn(state, mapGraph, agents, rng);

        expect(victory, isTrue);
      },
    );

    test(
      'executeTurn card_draw: player who conquered draws card at end of attack phase',
      () {
        final mapGraph = buildTestMap();
        final deckCard = const Card(territory: 'C', cardType: CardType.artillery);
        final state = buildTestState(
          territories: {
            'A': TerritoryState(owner: 0, armies: 10),
            'B': TerritoryState(owner: 0, armies: 5),
            'C': TerritoryState(owner: 1, armies: 1),
            'D': TerritoryState(owner: 1, armies: 2),
          },
          deck: [deckCard],
        );

        int attackCount = 0;
        final agent = FakePlayerAgent(
          reinforceFn: (state, armies) =>
              ReinforcePlacementAction(placements: {'A': armies}),
          attackFn: (state) {
            // Attack C once to conquer, then stop
            attackCount++;
            if (state.territories['C']!.owner == 1 && attackCount <= 3) {
              return BlitzAction(source: 'A', target: 'C');
            }
            return null;
          },
          fortifyFn: (_) => null,
          advanceFn: (state, src, tgt, min, max) => min,
        );

        final agents = {0: agent, 1: FakePlayerAgent()};
        final rng = FakeRandom(returnValue: 5);
        final (newState, _) = executeTurn(state, mapGraph, agents, rng);

        // Player 0 should have drawn the card
        expect(newState.cards['0'], contains(deckCard));
      },
    );
  });
}
