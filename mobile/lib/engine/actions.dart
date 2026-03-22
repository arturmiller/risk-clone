import 'models/cards.dart';

/// Sealed hierarchy for attack choices returned by PlayerAgent.chooseAttack().
sealed class AttackChoice {}

class AttackAction extends AttackChoice {
  final String source;
  final String target;
  final int numDice; // 1, 2, or 3
  AttackAction(
      {required this.source, required this.target, required this.numDice});
}

class BlitzAction extends AttackChoice {
  final String source;
  final String target;
  BlitzAction({required this.source, required this.target});
}

class FortifyAction {
  final String source;
  final String target;
  final int armies;
  const FortifyAction(
      {required this.source, required this.target, required this.armies});
}

class ReinforcePlacementAction {
  final Map<String, int> placements;
  const ReinforcePlacementAction({required this.placements});
}

class AdvanceArmiesAction {
  final String source;
  final String target;
  final int armies;
  const AdvanceArmiesAction(
      {required this.source, required this.target, required this.armies});
}

class TradeCardsAction {
  final List<Card> cards; // exactly 3 cards forming a valid set
  const TradeCardsAction({required this.cards});
}
