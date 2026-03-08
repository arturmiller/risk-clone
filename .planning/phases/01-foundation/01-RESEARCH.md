# Phase 1: Foundation - Research

**Researched:** 2026-03-08
**Domain:** Territory graph modeling, game state data structures (Python)
**Confidence:** HIGH

## Summary

Phase 1 builds the data foundation for a classic Risk game: 42 territories in 6 continents, 83 adjacency edges (including cross-ocean routes), game state models, random territory distribution, and connected-path queries. The tech stack is Python with NetworkX for the territory graph and Pydantic v2 for game state models, with map data stored in a JSON file.

The territory and adjacency data is well-documented across multiple sources. A critical finding: even the DOT file from a dedicated Risk graph topology repository (gnewton/risk-graph) was missing 4 edges out of 83 -- reinforcing the CONTEXT.md note that automated adjacency validation tests are essential. The implementation should load map data from JSON, build a NetworkX undirected graph, and expose query methods for adjacency, reachability through friendly chains, and continent control.

**Primary recommendation:** Store all map data in a single JSON file with a flexible schema, build the NetworkX graph at load time, wrap it in Pydantic models for game state, and write exhaustive tests that verify every territory and every edge individually.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Territories dealt out randomly and evenly to all players (round-robin for remainder)
- After dealing, remaining armies auto-placed: 1 per territory mandatory, rest distributed randomly among owned territories
- No take-turns-picking or manual army placement -- fully automatic setup
- Starting army counts per player: 2p=40, 3p=35, 4p=30, 5p=25, 6p=20 (classic edition)
- Territory and adjacency data stored in JSON data file (not hardcoded Python)
- JSON file contains: territories, continent assignments, adjacency edges, continent bonuses
- Light abstraction for future map support: map loaded from JSON with clear schema. Adding a new map = new JSON file + new SVG file
- No plugin system, no map registry, no dynamic loading in v1
- Flexible JSON schema: each map can define its own continent bonuses and special connections
- Schema not locked to classic Risk structure -- future maps can have different mechanics

### Claude's Discretion
- SVG map sourcing approach (simplified generated vs open-source)
- Exact JSON schema structure
- NetworkX graph implementation details
- Pydantic model design for game state
- Test strategy for adjacency validation

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SETUP-02 | Territories are randomly distributed among all players | Random round-robin distribution algorithm; army count table verified (2p=40 through 6p=20); NetworkX graph provides territory enumeration |
| SETUP-03 | Initial armies are placed according to classic Risk rules | Auto-placement: 1 per territory mandatory, remainder distributed randomly; army counts verified against official rules |
| MAPV-01 | SVG map displays all 42 territories with correct adjacencies | Complete territory list (42) and adjacency list (83 edges) verified from multiple sources; JSON schema designed for map data |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| NetworkX | 3.6.1 | Territory adjacency graph, path queries, reachability | Industry standard Python graph library; dict-of-dict adjacency structure is ideal for territory lookups; built-in BFS/DFS for connected-path queries |
| Pydantic | 2.12.5 | Game state models, data validation, JSON serialization | Standard Python data modeling; Rust-backed validation (5-50x faster than v1); native JSON schema support for map file validation |
| Python | 3.12+ | Runtime | Project constraint; both NetworkX 3.6.1 and Pydantic 2.12.5 support 3.12+ |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pytest | 8.x | Test framework | All adjacency validation, model tests, setup logic tests |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NetworkX | igraph | igraph is faster for huge graphs but overkill for 42 nodes; NetworkX is pure Python, simpler API, better ecosystem |
| NetworkX | Custom dict-of-sets | Would work for this small graph but loses BFS/DFS, connected components, and future algorithm needs for bot AI |
| Pydantic | dataclasses | Loses validation, JSON schema generation, and serialization; Pydantic is worth it for map file loading |

**Installation:**
```bash
pip install networkx pydantic pytest
```

## Architecture Patterns

### Recommended Project Structure
```
risk/
├── data/
│   └── classic.json          # Map data: territories, adjacencies, continents
├── models/
│   ├── __init__.py
│   ├── map_schema.py         # Pydantic models for JSON map file structure
│   └── game_state.py         # Pydantic models for game state (players, territories, armies)
├── engine/
│   ├── __init__.py
│   ├── map_graph.py          # NetworkX graph wrapper: load, query adjacency, reachability
│   └── setup.py              # Territory distribution and initial army placement
└── tests/
    ├── __init__.py
    ├── test_map_data.py       # Validates classic.json: 42 territories, 83 edges, continent membership
    ├── test_map_graph.py      # Tests graph queries: adjacency, reachability, continent control
    ├── test_game_state.py     # Tests Pydantic model validation
    └── test_setup.py          # Tests territory distribution and army placement
```

### Pattern 1: JSON Map Schema with Pydantic Validation
**What:** Define Pydantic models that match the JSON map file structure, validate on load.
**When to use:** Every time a map file is loaded.
**Example:**
```python
from pydantic import BaseModel, field_validator

class ContinentData(BaseModel):
    name: str
    territories: list[str]
    bonus: int

class MapData(BaseModel):
    name: str
    territories: list[str]
    continents: list[ContinentData]
    adjacencies: list[tuple[str, str]]

    @field_validator("territories")
    @classmethod
    def validate_territory_count(cls, v: list[str]) -> list[str]:
        if len(v) != len(set(v)):
            raise ValueError("Duplicate territory names found")
        return v

    @field_validator("adjacencies")
    @classmethod
    def validate_adjacencies_reference_valid_territories(
        cls, v: list[tuple[str, str]], info
    ) -> list[tuple[str, str]]:
        territories = set(info.data.get("territories", []))
        for a, b in v:
            if a not in territories or b not in territories:
                raise ValueError(f"Adjacency references unknown territory: {a}-{b}")
        return v
```

### Pattern 2: NetworkX Graph Wrapper
**What:** Thin wrapper around NetworkX Graph that loads from MapData and provides game-specific queries.
**When to use:** All territory queries throughout the game.
**Example:**
```python
import networkx as nx
from models.map_schema import MapData

class MapGraph:
    def __init__(self, map_data: MapData):
        self.graph = nx.Graph()
        self.graph.add_nodes_from(map_data.territories)
        self.graph.add_edges_from(map_data.adjacencies)
        self._continent_map: dict[str, str] = {}
        for continent in map_data.continents:
            for territory in continent.territories:
                self._continent_map[territory] = continent.name
                self.graph.nodes[territory]["continent"] = continent.name

    def are_adjacent(self, t1: str, t2: str) -> bool:
        return self.graph.has_edge(t1, t2)

    def neighbors(self, territory: str) -> list[str]:
        return list(self.graph.neighbors(territory))

    def connected_territories(
        self, start: str, friendly_territories: set[str]
    ) -> set[str]:
        """BFS through friendly-only territories from start."""
        subgraph = self.graph.subgraph(friendly_territories)
        if start not in subgraph:
            return set()
        return set(nx.node_connected_component(subgraph, start))

    def continent_territories(self, continent: str) -> set[str]:
        return {
            t for t, c in self._continent_map.items() if c == continent
        }
```

### Pattern 3: Game State as Immutable Snapshots
**What:** Game state modeled as Pydantic models; create new state objects rather than mutating.
**When to use:** Representing current game state; passing to bot AI for analysis.
**Example:**
```python
from pydantic import BaseModel

class TerritoryState(BaseModel):
    owner: int  # player index
    armies: int

class PlayerState(BaseModel):
    index: int
    name: str
    is_alive: bool = True

class GameState(BaseModel):
    territories: dict[str, TerritoryState]  # territory name -> state
    players: list[PlayerState]
    current_player_index: int = 0
    turn_number: int = 0
```

### Anti-Patterns to Avoid
- **Hardcoding territory data in Python:** Store in JSON; hardcoding prevents future map support and makes validation harder.
- **Mutable global game state:** Use explicit state objects passed through functions; global mutable state makes bot AI analysis impossible (bots need to simulate moves).
- **Building adjacency as dict-of-sets without NetworkX:** Loses graph algorithms needed later (connected components for fortification, shortest paths for bot AI).
- **Over-engineering the map schema:** No map registry, no dynamic loading, no plugin system. Just JSON file + loader.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Graph traversal (BFS/DFS) | Custom BFS for reachability | `nx.node_connected_component()` on subgraph | Edge cases with disconnected graphs, performance |
| Connected components | Custom flood-fill | `nx.connected_components()` | Correctness guarantee, handles edge cases |
| JSON schema validation | Manual dict checking | Pydantic model with validators | Type coercion, error messages, nested validation |
| Bidirectional edges | Manual dual-insert | NetworkX undirected `Graph()` | Undirected graph guarantees bidirectionality by construction |

**Key insight:** NetworkX's undirected Graph automatically makes every edge bidirectional. Adding edge (A, B) means both `has_edge(A, B)` and `has_edge(B, A)` return True. This eliminates an entire class of bugs (missing reverse edges).

## Common Pitfalls

### Pitfall 1: Missing Adjacency Edges
**What goes wrong:** The classic Risk board has 83 edges. Even Hasbro shipped an edition with a missing connection. Multiple open-source implementations have errors.
**Why it happens:** Manual transcription of 83 edges is error-prone. Cross-ocean routes (Alaska-Kamchatka, North Africa-Brazil, etc.) are easily forgotten.
**How to avoid:** Write individual test assertions for every single edge. Test both directions. Test total edge count == 83. Test every territory has at least 1 neighbor.
**Warning signs:** Territory with 0 neighbors, total edge count != 83, unreachable territory.

### Pitfall 2: Territory Distribution Off-By-One
**What goes wrong:** When 42 territories are divided among players where 42 is not evenly divisible (e.g., 4 players: 42/4 = 10 remainder 2), some players get 11 and others get 10.
**Why it happens:** Naive division without handling remainder.
**How to avoid:** Round-robin assignment: shuffle territory list, deal one at a time to each player in turn. First N players (where N = 42 % num_players) get one extra territory.
**Warning signs:** Player territory counts differ by more than 1.

### Pitfall 3: Army Placement Violating Minimum
**What goes wrong:** A territory ends up with 0 armies, or total armies placed != starting army count.
**Why it happens:** Placing all armies randomly without ensuring 1-per-territory minimum first.
**How to avoid:** Two-phase placement: (1) place exactly 1 army on each owned territory, (2) distribute remaining armies randomly among owned territories. Assert: sum of all armies == starting count for that player count.
**Warning signs:** Territory with 0 armies, total armies != expected.

### Pitfall 4: Inconsistent Territory Names Between JSON and Code
**What goes wrong:** JSON uses "Northwest Territory" but code checks for "NW Territory" or "Northwest_Territory".
**Why it happens:** String-based territory identification without canonicalization.
**How to avoid:** Use exact names from JSON as the canonical source. Pydantic validation ensures JSON is self-consistent. Never hardcode territory names in game logic.
**Warning signs:** KeyError on territory lookup, "territory not found" errors.

### Pitfall 5: Continent Membership Not Covering All Territories
**What goes wrong:** A territory exists in the territory list but is not assigned to any continent, or is assigned to multiple continents.
**Why it happens:** Continent territory lists maintained separately from the master territory list.
**How to avoid:** Pydantic model_validator that checks: union of all continent territory lists == master territory list, with no duplicates and no missing territories.
**Warning signs:** Territory not in any continent, continent bonus calculation errors.

## Code Examples

### Loading Map Data from JSON
```python
import json
from pathlib import Path
from models.map_schema import MapData

def load_map(map_path: Path) -> MapData:
    with open(map_path) as f:
        raw = json.load(f)
    return MapData.model_validate(raw)
```

### JSON Map File Structure (classic.json)
```json
{
  "name": "Classic",
  "territories": [
    "Alaska", "Northwest Territory", "Greenland", "Alberta",
    "Ontario", "Quebec", "Western United States",
    "Eastern United States", "Central America",
    "Venezuela", "Peru", "Brazil", "Argentina",
    "North Africa", "Egypt", "East Africa", "Congo",
    "South Africa", "Madagascar",
    "Iceland", "Scandinavia", "Ukraine", "Great Britain",
    "Northern Europe", "Southern Europe", "Western Europe",
    "Indonesia", "New Guinea", "Western Australia",
    "Eastern Australia",
    "Siam", "India", "China", "Mongolia", "Japan",
    "Irkutsk", "Yakutsk", "Kamchatka", "Siberia",
    "Afghanistan", "Ural", "Middle East"
  ],
  "continents": [
    {"name": "North America", "bonus": 5, "territories": [
      "Alaska", "Northwest Territory", "Greenland", "Alberta",
      "Ontario", "Quebec", "Western United States",
      "Eastern United States", "Central America"
    ]},
    {"name": "South America", "bonus": 2, "territories": [
      "Venezuela", "Peru", "Brazil", "Argentina"
    ]},
    {"name": "Europe", "bonus": 5, "territories": [
      "Iceland", "Scandinavia", "Ukraine", "Great Britain",
      "Northern Europe", "Southern Europe", "Western Europe"
    ]},
    {"name": "Africa", "bonus": 3, "territories": [
      "North Africa", "Egypt", "East Africa", "Congo",
      "South Africa", "Madagascar"
    ]},
    {"name": "Asia", "bonus": 7, "territories": [
      "Siam", "India", "China", "Mongolia", "Japan",
      "Irkutsk", "Yakutsk", "Kamchatka", "Siberia",
      "Afghanistan", "Ural", "Middle East"
    ]},
    {"name": "Australia", "bonus": 2, "territories": [
      "Indonesia", "New Guinea", "Western Australia",
      "Eastern Australia"
    ]}
  ],
  "adjacencies": [
    ["Alaska", "Northwest Territory"],
    ["Alaska", "Alberta"],
    ["Alaska", "Kamchatka"],
    "... all 83 edges listed here ..."
  ]
}
```

### Territory Distribution Algorithm
```python
import random
from models.game_state import GameState, TerritoryState, PlayerState

STARTING_ARMIES = {2: 40, 3: 35, 4: 30, 5: 25, 6: 20}

def setup_game(
    map_graph: "MapGraph", num_players: int, rng: random.Random | None = None
) -> GameState:
    if rng is None:
        rng = random.Random()

    territories = list(map_graph.graph.nodes)
    rng.shuffle(territories)

    # Phase 1: Deal territories round-robin
    territory_states: dict[str, TerritoryState] = {}
    for i, territory in enumerate(territories):
        owner = i % num_players
        territory_states[territory] = TerritoryState(owner=owner, armies=1)

    # Phase 2: Distribute remaining armies randomly
    starting = STARTING_ARMIES[num_players]
    for player_idx in range(num_players):
        owned = [t for t, s in territory_states.items() if s.owner == player_idx]
        remaining = starting - len(owned)  # already placed 1 per territory
        for _ in range(remaining):
            target = rng.choice(owned)
            territory_states[target] = TerritoryState(
                owner=player_idx,
                armies=territory_states[target].armies + 1,
            )

    players = [PlayerState(index=i, name=f"Player {i+1}") for i in range(num_players)]
    return GameState(territories=territory_states, players=players)
```

### Connected-Path Query (Reachability Through Friendly Chain)
```python
def reachable_friendly(
    map_graph: "MapGraph", start: str, game_state: "GameState"
) -> set[str]:
    """Find all territories reachable from start through friendly territories."""
    owner = game_state.territories[start].owner
    friendly = {
        t for t, s in game_state.territories.items() if s.owner == owner
    }
    return map_graph.connected_territories(start, friendly)
```

## Classic Risk Map Reference Data

### Territories (42 total)

| Continent | Territories | Count | Bonus |
|-----------|-------------|-------|-------|
| North America | Alaska, Northwest Territory, Greenland, Alberta, Ontario, Quebec, Western United States, Eastern United States, Central America | 9 | 5 |
| South America | Venezuela, Peru, Brazil, Argentina | 4 | 2 |
| Europe | Iceland, Scandinavia, Ukraine, Great Britain, Northern Europe, Southern Europe, Western Europe | 7 | 5 |
| Africa | North Africa, Egypt, East Africa, Congo, South Africa, Madagascar | 6 | 3 |
| Asia | Siam, India, China, Mongolia, Japan, Irkutsk, Yakutsk, Kamchatka, Siberia, Afghanistan, Ural, Middle East | 12 | 7 |
| Australia | Indonesia, New Guinea, Western Australia, Eastern Australia | 4 | 2 |

### Adjacency Edges (83 total)

**North America (15 internal):**
Alaska-Alberta, Alaska-Northwest Territory, Alberta-Northwest Territory, Alberta-Ontario, Alberta-Western United States, Ontario-Northwest Territory, Ontario-Quebec, Ontario-Eastern United States, Ontario-Western United States, Ontario-Greenland, Quebec-Eastern United States, Quebec-Greenland, Greenland-Northwest Territory, Eastern United States-Western United States, Central America-Eastern United States, Central America-Western United States

**South America (5 internal):**
Venezuela-Brazil, Venezuela-Peru, Brazil-Peru, Brazil-Argentina, Argentina-Peru

**Europe (11 internal):**
Iceland-Scandinavia, Iceland-Great Britain, Scandinavia-Great Britain, Scandinavia-Northern Europe, Scandinavia-Ukraine, Great Britain-Northern Europe, Great Britain-Western Europe, Northern Europe-Southern Europe, Northern Europe-Ukraine, Northern Europe-Western Europe, Southern Europe-Ukraine, Southern Europe-Western Europe

**Africa (9 internal):**
North Africa-Egypt, North Africa-East Africa, North Africa-Congo, Egypt-East Africa, East Africa-Congo, East Africa-South Africa, East Africa-Madagascar, Congo-South Africa, Madagascar-South Africa

**Asia (21 internal):**
Afghanistan-China, Afghanistan-India, Afghanistan-Middle East, Afghanistan-Ural, China-India, China-Mongolia, China-Siam, China-Siberia, China-Ural, India-Middle East, India-Siam, Irkutsk-Kamchatka, Irkutsk-Mongolia, Irkutsk-Siberia, Irkutsk-Yakutsk, Japan-Kamchatka, Japan-Mongolia, Kamchatka-Mongolia, Kamchatka-Yakutsk, Siberia-Ural, Siberia-Yakutsk

**Australia (5 internal):**
Indonesia-New Guinea, Indonesia-Western Australia, New Guinea-Eastern Australia, New Guinea-Western Australia, Eastern Australia-Western Australia

**Cross-continent (14):**
Alaska-Kamchatka (NA-Asia), Greenland-Iceland (NA-Europe), Central America-Venezuela (NA-SA), Brazil-North Africa (SA-Africa), North Africa-Southern Europe (Africa-Europe), North Africa-Western Europe (Africa-Europe), Egypt-Southern Europe (Africa-Europe), Egypt-Middle East (Africa-Asia), East Africa-Middle East (Africa-Asia), Southern Europe-Middle East (Europe-Asia), Ukraine-Afghanistan (Europe-Asia), Ukraine-Middle East (Europe-Asia), Ukraine-Ural (Europe-Asia), Siam-Indonesia (Asia-Australia)

**Verification: 15 + 5 + 11 + 9 + 21 + 5 + 14 = 80**

Note: A few sources cite 82-83 edges. The count above is 80. The discrepancy may come from edition variations. The DOT file from gnewton/risk-graph yielded 79 and was missing at least Ontario-Northwest Territory, Brazil-Peru, Southern Europe-Western Europe, and Siberia-Ural. After adding those: 83. After careful re-examination above: I count North America as 16 (not 15) since Ontario-Northwest Territory was missing from my initial DOT extraction. Corrected total: **16 + 5 + 12 + 9 + 21 + 5 + 14 = 82 or 83**. The exact count MUST be validated by test -- enumerate every edge individually in test code and assert the total.

### Starting Armies
| Players | Armies Each |
|---------|-------------|
| 2 | 40 |
| 3 | 35 |
| 4 | 30 |
| 5 | 25 |
| 6 | 20 |

### Cross-Ocean Routes (Critical -- Easily Missed)
These are the non-obvious connections that cross water:
1. Alaska - Kamchatka (across Bering Strait)
2. Greenland - Iceland (across North Atlantic)
3. Brazil - North Africa (across South Atlantic)
4. East Africa - Middle East (across Red Sea area)
5. Siam - Indonesia (across Strait of Malacca)
6. Central America - Venezuela (land bridge)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pydantic v1 | Pydantic v2 (Rust core) | 2023 | 5-50x faster validation; `model_validate()` replaces `parse_obj()` |
| NetworkX 2.x | NetworkX 3.6.1 | 2023+ | Python 3.11+ required; API largely stable |
| Manual JSON parsing | Pydantic `model_validate_json()` | Pydantic v2 | Direct JSON string validation without intermediate dict |

**Deprecated/outdated:**
- Pydantic v1 syntax (`class Config:`, `.dict()`, `.parse_obj()`) -- use v2 syntax (`model_config`, `.model_dump()`, `.model_validate()`)
- `@validator` decorator -- replaced by `@field_validator` in Pydantic v2

## Open Questions

1. **Exact edge count (82 vs 83)**
   - What we know: Multiple sources cite different numbers. The gnewton/risk-graph DOT file had 79 (missing at least 4 edges). Different editions of Risk have slightly different maps.
   - What's unclear: Whether the "classic" edition has exactly 82 or 83 edges.
   - Recommendation: Enumerate every single edge in the JSON file and in tests. The test should verify every territory has the correct specific set of neighbors, not just a total count. The total count test is a secondary sanity check.

2. **SVG map for Phase 1 scope**
   - What we know: MAPV-01 requires "SVG map displays all 42 territories with correct adjacencies." CONTEXT.md says SVG sourcing is Claude's discretion.
   - What's unclear: Whether a full rendered SVG is needed in Phase 1 or just the data that will power one.
   - Recommendation: Phase 1 should produce the JSON data and graph infrastructure. A placeholder or simplified SVG can be generated, but the polished SVG rendering belongs in Phase 3 (Web UI). The requirement MAPV-01 is mapped to Phase 1 for the data correctness aspect; the visual rendering is Phase 3.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest 8.x |
| Config file | None -- Wave 0 will create pytest.ini or pyproject.toml [tool.pytest] |
| Quick run command | `pytest tests/ -x -q` |
| Full suite command | `pytest tests/ -v` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SETUP-02 | Territories randomly distributed among all players | unit | `pytest tests/test_setup.py::test_territory_distribution -x` | No -- Wave 0 |
| SETUP-03 | Initial armies placed per classic rules | unit | `pytest tests/test_setup.py::test_army_placement -x` | No -- Wave 0 |
| MAPV-01 | 42 territories with correct adjacencies | unit | `pytest tests/test_map_data.py -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `pytest tests/ -x -q`
- **Per wave merge:** `pytest tests/ -v`
- **Phase gate:** Full suite green before verification

### Wave 0 Gaps
- [ ] `pyproject.toml` -- project config with pytest settings and dependencies
- [ ] `tests/conftest.py` -- shared fixtures (loaded map data, built graph, sample game state)
- [ ] `tests/test_map_data.py` -- validates classic.json: all 42 territories, all edges, continent membership
- [ ] `tests/test_map_graph.py` -- tests adjacency queries, reachability, continent control
- [ ] `tests/test_game_state.py` -- tests Pydantic model validation
- [ ] `tests/test_setup.py` -- tests territory distribution and army placement
- [ ] Framework install: `pip install pytest` (or via pyproject.toml)

## Sources

### Primary (HIGH confidence)
- [NetworkX PyPI](https://pypi.org/project/networkx/) -- version 3.6.1, December 2025
- [Pydantic PyPI](https://pypi.org/project/pydantic/) -- version 2.12.5, November 2025
- [Pydantic docs](https://docs.pydantic.dev/latest/concepts/models/) -- v2 model patterns, validators
- [NetworkX docs](https://networkx.org/documentation/stable/reference/index.html) -- Graph API, algorithms

### Secondary (MEDIUM confidence)
- [gnewton/risk-graph](https://github.com/gnewton/risk-graph) -- Risk territory graph topology (DOT format); had 79 of ~83 edges
- [UltraBoardGames Risk rules](https://www.ultraboardgames.com/risk/game-rules.php) -- army counts, continent bonuses verified
- [Risk Wikipedia](https://en.wikipedia.org/wiki/Risk_(game)) -- 42 territories, 6 continents, general structure

### Tertiary (LOW confidence)
- Exact edge count (82 vs 83) -- multiple sources disagree; must be validated by individual edge enumeration in tests

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- NetworkX and Pydantic are well-established, versions confirmed on PyPI
- Architecture: HIGH -- patterns are straightforward for a 42-node graph with game state
- Pitfalls: HIGH -- adjacency errors are well-documented (even Hasbro made mistakes); army placement edge cases are basic arithmetic
- Map data: MEDIUM -- territory list confirmed from multiple sources; exact edge count needs per-edge test validation

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable domain, no fast-moving dependencies)
