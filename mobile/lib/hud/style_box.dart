import 'package:flutter/material.dart';
import 'models.dart';
import 'style.dart';

class HudStyleBox extends StatelessWidget {
  final HudTheme theme;
  final Map<String, dynamic>? style;
  final Widget child;

  const HudStyleBox({
    super.key,
    required this.theme,
    required this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final s = style ?? const {};

    Color? bgColor;
    Gradient? gradient;
    final bg = s['background'];
    if (bg is String) {
      if (bg.startsWith('linear-gradient')) {
        gradient = parseGradient(bg, theme);
      } else {
        bgColor = parseColor(bg, theme);
      }
    }

    BoxBorder? border;
    final b = s['border'];
    if (b is String) {
      border = _parseBorder(b, theme);
    }

    BorderRadius? borderRadius;
    final br = s['borderRadius'];
    if (br is num) {
      borderRadius = BorderRadius.circular(br.toDouble());
    }

    EdgeInsets? padding;
    final p = s['padding'];
    if (p is num) {
      padding = EdgeInsets.all(p.toDouble());
    } else if (p is String) {
      padding = _parsePadding(p);
    }

    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        border: border,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    return decorated;
  }
}

BoxBorder? _parseBorder(String input, HudTheme theme) {
  // "1px solid rgba(...)" — only form we support
  final match = RegExp(r'^(\d+)px\s+solid\s+(.+)$').firstMatch(input.trim());
  if (match == null) {
    throw FormatException('Unsupported border: $input');
  }
  final width = double.parse(match.group(1)!);
  final color = parseColor(match.group(2)!, theme);
  return Border.all(color: color, width: width);
}

EdgeInsets _parsePadding(String input) {
  // "Xpx", "Xpx Ypx", "Xpx Ypx Zpx Wpx"; or unitless numbers.
  final parts = input.trim().split(RegExp(r'\s+'));
  final vals = parts.map((p) {
    final m = RegExp(r'^(-?\d+(?:\.\d+)?)(px)?$').firstMatch(p.trim());
    if (m == null) {
      throw FormatException('Unparseable padding value: $p');
    }
    return double.parse(m.group(1)!);
  }).toList();
  switch (vals.length) {
    case 1:
      return EdgeInsets.all(vals[0]);
    case 2:
      return EdgeInsets.symmetric(vertical: vals[0], horizontal: vals[1]);
    case 4:
      return EdgeInsets.fromLTRB(vals[3], vals[0], vals[1], vals[2]);
    default:
      throw FormatException('Unsupported padding arity: $input');
  }
}
