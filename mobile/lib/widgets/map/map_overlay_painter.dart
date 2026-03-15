import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../engine/models/game_state.dart';
import '../../engine/models/ui_state.dart';
import 'territory_data.dart';

class MapOverlayPainter extends CustomPainter {
  final GameState gameState;
  final UIState uiState;
  final Map<String, TerritoryGeometry> territoryData;

  const MapOverlayPainter({
    required this.gameState,
    required this.uiState,
    required this.territoryData,
  });

  static const double _svgWidth = 1200;
  static const double _svgHeight = 700;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _svgWidth;
    final scaleY = size.height / _svgHeight;
    canvas.scale(scaleX, scaleY);

    for (final entry in territoryData.entries) {
      final name = entry.key;
      final geom = entry.value;
      final ts = gameState.territories[name];
      if (ts == null) continue;

      // Fill with owner color
      canvas.drawRect(
        geom.rect,
        Paint()
          ..color = kPlayerColors[ts.owner % kPlayerColors.length]
          ..style = PaintingStyle.fill,
      );

      // Valid source tint (yellow)
      if (uiState.validSources.contains(name)) {
        canvas.drawRect(
          geom.rect,
          Paint()
            ..color = const Color(0x55FDD835)
            ..style = PaintingStyle.fill,
        );
      }

      // Valid target tint (green)
      if (uiState.validTargets.contains(name)) {
        canvas.drawRect(
          geom.rect,
          Paint()
            ..color = const Color(0x5543A047)
            ..style = PaintingStyle.fill,
        );
      }

      // Selection highlight (white overlay)
      if (name == uiState.selectedTerritory) {
        canvas.drawRect(
          geom.rect,
          Paint()
            ..color = const Color(0x66FFFFFF)
            ..style = PaintingStyle.fill,
        );
      }

      // Army count label
      final tp = TextPainter(
        text: TextSpan(
          text: '${ts.armies}',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        geom.labelOffset - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(MapOverlayPainter old) =>
      old.gameState != gameState || old.uiState != uiState;
}
