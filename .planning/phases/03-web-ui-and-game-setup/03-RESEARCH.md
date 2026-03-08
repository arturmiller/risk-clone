# Phase 3: Web UI and Game Setup - Research

**Researched:** 2026-03-08
**Domain:** WebSocket game server, interactive SVG frontend, async/sync bridge
**Confidence:** HIGH

## Summary

Phase 3 bridges the existing synchronous Python game engine (Pydantic models, `execute_turn()` loop) with a browser-based UI via WebSockets. The core architectural challenge is that `execute_turn()` runs synchronously, calling `agent.choose_*()` methods that block until they return -- but for a human player, those methods must wait for WebSocket messages from the browser. The solution is to run the game loop in a background thread using `asyncio.to_thread()`, with the human agent's decision methods blocking on `asyncio` primitives (an `asyncio.Queue` or `asyncio.Event`) that get fulfilled when WebSocket messages arrive.

The frontend is a single HTML page with inline or bundled vanilla JavaScript -- no framework needed. The SVG map from `classic.json` territory data will be generated programmatically (or from a static SVG asset with territory IDs matching `classic.json` names). The sidebar shows turn phase, continent bonuses, and a scrollable game log. FastAPI serves both the static page and the WebSocket endpoint.

**Primary recommendation:** Use FastAPI with `websockets` for the server, vanilla JS for the frontend, and `asyncio.Queue` to bridge the sync game loop with async WebSocket I/O. Run the game loop in a thread via `asyncio.to_thread()`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Click-click model: click source territory (highlights), then click target territory for attacks and fortification
- Valid targets indicated by glowing/thicker borders; invalid territories dim slightly
- Reinforcement: click a territory to open a number input for how many armies to place; counter shows remaining armies
- Attack dice: defaults to max dice (3 if possible); small UI element allows reducing dice count
- Post-conquest: prompt asks how many armies to move in (minimum = dice rolled)
- Setup screen offers only player count (2-6) and a Start button
- Human is always Player 1 (goes first); other slots filled by RandomAgent bots
- Colors and names auto-assigned (no customization in v1)
- Single HTML page: setup form shows first, replaced by game board on start (no routing)
- Game end: show win/loss result with a "New Game" button that returns to setup
- Map takes ~75% of screen width; right sidebar contains turn info, continent bonuses, and game log
- Turn phase indicator: horizontal stepper at top of sidebar showing Reinforce -> Attack -> Fortify
- Continent bonuses: sidebar section listing each continent, its bonus value, and human control count
- Game log: scrollable list of key events only (attacks, conquests, card trades, eliminations, reinforcement totals)
- Phase prompt banner: clear banner when it is the human's turn
- Bot turns execute with brief delays (~500ms between actions); map updates in real time
- Human always auto-defends with max dice during bot attacks (no interruption)
- Banner disappears during bot turns; reappears when human's turn begins

### Claude's Discretion
- WebSocket server framework choice (FastAPI, aiohttp, etc.)
- SVG map creation/sourcing approach (decided in Phase 1)
- Frontend framework choice (vanilla JS vs lightweight library)
- Exact styling, spacing, and color palette
- Error handling for invalid moves in the UI
- Card trading UI design (how to present cards and trade options)
- How to present dice roll results visually

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SETUP-01 | Player can select number of players (2-6) | Setup screen with count selector and Start button; WebSocket sends setup message to server |
| MAPV-02 | Territories are colored by owning player | SVG `fill` attribute updated per GameState snapshot; 6-color palette for players |
| MAPV-03 | Army count is displayed on each territory | SVG `<text>` elements positioned at territory centroids, updated on state change |
| MAPV-04 | Territories are clickable for game actions | Click event listeners on SVG `<path>` elements; click-click source/target model |
| MAPV-05 | Current turn phase and active player are clearly indicated | Sidebar stepper (Reinforce/Attack/Fortify) + player name/color banner |
| MAPV-06 | Game log shows event history | Scrollable sidebar list; server sends structured event messages over WebSocket |
| MAPV-07 | Continent bonus information is displayed | Sidebar section computed from GameState + map_graph continent data |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| FastAPI | >=0.110 | WebSocket server + static file serving | Already uses Pydantic (matches project); built-in WebSocket support; serves static files via StaticFiles mount |
| uvicorn | >=0.29 | ASGI server to run FastAPI | Standard FastAPI deployment server |
| websockets | >=12.0 | WebSocket protocol (FastAPI dependency) | Pulled in by FastAPI; no separate install needed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jinja2 | >=3.1 | Optional HTML templating | Only if injecting map data into HTML at serve time; can skip if using pure static HTML + fetch |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| FastAPI | aiohttp | aiohttp is lighter but lacks Pydantic integration; FastAPI already matches project's Pydantic v2 stack |
| FastAPI | plain `websockets` lib | Would need separate HTTP server for static files; FastAPI bundles both |
| Vanilla JS | Preact/Alpine.js | Adds build step complexity; vanilla JS is sufficient for this UI complexity level |

### Installation
```bash
pip install fastapi uvicorn[standard]
```

Add to `pyproject.toml` dependencies:
```toml
dependencies = [
    "networkx>=3.0",
    "pydantic>=2.0",
    "fastapi>=0.110",
    "uvicorn[standard]>=0.29",
]
```

## Architecture Patterns

### Recommended Project Structure
```
risk/
├── server/
│   ├── __init__.py
│   ├── app.py            # FastAPI app, static mount, WebSocket endpoint
│   ├── game_manager.py   # Game lifecycle: create, run in thread, manage state
│   ├── human_agent.py    # HumanWebSocketAgent implementing PlayerAgent protocol
│   └── messages.py       # Pydantic models for WebSocket message protocol
├── static/
│   ├── index.html         # Single-page app (setup + game board)
│   ├── style.css          # Layout and styling
│   ├── app.js             # Main application logic, WebSocket client
│   ├── map.js             # SVG map rendering and interaction
│   └── sidebar.js         # Turn info, continent bonuses, game log
├── engine/                # (existing)
├── models/                # (existing)
├── data/
│   ├── classic.json       # (existing)
│   └── classic_map.svg    # SVG map asset (territories as <path> elements)
├── game.py                # (existing)
└── player.py              # (existing)
```

### Pattern 1: Async/Sync Bridge via asyncio.Queue
**What:** The game loop runs synchronously in a thread. The HumanWebSocketAgent blocks on an `asyncio.Queue.get()` (via `asyncio.run_coroutine_threadsafe`) when it needs human input. The WebSocket handler puts player actions into that queue.
**When to use:** Every human decision point (choose_attack, choose_fortify, etc.)

```python
import asyncio
from concurrent.futures import Future

class HumanWebSocketAgent:
    """PlayerAgent that bridges sync game loop with async WebSocket."""

    def __init__(self, loop: asyncio.AbstractEventLoop):
        self._loop = loop
        self._input_queue: asyncio.Queue = asyncio.Queue()
        self._state_callback = None  # set by game_manager

    def _wait_for_input(self):
        """Block the game thread until WebSocket delivers player input."""
        future: Future = asyncio.run_coroutine_threadsafe(
            self._input_queue.get(), self._loop
        )
        return future.result()  # blocks the game thread

    def choose_attack(self, state):
        # Send state + prompt to browser, then wait
        self._send_state(state, "choose_attack")
        raw = self._wait_for_input()
        if raw is None:
            return None  # player chose to end attack phase
        return AttackAction(**raw)

    # ... similar for all other PlayerAgent methods
```

### Pattern 2: Game Manager with Thread Lifecycle
**What:** A GameManager class owns the game lifecycle -- creates agents, starts the game loop in a thread, and handles WebSocket message routing.
**When to use:** On "start game" message from the browser.

```python
import asyncio
from threading import Thread

class GameManager:
    def __init__(self):
        self.human_agent = None
        self.game_task = None

    async def start_game(self, num_players: int, websocket):
        loop = asyncio.get_event_loop()
        self.human_agent = HumanWebSocketAgent(loop)
        self.human_agent.set_send_callback(
            lambda msg: asyncio.run_coroutine_threadsafe(
                websocket.send_json(msg), loop
            )
        )

        agents = {0: self.human_agent}
        for i in range(1, num_players):
            agents[i] = RandomAgent()

        # Run synchronous game loop in thread
        self.game_task = asyncio.get_event_loop().run_in_executor(
            None, self._run_game, agents
        )

    def _run_game(self, agents):
        # This runs in a thread -- calls execute_turn() synchronously
        map_graph = MapGraph(load_map(...))
        run_game(map_graph, agents, random.Random())
```

### Pattern 3: WebSocket Message Protocol
**What:** Typed JSON messages between server and client, using a `type` discriminator field.
**When to use:** All WebSocket communication.

```python
# Server -> Client messages
{"type": "game_state", "state": {...}, "phase_prompt": "Place 5 reinforcements"}
{"type": "request_input", "input_type": "choose_attack", "valid_sources": [...]}
{"type": "game_event", "event": "attack", "details": {...}}
{"type": "game_over", "winner": 0, "is_human_winner": true}

# Client -> Server messages
{"type": "start_game", "num_players": 4}
{"type": "player_action", "action_type": "attack", "data": {"source": "Alaska", "target": "Kamchatka", "num_dice": 3}}
{"type": "player_action", "action_type": "end_phase"}
```

### Pattern 4: SVG Map Rendering
**What:** Each territory is an SVG `<path>` or `<polygon>` element with an `id` matching the territory name (or a `data-territory` attribute). Army counts are `<text>` elements overlaid at territory centroids.
**When to use:** Map display and updates.

```javascript
function updateMap(gameState) {
    for (const [name, territory] of Object.entries(gameState.territories)) {
        const el = document.querySelector(`[data-territory="${name}"]`);
        if (el) {
            el.style.fill = PLAYER_COLORS[territory.owner];
            el.style.opacity = '1';
        }
        const label = document.querySelector(`[data-army-label="${name}"]`);
        if (label) {
            label.textContent = territory.armies;
        }
    }
}
```

### Anti-Patterns to Avoid
- **Running game loop in the async event loop:** The synchronous `execute_turn()` will block the event loop, freezing WebSocket I/O. Always use `run_in_executor()` or `asyncio.to_thread()`.
- **Polling for state changes:** Use the queue/callback pattern instead of having the frontend poll for updates.
- **Mutating SVG DOM on every minor change:** Batch updates -- receive full GameState, update all territories at once.
- **Tight coupling between game engine and server:** The engine should remain unaware of WebSockets. The HumanWebSocketAgent is the sole bridge.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WebSocket protocol handling | Raw socket management | FastAPI WebSocket support | Handles handshake, ping/pong, frame parsing, connection lifecycle |
| JSON serialization of game state | Custom serializers | Pydantic `model_dump(mode="json")` | Handles enums, nested models, datetime automatically |
| ASGI server | Custom HTTP server | uvicorn | Production-grade, handles signals, reload, logging |
| SVG world map geometry | Drawing 42 territories by hand | Use existing Risk SVG map or generate from coordinate data | Getting territory shapes right is hours of work with no game logic value |
| Async/sync thread safety | Manual threading locks | `asyncio.run_coroutine_threadsafe()` + `asyncio.Queue` | Correctly handles cross-thread async coordination |

**Key insight:** The game engine is already complete and well-tested. Phase 3 is a presentation/bridge layer -- the less custom code between the engine and the browser, the fewer bugs.

## Common Pitfalls

### Pitfall 1: Blocking the asyncio Event Loop
**What goes wrong:** Calling synchronous game engine code directly in a WebSocket handler freezes all I/O.
**Why it happens:** `execute_turn()` calls `agent.choose_attack()` which for bots returns instantly, but for human blocks on input. If this runs in the event loop, the server cannot process any messages.
**How to avoid:** Always run the game loop in a separate thread via `asyncio.to_thread()` or `run_in_executor()`.
**Warning signs:** Server stops responding to WebSocket pings; frontend connection drops.

### Pitfall 2: Thread-Safety of asyncio Primitives
**What goes wrong:** Calling `queue.put()` from the async side while `queue.get()` is awaited from a thread.
**Why it happens:** `asyncio.Queue` is not thread-safe for direct use across threads.
**How to avoid:** From the game thread, use `asyncio.run_coroutine_threadsafe(queue.get(), loop)` to interact with the queue. From the async WebSocket handler, use `queue.put_nowait()` or `await queue.put()` normally since you are already in the event loop.
**Warning signs:** Deadlocks, missed messages, `RuntimeError: no running event loop`.

### Pitfall 3: Territory Name Mismatch Between SVG and Game State
**What goes wrong:** Clicking a territory in the SVG sends a name that does not match `classic.json` territory names.
**Why it happens:** SVG element IDs might use hyphens, underscores, or different casing than the game state keys.
**How to avoid:** Use `data-territory` attributes on SVG elements with exact `classic.json` territory names. Validate at startup that all 42 territories have matching SVG elements.
**Warning signs:** Clicks produce "unknown territory" errors; map shows wrong colors.

### Pitfall 4: GameState Serialization of Enums
**What goes wrong:** Pydantic enums serialize as `"TurnPhase.ATTACK"` or integer values instead of readable strings.
**Why it happens:** Default Pydantic v2 enum serialization behavior.
**How to avoid:** Use `model_dump(mode="json")` which serializes enums to their value. Or define custom serializers. Test serialization output before building frontend parsing.
**Warning signs:** Frontend JavaScript comparisons like `phase === "ATTACK"` fail silently.

### Pitfall 5: Bot Turn Speed and UI Responsiveness
**What goes wrong:** Bot turns execute instantly (milliseconds), making the game unreadable.
**Why it happens:** `RandomAgent.choose_*()` methods return immediately; the game loop runs 5 bot turns in under a second.
**How to avoid:** Insert `time.sleep(0.5)` delays in the game thread between bot actions, or have the GameManager inject delays around bot `execute_turn()` calls. The game loop runs in a thread so `time.sleep()` is safe and does not block the event loop.
**Warning signs:** Map shows final state instantly; game log floods with entries.

### Pitfall 6: WebSocket Connection Lifecycle
**What goes wrong:** Game thread continues running after browser disconnects; or game state leaks between sessions.
**Why it happens:** No cleanup on WebSocket close; game thread has no cancellation mechanism.
**How to avoid:** Set a cancellation flag that the game loop checks between turns. On WebSocket disconnect, set the flag and let the thread exit gracefully. Clear GameManager state.
**Warning signs:** Orphaned game threads consuming CPU; stale state on reconnection.

## Code Examples

### FastAPI WebSocket Endpoint
```python
# Source: FastAPI official docs + project-specific patterns
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles

app = FastAPI()
app.mount("/static", StaticFiles(directory="risk/static"), name="static")

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    manager = GameManager()

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "start_game":
                await manager.start_game(
                    num_players=data["num_players"],
                    websocket=websocket,
                )
            elif msg_type == "player_action":
                await manager.handle_player_action(data)
    except WebSocketDisconnect:
        manager.cancel_game()
```

### Pydantic GameState to JSON for Frontend
```python
# Serialize GameState for WebSocket transmission
def state_to_message(state: GameState, prompt: str | None = None) -> dict:
    data = state.model_dump(mode="json")
    return {
        "type": "game_state",
        "state": data,
        "prompt": prompt,
    }
```

### SVG Territory Click Handling (Vanilla JS)
```javascript
// Attach click handlers to all territory paths
document.querySelectorAll('[data-territory]').forEach(el => {
    el.addEventListener('click', () => {
        const territory = el.dataset.territory;
        handleTerritoryClick(territory);
    });
    el.addEventListener('mouseenter', () => {
        el.classList.add('hovered');
    });
    el.addEventListener('mouseleave', () => {
        el.classList.remove('hovered');
    });
});

function handleTerritoryClick(territory) {
    if (currentInputType === 'choose_attack') {
        if (!selectedSource) {
            // First click: select source
            if (validSources.includes(territory)) {
                selectedSource = territory;
                highlightValidTargets(territory);
            }
        } else {
            // Second click: select target
            if (validTargets.includes(territory)) {
                sendAction({
                    type: 'player_action',
                    action_type: 'attack',
                    data: { source: selectedSource, target: territory, num_dice: selectedDice }
                });
                clearSelection();
            }
        }
    }
}
```

### WebSocket Client Setup (Vanilla JS)
```javascript
const ws = new WebSocket(`ws://${window.location.host}/ws`);

ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    switch (msg.type) {
        case 'game_state':
            updateMap(msg.state);
            updateSidebar(msg.state);
            if (msg.prompt) showPromptBanner(msg.prompt);
            break;
        case 'request_input':
            enableInputMode(msg.input_type, msg);
            break;
        case 'game_event':
            appendToGameLog(msg);
            break;
        case 'game_over':
            showGameOverScreen(msg);
            break;
    }
};

function sendAction(action) {
    ws.send(JSON.stringify(action));
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Synchronous WSGI + long-polling | ASGI + WebSocket | 2020+ | Real-time bidirectional communication; no polling overhead |
| jQuery DOM manipulation | Vanilla JS (querySelector, dataset, classList) | 2018+ | No dependency needed; modern browser APIs are sufficient |
| Pydantic v1 `.dict()` | Pydantic v2 `.model_dump(mode="json")` | 2023 | Proper enum/type serialization for JSON transport |
| `threading.Event` for async bridge | `asyncio.run_coroutine_threadsafe()` | Python 3.7+ | Safe cross-thread async coordination |

**Deprecated/outdated:**
- Pydantic v1 `.dict()` / `.json()` -- use `.model_dump()` / `.model_dump_json()` in v2
- `@app.on_event("startup")` in FastAPI -- use lifespan context manager instead (but not needed here)

## Open Questions

1. **SVG Map Asset Source**
   - What we know: `classic.json` has 42 territory names. STATE.md flags "SVG map asset needs to be sourced or created."
   - What's unclear: Whether to find a public-domain Risk SVG, generate simplified territory polygons programmatically, or draw from scratch.
   - Recommendation: Generate a simplified SVG programmatically with approximate territory positions and shapes. Exact geographic accuracy is not needed for a functional game. Alternatively, use a public-domain world map SVG and add `data-territory` attributes to regions. The simplest approach is a schematic/abstract map with labeled regions -- functional UI, not fancy.

2. **Post-Conquest Army Movement UI**
   - What we know: User decision says "prompt asks how many armies to move in (minimum = dice rolled)."
   - What's unclear: The current `execute_attack()` auto-moves `num_dice` armies on conquest. The engine may need a minor modification to support variable army movement post-conquest, OR the UI can handle this as a separate fortify-like action immediately after conquest.
   - Recommendation: For v1, keep the engine behavior (auto-move `num_dice` armies) and show it in the UI. If the user wants strategic choice, a small engine modification to `execute_attack()` would be needed -- flag this for the planner.

3. **Card Trading UI**
   - What we know: Cards have territory + type (Infantry/Cavalry/Artillery/Wild). Valid sets are 3 of same type or 1 of each.
   - What's unclear: Exact visual design for displaying cards and selecting sets.
   - Recommendation: Simple card display as styled divs showing card type icon + territory name. "Trade" button enables when a valid set of 3 is selected. Forced trade shows a modal.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest >= 8.0 |
| Config file | `pyproject.toml [tool.pytest.ini_options]` |
| Quick run command | `pytest tests/ -x --timeout=10` |
| Full suite command | `pytest tests/` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SETUP-01 | Player count selection creates game with N players | integration | `pytest tests/test_server.py::test_start_game_creates_correct_players -x` | No -- Wave 0 |
| MAPV-02 | GameState serialization includes owner for coloring | unit | `pytest tests/test_server.py::test_state_serialization_includes_owners -x` | No -- Wave 0 |
| MAPV-03 | GameState serialization includes army counts | unit | `pytest tests/test_server.py::test_state_serialization_includes_armies -x` | No -- Wave 0 |
| MAPV-04 | Player action messages parsed into valid game actions | unit | `pytest tests/test_server.py::test_action_message_parsing -x` | No -- Wave 0 |
| MAPV-05 | State message includes turn phase and current player | unit | `pytest tests/test_server.py::test_state_includes_phase_and_player -x` | No -- Wave 0 |
| MAPV-06 | Game events are emitted for attacks, conquests, etc. | integration | `pytest tests/test_server.py::test_game_events_emitted -x` | No -- Wave 0 |
| MAPV-07 | Continent bonus data is available in state/message | unit | `pytest tests/test_server.py::test_continent_data_in_messages -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `pytest tests/test_server.py -x --timeout=10`
- **Per wave merge:** `pytest tests/ --timeout=30`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/test_server.py` -- covers SETUP-01, MAPV-02 through MAPV-07 (server-side logic)
- [ ] `tests/test_human_agent.py` -- covers HumanWebSocketAgent queue bridging
- [ ] `tests/test_messages.py` -- covers WebSocket message serialization/deserialization
- [ ] Framework install: `pip install fastapi uvicorn[standard] httpx pytest-asyncio` (httpx for FastAPI TestClient WebSocket testing)
- [ ] `pytest-asyncio` -- needed for async test functions

## Sources

### Primary (HIGH confidence)
- Project codebase: `risk/player.py`, `risk/game.py`, `risk/engine/turn.py`, `risk/models/` -- direct code analysis of existing engine
- [FastAPI WebSocket docs](https://fastapi.tiangolo.com/advanced/websockets/) -- WebSocket endpoint patterns
- [FastAPI Static Files docs](https://fastapi.tiangolo.com/tutorial/static-files/) -- StaticFiles mount pattern
- [Python asyncio docs](https://docs.python.org/3/library/asyncio.html) -- `run_coroutine_threadsafe`, Queue, event loop

### Secondary (MEDIUM confidence)
- [websockets 16.0 asyncio FAQ](https://websockets.readthedocs.io/en/stable/faq/asyncio.html) -- async/sync bridge patterns verified
- [Peter Collingridge SVG interactive map tutorial](https://www.petercollingridge.co.uk/tutorials/svg/interactive/interactive-map/) -- SVG click interaction patterns
- [7webpages multiplayer game with asyncio](https://7webpages.com/blog/writing-online-multiplayer-game-with-python-and-asyncio-writing-game-loop/) -- game loop in asyncio patterns

### Tertiary (LOW confidence)
- SVG map asset availability -- needs validation during implementation (may need to generate programmatically)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- FastAPI + Pydantic is natural fit for this project; well-documented
- Architecture: HIGH -- async/sync bridge pattern is well-established; game engine code analyzed directly
- Pitfalls: HIGH -- identified from direct code analysis (synchronous execute_turn, enum serialization, territory naming)
- SVG map asset: LOW -- sourcing/creating the actual map geometry is unresearched; flagged as open question

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable domain, no fast-moving dependencies)
