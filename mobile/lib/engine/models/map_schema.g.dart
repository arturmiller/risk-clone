// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContinentData _$ContinentDataFromJson(Map<String, dynamic> json) =>
    _ContinentData(
      name: json['name'] as String,
      territories:
          (json['territories'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      bonus: (json['bonus'] as num).toInt(),
    );

Map<String, dynamic> _$ContinentDataToJson(_ContinentData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'territories': instance.territories,
      'bonus': instance.bonus,
    };

_MapData _$MapDataFromJson(Map<String, dynamic> json) => _MapData(
  name: json['name'] as String,
  territories:
      (json['territories'] as List<dynamic>).map((e) => e as String).toList(),
  continents:
      (json['continents'] as List<dynamic>)
          .map((e) => ContinentData.fromJson(e as Map<String, dynamic>))
          .toList(),
  adjacencies:
      (json['adjacencies'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList(),
);

Map<String, dynamic> _$MapDataToJson(_MapData instance) => <String, dynamic>{
  'name': instance.name,
  'territories': instance.territories,
  'continents': instance.continents.map((e) => e.toJson()).toList(),
  'adjacencies': instance.adjacencies,
};
