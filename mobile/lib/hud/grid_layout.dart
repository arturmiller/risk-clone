import 'package:flutter/material.dart';

/// Marker widget wrapping each grid child with its placement info.
class HudGridCell extends StatelessWidget {
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
  final String? alignSelf;
  final String? justifySelf;
  final Widget child;

  const HudGridCell({
    super.key,
    required this.row,
    required this.col,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.alignSelf,
    this.justifySelf,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}

class HudGridLayout extends StatelessWidget {
  final List<String> rows;
  final List<String> cols;
  final double gap;
  final List<Widget> children; // each must be a LayoutId wrapping a HudGridCell

  const HudGridLayout({
    super.key,
    required this.rows,
    required this.cols,
    required this.gap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _HudGridDelegate(
        rows: rows,
        cols: cols,
        gap: gap,
        cells: _collectCells(children),
      ),
      children: children,
    );
  }

  List<_CellInfo> _collectCells(List<Widget> children) {
    return children.map((w) {
      if (w is! LayoutId) {
        throw StateError('HudGridLayout children must be LayoutId-wrapped');
      }
      final cell = _findCell(w.child);
      return _CellInfo(
        id: w.id,
        row: cell.row,
        col: cell.col,
        rowSpan: cell.rowSpan,
        colSpan: cell.colSpan,
        alignSelf: cell.alignSelf,
        justifySelf: cell.justifySelf,
      );
    }).toList();
  }

  HudGridCell _findCell(Widget w) {
    if (w is HudGridCell) return w;
    throw StateError('LayoutId child must be HudGridCell (got ${w.runtimeType})');
  }
}

class _CellInfo {
  final Object id;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
  final String? alignSelf;
  final String? justifySelf;

  _CellInfo({
    required this.id,
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
    this.alignSelf,
    this.justifySelf,
  });
}

class _HudGridDelegate extends MultiChildLayoutDelegate {
  final List<String> rows;
  final List<String> cols;
  final double gap;
  final List<_CellInfo> cells;

  _HudGridDelegate({
    required this.rows,
    required this.cols,
    required this.gap,
    required this.cells,
  });

  @override
  void performLayout(Size size) {
    final double totalColGap = gap * (cols.length - 1);
    final double totalRowGap = gap * (rows.length - 1);
    final double availW = size.width - totalColGap;
    final double availH = size.height - totalRowGap;

    // Step 1: first pass — resolve px tracks; mark fr tracks with negative
    // sentinel (-fr value); auto tracks start at 0.
    final colSizes = _firstPassTracks(cols);
    final rowSizes = _firstPassTracks(rows);

    // We need col widths when sizing auto rows, and row heights when sizing
    // auto cols. Use a preliminary fr distribution for this estimate — the fr
    // sizes are re-computed from scratch after auto sizing (step 3).
    final colEstimate = List<double>.of(colSizes);
    final rowEstimate = List<double>.of(rowSizes);
    _applyFrTracks(colEstimate, availW);
    _applyFrTracks(rowEstimate, availH);

    // Cells laid out in this pass: id → measured Size (for positioning later).
    final Map<Object, Size> autoMeasured = {};

    // Auto rows: for each auto row, find cells that span only that single row.
    for (int ri = 0; ri < rows.length; ri++) {
      if (rows[ri].trim() != 'auto') continue;
      double maxH = 0;
      for (final cell in cells) {
        if (cell.row != ri || cell.rowSpan != 1) continue;
        double w = 0;
        for (int ci = 0; ci < cell.colSpan; ci++) {
          w += colEstimate[cell.col + ci];
          if (ci > 0) w += gap;
        }
        final measured = layoutChild(
          cell.id,
          // Use availH as the upper bound so nested layouts get finite constraints.
          BoxConstraints(
            maxWidth: w.clamp(0.0, double.infinity),
            maxHeight: availH.clamp(0.0, double.infinity),
          ),
        );
        autoMeasured[cell.id] = measured;
        if (measured.height > maxH) maxH = measured.height;
      }
      rowSizes[ri] = maxH;
    }

    // Auto cols: for each auto col, find cells that span only that single col.
    for (int ci = 0; ci < cols.length; ci++) {
      if (cols[ci].trim() != 'auto') continue;
      double maxW = 0;
      for (final cell in cells) {
        if (autoMeasured.containsKey(cell.id)) continue;
        if (cell.col != ci || cell.colSpan != 1) continue;
        double h = 0;
        for (int ri = 0; ri < cell.rowSpan; ri++) {
          h += rowEstimate[cell.row + ri];
          if (ri > 0) h += gap;
        }
        final measured = layoutChild(
          cell.id,
          // Use availW as the upper bound so nested layouts get finite constraints.
          BoxConstraints(
            maxHeight: h.clamp(0.0, double.infinity),
            maxWidth: availW.clamp(0.0, double.infinity),
          ),
        );
        autoMeasured[cell.id] = measured;
        if (measured.width > maxW) maxW = measured.width;
      }
      colSizes[ci] = maxW;
    }

    // Step 3: distribute fr tracks using the now-settled auto sizes.
    // colSizes/rowSizes still hold negative sentinels for fr tracks.
    _applyFrTracks(colSizes, availW);
    _applyFrTracks(rowSizes, availH);

    // Step 4: final layout pass — position all children.
    final colOffsets = _cumulative(colSizes, gap);
    final rowOffsets = _cumulative(rowSizes, gap);

    for (final cell in cells) {
      final x = colOffsets[cell.col];
      final y = rowOffsets[cell.row];
      double w = 0;
      double h = 0;
      for (int i = 0; i < cell.colSpan; i++) {
        w += colSizes[cell.col + i];
        if (i > 0) w += gap;
      }
      for (int i = 0; i < cell.rowSpan; i++) {
        h += rowSizes[cell.row + i];
        if (i > 0) h += gap;
      }

      // Ensure non-negative dimensions (overflow can produce tiny negatives).
      final cw = w.clamp(0.0, double.infinity);
      final ch = h.clamp(0.0, double.infinity);

      final Size childSize;
      if (autoMeasured.containsKey(cell.id)) {
        // Already laid out; reuse the measured size.
        childSize = autoMeasured[cell.id]!;
      } else {
        // Normal layout: stretch by default, or loose if align/justify specified.
        final alignSelf = cell.alignSelf ?? 'stretch';
        final justifySelf = cell.justifySelf ?? 'stretch';
        final loose = alignSelf != 'stretch' || justifySelf != 'stretch';
        childSize = layoutChild(
          cell.id,
          loose
              ? BoxConstraints(maxWidth: cw, maxHeight: ch)
              : BoxConstraints.tightFor(width: cw, height: ch),
        );
      }

      final alignSelf = cell.alignSelf ?? 'stretch';
      final justifySelf = cell.justifySelf ?? 'stretch';
      double dx = x;
      double dy = y;
      if (justifySelf == 'center') dx = x + (w - childSize.width) / 2;
      if (justifySelf == 'end') dx = x + (w - childSize.width);
      if (alignSelf == 'center') dy = y + (h - childSize.height) / 2;
      if (alignSelf == 'end') dy = y + (h - childSize.height);

      positionChild(cell.id, Offset(dx, dy));
    }
  }

  /// First pass: resolve px tracks to their fixed size; mark fr tracks with
  /// a negative sentinel (-frMultiplier); auto tracks start at 0.
  /// Returns a mutable list used by subsequent passes.
  List<double> _firstPassTracks(List<String> specs) {
    final sizes = List<double>.filled(specs.length, 0);
    for (int i = 0; i < specs.length; i++) {
      final spec = specs[i].trim();
      if (spec.endsWith('px')) {
        sizes[i] = double.parse(spec.substring(0, spec.length - 2));
      } else if (spec.endsWith('fr')) {
        sizes[i] = -double.parse(spec.substring(0, spec.length - 2));
      } else if (spec == 'auto') {
        sizes[i] = 0; // filled by auto-sizing pass
      } else {
        throw FormatException('Unsupported track spec: $spec');
      }
    }
    return sizes;
  }

  /// Distributes remaining space among fr tracks in-place.
  /// Fr tracks are encoded as negative values (-frMultiplier); non-negative
  /// entries are fixed (px or already-measured auto).
  void _applyFrTracks(List<double> sizes, double available) {
    double used = 0;
    double frTotal = 0;
    for (int i = 0; i < sizes.length; i++) {
      if (sizes[i] >= 0) {
        used += sizes[i];
      } else {
        frTotal += -sizes[i];
      }
    }
    final remaining = (available - used).clamp(0.0, double.infinity);
    if (frTotal > 0) {
      final per = remaining / frTotal;
      for (int i = 0; i < sizes.length; i++) {
        if (sizes[i] < 0) sizes[i] = per * -sizes[i];
      }
    } else {
      for (int i = 0; i < sizes.length; i++) {
        if (sizes[i] < 0) sizes[i] = 0;
      }
    }
  }

  List<double> _cumulative(List<double> sizes, double gap) {
    final offs = <double>[0];
    double acc = 0;
    for (int i = 0; i < sizes.length - 1; i++) {
      acc += sizes[i] + gap;
      offs.add(acc);
    }
    return offs;
  }

  @override
  bool shouldRelayout(_HudGridDelegate old) =>
      !_listEq(old.rows, rows) ||
      !_listEq(old.cols, cols) ||
      old.gap != gap ||
      old.cells.length != cells.length;

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
