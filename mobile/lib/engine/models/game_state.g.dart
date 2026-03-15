// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TerritoryState _$TerritoryStateFromJson(Map<String, dynamic> json) =>
    _TerritoryState(
      owner: (json['owner'] as num).toInt(),
      armies: (json['armies'] as num).toInt(),
    );

Map<String, dynamic> _$TerritoryStateToJson(_TerritoryState instance) =>
    <String, dynamic>{'owner': instance.owner, 'armies': instance.armies};

_PlayerState _$PlayerStateFromJson(Map<String, dynamic> json) => _PlayerState(
  index: (json['index'] as num).toInt(),
  name: json['name'] as String,
  isAlive: json['isAlive'] as bool? ?? true,
);

Map<String, dynamic> _$PlayerStateToJson(_PlayerState instance) =>
    <String, dynamic>{
      'index': instance.index,
      'name': instance.name,
      'isAlive': instance.isAlive,
    };

_GameState _$GameStateFromJson(Map<String, dynamic> json) => _GameState(
  territories: (json['territories'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, TerritoryState.fromJson(e as Map<String, dynamic>)),
  ),
  players:
      (json['players'] as List<dynamic>)
          .map((e) => PlayerState.fromJson(e as Map<String, dynamic>))
          .toList(),
  currentPlayerIndex: (json['currentPlayerIndex'] as num?)?.toInt() ?? 0,
  turnNumber: (json['turnNumber'] as num?)?.toInt() ?? 0,
  turnPhase:
      $enumDecodeNullable(_$TurnPhaseEnumMap, json['turnPhase']) ??
      TurnPhase.reinforce,
  tradeCount: (json['tradeCount'] as num?)?.toInt() ?? 0,
  cards:
      (json['cards'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ) ??
      const {},
  deck:
      (json['deck'] as List<dynamic>?)
          ?.map((e) => Card.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  conqueredThisTurn: json['conqueredThisTurn'] as bool? ?? false,
);

Map<String, dynamic> _$GameStateToJson(
  _GameState instance,
) => <String, dynamic>{
  'territories': instance.territories.map((k, e) => MapEntry(k, e.toJson())),
  'players': instance.players.map((e) => e.toJson()).toList(),
  'currentPlayerIndex': instance.currentPlayerIndex,
  'turnNumber': instance.turnNumber,
  'turnPhase': _$TurnPhaseEnumMap[instance.turnPhase]!,
  'tradeCount': instance.tradeCount,
  'cards': instance.cards.map(
    (k, e) => MapEntry(k, e.map((e) => e.toJson()).toList()),
  ),
  'deck': instance.deck.map((e) => e.toJson()).toList(),
  'conqueredThisTurn': instance.conqueredThisTurn,
};

const _$TurnPhaseEnumMap = {
  TurnPhase.reinforce: 'reinforce',
  TurnPhase.attack: 'attack',
  TurnPhase.fortify: 'fortify',
};
