# Phase 6: Flutter Scaffold and Data Models - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Set up a compiling Flutter project with all data models (@freezed), map graph (BFS/adjacency), ObjectBox persistence, Riverpod scaffolding, and bundled map data. This is the zero-dependency foundation — every subsequent phase builds on it.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
User granted full discretion on all infrastructure decisions. Claude should make the best choices based on research findings:

- **Project structure**: Feature-first folder layout (engine/, models/, providers/, widgets/, screens/) with pure Dart engine layer having zero Flutter imports
- **Map data format**: Reuse classic.json structure from Python project, bundled as Flutter asset. Territory paths for rendering can be added separately when needed in Phase 10
- **Model design**: Mirror Python Pydantic models closely with @freezed (GameState, TerritoryState, PlayerState, Card, TurnPhase enum). Use copyWith as direct replacement for model_copy. Keep same field names for consistency
- **Graph implementation**: Manual adjacency Map<String, Set<String>> with BFS — no external graph library needed (~60 lines)
- **Persistence setup**: ObjectBox configured with a simple GameState JSON blob entity for save/resume
- **State management**: Riverpod providers scaffolded but minimal — just enough to verify the dependency works
- **Testing**: Pure Dart unit tests for models and map graph, runnable without Flutter simulator

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. Research recommends:
- Flutter 3.41 / Dart 3.11
- flutter_riverpod ^3.3.1
- freezed + json_serializable for code generation
- objectbox ^5.2.0 for persistence
- path_parsing for future SVG territory hit detection (install now, use in Phase 10)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `risk/data/classic.json`: Map data with 42 territories, 6 continents, 83 adjacency edges — can be copied directly as a Flutter asset
- `risk/engine/map_graph.py`: MapGraph implementation (~80 lines) — direct port reference for Dart implementation
- `risk/models/game_state.py`, `risk/models/cards.py`, `risk/models/actions.py`: Pydantic models — direct port reference for @freezed models

### Established Patterns
- Immutable state with copyWith (mirrors Pydantic model_copy)
- Enum-based turn phases and card types
- Map data loaded from JSON at startup

### Integration Points
- classic.json is the shared truth between Python and Dart — same territory names, same adjacencies
- Model field names should match Python for golden fixture validation in Phase 7

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 06-flutter-scaffold-and-data-models*
*Context gathered: 2026-03-14*
