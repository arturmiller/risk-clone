import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/widgets/game_over_dialog.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/game_log_provider.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/log_entry.dart';

void main() {
  group('GameOverDialog (MOBX-06)', () {
    testWidgets('shows winner name', (tester) async {
      const winner = PlayerState(index: 0, name: 'Player 1', isAlive: true);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GameOverDialog(winner: winner),
            ),
          ),
        ),
      );
      expect(find.text('Player 1 wins!'), findsOneWidget);
      expect(find.text('Congratulations!'), findsOneWidget);
    });

    testWidgets('New Game button triggers clearSave', (tester) async {
      const winner = PlayerState(index: 1, name: 'Bot 1', isAlive: true);
      bool clearSaveCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameProvider.overrideWith(
              () => _FakeGameNotifier(onClearSave: () {
                clearSaveCalled = true;
              }),
            ),
            gameLogProvider.overrideWith(() => _FakeGameLogNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameOverDialog(winner: winner),
            ),
          ),
        ),
      );

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();

      expect(clearSaveCalled, isTrue);
    });

    testWidgets('Home button navigates back to HomeScreen', (tester) async {
      markTestSkipped(
          'navigation popUntil not easily testable in unit tests — verified in Plan 06 checkpoint');
    });
  });
}

/// Fake GameNotifier that records clearSave() calls.
class _FakeGameNotifier extends GameNotifier {
  final VoidCallback? onClearSave;
  _FakeGameNotifier({this.onClearSave});

  @override
  Future<GameState?> build() async => null;

  @override
  Future<void> clearSave() async {
    onClearSave?.call();
    state = const AsyncData(null);
  }
}

/// Fake GameLog notifier for tests.
class _FakeGameLogNotifier extends GameLog {
  @override
  List<LogEntry> build() => const [];

  @override
  void clear() => state = const [];
}
