import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/map_provider.dart';
import '../widgets/map/territory_data.dart'; // for kPlayerColors

/// Displays each continent with its army bonus and whether the current player controls it.
class ContinentPanel extends ConsumerWidget {
  const ContinentPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapGraphProvider);
    final gameAsync = ref.watch(gameProvider);

    return mapAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (mapGraph) {
        final gameState = gameAsync.value;
        if (gameState == null) return const SizedBox.shrink();

        final playerIdx = gameState.currentPlayerIndex;
        final playerColor = kPlayerColors[playerIdx % kPlayerColors.length];
        final playerTerritories = gameState.territories.entries
            .where((e) => e.value.owner == playerIdx)
            .map((e) => e.key)
            .toSet();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Continents',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final continent in mapGraph.continentNames)
              _ContinentRow(
                name: continent,
                bonus: mapGraph.continentBonus(continent),
                controlled: mapGraph.controlsContinent(continent, playerTerritories),
                playerColor: playerColor,
              ),
          ],
        );
      },
    );
  }
}

class _ContinentRow extends StatelessWidget {
  final String name;
  final int bonus;
  final bool controlled;
  final Color playerColor;

  const _ContinentRow({
    required this.name,
    required this.bonus,
    required this.controlled,
    required this.playerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (controlled)
            Icon(Icons.star, size: 14, color: playerColor)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            '+$bonus',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
