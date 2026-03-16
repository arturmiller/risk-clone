import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: unused_import
import 'package:risk_mobile/providers/game_log_provider.dart';

void main() {
  group('GameLog widget (MOBX-04)', () {
    testWidgets('renders empty state with no entries', (tester) async {
      markTestSkipped('not yet implemented — Phase 11 Plan 04');
    });

    testWidgets('renders list of LogEntry messages', (tester) async {
      markTestSkipped('not yet implemented — Phase 11 Plan 04');
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
