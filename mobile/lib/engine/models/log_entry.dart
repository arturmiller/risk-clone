/// A single game log event. Plain Dart — not persisted, no code generation.
class LogEntry {
  final String message;
  final DateTime timestamp;

  const LogEntry({required this.message, required this.timestamp});
}
