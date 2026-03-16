import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/game_config.dart';

void main() {
  group('GameConfig + GameMode (MOBX-01)', () {
    test('GameMode enum has vsBot and simulation values', () {
      expect(GameMode.values, contains(GameMode.vsBot));
      expect(GameMode.values, contains(GameMode.simulation));
    });

    test('GameConfig defaults gameMode to vsBot', () {
      const config = GameConfig(
        playerCount: 3,
        difficulty: Difficulty.medium,
      );
      expect(config.gameMode, GameMode.vsBot);
    });

    test('GameConfig accepts explicit gameMode', () {
      const config = GameConfig(
        playerCount: 3,
        difficulty: Difficulty.medium,
        gameMode: GameMode.simulation,
      );
      expect(config.gameMode, GameMode.simulation);
    });
  });
}
