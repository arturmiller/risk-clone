import 'dart:ui';

/// Geometry for a single territory: polygon path, bounding rect, and label center.
class TerritoryGeometry {
  final List<Offset> polygon;
  final Rect rect;
  final Offset labelOffset;
  final Color? baseColor;

  TerritoryGeometry({
    required this.polygon,
    required this.labelOffset,
    this.baseColor,
  }) : rect = _boundingRect(polygon);

  static Rect _boundingRect(List<Offset> pts) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Path toPath() {
    final path = Path();
    if (polygon.isEmpty) return path;
    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(polygon[i].dx, polygon[i].dy);
    }
    path.close();
    return path;
  }
}

/// Six player colors, indexed 0-5.
const List<Color> kPlayerColors = [
  Color(0xFFE53935), // P0 - Red
  Color(0xFF1E88E5), // P1 - Blue
  Color(0xFF43A047), // P2 - Green
  Color(0xFFFDD835), // P3 - Yellow
  Color(0xFF8E24AA), // P4 - Purple
  Color(0xFFFF7043), // P5 - Orange
];

/// Ray-casting point-in-polygon test.
bool pointInPolygon(Offset point, List<Offset> polygon) {
  bool inside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].dx, yi = polygon[i].dy;
    final xj = polygon[j].dx, yj = polygon[j].dy;
    if (((yi > point.dy) != (yj > point.dy)) &&
        (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}
