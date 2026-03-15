import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../engine/models/game_config.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk')),
      body: gameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (gameState) {
          if (gameState == null) {
            // No active game — show new game options
            return _NewGamePrompt(onStart: (config) {
              ref.read(gameProvider.notifier).setupGame(config);
            });
          }
          // Game in progress — show resume / new game options
          return _ResumePrompt(
            gameState: gameState,
            onResume: () {}, // Phase 11 will navigate to game screen
            onNewGame: () {
              ref.read(gameProvider.notifier).clearSave();
            },
          );
        },
      ),
    );
  }
}

class _NewGamePrompt extends StatelessWidget {
  final void Function(GameConfig) onStart;
  const _NewGamePrompt({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Risk Mobile',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => onStart(
              const GameConfig(playerCount: 3, difficulty: Difficulty.medium),
            ),
            child: const Text('New Game (3 Players, Medium)'),
          ),
        ],
      ),
    );
  }
}

class _ResumePrompt extends StatelessWidget {
  final dynamic gameState;
  final VoidCallback onResume;
  final VoidCallback onNewGame;
  const _ResumePrompt({
    required this.gameState,
    required this.onResume,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Resume Game?',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text('Turn ${gameState.turnNumber}'),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onResume, child: const Text('Resume')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onNewGame, child: const Text('New Game')),
        ],
      ),
    );
  }
}
