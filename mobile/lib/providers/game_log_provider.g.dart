// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the running list of game log entries for the current session.
/// Not serialized to ObjectBox — resets when a new game starts.

@ProviderFor(GameLog)
final gameLogProvider = GameLogProvider._();

/// Holds the running list of game log entries for the current session.
/// Not serialized to ObjectBox — resets when a new game starts.
final class GameLogProvider extends $NotifierProvider<GameLog, List<LogEntry>> {
  /// Holds the running list of game log entries for the current session.
  /// Not serialized to ObjectBox — resets when a new game starts.
  GameLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameLogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameLogHash();

  @$internal
  @override
  GameLog create() => GameLog();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LogEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LogEntry>>(value),
    );
  }
}

String _$gameLogHash() => r'30a74dc7e455399e1dfa88e537211cf8d2e245bb';

/// Holds the running list of game log entries for the current session.
/// Not serialized to ObjectBox — resets when a new game starts.

abstract class _$GameLog extends $Notifier<List<LogEntry>> {
  List<LogEntry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<LogEntry>, List<LogEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<LogEntry>, List<LogEntry>>,
              List<LogEntry>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
