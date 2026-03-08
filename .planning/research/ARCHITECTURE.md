# Architecture Patterns

**Domain:** Risk-like turn-based strategy board game with AI bots
**Researched:** 2026-03-08

## Recommended Architecture

The system follows a **server-authoritative, state-machine-driven** architecture with clear separation between game logic, AI, and presentation. The server (Python) owns all game state and rule enforcement. The client (browser) is a thin view layer that sends player actions and renders state updates.

```
+------------------------------------------------------------------+
|                        Python Backend                             |
|                                                                   |
|  +------------+    +-------------+    +-----------------------+   |
|  |            |    |             |    |                       |   |
|  |  Map/Graph |<-->| Game State  |<-->|   Turn Engine (FSM)   |   |
|  |   Module   |    |  Container  |    |                       |   |
|  |            |    |             |    |  Reinforce -> Attack   |   |
|  +------------+    +------+------+    |  -> Fortify -> Next   |   |
|                           |           +-----------+-----------+   |
|                           |                       |               |
|                    +------v------+    +-----------v-----------+   |
|                    |             |    |                       |   |
|                    | Combat      |    |   Player Interface    |   |
|                    | Resolver    |    |   (Human / Bot ABC)   |   |
|                    |             |    |                       |   |
|                    +-------------+    |  +-------+ +-------+ |   |
|                                       |  | Easy  | | Hard  | |   |
|                                       |  | Bot   | | Bot   | |   |
|                                       |  +-------+ +-------+ |   |
|                                       +-----------------------+   |
|                                                                   |
|  +------------------------------------------------------------+  |
|  |              Action Validator / Rule Engine                 |  |
|  +------------------------------------------------------------+  |
|                                                                   |
|  +------------------------------------------------------------+  |
|  |              WebSocket Server (FastAPI)                     |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
        |  WebSocket (JSON messages)  ^
        v                             |
+------------------------------------------------------------------+
|                      Browser Client                               |
|                                                                   |
|  +------------------+  +------------------+  +-----------------+  |
|  | Map Renderer     |  | Game Info Panel  |  | Action Controls |  |
|  | (SVG/Canvas)     |  | (armies, cards)  |  | (buttons, dice) |  |
|  +------------------+  +------------------+  +-----------------+  |
+------------------------------------------------------------------+
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Map/Graph Module** | Territory definitions, adjacency graph, continent groupings, pathfinding (connected territory checks) | Game State (reads map structure), Turn Engine (validates moves) |
| **Game State Container** | Single source of truth: territory ownership, army counts, player hands (cards), turn order, elimination status | All backend components read from it; only Turn Engine and Action Validator mutate it |
| **Turn Engine (FSM)** | Drives the game loop through phases: Setup -> Reinforce -> Attack -> Fortify -> Next Player. Manages turn transitions and win condition checks | Game State (reads/writes), Player Interface (requests actions), Combat Resolver (delegates attacks) |
| **Combat Resolver** | Dice rolling, attacker/defender loss calculation, territory capture, card awards | Turn Engine (called during attack phase), Game State (reads armies, writes results) |
| **Action Validator / Rule Engine** | Validates every action against current game state and rules before execution. Rejects illegal moves | Turn Engine (pre-action check), Game State (reads for validation) |
| **Player Interface (ABC)** | Abstract base class that both HumanPlayer and Bot classes implement. Defines the contract: `choose_reinforce()`, `choose_attack()`, `choose_fortify()`, etc. | Turn Engine (called for decisions), Game State (reads for decision-making) |
| **Bot AI Implementations** | Concrete Player Interface implementations with varying strategy depth (Easy=random, Medium=heuristic, Hard=strategic) | Player Interface contract, Game State (reads for analysis), Map/Graph (reads for pathfinding/territory analysis) |
| **WebSocket Server** | Bridges backend to browser. Sends state updates, receives human player actions. Translates between JSON messages and internal action objects | HumanPlayer adapter (forwards actions), Game State (serializes for client) |
| **Browser Client** | Renders map, displays game info, captures human input. Zero game logic | WebSocket Server only |

### Data Flow

**Game Loop (per turn):**

```
1. Turn Engine determines current player and phase
2. Turn Engine asks Player Interface for a decision
   - If Bot: Bot analyzes GameState, returns action immediately
   - If Human: HumanPlayer adapter sends state to browser via WebSocket,
     waits for action response from browser via WebSocket
3. Action Validator checks the proposed action against rules
   - If invalid: reject, request again (step 2)
   - If valid: proceed
4. Turn Engine applies action to Game State
   - If attack: delegate to Combat Resolver, apply results
5. Turn Engine checks win/elimination conditions
6. Turn Engine serializes updated state, broadcasts to client via WebSocket
7. Turn Engine advances phase or player
8. Repeat from step 1
```

**State Update Flow (unidirectional):**

```
Player Decision --> Action Validator --> Game State Mutation --> State Broadcast --> Client Render
```

The client never mutates game state. It only sends action intents (e.g., `{"action": "attack", "from": "Brazil", "to": "North Africa", "armies": 3}`). The server validates and either applies or rejects.

**AI Decision Flow:**

```
Game State (read-only snapshot) --> Bot Strategy Layer
  --> Territory Analysis (border detection, continent progress)
  --> Threat Assessment (neighbor army counts, player strength)
  --> Goal Selection (which continent to pursue, who to attack)
  --> Action Generation (concrete moves)
--> Action returned to Turn Engine
```

## Patterns to Follow

### Pattern 1: Finite State Machine for Turn Phases

**What:** Model each turn as a state machine with explicit phase transitions: `REINFORCE -> ATTACK -> FORTIFY -> END_TURN`. The game itself is a higher-level FSM: `SETUP -> PLAYING -> GAME_OVER`.

**When:** Always. This is the backbone of the game loop.

**Why:** Turn-based games map perfectly to FSMs. Each phase has different valid actions, different UI states, and different exit conditions. The FSM prevents illegal state transitions (e.g., attacking during reinforcement phase).

**Example:**
```python
from enum import Enum, auto

class TurnPhase(Enum):
    REINFORCE = auto()
    ATTACK = auto()
    FORTIFY = auto()
    END_TURN = auto()

class GamePhase(Enum):
    SETUP = auto()       # Initial army placement
    PLAYING = auto()     # Main game loop
    GAME_OVER = auto()   # Winner determined

class TurnEngine:
    def __init__(self, game_state: GameState):
        self.game_phase = GamePhase.SETUP
        self.turn_phase = TurnPhase.REINFORCE
        self.game_state = game_state

    def advance_phase(self):
        if self.turn_phase == TurnPhase.REINFORCE:
            self.turn_phase = TurnPhase.ATTACK
        elif self.turn_phase == TurnPhase.ATTACK:
            self.turn_phase = TurnPhase.FORTIFY
        elif self.turn_phase == TurnPhase.FORTIFY:
            self.turn_phase = TurnPhase.END_TURN
            self._next_player()
            self.turn_phase = TurnPhase.REINFORCE
```

### Pattern 2: Player Interface Abstraction (Strategy Pattern)

**What:** Define an abstract `Player` interface that both human and bot players implement. The Turn Engine interacts only with this interface, never with concrete implementations.

**When:** Always. This is what makes bots and humans interchangeable.

**Why:** The Turn Engine should not care whether it's asking a human or a bot. The same `choose_attack()` call works for both. For humans, the implementation bridges to the WebSocket; for bots, it runs AI logic. This also makes adding new bot strategies trivial.

**Example:**
```python
from abc import ABC, abstractmethod

class Player(ABC):
    @abstractmethod
    async def choose_reinforcement(self, state: GameState, armies: int) -> dict[str, int]:
        """Return {territory_name: army_count} allocation."""
        ...

    @abstractmethod
    async def choose_attack(self, state: GameState) -> Attack | None:
        """Return an Attack action or None to end attack phase."""
        ...

    @abstractmethod
    async def choose_fortify(self, state: GameState) -> Fortify | None:
        """Return a Fortify action or None to skip."""
        ...

class HumanPlayer(Player):
    async def choose_attack(self, state: GameState) -> Attack | None:
        await self.websocket.send_json({"phase": "attack", "state": state.serialize()})
        response = await self.websocket.receive_json()
        return Attack.from_dict(response) if response.get("action") != "pass" else None

class EasyBot(Player):
    async def choose_attack(self, state: GameState) -> Attack | None:
        # Random valid attack or pass
        ...
```

### Pattern 3: Graph-Based Map Representation

**What:** Represent the world map as an adjacency graph where territories are nodes and borders are edges. Continents are node groups with metadata (bonus value).

**When:** Always. The map is fundamentally a graph problem.

**Why:** Graph representation enables efficient adjacency checks (can I attack from here?), connected-component analysis (can I fortify between these territories?), and continent control verification. It also supports the future requirement of custom maps -- any valid graph is a valid map.

**Example:**
```python
from dataclasses import dataclass

@dataclass
class Territory:
    name: str
    continent: str
    neighbors: list[str]  # adjacent territory names

@dataclass
class Continent:
    name: str
    territories: list[str]
    bonus_armies: int

class GameMap:
    def __init__(self):
        self.territories: dict[str, Territory] = {}
        self.continents: dict[str, Continent] = {}

    def are_adjacent(self, t1: str, t2: str) -> bool:
        return t2 in self.territories[t1].neighbors

    def are_connected(self, t1: str, t2: str, owner: str, state: GameState) -> bool:
        """BFS/DFS to check if t1 and t2 are connected through territories owned by owner."""
        ...

    def controls_continent(self, player: str, continent: str, state: GameState) -> bool:
        return all(
            state.owner(t) == player
            for t in self.continents[continent].territories
        )
```

### Pattern 4: Serializable Game State

**What:** The GameState object should be trivially serializable to JSON for WebSocket transmission and for potential save/load functionality.

**When:** Every state update that needs to reach the client.

**Why:** The client needs the full state to render. Bots may want state snapshots for simulation. Serialization also enables game replay and debugging.

**Example:**
```python
@dataclass
class GameState:
    territories: dict[str, TerritoryState]  # {name: {owner, armies}}
    players: list[PlayerState]               # [{name, cards, alive}]
    current_player: int
    turn_phase: TurnPhase
    turn_number: int
    card_trade_count: int                    # escalating card values

    def serialize(self) -> dict:
        """Convert to JSON-safe dict for WebSocket transmission."""
        ...

    def snapshot(self) -> "GameState":
        """Deep copy for AI simulation without affecting real state."""
        ...
```

### Pattern 5: Action Objects (Command-like)

**What:** Represent every player action as a typed data object that the validator can inspect and the engine can apply. Not full Command pattern (no undo needed), but structured actions rather than raw dicts.

**When:** All player interactions with the game.

**Why:** Typed action objects enable validation logic to be centralized and thorough. They also provide a clean audit trail of what happened during the game.

**Example:**
```python
@dataclass
class Attack:
    source: str       # attacking territory
    target: str       # defending territory
    num_dice: int     # 1-3

@dataclass
class Reinforce:
    placements: dict[str, int]  # {territory: armies_to_add}

@dataclass
class Fortify:
    source: str
    target: str
    armies: int
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Client-Side Game Logic

**What:** Putting rule validation or state mutation in the browser JavaScript.

**Why bad:** Even though this is single-player, splitting logic between Python and JS creates two sources of truth, doubles the bug surface, and makes the Python game engine untestable in isolation. The browser should be a dumb terminal.

**Instead:** All game logic lives in Python. The browser sends action intents, receives state updates. The only JS logic is rendering and UI interaction.

### Anti-Pattern 2: Monolithic Game Class

**What:** One giant `Game` class that handles map, state, rules, AI, combat, and communication.

**Why bad:** Becomes unmaintainable fast. Risk has enough complexity (42 territories, cards, continent bonuses, multi-phase turns, multiple bot strategies) that a single class will balloon to thousands of lines.

**Instead:** Separate concerns into distinct modules: `map.py`, `state.py`, `engine.py`, `combat.py`, `rules.py`, `bots/`. Each with clear interfaces.

### Anti-Pattern 3: Tight Coupling Between Bot Logic and Game Engine

**What:** Bot decision-making code directly calling game engine internals or mutating state.

**Why bad:** Makes it impossible to test bots independently, swap strategies, or add difficulty levels without touching engine code.

**Instead:** Bots receive a read-only state snapshot and return action objects. They never call engine methods or mutate state directly.

### Anti-Pattern 4: Synchronous Blocking for Human Input

**What:** Using blocking I/O to wait for human player actions in the game loop.

**Why bad:** Blocks the entire server, prevents sending state updates, and makes the architecture incompatible with async WebSocket communication.

**Instead:** Use async/await. The Turn Engine awaits the Player Interface, which for humans awaits a WebSocket message. For bots, the await resolves immediately with their computed action.

### Anti-Pattern 5: Storing Map Topology in Game State

**What:** Mixing the static map definition (which territories exist, their adjacencies) with dynamic game state (who owns what, army counts).

**Why bad:** The map never changes during a game. Mixing it with mutable state complicates serialization, makes state snapshots heavier than needed, and blocks the "future custom maps" requirement.

**Instead:** `GameMap` is a static, immutable configuration loaded once. `GameState` references territory names but doesn't store topology. The map is injected into the engine at startup.

## Scalability Considerations

| Concern | This Project (1 human, local) | Future: Multiple Maps | Future: Online Multiplayer |
|---------|-------------------------------|----------------------|---------------------------|
| State size | Trivial (42 territories) | Same per game | Same per game, many concurrent games |
| AI compute | Main bottleneck for Hard bot; keep under 2s per decision | Same | Move AI to background workers |
| WebSocket | Single connection, negligible | Same | Connection management, rooms |
| Map loading | Load once at startup from JSON/Python config | Load selected map config | Same, validated server-side |
| Concurrency | Single game loop, no contention | Same | Async game rooms, each with own state |

## Suggested Build Order (Dependencies)

The architecture has clear dependency layers. Build bottom-up:

```
Phase 1: Foundation (no dependencies)
  |- Map/Graph Module (territories, adjacency, continents)
  |- Game State Container (ownership, armies, cards, serialization)
  |- Action Types (dataclasses for Reinforce, Attack, Fortify)

Phase 2: Game Engine (depends on Phase 1)
  |- Combat Resolver (dice logic, loss calculation)
  |- Action Validator / Rule Engine (legal move checking)
  |- Turn Engine / FSM (phase management, turn flow)
  |- Player Interface ABC

Phase 3: Players (depends on Phase 2)
  |- Easy Bot (random valid moves)
  |- Medium Bot (heuristic-based)
  |- Hard Bot (strategic reasoning)

Phase 4: Communication (depends on Phase 2)
  |- WebSocket Server (FastAPI)
  |- HumanPlayer adapter (bridges WebSocket to Player Interface)
  |- State serialization for client

Phase 5: Client (depends on Phase 4)
  |- Map rendering (SVG or Canvas)
  |- Game info display
  |- Action input controls

Phase 6: Integration (depends on all above)
  |- Full game loop: human + bots playing together
  |- Game setup UI (player count, difficulty selection)
```

**Key dependency insight:** Phases 3 and 4 are independent of each other and can be built in parallel. The game engine (Phase 2) can be fully tested with mock players before any UI or real bots exist. This means the core game can be validated with automated tests before investing in frontend work.

**Critical path:** Map -> State -> Rules -> Engine -> Integration. The AI bots and the web UI are branches off the engine, not sequential.

## Technology Choices (Architecture-Relevant)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Server framework | **FastAPI** | Native async support, WebSocket built-in, lightweight for local use. No need for Django's overhead. |
| Client-server protocol | **WebSocket (JSON)** | Bidirectional, persistent connection. Server can push state updates without polling. JSON is human-readable for debugging. |
| Map data format | **Python module or JSON file** | Static data, loaded once. A Python dict/dataclass is simplest; JSON enables future map loading from files. |
| Client rendering | **SVG** | Territory shapes need to be clickable and individually styled (color by owner, army count labels). SVG handles this natively. Canvas requires manual hit detection. |
| Async framework | **asyncio** | Native Python. The game loop is inherently sequential (turn-based) with one async wait point (human input). No need for Celery or threading. |

## Sources

- [Turn-Based Game Architecture Guide](https://outscal.com/blog/turn-based-game-architecture) - FSM patterns for turn-based games
- [Game Programming Patterns: State](https://gameprogrammingpatterns.com/state.html) - State pattern in game development
- [Game Programming Patterns: Command](https://gameprogrammingpatterns.com/command.html) - Command pattern for game actions
- [FSM for Turn-Based Games](https://www.gamedev.net/blogs/entry/2274204-finite-state-machine-for-turn-based-games/) - Finite state machines in turn-based contexts
- [A Turn-Based Game Loop](https://journal.stuffwithstuff.com/2014/07/15/a-turn-based-game-loop/) - Turn-based loop architecture
- [Creating an AI for Risk](https://martinsonesson.wordpress.com/2018/01/07/creating-an-ai-for-risk-board-game/) - Risk-specific AI implementation
- [Risk Game Strategies](https://github.com/kengz/Risk-game/blob/master/strategies.md) - Strategic concepts for Risk bots
- [GNN for Risk-like Board Games](https://ieeexplore.ieee.org/document/10108022/) - Graph neural network approaches
- [Functional Immutable Game State](https://dev.to/binarykoan/functional-immutable-game-state-2fal) - Immutable state patterns
- [Command Pattern for Game Architecture](https://medium.com/gamedev-architecture/decoupling-game-code-via-command-pattern-debugging-it-with-time-machine-2b177e61556c) - Decoupling via commands
- [FastAPI WebSockets](https://fastapi.tiangolo.com/advanced/websockets/) - WebSocket implementation in FastAPI
- [PyRisk](https://github.com/chronitis/pyrisk) - Python Risk implementation reference
- [Networking Turn-Based Games](https://longwelwind.net/blog/networking-turn-based-game/) - Client-server patterns for turn-based games
