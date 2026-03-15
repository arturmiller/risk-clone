import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../engine/map_graph.dart';
import '../engine/models/map_schema.dart';

part 'map_provider.g.dart';

@riverpod
Future<MapGraph> mapGraph(Ref ref) async {
  final jsonString = await rootBundle.loadString('assets/classic.json');
  final mapData = MapData.fromJson(
    jsonDecode(jsonString) as Map<String, dynamic>,
  );
  return MapGraph(mapData);
}
