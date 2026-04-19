import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/hud/hud_renderer.dart';
import 'package:risk_mobile/providers/game_provider.dart';

class _FakeGame extends GameNotifier {
  final GameState _s;
  _FakeGame(this._s);
  @override
  Future<GameState?> build() async => _s;
}

GameState _fixture() => const GameState(
      territories: {
        'Alaska': TerritoryState(owner: 0, armies: 3),
        'Siberia': TerritoryState(owner: 1, armies: 2),
      },
      players: [
        PlayerState(index: 0, name: 'Player 1'),
        PlayerState(index: 1, name: 'Bot Player'),
      ],
      currentPlayerIndex: 0,
      turnPhase: TurnPhase.attack,
    );

void main() {
  testWidgets('mobile-landscape golden', (t) async {
    await t.binding.setSurfaceSize(const Size(844, 390));
    await t.pumpWidget(ProviderScope(
      // ignore: invalid_use_of_internal_member
      overrides: List.castFrom([
        gameProvider.overrideWith(() => _FakeGame(_fixture())),
      ]),
      child: const MaterialApp(home: Scaffold(body: HudRenderer())),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byType(HudRenderer),
      matchesGoldenFile('goldens/hud_mobile_landscape.png'),
    );
  });

  testWidgets('desktop-landscape golden', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 700));
    await t.pumpWidget(ProviderScope(
      // ignore: invalid_use_of_internal_member
      overrides: List.castFrom([
        gameProvider.overrideWith(() => _FakeGame(_fixture())),
      ]),
      child: const MaterialApp(home: Scaffold(body: HudRenderer())),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byType(HudRenderer),
      matchesGoldenFile('goldens/hud_desktop_landscape.png'),
    );
  });
}
