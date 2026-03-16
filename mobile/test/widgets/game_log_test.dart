import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: unused_import
import 'package:risk_mobile/providers/game_log_provider.dart';
import 'package:risk_mobile/widgets/game_log.dart';
import 'package:risk_mobile/engine/models/log_entry.dart';

void main() {
  group('GameLog widget (MOBX-04)', () {
    testWidgets('renders empty state with no entries', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: GameLogWidget())),
        ),
      );
      expect(find.text('No events yet'), findsOneWidget);
    });

    testWidgets('renders list of LogEntry messages', (tester) async {
      final entries = [
        LogEntry(message: 'Player 1 attacked Alaska', timestamp: DateTime.now()),
        LogEntry(message: 'Player 2 reinforced Brazil', timestamp: DateTime.now()),
        LogEntry(message: 'Blitz! Player 1 conquered Egypt', timestamp: DateTime.now()),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameLogProvider.overrideWith(() {
              final notifier = GameLog();
              for (final e in entries) {
                // Schedule state update after build
              }
              return notifier;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: GameLogWidget())),
        ),
      );

      // Use a container to inject entries directly
      final container = ProviderContainer(
        overrides: [
          gameLogProvider.overrideWith(
            () => _FakeGameLog(entries),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: GameLogWidget())),
        ),
      );

      expect(find.text('Player 1 attacked Alaska'), findsOneWidget);
      expect(find.text('Player 2 reinforced Brazil'), findsOneWidget);
      expect(find.text('Blitz! Player 1 conquered Egypt'), findsOneWidget);
    });

    test('gameLogProvider accumulates entries via add()', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(gameLogProvider), isEmpty);
      container.read(gameLogProvider.notifier).add('Player 1 attacked');
      expect(container.read(gameLogProvider), hasLength(1));
      expect(container.read(gameLogProvider).first.message, 'Player 1 attacked');
    });

    test('gameLogProvider resets to empty via clear()', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameLogProvider.notifier).add('entry 1');
      container.read(gameLogProvider.notifier).add('entry 2');
      container.read(gameLogProvider.notifier).add('entry 3');
      expect(container.read(gameLogProvider), hasLength(3));
      container.read(gameLogProvider.notifier).clear();
      expect(container.read(gameLogProvider), isEmpty);
    });
  });
}

/// Fake GameLog notifier that starts with a preset list of entries.
class _FakeGameLog extends GameLog {
  final List<LogEntry> _initialEntries;
  _FakeGameLog(this._initialEntries);

  @override
  List<LogEntry> build() => _initialEntries;
}
