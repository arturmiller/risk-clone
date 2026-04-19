import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/hud/hud_renderer.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/map_provider.dart';
import 'package:risk_mobile/screens/game_screen.dart';
import 'package:risk_mobile/widgets/map/territory_data.dart';

class _FakeGame extends GameNotifier {
  @override
  Future<GameState?> build() async => const GameState(
        territories: {},
        players: [
          PlayerState(index: 0, name: 'P1'),
          PlayerState(index: 1, name: 'P2'),
        ],
      );
}

LoadedMap _fakeLoadedMap() {
  const mapJson = {
    'name': 'Smoke',
    'territories': <String>[],
    'continents': <dynamic>[],
    'adjacencies': <dynamic>[],
  };
  final mapData = MapData(
    name: 'Smoke',
    territories: const [],
    continents: const [],
    adjacencies: const [],
  );
  return LoadedMap(
    graph: MapGraph(mapData),
    territoryData: const <String, TerritoryGeometry>{},
    canvasSize: const Size(100, 100),
    name: 'Smoke',
  );
}

void main() {
  testWidgets('GameScreen renders HudRenderer and does not throw', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 700));
    await t.pumpWidget(ProviderScope(
      // ignore: invalid_use_of_internal_member
      overrides: List.castFrom([
        gameProvider.overrideWith(() => _FakeGame()),
        loadedMapProvider.overrideWith((ref, arg) => Future.value(_fakeLoadedMap())),
      ]),
      child: const MaterialApp(home: GameScreen(gameMode: GameMode.vsBot)),
    ));
    await t.pumpAndSettle();
    expect(find.byType(HudRenderer), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
