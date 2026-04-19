import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/models.dart';
import 'package:risk_mobile/hud/style.dart';

void main() {
  const theme = HudTheme(
    background: 'rgba(62,39,12,0.9)',
    border: 'rgba(255,193,7,0.3)',
    text: '#FFB300',
    borderRadius: 10,
  );

  group('parseColor', () {
    test('hex RRGGBB', () {
      expect(parseColor('#FF0000', theme), const Color(0xFFFF0000));
    });

    test('hex RRGGBBAA', () {
      expect(parseColor('#FF000080', theme), const Color(0x80FF0000));
    });

    test('rgba', () {
      expect(parseColor('rgba(255,0,0,0.5)', theme),
          Color.fromRGBO(255, 0, 0, 0.5));
    });

    test('rgb', () {
      expect(parseColor('rgb(255,0,0)', theme), const Color(0xFFFF0000));
    });

    test('theme token {text}', () {
      expect(parseColor('{text}', theme), const Color(0xFFFFB300));
    });

    test('theme token {border}', () {
      expect(parseColor('{border}', theme), parseColor(theme.border, theme));
    });

    test('throws on unknown format', () {
      expect(() => parseColor('hotpink', theme), throwsA(isA<FormatException>()));
    });
  });

  group('parseGradient', () {
    test('linear-gradient 2 stops', () {
      final g = parseGradient('linear-gradient(90deg, #FF0000, #0000FF)', theme);
      expect(g, isA<LinearGradient>());
      expect(g.colors, [const Color(0xFFFF0000), const Color(0xFF0000FF)]);
    });

    test('linear-gradient 3 stops', () {
      final g = parseGradient(
          'linear-gradient(180deg, #FF0000, #00FF00, #0000FF)', theme);
      expect(g.colors.length, 3);
    });

    test('throws on non-gradient input', () {
      expect(() => parseGradient('#FF0000', theme),
          throwsA(isA<FormatException>()));
    });
  });
}
