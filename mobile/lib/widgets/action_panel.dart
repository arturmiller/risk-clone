import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/actions.dart';
import '../engine/models/cards.dart';
import '../providers/game_provider.dart';
import '../providers/ui_provider.dart';

/// Phase-aware action controls for the human player's turn.
/// Uses .select() on gameProvider to minimize rebuilds.
class ActionPanel extends ConsumerWidget {
  const ActionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnPhase = ref.watch(
      gameProvider.select((a) => a.value?.turnPhase),
    );
    return switch (turnPhase) {
      TurnPhase.reinforce => const _ReinforcePanel(),
      TurnPhase.attack => const _AttackPanel(),
      TurnPhase.fortify => const _FortifyPanel(),
      null => const Center(child: CircularProgressIndicator()),
    };
  }
}

// ---------------------------------------------------------------------------
// Reinforce Panel
// ---------------------------------------------------------------------------

class _ReinforcePanel extends ConsumerWidget {
  const _ReinforcePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uIStateProvider);
    final pending = uiState.pendingArmies;
    final allPlaced = pending == 0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Armies to place: $pending',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: allPlaced
                ? () {
                    ref.read(gameProvider.notifier).humanMove(
                          ReinforcePlacementAction(
                            placements: uiState.proposedPlacements,
                          ),
                        );
                    ref.read(uIStateProvider.notifier).clearSelection();
                  }
                : null,
            child: const Text('Confirm Placement'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attack Panel
// ---------------------------------------------------------------------------

class _AttackPanel extends ConsumerStatefulWidget {
  const _AttackPanel();

  @override
  ConsumerState<_AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends ConsumerState<_AttackPanel> {
  int _selectedDice = 1;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(uIStateProvider);
    final canAct = uiState.selectedTerritory != null &&
        uiState.validTargets.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dice selector
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
            ],
            selected: {_selectedDice},
            onSelectionChanged: (s) => setState(() => _selectedDice = s.first),
          ),
          const SizedBox(height: 8),
          // Attack button
          ElevatedButton(
            onPressed: canAct
                ? () {
                    final source = uiState.selectedTerritory!;
                    final target = uiState.validTargets.first;
                    ref.read(gameProvider.notifier).humanMove(
                          AttackAction(
                            source: source,
                            target: target,
                            numDice: _selectedDice,
                          ),
                        );
                  }
                : null,
            child: const Text('Attack'),
          ),
          const SizedBox(height: 4),
          // Blitz button
          ElevatedButton(
            onPressed: canAct
                ? () {
                    final source = uiState.selectedTerritory!;
                    final target = uiState.validTargets.first;
                    ref.read(gameProvider.notifier).humanMove(
                          BlitzAction(source: source, target: target),
                        );
                  }
                : null,
            child: const Text('Blitz'),
          ),
          const SizedBox(height: 4),
          // End attack
          TextButton(
            onPressed: () {
              ref.read(gameProvider.notifier).humanMove(null);
            },
            child: const Text('End Attack'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fortify Panel
// ---------------------------------------------------------------------------

class _FortifyPanel extends ConsumerStatefulWidget {
  const _FortifyPanel();

  @override
  ConsumerState<_FortifyPanel> createState() => _FortifyPanelState();
}

class _FortifyPanelState extends ConsumerState<_FortifyPanel> {
  double _armies = 1;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(uIStateProvider);
    final source = uiState.selectedTerritory;
    final hasTarget =
        source != null && uiState.validTargets.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Army count slider — only meaningful when source + target selected
          Slider(
            value: _armies,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${_armies.round()}',
            onChanged: hasTarget
                ? (v) => setState(() => _armies = v)
                : null,
          ),
          const SizedBox(height: 8),
          // Confirm Fortify
          ElevatedButton(
            onPressed: hasTarget
                ? () {
                    ref.read(gameProvider.notifier).humanMove(
                          FortifyAction(
                            source: source,
                            target: uiState.validTargets.first,
                            armies: _armies.round(),
                          ),
                        );
                  }
                : null,
            child: const Text('Confirm Fortify'),
          ),
          const SizedBox(height: 4),
          // Skip Fortify
          TextButton(
            onPressed: () {
              ref.read(gameProvider.notifier).humanMove(null);
            },
            child: const Text('Skip Fortify'),
          ),
        ],
      ),
    );
  }
}
