import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../engine/models/game_state.dart';
import '../../engine/models/ui_state.dart';
import 'territory_data.dart';

class MapOverlayPainter extends CustomPainter {
  final GameState gameState;
  final UIState uiState;
  final Map<String, TerritoryGeometry> territoryData;
  final Size canvasSize;

  const MapOverlayPainter({
    required this.gameState,
    required this.uiState,
    required this.territoryData,
    this.canvasSize = const Size(1200, 700),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / canvasSize.width;
    final scaleY = size.height / canvasSize.height;
    canvas.scale(scaleX, scaleY);

    for (final entry in territoryData.entries) {
      final name = entry.key;
      final geom = entry.value;
      final ts = gameState.territories[name];
      if (ts == null) continue;

      final path = geom.toPath();

      // Selected attacker: thick border
      if (name == uiState.selectedTerritory) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF000000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );
      }

      // Valid target highlight
      if (uiState.validTargets.contains(name)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
      }

      // Army count label with player-colored circle background
      final proposed = uiState.proposedPlacements[name] ?? 0;
      final tp = TextPainter(
        text: TextSpan(
          text: '${ts.armies}${proposed > 0 ? ' +$proposed' : ''}',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw filled circle in player color behind the army count
      final playerColor = kPlayerColors[ts.owner % kPlayerColors.length];
      final circleRadius = math.max(tp.width, tp.height) / 2 + 4;
      canvas.drawCircle(
        geom.labelOffset,
        circleRadius,
        Paint()..color = playerColor,
      );
      // Circle border for contrast
      canvas.drawCircle(
        geom.labelOffset,
        circleRadius,
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      tp.paint(
        canvas,
        geom.labelOffset - Offset(tp.width / 2, tp.height / 2),
      );
    }

    // Draw arrow from attacker to target
    if (uiState.selectedTerritory != null && uiState.selectedTarget != null) {
      final sourceGeom = territoryData[uiState.selectedTerritory];
      final targetGeom = territoryData[uiState.selectedTarget];
      if (sourceGeom != null && targetGeom != null) {
        _drawArrow(canvas, sourceGeom.labelOffset, targetGeom.labelOffset);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to) {
    final arrowPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final arrowHeadPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.fill;

    final direction = (to - from);
    final distance = direction.distance;
    if (distance < 1) return;
    final unit = direction / distance;
    final shortenedFrom = from + unit * 12;
    final shortenedTo = to - unit * 12;

    canvas.drawLine(shortenedFrom, shortenedTo, arrowPaint);

    const headLength = 12.0;
    const headAngle = 0.45;
    final angle = math.atan2(unit.dy, unit.dx);
    final p1 = shortenedTo -
        Offset(
          headLength * math.cos(angle - headAngle),
          headLength * math.sin(angle - headAngle),
        );
    final p2 = shortenedTo -
        Offset(
          headLength * math.cos(angle + headAngle),
          headLength * math.sin(angle + headAngle),
        );

    final arrowPath = Path()
      ..moveTo(shortenedTo.dx, shortenedTo.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(arrowPath, arrowHeadPaint);
  }

  @override
  bool shouldRepaint(MapOverlayPainter old) =>
      old.gameState != gameState || old.uiState != uiState;
}
