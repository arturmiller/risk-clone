import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../style.dart';
import '../style_box.dart';
import '../../providers/game_log_provider.dart';

class AttackLogWidget extends ConsumerWidget {
  final HudList element;
  final HudTheme theme;
  const AttackLogWidget({super.key, required this.element, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(gameLogProvider);
    final items = log.map((e) => e.message).toList();
    final recent = items.length > element.maxItems
        ? items.sublist(items.length - element.maxItems)
        : items;
    final fontSize = (element.style?['fontSize'] is num)
        ? (element.style!['fontSize'] as num).toDouble()
        : 10.0;
    final color = (element.style?['color'] is String)
        ? parseColor(element.style!['color'] as String, theme)
        : Colors.white70;

    return HudStyleBox(
      theme: theme,
      style: element.style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: recent
            .map((line) => Text(line,
                style: TextStyle(fontSize: fontSize, color: color)))
            .toList(),
      ),
    );
  }
}
