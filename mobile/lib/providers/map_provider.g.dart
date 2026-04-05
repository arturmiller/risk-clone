// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loadedMap)
final loadedMapProvider = LoadedMapFamily._();

final class LoadedMapProvider
    extends
        $FunctionalProvider<
          AsyncValue<LoadedMap>,
          LoadedMap,
          FutureOr<LoadedMap>
        >
    with $FutureModifier<LoadedMap>, $FutureProvider<LoadedMap> {
  LoadedMapProvider._({
    required LoadedMapFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'loadedMapProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loadedMapHash();

  @override
  String toString() {
    return r'loadedMapProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LoadedMap> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LoadedMap> create(Ref ref) {
    final argument = this.argument as String;
    return loadedMap(ref, mapAsset: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LoadedMapProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loadedMapHash() => r'678630e5ffc82335db2cab9b0e7d6a95bdf80ab5';

final class LoadedMapFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LoadedMap>, String> {
  LoadedMapFamily._()
    : super(
        retry: null,
        name: r'loadedMapProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LoadedMapProvider call({String mapAsset = 'original'}) =>
      LoadedMapProvider._(argument: mapAsset, from: this);

  @override
  String toString() => r'loadedMapProvider';
}

/// Keep backwards-compatible mapGraphProvider for existing code.

@ProviderFor(mapGraph)
final mapGraphProvider = MapGraphFamily._();

/// Keep backwards-compatible mapGraphProvider for existing code.

final class MapGraphProvider
    extends
        $FunctionalProvider<AsyncValue<MapGraph>, MapGraph, FutureOr<MapGraph>>
    with $FutureModifier<MapGraph>, $FutureProvider<MapGraph> {
  /// Keep backwards-compatible mapGraphProvider for existing code.
  MapGraphProvider._({
    required MapGraphFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mapGraphProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mapGraphHash();

  @override
  String toString() {
    return r'mapGraphProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MapGraph> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MapGraph> create(Ref ref) {
    final argument = this.argument as String;
    return mapGraph(ref, mapAsset: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MapGraphProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapGraphHash() => r'dd788f800f1aa1c5edd85f0a57ef435579db56da';

/// Keep backwards-compatible mapGraphProvider for existing code.

final class MapGraphFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MapGraph>, String> {
  MapGraphFamily._()
    : super(
        retry: null,
        name: r'mapGraphProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keep backwards-compatible mapGraphProvider for existing code.

  MapGraphProvider call({String mapAsset = 'original'}) =>
      MapGraphProvider._(argument: mapAsset, from: this);

  @override
  String toString() => r'mapGraphProvider';
}
