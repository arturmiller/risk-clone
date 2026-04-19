import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/models.dart';

void main() {
  group('HudConfig.fromJson', () {
    test('parses a minimal valid config', () {
      final json = {
        'version': 1,
        'theme': {
          'background': '#000000',
          'border': '#FFFFFF',
          'text': '#FF0000',
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
      final config = HudConfig.fromJson(json);
      expect(config.version, 1);
      expect(config.theme.text, '#FF0000');
      expect(config.layouts.keys, ['mobile-landscape']);
      final root = config.layouts['mobile-landscape']!.root;
      expect(root, isA<HudGrid>());
      expect((root as HudGrid).id, 'root');
    });

    test('parses a label element', () {
      final json = _wrapInRoot({
        'type': 'label',
        'id': 'hello',
        'text': 'Hello',
        'row': 0,
        'col': 0,
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudLabel>());
      expect((el as HudLabel).text, 'Hello');
    });

    test('parses a button with action and selectedWhen', () {
      final json = _wrapInRoot({
        'type': 'button',
        'id': 'b',
        'text': 'GO',
        'row': 0,
        'col': 0,
        'action': 'attack',
        'selectedWhen': 'ui.diceCount == 3',
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudButton>());
      expect((el as HudButton).action, 'attack');
      expect(el.selectedWhen, 'ui.diceCount == 3');
    });

    test('parses a list element', () {
      final json = _wrapInRoot({
        'type': 'list',
        'id': 'log',
        'maxItems': 4,
        'itemBinding': 'game.battleLog',
        'row': 0,
        'col': 0,
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudList>());
      expect((el as HudList).itemBinding, 'game.battleLog');
      expect(el.maxItems, 4);
    });

    test('parses a cardhand element', () {
      final json = _wrapInRoot({
        'type': 'cardhand',
        'id': 'ch',
        'row': 0,
        'col': 0,
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudCardHand>());
    });

    test('throws on unknown element type', () {
      final json = _wrapInRoot({
        'type': 'unknown',
        'id': 'x',
        'row': 0,
        'col': 0,
      });
      expect(() => HudConfig.fromJson(json), throwsA(isA<FormatException>()));
    });
  });
}

Map<String, dynamic> _wrapInRoot(Map<String, dynamic> child) => {
      'version': 1,
      'theme': {
        'background': '#000',
        'border': '#000',
        'text': '#000',
        'borderRadius': 0,
      },
      'layouts': {
        'mobile-landscape': {
          'canvasSize': [844, 390],
          'root': {
            'type': 'grid',
            'id': 'root',
            'rows': ['1fr'],
            'cols': ['1fr'],
            'children': [child],
          },
        },
      },
    };

HudElement _firstChild(HudConfig c) =>
    (c.layouts['mobile-landscape']!.root as HudGrid).children.first;
