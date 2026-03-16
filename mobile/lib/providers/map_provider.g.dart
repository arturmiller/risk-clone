// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapGraph)
final mapGraphProvider = MapGraphProvider._();

final class MapGraphProvider
    extends
        $FunctionalProvider<AsyncValue<MapGraph>, MapGraph, FutureOr<MapGraph>>
    with $FutureModifier<MapGraph>, $FutureProvider<MapGraph> {
  MapGraphProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapGraphProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapGraphHash();

  @$internal
  @override
  $FutureProviderElement<MapGraph> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MapGraph> create(Ref ref) {
    return mapGraph(ref);
  }
}

String _$mapGraphHash() => r'72c364ad5deafa43bcff697f476433f7dd6119b2';
