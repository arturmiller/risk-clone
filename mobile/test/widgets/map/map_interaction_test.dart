// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/widgets/map/territory_data.dart';

void main() {
  group('Territory hit testing (MAPW-02, MAPW-05)', () {
    test(
      'MAPW-02: hit test at 1x zoom selects correct territory by rect containment',
      () {
        markTestSkipped('Wave 0 stub — implement in plan 10-03');
      },
    );

    test(
      'MAPW-02: hit test at 2x zoom maps viewport coords to scene coords correctly',
      () {
        markTestSkipped('Wave 0 stub — implement in plan 10-03');
      },
    );

    test(
      'MAPW-05: tap 4dp outside territory rect still selects it (6dp expansion)',
      () {
        markTestSkipped('Wave 0 stub — implement in plan 10-03');
      },
    );

    test(
      'MAPW-05: tap in overlap of two expanded rects triggers disambiguation (returns multiple hits)',
      () {
        markTestSkipped('Wave 0 stub — implement in plan 10-03');
      },
    );
  });

  group('Territory selection highlighting (MAPW-04)', () {
    testWidgets(
      'MAPW-04: selected territory shows highlight; valid targets show target tint',
      (tester) async {
        markTestSkipped('Wave 0 stub — implement in plan 10-02');
      },
    );
  });
}
