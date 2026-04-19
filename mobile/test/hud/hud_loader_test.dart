import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/hud_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const valid = {
    'version': 1,
    'theme': {
      'background': '#000',
      'border': '#111',
      'text': '#FFB300',
      'borderRadius': 10,
    },
    'layouts': {
      'mobile-landscape': {
        'canvasSize': [844, 390],
        'root': {
          'type': 'grid',
          'id': 'root',
          'rows': ['1fr'],
          'cols': ['1fr'],
          'children': [],
        },
      },
    },
  };

  test('parses valid HUD JSON from string', () async {
    final config = parseHudConfig(jsonEncode(valid));
    expect(config.version, 1);
  });

  test('throws with friendly message on malformed JSON', () {
    expect(() => parseHudConfig('{not json'), throwsA(isA<FormatException>()));
  });

  test('throws on unknown element type', () {
    final bad = Map<String, dynamic>.from(valid);
    bad['layouts'] = {
      'mobile-landscape': {
        'canvasSize': [100, 100],
        'root': {
          'type': 'unknown',
          'id': 'x',
        },
      },
    };
    expect(() => parseHudConfig(jsonEncode(bad)), throwsA(isA<FormatException>()));
  });

  testWidgets('hudConfigProvider loads the real asset', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final config = await container.read(hudConfigProvider.future);
    expect(config.layouts.keys, containsAll(['mobile-landscape', 'desktop-landscape']));
  });
}
