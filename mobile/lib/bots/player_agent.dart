import '../engine/models/game_state.dart';
import '../engine/models/cards.dart';
import '../engine/actions.dart';

/// Abstract agent interface for all player types (human and bot).
/// turn.dart calls these methods to get player decisions.
/// Phase 8 implements EasyAgent, MediumAgent, HardAgent.
/// Phase 9 wires HumanAgent through Riverpod providers.
abstract class PlayerAgent {
  /// Choose how to place reinforcement armies.
  /// [armies] is the total to place; all must be placed.
  ReinforcePlacementAction chooseReinforcementPlacement(GameState state, int armies);

  /// Choose an attack or end the attack phase.
  /// Returns AttackAction, BlitzAction, or null (end attacks).
  AttackChoice? chooseAttack(GameState state);

  /// Choose a fortification move, or null to skip.
  FortifyAction? chooseFortify(GameState state);

  /// Choose cards to trade, or null to decline (only valid when not forced).
  /// [forced] is true when player has 5+ cards and MUST trade.
  TradeCardsAction? chooseCardTrade(GameState state, List<Card> hand, {required bool forced});

  /// Choose how many armies to advance into a conquered territory.
  /// Must return a value in [min, max].
  int chooseAdvanceArmies(GameState state, String source, String target, int min, int max);
}
