// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Card _$CardFromJson(Map<String, dynamic> json) => _Card(
  territory: json['territory'] as String?,
  cardType: $enumDecode(_$CardTypeEnumMap, json['cardType']),
);

Map<String, dynamic> _$CardToJson(_Card instance) => <String, dynamic>{
  'territory': instance.territory,
  'cardType': _$CardTypeEnumMap[instance.cardType]!,
};

const _$CardTypeEnumMap = {
  CardType.infantry: 'infantry',
  CardType.cavalry: 'cavalry',
  CardType.artillery: 'artillery',
  CardType.wild: 'wild',
};
