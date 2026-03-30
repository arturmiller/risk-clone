/// Golden fixture tests: load JSON fixtures generated from Python engine,
/// run each through the Dart engine, assert outputs match exactly.
///
/// These tests confirm Python-Dart parity on combat, reinforcements, and fortify.
/// Run from mobile/ directory: flutter test test/engine/golden_fixture_test.dart

import 'dart:convert';
import 'dart:io'; // still needed for fixture file loading below

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/actions.dart';
import 'package:risk_mobile/engine/combat.dart';
import 'package:risk_mobile/engine/fortify.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/reinforcements.dart';

import '../helpers/fake_random.dart';

/// Resolve fixture file paths relative to mobile/ (flutter test cwd).
String fixturesPath(String filename) => 'test/engine/fixtures/$filename';

/// Embedded classic map data for golden fixture tests.
/// This replicates the old classic.json structure (territories as a list)
/// so fixture files continue to work regardless of asset changes.
const String _classicMapJson = '''
{
  "name": "Classic",
  "territories": [
    "Alaska", "Northwest Territory", "Greenland", "Alberta", "Ontario",
    "Quebec", "Western United States", "Eastern United States", "Central America",
    "Venezuela", "Peru", "Brazil", "Argentina",
    "North Africa", "Egypt", "East Africa", "Congo", "South Africa", "Madagascar",
    "Iceland", "Scandinavia", "Ukraine", "Great Britain", "Northern Europe",
    "Southern Europe", "Western Europe",
    "Indonesia", "New Guinea", "Western Australia", "Eastern Australia",
    "Siam", "India", "China", "Mongolia", "Japan",
    "Irkutsk", "Yakutsk", "Kamchatka", "Siberia", "Afghanistan", "Ural", "Middle East"
  ],
  "continents": [
    {"name": "North America", "bonus": 5, "territories": [
      "Alaska", "Northwest Territory", "Greenland", "Alberta", "Ontario",
      "Quebec", "Western United States", "Eastern United States", "Central America"
    ]},
    {"name": "South America", "bonus": 2, "territories": ["Venezuela", "Peru", "Brazil", "Argentina"]},
    {"name": "Europe", "bonus": 5, "territories": [
      "Iceland", "Scandinavia", "Ukraine", "Great Britain",
      "Northern Europe", "Southern Europe", "Western Europe"
    ]},
    {"name": "Africa", "bonus": 3, "territories": [
      "North Africa", "Egypt", "East Africa", "Congo", "South Africa", "Madagascar"
    ]},
    {"name": "Asia", "bonus": 7, "territories": [
      "Siam", "India", "China", "Mongolia", "Japan",
      "Irkutsk", "Yakutsk", "Kamchatka", "Siberia", "Afghanistan", "Ural", "Middle East"
    ]},
    {"name": "Australia", "bonus": 2, "territories": [
      "Indonesia", "New Guinea", "Western Australia", "Eastern Australia"
    ]}
  ],
  "adjacencies": [
    ["Alaska", "Alberta"], ["Alaska", "Northwest Territory"], ["Alaska", "Kamchatka"],
    ["Alberta", "Northwest Territory"], ["Alberta", "Ontario"], ["Alberta", "Western United States"],
    ["Ontario", "Northwest Territory"], ["Ontario", "Quebec"], ["Ontario", "Eastern United States"],
    ["Ontario", "Western United States"], ["Ontario", "Greenland"],
    ["Quebec", "Eastern United States"], ["Quebec", "Greenland"],
    ["Greenland", "Northwest Territory"],
    ["Eastern United States", "Western United States"],
    ["Central America", "Eastern United States"], ["Central America", "Western United States"],
    ["Venezuela", "Brazil"], ["Venezuela", "Peru"],
    ["Brazil", "Peru"], ["Brazil", "Argentina"], ["Argentina", "Peru"],
    ["Iceland", "Scandinavia"], ["Iceland", "Great Britain"],
    ["Scandinavia", "Great Britain"], ["Scandinavia", "Northern Europe"], ["Scandinavia", "Ukraine"],
    ["Great Britain", "Northern Europe"], ["Great Britain", "Western Europe"],
    ["Northern Europe", "Southern Europe"], ["Northern Europe", "Ukraine"],
    ["Northern Europe", "Western Europe"],
    ["Southern Europe", "Ukraine"], ["Southern Europe", "Western Europe"],
    ["North Africa", "Egypt"], ["North Africa", "East Africa"], ["North Africa", "Congo"],
    ["Egypt", "East Africa"],
    ["East Africa", "Congo"], ["East Africa", "South Africa"], ["East Africa", "Madagascar"],
    ["Congo", "South Africa"], ["Madagascar", "South Africa"],
    ["Afghanistan", "China"], ["Afghanistan", "India"], ["Afghanistan", "Middle East"],
    ["Afghanistan", "Ural"], ["China", "India"], ["China", "Mongolia"],
    ["China", "Siam"], ["China", "Siberia"], ["China", "Ural"],
    ["India", "Middle East"], ["India", "Siam"],
    ["Irkutsk", "Kamchatka"], ["Irkutsk", "Mongolia"], ["Irkutsk", "Siberia"], ["Irkutsk", "Yakutsk"],
    ["Japan", "Kamchatka"], ["Japan", "Mongolia"],
    ["Kamchatka", "Mongolia"], ["Kamchatka", "Yakutsk"],
    ["Siberia", "Ural"], ["Siberia", "Yakutsk"],
    ["Indonesia", "New Guinea"], ["Indonesia", "Western Australia"],
    ["New Guinea", "Eastern Australia"], ["New Guinea", "Western Australia"],
    ["Eastern Australia", "Western Australia"],
    ["Greenland", "Iceland"], ["Central America", "Venezuela"],
    ["Brazil", "North Africa"], ["North Africa", "Southern Europe"], ["North Africa", "Western Europe"],
    ["Egypt", "Southern Europe"], ["Egypt", "Middle East"],
    ["East Africa", "Middle East"], ["Southern Europe", "Middle East"],
    ["Ukraine", "Afghanistan"], ["Ukraine", "Middle East"], ["Ukraine", "Ural"],
    ["Siam", "Indonesia"]
  ]
}
''';

/// Load and parse the embedded classic map for golden fixture tests.
MapGraph _loadClassicMap() {
  final mapData = MapData.fromJson(jsonDecode(_classicMapJson) as Map<String, dynamic>);
  return MapGraph(mapData);
}

void main() {
  late MapGraph mapGraph;

  setUpAll(() {
    mapGraph = _loadClassicMap();
  });

  // ---------------------------------------------------------------------------
  // Combat golden fixtures
  // ---------------------------------------------------------------------------
  group('golden_combat', () {
    late List<dynamic> fixtures;

    setUpAll(() async {
      final raw = await File(fixturesPath('golden_combat.json')).readAsString();
      fixtures = jsonDecode(raw) as List<dynamic>;
    });

    test('fixture count >= 4', () {
      expect(fixtures.length, greaterThanOrEqualTo(4));
    });

    // Run each fixture as a separate test dynamically.
    // Flutter test doesn't support dynamic test registration inside setUpAll,
    // so we iterate synchronously after loading. We rely on the count test
    // above to confirm loading succeeded; individual fixture tests run below.
    test('all combat fixtures pass', () {
      expect(fixtures, isNotEmpty);
      for (final f in fixtures) {
        final id = f['id'] as String;
        final inputState =
            GameState.fromJson(f['input_state'] as Map<String, dynamic>);
        final rolls =
            (f['injected_rolls'] as List<dynamic>).cast<int>();
        final rng = FakeRandom(rolls);
        final actionMap = f['action'] as Map<String, dynamic>;

        if (actionMap.containsKey('num_dice')) {
          // Regular attack
          final action = AttackAction(
            source: actionMap['source'] as String,
            target: actionMap['target'] as String,
            numDice: actionMap['num_dice'] as int,
          );
          final (newState, result, conquered) =
              executeAttack(inputState, mapGraph, action, 0, rng);

          expect(result.attackerLosses, f['expected_attacker_losses'],
              reason: '$id: attackerLosses mismatch');
          expect(result.defenderLosses, f['expected_defender_losses'],
              reason: '$id: defenderLosses mismatch');
          expect(conquered, f['expected_conquered'],
              reason: '$id: conquered mismatch');

          final expectedState = GameState.fromJson(
              f['output_state'] as Map<String, dynamic>);
          expect(newState, equals(expectedState),
              reason: '$id: output state mismatch');
        } else {
          // Blitz action
          final action = BlitzAction(
            source: actionMap['source'] as String,
            target: actionMap['target'] as String,
          );
          final (newState, _, conquered) =
              executeBlitz(inputState, mapGraph, action, 0, rng);

          expect(conquered, f['expected_conquered'],
              reason: '$id: blitz conquered mismatch');

          final expectedState = GameState.fromJson(
              f['output_state'] as Map<String, dynamic>);
          expect(newState, equals(expectedState),
              reason: '$id: blitz output state mismatch');
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Reinforcement golden fixtures
  // ---------------------------------------------------------------------------
  group('golden_reinforcements', () {
    late List<dynamic> fixtures;

    setUpAll(() async {
      final raw =
          await File(fixturesPath('golden_reinforcements.json')).readAsString();
      fixtures = jsonDecode(raw) as List<dynamic>;
    });

    test('fixture count >= 3', () {
      expect(fixtures.length, greaterThanOrEqualTo(3));
    });

    test('all reinforcement fixtures pass', () {
      expect(fixtures, isNotEmpty);
      for (final f in fixtures) {
        final id = f['id'] as String;
        final state =
            GameState.fromJson(f['input_state'] as Map<String, dynamic>);
        final playerIndex = f['player_index'] as int;
        final expectedReinforcements = f['expected_reinforcements'] as int;

        final result = calculateReinforcements(state, mapGraph, playerIndex);
        expect(result, expectedReinforcements,
            reason: '$id: reinforcements mismatch');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Fortify golden fixtures
  // ---------------------------------------------------------------------------
  group('golden_fortify', () {
    late List<dynamic> fixtures;

    setUpAll(() async {
      final raw =
          await File(fixturesPath('golden_fortify.json')).readAsString();
      fixtures = jsonDecode(raw) as List<dynamic>;
    });

    test('fixture count >= 2', () {
      expect(fixtures.length, greaterThanOrEqualTo(2));
    });

    test('all fortify fixtures pass', () {
      expect(fixtures, isNotEmpty);
      for (final f in fixtures) {
        final id = f['id'] as String;
        final state =
            GameState.fromJson(f['input_state'] as Map<String, dynamic>);
        final actionMap = f['action'] as Map<String, dynamic>;
        final playerIndex = f['player_index'] as int;
        final action = FortifyAction(
          source: actionMap['source'] as String,
          target: actionMap['target'] as String,
          armies: actionMap['armies'] as int,
        );

        final expectsRaise = f['expected_raises'] as bool? ?? false;
        if (expectsRaise) {
          // Disconnected path — expect ArgumentError from validateFortify
          expect(
            () => executeFortify(state, mapGraph, action, playerIndex),
            throwsA(isA<ArgumentError>()),
            reason: '$id: expected ArgumentError for disconnected path',
          );
        } else {
          final newState = executeFortify(state, mapGraph, action, playerIndex);
          final expectedState = GameState.fromJson(
              f['output_state'] as Map<String, dynamic>);
          expect(newState, equals(expectedState),
              reason: '$id: fortify output state mismatch');
        }
      }
    });
  });
}
