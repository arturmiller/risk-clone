# Architecture Patterns

**Domain:** Flutter mobile port of a turn-based Risk board game (no backend, on-device engine)
**Researched:** 2026-03-14
**Confidence:** HIGH

---

## Context: What Is Being Ported

The existing system is a Python/FastAPI backend + vanilla JS frontend communicating over WebSocket. The mobile version eliminates the client-server split entirely. Everything runs on-device in Dart. This is a structural transformation, not a line-for-line translation.

**What disappears:** FastAPI, WebSocket, JSON serialization layer, NetworkX
**What maps directly:** Game engine logic, bot strategy algorithms, FSM phases, map graph
**What is new:** Flutter widget tree, Riverpod state providers, CustomPainter map rendering, Dart isolates for bot AI

---

## Standard Architecture

### System Overview

```
+--------------------------------------------------------------------+
|                         Flutter App (on-device)                     |
+--------------------------------------------------------------------+
|                          Presentation Layer                         |
|                                                                     |
|  +------------------+  +-------------------+  +------------------+ |
|  |  MapWidget       |  |  SidebarWidget    |  |  ActionPanel     | |
|  |  (CustomPainter) |  |  (armies, cards)  |  |  (bottom sheet)  | |
|  +--------+---------+  +---------+---------+  +--------+---------+ |
|           |                      |                     |           |
+-----------|----------------------|---------------------|------------+
|                         State Layer (Riverpod)                      |
|                                                                     |
|  +------------------+  +-------------------+  +------------------+ |
|  |  GameNotifier    |  |  UIStateNotifier  |  |  SimModeNotifier | |
|  |  (game state,    |  |  (selection,      |  |  (auto-play,     | |
|  |   turn control)  |  |   phase prompts)  |  |   speed control) | |
|  +--------+---------+  +---------+---------+  +--------+---------+ |
|           |                      |                     |           |
+-----------|----------------------|---------------------|------------+
|                         Engine Layer (pure Dart)                    |
|                                                                     |
|  +------------------+  +-------------------+  +------------------+ |
|  |  TurnEngine      |  |  CombatResolver   |  |  MapGraph        | |
|  |  (FSM: reinforce |  |  (dice, losses,   |  |  (adjacency,     | |
|  |   attack fortify)|  |   conquest)       |  |   BFS, conts)    | |
|  +------------------+  +-------------------+  +------------------+ |
|                                                                     |
|  +------------------+  +-------------------+  +------------------+ |
|  |  Bot Agents      |  |  CardEngine       |  |  SetupEngine     | |
|  |  Easy/Med/Hard   |  |  (trade, deck,    |  |  (distribute     | |
|  |  (Dart isolates) |  |   wildcards)      |  |   territories)   | |
|  +------------------+  +-------------------+  +------------------+ |
|                                                                     |
+--------------------------------------------------------------------+
|                          Data Layer                                 |
|                                                                     |
|  +------------------+  +-------------------+                       |
|  |  GameState       |  |  MapData           |                      |
|  |  (freezed,       |  |  (static JSON,     |                      |
|  |   immutable)     |  |   loaded once)     |                      |
|  +------------------+  +-------------------+                       |
+--------------------------------------------------------------------+
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| **MapWidget** | Renders 42 territories with color-by-owner, army counts, selection highlight; handles tap-to-select | `CustomPainter` + `GestureDetector`, SVG paths parsed via `path_drawing` |
| **SidebarWidget** | Displays current player info, cards in hand, continent bonuses, phase indicator | Stateless widgets reading Riverpod providers |
| **ActionPanel** | Bottom sheet with context-sensitive controls (attack button, dice selector, end phase) | `DraggableScrollableSheet`, watches `UIStateNotifier` |
| **GameNotifier** | Owns the canonical `GameState`; orchestrates turn execution; exposes methods called by widgets | `AsyncNotifier<GameState>` in Riverpod |
| **UIStateNotifier** | Tracks ephemeral UI: selected source territory, selected target, valid targets list, phase prompt text | `Notifier<UIState>` in Riverpod |
| **SimModeNotifier** | Controls AI-vs-AI simulation: running/paused, speed, turn delay timer | `Notifier<SimState>` in Riverpod |
| **TurnEngine** | Pure functions: `executeReinforce`, `executeAttack`, `executeFortify`, `executeTurn`; no Flutter dependencies | Pure Dart library, zero imports from flutter |
| **CombatResolver** | `resolveCombat(attackerDice, defenderDice, rng)` → losses; `executeBlitz` loop | Pure Dart, injectable `Random` for tests |
| **MapGraph** | Adjacency check, `neighbors()`, `connectedTerritories()` via BFS, `continentBonus()` | Pure Dart, built from `MapData` at startup |
| **Bot Agents** | `EasyAgent`, `MediumAgent`, `HardAgent` implementing `PlayerAgent` interface; all methods synchronous and pure | Pure Dart classes, run in Isolate via `Isolate.run()` |
| **CardEngine** | `drawCard`, `executeTrade`, `isValidSet`, card bonus escalation table | Pure Dart |
| **SetupEngine** | `distributeTerritoriesRandomly`, `assignInitialArmies` | Pure Dart |
| **GameState** | Complete game snapshot: territories, players, turn phase, cards, deck, trade count | `@freezed` class with `copyWith`, deep equality |
| **MapData** | Static: territory names, adjacencies, continents, bonuses | Loaded once from bundled JSON asset |

---

## Recommended Project Structure

```
lib/
├── main.dart                    # App entry point, ProviderScope
├── app.dart                     # MaterialApp, routing
│
├── engine/                      # Pure Dart game logic (zero Flutter imports)
│   ├── models/
│   │   ├── game_state.dart      # @freezed GameState, TerritoryState, PlayerState
│   │   ├── actions.dart         # @freezed AttackAction, FortifyAction, etc.
│   │   ├── cards.dart           # @freezed Card, TurnPhase enum
│   │   └── map_schema.dart      # @freezed MapData, ContinentData
│   ├── map_graph.dart           # MapGraph: adjacency, BFS, continent queries
│   ├── combat.dart              # resolveCombat, executeAttack, executeBlitz
│   ├── reinforcements.dart      # calculateReinforcements
│   ├── cards.dart               # drawCard, executeTrade, isValidSet
│   ├── fortify.dart             # executeFortify, BFS path validation
│   ├── setup.dart               # distributeTerritoriesRandomly
│   └── turn.dart                # executeReinforcePhase, executeAttackPhase, etc.
│
├── bots/                        # AI agents (pure Dart, no Flutter)
│   ├── player_agent.dart        # abstract class PlayerAgent (interface)
│   ├── easy_agent.dart          # random valid moves
│   ├── medium_agent.dart        # heuristic scoring
│   └── hard_agent.dart          # HardAgent: BSR, continent progress, probability
│
├── providers/                   # Riverpod state providers
│   ├── game_provider.dart       # GameNotifier: AsyncNotifier<GameState>
│   ├── ui_provider.dart         # UIStateNotifier: selection, valid targets
│   ├── sim_provider.dart        # SimModeNotifier: simulation speed/state
│   └── map_provider.dart        # mapGraphProvider: loaded once, cached
│
├── screens/
│   ├── home_screen.dart         # Game setup: player count, difficulty
│   └── game_screen.dart         # Main game UI: map + sidebar + action panel
│
├── widgets/
│   ├── map/
│   │   ├── map_widget.dart      # CustomPaint host + GestureDetector
│   │   ├── map_painter.dart     # CustomPainter implementation
│   │   └── territory_paths.dart # Parsed SVG path data for 42 territories
│   ├── sidebar/
│   │   ├── player_info.dart     # Current player name, armies to place
│   │   ├── cards_hand.dart      # Card display + trade button
│   │   └── continent_panel.dart # Continent control bonuses
│   └── action_panel/
│       ├── action_panel.dart    # DraggableScrollableSheet container
│       ├── reinforce_controls.dart
│       ├── attack_controls.dart  # Dice selector, blitz toggle
│       └── fortify_controls.dart
│
└── assets/
    └── map.json                 # Territory definitions, adjacencies, continents
```

### Structure Rationale

- **engine/:** Zero Flutter imports enforced. This enables testing every game rule, bot decision, and combat outcome with plain `dart test`, no widget testing overhead. Direct Dart port of the Python engine with immutable `copyWith` replacing `model_copy`.
- **bots/:** Separate from engine because they depend on the engine (read-only state analysis) but are not part of the turn execution mechanism. Mirrors the Python `bots/` package.
- **providers/:** Thin coordination layer. Providers call engine functions, store results, notify widgets. No game logic lives here.
- **widgets/map/:** Isolated because the map painter is the most complex widget; isolating it makes it independently testable via golden tests.

---

## Architectural Patterns

### Pattern 1: Riverpod AsyncNotifier for Game Orchestration

**What:** A single `GameNotifier extends AsyncNotifier<GameState>` owns turn execution. Human player actions call public methods (`attack(source, target, dice)`). Bot turns run asynchronously via Dart isolates and resolve to state updates. The UI always rebuilds from the new state.

**When to use:** Always. Riverpod's `AsyncNotifier` handles loading states during bot AI computation, error states for rule violations, and provides a single place to reason about game progression.

**Trade-offs:** Slightly more ceremony than direct state mutation, but gives you `ref.watch` granularity, loading spinners during bot turns, and easy testing via `ProviderContainer`.

**Example:**
```dart
@riverpod
class GameNotifier extends _$GameNotifier {
  @override
  Future<GameState> build() async {
    // Initial state is empty; game starts via setupGame()
    return GameState.initial();
  }

  Future<void> setupGame(GameConfig config) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final mapGraph = ref.read(mapGraphProvider);
      return SetupEngine.distributeTerritoriesRandomly(config, mapGraph);
    });
  }

  Future<void> submitHumanAttack(AttackAction action) async {
    final current = state.requireValue;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final rng = Random();
      final mapGraph = ref.read(mapGraphProvider);
      final (newState, _, conquered) = CombatEngine.executeAttack(
        current, mapGraph, action, current.currentPlayerIndex, rng);
      return newState;
    });
  }

  Future<void> runBotTurn() async {
    final current = state.requireValue;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Run bot in isolate to avoid UI jank
      return await Isolate.run(() {
        final mapGraph = ref.read(mapGraphProvider);
        final bot = _agentFor(current.currentPlayerIndex);
        return TurnEngine.executeTurn(current, mapGraph, bot, Random());
      });
    });
  }
}
```

### Pattern 2: Immutable State with Freezed (Mirrors Python model_copy)

**What:** All game state objects are `@freezed` classes. Every engine function takes a `GameState` and returns a new `GameState`. No mutation. Mirrors Python's `state.model_copy(update={...})` exactly.

**When to use:** Always. The entire engine layer is pure functions on immutable data. This is the direct translation of the Pydantic immutable state pattern.

**Trade-offs:** Code generation step required (`dart run build_runner build`). Adds a `build_runner` dev dependency. Worth it: deep equality, `copyWith`, pattern matching, and JSON serialization are generated for free.

**Example:**
```dart
@freezed
class GameState with _$GameState {
  const factory GameState({
    required Map<String, TerritoryState> territories,
    required List<PlayerState> players,
    @Default(0) int currentPlayerIndex,
    @Default(0) int turnNumber,
    @Default(TurnPhase.reinforce) TurnPhase turnPhase,
    @Default(0) int tradeCount,
    @Default({}) Map<int, List<Card>> cards,
    @Default([]) List<Card> deck,
    @Default(false) bool conqueredThisTurn,
  }) = _GameState;
}

// Engine function: same shape as Python execute_attack
(GameState, CombatResult, bool) executeAttack(
  GameState state,
  MapGraph mapGraph,
  AttackAction action,
  int playerIndex,
  Random rng,
) {
  // ... resolve combat
  return (state.copyWith(territories: newTerritories), result, conquered);
}
```

### Pattern 3: CustomPainter Map with Hit Detection

**What:** The 42 territories are rendered as `Path` objects in a `CustomPainter`. Tap detection uses `path.contains(localPosition)` for each territory. This avoids the weight of Flame or a game loop for a static board game map.

**When to use:** For this project. A full game engine (Flame) adds 5MB+ and a component/game-loop abstraction that is unnecessary for a board game where the "animation" is just color changes and number updates.

**Trade-offs:** CustomPainter requires manual SVG path parsing upfront. The `path_drawing` package converts SVG path strings to Flutter `Path` objects. Hit detection is O(n) over 42 territories per tap — completely negligible.

**Example:**
```dart
class MapPainter extends CustomPainter {
  final GameState gameState;
  final String? selectedTerritory;
  final Set<String> validTargets;
  final Map<String, Path> territoryPaths; // pre-parsed from SVG

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in territoryPaths.entries) {
      final name = entry.key;
      final path = entry.value;
      final ts = gameState.territories[name]!;

      final paint = Paint()
        ..color = _ownerColor(ts.owner)
        ..style = PaintingStyle.fill;

      if (name == selectedTerritory) {
        paint.color = paint.color.withOpacity(0.5);
      }
      canvas.drawPath(path, paint);
    }
  }

  String? hitTest(Offset localPosition) {
    for (final entry in territoryPaths.entries) {
      if (entry.value.contains(localPosition)) return entry.key;
    }
    return null;
  }
}

// In MapWidget:
GestureDetector(
  onTapDown: (details) {
    final hit = painter.hitTest(details.localPosition);
    if (hit != null) ref.read(uiStateProvider.notifier).selectTerritory(hit);
  },
  child: CustomPaint(painter: painter),
)
```

### Pattern 4: PlayerAgent Interface (Mirrors Python Protocol)

**What:** An abstract `PlayerAgent` class defines the contract: `chooseReinforcement`, `chooseAttack`, `chooseFortify`, `chooseCardTrade`, `chooseAdvanceArmies`. Human turns fulfill this contract through UI interaction captured by the `GameNotifier`. Bot turns fulfill it inline.

**When to use:** Always. This is the direct Dart translation of the Python duck-typed agent protocol.

**Trade-offs:** The human player's "agent" is implicit in the UI flow — the user taps, `GameNotifier` receives the action, and the phase advances. Bots are explicit `PlayerAgent` implementations that can be unit tested in isolation.

**Example:**
```dart
abstract class PlayerAgent {
  ReinforcePlacementAction chooseReinforcement(GameState state, int armies);
  AttackAction? chooseAttack(GameState state);
  FortifyAction? chooseFortify(GameState state);
  TradeCardsAction? chooseCardTrade(GameState state, List<Card> cards, {required bool forced});
  int chooseAdvanceArmies(GameState state, String source, String target, int min, int max);
}

class HardAgent implements PlayerAgent {
  final MapGraph _mapGraph;
  final Random _rng;
  // ... direct port of Python HardAgent
}
```

### Pattern 5: Dart Isolates for Bot AI (No UI Jank)

**What:** Bot turn execution runs in a separate Dart isolate via `Isolate.run()`. The UI shows a loading/thinking indicator while the bot computes. When the isolate returns the new `GameState`, the `GameNotifier` updates and the UI rebuilds.

**When to use:** For bot turns in non-simulation mode. In simulation mode (all bots), consider a ticker-based loop with configurable delay for visual feedback.

**Trade-offs:** `Isolate.run()` spawns a new isolate per call and passes data by copy. For Risk's game state (~42 territories, ≤6 players), serialization overhead is negligible. The HardAgent's `O(n^2)` territory analysis runs in under 10ms in practice; isolates are used defensively to keep the UI frame rate clean.

**Caveats:** Objects passed to/from isolates must be primitives, typed lists, or implement `Isolatable`. Since `GameState` is a plain Dart object (no Flutter state), it passes across the isolate boundary cleanly. The `MapGraph` must be reconstructed in the isolate (it's inexpensive — just adjacency maps).

---

## Data Flow

### Human Turn Flow

```
User taps territory
    |
    v
MapWidget.onTapDown → UIStateNotifier.selectTerritory(name)
    |
    v (user taps second territory for attack target)
ActionPanel shows AttackControls (source, target, dice count)
    |
    v (user confirms attack)
GameNotifier.submitHumanAttack(action)
    |
    v
CombatEngine.executeAttack(state, mapGraph, action, rng)
    |
    v (returns new GameState)
GameNotifier emits AsyncData(newState)
    |
    v
MapWidget, SidebarWidget, ActionPanel all rebuild via ref.watch
```

### Bot Turn Flow

```
GameNotifier.runBotTurn()
    |
    v (AsyncLoading emitted, UI shows spinner)
Isolate.run(() {
    bot = HardAgent(mapGraph, rng)
    return TurnEngine.executeTurn(state, mapGraph, bot, rng)
})
    |
    v (Isolate returns new GameState)
GameNotifier emits AsyncData(newState)
    |
    v
UI rebuilds with updated state
    |
    v (if not game over, schedule next bot turn with Timer delay in sim mode)
```

### Simulation Mode Flow

```
SimModeNotifier.startSimulation()
    |
    v
Timer.periodic(speed) → GameNotifier.runBotTurn()
    |
    v (each timer tick advances one full turn)
GameNotifier emits updated state after each turn
    |
    v
SimModeNotifier.pauseSimulation() → Timer.cancel()
```

### State Management (Riverpod)

```
GameState (in GameNotifier)
    |
    +--[ref.watch]--> MapWidget (repaints on territory/player changes)
    +--[ref.watch]--> SidebarWidget (shows current player info)
    +--[ref.watch]--> ActionPanel (shows phase-relevant controls)
    +--[ref.select]--> specific territory (minimal rebuilds)

UIState (in UIStateNotifier)
    |
    +--[ref.watch]--> MapWidget (selection highlight, valid targets overlay)
    +--[ref.watch]--> ActionPanel (enables/disables confirm button)

SimState (in SimModeNotifier)
    |
    +--[ref.watch]--> SimControls (play/pause button, speed slider)
```

---

## Integration Points

### New Components (Does Not Exist in Python Version)

| Component | What It Is | Notes |
|-----------|------------|-------|
| `MapPainter` | Flutter CustomPainter for the world map | Needs SVG territory paths converted to Flutter `Path` objects |
| `territory_paths.dart` | Static map of territory name → Flutter Path | Generated once by parsing the SVG; stored as Dart code |
| `GameNotifier` | Riverpod orchestrator replacing FastAPI + WebSocket | All turn control flows through here |
| `UIStateNotifier` | Selection state for map interaction | No equivalent in Python (browser handled this in JS) |
| `SimModeNotifier` | Simulation mode timer control | Previously in JS `simulation.js` |
| `HomeScreen` | Game setup UI | Previously a JS form |

### Modified Components (Port from Python)

| Python Module | Dart Equivalent | Changes |
|---------------|-----------------|---------|
| `risk/engine/turn.py` | `engine/turn.dart` | Pure functions; `async/isolate` wrapping in `GameNotifier`, not in engine |
| `risk/engine/combat.py` | `engine/combat.dart` | Direct port; `Random` injected instead of `random.Random` |
| `risk/engine/map_graph.py` | `engine/map_graph.dart` | BFS implemented manually (no NetworkX); `Map<String, Set<String>>` adjacency |
| `risk/engine/cards.py` | `engine/cards.dart` | Direct port |
| `risk/engine/fortify.py` | `engine/fortify.dart` | BFS path validation rewritten without NetworkX |
| `risk/models/game_state.py` | `engine/models/game_state.dart` | Pydantic → `@freezed`; `model_copy` → `copyWith` |
| `risk/models/actions.py` | `engine/models/actions.dart` | Pydantic → `@freezed` |
| `risk/bots/hard.py` | `bots/hard_agent.dart` | Direct algorithmic port; `_rng` → injected `Random` |
| `risk/bots/medium.py` | `bots/medium_agent.dart` | Direct port |

### Components That Disappear

| Python Component | Reason |
|-----------------|--------|
| `risk/server/app.py` (FastAPI) | No network layer needed; game runs on-device |
| `risk/server/game_manager.py` | `GameNotifier` replaces this |
| `risk/server/human_agent.py` | Human input is captured by UI widgets, not an agent class |
| `risk/server/messages.py` | No WebSocket messages needed |
| Static JS files | Replaced by Flutter widgets |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `GameNotifier` ↔ Engine functions | Direct function calls; engine returns new `GameState` | Engine has no knowledge of Riverpod |
| `GameNotifier` ↔ Bot agents | `Isolate.run()` with state passed by copy | Isolate boundary enforces no shared mutable state |
| Widgets ↔ `GameNotifier` | `ref.watch(gameProvider)` and `ref.read(gameProvider.notifier).method()` | Widgets never call engine functions directly |
| `MapWidget` ↔ `UIStateNotifier` | `ref.watch(uiStateProvider)` for display; `ref.read(uiStateProvider.notifier).selectTerritory()` for input | Selection state is UI-only, not in GameState |
| Engine ↔ `MapGraph` | Injected at `GameNotifier` construction, passed to engine functions | Map is immutable; loaded once from bundled JSON |

---

## Suggested Build Order

The architecture has clear dependency layers. Build bottom-up, engine first:

```
Phase 1: Data Models + Map Graph (no dependencies)
  |- @freezed GameState, TerritoryState, PlayerState
  |- @freezed AttackAction, FortifyAction, etc.
  |- @freezed Card, TurnPhase, MapData
  |- MapGraph: adjacency Map, neighbors(), connectedTerritories() BFS
  |- map.json asset (territory definitions)
  Unit tests: all MapGraph queries, BFS path finding

Phase 2: Combat + Engine (depends on Phase 1)
  |- CombatResolver: resolveCombat, executeAttack, executeBlitz
  |- CardEngine: drawCard, executeTrade, isValidSet
  |- ReinforcementEngine: calculateReinforcements
  |- FortifyEngine: executeFortify
  |- SetupEngine: distributeTerritoriesRandomly
  |- TurnEngine: executeReinforcePhase, executeAttackPhase, executeFortifyPhase
  Unit tests: all combat outcomes, card trading rules, fortify validation

Phase 3: Bot Agents (depends on Phase 1 + 2)
  |- PlayerAgent abstract interface
  |- EasyAgent (random valid moves)
  |- MediumAgent (heuristic scoring, direct Python port)
  |- HardAgent (BSR, continent progress, probability — direct Python port)
  Unit tests: all agent methods with fixed-seed Random; property tests for valid actions

Phase 4: Riverpod Providers (depends on Phase 1-3)
  |- mapGraphProvider (loaded once from assets)
  |- GameNotifier: setupGame, submitHumanAction, runBotTurn
  |- UIStateNotifier: selection logic, valid target computation
  |- SimModeNotifier: timer, speed control
  Tests: ProviderContainer tests with fake GameState

Phase 5: Map Widget (depends on Phase 1 + 4)
  |- Parse SVG territory paths into Flutter Path objects
  |- MapPainter: color-by-owner, army count labels, selection highlight
  |- MapWidget: CustomPaint + GestureDetector + hit detection
  Tests: golden tests for map rendering; hit detection unit tests

Phase 6: Screens + Other Widgets (depends on Phase 4 + 5)
  |- HomeScreen: player count, difficulty selector, start button
  |- SidebarWidget: player info, cards, continents
  |- ActionPanel: phase-sensitive controls, bottom sheet
  |- GameScreen: compose map + sidebar + action panel
  Tests: widget tests for each control

Phase 7: Integration + Simulation Mode (depends on all)
  |- Full game loop: human + bots
  |- Simulation mode: all-bot timer loop
  |- Win/elimination/game-over screens
  Tests: integration test running a full simulated game
```

**Key dependency insight:** Phases 1-3 are pure Dart with zero Flutter imports. They can be developed and tested in a standalone Dart package before the Flutter shell exists. This mirrors how the Python engine was developed and tested independently of FastAPI.

**Critical path for playability:** Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5. The map widget blocks playability because without it there is no way to select territories.

---

## Anti-Patterns

### Anti-Pattern 1: Game Logic in Providers or Widgets

**What people do:** Put combat resolution or bot decision-making inside `GameNotifier` or directly in widget `onTap` callbacks.

**Why it's wrong:** Impossible to unit test. Game rules become entangled with Flutter's widget lifecycle. Breaks the separation that made the Python engine so testable.

**Do this instead:** All game logic lives in `engine/` as pure Dart functions. `GameNotifier` is a thin orchestrator that calls engine functions and stores results.

### Anti-Pattern 2: Sharing MapGraph via Mutable State

**What people do:** Put `MapGraph` inside `GameState` or recreate it each turn.

**Why it's wrong:** The map is static (never changes during a game). Including it in `GameState` bloats state copies on every `copyWith`, inflates memory, and complicates isolate data passing.

**Do this instead:** `mapGraphProvider` holds a single `MapGraph` instance loaded at startup. Engine functions receive it as a parameter. Isolates reconstruct it from raw `MapData` (which is small and serializable).

### Anti-Pattern 3: Using Flame for a Board Game

**What people do:** Add Flame because "it's a game."

**Why it's wrong:** Flame is designed for continuous game loops (physics, sprites, animation). Risk is event-driven: state only changes on player actions. Flame adds a mandatory game loop, `Component` hierarchy, and camera system that are all overhead for a board game. It also makes standard Flutter widgets (Material bottom sheets, etc.) more awkward to integrate.

**Do this instead:** Use `CustomPainter` for the map canvas and standard Flutter widgets for all UI. The map needs to repaint on state change, not every 16ms.

### Anti-Pattern 4: Blocking the UI Thread with Bot AI

**What people do:** Run bot turn computation synchronously in `setState` or directly in a provider update.

**Why it's wrong:** HardAgent's territory scoring loops over all territories and all candidates. On a large game state, this causes frame drops. Even if it's currently fast enough, it will jank on low-end Android devices.

**Do this instead:** Always run bot turns via `Isolate.run()`. The overhead of spawning an isolate is ~1ms; the safety guarantee is permanent.

### Anti-Pattern 5: Putting UIState Inside GameState

**What people do:** Add `selectedTerritory` or `validAttackTargets` to `GameState`.

**Why it's wrong:** UI ephemera pollutes game logic. It means every bot turn carries selection state through the engine. It makes state equality unreliable (two equal game positions with different UI selections compare as not-equal). It complicates snapshot testing.

**Do this instead:** `UIStateNotifier` owns selection state separately. `GameState` is pure game logic. The two are composed in the UI layer only.

### Anti-Pattern 6: Re-parsing SVG Territory Paths on Every Repaint

**What people do:** Parse SVG path strings inside `MapPainter.paint()`.

**Why it's wrong:** `paint()` is called every frame when the widget is dirty. Parsing 42 SVG paths on every repaint causes severe jank.

**Do this instead:** Parse all SVG territory paths once at app startup (or in a `FutureProvider`) and store the resulting `Map<String, Path>` in a provider. Pass the pre-parsed paths to `MapPainter` as a constructor parameter.

---

## Scaling Considerations

This is a single-player local game, so "scaling" means adding features, not users:

| Concern | Current Scope | If Multi-Map Support Added | If Save/Load Added |
|---------|--------------|---------------------------|-------------------|
| MapGraph | Hardcoded classic map | `mapGraphProvider` is already parameterized by `MapData`; swap JSON asset | No change |
| GameState | In-memory only | No change | Add JSON serialization (freezed provides `fromJson`/`toJson` for free) |
| Bot performance | HardAgent: ~5ms/turn | Same per map | Same |
| Map rendering | 42 SVG paths | Scale with territory count; hit detection stays O(n) | No change |
| Isolate spawning | One per bot turn | Same | Same |

---

## Sources

- [Flutter Riverpod — official documentation](https://riverpod.dev/docs/introduction/why_riverpod) — HIGH confidence
- [Riverpod AsyncNotifier guide](https://riverpod.dev/docs/essentials/side_effects) — HIGH confidence
- [freezed package](https://pub.dev/packages/freezed) — HIGH confidence
- [Flutter CustomPainter documentation](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html) — HIGH confidence
- [Dart Isolates — official docs](https://dart.dev/language/isolates) — HIGH confidence
- [Flutter concurrency and isolates](https://docs.flutter.dev/perf/isolates) — HIGH confidence
- [Build interactive maps in Flutter with SVG — Appwriters](https://www.appwriters.dev/blog/flutter-interactive-svg-maps) — MEDIUM confidence
- [Flutter State Management 2025: Riverpod vs BLoC — Foresight Mobile](https://foresightmobile.com/blog/best-flutter-state-management) — MEDIUM confidence
- [Flutter Flame for board games — DEV Community](https://dev.to/krlz/make-games-with-flutter-in-2025-flame-engine-tools-and-free-assets-1n6) — MEDIUM confidence (used to confirm Flame is NOT the right choice here)
- [Flutter project structure: feature-first — codewithandrea.com](https://codewithandrea.com/articles/flutter-project-structure/) — MEDIUM confidence

---
*Architecture research for: Flutter mobile Risk game (on-device Dart engine)*
*Researched: 2026-03-14*
