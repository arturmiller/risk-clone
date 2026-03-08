---
phase: 01-foundation
plan: 01
subsystem: data
tags: [networkx, pydantic, json, graph, territory-map]

# Dependency graph
requires: []
provides:
  - "Classic Risk map data (42 territories, 6 continents, 82 adjacency edges) in JSON"
  - "Pydantic v2 MapData/ContinentData models with validation"
  - "MapGraph NetworkX wrapper with adjacency, reachability, and continent queries"
  - "Exhaustive test suite (32 tests) validating all map data and graph queries"
affects: [02-game-engine, 03-web-ui, 04-bot-ai, 05-bot-hard]

# Tech tracking
tech-stack:
  added: [networkx, pydantic, pytest, python-3.13]
  patterns: [json-map-schema, pydantic-validation, networkx-graph-wrapper, tdd]

key-files:
  created:
    - pyproject.toml
    - risk/data/classic.json
    - risk/models/map_schema.py
    - risk/engine/map_graph.py
    - tests/conftest.py
    - tests/test_map_data.py
    - tests/test_map_graph.py
  modified: []

key-decisions:
  - "82 adjacency edges verified via individual test assertions (research noted 80-83 range; 82 is the correct count for classic Risk)"
  - "Pydantic v2 model_validator ensures continent territories exactly cover master list"
  - "MapGraph stores precomputed continent lookups for O(1) queries"

patterns-established:
  - "JSON map data loaded and validated through Pydantic before use"
  - "MapGraph wraps NetworkX undirected graph with game-specific query methods"
  - "TDD workflow: write failing tests first, then implement to pass"
  - "conftest.py provides map_data and map_graph fixtures for all test modules"

requirements-completed: [MAPV-01]

# Metrics
duration: 4min
completed: 2026-03-08
---

# Phase 1 Plan 1: Map Data and Graph Infrastructure Summary

**Classic Risk map (42 territories, 82 edges) with Pydantic schema validation and NetworkX graph wrapper providing adjacency, reachability, and continent control queries**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T06:41:53Z
- **Completed:** 2026-03-08T06:45:58Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Complete classic Risk map data in JSON with all 42 territories, 6 continents, continent bonuses, and 82 adjacency edges including all cross-ocean routes
- Pydantic v2 models (MapData, ContinentData) with field validators rejecting duplicate territories, unknown adjacency endpoints, and mismatched continent coverage
- MapGraph NetworkX wrapper with are_adjacent, neighbors, connected_territories (BFS through friendly chain), continent_territories, controls_continent, and continent_bonus queries
- 32 passing tests covering every adjacency edge individually, cross-ocean routes, validation rejection, graph queries, and reachability

## Task Commits

Each task was committed atomically:

1. **Task 1: Project scaffolding, JSON map data, and Pydantic map schema** - `431d52d` (feat)
2. **Task 2: NetworkX graph wrapper and graph query tests** - `4b1eef8` (feat)

## Files Created/Modified
- `pyproject.toml` - Project config with networkx, pydantic, pytest dependencies
- `risk/__init__.py` - Package init
- `risk/models/__init__.py` - Models package init
- `risk/models/map_schema.py` - MapData and ContinentData Pydantic v2 models with validators
- `risk/engine/__init__.py` - Engine package init
- `risk/engine/map_graph.py` - MapGraph NetworkX wrapper with load_map and game queries
- `risk/data/classic.json` - Complete classic Risk map data (42 territories, 82 edges)
- `tests/__init__.py` - Tests package init
- `tests/conftest.py` - Shared fixtures: map_data, map_graph
- `tests/test_map_data.py` - 20 tests: territory/continent validation, every edge assertion, rejection tests
- `tests/test_map_graph.py` - 12 tests: adjacency, neighbors, reachability, continent control

## Decisions Made
- 82 adjacency edges is the correct count for classic Risk (research noted 80-83 range from various sources; individual edge enumeration in tests confirms 82)
- Pydantic model_validator (mode="after") ensures continent territory lists exactly match master list with no gaps or overlaps
- MapGraph precomputes continent membership and bonus lookups at construction time for O(1) queries
- Python 3.13 selected (pyenv local) since 3.12+ was required

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Map data foundation complete: JSON schema, Pydantic validation, graph queries all working
- Ready for Plan 01-02 (game state models, territory distribution, army placement)
- MapGraph and MapData are the integration points for Phase 2 game engine

---
*Phase: 01-foundation*
*Completed: 2026-03-08*
