# Phase 8: Bot Agents — Research

**Researched:** 2026-03-15
**Domain:** Dart AI agent implementation, Dart isolates, pure-function bot strategy
**Confidence:** HIGH

---

## Summary

Phase 8 ports three Python AI difficulty levels (Easy/RandomAgent, Medium/MediumAgent,
Hard/HardAgent) into Dart classes that implement the `PlayerAgent` abstract interface
already created in Phase 7. The interface contract, engine function signatures, and
data models are all finalized — this phase is a direct algorithmic translation,
not a design problem.

The primary technical concerns are: (1) confirming the Dart `Isolate.run()` boundary
works cleanly with plain Dart objects, (2) understanding how to inject `MapGraph` into
bot instances (Python uses duck-typed injection; Dart must be explicit constructor
injection), and (3) ensuring statistical validation matches the Python baseline (~80%
HardAgent win rate vs Medium over 500 games) without relying on PRNG equivalence.

The phase produces no Flutter widget code. All files live in `mobile/lib/bots/` and
`mobile/test/bots/`. Testing uses `flutter test` with the existing `FakeRandom` helpers
already established in `mobile/test/helpers/fake_random.dart`.

**Primary recommendation:** Implement agents as pure Dart classes with constructor-injected
`MapGraph` and `Random`. Run statistical validation with a full game simulation loop in
Dart (mirrors Python's `run_game`). Wrap each bot turn in `Isolate.run()` at the
`GameNotifier` level — agents themselves stay synchronous.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BOTS-05 | Easy bot ported (random valid moves) | Python `RandomAgent` in `risk/game.py` is a direct algorithmic translation; all needed engine functions exist in Dart (`isValidSet`, `connectedTerritories`, `neighbors`) |
| BOTS-06 | Medium bot ported (continent focus, border reinforcement) | Python `MediumAgent` in `risk/bots/medium.py`; `MapGraph` API in Dart exposes all required methods (`continentTerritories`, `neighbors`, `connectedTerritories`, `continentBonus`) |
| BOTS-07 | Hard bot ported (multi-factor heuristic scoring, threat assessment) | Python `HardAgent` in `risk/bots/hard.py`; uses precomputed `ATTACK_PROBABILITIES` table and scoring weights — port as Dart constants; all graph traversal uses `MapGraph` already available |
| BOTS-08 | Bot computation runs in isolate (no UI thread blocking) | `Isolate.run()` API confirmed in official Dart docs; plain Dart objects (`GameState`, `MapGraph`) cross isolate boundary cleanly; agents are synchronous pure functions |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dart:math` Random | bundled (Dart 3.11) | Injected RNG for all agent decisions | Already used throughout engine; injectable for test determinism |
| `dart:isolate` / `Isolate.run()` | bundled (Dart 3.11) | Offload bot turn from UI thread | Required by BOTS-08; well-documented pattern |
| `flutter_test` | bundled | Unit tests for agent behavior | Existing test infrastructure; same pattern as all Phase 7 tests |

### No New Dependencies
Phase 8 requires no new pub.dev packages. All Dart APIs are from the standard library.
All game types (`GameState`, `MapGraph`, `AttackAction`, etc.) are already in `mobile/lib/`.

### Installation
```bash
# No new packages — all dependencies already in mobile/pubspec.yaml
```

---

## Architecture Patterns

### Recommended File Structure
```
mobile/lib/bots/
├── player_agent.dart     # EXISTING — abstract interface (Phase 7)
├── easy_agent.dart       # NEW — RandomAgent port
├── medium_agent.dart     # NEW — MediumAgent port
└── hard_agent.dart       # NEW — HardAgent port + ATTACK_PROBABILITIES constant

mobile/test/bots/
├── easy_agent_test.dart      # Unit tests with FakeRandom
├── medium_agent_test.dart    # Unit tests with FakeRandom
├── hard_agent_test.dart      # Unit tests with FakeRandom
└── win_rate_test.dart        # Statistical validation (500+ games)
```

### Pattern 1: Constructor-Injected MapGraph (Not Post-Construction)

**What:** Python injects `_map_graph` via duck-typed attribute assignment after
construction (`agent._map_graph = map_graph`). Dart agents should receive `MapGraph`
as a required constructor parameter instead. This is idiomatic Dart and avoids
nullable field guards throughout the agent methods.

**When to use:** Always for new Dart agents.

**Example:**
```dart
// Source: direct idiomatic Dart translation of Python pattern
class HardAgent implements PlayerAgent {
  final MapGraph _mapGraph;
  final Random _rng;

  HardAgent({required MapGraph mapGraph, Random? rng})
      : _mapGraph = mapGraph,
        _rng = rng ?? Random();
}
```

**Python original used nullable check guards** (`if mg is None: return ...`) throughout
every method. Dart constructor injection eliminates all those guards. The Dart methods
can access `_mapGraph` directly without null checks.

### Pattern 2: Isolate.run() Boundary — Plain Dart Objects Pass Cleanly

**What:** `Isolate.run()` requires the closure and any captured values to be sendable
across the isolate boundary. Plain Dart objects with no Flutter imports (like `GameState`,
`MapGraph`, `EasyAgent`) pass cleanly. No serialization needed.

**Important caveat from official docs:** The closure passed to `Isolate.run()` must be
a top-level function or a static method — it cannot be a lambda that captures non-sendable
state. In practice, creating agents and `MapGraph` inside the closure (from raw `MapData`
or from the already-serializable `GameState`) is the pattern.

**When to use:** `GameNotifier.runBotTurn()` calls `Isolate.run()`. The agents
themselves are synchronous — they never call `Isolate.run()` internally.

**Example (used at GameNotifier level, not inside agents):**
```dart
// Source: dart.dev/language/isolates — Isolate.run() pattern
Future<GameState> runBotTurn(GameState state, MapGraph mapGraph, int difficulty) async {
  return await Isolate.run(() {
    final rng = Random();
    final agent = _makeAgent(difficulty, mapGraph, rng);
    final agents = {state.currentPlayerIndex: agent};
    // Other players get placeholder agents if needed, or use stored difficulty map
    final (newState, _) = executeTurn(state, mapGraph, agents, rng);
    return newState;
  });
}
```

**Caveats to verify:**
- `GameState` is a `@freezed` class — it is a plain Dart value type with no Flutter
  references. It passes across isolate boundaries.
- `MapGraph` is a plain Dart class (zero Flutter imports, confirmed from source).
  It passes across isolate boundaries.
- `Random` objects created inside the closure are fine; do not pass a `Random` from
  the outer isolate.

### Pattern 3: ATTACK_PROBABILITIES as a Dart Map Constant

**What:** Python `HardAgent` uses a module-level `ATTACK_PROBABILITIES` dict. In Dart,
this becomes a `const Map<(int, int), List<double>>` at file scope. Dart record types
`(int, int)` work as map keys if both elements are primitive.

**Note:** Dart record types as map keys require `==` and `hashCode` — Dart records have
structural equality by default, so `(3, 2) == (3, 2)` is `true`. This makes them valid
const map keys only if ALL values are compile-time constants.

**Recommended alternative:** Use a nested map or encode the key as a string:
```dart
// Source: Dart language spec — records have structural equality but not const
// Use Map<String, List<double>> with key encoding to avoid const limitations
const Map<String, List<double>> attackProbabilities = {
  '1,1': [0.4167, 0.5833],
  '2,1': [0.5787, 0.4213],
  '3,1': [0.6597, 0.3403],
  '1,2': [0.2546, 0.7454],
  '2,2': [0.2276, 0.4483, 0.3241],
  '3,2': [0.3717, 0.2926, 0.3358],
};

List<double> _lookupProb(int attackerDice, int defenderDice) =>
    attackProbabilities['$attackerDice,$defenderDice']!;
```

### Pattern 4: Statistical Validation Loop in Dart

**What:** Phase 8 must verify win rates match Python baseline (HardAgent ~80% vs Medium).
This requires a full game simulation loop in Dart that mirrors Python's `run_game()`.
The Python `run_game` function is already ported to Dart as `executeTurn` + setup logic.

A dedicated `runGame()` Dart function (analogous to Python's `run_game`) belongs in
the test helpers or a separate `simulation.dart` file usable by both the win_rate test
and the future Phase 12 simulation mode.

**Example structure:**
```dart
// win_rate_test.dart — statistical validation
test('HardAgent wins ~80% vs MediumAgent over 500 games', () async {
  int hardWins = 0;
  const games = 500;
  for (int i = 0; i < games; i++) {
    final rng = Random(i); // seeded for reproducibility
    final mapData = ...; // load classic.json once outside loop
    final mapGraph = MapGraph(mapData);
    final agents = {
      0: HardAgent(mapGraph: mapGraph, rng: rng),
      1: MediumAgent(mapGraph: mapGraph, rng: rng),
    };
    final result = runGame(mapGraph, agents, rng);
    if (result.players[0].isAlive) hardWins++;
  }
  final winRate = hardWins / games;
  expect(winRate, closeTo(0.80, 0.05)); // within 5pp
});
```

**Note on test speed:** 500 games at ~50 turns each = 25,000 `executeTurn` calls.
In Dart this runs in < 5 seconds on a modern machine (no I/O, pure computation).
Do NOT use `Isolate.run()` in the test loop — tests run serially on the test runner
thread; isolates in tests add overhead without benefit.

### Pattern 5: AttackChoice Sealed Class Dispatch

**What:** The Dart `PlayerAgent.chooseAttack()` returns `AttackChoice?` — a sealed
class with `AttackAction` and `BlitzAction` variants. Python bots only return
`AttackAction` (not `BlitzAction`). Dart bots should follow the same pattern: return
`AttackAction?` cast as `AttackChoice?`, never `BlitzAction`.

This matches the Python `choose_blitz()` returning `None` — Python bots use
regular attacks for granular control.

```dart
// Correct — Dart bots return AttackAction (never BlitzAction)
@override
AttackChoice? chooseAttack(GameState state) {
  // ... compute source/target
  if (source == null) return null;
  return AttackAction(source: source, target: target, numDice: numDice);
}
```

### Anti-Patterns to Avoid

- **Nullable MapGraph field:** Do NOT use Python's post-construction injection pattern
  (`_mapGraph` as nullable with null guards). Use constructor injection; the Dart
  `PlayerAgent` interface doesn't dictate construction, so agents can require
  `MapGraph` in their constructors.

- **Agents calling Isolate.run() internally:** Agents are synchronous pure functions.
  The isolate boundary is at the `GameNotifier` level only. Agent methods must not
  use `async`/`await`.

- **Accessing `_continent_territories` directly:** Python bots access
  `mg._continent_territories` and `mg._continent_map` as internal fields (Python
  has no access modifiers). In Dart these are private (`_continentTerritories`,
  `_continentByTerritory`). Use the public API methods: `continentTerritories(name)`,
  `continentOf(territory)`, `continentNames`, `continentBonus(name)`.

- **Iterating `GameState.territories` in undefined order:** Dart `Map` preserves
  insertion order (LinkedHashMap), but Python `dict` also preserves insertion order
  since Python 3.7. Both engines process territories in the order they appear in
  `classic.json`. This means tie-breaking in bot heuristics (e.g. "first candidate
  with advantage") will produce the same winner as Python as long as iteration order
  matches. Verify during statistical testing; if rates diverge, check sort stability.

---

## MapGraph API: Python → Dart Translation

The Python bots access private fields of `MapGraph` in several places. The Dart
`MapGraph` exposes a public API that covers all required operations:

| Python (private field access) | Dart public API equivalent |
|-------------------------------|---------------------------|
| `mg._continent_territories.items()` | `for name in mg.continentNames: mg.continentTerritories(name)` |
| `mg._continent_map.get(target)` | `mg.continentOf(territory)` |
| `mg.continent_territories(name)` | `mg.continentTerritories(name)` |
| `mg.neighbors(name)` | `mg.neighbors(name)` |
| `mg.connected_territories(src, owned)` | `mg.connectedTerritories(src, owned)` |
| `mg.continent_bonus(name)` | `mg.continentBonus(name)` |

All required operations are available through the public API. No Dart equivalent of
Python's private field access is needed or appropriate.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Card set validation | Custom set-checking logic | `isValidSet()` from `cards_engine.dart` | Already ported, tested, handles wildcards correctly |
| Connected territory BFS | New BFS in agent code | `mapGraph.connectedTerritories()` | Already ported with correct NetworkX semantics |
| Army calculation | Manual territory-count logic | `calculateReinforcements()` from `reinforcements.dart` | Engine function handles all edge cases including continent bonuses |
| Win rate benchmark infrastructure | Ad-hoc simulation | Extract `runGame()` helper from test setup | Will be reused by Phase 12 simulation mode — establish the pattern now |

---

## Common Pitfalls

### Pitfall 1: Dart MapGraph Private Fields vs Python Private Fields

**What goes wrong:** Python bots directly access `mg._continent_territories` (a dict)
and `mg._continent_map` (a dict mapping territory → continent name). In Dart, these
are private (`_continentTerritories`, `_continentByTerritory`) and inaccessible from
`mobile/lib/bots/`.

**Why it happens:** Python has no access enforcement; `_` is convention only. Dart
`_` prefix enforces library-level privacy.

**How to avoid:** Use the public API: `mg.continentOf(territory)` instead of
`mg._continent_map.get(territory)`, and iterate via `mg.continentNames` +
`mg.continentTerritories(name)` instead of `mg._continent_territories.items()`.

**Warning signs:** Compiler error `'_continentByTerritory' isn't defined` or
`The getter '_continentTerritories' isn't defined`.

### Pitfall 2: MapGraph Iteration Order for Continent Scoring

**What goes wrong:** `_continent_scores` in both Python bots iterates all continents
and computes a score. In Python, `max(scores, key=...)` will break ties consistently
because dict iteration order is deterministic. In Dart, `Map.keys` iteration order is
also deterministic (insertion order). Both should agree as long as `classic.json`
continent order is identical.

**Why it happens:** If the Dart continent scoring produces slightly different `max()`
results due to floating-point ordering, the bot may choose different reinforcement
targets, causing win-rate divergence.

**How to avoid:** If win rates fall outside the 5pp tolerance, add explicit secondary
sort by continent name (string sort) to break ties deterministically. This matches
a common Python behavior where dict keys have incidental alphabetic ordering.

**Warning signs:** Win rate test fails intermittently with different seeds; or rate
is consistently 5-10pp off from Python baseline.

### Pitfall 3: Isolate.run() Closure Must Be a Top-Level Function

**What goes wrong:** `Isolate.run()` requires the function argument to be a
`SendPort`-compatible callable. A closure that captures non-primitive values from the
enclosing scope may fail at runtime with `Invalid argument: is not a SendPort`.

**Why it happens:** Dart's isolate boundary requires all transferred values to be
primitives, typed data lists, or sendable objects. Closures that close over Riverpod
`ref`, Flutter widget state, or platform-channel objects cannot be transferred.

**How to avoid:** Pass only plain Dart values into the `Isolate.run()` closure
parameter. Create agents, `MapGraph`, and `Random` inside the closure. If `MapData`
must come from outside, pass it as a function argument (it is a `@freezed` plain
Dart object with no Flutter imports).

**Warning signs:** Runtime exception `Isolate.run`: `Invalid argument`.

### Pitfall 4: HardAgent Advance Armies — Interior Detection After Conquest

**What goes wrong:** `_is_interior()` in Python's HardAgent checks if all neighbors of
a territory are owned by the same player. After conquest, the newly captured territory's
ownership has changed in `state`, so `_is_interior(state, source)` may now return
`true` for the source territory (if taking the last enemy neighbor). But the engine
has already deducted armies from `source` and placed them in `target`. The
`chooseAdvanceArmies` method sees the post-conquest state.

**Why it happens:** The Python engine passes the post-conquest state to
`choose_advance_armies`. The Dart engine does the same (confirmed in `turn.dart`).
Both the Python and Dart HardAgent methods should behave consistently as long as
both read from post-conquest state.

**How to avoid:** Read `choose_advance_armies` in context: it receives the
post-conquest `GameState`. The `source` territory still has at least 1 army (the
engine ensures this). The `target` territory is now owned by the bot. The
`_is_interior` check on `source` reflects the post-conquest world.

**Warning signs:** `chooseAdvanceArmies` returns 0 or throws a clamp error.

### Pitfall 5: Statistical Test Performance

**What goes wrong:** Running 500 full games in a single test suite can time out on
slow CI machines or cause flutter_test's default timeout to trigger.

**Why it happens:** `flutter test` has a 30-second default timeout per test. 500
games x ~50 turns x ~10 agent calls per turn = ~250,000 function calls. This is
fast in Dart (~2-3 seconds locally) but may be unpredictable in CI.

**How to avoid:** Set a generous explicit test timeout (`timeout: Timeout(Duration(minutes: 2))`).
Run statistical tests in a separate test file (`win_rate_test.dart`) so unit tests
run fast independently. Optionally mark win-rate tests with `@Tags(['slow'])` to
allow selective exclusion.

**Warning signs:** `Test timed out after 30 seconds`.

---

## Code Examples

### EasyAgent (RandomAgent port)

Python distributes armies one-at-a-time with `rng.choice(owned)`. Dart equivalent:

```dart
// Direct port of risk/game.py RandomAgent.choose_reinforcement_placement
@override
ReinforcePlacementAction chooseReinforcementPlacement(GameState state, int armies) {
  final playerIdx = state.currentPlayerIndex;
  final owned = state.territories.entries
      .where((e) => e.value.owner == playerIdx)
      .map((e) => e.key)
      .toList();
  final placements = <String, int>{};
  for (int i = 0; i < armies; i++) {
    final t = owned[_rng.nextInt(owned.length)];
    placements[t] = (placements[t] ?? 0) + 1;
  }
  return ReinforcePlacementAction(placements: placements);
}
```

### MediumAgent: Continent Score Helper

Python accesses `mg._continent_territories` directly. Dart uses public API:

```dart
// Direct port of risk/bots/medium.py MediumAgent._continent_scores
// using Dart MapGraph public API instead of private field access
Map<String, double> _continentScores(GameState state) {
  final player = state.currentPlayerIndex;
  final scores = <String, double>{};
  for (final continent in _mapGraph.continentNames) {
    final territories = _mapGraph.continentTerritories(continent);
    if (territories.isEmpty) continue;
    final owned = territories
        .where((t) => state.territories[t]?.owner == player)
        .length;
    scores[continent] = owned / territories.length;
  }
  return scores;
}
```

### HardAgent: Win Probability Estimation

Python's `_estimate_win_probability` uses a 50-iteration simulation loop with
the precomputed probability table. This is a pure numeric function — direct port:

```dart
// Direct port of risk/bots/hard.py _estimate_win_probability
double _estimateWinProbability(int attackerArmies, int defenderArmies) {
  double a = (attackerArmies - 1).toDouble();
  double d = defenderArmies.toDouble();
  if (a <= 0) return 0.0;
  if (d <= 0) return 1.0;
  for (int i = 0; i < 50; i++) {
    if (a <= 0) return 0.0;
    if (d <= 0) return 1.0;
    final attDice = min(3, max(1, a.toInt()));
    final defDice = min(2, max(1, d.toInt()));
    final probs = _lookupProb(attDice, defDice);
    if (probs.length == 2) {
      final pAttWin = probs[0];
      a -= (1 - pAttWin);
      d -= pAttWin;
    } else {
      a -= 2 * probs[1] + probs[2];
      d -= 2 * probs[0] + probs[2];
    }
  }
  if (d <= 0) return 1.0;
  if (a <= 0) return 0.0;
  return a / (a + d);
}
```

### runGame Helper (needed for statistical tests)

```dart
// Analogous to risk/game.py run_game — needed for win_rate_test.dart
// Place in mobile/test/helpers/run_game.dart or mobile/lib/engine/simulation.dart
GameState runGame(
  MapGraph mapGraph,
  Map<int, PlayerAgent> agents,
  Random rng, {
  int maxTurns = 5000,
}) {
  var state = setupGame(mapGraph, agents.length, rng);
  // Initialize deck
  var deck = createDeck(mapGraph.allTerritories);
  // Shuffle deck using Fisher-Yates
  for (int i = deck.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = deck[i]; deck[i] = deck[j]; deck[j] = tmp;
  }
  final cards = {for (int i = 0; i < agents.length; i++) i.toString(): <Card>[]};
  state = state.copyWith(deck: deck, cards: cards);

  for (int turn = 0; turn < maxTurns; turn++) {
    final (newState, victory) = executeTurn(state, mapGraph, agents, rng);
    state = newState;
    if (victory) return state;
  }
  throw StateError('Game did not complete within $maxTurns turns');
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Python duck-typed `_map_graph` post-injection | Dart constructor injection (`required MapGraph mapGraph`) | Phase 8 | Eliminates null guards; compile-time safety |
| Python `random.Random()` global module import | Dart `dart:math Random` injected constructor parameter | Phase 7 established pattern | Enables `FakeRandom` for deterministic tests |
| Python private field access `mg._continent_map` | Dart public API `mg.continentOf()` | Phase 8 (MapGraph public API added in Phase 7) | Idiomatic Dart; no breaking encapsulation |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with Flutter 3.41) |
| Config file | `mobile/pubspec.yaml` dev_dependencies |
| Quick run command | `cd /home/amiller/flutter-sdk/flutter && bin/flutter test mobile/test/bots/ --no-pub` |
| Full suite command | `cd /home/amiller/flutter-sdk/flutter && bin/flutter test mobile/test/ --no-pub` |

Note: Flutter SDK is at `/home/amiller/flutter-sdk/flutter/bin/flutter` (not in PATH per STATE.md).

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOTS-05 | EasyAgent places only on owned territories | unit | `bin/flutter test mobile/test/bots/easy_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-05 | EasyAgent returns AttackAction only for valid source/target pairs | unit | `bin/flutter test mobile/test/bots/easy_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-05 | EasyAgent fortify returns valid connected path | unit | `bin/flutter test mobile/test/bots/easy_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-06 | MediumAgent reinforces border of highest-scoring continent | unit | `bin/flutter test mobile/test/bots/medium_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-06 | MediumAgent attacks with continent-completion priority | unit | `bin/flutter test mobile/test/bots/medium_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-06 | MediumAgent fortifies from interior to border | unit | `bin/flutter test mobile/test/bots/medium_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-07 | HardAgent reinforces highest-BSR border territory | unit | `bin/flutter test mobile/test/bots/hard_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-07 | HardAgent attacks continent-completing target first | unit | `bin/flutter test mobile/test/bots/hard_agent_test.dart -x` | ❌ Wave 0 |
| BOTS-07 | HardAgent win rate within 5pp of 80% vs Medium over 500 games | statistical | `bin/flutter test mobile/test/bots/win_rate_test.dart --timeout 120s` | ❌ Wave 0 |
| BOTS-08 | Bot turn runs in Isolate.run() without blocking UI thread | integration | Manual: run on device and confirm no frame drops; automated: verify `Isolate.run()` call in GameNotifier | N/A — Phase 9 integration |

Note on BOTS-08: The `Isolate.run()` call lives in `GameNotifier` (Phase 9). Phase 8
establishes that agents are synchronous functions suitable for isolate wrapping.
Validate BOTS-08 requirement during Phase 9 by confirming agent classes contain no
`async` methods and no Flutter imports.

### Sampling Rate
- **Per task commit:** `bin/flutter test mobile/test/bots/ --no-pub`
- **Per wave merge:** `bin/flutter test mobile/test/ --no-pub`
- **Phase gate:** Full suite (81 existing + new bot tests) green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `mobile/test/bots/easy_agent_test.dart` — covers BOTS-05
- [ ] `mobile/test/bots/medium_agent_test.dart` — covers BOTS-06
- [ ] `mobile/test/bots/hard_agent_test.dart` — covers BOTS-07
- [ ] `mobile/test/bots/win_rate_test.dart` — statistical validation for BOTS-07
- [ ] `mobile/lib/bots/easy_agent.dart` — implementation
- [ ] `mobile/lib/bots/medium_agent.dart` — implementation
- [ ] `mobile/lib/bots/hard_agent.dart` — implementation
- [ ] `mobile/test/helpers/run_game.dart` — shared `runGame()` helper (needed by win_rate_test and Phase 12)

Existing infrastructure that Phase 8 reuses without modification:
- `mobile/test/helpers/fake_random.dart` — FakeRandom(List<int>) already exists
- `mobile/lib/bots/player_agent.dart` — abstract interface already exists
- All engine functions (combat, cards_engine, reinforcements, fortify, turn, setup, map_graph)

---

## Open Questions

1. **Can `GameState` (freezed) pass across `Isolate.run()` boundary without serialization?**
   - What we know: `GameState` is a plain Dart value type, zero Flutter imports
   - What's unclear: `@freezed` generates code that may include non-sendable types
     (e.g., `==` overrides, `hashCode`). These are typically fine; `Isolate.run()`
     copies by deep-copy for non-primitive types.
   - Recommendation: Validate with a minimal `Isolate.run(() => gameState)` call
     in a test during Plan 1 setup. If it throws, fall back to JSON encode/decode
     at the boundary (`GameState.toJson()` / `GameState.fromJson()`).

2. **Should `runGame()` go in `lib/engine/` or `test/helpers/`?**
   - What we know: The function will be needed by Phase 12 simulation mode
     (BOTS-09: AI-vs-AI simulation mode). Phase 8 needs it for statistical tests.
   - What's unclear: Whether the Phase 12 planner wants it in production code or
     test-only code.
   - Recommendation: Place in `mobile/lib/engine/simulation.dart` (production code).
     This avoids duplicating the function in Phase 12, and it has no Flutter
     dependencies so it belongs in the engine layer.

3. **Win rate target: 80% +/- 5pp or a different baseline?**
   - What we know: Python HardAgent achieves ~80% vs Medium (from v1.0 development);
     success criterion states "within 5pp of ~80%".
   - What's unclear: The exact Python measurement (how many games, what seed range).
   - Recommendation: Run Python `run_game` with 500 seeds (0–499) to establish an
     exact baseline before coding. If Python baseline is e.g. 78.4%, target 73–84%.
     Do this as part of Plan 1 (establish baseline before porting).

---

## Sources

### Primary (HIGH confidence)
- `mobile/lib/bots/player_agent.dart` — exact interface contract (5 methods, return types)
- `mobile/lib/engine/turn.dart` — how agents are called (signatures, state passing)
- `mobile/lib/engine/map_graph.dart` — confirmed public API surface
- `risk/game.py` — RandomAgent (EasyAgent) complete source
- `risk/bots/medium.py` — MediumAgent complete source
- `risk/bots/hard.py` — HardAgent complete source + ATTACK_PROBABILITIES table
- [Dart Isolates — official docs](https://dart.dev/language/isolates) — `Isolate.run()` API
- [Flutter concurrency and isolates](https://docs.flutter.dev/perf/isolates) — Flutter-specific guidance
- `.planning/STATE.md` — confirmed Flutter SDK path, all Phase 7 decisions

### Secondary (MEDIUM confidence)
- `.planning/research/ARCHITECTURE.md` — isolate pattern, agent pattern confirmed
- `.planning/research/SUMMARY.md` — bot isolate architecture decision rationale

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all APIs confirmed in existing source files
- Architecture: HIGH — PlayerAgent contract is finalized; Python source is the spec
- Pitfalls: HIGH — based on direct analysis of Python private-field access vs Dart
  public API, plus confirmed engine call patterns from turn.dart
- Statistical targets: MEDIUM — "~80%" is from v1.0 experience; exact baseline
  should be re-measured in Python before porting

**Research date:** 2026-03-15
**Valid until:** Stable — the Python source files are the spec and won't change; Dart APIs are confirmed
