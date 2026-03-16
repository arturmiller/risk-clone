import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/game_log_provider.dart';

/// Shown when a player wins the game (or the human is eliminated).
/// Displays winner name + options to start a new game or return to home.
class GameOverDialog extends ConsumerWidget {
  final PlayerState winner;

  const GameOverDialog({super.key, required this.winner});

  void _handleDismiss(BuildContext context, WidgetRef ref) {
    ref.read(gameProvider.notifier).clearSave();
    ref.read(gameLogProvider.notifier).clear();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Game Over'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${winner.name} wins!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            winner.index == 0 ? 'Congratulations!' : 'Better luck next time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _handleDismiss(context, ref),
          child: const Text('Home'),
        ),
        ElevatedButton(
          onPressed: () => _handleDismiss(context, ref),
          child: const Text('New Game'),
        ),
      ],
    );
  }
}
