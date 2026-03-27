import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/actions.dart';
import '../engine/models/cards.dart';
import '../providers/game_provider.dart';
import '../providers/ui_provider.dart';

/// Compact bottom action bar for mobile screens.
/// Shows phase indicator + action buttons in a minimal overlay style.
class MobileActionBar extends ConsumerStatefulWidget {
  const MobileActionBar({super.key});

  @override
  ConsumerState<MobileActionBar> createState() => _MobileActionBarState();
}

class _MobileActionBarState extends ConsumerState<MobileActionBar> {
  int _selectedDice = 3;
  double _advanceArmies = -1;
  double _fortifyArmies = -1;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider.select((a) => a.value));
    if (gameState == null) return const SizedBox.shrink();

    // Bot's turn
    if (gameState.currentPlayerIndex != 0) {
      return _buildContainer(
        context,
        phaseText:
            '${gameState.players[gameState.currentPlayerIndex].name}\'s turn',
        subtitle: 'Waiting...',
        children: [],
      );
    }

    return switch (gameState.turnPhase) {
      TurnPhase.reinforce => _buildReinforce(context),
      TurnPhase.attack => _buildAttack(context),
      TurnPhase.fortify => _buildFortify(context),
    };
  }

  Widget _buildReinforce(BuildContext context) {
    final uiState = ref.watch(uIStateProvider);
    final pending = uiState.pendingArmies;
    final allPlaced = pending == 0;

    return _buildContainer(
      context,
      phaseText: 'REINFORCE PHASE',
      subtitle: allPlaced
          ? 'All armies placed'
          : 'Tap territories to place $pending armies',
      children: [
        _ActionButton(
          label: 'CONFIRM',
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
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildAttack(BuildContext context) {
    final uiState = ref.watch(uIStateProvider);

    // Advance armies after conquest
    if (uiState.advanceSource != null) {
      final min = uiState.advanceMin;
      final max = uiState.advanceMax;
      final extraMovable = max - min;
      if (_advanceArmies < 0) _advanceArmies = extraMovable.toDouble();

      return _buildContainer(
        context,
        phaseText: 'CONQUERED ${uiState.advanceTarget}!',
        subtitle: extraMovable > 0
            ? 'Move armies: ${min + _advanceArmies.round()} of $max'
            : '$min armies moved',
        children: [
          if (extraMovable > 0)
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: _advanceArmies.clamp(0, extraMovable.toDouble()),
                  min: 0,
                  max: extraMovable.toDouble(),
                  divisions: extraMovable > 0 ? extraMovable : 1,
                  onChanged: (v) => setState(() => _advanceArmies = v),
                ),
              ),
            ),
          _ActionButton(
            label: extraMovable > 0
                ? 'MOVE ${min + _advanceArmies.round()}'
                : 'CONTINUE',
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
            isPrimary: true,
          ),
        ],
      );
    }

    final source = uiState.selectedTerritory;
    final target = uiState.selectedTarget;
    final canAttack = source != null && target != null;

    return _buildContainer(
      context,
      phaseText: 'ATTACK PHASE',
      subtitle: target != null
          ? 'Attack $target from $source'
          : 'Select attacker, then target',
      children: [
        // Dice selector - compact
        _DiceSelector(
          selected: _selectedDice,
          onChanged: (v) => setState(() => _selectedDice = v),
        ),
        const SizedBox(width: 6),
        _ActionButton(
          label: 'ATTACK',
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
          isPrimary: true,
        ),
        const SizedBox(width: 4),
        _ActionButton(
          label: 'BLITZ',
          onPressed: canAttack
              ? () {
                  ref.read(gameProvider.notifier).humanMove(
                        BlitzAction(source: source, target: target),
                      );
                }
              : null,
        ),
        const SizedBox(width: 4),
        _ActionButton(
          label: 'END',
          onPressed: () {
            ref.read(gameProvider.notifier).humanMove(null);
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildFortify(BuildContext context) {
    final uiState = ref.watch(uIStateProvider);
    final source = uiState.selectedTerritory;
    final target = uiState.selectedTarget;
    final hasTarget = source != null && target != null;

    final gameState = ref.watch(gameProvider.select((a) => a.value));
    final sourceArmies = (source != null && gameState != null)
        ? (gameState.territories[source]?.armies ?? 1)
        : 1;
    final maxMovable = (sourceArmies - 1).clamp(1, 99).toDouble();
    if (_fortifyArmies < 0 || _fortifyArmies > maxMovable) {
      _fortifyArmies = maxMovable;
    }

    return _buildContainer(
      context,
      phaseText: 'FORTIFY PHASE',
      subtitle: hasTarget
          ? '$source -> $target (${_fortifyArmies.round()})'
          : 'Move your troops',
      children: [
        if (hasTarget)
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: _fortifyArmies.clamp(1, maxMovable),
                min: 1,
                max: maxMovable,
                divisions: maxMovable > 1 ? (maxMovable - 1).round() : 1,
                onChanged: (v) => setState(() => _fortifyArmies = v),
              ),
            ),
          ),
        _ActionButton(
          label: 'MOVE TROOPS',
          onPressed: hasTarget
              ? () {
                  ref.read(gameProvider.notifier).humanMove(
                        FortifyAction(
                          source: source,
                          target: target,
                          armies: _fortifyArmies.round(),
                        ),
                      );
                }
              : null,
          isPrimary: true,
        ),
        const SizedBox(width: 6),
        _ActionButton(
          label: 'END TURN',
          onPressed: () {
            ref.read(gameProvider.notifier).humanMove(null);
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildContainer(
    BuildContext context, {
    required String phaseText,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.brown.shade900.withValues(alpha: 0.95),
            Colors.brown.shade800.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.shade700.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phase header
          Text(
            phaseText,
            style: TextStyle(
              color: Colors.amber.shade300,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact dice selector
// ---------------------------------------------------------------------------
class _DiceSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DiceSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 3; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: selected == i
                    ? Colors.red.shade700
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: selected == i
                    ? Border.all(color: Colors.red.shade300, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    color:
                        selected == i ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Styled action button
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _ActionButton({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Color bgColor;
    if (!enabled) {
      bgColor = Colors.grey.shade800;
    } else if (isDestructive) {
      bgColor = Colors.red.shade900;
    } else if (isPrimary) {
      bgColor = Colors.green.shade700;
    } else {
      bgColor = Colors.blueGrey.shade700;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: enabled
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
