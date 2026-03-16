// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UIStateNotifier)
final uIStateProvider = UIStateNotifierProvider._();

final class UIStateNotifierProvider
    extends $NotifierProvider<UIStateNotifier, UIState> {
  UIStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uIStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uIStateNotifierHash();

  @$internal
  @override
  UIStateNotifier create() => UIStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UIState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UIState>(value),
    );
  }
}

String _$uIStateNotifierHash() => r'ca2842ba1c982618f5c5f6b782924330cebc432a';

abstract class _$UIStateNotifier extends $Notifier<UIState> {
  UIState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UIState, UIState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UIState, UIState>,
              UIState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
