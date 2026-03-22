import 'package:objectbox/objectbox.dart';
import '../objectbox.g.dart';
import 'save_slot.dart';

/// Opens the ObjectBox store on native platforms.
Future<Store> openRiskStore() async {
  return openStore(directory: 'obx-risk');
}

/// Save game state to ObjectBox.
void saveGameState(Object store, String json, int turnNumber) {
  final box = (store as Store).box<SaveSlot>();
  final existing = box.getAll();
  final slot = existing.isNotEmpty ? existing.first : SaveSlot();
  slot.gameStateJson = json;
  slot.turnNumber = turnNumber;
  slot.timestamp = DateTime.now().toIso8601String();
  box.put(slot);
}

/// Load saved game state JSON from ObjectBox, or null if none.
String? loadGameState(Object store) {
  final box = (store as Store).box<SaveSlot>();
  final slots = box.getAll();
  if (slots.isEmpty) return null;
  return slots.first.gameStateJson;
}

/// Clear all saved game data.
void clearGameState(Object store) {
  (store as Store).box<SaveSlot>().removeAll();
}
