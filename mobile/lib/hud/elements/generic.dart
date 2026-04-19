import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../actions.dart';
import '../bindings.dart';
import '../grid_layout.dart';
import '../models.dart';
import '../selected_when.dart';
import '../style.dart';
import '../style_box.dart';
import '../widgets/attack_log.dart';
import '../widgets/card_hand.dart';

/// Top-level dispatch: given any HudElement, produce a widget.
Widget renderElement(HudElement el, HudTheme theme) => switch (el) {
      HudGrid() => _Grid(grid: el, theme: theme),
      HudLabel() => _Label(label: el, theme: theme),
      HudIcon() => _Icon(icon: el, theme: theme),
      HudButton() => _Button(button: el, theme: theme),
      HudList() => _listWidget(el, theme),
      HudCardHand() => _cardHandWidget(el, theme),
    };

/// Wrap a child with grid placement data so HudGridLayout sees it.
Widget _placed(HudElement el, Widget child) {
  return LayoutId(
    id: el.id,
    child: HudGridCell(
      row: el.row ?? 0,
      col: el.col ?? 0,
      rowSpan: el.rowSpan ?? 1,
      colSpan: el.colSpan ?? 1,
      alignSelf: (el.style?['alignSelf']) as String?,
      justifySelf: (el.style?['justifySelf']) as String?,
      child: child,
    ),
  );
}

class _Grid extends StatelessWidget {
  final HudGrid grid;
  final HudTheme theme;
  const _Grid({required this.grid, required this.theme});

  @override
  Widget build(BuildContext context) {
    final gap = (grid.style?['gap'] is num)
        ? (grid.style!['gap'] as num).toDouble()
        : 0.0;
    final inner = HudGridLayout(
      rows: grid.rows,
      cols: grid.cols,
      gap: gap,
      children: grid.children.map((c) => _placed(c, renderElement(c, theme))).toList(),
    );
    return HudStyleBox(theme: theme, style: grid.style, child: inner);
  }
}

class _Label extends ConsumerWidget {
  final HudLabel label;
  final HudTheme theme;
  const _Label({required this.label, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bound = label.binding != null
        ? resolveBinding(label.binding!, ref)?.toString()
        : null;
    final text = bound ?? label.text ?? '';
    return HudStyleBox(
      theme: theme,
      style: label.style,
      child: Text(text, style: _textStyleFrom(label.style, theme), textAlign: _textAlignFrom(label.style)),
    );
  }
}

class _Icon extends StatelessWidget {
  final HudIcon icon;
  final HudTheme theme;
  const _Icon({required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    final mat = _materialIconFromName(icon.name);
    final color = (icon.style?['color'] is String)
        ? parseColor(icon.style!['color'] as String, theme)
        : null;
    final size = (icon.style?['fontSize'] is num)
        ? (icon.style!['fontSize'] as num).toDouble()
        : 14.0;
    return HudStyleBox(
      theme: theme,
      style: icon.style,
      child: Icon(mat, color: color, size: size),
    );
  }
}

class _Button extends ConsumerWidget {
  final HudButton button;
  final HudTheme theme;
  const _Button({required this.button, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = button.selectedWhen != null
        ? evaluateSelectedWhen(button.selectedWhen!, ref)
        : false;
    final style = selected && button.selectedStyle != null
        ? {...?button.style, ...button.selectedStyle!}
        : button.style;
    return HudStyleBox(
      theme: theme,
      style: style,
      child: InkWell(
        onTap: button.action != null
            ? () => dispatchAction(button.action!, ref)
            : null,
        child: Center(
          child: Text(button.text ?? '', style: _textStyleFrom(style, theme), textAlign: _textAlignFrom(style)),
        ),
      ),
    );
  }
}

TextStyle _textStyleFrom(Map<String, dynamic>? s, HudTheme theme) {
  if (s == null) return const TextStyle();
  final color = s['color'] is String ? parseColor(s['color'] as String, theme) : null;
  final fontSize = s['fontSize'] is num ? (s['fontSize'] as num).toDouble() : null;
  FontWeight? fw;
  if (s['fontWeight'] == 'bold') fw = FontWeight.bold;
  return TextStyle(color: color, fontSize: fontSize, fontWeight: fw);
}

TextAlign? _textAlignFrom(Map<String, dynamic>? s) {
  if (s == null) return null;
  switch (s['textAlign']) {
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    case 'start':
      return TextAlign.start;
    case 'end':
      return TextAlign.end;
    default:
      return null;
  }
}

IconData _materialIconFromName(String name) {
  switch (name) {
    case 'person':
      return Icons.person;
    case 'smart_toy':
      return Icons.smart_toy;
    case 'style':
      return Icons.style;
    default:
      if (kDebugMode) {
        debugPrint('[hud.icon] Unknown Material icon name: $name');
      }
      return Icons.help_outline;
  }
}

Widget _listWidget(HudList el, HudTheme theme) {
  if (el.itemBinding == 'game.battleLog') {
    return AttackLogWidget(element: el, theme: theme);
  }
  assert(false, 'Unknown itemBinding: ${el.itemBinding}');
  return const SizedBox();
}

Widget _cardHandWidget(HudCardHand el, HudTheme theme) =>
    CardHandWidget(element: el, theme: theme);
