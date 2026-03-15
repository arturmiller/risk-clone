import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/models/game_state.dart';
import '../../engine/map_graph.dart';
import '../../providers/game_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/ui_provider.dart';
import 'map_base_painter.dart';
import 'map_overlay_painter.dart';
import 'territory_data.dart';

class MapWidget extends ConsumerStatefulWidget {
  const MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(
    TapUpDetails details,
    GameState gameState,
    MapGraph mapGraph,
  ) {
    // GestureDetector is INSIDE InteractiveViewer, so details.localPosition
    // is in the child's local coordinate space (the 1200x700 SizedBox).
    // toScene() inverts the zoom/pan transform to get the unscaled scene point.
    final scenePoint = _controller.toScene(details.localPosition);
    _selectTerritoryAt(scenePoint, gameState, mapGraph);
  }

  void _selectTerritoryAt(
    Offset svgPoint,
    GameState gameState,
    MapGraph mapGraph,
  ) {
    const hitPadding = 6.0;
    final hits = <String>[];

    for (final entry in kTerritoryData.entries) {
      if (entry.value.rect.inflate(hitPadding).contains(svgPoint)) {
        hits.add(entry.key);
      }
    }

    if (hits.isEmpty) return;

    if (hits.length == 1) {
      ref
          .read(uIStateProvider.notifier)
          .selectTerritory(hits.first, gameState, mapGraph);
    } else {
      _showDisambiguationDialog(hits, gameState, mapGraph);
    }
  }

  void _showDisambiguationDialog(
    List<String> territories,
    GameState gameState,
    MapGraph mapGraph,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select territory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final name in territories)
              ListTile(
                title: Text(name),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(uIStateProvider.notifier)
                      .selectTerritory(name, gameState, mapGraph);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameProvider);
    final mapAsync = ref.watch(mapGraphProvider);

    return gameAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Map error: $e')),
      data: (gameState) {
        if (gameState == null) {
          return const Center(child: Text('No active game'));
        }
        return mapAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Map load error: $e')),
          data: (mapGraph) {
            final uiState = ref.watch(uIStateProvider);
            return InteractiveViewer(
              transformationController: _controller,
              minScale: 1.0,
              maxScale: 4.0,
              constrained: false,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _handleTap(details, gameState, mapGraph),
                child: SizedBox(
                  width: 1200,
                  height: 700,
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: MapBasePainter(
                            territoryData: kTerritoryData,
                          ),
                          size: const Size(1200, 700),
                          isComplex: true,
                          willChange: false,
                        ),
                      ),
                      CustomPaint(
                        painter: MapOverlayPainter(
                          gameState: gameState,
                          uiState: uiState,
                          territoryData: kTerritoryData,
                        ),
                        size: const Size(1200, 700),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
