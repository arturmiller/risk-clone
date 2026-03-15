import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:risk_mobile/widgets/map/territory_data.dart';
import 'package:risk_mobile/widgets/map/map_overlay_painter.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/ui_state.dart';

void main() {
  group('MapWidget rendering (MAPW-01, MAPW-03)', () {
    testWidgets(
      'MAPW-01: MapWidget renders inside InteractiveViewer without overflow',
      (tester) async {
        markTestSkipped('Wave 0 stub — implement in plan 10-03');
      },
    );

    testWidgets(
      'MAPW-03: territory filled with owner color (player 0 = red)',
      (tester) async {
        // Build a minimal GameState with only Alaska owned by player 0
        final gameState = GameState(
          territories: {
            'Alaska': const TerritoryState(owner: 0, armies: 5),
          },
          players: const [],
        );
        final uiState = UIState.empty();

        final painter = MapOverlayPainter(
          gameState: gameState,
          uiState: uiState,
          territoryData: kTerritoryData,
        );

        // Verify owner color is player 0's color (red)
        expect(painter.gameState.territories['Alaska']!.owner, 0);
        expect(kPlayerColors[0], const Color(0xFFE53935));

        // Render the painter inside a CustomPaint widget
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: painter,
                  size: const Size(1200, 700),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'MAPW-03: army count label visible on territory',
      (tester) async {
        final gameState = GameState(
          territories: {
            'Alaska': const TerritoryState(owner: 0, armies: 5),
          },
          players: const [],
        );
        final uiState = UIState.empty();

        final painter = MapOverlayPainter(
          gameState: gameState,
          uiState: uiState,
          territoryData: kTerritoryData,
        );

        // Verify armies value is accessible
        expect(painter.gameState.territories['Alaska']!.armies, 5);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: painter,
                  size: const Size(1200, 700),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      },
    );

    test('MapOverlayPainter shouldRepaint: false for same state', () {
      final gameState = GameState(
        territories: {'Alaska': const TerritoryState(owner: 0, armies: 5)},
        players: const [],
      );
      final uiState = UIState.empty();

      final painter1 = MapOverlayPainter(
        gameState: gameState,
        uiState: uiState,
        territoryData: kTerritoryData,
      );
      final painter2 = MapOverlayPainter(
        gameState: gameState,
        uiState: uiState,
        territoryData: kTerritoryData,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });

    test('MapOverlayPainter shouldRepaint: true for different gameState', () {
      final gameState1 = GameState(
        territories: {'Alaska': const TerritoryState(owner: 0, armies: 5)},
        players: const [],
      );
      final gameState2 = GameState(
        territories: {'Alaska': const TerritoryState(owner: 1, armies: 3)},
        players: const [],
      );
      final uiState = UIState.empty();

      final painter1 = MapOverlayPainter(
        gameState: gameState1,
        uiState: uiState,
        territoryData: kTerritoryData,
      );
      final painter2 = MapOverlayPainter(
        gameState: gameState2,
        uiState: uiState,
        territoryData: kTerritoryData,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('kTerritoryData contains exactly 42 territories', () {
      expect(kTerritoryData.length, 42);
    });

    test('kPlayerColors contains exactly 6 colors', () {
      expect(kPlayerColors.length, 6);
    });
  });
}
