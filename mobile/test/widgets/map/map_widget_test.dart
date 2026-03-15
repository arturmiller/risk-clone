// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/widgets/map/territory_data.dart';

void main() {
  group('MapWidget rendering (MAPW-01, MAPW-03)', () {
    testWidgets(
      'MAPW-01: MapWidget renders inside InteractiveViewer without overflow',
      (tester) async {
        markTestSkipped('Wave 0 stub — implement in plan 10-02');
      },
    );

    testWidgets(
      'MAPW-03: territory filled with owner color (player 0 = red)',
      (tester) async {
        markTestSkipped('Wave 0 stub — implement in plan 10-02');
      },
    );

    testWidgets(
      'MAPW-03: army count label visible on territory',
      (tester) async {
        markTestSkipped('Wave 0 stub — implement in plan 10-02');
      },
    );

    test('kTerritoryData contains exactly 42 territories', () {
      expect(kTerritoryData.length, 42);
    });

    test('kPlayerColors contains exactly 6 colors', () {
      expect(kPlayerColors.length, 6);
    });
  });
}
