import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/actions.dart';
import '../engine/cards_engine.dart' as cards_engine;
import '../engine/models/cards.dart' as game_cards;
import '../providers/game_log_provider.dart';
import '../providers/game_provider.dart';
import 'mobile_action_bar.dart';
import 'player_info_bar.dart';

/// Full-screen overlay for mobile portrait mode.
/// Layers player bar, attack log, cards button, and action bar over the map.
class MobileGameOverlay extends StatelessWidget {
  const MobileGameOverlay({super.key});

  /// Returns the overlay widgets to be placed in a parent Stack.
  /// Call this instead of using MobileGameOverlay as a widget directly.
  static List<Widget> buildOverlayWidgets() {
    return const [
      // Top player info bar
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: PlayerInfoBar(),
      ),
      // Attack log (top-right, below player bar)
      Positioned(
        top: 44,
        right: 4,
        child: _FloatingAttackLog(),
      ),
      // Cards button (bottom-left)
      Positioned(
        bottom: 4,
        left: 8,
        child: _FloatingCardsButton(),
      ),
      // Action bar (bottom-center)
      Positioned(
        bottom: 0,
        left: 60,
        right: 4,
        child: MobileActionBar(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Not used directly — use buildOverlayWidgets() in a parent Stack instead.
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Floating Attack Log
// ---------------------------------------------------------------------------
class _FloatingAttackLog extends ConsumerStatefulWidget {
  const _FloatingAttackLog();

  @override
  ConsumerState<_FloatingAttackLog> createState() =>
      _FloatingAttackLogState();
}

class _FloatingAttackLogState extends ConsumerState<_FloatingAttackLog> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(gameLogProvider);
    final recentEntries = entries.length > 4
        ? entries.sublist(entries.length - 4)
        : entries;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: _expanded ? 180 : 120,
        constraints: BoxConstraints(
          maxHeight: _expanded ? 200 : 100,
        ),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.brown.shade900.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.amber.shade700.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 10, color: Colors.amber.shade300),
                const SizedBox(width: 3),
                Text(
                  'ATTACK LOG',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 12,
                  color: Colors.white54,
                ),
              ],
            ),
            const SizedBox(height: 3),
            if (recentEntries.isEmpty)
              const Text(
                'No events yet',
                style: TextStyle(color: Colors.white38, fontSize: 9),
              )
            else
              ...recentEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    entry.message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      height: 1.2,
                    ),
                    maxLines: _expanded ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating Cards Button
// ---------------------------------------------------------------------------
class _FloatingCardsButton extends ConsumerStatefulWidget {
  const _FloatingCardsButton();

  @override
  ConsumerState<_FloatingCardsButton> createState() =>
      _FloatingCardsButtonState();
}

class _FloatingCardsButtonState extends ConsumerState<_FloatingCardsButton> {
  bool _showCards = false;
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider.select((a) => a.value));
    if (gameState == null) return const SizedBox.shrink();

    final hand = gameState.cards['0'] ?? [];

    if (_showCards && hand.isNotEmpty) {
      return _buildCardPanel(context, hand);
    }

    return GestureDetector(
      onTap: hand.isNotEmpty
          ? () => setState(() => _showCards = true)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.brown.shade900.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.amber.shade700.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style, size: 14, color: Colors.amber.shade300),
            const SizedBox(width: 4),
            Text(
              'CARDS (${hand.length})',
              style: TextStyle(
                color: Colors.amber.shade300,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPanel(
      BuildContext context, List<game_cards.Card> hand) {
    final forced = hand.length >= 5;
    final selectedCards = _selected.map((i) => hand[i]).toList();
    final validSet = selectedCards.length == 3 &&
        cards_engine.isValidSet(selectedCards);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.shade700.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Cards (${hand.length})',
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (forced)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    'Must trade!',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _showCards = false;
                  _selected.clear();
                }),
                child: const Icon(Icons.close, size: 14, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (int i = 0; i < hand.length; i++)
                _buildCardChip(context, hand[i], i),
            ],
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: validSet
                  ? () {
                      ref.read(gameProvider.notifier).humanMove(
                            TradeCardsAction(cards: selectedCards),
                          );
                      setState(() {
                        _selected.clear();
                        _showCards = false;
                      });
                    }
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: validSet
                      ? Colors.green.shade700
                      : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  validSet ? 'Trade cards' : 'Select 3 matching',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: validSet ? Colors.white : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardChip(
      BuildContext context, game_cards.Card card, int index) {
    final isSelected = _selected.contains(index);
    final icon = switch (card.cardType) {
      game_cards.CardType.infantry => Icons.person,
      game_cards.CardType.cavalry => Icons.directions_run,
      game_cards.CardType.artillery => Icons.gps_fixed,
      game_cards.CardType.wild => Icons.star,
    };
    final label = card.territory ?? 'Wild';
    final shortLabel =
        label.length > 8 ? '${label.substring(0, 7)}...' : label;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selected.contains(index)) {
            _selected.remove(index);
          } else if (_selected.length < 3) {
            _selected.add(index);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.shade700.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: Colors.amber.shade400, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 3),
            Text(
              shortLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
