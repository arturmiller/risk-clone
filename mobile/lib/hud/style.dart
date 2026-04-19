import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

Color parseColor(String input, HudTheme theme) {
  final trimmed = input.trim();

  // Theme tokens: {text}, {border}, {background}
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    final token = trimmed.substring(1, trimmed.length - 1);
    switch (token) {
      case 'text':
        return parseColor(theme.text, theme);
      case 'border':
        return parseColor(theme.border, theme);
      case 'background':
        return parseColor(theme.background, theme);
      default:
        throw FormatException('Unknown theme token: $token');
    }
  }

  // Hex: #RRGGBB or #RRGGBBAA
  if (trimmed.startsWith('#')) {
    final hex = trimmed.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      // Input is RRGGBBAA, Flutter wants AARRGGBB
      final rgb = hex.substring(0, 6);
      final alpha = hex.substring(6);
      return Color(int.parse('$alpha$rgb', radix: 16));
    }
    throw FormatException('Invalid hex color: $trimmed');
  }

  // rgba(r,g,b,a) or rgb(r,g,b)
  final rgbaMatch = RegExp(r'^rgba?\(([^)]+)\)$').firstMatch(trimmed);
  if (rgbaMatch != null) {
    final parts = rgbaMatch.group(1)!.split(',').map((s) => s.trim()).toList();
    if (parts.length == 3) {
      return Color.fromRGBO(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        1.0,
      );
    }
    if (parts.length == 4) {
      return Color.fromRGBO(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        double.parse(parts[3]),
      );
    }
  }

  throw FormatException('Unrecognized color: $trimmed');
}

LinearGradient parseGradient(String input, HudTheme theme) {
  final trimmed = input.trim();
  final match = RegExp(r'^linear-gradient\(([^)]+)\)$').firstMatch(trimmed);
  if (match == null) {
    throw FormatException('Not a linear-gradient: $trimmed');
  }
  final parts = match.group(1)!.split(',').map((s) => s.trim()).toList();
  if (parts.isEmpty) {
    throw FormatException('Empty linear-gradient args');
  }

  // First part is the angle: "90deg" or "180deg"
  final angleMatch = RegExp(r'^(-?\d+)deg$').firstMatch(parts.first);
  if (angleMatch == null) {
    throw FormatException('Missing angle in linear-gradient');
  }
  final angleDeg = int.parse(angleMatch.group(1)!);
  final (begin, end) = _anglePoints(angleDeg);

  final colors = parts.skip(1).map((c) => parseColor(c, theme)).toList();
  if (colors.length < 2) {
    throw FormatException('linear-gradient needs at least 2 color stops');
  }
  return LinearGradient(begin: begin, end: end, colors: colors);
}

(Alignment, Alignment) _anglePoints(int deg) {
  // CSS gradient angles: 0deg = to top, 90deg = to right, 180deg = to bottom.
  // Flutter Alignment has y inverted (top is -1).
  final norm = ((deg % 360) + 360) % 360;
  switch (norm) {
    case 0:
      return (Alignment.bottomCenter, Alignment.topCenter);
    case 90:
      return (Alignment.centerLeft, Alignment.centerRight);
    case 180:
      return (Alignment.topCenter, Alignment.bottomCenter);
    case 270:
      return (Alignment.centerRight, Alignment.centerLeft);
    default:
      final rad = norm * math.pi / 180.0;
      final dx = 0.5 * math.sin(rad);
      final dy = -0.5 * math.cos(rad);
      return (Alignment(-dx, -dy), Alignment(dx, dy));
  }
}
