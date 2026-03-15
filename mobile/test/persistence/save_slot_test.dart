import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:risk_mobile/persistence/save_slot.dart';

void main() {
  group('SaveSlot unit', () {
    test('fields are readable', () {
      final slot = SaveSlot(
        gameStateJson: '{"test":true}',
        turnNumber: 5,
        timestamp: '2026-01-01T00:00:00Z',
      );
      expect(slot.gameStateJson, equals('{"test":true}'));
      expect(slot.turnNumber, equals(5));
      expect(slot.timestamp, equals('2026-01-01T00:00:00Z'));
    });
  });

  group('shared_preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('round-trip string value', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('difficulty', 'hard');
      expect(prefs.getString('difficulty'), equals('hard'));
    });
  });
}
