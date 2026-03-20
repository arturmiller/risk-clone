import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/simulation_provider.dart';
import 'package:risk_mobile/widgets/simulation_status_bar.dart';

// ignore_for_file: unused_import
import 'package:risk_mobile/engine/models/cards.dart';

class FakeGameNotifier extends GameNotifier {
  final GameState fakeState;
  FakeGameNotifier(this.fakeState);

  @override
  Future<GameState?> build() async => fakeState;
}

GameState _makeState({
  int currentPlayerIndex = 0,
  int turnNumber = 5,
  TurnPhase turnPhase = TurnPhase.attack,
}) {
  return GameState(
    currentPlayerIndex: currentPlayerIndex,
    turnNumber: turnNumber,
    turnPhase: turnPhase,
    territories: const {
      'Alaska': TerritoryState(owner: 0, armies: 5),
    },
    players: const [
      PlayerState(index: 0, name: 'Alice'),
      PlayerState(index: 1, name: 'Bob'),
      PlayerState(index: 2, name: 'Charlie'),
    ],
  );
}

Widget _wrap({
  required SimulationState simState,
  required GameState gameState,
}) {
  return ProviderScope(
    overrides: [
      simulationProvider.overrideWithValue(simState),
      gameProvider.overrideWith(() => FakeGameNotifier(gameState)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SimulationStatusBar()),
    ),
  );
}

void main() {
  group('SimulationStatusBar', () {
    testWidgets('shows turn number and player name', (tester) async {
      await tester.pumpWidget(_wrap(
        simState: const SimulationState(status: SimulationStatus.running),
        gameState: _makeState(turnNumber: 5),
      ));
      await tester.pump();
      expect(find.text('Turn 5'), findsOneWidget);
      expect(find.text("Alice's turn"), findsOneWidget);
    });

    testWidgets('shows color dot matching current player', (tester) async {
      await tester.pumpWidget(_wrap(
        simState: const SimulationState(status: SimulationStatus.running),
        gameState: _makeState(currentPlayerIndex: 1),
      ));
      await tester.pump();
      expect(find.text("Bob's turn"), findsOneWidget);
      // Find the color dot
      final dot = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      final decoration = dot.decoration as BoxDecoration;
      // Player 1 (Bob) = Blue = 0xFF1E88E5
      expect(decoration.color, const Color(0xFF1E88E5));
    });

    testWidgets('shows phase label (reinforce/attack/fortify)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        simState: const SimulationState(status: SimulationStatus.running),
        gameState: _makeState(turnPhase: TurnPhase.reinforce),
      ));
      await tester.pump();
      expect(find.text('Reinforce'), findsOneWidget);
    });

    testWidgets('shows "Paused" text when simulation is paused',
        (tester) async {
      await tester.pumpWidget(_wrap(
        simState: const SimulationState(status: SimulationStatus.paused),
        gameState: _makeState(turnNumber: 7),
      ));
      await tester.pump();
      expect(find.text('Paused - Turn 7'), findsOneWidget);
    });

    testWidgets('shows progress indicator in instant mode', (tester) async {
      await tester.pumpWidget(_wrap(
        simState: const SimulationState(
          status: SimulationStatus.running,
          speed: SimulationSpeed.instant,
        ),
        gameState: _makeState(turnNumber: 3),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simulating... Turn 3'), findsOneWidget);
    });
  });
}
