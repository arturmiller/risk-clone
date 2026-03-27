import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/models/game_state.dart';
import '../providers/game_provider.dart';
import 'map/territory_data.dart';

/// Top bar showing player info on left/right with "RISK" title centered.
/// Styled to match the classic Risk mobile game UI.
class PlayerInfoBar extends ConsumerWidget {
  const PlayerInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider.select((a) => a.value));
    if (gameState == null) return const SizedBox(height: 40);

    final players = gameState.players.where((p) => p.isAlive).toList();
    final territories = gameState.territories;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.brown.shade900,
            Colors.brown.shade800,
            Colors.brown.shade900,
          ],
        ),
      ),
      child: Row(
        children: [
          // Player 1 info (left)
          if (players.isNotEmpty)
            _PlayerChip(
              player: players[0],
              territoryCount: territories.values
                  .where((t) => t.owner == players[0].index)
                  .length,
              armyCount: territories.values
                  .where((t) => t.owner == players[0].index)
                  .fold(0, (sum, t) => sum + t.armies),
              isCurrentPlayer:
                  gameState.currentPlayerIndex == players[0].index,
            ),
          const Spacer(),
          // RISK title
          Text(
            'RISK',
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Player 2 info (right)
          if (players.length > 1)
            _PlayerChip(
              player: players[1],
              territoryCount: territories.values
                  .where((t) => t.owner == players[1].index)
                  .length,
              armyCount: territories.values
                  .where((t) => t.owner == players[1].index)
                  .fold(0, (sum, t) => sum + t.armies),
              isCurrentPlayer:
                  gameState.currentPlayerIndex == players[1].index,
              alignRight: true,
            ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final PlayerState player;
  final int territoryCount;
  final int armyCount;
  final bool isCurrentPlayer;
  final bool alignRight;

  const _PlayerChip({
    required this.player,
    required this.territoryCount,
    required this.armyCount,
    required this.isCurrentPlayer,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = kPlayerColors[player.index % kPlayerColors.length];

    return Container(
      margin: EdgeInsets.only(
        left: alignRight ? 0 : 4,
        right: alignRight ? 4 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? color.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: isCurrentPlayer
            ? Border.all(color: color, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignRight) ...[
            _buildInfo(context, color),
            const SizedBox(width: 4),
            _buildAvatar(color),
          ] else ...[
            _buildAvatar(color),
            const SizedBox(width: 4),
            _buildInfo(context, color),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: Icon(
          player.index == 0 ? Icons.person : Icons.smart_toy,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          player.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, size: 9, color: Colors.white70),
            Text(
              ' $territoryCount',
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
            const SizedBox(width: 4),
            Icon(Icons.shield, size: 9, color: Colors.white70),
            Text(
              ' $armyCount',
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }
}
