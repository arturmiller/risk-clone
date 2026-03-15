import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/bots/easy_agent.dart';
import 'package:risk_mobile/bots/hard_agent.dart';
import 'package:risk_mobile/bots/medium_agent.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';
import 'package:risk_mobile/engine/simulation.dart';
import 'package:risk_mobile/bots/player_agent.dart';

void main() {
  group('win_rate', () {
    late MapGraph mapGraph;

    setUpAll(() {
      final raw = File('assets/classic.json').readAsStringSync();
      final mapData =
          MapData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      mapGraph = MapGraph(mapData);
    });

    test(
      'HardAgent wins ~80% vs MediumAgent over 500 games',
      () {
        int hardWins = 0;
        const games = 500;
        final perSeed = <int, int>{};

        for (int i = 0; i < games; i++) {
          final rng = Random(i);
          final agents = <int, PlayerAgent>{
            0: HardAgent(mapGraph: mapGraph, rng: rng),
            1: MediumAgent(mapGraph: mapGraph, rng: rng),
          };
          final finalState = runGame(mapGraph, agents, rng);
          final winner =
              finalState.players.indexWhere((p) => p.isAlive);
          perSeed[i] = winner;
          if (winner == 0) hardWins++;
        }

        final winRate = hardWins / games;

        if (winRate < 0.75 || winRate > 0.85) {
          // Diagnostic output for debugging
          print(
              'DIAGNOSTIC: HardAgent win rate = ${(winRate * 100).toStringAsFixed(1)}% ($hardWins/$games)');
          final losses = perSeed.entries
              .where((e) => e.value != 0)
              .take(20)
              .map((e) => 'seed=${e.key} winner=player${e.value}')
              .join(', ');
          print('Sample losses (first 20): $losses');
        }

        expect(winRate, closeTo(0.80, 0.05),
            reason:
                'HardAgent win rate ${(winRate * 100).toStringAsFixed(1)}% is outside 75-85% target');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'EasyAgent wins significantly less than HardAgent vs Medium (sanity check)',
      () {
        int easyWins = 0;
        const games = 100;

        for (int i = 0; i < games; i++) {
          final rng = Random(i);
          final agents = <int, PlayerAgent>{
            0: EasyAgent(mapGraph: mapGraph, rng: rng),
            1: MediumAgent(mapGraph: mapGraph, rng: rng),
          };
          final finalState = runGame(mapGraph, agents, rng);
          final winner =
              finalState.players.indexWhere((p) => p.isAlive);
          if (winner == 0) easyWins++;
        }

        final easyWinRate = easyWins / games;
        // EasyAgent should win significantly less than 75%
        expect(easyWinRate, lessThan(0.60),
            reason:
                'EasyAgent should win < 60% vs Medium; got ${(easyWinRate * 100).toStringAsFixed(1)}%');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
