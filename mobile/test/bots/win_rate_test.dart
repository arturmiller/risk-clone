import 'dart:convert';
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

/// Embedded classic map for win-rate tests.
/// Using the embedded map ensures these tests remain stable regardless of
/// asset file changes.
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

void main() {
  group('win_rate', () {
    late MapGraph mapGraph;

    setUpAll(() {
      final mapData =
          MapData.fromJson(jsonDecode(_classicMapJson) as Map<String, dynamic>);
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
