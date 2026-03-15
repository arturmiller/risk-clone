import 'package:freezed_annotation/freezed_annotation.dart';

part 'ui_state.freezed.dart';

@freezed
abstract class UIState with _$UIState {
  const factory UIState({
    String? selectedTerritory,
    @Default({}) Set<String> validTargets,
    @Default({}) Set<String> validSources,
  }) = _UIState;

  factory UIState.empty() => const UIState();
}
