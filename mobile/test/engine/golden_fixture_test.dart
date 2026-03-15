/// Golden fixture tests: load JSON fixtures generated from Python engine,
/// run each through the Dart engine, assert outputs match exactly.
///
/// These tests confirm Python-Dart parity on combat, reinforcements, and fortify.
/// Run from mobile/ directory: flutter test test/engine/golden_fixture_test.dart

import 'dart:convert';
import 'dart:io';

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

/// Load and parse the classic map once for all groups.
MapGraph _loadClassicMap() {
  final raw = File('assets/classic.json').readAsStringSync();
  final mapData = MapData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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
