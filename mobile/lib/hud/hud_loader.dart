import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models.dart';

part 'hud_loader.g.dart';

/// Synchronously parse HUD config from a JSON string. Throws FormatException
/// with a specific message on any parsing or validation failure.
HudConfig parseHudConfig(String raw) {
  late final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    throw FormatException('Invalid HUD JSON: $e');
  }
  try {
    return HudConfig.fromJson(json);
  } on FormatException {
    rethrow;
  } catch (e, st) {
    throw FormatException('Failed to build HudConfig: $e\n$st');
  }
}

@Riverpod(keepAlive: true)
Future<HudConfig> hudConfig(Ref ref) async {
  final raw = await rootBundle.loadString('assets/hud.json');
  return parseHudConfig(raw);
}
