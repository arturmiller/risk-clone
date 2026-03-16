import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../engine/models/log_entry.dart';

part 'game_log_provider.g.dart';

/// Holds the running list of game log entries for the current session.
/// Not serialized to ObjectBox — resets when a new game starts.
@riverpod
class GameLog extends _$GameLog {
  @override
  List<LogEntry> build() => const [];

  void add(String message) {
    state = [...state, LogEntry(message: message, timestamp: DateTime.now())];
  }

  void clear() => state = const [];
}
