import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/models/cards.dart';
import '../../engine/models/game_config.dart';
import '../../engine/models/game_state.dart';
import '../../engine/map_graph.dart';
import '../../providers/game_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/ui_provider.dart';
import 'map_base_painter.dart';
import 'map_overlay_painter.dart';
import 'territory_data.dart';

class MapWidget extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final String mapAsset;
  const MapWidget({
    super.key,
    this.gameMode = GameMode.vsBot,
    this.mapAsset = 'original',
  });

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
    Map<String, TerritoryGeometry> territoryData,
  ) {
    _selectTerritoryAt(
        details.localPosition, gameState, mapGraph, territoryData);
  }

  void _selectTerritoryAt(
    Offset svgPoint,
    GameState gameState,
    MapGraph mapGraph,
    Map<String, TerritoryGeometry> territoryData,
  ) {
    final hits = <String>[];

    for (final entry in territoryData.entries) {
      if (pointInPolygon(svgPoint, entry.value.polygon)) {
        hits.add(entry.key);
      }
    }

    if (hits.isEmpty) {
      ref.read(uIStateProvider.notifier).clearSelection();
      return;
    }

    if (hits.length == 1) {
      final territory = hits.first;

      if (widget.gameMode == GameMode.vsBot &&
          gameState.currentPlayerIndex == 0 &&
          gameState.turnPhase == TurnPhase.reinforce) {
        final ts = gameState.territories[territory];
        if (ts != null && ts.owner == 0) {
          ref.read(uIStateProvider.notifier).addProposedArmy(territory);
        }
        return;
      }

      final uiState = ref.read(uIStateProvider);
      final currentSelection = uiState.selectedTerritory;

      if (currentSelection == territory) {
        ref.read(uIStateProvider.notifier).clearSelection();
      } else if (currentSelection != null &&
          uiState.validTargets.contains(territory) &&
          (gameState.turnPhase == TurnPhase.attack ||
              gameState.turnPhase == TurnPhase.fortify)) {
        ref.read(uIStateProvider.notifier).selectTarget(territory);
      } else {
        ref
            .read(uIStateProvider.notifier)
            .selectTerritory(territory, gameState, mapGraph);
      }
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
    final mapAsync =
        ref.watch(loadedMapProvider(mapAsset: widget.mapAsset));

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
          data: (loadedMap) {
            final uiState = ref.watch(uIStateProvider);
            final cs = loadedMap.canvasSize;
            return InteractiveViewer(
              transformationController: _controller,
              minScale: 0.5,
              maxScale: 4.0,
              constrained: false,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTap(
                    details, gameState, loadedMap.graph, loadedMap.territoryData),
                child: SizedBox(
                  width: cs.width,
                  height: cs.height,
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: MapBasePainter(
                            territoryData: loadedMap.territoryData,
                            canvasSize: cs,
                          ),
                          size: cs,
                          isComplex: true,
                          willChange: false,
                        ),
                      ),
                      CustomPaint(
                        painter: MapOverlayPainter(
                          gameState: gameState,
                          uiState: uiState,
                          territoryData: loadedMap.territoryData,
                          canvasSize: cs,
                        ),
                        size: cs,
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
