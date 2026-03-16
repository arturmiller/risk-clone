/// Configuration for starting a new game. Plain Dart class — no freezed needed
/// because GameConfig is never stored or compared for equality; it's a one-shot
/// parameter to GameNotifier.setupGame().
enum GameMode { vsBot, simulation }

enum Difficulty { easy, medium, hard }

class GameConfig {
  final int playerCount;
  final Difficulty difficulty;
  final GameMode gameMode;

  const GameConfig({
    required this.playerCount,
    required this.difficulty,
    this.gameMode = GameMode.vsBot,
  });
}
