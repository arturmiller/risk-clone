import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/screens/home_screen.dart';

void main() {
  group('HomeScreen setup form (MOBX-01)', () {
    Widget buildForm() {
      return MaterialApp(
        home: Scaffold(
          body: SetupForm(onStart: (_) {}),
        ),
      );
    }

    testWidgets('renders player count selector', (tester) async {
      await tester.pumpWidget(buildForm());
      // Slider widget should be present
      expect(find.byType(Slider), findsOneWidget);
      // Default label "Players: 3" should appear
      expect(find.text('Players: 3'), findsOneWidget);
    });

    testWidgets('renders difficulty selector', (tester) async {
      await tester.pumpWidget(buildForm());
      // SegmentedButton with Difficulty values
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('renders game mode selector', (tester) async {
      await tester.pumpWidget(buildForm());
      // SegmentedButton with GameMode values
      expect(find.text('vs Bots'), findsOneWidget);
      expect(find.text('Simulation'), findsOneWidget);
    });

    testWidgets('tapping Start calls setupGame with chosen config',
        (tester) async {
      markTestSkipped('requires provider setup — Phase 11 Plan 06');
    });

    testWidgets('Resume button navigates to GameScreen when game in progress',
        (tester) async {
      markTestSkipped('requires provider setup — Phase 11 Plan 06');
    });
  });
}
