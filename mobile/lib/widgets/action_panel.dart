import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/actions.dart';
import '../engine/models/cards.dart';
import '../providers/game_provider.dart';
import '../providers/ui_provider.dart';
import 'card_panel.dart';

/// Phase-aware action controls for the human player's turn.
/// Uses .select() on gameProvider to minimize rebuilds.
class ActionPanel extends ConsumerWidget {
  const ActionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(
      gameProvider.select((a) => a.value),
    );
    if (gameState == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Only show action controls during the human player's turn
    if (gameState.currentPlayerIndex != 0) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            '${gameState.players[gameState.currentPlayerIndex].name}\'s turn...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return switch (gameState.turnPhase) {
      TurnPhase.reinforce => const _ReinforcePanel(),
      TurnPhase.attack => const _AttackPanel(),
      TurnPhase.fortify => const _FortifyPanel(),
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Armies to place: $pending',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const CardPanel(),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: allPlaced
                  ? () {
                      ref.read(gameProvider.notifier).humanMove(
                            ReinforcePlacementAction(
                              placements: uiState.proposedPlacements,
                            ),
                          );
                      ref.read(uIStateProvider.notifier).resetAll();
                    }
                  : null,
              child: const Text('Confirm Placement'),
            ),
          ],
        ),
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
  int _selectedDice = 3;
  double _advanceArmies = -1; // -1 = uninitialized, will default to max

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(uIStateProvider);

    // Show advance armies panel after conquest
    if (uiState.advanceSource != null) {
      final min = uiState.advanceMin;
      final max = uiState.advanceMax;
      final extraMovable = max - min; // additional armies beyond the default
      // Default slider to max on first show
      if (_advanceArmies < 0) _advanceArmies = extraMovable.toDouble();
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Conquered ${uiState.advanceTarget}!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (extraMovable > 0) ...[
              Text('Move armies: $min already moved, up to $max total'),
              const SizedBox(height: 8),
              Slider(
                value: _advanceArmies.clamp(0, extraMovable.toDouble()),
                min: 0,
                max: extraMovable.toDouble(),
                divisions: extraMovable,
                label: '${min + _advanceArmies.round()}',
                onChanged: (v) => setState(() => _advanceArmies = v),
              ),
            ] else
              Text('$min armies moved to ${uiState.advanceTarget}.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).humanMove(
                      AdvanceArmiesAction(
                        source: uiState.advanceSource!,
                        target: uiState.advanceTarget!,
                        armies: _advanceArmies.round(),
                      ),
                    );
                _advanceArmies = -1;
              },
              child: Text(extraMovable > 0
                  ? 'Move ${min + _advanceArmies.round()} armies total'
                  : 'Continue'),
            ),
          ],
        ),
      );
    }

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
          // Attack button — requires source + a selected enemy target
          Builder(builder: (context) {
            final source = uiState.selectedTerritory;
            final target = uiState.selectedTarget;
            final canAttack = source != null && target != null;

            return ElevatedButton(
              onPressed: canAttack
                  ? () {
                      ref.read(gameProvider.notifier).humanMove(
                            AttackAction(
                              source: source,
                              target: target,
                              numDice: _selectedDice,
                            ),
                          );
                    }
                  : null,
              child: Text(target != null ? 'Attack $target' : 'Select target'),
            );
          }),
          const SizedBox(height: 4),
          // Blitz button
          Builder(builder: (context) {
            final source = uiState.selectedTerritory;
            final target = uiState.selectedTarget;
            return ElevatedButton(
              onPressed: source != null && target != null
                  ? () {
                      ref.read(gameProvider.notifier).humanMove(
                            BlitzAction(source: source, target: target),
                          );
                    }
                  : null,
              child: const Text('Blitz'),
            );
          }),
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
  double _armies = -1; // -1 = uninitialized, will default to max

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(uIStateProvider);
    final source = uiState.selectedTerritory;
    final target = uiState.selectedTarget;
    final hasTarget = source != null && target != null;

    // Cap slider to source armies - 1 (must leave at least 1)
    final gameState = ref.watch(gameProvider.select((a) => a.value));
    final sourceArmies = (source != null && gameState != null)
        ? (gameState.territories[source]?.armies ?? 1)
        : 1;
    final maxMovable = (sourceArmies - 1).clamp(1, 99).toDouble();
    if (_armies < 0 || _armies > maxMovable) _armies = maxMovable;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasTarget ? 'Fortify: $source → $target (max ${maxMovable.round()})' : 'Select source, then target',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          // Army count slider — capped to source armies - 1
          Slider(
            value: _armies.clamp(1, maxMovable),
            min: 1,
            max: maxMovable,
            divisions: maxMovable > 1 ? (maxMovable - 1).round() : 1,
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
                            target: target,
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
