# Phase 11: Screens, Widgets, and Mobile UX — Research

**Researched:** 2026-03-15
**Domain:** Flutter screen composition, responsive layout, bottom sheets, Material widgets, HumanAgent wiring, game log, continent panel
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MOBX-01 | Game setup screen — player count, difficulty, game mode | HomeScreen already exists as stub; needs full setup form with dropdowns/sliders, NavigationPush to GameScreen |
| MOBX-02 | Responsive layout for phone and tablet | LayoutBuilder breakpoint: portrait (bottom sheet controls) vs landscape (side panel); OrientationBuilder for map aspect ratio |
| MOBX-03 | Game action controls (dice selection, blitz, end attack, skip fortify, card trade) | Phase-aware ActionPanel widget reading TurnPhase from gameProvider; human move dispatching through HumanAgent via Completer; bottom sheet isDismissible: false |
| MOBX-04 | Game log showing events (attacks, conquests, eliminations, card trades) | LogEntry model added to GameState; GameNotifier appends entries; ListView.builder with auto-scroll |
| MOBX-05 | Continent info with bonus display | ContinentPanel reads MapGraph.continentNames + continentBonus + controlsContinent; no new data needed |
| MOBX-06 | Game over screen with new game option | WinnerDialog / game-over modal shown when checkVictory != null; PopScope for abandon confirmation |
</phase_requirements>

---

## Summary

Phase 11 assembles all previously-built components — MapWidget (Phase 10), GameNotifier + UIStateNotifier (Phase 9), engine + bots (Phases 7–8) — into a playable game UI. The engine and state layer are already fully correct and tested; this phase is pure UI composition. There are no new algorithms to port.

The most important architectural decision in this phase is the **HumanAgent pattern**: the turn engine calls `agent.chooseAttack()`, `agent.chooseReinforcementPlacement()`, etc. synchronously inside `Isolate.run()` from `GameNotifier.runBotTurn()`. For human turns, the engine must block until the UI delivers a decision. The correct Dart pattern for this is a `Completer<T>` — the HumanAgent holds a completer, the engine awaits the future, and the UI resolves it when the player acts. However, `Isolate.run()` cannot pass `Completer` or `SendPort` across isolate boundaries. **Human turns must NOT use Isolate.run()** — they must execute synchronously on the main isolate and resolve through Riverpod state, not through a blocking call.

The recommended design is: `GameNotifier` checks whether the current player is human. If bot, use the existing `Isolate.run()` path. If human, the notifier exposes a `humanMove(action)` method. UIStateNotifier already handles selection — the ActionPanel reads UIState and dispatches the chosen action. This means adding a `humanMove()` method to GameNotifier and a HumanAgent stub that simply validates and applies the move.

The second key decision is **game log design**. The `GameState` is a freezed value type used as truth in Riverpod — it cannot hold mutable log history by itself without unbounded growth. The right pattern is to store `List<LogEntry>` inside `GameState` (appended per-turn) or in a separate `gameLogProvider`. Using a separate notifier (a `List<LogEntry>` held by a `StateNotifier` updated by the game loop) is cleaner and avoids inflating the serialized save-game JSON with the full event history.

Responsive layout uses `LayoutBuilder` with a breakpoint at 600dp width: below is portrait mode (MapWidget fills the top portion, ActionPanel in a persistent bottom sheet), above is landscape/tablet mode (Row with MapWidget + sidebar panel). The `MediaQuery.of(context).orientation` approach is less reliable than a width breakpoint.

**Primary recommendation:** One GameScreen Scaffold with LayoutBuilder-driven portrait/landscape layout; HumanAgent wiring via `GameNotifier.humanMove()` on the main isolate (never in `Isolate.run()`); game log as a separate `gameLogProvider` StateNotifier; `isDismissible: false` on all bottom sheets; `PopScope` on HomeScreen for game-in-progress abandon confirmation.

---

## Architecture Patterns

### HumanAgent Wiring — The Central Design Problem

The turn engine in `turn.dart` calls `PlayerAgent` methods synchronously. Bots implement these as pure computations. For a human player, the game must pause after each prompt and wait for UI input.

**The wrong approach:** Trying to use `Completer` across `Isolate.run()`. Dart `Completer` and `SendPort` objects cannot cross isolate boundaries. Any attempt to pass a `Completer` into `Isolate.run()` will throw at runtime.

**The correct approach:** Human turns never enter `Isolate.run()`. `GameNotifier` distinguishes between bot turns and human turns:

```dart
// In GameNotifier
bool _isHumanTurn(GameState state) {
  return state.currentPlayerIndex == 0; // player 0 is always human
}

Future<void> advanceTurn() async {
  final current = state.value;
  if (current == null) return;
  if (_isHumanTurn(current)) {
    // Do nothing — wait for humanMove() to be called by ActionPanel
    return;
  }
  await runBotTurn(); // existing Isolate.run() path
}
```

The human's `PlayerAgent` implementation (`HumanAgent`) is never called through the bot turn path. Instead, `GameNotifier.humanMove()` takes an action object, validates it, applies it to `GameState` directly, and calls `advanceTurn()` when the human's phase is complete.

This means the `executeTurn()` engine function is called only for bot turns. Human turns are handled phase-by-phase through direct `GameState` mutations in `GameNotifier`. The engine functions (`executeReinforcePhase`, `executeAttackPhase`, `executeFortifyPhase`) still own the logic — `humanMove()` delegates to these same functions with a minimal HumanAgent that holds the chosen action.

**HumanAgent as a one-shot stub:**

```dart
// Source: pattern from player_agent.dart interface + Dart Completer docs
class HumanAgent implements PlayerAgent {
  final ReinforcePlacementAction? _placement;
  final AttackChoice? _attack;
  final FortifyAction? _fortify;
  final TradeCardsAction? _trade;
  final int _advance;

  // One-shot: each HumanAgent instance holds a single decision
  const HumanAgent({
    ReinforcePlacementAction? placement,
    AttackChoice? attack,
    FortifyAction? fortify,
    TradeCardsAction? trade,
    int advance = 0,
  }) : _placement = placement, _attack = attack,
       _fortify = fortify, _trade = trade, _advance = advance;

  @override
  ReinforcePlacementAction chooseReinforcementPlacement(GameState s, int armies) =>
      _placement!;

  @override
  AttackChoice? chooseAttack(GameState s) => _attack;

  @override
  FortifyAction? chooseFortify(GameState s) => _fortify;

  @override
  TradeCardsAction? chooseCardTrade(GameState s, List<Card> hand, {required bool forced}) =>
      _trade;

  @override
  int chooseAdvanceArmies(GameState s, String src, String tgt, int min, int max) =>
      _advance.clamp(min, max);
}
```

`GameNotifier.humanMove(action)` constructs a `HumanAgent` with the action, calls the relevant engine phase function, then saves the new state and calls `advanceTurn()`.

### Responsive Layout with LayoutBuilder

```dart
// Source: Flutter docs — flutter.dev/docs/development/ui/layout/adaptive-responsive
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return _LandscapeLayout(); // Row: map + sidebar
      } else {
        return _PortraitLayout(); // Column: map + bottom panel
      }
    },
  );
}
```

**Portrait layout:** MapWidget fills the top ~60% of the screen. A persistent `BottomSheet` (not `showModalBottomSheet`) or a fixed-height `Column` bottom region holds the ActionPanel. Use `SafeArea` with `bottom: true` to respect iOS home indicator and Android navigation bar.

**Landscape layout:** `Row` with the MapWidget taking flex: 3 and a side panel taking flex: 2. The side panel contains ActionPanel + GameLog + ContinentPanel in a `SingleChildScrollView`.

### Screen Navigation

```
main.dart → ProviderScope → RiskApp → MaterialApp
  - home: HomeScreen (existing, needs upgrade)
  - /game → GameScreen (new)
```

Navigation uses `Navigator.push` / `Navigator.pop`. No named routes needed. `PopScope` on `GameScreen` shows an abandon-confirmation dialog before pop.

```dart
// Source: Flutter docs — PopScope replaces deprecated WillPopScope in Flutter 3.x
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Abandon game?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Abandon')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
    }
  },
  child: GameScreen(),
)
```

**CRITICAL:** `WillPopScope` is removed in Flutter 3.x. Use `PopScope` with `onPopInvokedWithResult` (the `result` parameter replaces the removed `onPopInvoked` in Flutter 3.22+).

### Bottom Sheet Pattern for ActionPanel

The ActionPanel is always visible during gameplay — it is NOT a modal bottom sheet. Use a `DraggableScrollableSheet` anchored at a minimum height or a fixed-height `Container` in the scaffold body.

For any action that requires a sub-choice (card trade picker, advance armies slider), use `showModalBottomSheet` with `isDismissible: false` and `enableDrag: false`:

```dart
// Source: Flutter docs — showModalBottomSheet
showModalBottomSheet(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  builder: (ctx) => CardTradeSheet(cards: hand),
);
```

`isDismissible: false` prevents the player from accidentally dismissing a required decision.

### GameScreen Structure

```dart
// Scaffold with LayoutBuilder for portrait/landscape
Scaffold(
  body: SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // Landscape: side-by-side
          return Row(children: [
            Expanded(flex: 3, child: MapWidget()),
            SizedBox(width: 280, child: GameSidebar()),
          ]);
        }
        // Portrait: map + bottom panel
        return Column(children: [
          Expanded(child: MapWidget()),
          GameBottomPanel(), // fixed height ~200dp
        ]);
      },
    ),
  ),
)
```

### ActionPanel — Phase-Aware Controls

The `ActionPanel` reads `gameAsync.value?.turnPhase` and renders the correct controls:

| TurnPhase | Controls |
|-----------|----------|
| `reinforce` | Army count remaining display, "Place armies" button (via territory tap on map), "Done Reinforcing" when all placed |
| `attack` | Dice count selector (1/2/3 + Blitz toggle), "End Attack" button; map tap selects source then target |
| `fortify` | Army count slider, "Skip Fortify" button; map tap selects source then target |

**Dice selector as SegmentedButton (Flutter 3.x Material 3):**

```dart
// Source: Flutter Material 3 docs — SegmentedButton
SegmentedButton<int>(
  segments: const [
    ButtonSegment(value: 1, label: Text('1')),
    ButtonSegment(value: 2, label: Text('2')),
    ButtonSegment(value: 3, label: Text('3')),
  ],
  selected: {selectedDice},
  onSelectionChanged: (s) => setState(() => selectedDice = s.first),
)
```

The Blitz option is a separate `FilterChip` or `ElevatedButton` that bypasses the dice selector.

### Game Log Design

A `gameLogProvider` (separate from `gameProvider`) holds `List<LogEntry>`. `GameNotifier` calls a method on the log provider after each significant event. The log is NOT serialized to ObjectBox — it resets on each game load.

```dart
// LogEntry model — plain Dart, no freezed needed (not persisted)
class LogEntry {
  final String message;
  final DateTime timestamp;
  const LogEntry({required this.message, required this.timestamp});
}

// gameLogProvider
@riverpod
class GameLog extends _$GameLog {
  @override
  List<LogEntry> build() => [];

  void add(String message) {
    state = [...state, LogEntry(message: message, timestamp: DateTime.now())];
  }

  void clear() => state = [];
}
```

**Auto-scroll to latest entry:**

```dart
// Source: Flutter docs — ListView with ScrollController
final _scrollController = ScrollController();

// After new entry:
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
});
```

### ContinentPanel — Continent Bonus Display

Reads from `mapGraphProvider` (already available). For each continent, shows: continent name, bonus armies, whether current player controls it (color-coded).

```dart
// Source: MapGraph API already in mobile/lib/engine/map_graph.dart
final mapGraph = ref.watch(mapGraphProvider).value;
final gameState = ref.watch(gameProvider).value;
if (mapGraph == null || gameState == null) return const SizedBox.shrink();

final playerIdx = gameState.currentPlayerIndex;
final playerTerritories = gameState.territories.entries
    .where((e) => e.value.owner == playerIdx)
    .map((e) => e.key).toSet();

for (final continent in mapGraph.continentNames) {
  final bonus = mapGraph.continentBonus(continent);
  final controls = mapGraph.controlsContinent(continent, playerTerritories);
  // render chip or row with continent, bonus, controls indicator
}
```

### Game Over Detection

`GameNotifier` already calls `checkVictory()` in `turn.dart`. The game over state is surfaced via `GameState.players` — if only one player has `isAlive: true`, the game is won. The UI watches for this condition:

```dart
// In GameScreen (or GameNotifier post-processing)
final gameAsync = ref.watch(gameProvider);
gameAsync.whenData((gameState) {
  if (gameState != null) {
    final winner = gameState.players
        .where((p) => p.isAlive).toList();
    if (winner.length == 1) {
      // Show game over modal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(context: context, builder: (_) => GameOverDialog(winner: winner.first));
      });
    }
  }
});
```

**GameOverDialog** shows the winner name, turn count, and New Game / Return to Home buttons.

### HomeScreen Upgrade (MOBX-01)

The existing `HomeScreen` has a hardcoded `GameConfig(playerCount: 3, difficulty: Difficulty.medium)`. Phase 11 replaces the `_NewGamePrompt` widget with a proper setup form:

- **Player count:** `Slider` (2–6) or `DropdownButton<int>`
- **Difficulty:** `SegmentedButton<Difficulty>` with Easy/Medium/Hard segments
- **Game mode:** Currently only single-player vs bots — keep it simple, one option; `gameMode` is not in the existing `GameConfig` model. Do NOT add `gameMode` to `GameConfig` until Phase 12 requires it (simulation mode is Phase 12).

**Important:** `GameConfig` is a plain Dart class (not freezed). Adding `gameMode` requires only adding a field with a default value. However, since Phase 12 is simulation mode and the requirement says "game mode from setup screen", this should add a `GameMode` enum (`vsBot` | `simulation`) to `GameConfig` now so the HomeScreen can surface it.

---

## Standard Stack

### Core (all already in pubspec.yaml — no new deps required)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | Watch gameProvider, uIStateProvider, gameLogProvider | Already wired throughout project |
| riverpod_annotation + riverpod_generator | ^4.0.2 / ^4.0.3 | Generate gameLogProvider (new notifier this phase) | Already configured, build_runner in place |
| freezed_annotation | ^3.0.0 | NOT needed for LogEntry (plain Dart is fine) | Already in pubspec |
| flutter/material.dart | SDK | Scaffold, BottomSheet, SegmentedButton, AlertDialog, PopScope | Material 3 default for this app |
| flutter_test | SDK | widget tests with WidgetTester | Already used in project |

### No New Dependencies

All UI construction in this phase uses Flutter SDK widgets (Material 3). No new `pub add` commands are needed. `riverpod_generator` is already configured and `build_runner` is already in `dev_dependencies`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dice selector radio buttons | Custom RadioGroup widget | `SegmentedButton<int>` (Material 3) | Built-in, accessible, handles exclusive selection |
| Back gesture interception | Custom GestureDetector | `PopScope` with `onPopInvokedWithResult` | Platform-correct: handles Android back button AND iOS swipe-back gesture |
| Bottom safe area padding | Manual pixel padding | `SafeArea` widget wrapping Scaffold body | Platform-adaptive: handles iPhone notch, Android nav bar, and foldables automatically |
| Action result feedback | Custom overlay | `ScaffoldMessenger.showSnackBar` | Correct Material pattern; accessible, dismissible |
| Human input blocking | Completer across isolate | One-shot HumanAgent on main isolate | Completers cannot cross isolate boundaries; this is the correct Dart pattern |
| Form state management | StatefulWidget + controllers | Local widget state (`StatefulWidget` with simple fields) | Setup screen has simple one-off fields; full form library is overkill |

---

## Common Pitfalls

### Pitfall 1: Trying to Wire HumanAgent Through Isolate.run()
**What goes wrong:** Developer tries to share a `Completer<AttackAction>` between the UI isolate and the `Isolate.run()` closure to let the human agent "pause" the engine. Dart throws `Invalid argument(s)` at the isolate boundary — `Completer`, `StreamController`, and most objects with internal ports cannot cross isolate boundaries.
**Why it happens:** The existing `runBotTurn()` uses `Isolate.run()` for all turns. It seems natural to reuse this path for the human. It is not.
**How to avoid:** Human turns never enter `Isolate.run()`. `GameNotifier` checks `state.value?.currentPlayerIndex == 0` and takes the direct-mutation path for player 0.
**Warning signs:** `Invalid argument` exceptions during bot turn dispatch; `Isolate.run()` capture of ref or BuildContext.

### Pitfall 2: WillPopScope vs PopScope (Removed in Flutter 3.x)
**What goes wrong:** `WillPopScope` was removed in Flutter 3.22. Code using it causes a compile error: `'WillPopScope' is deprecated and shouldn't be used`.
**Why it happens:** Most Stack Overflow answers and pre-2024 tutorials reference `WillPopScope`.
**How to avoid:** Use `PopScope` with `canPop: false` and `onPopInvokedWithResult`. The `result` parameter (added in Flutter 3.22) is required for the current API.
**Warning signs:** Compile-time deprecation warnings or missing symbol errors.

### Pitfall 3: showModalBottomSheet Dismissed on Tap-Outside
**What goes wrong:** Player is in the middle of a card trade selection, taps slightly outside the bottom sheet, and it dismisses — losing their in-progress selection. On iOS this is the default behavior.
**Why it happens:** `isDismissible` defaults to `true`.
**How to avoid:** All game-critical bottom sheets (card trade, advance armies, fortify count) must set `isDismissible: false` and `enableDrag: false`.
**Warning signs:** Bottom sheet closes unexpectedly during user testing; user loses progress in a multi-step action.

### Pitfall 4: ListView Game Log Not Auto-Scrolling
**What goes wrong:** New log entries are added to the bottom of the list but the `ListView` viewport does not scroll to show them — the latest event is always off-screen unless the user manually scrolls.
**Why it happens:** `ListView` does not auto-scroll by default. `ScrollController.jumpTo()` called during the same frame as `setState()` has no effect because the layout has not been updated yet.
**How to avoid:** Use `WidgetsBinding.instance.addPostFrameCallback` to schedule the scroll after the next frame renders.
**Warning signs:** Log entries appear but the view is stuck at the top or at a previous position.

### Pitfall 5: LayoutBuilder Breaks MapWidget Aspect Ratio
**What goes wrong:** The 1200x700 `SizedBox` inside `MapWidget` causes layout overflow in portrait mode when the screen height is tight. `LayoutBuilder` gives `maxWidth` correctly but the `MapWidget` tries to size itself to the SVG coordinate space and overflows vertically.
**Why it happens:** `MapWidget` currently uses `SizedBox(width: 1200, height: 700)` with `constrained: false` on `InteractiveViewer`. This is correct for the zoomed-out map but does not automatically fit into the available space.
**How to avoid:** Wrap `MapWidget` in `Expanded` within the portrait `Column`. The map will be constrained by the available vertical space. The `InteractiveViewer`'s `constrained: false` ensures the 1200x700 internal content is pannable within whatever viewport size the parent provides.
**Warning signs:** `RenderFlex overflowed by N pixels` in portrait mode.

### Pitfall 6: gameProvider Rebuild Storm During ActionPanel Rendering
**What goes wrong:** `ActionPanel` watches `gameProvider` and `uIStateProvider`. Both can update on territory tap. If `ActionPanel` also triggers UI rebuilds (e.g., by reading `gameAsync.value?.territories`), a tap can cause cascading rebuilds including a re-layout of the entire `Scaffold`.
**Why it happens:** Watching broad providers in a widget that re-renders expensive children. `gameProvider` emits a new `AsyncData` for every state change.
**How to avoid:** Use `select` to narrow the watched slice: `ref.watch(gameProvider.select((a) => a.value?.turnPhase))`. The `ActionPanel` only needs `turnPhase` for its top-level rendering logic; deeper details are passed explicitly or watched by sub-widgets.
**Warning signs:** Jank or dropped frames when tapping territories; profile shows `ActionPanel.build()` running on every map tap.

### Pitfall 7: GameState Missing gameMode / Human Play Detection
**What goes wrong:** The current `GameConfig` has `playerCount` and `difficulty` but no `gameMode`. The setup screen requirement says "game mode from setup screen" — this must be added to `GameConfig` now even if only `vsBot` mode is usable in Phase 11. Failing to add it means Phase 12 requires a data model change that affects providers, tests, and serialization.
**How to avoid:** Add `enum GameMode { vsBot, simulation }` and `gameMode` field to `GameConfig` before the setup screen is built. `GameConfig` is a plain Dart class (no code gen) so this change is trivial. No JSON serialization involved.

---

## Code Examples

### ActionPanel Skeleton

```dart
// Source: Flutter docs — Consumer widget + ref.watch select
class ActionPanel extends ConsumerWidget {
  const ActionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnPhase = ref.watch(
      gameProvider.select((a) => a.value?.turnPhase),
    );
    final armiesLeft = ref.watch(
      gameProvider.select((a) => a.value?.pendingArmies),
    );

    return switch (turnPhase) {
      TurnPhase.reinforce => _ReinforcePanel(armiesLeft: armiesLeft ?? 0),
      TurnPhase.attack    => const _AttackPanel(),
      TurnPhase.fortify   => const _FortifyPanel(),
      null                => const CircularProgressIndicator(),
    };
  }
}
```

**Note:** `pendingArmies` does not currently exist in `GameState`. It must be added: the number of armies the human has yet to place during the reinforce phase. Alternatively, track it in `UIStateNotifier` as ephemeral UI state (cleaner, does not pollute engine state).

### Portrait GameScreen Skeleton

```dart
// Source: Flutter layout docs
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return Row(children: [
                  const Expanded(flex: 3, child: MapWidget()),
                  SizedBox(width: 280, child: _GameSidebar()),
                ]);
              }
              return Column(children: [
                const Expanded(child: MapWidget()),
                const SizedBox(height: 200, child: ActionPanel()),
              ]);
            },
          ),
        ),
      ),
    );
  }
}
```

### GameNotifier humanMove Addition

```dart
// Source: derived from existing GameNotifier in game_provider.dart
// Added to GameNotifier class:

/// Execute a human player action for the current phase step.
/// Called by ActionPanel widgets — never enters Isolate.run().
Future<void> humanMove(Object action) async {
  if (_processing) return;
  final current = state.value;
  if (current == null) return;

  _processing = true;
  try {
    final mapGraph = await ref.read(mapGraphProvider.future);
    final agent = HumanAgent.fromAction(action);

    GameState newState;
    switch (current.turnPhase) {
      case TurnPhase.reinforce:
        newState = executeReinforcePhase(current, mapGraph, agent, current.currentPlayerIndex);
      case TurnPhase.attack:
        bool _; // victory handled by caller after state update
        (newState, _) = executeAttackPhase(current, mapGraph, agent, current.currentPlayerIndex, Random());
      case TurnPhase.fortify:
        newState = executeFortifyPhase(current, mapGraph, agent, current.currentPlayerIndex);
        // Advance to next player
        // ... advance turn logic
    }

    if (ref.mounted) {
      state = AsyncData(newState);
      _saveState();
    }
  } finally {
    _processing = false;
  }
}
```

---

## Architecture: What Phase 11 Adds vs What's Already There

### Already in Place (DO NOT REBUILD)

| Component | Where | Status |
|-----------|-------|--------|
| MapWidget | `lib/widgets/map/map_widget.dart` | Complete — hit testing, zoom, disambiguation |
| GameNotifier + gameProvider | `lib/providers/game_provider.dart` | Complete — setupGame, runBotTurn, clearSave, auto-save |
| UIStateNotifier + uIStateProvider | `lib/providers/ui_provider.dart` | Complete — selectTerritory, validSources, validTargets |
| mapGraphProvider | `lib/providers/map_provider.dart` | Complete |
| HomeScreen (stub) | `lib/screens/home_screen.dart` | Stub — needs upgrade to full setup form |
| All engine functions | `lib/engine/` | Complete — executeReinforcePhase, executeAttackPhase, etc. |
| All bot agents | `lib/bots/` | Complete |

### New Components to Build in Phase 11

| Component | File (suggested) | Purpose |
|-----------|-----------------|---------|
| GameScreen | `lib/screens/game_screen.dart` | Main game Scaffold with LayoutBuilder, PopScope |
| ActionPanel | `lib/widgets/action_panel.dart` | Phase-aware controls (reinforce/attack/fortify) |
| GameLog widget | `lib/widgets/game_log.dart` | ListView.builder + auto-scroll |
| gameLogProvider | `lib/providers/game_log_provider.dart` | StateNotifier holding List<LogEntry> |
| LogEntry model | `lib/engine/models/log_entry.dart` | Plain Dart, no freezed |
| ContinentPanel | `lib/widgets/continent_panel.dart` | Continent bonus display |
| GameOverDialog | `lib/widgets/game_over_dialog.dart` | Winner display, new game / home buttons |
| HumanAgent | `lib/bots/human_agent.dart` | One-shot PlayerAgent wrapper for UI actions |
| HomeScreen (upgrade) | `lib/screens/home_screen.dart` | Full setup form replacing stub |
| GameMode enum | `lib/engine/models/game_config.dart` | Add gameMode field to GameConfig |

### GameNotifier Additions Needed

| Method | Purpose |
|--------|---------|
| `humanMove(Object action)` | Apply human action for current phase step, advance state |
| `_advanceTurnIfBot()` | After human's turn ends, auto-trigger bot turns |

`UIStateNotifier` needs one addition: `pendingArmies` tracking during the reinforce phase, or this is tracked as widget-local state in `ActionPanel`.

---

## Recommended Project Structure for Phase 11 Files

```
mobile/lib/
├── screens/
│   ├── home_screen.dart     # UPGRADE: full setup form
│   └── game_screen.dart     # NEW: main game scaffold
├── widgets/
│   ├── map/                 # existing — no changes
│   ├── action_panel.dart    # NEW: phase-aware controls
│   ├── game_log.dart        # NEW: scrolling log list
│   ├── continent_panel.dart # NEW: bonus display
│   └── game_over_dialog.dart # NEW: win/lose modal
├── providers/
│   ├── game_provider.dart   # MODIFY: add humanMove()
│   └── game_log_provider.dart # NEW: list of LogEntry
├── bots/
│   └── human_agent.dart     # NEW: one-shot agent adapter
└── engine/models/
    ├── game_config.dart     # MODIFY: add GameMode enum
    └── log_entry.dart       # NEW: plain Dart LogEntry
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK, already configured) |
| Config file | none — uses `flutter test` runner |
| Quick run command | `cd mobile && flutter test test/screens/ test/widgets/ test/providers/` |
| Full suite command | `cd mobile && flutter test` |

**Note:** All tests currently run via `flutter test` from the `mobile/` directory. Flutter SDK is at `/home/amiller/flutter-sdk/flutter/bin/flutter`. The PATH note in STATE.md applies: `export PATH="/home/amiller/flutter-sdk/flutter/bin:$PATH"`.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOBX-01 | HomeScreen renders setup form; player count, difficulty, game mode are configurable; tapping Start calls setupGame | widget | `flutter test test/screens/home_screen_test.dart` | Wave 0 |
| MOBX-01 | GameConfig includes gameMode field and defaults correctly | unit | `flutter test test/engine/game_config_test.dart` | Wave 0 |
| MOBX-02 | GameScreen portrait layout: map + bottom panel, no overflow | widget | `flutter test test/screens/game_screen_test.dart` | Wave 0 |
| MOBX-02 | GameScreen landscape layout (600dp+ width): map + sidebar | widget | `flutter test test/screens/game_screen_test.dart` | Wave 0 |
| MOBX-03 | ActionPanel shows reinforce controls when turnPhase == reinforce | widget | `flutter test test/widgets/action_panel_test.dart` | Wave 0 |
| MOBX-03 | ActionPanel shows attack controls (dice selector, end attack) when turnPhase == attack | widget | `flutter test test/widgets/action_panel_test.dart` | Wave 0 |
| MOBX-03 | ActionPanel shows fortify controls (skip fortify) when turnPhase == fortify | widget | `flutter test test/widgets/action_panel_test.dart` | Wave 0 |
| MOBX-03 | humanMove() in GameNotifier advances game state correctly for reinforce action | unit | `flutter test test/providers/human_move_test.dart` | Wave 0 |
| MOBX-04 | gameLogProvider accumulates entries; GameLog widget renders list | widget | `flutter test test/widgets/game_log_test.dart` | Wave 0 |
| MOBX-05 | ContinentPanel renders correct continent names and bonuses | widget | `flutter test test/widgets/continent_panel_test.dart` | Wave 0 |
| MOBX-06 | GameOverDialog shows winner name and new game button | widget | `flutter test test/widgets/game_over_dialog_test.dart` | Wave 0 |

### Sampling Rate

- **Per task commit:** `cd mobile && flutter test test/screens/ test/widgets/ test/providers/ --name "phase11"` (or specific test files for the task)
- **Per wave merge:** `cd mobile && flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `mobile/test/screens/home_screen_test.dart` — covers MOBX-01 setup form
- [ ] `mobile/test/engine/game_config_test.dart` — covers GameMode enum field
- [ ] `mobile/test/screens/game_screen_test.dart` — covers MOBX-02 portrait/landscape layout
- [ ] `mobile/test/widgets/action_panel_test.dart` — covers MOBX-03 phase-aware controls
- [ ] `mobile/test/providers/human_move_test.dart` — covers MOBX-03 humanMove() engine wiring
- [ ] `mobile/test/widgets/game_log_test.dart` — covers MOBX-04 log rendering
- [ ] `mobile/test/widgets/continent_panel_test.dart` — covers MOBX-05 continent display
- [ ] `mobile/test/widgets/game_over_dialog_test.dart` — covers MOBX-06 game over screen

**Existing test infra notes:**
- `testWidgets skip:` must use `markTestSkipped()` in test body (bool? constraint — documented in STATE.md `[10-01]`)
- Widget tests that watch providers need `ProviderScope` wrapping: `tester.pumpWidget(ProviderScope(child: widget))`
- Tests that need a real `GameState` use `engine_setup.setupGame(mapGraph, playerCount)` pattern from existing provider tests

---

## Open Questions

1. **Human turn advancement: full phase or step-by-step?**
   - What we know: The engine's `executeReinforcePhase`, `executeAttackPhase`, `executeFortifyPhase` each complete a full phase in one call. For bots this is correct (bot decides everything). For humans, reinforce and attack are multi-step (multiple army placements, multiple attacks).
   - What's unclear: Should `humanMove()` advance a full phase at once (human picks all placements in one interaction) or step-by-step (one action per call)?
   - Recommendation: Step-by-step for attack (one attack per tap), but single-call for reinforce (player distributes armies in the ActionPanel UI then taps "Confirm Placement"). The engine's `executeReinforcePhase` can be called once with the full `ReinforcePlacementAction`. For attack, `humanMove(AttackAction)` calls `executeAttack()` once and returns; the player taps "End Attack" to transition to fortify.

2. **pendingArmies tracking during reinforce phase**
   - What we know: The human must distribute exactly N armies during reinforce. The engine validates this in `executeReinforcePhase`. The UI needs to track how many have been allocated vs. remaining.
   - What's unclear: Whether to track this in `UIStateNotifier` or as widget-local state in the ActionPanel form.
   - Recommendation: Track in `UIStateNotifier` — add `pendingArmies: int` and `proposedPlacements: Map<String, int>` fields to `UIState`. This avoids the reinforce state living only in ephemeral widget state (which gets lost on orientation change). UIState is already a freezed model and would need `pendingArmies` added.

3. **Game log source of truth**
   - What we know: `gameLogProvider` as a separate `StateNotifier` avoids polluting serialized `GameState`. `GameNotifier` would call `ref.read(gameLogProvider.notifier).add(...)` after each event.
   - What's unclear: `GameNotifier` can only call `ref.read()` (not watch) from inside its methods. This is valid Riverpod pattern.
   - Recommendation: Separate `gameLogProvider` is correct. `GameNotifier.humanMove()` and `runBotTurn()` call `ref.read(gameLogProvider.notifier).add(message)` after state updates.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `WillPopScope` | `PopScope` with `onPopInvokedWithResult` | Flutter 3.22 (2024) | Must use PopScope — WillPopScope removed |
| `showModalBottomSheet` with builder only | `showModalBottomSheet` with `isDismissible: false, enableDrag: false` for game-critical | Always best practice | Prevents accidental dismissal |
| `ref.watch(provider).when(...)` everywhere | `ref.watch(provider.select(...))` for narrow slices | Riverpod 2+ | Prevents unnecessary rebuilds |
| Manual SegmentedControl widget | `SegmentedButton<T>` (Material 3) | Flutter 3.10 (2023) | Built-in, accessible; preferred over Radio widgets for small sets |
| `Navigator.of(context).push(...)` | Same, but with `context.mounted` guard after async | Best practice since Dart null-safety | Prevents BuildContext-after-async warnings |

**Deprecated patterns to avoid:**
- `WillPopScope`: removed, use `PopScope`
- `showBottomSheet` (persistent, not modal): still exists but `BottomSheet` widget usage within Scaffold is cleaner for always-visible panels
- `RadioListTile` for dice selection: verbose; use `SegmentedButton` (M3)

---

## Sources

### Primary (HIGH confidence)

- Flutter source code at `/home/amiller/Repos/risk/mobile/lib/` — direct inspection of all existing providers, models, engine functions, and widget infrastructure
- Flutter 3.x documentation patterns — `PopScope`, `LayoutBuilder`, `SegmentedButton`, `SafeArea` (verified by project's `flutter: ">=3.41.0"` SDK constraint)
- Existing Phase 9 provider patterns (STATE.md decisions and 09-02-SUMMARY.md) — `ref.read()`, `ProviderContainer`, override patterns
- Existing Phase 10 patterns (10-03-SUMMARY.md) — `markTestSkipped()`, widget test patterns, `ProviderScope` in tests

### Secondary (MEDIUM confidence)

- PROJECT-level RESEARCH.md SUMMARY.md (`/home/amiller/Repos/risk/.planning/research/SUMMARY.md`) — confirms standard stack, architecture decisions, pitfall catalog for the entire v1.1 project
- Flutter Material 3 component catalog — `SegmentedButton`, `FilterChip` for game controls (current Material 3 components, matches the `ThemeData(colorSchemeSeed: Colors.red)` already in `app.dart`)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries are already in pubspec.yaml; zero new dependencies needed; verified against actual project files
- Architecture: HIGH — HumanAgent pattern is derived directly from the Dart isolate constraint (Completers cannot cross isolate boundaries) and the existing `PlayerAgent` interface; this is not exploratory
- Pitfalls: HIGH — most pitfalls are derived from directly reading the existing codebase (WillPopScope removed, `isDismissible` default, LayoutBuilder overflow with fixed-size SizedBox) or from the project's own STATE.md documented decisions

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable Flutter APIs; no fast-moving ecosystem changes expected)
