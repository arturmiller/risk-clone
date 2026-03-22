// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SimulationNotifier)
final simulationProvider = SimulationNotifierProvider._();

final class SimulationNotifierProvider
    extends $NotifierProvider<SimulationNotifier, SimulationState> {
  SimulationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'simulationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$simulationNotifierHash();

  @$internal
  @override
  SimulationNotifier create() => SimulationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SimulationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SimulationState>(value),
    );
  }
}

String _$simulationNotifierHash() =>
    r'0934f1778b38b90041342f49abc3ee5ef017461c';

abstract class _$SimulationNotifier extends $Notifier<SimulationState> {
  SimulationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SimulationState, SimulationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SimulationState, SimulationState>,
              SimulationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
