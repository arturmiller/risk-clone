import 'dart:ui';

/// Geometry for a single territory: bounding rect and label center.
class TerritoryGeometry {
  final Rect rect;
  final Offset labelOffset;
  const TerritoryGeometry({required this.rect, required this.labelOffset});
}

/// Six player colors, indexed 0–5.
const List<Color> kPlayerColors = [
  Color(0xFFE53935), // P0 — Red
  Color(0xFF1E88E5), // P1 — Blue
  Color(0xFF43A047), // P2 — Green
  Color(0xFFFDD835), // P3 — Yellow
  Color(0xFF8E24AA), // P4 — Purple
  Color(0xFFFF7043), // P5 — Orange
];

/// All 42 territory geometries in the classic Risk map.
///
/// Keys match the territory name strings in `assets/classic.json` exactly.
/// Coordinate space: SVG viewBox 0 0 1200 700.
const Map<String, TerritoryGeometry> kTerritoryData = {
  // ── North America ──────────────────────────────────────────────────────────
  'Alaska': TerritoryGeometry(
    rect: Rect.fromLTWH(30, 60, 60, 50),
    labelOffset: Offset(60, 85),
  ),
  'Northwest Territory': TerritoryGeometry(
    rect: Rect.fromLTWH(100, 45, 100, 50),
    labelOffset: Offset(150, 70),
  ),
  'Greenland': TerritoryGeometry(
    rect: Rect.fromLTWH(260, 30, 90, 60),
    labelOffset: Offset(305, 60),
  ),
  'Alberta': TerritoryGeometry(
    rect: Rect.fromLTWH(70, 120, 70, 55),
    labelOffset: Offset(105, 147),
  ),
  'Ontario': TerritoryGeometry(
    rect: Rect.fromLTWH(150, 105, 80, 65),
    labelOffset: Offset(190, 137),
  ),
  'Quebec': TerritoryGeometry(
    rect: Rect.fromLTWH(240, 100, 70, 65),
    labelOffset: Offset(275, 132),
  ),
  'Western United States': TerritoryGeometry(
    rect: Rect.fromLTWH(60, 185, 85, 65),
    labelOffset: Offset(102, 217),
  ),
  'Eastern United States': TerritoryGeometry(
    rect: Rect.fromLTWH(155, 175, 95, 80),
    labelOffset: Offset(202, 215),
  ),
  'Central America': TerritoryGeometry(
    rect: Rect.fromLTWH(100, 260, 85, 65),
    labelOffset: Offset(142, 292),
  ),

  // ── South America ──────────────────────────────────────────────────────────
  'Venezuela': TerritoryGeometry(
    rect: Rect.fromLTWH(160, 340, 95, 55),
    labelOffset: Offset(207, 367),
  ),
  'Peru': TerritoryGeometry(
    rect: Rect.fromLTWH(145, 405, 75, 70),
    labelOffset: Offset(182, 440),
  ),
  'Brazil': TerritoryGeometry(
    rect: Rect.fromLTWH(230, 390, 90, 80),
    labelOffset: Offset(275, 430),
  ),
  'Argentina': TerritoryGeometry(
    rect: Rect.fromLTWH(170, 485, 90, 85),
    labelOffset: Offset(215, 527),
  ),

  // ── Africa ─────────────────────────────────────────────────────────────────
  'North Africa': TerritoryGeometry(
    rect: Rect.fromLTWH(400, 295, 110, 80),
    labelOffset: Offset(455, 335),
  ),
  'Egypt': TerritoryGeometry(
    rect: Rect.fromLTWH(520, 285, 90, 65),
    labelOffset: Offset(565, 317),
  ),
  'East Africa': TerritoryGeometry(
    rect: Rect.fromLTWH(545, 360, 85, 85),
    labelOffset: Offset(587, 402),
  ),
  'Congo': TerritoryGeometry(
    rect: Rect.fromLTWH(460, 385, 75, 75),
    labelOffset: Offset(497, 422),
  ),
  'South Africa': TerritoryGeometry(
    rect: Rect.fromLTWH(480, 470, 95, 85),
    labelOffset: Offset(527, 512),
  ),
  'Madagascar': TerritoryGeometry(
    rect: Rect.fromLTWH(620, 470, 60, 70),
    labelOffset: Offset(650, 505),
  ),

  // ── Europe ─────────────────────────────────────────────────────────────────
  'Iceland': TerritoryGeometry(
    rect: Rect.fromLTWH(400, 65, 60, 45),
    labelOffset: Offset(430, 87),
  ),
  'Scandinavia': TerritoryGeometry(
    rect: Rect.fromLTWH(500, 60, 75, 65),
    labelOffset: Offset(537, 92),
  ),
  'Ukraine': TerritoryGeometry(
    rect: Rect.fromLTWH(585, 70, 95, 105),
    labelOffset: Offset(632, 122),
  ),
  'Great Britain': TerritoryGeometry(
    rect: Rect.fromLTWH(405, 125, 70, 60),
    labelOffset: Offset(440, 155),
  ),
  'Northern Europe': TerritoryGeometry(
    rect: Rect.fromLTWH(485, 135, 90, 60),
    labelOffset: Offset(530, 165),
  ),
  'Southern Europe': TerritoryGeometry(
    rect: Rect.fromLTWH(490, 205, 90, 65),
    labelOffset: Offset(535, 237),
  ),
  'Western Europe': TerritoryGeometry(
    rect: Rect.fromLTWH(400, 200, 80, 80),
    labelOffset: Offset(440, 240),
  ),

  // ── Asia ───────────────────────────────────────────────────────────────────
  'Ural': TerritoryGeometry(
    rect: Rect.fromLTWH(700, 60, 70, 80),
    labelOffset: Offset(735, 100),
  ),
  'Siberia': TerritoryGeometry(
    rect: Rect.fromLTWH(780, 45, 70, 80),
    labelOffset: Offset(815, 85),
  ),
  'Yakutsk': TerritoryGeometry(
    rect: Rect.fromLTWH(860, 40, 85, 60),
    labelOffset: Offset(902, 70),
  ),
  'Kamchatka': TerritoryGeometry(
    rect: Rect.fromLTWH(955, 35, 85, 70),
    labelOffset: Offset(997, 70),
  ),
  'Irkutsk': TerritoryGeometry(
    rect: Rect.fromLTWH(870, 110, 80, 60),
    labelOffset: Offset(910, 140),
  ),
  'Mongolia': TerritoryGeometry(
    rect: Rect.fromLTWH(880, 180, 95, 60),
    labelOffset: Offset(927, 210),
  ),
  'Japan': TerritoryGeometry(
    rect: Rect.fromLTWH(1000, 150, 60, 70),
    labelOffset: Offset(1030, 185),
  ),
  'Afghanistan': TerritoryGeometry(
    rect: Rect.fromLTWH(700, 150, 90, 65),
    labelOffset: Offset(745, 182),
  ),
  'China': TerritoryGeometry(
    rect: Rect.fromLTWH(800, 180, 70, 80),
    labelOffset: Offset(835, 220),
  ),
  'Middle East': TerritoryGeometry(
    rect: Rect.fromLTWH(620, 195, 100, 85),
    labelOffset: Offset(670, 237),
  ),
  'India': TerritoryGeometry(
    rect: Rect.fromLTWH(750, 225, 80, 85),
    labelOffset: Offset(790, 267),
  ),
  'Siam': TerritoryGeometry(
    rect: Rect.fromLTWH(840, 270, 70, 75),
    labelOffset: Offset(875, 307),
  ),

  // ── Australia ──────────────────────────────────────────────────────────────
  'Indonesia': TerritoryGeometry(
    rect: Rect.fromLTWH(880, 385, 80, 60),
    labelOffset: Offset(920, 415),
  ),
  'New Guinea': TerritoryGeometry(
    rect: Rect.fromLTWH(1000, 380, 85, 50),
    labelOffset: Offset(1042, 405),
  ),
  'Western Australia': TerritoryGeometry(
    rect: Rect.fromLTWH(900, 460, 85, 80),
    labelOffset: Offset(942, 500),
  ),
  'Eastern Australia': TerritoryGeometry(
    rect: Rect.fromLTWH(1010, 445, 85, 95),
    labelOffset: Offset(1052, 492),
  ),
};
