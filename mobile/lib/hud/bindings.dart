import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/models/cards.dart';
import '../engine/models/game_state.dart';
import '../providers/game_log_provider.dart';
import '../providers/game_provider.dart';
import '../providers/ui_provider.dart';

/// Resolves a binding path (e.g. "players[0].name") against the current
/// Riverpod state. Returns null for unknown paths.
Object? resolveBinding(String path, WidgetRef ref) {
  switch (path) {
    case 'ui.diceCount':
      return ref.watch(uIStateProvider).diceCount;
  }

  // game.* paths
  final gameAsync = ref.watch(gameProvider);
  final gs = gameAsync.value;

  if (path == 'game.phaseLabel') return _phaseLabel(gs);
  if (path == 'game.phaseHint') return _phaseHint(gs);
  if (path == 'game.battleLog') {
    final log = ref.watch(gameLogProvider);
    return log.map((e) => e.message).toList();
  }

  // activePlayer.cardsLabel
  if (path == 'activePlayer.cardsLabel') {
    if (gs == null) return 'CARDS (0)';
    final hand = gs.cards[gs.currentPlayerIndex.toString()] ?? const <Card>[];
    return 'CARDS (${hand.length})';
  }

  // players[i].* — parse the index
  final m = RegExp(r'^players\[(\d+)\]\.(.+)$').firstMatch(path);
  if (m != null) {
    final index = int.parse(m.group(1)!);
    final field = m.group(2)!;
    if (gs == null || index >= gs.players.length) return null;
    final p = gs.players[index];
    final territoryCount =
        gs.territories.values.where((t) => t.owner == index).length;
    final armyCount =
        gs.territories.values.where((t) => t.owner == index).fold<int>(
              0,
              (a, t) => a + t.armies,
            );
    switch (field) {
      case 'name':
        return p.name;
      case 'stats':
        return '🏴 $territoryCount  🛡️ $armyCount';
      case 'summary':
        return '${p.name} — 🏴 $territoryCount  🛡️ $armyCount';
      default:
        return null;
    }
  }

  if (kDebugMode) {
    debugPrint('[hud.bindings] Unknown path: $path');
  }
  return null;
}

String _phaseLabel(GameState? gs) {
  if (gs == null) return '';
  switch (gs.turnPhase) {
    case TurnPhase.reinforce:
      return 'REINFORCE PHASE';
    case TurnPhase.attack:
      return 'ATTACK PHASE';
    case TurnPhase.fortify:
      return 'FORTIFY PHASE';
  }
}

String _phaseHint(GameState? gs) {
  if (gs == null) return '';
  switch (gs.turnPhase) {
    case TurnPhase.reinforce:
      return 'Place your reinforcements';
    case TurnPhase.attack:
      return 'Select attacker, then target';
    case TurnPhase.fortify:
      return 'Move armies between your territories';
  }
}
