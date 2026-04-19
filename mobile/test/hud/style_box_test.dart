import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/models.dart';
import 'package:risk_mobile/hud/style_box.dart';

const _theme = HudTheme(
  background: '#111111',
  border: '#222222',
  text: '#333333',
  borderRadius: 4,
);

void main() {
  testWidgets('applies background color from style map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {'background': '#FF0000'},
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final box = tester.widget<Container>(find.byType(Container));
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, const Color(0xFFFF0000));
  });

  testWidgets('applies linear-gradient background', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {
            'background': 'linear-gradient(90deg, #FF0000, #0000FF)',
          },
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final deco = tester.widget<Container>(find.byType(Container)).decoration
        as BoxDecoration;
    expect(deco.gradient, isA<LinearGradient>());
  });

  testWidgets('applies 1px solid border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {'border': '1px solid rgba(255,160,0,0.4)'},
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final deco = tester.widget<Container>(find.byType(Container)).decoration
        as BoxDecoration;
    expect(deco.border, isNotNull);
  });

  testWidgets('applies borderRadius and padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {'borderRadius': 8, 'padding': '4px 8px'},
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final container = tester.widget<Container>(find.byType(Container));
    final deco = container.decoration as BoxDecoration;
    expect(deco.borderRadius, BorderRadius.circular(8));
    expect(container.padding, const EdgeInsets.symmetric(vertical: 4, horizontal: 8));
  });
}
