import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hud.json asset loads and parses', () async {
    final raw = await rootBundle.loadString('assets/hud.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    expect(json['version'], 1);
    expect(json['layouts'], isA<Map>());
    expect((json['layouts'] as Map).keys,
        containsAll(['mobile-landscape', 'desktop-landscape']));
  });
}
