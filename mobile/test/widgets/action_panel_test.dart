import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/widgets/action_panel.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/ui_provider.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/cards.dart';

// ignore_for_file: unused_import

/// Minimal fake GameNotifier that returns a fixed AsyncData<GameState?>.
class FakeGameNotifier extends GameNotifier {
  final GameState fakeState;
  FakeGameNotifier(this.fakeState);

  @override
  Future<GameState?> build() async => fakeState;
}

/// Builds a minimal GameState with the given TurnPhase.
GameState _makeState(TurnPhase phase) {
  return GameState(
    turnPhase: phase,
    territories: {
      'Alaska': const TerritoryState(owner: 0, armies: 5),
      'Alberta': const TerritoryState(owner: 1, armies: 2),
    },
    players: [
      const PlayerState(index: 0, name: 'Human'),
      const PlayerState(index: 1, name: 'Bot'),
    ],
  );
}

void main() {
  group('ActionPanel (MOBX-03)', () {
    testWidgets('shows reinforce controls when turnPhase == reinforce',
        (tester) async {
      final fakeState = _makeState(TurnPhase.reinforce);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameProvider.overrideWith(() => FakeGameNotifier(fakeState)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ActionPanel()),
          ),
        ),
      );
      await tester.pump(); // allow async build
      expect(find.textContaining('Armies to place'), findsOneWidget);
      expect(find.text('Confirm Placement'), findsOneWidget);
    });

    testWidgets(
        'shows attack controls (dice selector, end attack) when turnPhase == attack',
        (tester) async {
      final fakeState = _makeState(TurnPhase.attack);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameProvider.overrideWith(() => FakeGameNotifier(fakeState)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ActionPanel()),
          ),
        ),
      );
      await tester.pump();
      // SegmentedButton with dice values
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('End Attack'), findsOneWidget);
    });

    testWidgets('shows fortify controls (skip fortify) when turnPhase == fortify',
        (tester) async {
      final fakeState = _makeState(TurnPhase.fortify);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameProvider.overrideWith(() => FakeGameNotifier(fakeState)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ActionPanel()),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Skip Fortify'), findsOneWidget);
    });

    testWidgets('Blitz button dispatches BlitzAction via humanMove',
        (tester) async {
      markTestSkipped('Blitz dispatch tested in Plan 06 integration checkpoint');
    });
  });
}
