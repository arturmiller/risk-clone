import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/simulation_provider.dart';
import '../widgets/map/territory_data.dart';

/// Horizontal status bar showing current turn number, active player with color
/// dot, and phase label during simulation mode.
class SimulationStatusBar extends ConsumerWidget {
  const SimulationStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simState = ref.watch(simulationProvider);
    final gameState = ref.watch(gameProvider).value;

    final turnNumber = gameState?.turnNumber ?? 0;
    final isPaused = simState.status == SimulationStatus.paused;
    final isInstantRunning = simState.status == SimulationStatus.running &&
        simState.speed == SimulationSpeed.instant;

    final currentPlayerIndex = gameState?.currentPlayerIndex ?? 0;
    final playerName =
        gameState?.players[currentPlayerIndex].name ?? 'Unknown';
    final playerColor =
        kPlayerColors[currentPlayerIndex % kPlayerColors.length];
    final phaseName = gameState?.turnPhase.name ?? '';
    final phaseLabel =
        phaseName.isNotEmpty
            ? '${phaseName[0].toUpperCase()}${phaseName.substring(1)}'
            : '';

    return SizedBox(
      height: 48,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: turn number
              Text(
                'Turn $turnNumber',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              // Center: player info or status
              if (isInstantRunning)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Simulating... Turn $turnNumber',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              else if (isPaused)
                Text(
                  'Paused - Turn $turnNumber',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: playerColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$playerName's turn",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              // Right: phase label
              Text(
                phaseLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
