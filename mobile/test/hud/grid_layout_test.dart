import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/grid_layout.dart';

Widget _childAt({
  required int row,
  required int col,
  int rowSpan = 1,
  int colSpan = 1,
  String? alignSelf,
  String? justifySelf,
  required Widget child,
  required String id,
}) =>
    LayoutId(
      id: id,
      child: HudGridCell(
        row: row,
        col: col,
        rowSpan: rowSpan,
        colSpan: colSpan,
        alignSelf: alignSelf,
        justifySelf: justifySelf,
        child: child,
      ),
    );

void main() {
  testWidgets('lays out fixed px tracks', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 200,
        height: 100,
        child: HudGridLayout(
          rows: const ['100px'],
          cols: const ['50px', '50px'],
          gap: 0,
          children: [
            _childAt(id: 'a', row: 0, col: 0, child: const SizedBox.expand(key: ValueKey('a'))),
            _childAt(id: 'b', row: 0, col: 1, child: const SizedBox.expand(key: ValueKey('b'))),
          ],
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(a.width, 50);
    expect(b.left - a.left, 50);
  });

  testWidgets('distributes fr tracks', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 100,
          child: HudGridLayout(
            rows: const ['1fr'],
            cols: const ['1fr', '2fr'],
            gap: 0,
            children: [
              _childAt(id: 'a', row: 0, col: 0, child: const SizedBox.expand(key: ValueKey('a'))),
              _childAt(id: 'b', row: 0, col: 1, child: const SizedBox.expand(key: ValueKey('b'))),
            ],
          ),
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(a.width, 100); // 1/3 of 300
    expect(b.width, 200); // 2/3 of 300
  });

  testWidgets('respects rowSpan', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 100,
        height: 200,
        child: HudGridLayout(
          rows: const ['100px', '100px'],
          cols: const ['1fr'],
          gap: 0,
          children: [
            _childAt(id: 'a', row: 0, col: 0, rowSpan: 2,
              child: const SizedBox.expand(key: ValueKey('a'))),
          ],
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    expect(a.height, 200);
  });

  testWidgets('applies gap between tracks', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 210,
        height: 100,
        child: HudGridLayout(
          rows: const ['100px'],
          cols: const ['100px', '100px'],
          gap: 10,
          children: [
            _childAt(id: 'a', row: 0, col: 0,
                child: const SizedBox.expand(key: ValueKey('a'))),
            _childAt(id: 'b', row: 0, col: 1,
                child: const SizedBox.expand(key: ValueKey('b'))),
          ],
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(b.left - a.right, 10);
  });

  testWidgets('auto tracks size to intrinsic child height', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 200,
          child: HudGridLayout(
            rows: const ['auto', '1fr'],
            cols: const ['1fr'],
            gap: 0,
            children: [
              _childAt(
                  id: 'h',
                  row: 0,
                  col: 0,
                  child: const SizedBox(key: ValueKey('h'), height: 40)),
              _childAt(
                  id: 'b',
                  row: 1,
                  col: 0,
                  child: const SizedBox.expand(key: ValueKey('b'))),
            ],
          ),
        ),
      ),
    ));
    final h = tester.getRect(find.byKey(const ValueKey('h')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(h.height, 40); // auto row sized to child
    expect(b.height, 160); // fr row gets the rest
    expect(b.top, 40); // fr row starts below auto row
  });
}
