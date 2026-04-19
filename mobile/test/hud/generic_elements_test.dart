import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/elements/generic.dart';
import 'package:risk_mobile/hud/models.dart';

const _theme = HudTheme(
  background: '#000',
  border: '#111',
  text: '#FFB300',
  borderRadius: 10,
);

void main() {
  testWidgets('renders a label with static text', (t) async {
    final label = const HudLabel(
      id: 'l',
      text: 'Hello',
      row: 0,
      col: 0,
      style: {'fontSize': 12, 'color': '#FF0000'},
    );
    await t.pumpWidget(ProviderScope(child: MaterialApp(
      home: Scaffold(body: renderElement(label, _theme)),
    )));
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('renders a grid with a child label', (t) async {
    final root = const HudGrid(
      id: 'root',
      rows: ['1fr'],
      cols: ['1fr'],
      children: [
        HudLabel(id: 'l', text: 'Inside', row: 0, col: 0),
      ],
    );
    await t.pumpWidget(ProviderScope(child: MaterialApp(
      home: Scaffold(body: renderElement(root, _theme)),
    )));
    expect(find.text('Inside'), findsOneWidget);
  });
}
