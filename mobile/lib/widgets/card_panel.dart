import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/actions.dart';
import '../engine/cards_engine.dart' as cards_engine;
import '../engine/models/cards.dart' as game_cards;
import '../providers/game_provider.dart';

/// Shows the player's cards with an option to trade 3 for bonus armies.
class CardPanel extends ConsumerStatefulWidget {
  const CardPanel({super.key});

  @override
  ConsumerState<CardPanel> createState() => _CardPanelState();
}

class _CardPanelState extends ConsumerState<CardPanel> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider.select((a) => a.value));
    if (gameState == null) return const SizedBox.shrink();

    final hand = gameState.cards['0'] ?? [];
    if (hand.isEmpty) return const SizedBox.shrink();

    final forced = hand.length >= 5;
    final selectedCards = _selected.map((i) => hand[i]).toList();
    final validSet = selectedCards.length == 3 && cards_engine.isValidSet(selectedCards);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Cards (${hand.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (forced)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Must trade!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (int i = 0; i < hand.length; i++)
                _CardChip(
                  card: hand[i],
                  selected: _selected.contains(i),
                  onTap: () {
                    setState(() {
                      if (_selected.contains(i)) {
                        _selected.remove(i);
                      } else if (_selected.length < 3) {
                        _selected.add(i);
                      }
                    });
                  },
                ),
            ],
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: validSet
                  ? () {
                      ref.read(gameProvider.notifier).humanMove(
                            TradeCardsAction(cards: selectedCards),
                          );
                      setState(() => _selected.clear());
                    }
                  : null,
              child: Text(validSet
                  ? 'Trade ${_selected.length} cards'
                  : 'Select 3 matching cards'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final game_cards.Card card;
  final bool selected;
  final VoidCallback onTap;

  const _CardChip({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (card.cardType) {
      game_cards.CardType.infantry => Icons.person,
      game_cards.CardType.cavalry => Icons.directions_run,
      game_cards.CardType.artillery => Icons.gps_fixed,
      game_cards.CardType.wild => Icons.star,
    };
    final label = card.territory ?? 'Wild';
    final shortLabel = label.length > 10 ? '${label.substring(0, 9)}…' : label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(shortLabel, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
