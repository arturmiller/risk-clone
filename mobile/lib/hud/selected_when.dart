import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bindings.dart';

/// Evaluates a `<binding> == <literal>` expression. Only this shape is supported.
bool evaluateSelectedWhen(String expr, WidgetRef ref) {
  final match = RegExp(r'^\s*(.+?)\s*==\s*(.+?)\s*$').firstMatch(expr);
  if (match == null) {
    if (kDebugMode) debugPrint('[hud.selectedWhen] Bad expression: $expr');
    return false;
  }
  final left = resolveBinding(match.group(1)!, ref);
  final rhs = match.group(2)!.trim();

  // String literal ("X")
  if (rhs.length >= 2 && rhs.startsWith('"') && rhs.endsWith('"')) {
    final str = rhs.substring(1, rhs.length - 1);
    return left?.toString() == str;
  }

  // Integer literal
  final n = int.tryParse(rhs);
  if (n != null) {
    return left == n;
  }

  if (kDebugMode) {
    debugPrint('[hud.selectedWhen] Unsupported literal: $rhs');
  }
  return false;
}
