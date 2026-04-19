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
    final colSizes = _resolveTracks(cols, size.width - gap * (cols.length - 1));
    final rowSizes = _resolveTracks(rows, size.height - gap * (rows.length - 1));

    // Compute cumulative offsets per track.
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

      // Let the child measure itself up to the cell; default stretch.
      final alignSelf = cell.alignSelf ?? 'stretch';
      final justifySelf = cell.justifySelf ?? 'stretch';
      final loose = alignSelf != 'stretch' || justifySelf != 'stretch';

      final childSize = layoutChild(
        cell.id,
        loose
            ? BoxConstraints(maxWidth: w, maxHeight: h)
            : BoxConstraints.tightFor(width: w, height: h),
      );

      double dx = x;
      double dy = y;
      if (justifySelf == 'center') dx = x + (w - childSize.width) / 2;
      if (justifySelf == 'end') dx = x + (w - childSize.width);
      if (alignSelf == 'center') dy = y + (h - childSize.height) / 2;
      if (alignSelf == 'end') dy = y + (h - childSize.height);

      positionChild(cell.id, Offset(dx, dy));
    }
  }

  List<double> _resolveTracks(List<String> specs, double available) {
    final sizes = List<double>.filled(specs.length, 0);
    double remaining = available;
    double frTotal = 0;
    final autoIndices = <int>[];

    for (int i = 0; i < specs.length; i++) {
      final spec = specs[i].trim();
      if (spec.endsWith('px')) {
        final v = double.parse(spec.substring(0, spec.length - 2));
        sizes[i] = v;
        remaining -= v;
      } else if (spec.endsWith('fr')) {
        final v = double.parse(spec.substring(0, spec.length - 2));
        sizes[i] = -v; // negative marker; fill later
        frTotal += v;
      } else if (spec == 'auto') {
        autoIndices.add(i);
      } else {
        throw FormatException('Unsupported track spec: $spec');
      }
    }

    // Auto tracks: for now, give them 0 (children will pack); refine later if needed.
    for (final i in autoIndices) {
      sizes[i] = 0;
    }

    if (frTotal > 0 && remaining > 0) {
      final per = remaining / frTotal;
      for (int i = 0; i < sizes.length; i++) {
        if (sizes[i] < 0) sizes[i] = per * -sizes[i];
      }
    }
    for (int i = 0; i < sizes.length; i++) {
      if (sizes[i] < 0) sizes[i] = 0;
    }
    return sizes;
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
