// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameNotifier)
final gameProvider = GameNotifierProvider._();

final class GameNotifierProvider
    extends $AsyncNotifierProvider<GameNotifier, GameState?> {
  GameNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameNotifierHash();

  @$internal
  @override
  GameNotifier create() => GameNotifier();
}

String _$gameNotifierHash() => r'1a5e636d682ea10246c5cac9e0c7a536450708f1';

abstract class _$GameNotifier extends $AsyncNotifier<GameState?> {
  FutureOr<GameState?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GameState?>, GameState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameState?>, GameState?>,
              AsyncValue<GameState?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
