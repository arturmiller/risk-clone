import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_schema.freezed.dart';
part 'map_schema.g.dart';

@freezed
abstract class ContinentData with _$ContinentData {
  const factory ContinentData({
    required String name,
    required List<String> territories,
    required int bonus,
  }) = _ContinentData;

  factory ContinentData.fromJson(Map<String, dynamic> json) =>
      _$ContinentDataFromJson(json);
}

@freezed
abstract class MapData with _$MapData {
  const factory MapData({
    required String name,
    required List<String> territories,
    required List<ContinentData> continents,
    required List<List<String>> adjacencies,
  }) = _MapData;

  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
}
