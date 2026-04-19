import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/actions.dart' as ga;
import '../providers/game_provider.dart';
import '../providers/ui_provider.dart';
import 'widgets/card_hand_visibility_provider.dart';

/// Dispatches a declarative action string to the appropriate game mutation.
void dispatchAction(String action, WidgetRef ref) {
  // selectDice:N
  final diceMatch = RegExp(r'^selectDice:(\d+)$').firstMatch(action);
  if (diceMatch != null) {
    final n = int.parse(diceMatch.group(1)!);
    ref.read(uIStateProvider.notifier).setDiceCount(n);
    return;
  }

  switch (action) {
    case 'attack':
      _doAttack(ref);
      return;
    case 'blitz':
      _doBlitz(ref);
      return;
    case 'endPhase':
      _doEndPhase(ref);
      return;
    case 'openCards':
      _openCards(ref);
      return;
  }

  if (kDebugMode) {
    debugPrint('[hud.actions] Unknown action: $action');
  }
}

void _doAttack(WidgetRef ref) {
  final ui = ref.read(uIStateProvider);
  final src = ui.selectedTerritory;
  final tgt = ui.selectedTarget;
  if (src == null || tgt == null) return;
  ref.read(gameProvider.notifier).humanMove(
        ga.AttackAction(source: src, target: tgt, numDice: ui.diceCount),
      );
}

void _doBlitz(WidgetRef ref) {
  final ui = ref.read(uIStateProvider);
  final src = ui.selectedTerritory;
  final tgt = ui.selectedTarget;
  if (src == null || tgt == null) return;
  ref.read(gameProvider.notifier).humanMove(
        ga.BlitzAction(source: src, target: tgt),
      );
}

void _doEndPhase(WidgetRef ref) {
  final gs = ref.read(gameProvider).value;
  if (gs == null) return;
  // Null action → end attack OR skip fortify, depending on current phase.
  ref.read(gameProvider.notifier).humanMove(null);
}

void _openCards(WidgetRef ref) =>
    ref.read(cardHandVisibilityProvider.notifier).toggle();
