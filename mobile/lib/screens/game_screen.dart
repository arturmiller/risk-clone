import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/models/cards.dart';
import '../engine/models/game_config.dart';
import '../engine/models/game_state.dart';
import '../engine/reinforcements.dart';
import '../hud/hud_renderer.dart';
import '../providers/game_provider.dart';
import '../providers/map_provider.dart';
import '../providers/simulation_provider.dart';
import '../providers/ui_provider.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/map/map_widget.dart';
import '../widgets/simulation_control_bar.dart';
import '../widgets/simulation_status_bar.dart';
import '../widgets/territory_inspector.dart';

class GameScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final String mapAsset;
  const GameScreen({
    super.key,
    this.gameMode = GameMode.vsBot,
    this.mapAsset = 'original',
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  TurnPhase? _lastPhase;
  int? _lastPlayerIndex;
  bool _gameOverShown = false;

  void _maybeInitReinforce(GameState gameState) {
    if (widget.gameMode == GameMode.simulation) return;
    debugPrint('[REINFORCE] check: player=${gameState.currentPlayerIndex} '
        'phase=${gameState.turnPhase} lastPhase=$_lastPhase lastPlayer=$_lastPlayerIndex');
    if (gameState.currentPlayerIndex == 0 &&
        gameState.turnPhase == TurnPhase.reinforce &&
        (gameState.turnPhase != _lastPhase ||
            gameState.currentPlayerIndex != _lastPlayerIndex)) {
      _lastPhase = gameState.turnPhase;
      _lastPlayerIndex = gameState.currentPlayerIndex;
      debugPrint('[REINFORCE] scheduling mapGraph read...');
      ref.read(mapGraphProvider(mapAsset: widget.mapAsset).future).then((mapGraph) {
        debugPrint('[REINFORCE] mapGraph resolved, mounted=$mounted');
        if (!mounted) return;
        final armies = calculateReinforcements(gameState, mapGraph, 0);
        debugPrint('[REINFORCE] armies=$armies, calling initReinforce');
        ref.read(uIStateProvider.notifier).initReinforce(armies);
      }).catchError((e) {
        debugPrint('[REINFORCE] ERROR: $e');
      });
    } else if (gameState.turnPhase != TurnPhase.reinforce) {
      _lastPhase = gameState.turnPhase;
      _lastPlayerIndex = gameState.currentPlayerIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the game state — this also provides the initial value
    final gameAsync = ref.watch(gameProvider);
    final gameState = gameAsync.value;

    // Initialize reinforce on every build where conditions match
    // (idempotent: _lastPhase/_lastPlayerIndex guard prevents re-init)
    debugPrint('[BUILD] gameAsync=${gameAsync.runtimeType} gameState=${gameState != null ? "present(player=${gameState.currentPlayerIndex}, phase=${gameState.turnPhase})" : "null"}');
    if (gameState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeInitReinforce(gameState);
      });
    }

    // Listen for game-over, phase changes, and subsequent state changes
    ref.listen(gameProvider, (prev, next) {
      final gs = next.value;
      if (gs == null) return;
      final prevGs = prev?.value;

      // Clear stale UI selections when phase or player changes
      // BUT not when entering reinforce (initReinforce will set it up)
      if (prevGs != null &&
          (gs.turnPhase != prevGs.turnPhase ||
              gs.currentPlayerIndex != prevGs.currentPlayerIndex)) {
        if (gs.turnPhase != TurnPhase.reinforce || gs.currentPlayerIndex != 0) {
          ref.read(uIStateProvider.notifier).resetAll();
        }
      }

      // Re-init reinforce when it's human's turn again
      _maybeInitReinforce(gs);

      // Game over detection: single winner OR human player eliminated
      final alive = gs.players.where((p) => p.isAlive).toList();
      final humanDead = !gs.players[0].isAlive;
      if ((alive.length == 1 || humanDead) && !_gameOverShown) {
        _gameOverShown = true;
        // Pick the winner: if only one alive, that's the winner.
        // If human died but bots are still fighting, pick the leading bot.
        final winner = alive.length == 1
            ? alive.first
            : alive.reduce((a, b) {
                final aCount = gs.territories.values.where((t) => t.owner == a.index).length;
                final bCount = gs.territories.values.where((t) => t.owner == b.index).length;
                return aCount >= bCount ? a : b;
              });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => GameOverDialog(winner: winner),
          ).then((_) => _gameOverShown = false);
        });
      }
    });

    if (widget.gameMode == GameMode.simulation) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: _handlePop,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48, child: SimulationStatusBar()),
                Expanded(
                  child: Stack(
                    children: [
                      MapWidget(gameMode: widget.gameMode, mapAsset: widget.mapAsset),
                      const Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: TerritoryInspector(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80, child: SimulationControlBar()),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: MapWidget(mapAsset: widget.mapAsset, gameMode: widget.gameMode)),
              const Positioned.fill(child: HudRenderer()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;

    if (widget.gameMode == GameMode.simulation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Stop Simulation'),
          content: const Text(
              'End this simulation and return to the home screen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Stop'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        ref.read(simulationProvider.notifier).stop();
        Navigator.pop(context);
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Abandon game?'),
          content: const Text('Your progress will be saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abandon'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        Navigator.pop(context);
      }
    }
  }
}

