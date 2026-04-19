import 'package:freezed_annotation/freezed_annotation.dart';

part 'ui_state.freezed.dart';

@freezed
abstract class UIState with _$UIState {
  const factory UIState({
    String? selectedTerritory,
    String? selectedTarget,
    @Default({}) Set<String> validTargets,
    @Default({}) Set<String> validSources,
    @Default(0) int pendingArmies,
    @Default({}) Map<String, int> proposedPlacements,
    // Pending advance after conquest
    String? advanceSource,
    String? advanceTarget,
    @Default(0) int advanceMin,
    @Default(0) int advanceMax,
    @Default(3) int diceCount,
  }) = _UIState;

  factory UIState.empty() => const UIState();
}
