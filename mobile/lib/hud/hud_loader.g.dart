// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hud_loader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(hudConfig)
final hudConfigProvider = HudConfigProvider._();

final class HudConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<HudConfig>,
          HudConfig,
          FutureOr<HudConfig>
        >
    with $FutureModifier<HudConfig>, $FutureProvider<HudConfig> {
  HudConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hudConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hudConfigHash();

  @$internal
  @override
  $FutureProviderElement<HudConfig> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<HudConfig> create(Ref ref) {
    return hudConfig(ref);
  }
}

String _$hudConfigHash() => r'3b11c9c7a5a570d93e3630feadaec42fd130718b';
