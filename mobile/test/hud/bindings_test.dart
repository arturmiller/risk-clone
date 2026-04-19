import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/log_entry.dart';
import 'package:risk_mobile/hud/bindings.dart';
import 'package:risk_mobile/providers/game_log_provider.dart';
import 'package:risk_mobile/providers/game_provider.dart';

class _Probe extends ConsumerWidget {
  final String path;
  final void Function(Object?) onResolved;
  const _Probe({required this.path, required this.onResolved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onResolved(resolveBinding(path, ref));
    return const SizedBox();
  }
}

// Override is a sealed class not exported from flutter_riverpod v3 public API;
// use dynamic as the list element type so the parameter accepts the real values.
Future<Object?> _resolve(WidgetTester t, String path, List<dynamic> overrides) async {
  Object? captured;
  await t.pumpWidget(
    ProviderScope(
      // ignore: invalid_use_of_internal_member
      overrides: List.castFrom(overrides),
      child: _Probe(path: path, onResolved: (v) => captured = v),
    ),
  );
  // Pump once more so async notifiers (e.g. gameProvider) can resolve.
  await t.pump();
  return captured;
}

void main() {
  final testState = GameState(
    territories: const {},
    players: const [
      PlayerState(index: 0, name: 'Alice'),
      PlayerState(index: 1, name: 'Bot'),
    ],
    currentPlayerIndex: 0,
    turnPhase: TurnPhase.attack,
  );

  testWidgets('players[0].name', (t) async {
    final result = await _resolve(t, 'players[0].name', [
      gameProvider.overrideWith(() => _FakeGame(testState)),
    ]);
    expect(result, 'Alice');
  });

  testWidgets('players[1].name', (t) async {
    final result = await _resolve(t, 'players[1].name', [
      gameProvider.overrideWith(() => _FakeGame(testState)),
    ]);
    expect(result, 'Bot');
  });

  testWidgets('game.phaseLabel for attack', (t) async {
    final result = await _resolve(t, 'game.phaseLabel', [
      gameProvider.overrideWith(() => _FakeGame(testState)),
    ]);
    expect(result, 'ATTACK PHASE');
  });

  testWidgets('game.battleLog returns log entry strings', (t) async {
    final result = await _resolve(t, 'game.battleLog', [
      gameLogProvider.overrideWith(() => _FakeLog([
            LogEntry(message: 'A attacked B', timestamp: DateTime(2026)),
            LogEntry(message: 'B lost', timestamp: DateTime(2026)),
          ])),
    ]);
    expect(result, ['A attacked B', 'B lost']);
  });

  testWidgets('ui.diceCount returns a number', (t) async {
    final result = await _resolve(t, 'ui.diceCount', []);
    expect(result, isA<int>());
  });

  testWidgets('unknown path returns null', (t) async {
    final result = await _resolve(t, 'some.bogus.path', []);
    expect(result, isNull);
  });
}

class _FakeGame extends GameNotifier {
  final GameState _s;
  _FakeGame(this._s);
  @override
  Future<GameState?> build() async => _s;
}

class _FakeLog extends GameLog {
  final List<LogEntry> _entries;
  _FakeLog(this._entries);
  @override
  List<LogEntry> build() => _entries;
}
