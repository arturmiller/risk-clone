// Basic smoke test verifying the app renders without crashing.
// Full widget tests are in test/engine/ and test/persistence/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:risk_mobile/app.dart';

void main() {
  testWidgets('RiskApp smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RiskApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
