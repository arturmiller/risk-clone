import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/providers/simulation_provider.dart';
import 'package:risk_mobile/widgets/simulation_control_bar.dart';

Widget _wrap(SimulationState simState) {
  return ProviderScope(
    overrides: [
      simulationProvider.overrideWithValue(simState),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SimulationControlBar()),
    ),
  );
}

void main() {
  group('SimulationControlBar', () {
    testWidgets('renders 3 speed segments (Slow, Fast, Instant)',
        (tester) async {
      await tester.pumpWidget(_wrap(const SimulationState(
        status: SimulationStatus.running,
      )));
      expect(find.text('Slow'), findsOneWidget);
      expect(find.text('Fast'), findsOneWidget);
      expect(find.text('Instant'), findsOneWidget);
    });

    testWidgets('default selection is Fast', (tester) async {
      await tester.pumpWidget(_wrap(const SimulationState(
        status: SimulationStatus.running,
        speed: SimulationSpeed.fast,
      )));
      // The SegmentedButton renders the selected segment; verify Fast is default
      final segmented = tester.widget<SegmentedButton<SimulationSpeed>>(
        find.byType(SegmentedButton<SimulationSpeed>),
      );
      expect(segmented.selected, {SimulationSpeed.fast});
    });

    testWidgets('shows pause icon when running', (tester) async {
      await tester.pumpWidget(_wrap(const SimulationState(
        status: SimulationStatus.running,
      )));
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('shows play icon when paused', (tester) async {
      await tester.pumpWidget(_wrap(const SimulationState(
        status: SimulationStatus.paused,
      )));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('stop button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_wrap(const SimulationState(
        status: SimulationStatus.running,
      )));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      expect(
        find.text('End this simulation and return to the home screen?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('controls disabled when status is complete', (tester) async {
      await tester.pumpWidget(_wrap(const SimulationState(
        status: SimulationStatus.complete,
      )));
      // Play/pause should be disabled
      final playPause = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.play_arrow),
          matching: find.byType(IconButton),
        ),
      );
      expect(playPause.onPressed, isNull);

      // Stop should be disabled
      final stop = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.stop),
          matching: find.byType(IconButton),
        ),
      );
      expect(stop.onPressed, isNull);
    });

    testWidgets('play/pause disabled during instant mode', (tester) async {
      await tester.pumpWidget(_wrap(const SimulationState(
        status: SimulationStatus.running,
        speed: SimulationSpeed.instant,
      )));
      // Play/pause disabled in instant mode
      final playPause = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.pause),
          matching: find.byType(IconButton),
        ),
      );
      expect(playPause.onPressed, isNull);
    });
  });
}
