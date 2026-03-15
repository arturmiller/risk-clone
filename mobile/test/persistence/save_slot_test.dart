import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/persistence/save_slot.dart';

// ObjectBox integration tests require device/emulator with native libs.
// This stub verifies the SaveSlot class and its fields exist.
// The full round-trip test will be enabled in Plan 03 when ObjectBox is wired up.
@Skip('Requires ObjectBox native libs — run with flutter test not dart test')
void main() {
  group('SaveSlot', () {
    test('write and read SaveSlot', () {
      // Verify the class and its fields exist and are accessible.
      final slot = SaveSlot()
        ..gameStateJson = '{"test":true}'
        ..turnNumber = 5
        ..timestamp = '2026-01-01T00:00:00Z';

      expect(slot.gameStateJson, equals('{"test":true}'));
      expect(slot.turnNumber, equals(5));
      expect(slot.timestamp, equals('2026-01-01T00:00:00Z'));

      // Full ObjectBox write/read round-trip is tested in Plan 03
      // when the ObjectBox store is initialized with openStore().
    });
  });
}
