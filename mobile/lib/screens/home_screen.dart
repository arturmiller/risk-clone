import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/map_provider.dart';
import '../providers/simulation_provider.dart';
import '../engine/models/game_config.dart';
import 'game_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk')),
      body: gameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (gameState) {
          if (gameState == null) {
            return Center(
              child: SingleChildScrollView(
                child: SetupForm(onStart: (config) async {
                  await ref.read(gameProvider.notifier).setupGame(config);
                  if (context.mounted) {
                    if (config.gameMode == GameMode.simulation) {
                      ref.read(simulationProvider.notifier).start(config);
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => GameScreen(
                                gameMode: config.gameMode,
                                mapAsset: config.mapAsset,
                              )),
                    );
                  }
                }),
              ),
            );
          }
          return _ResumePrompt(
            gameState: gameState,
            onResume: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            },
            onNewGame: () {
              ref.read(gameProvider.notifier).clearSave();
            },
          );
        },
      ),
    );
  }
}

/// Setup form for starting a new game. Public (no underscore prefix) for
/// testability in unit tests.
class SetupForm extends StatefulWidget {
  final void Function(GameConfig) onStart;
  const SetupForm({super.key, required this.onStart});

  @override
  State<SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<SetupForm> {
  int _playerCount = 3;
  Difficulty _difficulty = Difficulty.medium;
  GameMode _gameMode = GameMode.vsBot;
  String _mapAsset = 'original';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Risk Mobile',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),

          // Player count
          Text('Players: $_playerCount'),
          Slider(
            value: _playerCount.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            label: '$_playerCount',
            onChanged: (v) => setState(() => _playerCount = v.round()),
          ),
          const SizedBox(height: 16),

          // Difficulty
          const Text('Difficulty'),
          const SizedBox(height: 8),
          SegmentedButton<Difficulty>(
            segments: const [
              ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
              ButtonSegment(value: Difficulty.medium, label: Text('Medium')),
              ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 16),

          // Game mode
          const Text('Mode'),
          const SizedBox(height: 8),
          SegmentedButton<GameMode>(
            segments: const [
              ButtonSegment(value: GameMode.vsBot, label: Text('vs Bots')),
              ButtonSegment(
                  value: GameMode.simulation, label: Text('Simulation')),
            ],
            selected: {_gameMode},
            onSelectionChanged: (s) => setState(() => _gameMode = s.first),
          ),
          const SizedBox(height: 16),

          // Map selection
          const Text('Map'),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _mapAsset,
            isExpanded: true,
            items: kAvailableMaps.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _mapAsset = v);
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () => widget.onStart(GameConfig(
              playerCount: _playerCount,
              difficulty: _difficulty,
              gameMode: _gameMode,
              mapAsset: _mapAsset,
            )),
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }
}

class _ResumePrompt extends StatelessWidget {
  final dynamic gameState;
  final VoidCallback onResume;
  final VoidCallback onNewGame;
  const _ResumePrompt({
    required this.gameState,
    required this.onResume,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Resume Game?',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text('Turn ${gameState.turnNumber}'),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onResume, child: const Text('Resume')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onNewGame, child: const Text('New Game')),
        ],
      ),
    );
  }
}
