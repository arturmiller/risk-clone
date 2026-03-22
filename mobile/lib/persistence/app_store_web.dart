/// Web no-op persistence. ObjectBox is unavailable on web.

class _WebStore {}

Future<Object> openRiskStore() async => _WebStore();

void saveGameState(Object store, String json, int turnNumber) {
  // No-op on web — simulation is ephemeral
}

String? loadGameState(Object store) => null;

void clearGameState(Object store) {
  // No-op on web
}
