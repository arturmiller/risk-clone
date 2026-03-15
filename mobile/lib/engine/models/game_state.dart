import 'package:freezed_annotation/freezed_annotation.dart';
import 'cards.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
abstract class TerritoryState with _$TerritoryState {
  const factory TerritoryState({
    required int owner,
    required int armies,
  }) = _TerritoryState;

  factory TerritoryState.fromJson(Map<String, dynamic> json) =>
      _$TerritoryStateFromJson(json);
}

@freezed
abstract class PlayerState with _$PlayerState {
  const factory PlayerState({
    required int index,
    required String name,
    @Default(true) bool isAlive,
  }) = _PlayerState;

  factory PlayerState.fromJson(Map<String, dynamic> json) =>
      _$PlayerStateFromJson(json);
}

@freezed
abstract class GameState with _$GameState {
  const factory GameState({
    required Map<String, TerritoryState> territories,
    required List<PlayerState> players,
    @Default(0) int currentPlayerIndex,
    @Default(0) int turnNumber,
    @Default(TurnPhase.reinforce) TurnPhase turnPhase,
    @Default(0) int tradeCount,
    // JSON map keys must be strings; access with cards[playerIndex.toString()]
    @Default({}) Map<String, List<Card>> cards,
    @Default([]) List<Card> deck,
    @Default(false) bool conqueredThisTurn,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}
