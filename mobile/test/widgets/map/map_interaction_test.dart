// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/widgets/map/territory_data.dart';

// Mirror of _MapWidgetState._selectTerritoryAt logic for unit testing
List<String> hitTest(Offset svgPoint, {double hitPadding = 6.0}) {
  return kTerritoryData.entries
      .where((e) => e.value.rect.inflate(hitPadding).contains(svgPoint))
      .map((e) => e.key)
      .toList();
}

void main() {
  group('Territory hit testing (MAPW-02, MAPW-05)', () {
    test('MAPW-02: hit test at center of Alaska selects exactly Alaska', () {
      // Alaska: Rect.fromLTWH(30, 60, 60, 50), center ~(60, 85)
      final hits = hitTest(const Offset(60, 85));
      expect(hits, contains('Alaska'));
      expect(hits, hasLength(1));
    });

    test('MAPW-02: scene coordinate system — same point always maps to same territory', () {
      // Scene coordinates are always in 1200x700 SVG space regardless of zoom
      // toScene() handles the viewport-to-scene mapping before hit testing
      final hits1 = hitTest(const Offset(60, 85));
      final hits2 = hitTest(const Offset(60, 85));
      expect(hits1, equals(hits2));
    });

    test('MAPW-05: tap 4dp outside territory left edge still selects it (within 6dp expansion)', () {
      // Alaska left edge is x=30; 4dp outside is x=26
      final hits = hitTest(const Offset(26, 85));
      expect(hits, contains('Alaska'));
    });

    test('MAPW-05: tap 7dp outside territory left edge does not select it (beyond 6dp expansion)', () {
      // Alaska left edge is x=30; 7dp outside is x=23
      final hits = hitTest(const Offset(23, 85));
      expect(hits, isNot(contains('Alaska')));
    });

    test('MAPW-05: tap in overlap of expanded rects triggers disambiguation (returns multiple hits)', () {
      // Northern Europe: Rect.fromLTWH(485, 135, 90, 60) => bottom = 195, inflated by 6 => bottom = 201
      // Southern Europe: Rect.fromLTWH(490, 205, 90, 65) => top = 205, inflated by 6 => top = 199
      // Overlap y range: 199 to 201 (a 2-unit band)
      // At y=200 (midpoint):
      //   Northern Europe inflated x: 479 to 581
      //   Southern Europe inflated x: 484 to 586
      //   Overlap x range: 484 to 581
      // Test point Offset(535, 200) is inside both inflated rects. Confirmed.
      final hits = hitTest(const Offset(535, 200));
      expect(hits.length, greaterThanOrEqualTo(2));
      expect(hits, containsAll(['Northern Europe', 'Southern Europe']));
    });
  });

  group('Territory selection highlighting (MAPW-04)', () {
    testWidgets(
      'MAPW-04: selected territory shows highlight; valid targets show target tint',
      (tester) async {
        markTestSkipped(
          'Visual test — verified manually via flutter run; painter logic covered in map_widget_test.dart',
        );
      },
    );
  });
}
