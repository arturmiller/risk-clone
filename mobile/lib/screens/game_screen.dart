import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/models/cards.dart';
import '../engine/models/game_config.dart';
import '../engine/reinforcements.dart';
import '../providers/game_provider.dart';
import '../providers/map_provider.dart';
import '../providers/simulation_provider.dart';
import '../providers/ui_provider.dart';
import '../widgets/action_panel.dart';
import '../widgets/continent_panel.dart';
import '../widgets/game_log.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/map/map_widget.dart';
import '../widgets/simulation_control_bar.dart';
import '../widgets/simulation_status_bar.dart';
import '../widgets/territory_inspector.dart';

class GameScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  const GameScreen({super.key, this.gameMode = GameMode.vsBot});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  TurnPhase? _lastPhase;
  int? _lastPlayerIndex;
  bool _gameOverShown = false;

  @override
  Widget build(BuildContext context) {
    // Watch for game-over condition and reinforce phase init
    ref.listen(gameProvider, (prev, next) {
      final gameState = next.value;
      if (gameState == null) return;

      // Game over detection: only one alive player
      final alive = gameState.players.where((p) => p.isAlive).toList();
      if (alive.length == 1 && !_gameOverShown) {
        _gameOverShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => GameOverDialog(winner: alive.first),
          ).then((_) => _gameOverShown = false);
        });
      }

      // Reinforce phase init for human player (player 0) — skip in simulation mode
      if (widget.gameMode != GameMode.simulation) {
        if (gameState.currentPlayerIndex == 0 &&
            gameState.turnPhase == TurnPhase.reinforce &&
            (gameState.turnPhase != _lastPhase ||
                gameState.currentPlayerIndex != _lastPlayerIndex)) {
          _lastPhase = gameState.turnPhase;
          _lastPlayerIndex = gameState.currentPlayerIndex;
          ref.read(mapGraphProvider.future).then((mapGraph) {
            if (!context.mounted) return;
            final armies = calculateReinforcements(gameState, mapGraph, 0);
            ref.read(uIStateProvider.notifier).initReinforce(armies);
          });
        } else if (gameState.turnPhase != TurnPhase.reinforce) {
          _lastPhase = gameState.turnPhase;
          _lastPlayerIndex = gameState.currentPlayerIndex;
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return _LandscapeLayout(gameMode: widget.gameMode);
              }
              return _PortraitLayout(gameMode: widget.gameMode);
            },
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

class _PortraitLayout extends StatelessWidget {
  final GameMode gameMode;
  const _PortraitLayout({required this.gameMode});

  @override
  Widget build(BuildContext context) {
    if (gameMode == GameMode.simulation) {
      return Column(
        children: [
          const SizedBox(height: 48, child: SimulationStatusBar()),
          Expanded(
            child: Stack(
              children: [
                MapWidget(gameMode: gameMode),
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
      );
    }
    return const Column(
      children: [
        Expanded(child: MapWidget()),
        SizedBox(height: 200, child: ActionPanel()),
      ],
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  final GameMode gameMode;
  const _LandscapeLayout({required this.gameMode});

  @override
  Widget build(BuildContext context) {
    if (gameMode == GameMode.simulation) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MapWidget(gameMode: gameMode),
                const Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: TerritoryInspector(),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 280,
            child: Column(
              children: [
                const SizedBox(height: 48, child: SimulationStatusBar()),
                const Divider(height: 1),
                const Expanded(
                  flex: 3,
                  child: ClipRect(child: GameLogWidget()),
                ),
                const Divider(height: 1),
                const Expanded(
                  flex: 2,
                  child: ClipRect(child: SimulationControlBar()),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Expanded(flex: 3, child: MapWidget()),
        SizedBox(
          width: 280,
          child: Column(
            children: [
              const Expanded(
                flex: 2,
                child: ClipRect(child: ActionPanel()),
              ),
              const Divider(height: 1),
              const Expanded(
                flex: 3,
                child: ClipRect(child: GameLogWidget()),
              ),
              const Divider(height: 1),
              const Expanded(
                flex: 2,
                child: ClipRect(child: ContinentPanel()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
