# Phase 4: Easy and Medium Bots - Research

**Researched:** 2026-03-09
**Domain:** Python AI agent design, continent-aware heuristic strategy, WebSocket protocol extension
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Difficulty Selection UI**
- One global difficulty dropdown on the setup screen: Easy / Medium
- All bot slots use the same difficulty
- Setup screen layout: Player count selector + Difficulty selector + Start button
- No per-bot difficulty in Phase 4 (v2 concern per REQUIREMENTS SETUP-04)

**Easy Bot Behavior**
- `RandomAgent` (already implemented in `risk/game.py`) IS the Easy bot
- BOTS-01 is already satisfied — just expose it via the UI and rename/alias as needed
- Easy bot: advantage-based attack selection, random reinforcement, 50% fortify chance
- No changes needed to RandomAgent behavior

**Medium Bot — Reinforcement**
- Reinforce territories on the borders of continents you're close to completing
- Border territory = adjacent to at least one enemy-owned territory
- Prioritize continents where the bot owns the most territories (closest to completion)
- Fall back to random owned territory if no suitable border territory found

**Medium Bot — Attack**
- Attack when both conditions hold: favorable odds (more armies than defender) AND strategic value
- Strategic value: target territory is in a continent where bot owns the most territories, OR blocking opponent from completing a continent
- Skip unfavorable attacks (bot armies ≤ defender armies) unless target would complete a continent bonus

**Medium Bot — Fortification**
- Move armies toward continent borders after attacking
- Border = owned territory adjacent to at least one enemy territory
- Pick the interior territory with the most surplus armies, move toward the most exposed border territory
- If no interior surplus, skip fortify

**Medium Bot — Card Trading**
- Same as Easy (RandomAgent): always trade when a valid set exists, never skip if forced
- Card trading strategy differences are Hard bot territory (Phase 5)

**Bot Labeling in UI**
- Bot names remain "Bot 1", "Bot 2", etc. — no difficulty shown during play
- Difficulty is global and set at game start; no need to repeat it in the turn indicator or game log
- PLAYER_NAMES constant in app.js stays as-is

### Claude's Discretion
- Exact continent-completion scoring formula for Medium bot
- How to break ties when multiple continents are equally close to completion
- Internal class structure for MediumAgent (new class vs subclass of RandomAgent)
- Test strategy for verifying Medium bot exhibits continent focus behavior

### Deferred Ideas (OUT OF SCOPE)
- Per-bot difficulty selection — v2 (REQUIREMENTS SETUP-04 already tracks this)
- Medium bot threat assessment (tracking which opponents are strongest) — Hard bot territory (Phase 5)
- Bot turn speed controls (slow/fast/instant) — v2 UIEN-01
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BOTS-01 | Easy bot makes random valid moves | `RandomAgent` already implements this; wire difficulty param through WebSocket + GameManager.setup() |
| BOTS-02 | Medium bot uses basic strategy (continent focus, reasonable attack decisions) | `MediumAgent` new class using `MapGraph.continent_territories()`, `neighbors()`, `connected_territories()`; continent-completion scoring formula documented in Architecture Patterns below |
</phase_requirements>

---

## Summary

Phase 4 has a narrow, well-scoped implementation surface. The "Easy bot" work is almost entirely wiring: `RandomAgent` already exists and plays valid games; the only task is propagating a `difficulty` field from the browser dropdown through the WebSocket message to `GameManager.setup()` so the correct class gets instantiated. No changes to `RandomAgent` itself are needed.

The "Medium bot" is the substantive new piece: a `MediumAgent` Python class that implements the six-method `PlayerAgent` protocol with continent-aware heuristics. All data it needs is already available — `MapGraph` exposes `continent_territories()`, `neighbors()`, and `connected_territories()`, and `GameState` carries the current territory ownership map. The class reads `GameState`, scores continents by ownership fraction, and uses that score to prioritize reinforcement targets, attack targets, and fortify destinations.

The full delivery is four discrete areas: (1) `MediumAgent` Python class, (2) `difficulty` field added to `StartGameMessage` and threaded through `app.py` → `GameManager.setup()`, (3) difficulty `<select>` added to `index.html`, and (4) the `start_game` send in `app.js` updated to include the selected difficulty value.

**Primary recommendation:** Implement `MediumAgent` as a standalone class in `risk/bots/medium.py` (new file, new package). Keep `RandomAgent` in `risk/game.py` untouched. Wire difficulty as a string literal `"easy" | "medium"` through the existing message/manager stack.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python stdlib `random` | 3.13 | RNG for MediumAgent (tie-breaking, fallback random choices) | Already used by RandomAgent; no new deps |
| Pydantic v2 | existing | `StartGameMessage` field extension | Already project dependency |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `networkx` | existing | MapGraph BFS via `connected_territories()` | Fortify path validation — already used |
| `pytest` | existing | Unit + integration tests for MediumAgent | All test coverage for this phase |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Standalone `MediumAgent` class | Subclass of `RandomAgent` | Subclassing saves ~30 lines but creates coupling to RandomAgent internals; standalone is cleaner and the Protocol is structural anyway |

**Installation:** No new packages required for this phase.

---

## Architecture Patterns

### Recommended Project Structure

```
risk/
├── bots/
│   ├── __init__.py          # exports MediumAgent
│   └── medium.py            # MediumAgent class
├── game.py                  # RandomAgent unchanged
├── server/
│   ├── game_manager.py      # setup() gains difficulty param
│   ├── messages.py          # StartGameMessage gains difficulty field
│   └── app.py               # parse difficulty from start_game message
└── static/
    ├── index.html           # add <select id="difficulty"> to setup form
    └── app.js               # read difficulty, include in start_game WS message
tests/
└── test_medium_agent.py     # new test file
```

The `risk/bots/` package isolates all agent implementations. Phase 5 will add `risk/bots/hard.py` in the same package. `RandomAgent` stays in `risk/game.py` for backwards compatibility with existing `test_full_game.py` imports.

### Pattern 1: Continent Scoring Formula

**What:** Score each continent as `(owned / total)` — the fraction of territories the bot already controls. Use this score to rank which continent to prioritize.

**When to use:** Reinforcement target selection, attack target selection, fortify destination selection.

**Implementation guidance (Claude's Discretion area):**

```python
# Continent completion ratio — higher is closer to completing
def _continent_scores(self, state: GameState) -> dict[str, float]:
    """Score each continent by how close the bot is to completing it."""
    player_idx = state.current_player_index
    owned = {n for n, ts in state.territories.items() if ts.owner == player_idx}
    scores: dict[str, float] = {}
    for continent, territories in self._map_graph._continent_territories.items():
        total = len(territories)
        have = len(territories & owned)
        scores[continent] = have / total
    return scores
```

Tie-breaking recommendation: when two continents have equal score, prefer the one with the higher `continent_bonus` value (higher strategic value). This produces consistent, observable behavior.

**The _continent_map attribute** (`MapGraph._continent_map[territory] -> continent_name`) maps any territory name to its continent. This is used to categorize attack targets without iterating all continents.

### Pattern 2: Border Territory Identification

**What:** A "border territory" is an owned territory that has at least one enemy neighbor. An "interior territory" is an owned territory whose all neighbors are also owned by the bot.

**When to use:** Reinforcement targeting (place on borders of prioritized continent), fortify source/destination determination.

```python
def _border_territories(self, state: GameState, owned: set[str]) -> list[str]:
    """Return owned territories adjacent to at least one enemy."""
    borders = []
    for name in owned:
        for neighbor in self._map_graph.neighbors(name):
            if state.territories[neighbor].owner != state.current_player_index:
                borders.append(name)
                break
    return borders
```

### Pattern 3: Continent-Aware Reinforcement

**What:** Place all armies on the border territory of the highest-scoring continent. If no border territory in that continent exists (e.g., bot owns all of it already), fall back to any border territory. If no border territories at all, place randomly on any owned territory (same fallback as `RandomAgent`).

**Implementation note:** Place all `armies` on a single target territory rather than distributing, since concentration is better strategy than spreading.

### Pattern 4: Continent-Aware Attack Selection

**What:** Build candidate attack list as in `RandomAgent`, then filter/sort by strategic value before applying the favorable-odds gate.

Scoring priority:
1. Attack completes a continent (highest priority — take it even if odds are unfavorable by ≤1)
2. Attack is in the highest-scoring continent AND favorable odds
3. Attack blocks an opponent who would complete a continent (their territory count in a continent equals total - 1, and the attack target is in that continent)
4. Any favorable-odds attack (fallback)

**Stopping condition:** Return `None` if no attack passes either the favorable-odds gate or the continent-completion exception. Do not implement a stop probability — let continent value drive stopping naturally.

### Pattern 5: `StartGameMessage` Extension

**What:** Add `difficulty: str = "easy"` field to `StartGameMessage` with a default so existing clients are backwards compatible.

```python
class StartGameMessage(BaseModel):
    type: Literal["start_game"] = "start_game"
    num_players: int = Field(ge=2, le=6)
    difficulty: str = "easy"   # "easy" | "medium"
```

**`GameManager.setup()` signature change:**

```python
def setup(
    self,
    num_players: int,
    map_graph: MapGraph,
    send_callback: Callable[[dict[str, Any]], Any],
    loop: asyncio.AbstractEventLoop | None = None,
    bot_delay: float | None = None,
    difficulty: str = "easy",   # NEW
) -> None:
```

Agent instantiation inside `setup()`:

```python
from risk.bots.medium import MediumAgent

for i in range(1, num_players):
    if difficulty == "medium":
        bot = MediumAgent(rng=random.Random())
    else:
        bot = RandomAgent(rng=random.Random())
    bot._map_graph = map_graph
    self.agents[i] = bot
```

`app.py` WebSocket handler:

```python
if msg_type == "start_game":
    num_players = data.get("num_players", 4)
    difficulty = data.get("difficulty", "easy")
    manager.setup(
        num_players=num_players,
        map_graph=map_graph,
        send_callback=lambda msg: _schedule_send(loop, websocket, msg),
        loop=loop,
        difficulty=difficulty,
    )
```

### Pattern 6: Frontend Difficulty Selector

**What:** Add a `<select id="difficulty">` element to the setup form in `index.html`, then read its value in the `startBtn` click handler in `app.js`.

`index.html` setup form addition (after `player-count` select, before `start-btn`):

```html
<label for="difficulty">Difficulty</label>
<select id="difficulty">
  <option value="easy" selected>Easy</option>
  <option value="medium">Medium</option>
</select>
```

`app.js` DOM reference addition:

```javascript
const difficultySelect = document.getElementById('difficulty');
```

`app.js` `start_game` message update:

```javascript
ws.send(JSON.stringify({
    type: 'start_game',
    num_players: numPlayers,
    difficulty: difficultySelect.value
}));
```

### Anti-Patterns to Avoid

- **Mutating RandomAgent:** `RandomAgent` in `risk/game.py` must not be changed. Its tests (`test_full_game.py`) must continue to pass.
- **map_graph access before injection:** `MediumAgent` methods that use `self._map_graph` must guard with `if self._map_graph is None: return <fallback>` — the same pattern as `RandomAgent`.
- **Infinite attack loops:** `choose_attack` must have a clear `return None` path. Without it, a bot with armies in one territory could attack forever. The favorable-odds gate serves as the primary stopping condition; add a turn counter safety if needed.
- **Storing per-turn mutable state in the agent:** Agents are stateless decision-makers by design (`STATE.md`). Any intermediate calculation (e.g., continent scores) must be computed fresh each call from `GameState`, not stored on `self`.
- **Using `_continent_map` directly:** It is a private attribute with a leading underscore. Prefer `MapGraph.continent_territories()` and `MapGraph.continent_bonus()` public methods when possible. The `_continent_map` reverse lookup (territory → continent name) has no public equivalent, so direct access is acceptable but should be noted in a comment.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BFS connectivity check | Custom graph traversal | `MapGraph.connected_territories()` | Already implemented and tested with NetworkX |
| Continent membership | Manual territory-to-continent mapping | `MapGraph._continent_map[territory]` (direct) or `continent_territories()` (reverse) | Already precomputed in `__init__`, O(1) lookups |
| Continent completeness check | Counting owned territories in continent | `MapGraph.controls_continent()` | Already implemented |
| Valid card set detection | Custom set validation | `risk.engine.cards.is_valid_set()` | Already used by RandomAgent |
| WebSocket send scheduling | asyncio boilerplate | `_schedule_send()` in `app.py` | Already implemented |

**Key insight:** All map-query primitives needed for continent-aware AI already exist in `MapGraph`. `MediumAgent` is pure decision logic on top of existing infrastructure.

---

## Common Pitfalls

### Pitfall 1: map_graph Not Injected at Construction Time

**What goes wrong:** `MediumAgent.__init__` does not receive `map_graph` as a constructor argument. The injection happens after construction in `GameManager.setup()` via `bot._map_graph = map_graph`. If any method is called before injection (which shouldn't happen in normal flow but could in tests), `self._map_graph` is `None` and methods must not crash.

**Why it happens:** `RandomAgent` established this pattern intentionally (see STATE.md: "map_graph injected into RandomAgent by run_game rather than constructor parameter").

**How to avoid:** Initialize `self._map_graph: MapGraph | None = None` and guard all methods with `if self._map_graph is None: return <safe_fallback>`.

**Warning signs:** `AttributeError: 'NoneType' has no attribute 'neighbors'` in any agent method.

### Pitfall 2: Fortify Leaves Source with 0 Armies

**What goes wrong:** Fortify action sends all armies from an interior territory, leaving it with 0 armies, which violates `TerritoryState.armies = Field(ge=1)`.

**Why it happens:** Off-by-one when calculating `surplus = armies - 1` (you must leave at least 1).

**How to avoid:** Always compute `armies_to_move = state.territories[source].armies - 1` and only fortify if this is >= 1.

### Pitfall 3: Attack Loop on Last Territory

**What goes wrong:** When a bot has armies only in territories that border exclusively their own lands (fully enclosed), `choose_attack` returns no valid attack pairs but a bug could cause an infinite loop.

**Why it happens:** The attack collection loop iterates all owned territories with >= 2 armies; if `options` is empty, `return None` must be reached.

**How to avoid:** The `if not options: return None` guard in `RandomAgent` must be preserved in `MediumAgent`'s attack logic.

### Pitfall 4: StartGameMessage Validation Rejects Unknown difficulty Values

**What goes wrong:** If difficulty field is added as `Literal["easy", "medium"]`, existing test payloads without the field would fail validation.

**Why it happens:** Pydantic v2 strict literal validation.

**How to avoid:** Use `str` type with a default of `"easy"`, not `Literal`. Validate the value in `GameManager.setup()` with a simple `if difficulty not in ("easy", "medium"): difficulty = "easy"` guard.

### Pitfall 5: Continent Score of 0.0 for All Continents Early Game

**What goes wrong:** In a 6-player game, a bot may own very few territories at game start, giving all continents a score near 0. The scoring formula still works correctly (it returns relative fractions), but if `max(scores.values()) == 0`, all continents tie at 0.0. The tie-breaking by continent bonus then kicks in, which is correct behavior.

**How to avoid:** No special case needed — the formula handles this naturally. Document in code comments.

---

## Code Examples

Verified patterns from existing codebase:

### Accessing Continent Data (from map_graph.py)
```python
# Get all territories in a continent
territories = map_graph.continent_territories("Australia")  # returns set[str]

# Check if player owns entire continent
map_graph.controls_continent("Australia", owned_set)  # returns bool

# Get continent bonus
bonus = map_graph.continent_bonus("Australia")  # returns int

# Reverse lookup: territory -> continent (private but no public equivalent)
continent_name = map_graph._continent_map["Eastern Australia"]
```

### GameState Ownership Query Pattern (from game.py RandomAgent)
```python
player_idx = state.current_player_index
owned = {n for n, ts in state.territories.items() if ts.owner == player_idx}
```

### Neighbor Iteration with Enemy Check (from game.py RandomAgent)
```python
for name, ts in state.territories.items():
    if ts.owner != player_idx or ts.armies < 2:
        continue
    for neighbor in mg.neighbors(name):
        nts = state.territories[neighbor]
        if nts.owner != player_idx:
            # valid attack: name -> neighbor
```

### map_graph Injection Pattern (from game_manager.py)
```python
bot = RandomAgent(rng=random.Random())
bot._map_graph = map_graph
self.agents[i] = bot
```

### run_game map_graph Injection (from game.py)
```python
for agent in agents.values():
    if isinstance(agent, RandomAgent):
        agent._map_graph = map_graph
```

Note: `run_game` only injects into `RandomAgent` instances by type check. `MediumAgent` will need to be added to this isinstance check, OR `run_game` should be updated to check for `_map_graph` attribute duck-typing. Since `run_game` is used in tests, this must be updated.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ABC-based agent interface | `typing.Protocol` structural subtyping | Phase 2 | `MediumAgent` does NOT inherit anything; just implements the 6 methods with matching signatures |
| All bots in game.py | `risk/bots/` package | Phase 4 (this phase) | Cleaner organization for Phase 5 Hard bot |

---

## Open Questions

1. **Should `run_game()` in `game.py` inject map_graph into `MediumAgent`?**
   - What we know: `run_game()` currently checks `isinstance(agent, RandomAgent)` to inject `_map_graph`. `MediumAgent` is a different class.
   - What's unclear: Whether `run_game()` needs to be updated for Phase 4 (it's used in `test_full_game.py` and simulation; GameManager handles injection for the WebSocket path).
   - Recommendation: Update `run_game()` to inject into any agent with `hasattr(agent, '_map_graph')` instead of `isinstance(agent, RandomAgent)`. This future-proofs for Phase 5 Hard bot too.

2. **MediumAgent continent score when bot is being eliminated (owns < 3 territories)**
   - What we know: The formula still works mathematically. With 1-2 territories, the bot will score one continent highest and reinforce there.
   - What's unclear: Whether this produces reasonable behavior or if a "survival mode" (reinforce the most heavily attacked territory) is better.
   - Recommendation: CONTEXT.md locks Medium bot to continent focus without a survival mode. Let the formula run as-is — this is Phase 5 territory per the locked decisions.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest (existing, see conftest.py) |
| Config file | none detected — runs via `python -m pytest tests/` |
| Quick run command | `python -m pytest tests/test_medium_agent.py -x -q` |
| Full suite command | `python -m pytest tests/ -x -q` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOTS-01 | Easy bot wired: `GameManager.setup(difficulty="easy")` creates `RandomAgent` instances | unit | `python -m pytest tests/test_medium_agent.py::TestDifficultyWiring::test_easy_creates_random_agent -x` | Wave 0 |
| BOTS-01 | Easy bot plays a full game without crash | integration | `python -m pytest tests/test_medium_agent.py::TestFullGameIntegration::test_full_game_easy_bot -x` | Wave 0 |
| BOTS-02 | `GameManager.setup(difficulty="medium")` creates `MediumAgent` instances | unit | `python -m pytest tests/test_medium_agent.py::TestDifficultyWiring::test_medium_creates_medium_agent -x` | Wave 0 |
| BOTS-02 | MediumAgent reinforcement places armies on border of top continent | unit | `python -m pytest tests/test_medium_agent.py::TestMediumAgentReinforce -x` | Wave 0 |
| BOTS-02 | MediumAgent attacks prioritize highest-scoring continent | unit | `python -m pytest tests/test_medium_agent.py::TestMediumAgentAttack -x` | Wave 0 |
| BOTS-02 | MediumAgent fortify moves armies toward border | unit | `python -m pytest tests/test_medium_agent.py::TestMediumAgentFortify -x` | Wave 0 |
| BOTS-02 | MediumAgent completes a full game without stalling | integration | `python -m pytest tests/test_medium_agent.py::TestFullGameIntegration::test_full_game_medium_bot -x` | Wave 0 |
| BOTS-02 | StartGameMessage accepts difficulty field, defaults to "easy" | unit | `python -m pytest tests/test_messages.py -x -q` (extend existing) | Exists |

### Sampling Rate
- **Per task commit:** `python -m pytest tests/test_medium_agent.py -x -q`
- **Per wave merge:** `python -m pytest tests/ -x -q`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/test_medium_agent.py` — covers BOTS-01 wiring, all BOTS-02 unit tests, full game integration
- [ ] Framework install: none needed — pytest already in use

---

## Sources

### Primary (HIGH confidence)
- Direct code reading: `risk/game.py` — `RandomAgent` full implementation, `run_game()` injection pattern
- Direct code reading: `risk/player.py` — `PlayerAgent` Protocol (6 methods, exact signatures)
- Direct code reading: `risk/engine/map_graph.py` — all public methods available to `MediumAgent`
- Direct code reading: `risk/server/game_manager.py` — `setup()` signature, bot instantiation loop
- Direct code reading: `risk/server/messages.py` — `StartGameMessage` current fields
- Direct code reading: `risk/server/app.py` — WebSocket handler `start_game` path
- Direct code reading: `risk/static/index.html` — setup form layout
- Direct code reading: `risk/static/app.js` — `startBtn` handler, `start_game` WS send
- Direct code reading: `risk/models/game_state.py` — `GameState`, `TerritoryState`, `PlayerState` fields
- Direct code reading: `.planning/phases/04-easy-and-medium-bots/04-CONTEXT.md` — all locked decisions
- Direct code reading: `.planning/STATE.md` — project decisions, agent design patterns

### Secondary (MEDIUM confidence)
- N/A — all research findings derived from direct codebase inspection; no external sources required for this implementation-only phase.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies exist; no new packages needed
- Architecture: HIGH — all integration points verified by reading actual source files
- Pitfalls: HIGH — derived from existing code patterns and known Pydantic/Python constraints

**Research date:** 2026-03-09
**Valid until:** 2026-04-09 (stable codebase, no external dependencies changing)
