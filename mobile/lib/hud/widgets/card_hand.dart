import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/actions.dart';
import '../../engine/cards_engine.dart' as cards_engine;
import '../../engine/models/cards.dart' as game_cards;
import '../../providers/game_provider.dart';
import '../models.dart';
import '../style_box.dart';
import 'card_hand_visibility_provider.dart';

class CardHandWidget extends ConsumerStatefulWidget {
  final HudCardHand element;
  final HudTheme theme;
  const CardHandWidget({super.key, required this.element, required this.theme});

  @override
  ConsumerState<CardHandWidget> createState() => _CardHandWidgetState();
}

class _CardHandWidgetState extends ConsumerState<CardHandWidget> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(cardHandVisibilityProvider);
    if (!visible) return const SizedBox.shrink();

    final gameState = ref.watch(gameProvider.select((a) => a.value));
    if (gameState == null) return const SizedBox.shrink();

    final hand = gameState.cards['0'] ?? [];

    return HudStyleBox(
      theme: widget.theme,
      style: widget.element.style,
      child: _buildCardPanel(context, hand),
    );
  }

  // Lifted from _FloatingCardsButtonState._buildCardPanel (mobile_game_overlay.dart lines 207-308)
  Widget _buildCardPanel(BuildContext context, List<game_cards.Card> hand) {
    final forced = hand.length >= 5;
    final selectedCards = _selected.map((i) => hand[i]).toList();
    final validSet =
        selectedCards.length == 3 && cards_engine.isValidSet(selectedCards);

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
                onTap: () {
                  ref.read(cardHandVisibilityProvider.notifier).toggle();
                  setState(() => _selected.clear());
                },
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
                      ref
                          .read(cardHandVisibilityProvider.notifier)
                          .toggle();
                      setState(() => _selected.clear());
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

  // Lifted from _FloatingCardsButtonState._buildCardChip (mobile_game_overlay.dart lines 310-357)
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
