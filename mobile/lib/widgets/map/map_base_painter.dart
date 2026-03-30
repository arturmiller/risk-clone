import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'territory_data.dart';

class MapBasePainter extends CustomPainter {
  final Map<String, TerritoryGeometry> territoryData;
  final Size canvasSize;

  const MapBasePainter({
    required this.territoryData,
    this.canvasSize = const Size(1200, 700),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / canvasSize.width;
    final scaleY = size.height / canvasSize.height;
    canvas.scale(scaleX, scaleY);

    final borderPaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final entry in territoryData.entries) {
      final geom = entry.value;
      final path = geom.toPath();

      // Fill with territory base color or default gray
      final fillPaint = Paint()
        ..color = geom.baseColor ?? const Color(0xFFCFD8DC)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(MapBasePainter old) =>
      old.territoryData != territoryData;
}
