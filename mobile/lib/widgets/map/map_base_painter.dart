import 'package:flutter/rendering.dart';
import 'territory_data.dart';

class MapBasePainter extends CustomPainter {
  final Map<String, TerritoryGeometry> territoryData;

  const MapBasePainter({required this.territoryData});

  static const double _svgWidth = 1200;
  static const double _svgHeight = 700;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _svgWidth;
    final scaleY = size.height / _svgHeight;
    canvas.scale(scaleX, scaleY);

    final fillPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final geom in territoryData.values) {
      canvas.drawRect(geom.rect, fillPaint);
      canvas.drawRect(geom.rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(MapBasePainter old) => false;
}
