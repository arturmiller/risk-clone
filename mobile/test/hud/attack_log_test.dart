import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/log_entry.dart';
import 'package:risk_mobile/hud/models.dart';
import 'package:risk_mobile/hud/widgets/attack_log.dart';
import 'package:risk_mobile/providers/game_log_provider.dart';

const _theme = HudTheme(
  background: '#000', border: '#111', text: '#FFB300', borderRadius: 10,
);

class _FakeLog extends GameLog {
  final List<LogEntry> _e;
  _FakeLog(this._e);
  @override
  List<LogEntry> build() => _e;
}

void main() {
  testWidgets('renders up to maxItems most recent log lines', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        gameLogProvider.overrideWith(() => _FakeLog([
              LogEntry(message: 'one', timestamp: DateTime(2026)),
              LogEntry(message: 'two', timestamp: DateTime(2026)),
              LogEntry(message: 'three', timestamp: DateTime(2026)),
              LogEntry(message: 'four', timestamp: DateTime(2026)),
              LogEntry(message: 'five', timestamp: DateTime(2026)),
            ])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AttackLogWidget(
            element: const HudList(
              id: 'log', maxItems: 3, itemBinding: 'game.battleLog', row: 0, col: 0,
            ),
            theme: _theme,
          ),
        ),
      ),
    ));
    expect(find.text('three'), findsOneWidget);
    expect(find.text('four'), findsOneWidget);
    expect(find.text('five'), findsOneWidget);
    expect(find.text('one'), findsNothing);
  });
}
