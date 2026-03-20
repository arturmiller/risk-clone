import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';

/// Speed selector + Play/Pause + Stop controls for simulation mode.
/// Replaces ActionPanel when GameMode.simulation is active.
class SimulationControlBar extends ConsumerWidget {
  const SimulationControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simState = ref.watch(simulationProvider);
    final isComplete = simState.status == SimulationStatus.complete;
    final isIdle = simState.status == SimulationStatus.idle;
    final isRunning = simState.status == SimulationStatus.running;
    final isPaused = simState.status == SimulationStatus.paused;
    final isInstantRunning =
        isRunning && simState.speed == SimulationSpeed.instant;

    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Speed selector
            SegmentedButton<SimulationSpeed>(
              segments: const [
                ButtonSegment(
                    value: SimulationSpeed.slow, label: Text('Slow')),
                ButtonSegment(
                    value: SimulationSpeed.fast, label: Text('Fast')),
                ButtonSegment(
                    value: SimulationSpeed.instant, label: Text('Instant')),
              ],
              selected: {simState.speed},
              onSelectionChanged: (isComplete || isInstantRunning)
                  ? null
                  : (s) => ref
                      .read(simulationProvider.notifier)
                      .setSpeed(s.first),
            ),
            const SizedBox(width: 16),
            // Play/Pause toggle
            SizedBox(
              height: 44,
              child: IconButton(
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                tooltip:
                    isRunning ? 'Pause Simulation' : 'Resume Simulation',
                color: Theme.of(context).colorScheme.primary,
                onPressed: (isRunning && !isInstantRunning)
                    ? () => ref.read(simulationProvider.notifier).pause()
                    : isPaused
                        ? () =>
                            ref.read(simulationProvider.notifier).resume()
                        : null,
              ),
            ),
            const SizedBox(width: 8),
            // Stop button (destructive)
            SizedBox(
              height: 44,
              child: IconButton(
                icon: const Icon(Icons.stop),
                tooltip: 'Stop Simulation',
                color: Theme.of(context).colorScheme.error,
                onPressed: (isIdle || isComplete)
                    ? null
                    : () => _showStopConfirmation(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop Simulation'),
        content:
            const Text('End this simulation and return to the home screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(simulationProvider.notifier).stop();
              Navigator.of(dialogContext).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
