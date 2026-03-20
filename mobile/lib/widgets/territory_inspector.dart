import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/map_provider.dart';
import '../providers/ui_provider.dart';
import '../widgets/map/territory_data.dart';

/// Territory detail card overlay shown when a territory is tapped during
/// simulation mode. Displays territory name, owner with color dot, army count,
/// and continent name. Auto-updates when inspected territory data changes.
class TerritoryInspector extends ConsumerWidget {
  const TerritoryInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTerritory = ref.watch(uIStateProvider).selectedTerritory;
    if (selectedTerritory == null) return const SizedBox.shrink();

    final gameState = ref.watch(gameProvider).value;
    if (gameState == null) return const SizedBox.shrink();

    final territory = gameState.territories[selectedTerritory];
    if (territory == null) return const SizedBox.shrink();

    final ownerIndex = territory.owner;
    final ownerName = gameState.players[ownerIndex].name;
    final ownerColor = kPlayerColors[ownerIndex % kPlayerColors.length];

    // Look up continent from MapGraph (async provider)
    final mapAsync = ref.watch(mapGraphProvider);
    final continent = mapAsync.value?.continentOf(selectedTerritory);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Territory name
                Text(
                  selectedTerritory,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // Owner row: color dot + name
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ownerColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ownerName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Army count
                Text(
                  'Armies: ${territory.armies}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (continent != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    continent,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
