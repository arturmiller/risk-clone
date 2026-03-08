# Technology Stack

**Project:** Risk Strategy Game
**Researched:** 2026-03-08

## Recommended Stack

### Runtime & Language

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Python | 3.12+ | Backend: game logic, AI bots, web server | Project requirement. 3.12 for performance improvements and type hint maturity. Avoid 3.14 (too new, ecosystem catching up). | HIGH |
| Vanilla JS (ES6+) | N/A | Frontend interactivity | No build tooling needed. Game UI is simple enough that React/Vue would be overengineering. Keeps the project dependency-light on the frontend. | HIGH |

### Web Framework & Server

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| FastAPI | ~0.135 | HTTP API + WebSocket server | Native WebSocket support for real-time game state push. Async-first architecture handles concurrent bot computation without blocking UI updates. Pydantic integration provides typed game state serialization for free. Far superior to Flask for this use case (Flask needs flask-socketio and has no native async). | HIGH |
| Uvicorn | ~0.41 | ASGI server | Standard FastAPI companion. Lightweight, fast, handles WebSocket connections natively. | HIGH |
| Pydantic | ~2.12 | Game state models & validation | Comes with FastAPI. Use for all game state models (Territory, Player, GameState). Serialization to JSON for frontend is automatic. TypedDict alternative is weaker -- Pydantic gives validation, serialization, and documentation. | HIGH |

### Game State & Graph

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| NetworkX | ~3.6 | Territory adjacency graph | Mature, well-documented graph library. Territory map is fundamentally a graph problem (42 nodes, ~82 edges). Provides pathfinding (connected territories for fortification), subgraph operations (continent detection), and adjacency queries out of the box. Pure Python, no compiled dependencies. | HIGH |

### Frontend Visualization

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| SVG (inline) | N/A | Territory map rendering | Territories are polygons with fills -- SVG is the natural fit. Each territory is a `<path>` element, colorable via CSS class, clickable via JS event listeners. Resolution-independent. Canvas would require reimplementing hit detection and repainting; SVG gets this for free from the DOM. | HIGH |
| D3.js | ~7.9 | SVG manipulation & data binding (optional) | Useful if territory coloring/transitions get complex, but may not be needed. Start without it -- vanilla JS can binddata to SVG paths. Add D3 only if you need animated transitions or complex data-driven updates. | MEDIUM |

### AI & Algorithms

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| NumPy | ~2.2 | Dice simulation, probability calculations, batch operations | Vectorized dice rolls are significantly faster than Python loops when simulating attack outcomes. Use `numpy.random.Generator` (not legacy `numpy.random.randint`). Essential for Hard bot's attack outcome evaluation (Monte Carlo simulation of combat). | HIGH |
| Custom heuristic engine | N/A | Bot decision-making (all tiers) | Risk's game tree is too large for minimax (branching factor in the hundreds). MCTS is viable but overkill for this project. The proven approach from academic literature is heuristic evaluation: score each possible action using weighted factors (continent control, border strength, army concentration, threat assessment). Easy bot = random + basic heuristics. Medium bot = good heuristics. Hard bot = tuned heuristics + Monte Carlo combat simulation. | HIGH |

### Testing & Dev Tools

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| pytest | ~8.x | Unit & integration testing | Standard Python test runner. Game logic is highly testable (deterministic with seeded RNG). | HIGH |
| pytest-asyncio | ~0.25 | Async test support | Needed for testing FastAPI WebSocket endpoints and async game loop. | HIGH |
| httpx | ~0.28 | HTTP test client | FastAPI's recommended test client (via `TestClient`). | HIGH |

### Project Structure & Tooling

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| uv | latest | Package management & virtual env | Faster than pip, handles lockfiles, replaces pip + pip-tools + venv. Modern Python standard. | HIGH |
| Ruff | latest | Linting & formatting | Replaces flake8 + black + isort. Single tool, extremely fast. | HIGH |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Web framework | FastAPI | Flask | No native async, no native WebSocket support, no built-in Pydantic. Would need flask-socketio (Socket.IO adds complexity) and manual serialization. |
| Web framework | FastAPI | Django | Massive overkill. ORM, admin panel, template engine -- none needed for a local game. |
| Territory graph | NetworkX | Custom adjacency dict | NetworkX is small, battle-tested, and provides pathfinding algorithms needed for fortification validation. Reinventing this is pointless. |
| Frontend rendering | SVG | HTML Canvas | Canvas requires manual hit detection (point-in-polygon), manual redraw loops, and loses DOM event model. SVG territories are DOM elements with native click/hover events. |
| Frontend rendering | SVG | Pixi.js / Phaser | Game engine libraries designed for sprite-based games with animation loops. Massive overkill for a static territory map with color fills. |
| Frontend framework | Vanilla JS | React / Vue | Build tooling overhead (webpack/vite), component abstraction unnecessary for a single-page game UI. The frontend is ~3 views: map, sidebar info, action buttons. |
| AI approach | Heuristic evaluation | Minimax | Risk's branching factor makes minimax infeasible without extreme pruning. A single turn can involve dozens of attack/fortify decisions. |
| AI approach | Heuristic evaluation | Neural network (AlphaZero-style) | Training infrastructure, data generation, and complexity far exceed project scope. Academic papers show it works but requires thousands of GPU-hours of self-play. |
| AI approach | Heuristic evaluation | Pure MCTS | Viable but slower to implement correctly, and heuristic bots can be just as strong for Risk with proper tuning. MCTS shines in games with simpler action spaces. |
| Dice/random | NumPy | stdlib random | NumPy's vectorized operations make batch combat simulation (hundreds of dice rolls for Hard bot evaluation) 10-100x faster. |
| Package manager | uv | pip + venv | uv is faster, handles lockfiles natively, and is the direction the Python ecosystem is heading. |

## What NOT to Use

| Technology | Why Not |
|------------|---------|
| Pygame | Desktop GUI library, not web-based. Project requires browser-based frontend. |
| Socket.IO | Adds protocol complexity on top of WebSockets. FastAPI's native WebSocket support is sufficient for a single-client local game. |
| SQLite / any database | Game state lives in memory for the duration of a game. No persistence needed (local-only, single session). If save/load is added later, JSON file serialization via Pydantic is simpler. |
| Celery / task queues | Bot computation is fast enough to run in-process. No need for distributed task processing. |
| Docker | Local development only. Python venv via uv is sufficient. |
| TypeScript | Adds build step complexity. The frontend JS is small enough (~500-1000 lines) that type safety from TS doesn't justify the tooling overhead. |
| Jinja2 / templates | Serve a single static HTML file. Game state updates via WebSocket, not page reloads. |

## Installation

```bash
# Initialize project with uv
uv init risk-game
cd risk-game

# Core dependencies
uv add fastapi uvicorn[standard] pydantic networkx numpy

# Dev dependencies
uv add --dev pytest pytest-asyncio httpx ruff
```

## Frontend Dependencies

No package manager needed. Either:
- Use vanilla JS (recommended starting point)
- Add D3.js via CDN if needed later: `<script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>`

## Project Structure (Recommended)

```
risk/
  backend/
    __init__.py
    main.py              # FastAPI app, WebSocket endpoint
    models.py            # Pydantic models (GameState, Territory, Player, etc.)
    game/
      __init__.py
      engine.py          # Game rules engine (turn phases, combat resolution)
      board.py           # Territory graph (NetworkX), map data
      cards.py           # Territory card deck, set trading
      combat.py          # Dice rolling, combat resolution (NumPy)
    bots/
      __init__.py
      base.py            # Bot interface (abstract base class)
      easy.py            # Random + basic heuristics
      medium.py          # Weighted heuristics
      hard.py            # Tuned heuristics + Monte Carlo combat eval
      heuristics.py      # Shared evaluation functions
  frontend/
    index.html           # Single page app
    style.css
    app.js               # WebSocket client, UI controller
    map.js               # SVG map rendering & interaction
    map.svg              # Territory paths (42 territories)
  tests/
    test_engine.py
    test_combat.py
    test_bots.py
    test_api.py
  pyproject.toml
```

## Key Integration Points

### FastAPI <-> Frontend (WebSocket)

```python
# Server pushes game state as JSON after each action
@app.websocket("/ws/game/{game_id}")
async def game_ws(websocket: WebSocket, game_id: str):
    await websocket.accept()
    # Send full game state on connect
    await websocket.send_json(game.state.model_dump())
    # Receive player actions, process, broadcast updated state
```

### Pydantic <-> NetworkX (Game State)

```python
class Territory(BaseModel):
    id: str
    name: str
    continent: str
    owner: str | None = None
    armies: int = 0
    # Adjacency stored in NetworkX graph, not in model
```

### NumPy <-> Combat Resolution

```python
def simulate_combat(attackers: int, defenders: int, n_simulations: int = 10000) -> float:
    """Monte Carlo combat outcome probability using vectorized NumPy dice rolls."""
    rng = numpy.random.default_rng()
    # Vectorize across all simulations simultaneously
    attacker_dice = rng.integers(1, 7, size=(n_simulations, min(attackers, 3)))
    defender_dice = rng.integers(1, 7, size=(n_simulations, min(defenders, 2)))
    # ... compare sorted dice, return win probability
```

## Sources

- [FastAPI Releases](https://github.com/fastapi/fastapi/releases) - Version 0.135.x confirmed
- [FastAPI WebSocket Documentation](https://fastapi.tiangolo.com/advanced/websockets/) - Native WebSocket support
- [Pydantic v2.12 Release](https://pydantic.dev/articles/pydantic-v2-12-release) - Current stable version
- [Uvicorn PyPI](https://pypi.org/project/uvicorn/) - Version 0.41.0
- [NetworkX 3.6.1 Documentation](https://networkx.org/documentation/stable/tutorial.html) - Current stable, adjacency API
- [D3.js](https://d3js.org/) - Version 7.9.0
- [NumPy for Risk Dice Simulation](https://thepythoncodingbook.com/2022/12/30/using-python-numpy-to-improve-board-game-strategy-risk/) - Vectorized dice approach
- [Risk AI Heuristic Evaluation](https://project.dke.maastrichtuniversity.nl/games/files/bsc/Hahn_Bsc-paper.pdf) - Academic analysis of Risk heuristics
- [RISK AI Project (Gettysburg)](http://modelai.gettysburg.edu/2019/risk/RISK_AI_Handout.pdf) - Heuristic bot implementation guide
- [Risk AlphaZero Paper](https://www.diva-portal.org/smash/get/diva2:1514096/FULLTEXT01.pdf) - Why neural approach is overkill for this scope
- [SVG Interactive Maps](https://www.petercollingridge.co.uk/tutorials/svg/interactive/interactive-map/) - SVG territory interaction patterns
