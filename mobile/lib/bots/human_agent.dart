import '../engine/models/game_state.dart';
import '../engine/models/cards.dart';
import '../engine/actions.dart';
import 'player_agent.dart';

/// One-shot PlayerAgent that wraps a single human decision.
/// GameNotifier constructs a new HumanAgent for each humanMove() call.
/// NEVER passed into Isolate.run() — main isolate only.
class HumanAgent implements PlayerAgent {
  final ReinforcePlacementAction? _placement;
  final AttackChoice? _attack; // null = end attack phase
  final FortifyAction? _fortify; // null = skip fortify
  final TradeCardsAction? _trade;
  final int _advance;

  const HumanAgent({
    ReinforcePlacementAction? placement,
    AttackChoice? attack,
    FortifyAction? fortify,
    TradeCardsAction? trade,
    int advance = 0,
  })  : _placement = placement,
        _attack = attack,
        _fortify = fortify,
        _trade = trade,
        _advance = advance;

  /// Named constructors for each action type — cleaner call sites.
  const HumanAgent.reinforce(ReinforcePlacementAction placement)
      : this(placement: placement);

  const HumanAgent.attack(AttackChoice choice)
      : this(attack: choice);

  const HumanAgent.endAttack() : this();

  const HumanAgent.fortify(FortifyAction action)
      : this(fortify: action);

  const HumanAgent.skipFortify() : this();

  const HumanAgent.trade(TradeCardsAction trade)
      : this(trade: trade);

  const HumanAgent.advance(int armies)
      : this(advance: armies);

  @override
  ReinforcePlacementAction chooseReinforcementPlacement(
          GameState s, int armies) =>
      _placement!;

  @override
  AttackChoice? chooseAttack(GameState s) => _attack;

  @override
  FortifyAction? chooseFortify(GameState s) => _fortify;

  @override
  TradeCardsAction? chooseCardTrade(
    GameState s,
    List<Card> hand, {
    required bool forced,
  }) =>
      _trade;

  @override
  int chooseAdvanceArmies(
          GameState s, String source, String target, int min, int max) =>
      _advance.clamp(min, max);
}
