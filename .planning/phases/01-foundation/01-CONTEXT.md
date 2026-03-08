# Phase 1: Foundation - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Territory data model (42 territories, 6 continents), adjacency graph (83 edges), game state structures, random territory distribution, and initial army placement. This is the data foundation all downstream phases build on. No UI, no game engine logic beyond initial setup.

</domain>

<decisions>
## Implementation Decisions

### Initial Setup Rules
- Territories dealt out randomly and evenly to all players (round-robin for remainder)
- After dealing, remaining armies auto-placed: 1 per territory mandatory, rest distributed randomly among owned territories
- No take-turns-picking or manual army placement — fully automatic setup
- Starting army counts per player: 2p=40, 3p=35, 4p=30, 5p=25, 6p=20 (classic edition)

### Map Data Source
- Territory and adjacency data stored in JSON data file (not hardcoded Python)
- JSON file contains: territories, continent assignments, adjacency edges, continent bonuses
- SVG map source: Claude's discretion — generate simplified SVG or find open-source asset

### Future Map Support
- Light abstraction: map loaded from JSON with clear schema. Adding a new map = new JSON file + new SVG file
- No plugin system, no map registry, no dynamic loading in v1
- Flexible JSON schema: each map can define its own continent bonuses and special connections
- Schema not locked to classic Risk structure — future maps can have different mechanics

### Claude's Discretion
- SVG map sourcing approach (simplified generated vs open-source)
- Exact JSON schema structure
- NetworkX graph implementation details
- Pydantic model design for game state
- Test strategy for adjacency validation

</decisions>

<specifics>
## Specific Ideas

- Must faithfully match classic Risk's 42 territories, 6 continents, and all adjacencies including cross-ocean routes (Alaska-Kamchatka, North Africa-Brazil, etc.)
- Research flagged: even Hasbro shipped an edition with a missing connection — automated adjacency tests are critical

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None (greenfield project)

### Established Patterns
- None yet — this phase establishes the patterns

### Integration Points
- JSON map data will be consumed by Phase 3 (Web UI) for SVG rendering
- Game state models will be consumed by Phase 2 (Game Engine) for turn management
- NetworkX graph will be used by Phase 2 for fortification path validation and Phase 4-5 for bot territory analysis

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-08*
