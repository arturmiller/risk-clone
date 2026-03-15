# Phase 7: Dart Game Engine Port - Research

**Researched:** 2026-03-15
**Domain:** Pure-Dart algorithmic port of Python game rules + golden-fixture validation strategy
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DART-01 | All combat rules ported (dice rolling, attacker/defender pairing, ties to defender) | combat.py is fully read; translation is direct; `dart:math.Random` injected for testability |
| DART-02 | Card system ported (deck, drawing, trading with escalating bonus, forced trade at 5+) | cards.py is fully read; escalation table is a literal constant; string-keyed Map<String, List<Card>> already matches Dart model |
| DART-03 | Reinforcement calculation ported (territory count / 3 + continent bonuses, minimum 3) | reinforcements.py is 30 lines; MapGraph.controlsContinent already exists in Phase 6 |
| DART-04 | Fortification ported (move armies along connected friendly path) | fortify.py is 68 lines; MapGraph.connectedTerritories BFS already exists |
| DART-05 | Turn FSM ported (reinforce → attack → fortify, player rotation, elimination, victory) | turn.py fully read; FSM logic is explicit; all helper functions catalogued |
| DART-06 | Blitz attack mode (auto-resolve until conquest or attacker depleted) | execute_blitz loop is ~30 lines; loop exit conditions are clear |
</phase_requirements>

---

## Summary

Phase 7 is a pure algorithmic translation of six Python modules into Dart. The game rules are fully specified and working in Python — this is not a design problem but a translation problem. All six Python source files have been read and analyzed. The translation surface is well-defined: ~400 lines of Python engine logic becomes ~400 lines of Dart engine logic using the `copyWith` immutable pattern (already established in Phase 6 via freezed).

The critical non-obvious challenge in this phase is the **golden-fixture test strategy**. Dart's `dart:math.Random` uses a different algorithm than Python's Mersenne Twister, so fixtures cannot replay random draws. Fixtures must instead capture output states: given a deterministic (non-random) game state as input, what is the expected output state? For statistical validation (DART-01 combat accuracy), the Dart engine's own seeded `Random` is used against itself — 10,000 trials showing the same distribution as the mathematical expectation, not matching Python's specific seeds.

The Phase 6 foundation is complete: all freezed models (`GameState`, `TerritoryState`, `PlayerState`, `Card`, `TurnPhase`, `MapData`) and `MapGraph` with BFS are in place and tested. Phase 7 adds only the game logic layer on top of these models. No additional packages are needed.

**Primary recommendation:** Port each Python module 1:1 into a corresponding Dart file in `mobile/lib/engine/`. Use constructor-call immutable updates instead of Python's `model_copy()`. Inject `Random` via parameter for testability. Write golden fixtures by constructing deterministic game states manually (no RNG), then asserting the exact output state.

---

## Standard Stack

### Core (all already in pubspec.yaml from Phase 6 — NO new packages needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `freezed_annotation` | ^3.0.0 | `copyWith` on all state objects | Already in pubspec; replaces Python `model_copy()` |
| `dart:math` | bundled | `Random` class for dice rolling | Standard library; injected via constructor for testability |
| `dart:collection` | bundled | `Queue` for BFS in fortify path validation | Already used in MapGraph |
| `flutter_test` | SDK | Test runner for `flutter test` | Required because tests import engine via `package:risk_mobile` |
| `mocktail` | ^1.0.4 | Mock `PlayerAgent` in turn FSM tests | Already in dev_dependencies |

### No New Packages Required

The entire Phase 7 implementation uses only what Phase 6 already installed. All engine files must have zero Flutter imports — they are pure Dart.

---

## Architecture Patterns

### Recommended Project Structure for New Files

```
mobile/lib/engine/
├── models/               # DONE in Phase 6 — do not modify
│   ├── game_state.dart
│   ├── cards.dart
│   └── map_schema.dart
├── map_graph.dart        # DONE in Phase 6 — do not modify
├── actions.dart          # NEW: AttackAction, BlitzAction, FortifyAction,
│                         #      ReinforcePlacementAction, TradeCardsAction
├── combat.dart           # NEW: resolveCombat, validateAttack, executeAttack, executeBlitz
├── cards_engine.dart     # NEW: isValidSet, createDeck, drawCard, executeTrade, getTradeBonus
│                         #      (NOTE: named cards_engine.dart to avoid collision with
│                         #       models/cards.dart which already holds Card/CardType)
├── reinforcements.dart   # NEW: calculateReinforcements
├── fortify.dart          # NEW: validateFortify, executeFortify
├── setup.dart            # NEW: setupGame, STARTING_ARMIES const
└── turn.dart             # NEW: executeTurn, executeReinforcePhase, executeAttackPhase,
                          #      executeFortifyPhase, checkVictory, checkElimination,
                          #      transferCards, forceTradeLoop, nextAlivePlayer

mobile/test/
├── engine/
│   ├── models_test.dart         # DONE in Phase 6
│   ├── map_graph_test.dart      # DONE in Phase 6
│   ├── combat_test.dart         # NEW
│   ├── cards_engine_test.dart   # NEW
│   ├── reinforcements_test.dart # NEW
│   ├── fortify_test.dart        # NEW
│   ├── setup_test.dart          # NEW
│   ├── turn_test.dart           # NEW
│   └── fixtures/
│       ├── golden_combat.json       # NEW: golden output states
│       ├── golden_fortify.json      # NEW
│       ├── golden_reinforcements.json # NEW
│       └── golden_turn_sequence.json  # NEW

scripts/
└── generate_golden_fixtures.py  # NEW: Python script run once to emit fixtures
```

### Pattern 1: Python `model_copy()` → Dart `copyWith()`

The entire Python engine uses `state.model_copy(update={...})`. The Dart equivalent is `state.copyWith(...)`. This is a 1:1 mechanical translation.

**Python:**
```python
new_state = state.model_copy(update={"territories": new_territories, "conqueredThisTurn": True})
```

**Dart:**
```dart
// Source: mobile/lib/engine/models/game_state.dart (generated copyWith)
final newState = state.copyWith(
  territories: newTerritories,
  conqueredThisTurn: true,
);
```

### Pattern 2: Python `dict(state.territories)` → Dart `Map.of(state.territories)`

Python engine always does `new_territories = dict(state.territories)` then mutates then assigns. Dart equivalent:

**Python:**
```python
new_territories = dict(state.territories)
new_territories[action.source] = TerritoryState(owner=source_ts.owner, armies=new_source_armies)
new_state = state.model_copy(update={"territories": new_territories})
```

**Dart:**
```dart
final newTerritories = Map<String, TerritoryState>.of(state.territories);
newTerritories[action.source] = TerritoryState(
  owner: sourceTerr.owner,
  armies: newSourceArmies,
);
final newState = state.copyWith(territories: newTerritories);
```

### Pattern 3: Python `dict[int, list[Card]]` → Dart `Map<String, List<Card>>`

**Critical:** The Dart `GameState` model established in Phase 6 uses `Map<String, List<Card>> cards` with STRING keys (JSON map keys must be strings). Python uses `dict[int, list[Card]]` with integer keys. All Dart card lookups must use `playerIndex.toString()` as the key.

**Python:**
```python
hand = list(state.cards.get(player_index, []))
```

**Dart:**
```dart
final hand = List<Card>.of(state.cards[playerIndex.toString()] ?? []);
```

This applies throughout `cards_engine.dart` and `turn.dart`. This is a known decision from Phase 6 (recorded in STATE.md).

### Pattern 4: Injected `Random` for Testability

Every function that uses randomness takes a `Random rng` parameter — never creates its own. This is the direct translation of Python's `rng: random.Random` parameter convention already in the Python source.

```dart
// combat.dart
CombatResult resolveCombat(int attackerDice, int defenderDice, Random rng) {
  final attackerRolls = List.generate(attackerDice, (_) => rng.nextInt(6) + 1)
    ..sort((a, b) => b.compareTo(a));
  final defenderRolls = List.generate(defenderDice, (_) => rng.nextInt(6) + 1)
    ..sort((a, b) => b.compareTo(a));
  // ... zip and compare
}
```

### Pattern 5: Return Tuples as Records (Dart 3.x)

Python engine functions return tuples: `tuple[GameState, CombatResult, bool]`. Dart 3.x records provide the same syntax:

```dart
// Returns (newState, result, conquered)
(GameState, CombatResult, bool) executeAttack(
  GameState state,
  MapGraph mapGraph,
  AttackAction action,
  int playerIndex,
  Random rng, {
  int? defenderDice,
  int? armiesToMove,
}) { ... }
```

Records are a Dart 3.x feature — verified available since Dart 3.0 (2023). The project uses `sdk: ">=3.7.0"` (Phase 6 pubspec), so records are available.

### Pattern 6: Abstract `PlayerAgent` Class (replaces Python duck-typed protocol)

Python uses structural duck-typing; Dart needs explicit abstract class:

```dart
// mobile/lib/bots/player_agent.dart (Phase 7 creates the interface;
// actual bot implementations come in Phase 8)
abstract class PlayerAgent {
  ReinforcePlacementAction chooseReinforcementPlacement(GameState state, int armies);
  dynamic chooseAttack(GameState state); // AttackAction? | BlitzAction? | null
  FortifyAction? chooseFortify(GameState state);
  TradeCardsAction? chooseCardTrade(GameState state, List<Card> hand, {required bool forced});
  int chooseAdvanceArmies(GameState state, String source, String target, int min, int max);
}
```

**Note:** `chooseAttack` can return either `AttackAction`, `BlitzAction`, or `null` in Python. In Dart, define a sealed class `AttackChoice` with `AttackAction extends AttackChoice`, `BlitzAction extends AttackChoice` — then turn.dart can `switch` on the type cleanly.

### Pattern 7: `~/` for Integer Division

Python `//` floor-division maps to Dart `~/`. This is the single most common silent drift bug.

**Python:**
```python
base = max(len(player_territories) // 3, 3)
```

**Dart:**
```dart
final base = max(playerTerritories.length ~/ 3, 3);
```

**Never use `/` for integer division in the engine** — it returns `double` in Dart and will fail the type checker if assigned to `int`, but can silently produce wrong results if truncated with `.toInt()` in edge cases.

### Anti-Patterns to Avoid

- **Using `rng.nextInt(6)` as 0-5 and forgetting +1:** Python `rng.randint(1, 6)` is inclusive both ends → `rng.nextInt(6) + 1` in Dart (nextInt is exclusive upper bound)
- **Sorting ascending then reversing:** Python `sorted(..., reverse=True)` = descending. Use `..sort((a, b) => b.compareTo(a))` not `..sort()` (which is ascending)
- **Using `/` instead of `~/`:** Python `//` floor-divides integers; Dart `/` returns `double`
- **Integer keys in cards map:** Python uses `int` keys in `dict[int, list[Card]]`; Dart model uses `String` keys. Forgetting `.toString()` silently creates duplicate entries
- **Mutating freezed objects:** Dart freezed objects are const; `copyWith` always returns new instances — never try to assign fields directly
- **Importing Flutter in engine files:** All `mobile/lib/engine/` files must have zero Flutter imports. Verified by `grep -r "import 'package:flutter" lib/engine/` as part of CI sanity check

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BFS for fortify path validation | Custom graph traversal | `MapGraph.connectedTerritories()` (Phase 6) | Already implemented, tested, handles all edge cases |
| JSON serialization of GameState | Manual `toMap()` | `state.toJson()` (freezed-generated) | Generated by json_serializable; handles nested types, List, Map |
| Deep equality on game state | Custom `==` override | `@freezed` generated `==` | freezed generates structural equality recursively |
| Deck shuffling | Fisher-Yates implementation | `list.shuffle(rng)` (Dart stdlib) | Dart's `List.shuffle(Random)` is correct and injected |

**Key insight:** The engine functions are pure functions — the only "framework" they need is Dart's standard library. Everything complex is already handled by Phase 6 foundations.

---

## Golden-Fixture Test Strategy

This is the most architecturally important aspect of Phase 7. The goal is to catch Python/Dart logic drift before any UI is built.

### Why Standard Seeded-RNG Replay Does Not Work

Python's `random.Random(seed)` uses the Mersenne Twister PRNG. Dart's `dart:math.Random(seed)` uses a different algorithm. Same seed produces completely different sequences. Therefore: **fixtures cannot attempt to replay the same dice rolls as Python.** They must instead capture final state.

### Golden Fixture Approach: Deterministic Inputs → Known Outputs

The insight is that most game rules are **deterministic given the inputs**. Only combat involves RNG. Construct fixtures where the outcome is mathematically forced or where the RNG path doesn't matter:

**Type 1: Zero-RNG fixtures (most rules)**
- Reinforcement calculation: given territory count and continent ownership, calculate armies → no RNG involved
- Card trading: given hand state and trade count, compute bonus → no RNG
- Fortify validation: given map and territory ownership, validate move → no RNG
- Card draw: given known deck state, draw top card → no RNG (just list pop)
- Victory/elimination check: given territory ownership, detect winner → no RNG

**Type 2: Forced-outcome combat fixtures**
- Construct states where attacker has overwhelming advantage (e.g., 20 armies vs 1) with the guarantee that any single roll must result in conquest
- Example: attacker rolls at least 1 with 3 dice vs defender with 1 army — mathematically the defender MUST lose 1 army per round until 0 (because defender has 1 army and rolls 1 die; attacker needs only 1 die > defender's die at some point). **Actually this is probabilistic, not guaranteed.** Use a different approach: provide both input state AND injected dice values.

**Type 3: Controlled-dice fixtures using fake RNG**
The cleanest approach: create a `FakeRandom` that returns a pre-specified sequence of values. The Python script generates the fixture by recording what a real seeded Python Random produces, then the Dart test uses a `FakeRandom` that returns those same values. This bypasses the PRNG difference.

**Recommended fixture format (JSON):**

```json
{
  "id": "combat_3v2_attacker_wins",
  "description": "3 dice vs 2 dice where attacker rolls [6,5,4] defender rolls [3,2]",
  "input_state": { "territories": { "A": {"owner": 0, "armies": 5}, "B": {"owner": 1, "armies": 3} }, "players": [...], ... },
  "attack_action": { "source": "A", "target": "B", "num_dice": 3 },
  "injected_rolls": [6, 5, 4, 3, 2],
  "expected_attacker_losses": 0,
  "expected_defender_losses": 2,
  "expected_conquered": false,
  "expected_output_state": { "territories": { "A": {"owner": 0, "armies": 5}, "B": {"owner": 1, "armies": 1} }, ... }
}
```

### Fixture Generation Script

Write `scripts/generate_golden_fixtures.py` that:
1. Imports Python engine directly
2. Constructs specific game states by hand (no `setup_game` RNG)
3. Runs engine functions with controlled inputs
4. Serializes input + output states to JSON using Pydantic's `.model_dump()`
5. Writes to `mobile/test/engine/fixtures/`

The script is run once before implementing the Dart engine. Fixtures are checked into git. The Dart tests load them as JSON and assert exact equality.

### FakeRandom Pattern for Dart Tests

```dart
// test/helpers/fake_random.dart
import 'dart:math';

/// Returns pre-specified integers in sequence. Throws when exhausted.
class FakeRandom implements Random {
  final List<int> _values;
  int _index = 0;

  FakeRandom(List<int> values) : _values = values;

  @override
  int nextInt(int max) {
    if (_index >= _values.length) throw StateError('FakeRandom exhausted');
    // _values contains raw die faces (1-6); caller does nextInt(6)+1
    // Return value-1 so that nextInt(6)+1 == value
    return _values[_index++] - 1;
  }

  @override
  double nextDouble() => throw UnimplementedError();
  @override
  bool nextBool() => throw UnimplementedError();
}
```

### Statistical Validation (DART-01: combat accuracy within 0.5% over 10k trials)

This does NOT compare against Python. It validates mathematical correctness:
- With 3 dice vs 2 dice: theoretical probability attacker wins both = 37.17%, split = 33.58%, defender wins both = 29.26% (known from Risk probability tables)
- Run 10,000 trials with Dart's seeded `Random(42)` and assert each outcome frequency is within 0.5% of theoretical

This validates the dice pairing and comparison logic is correct without any Python comparison.

---

## Common Pitfalls

### Pitfall 1: `rng.nextInt(6)` is 0–5, Python `randint(1,6)` is 1–6

**What goes wrong:** `nextInt(6)` returns 0–5. Forgetting `+1` means dice never show 6, breaking all probability distributions.
**Why it happens:** Different API conventions between Python `random.randint(a, b)` (inclusive both) and Dart `nextInt(max)` (exclusive upper bound).
**How to avoid:** Always write `rng.nextInt(6) + 1` for dice rolls. Code-review every `nextInt(6)` call.
**Warning signs:** Statistical tests show attacker wins slightly more than expected (6 is missing from defender, reducing tied/defender-wins rate).

### Pitfall 2: Forgetting `~/` vs `/` for Integer Division

**What goes wrong:** Reinforcement calculation `territories ~/ 3` gives correct integer; if mistakenly written as `territories / 3` it returns `double` — either type error or silent `.toInt()` truncation.
**Why it happens:** Python `//` always floors to int; Dart `/` returns double; Dart `~/` truncates to int.
**How to avoid:** Search for `/` in engine files and verify none are integer division.
**Warning signs:** Reinforcement counts occasionally off by 1 at boundaries (e.g., 11 territories → should be 3, but `11 / 3 = 3.666...` truncated = 3 is correct here, but 12 territories → `12 / 3 = 4.0.toInt() = 4` works, while `14 / 3 = 4.666.toInt() = 4` = correct — but edge cases at exact multiples may surface).

### Pitfall 3: String Keys in Cards Map vs Python Int Keys

**What goes wrong:** Python `state.cards[player_index]` where `player_index` is `int`. Dart `state.cards[playerIndex]` where the map has `String` keys → returns `null` silently, treating all players as having empty hands.
**Why it happens:** JSON map keys are always strings; Phase 6 established `Map<String, List<Card>>` specifically for this reason.
**How to avoid:** Always use `state.cards[playerIndex.toString()]`. Add a test asserting card draw correctly keys by string index.
**Warning signs:** Players never trigger forced-trade logic (cards always appear empty), card counts never grow.

### Pitfall 4: Dice Sort Direction

**What goes wrong:** Python `sorted([...], reverse=True)` sorts descending. If Dart uses `..sort()` (ascending) the dice are paired lowest-first, inverting the probability distribution entirely.
**Why it happens:** `List.sort()` in Dart is ascending by default.
**How to avoid:** Use `..sort((a, b) => b.compareTo(a))` for descending. Test with a known ordered roll.
**Warning signs:** Statistical test shows much higher defender win rate than expected.

### Pitfall 5: `_continentBonuses` is Private in MapGraph

**What goes wrong:** Python `reinforcements.py` line 26 accesses `map_graph._continent_bonuses` directly. In Dart, the MapGraph field is `_continentBonuses` (private). Engine code cannot access it.
**Why it happens:** Python doesn't enforce privacy on `_` names; Dart does (library-private).
**How to avoid:** `MapGraph` needs to expose a `continentNames` getter (list of all continent names) so `calculateReinforcements` can iterate. Phase 6 MapGraph already has `continentBonus(String)` and `controlsContinent(String, Set<String>)` — only the list of continent names is missing.
**Fix:** Add `List<String> get continentNames => _continentBonuses.keys.toList();` to MapGraph. This is a minor Phase 6 augmentation needed by Phase 7.
**Warning signs:** `calculateReinforcements` always returns base with no continent bonus (bonus loop never executes because no way to iterate continents).

### Pitfall 6: `chooseAttack` Return Type Ambiguity

**What goes wrong:** Python `choose_attack` can return `AttackAction`, `BlitzAction`, or `None`. Dart's type system requires a concrete type. Using `dynamic` bypasses type safety and makes `instanceof` checks verbose.
**Why it happens:** Python duck-typing; Dart nominal typing.
**How to avoid:** Define a sealed class hierarchy in `actions.dart`:
```dart
sealed class AttackChoice {}
class AttackAction extends AttackChoice { ... }
class BlitzAction extends AttackChoice { ... }
```
Then `PlayerAgent.chooseAttack()` returns `AttackChoice?`. Turn engine switches exhaustively:
```dart
final choice = agent.chooseAttack(state);
if (choice == null) break;
switch (choice) {
  case AttackAction a: ...
  case BlitzAction b: ...
}
```
**Warning signs:** Runtime type errors when processing attack choices, or blitz mode silently ignored.

### Pitfall 7: Card Recycling Logic in `executeTrade`

**What goes wrong:** Python `execute_trade` only recycles traded cards back into the deck when the deck is EMPTY (`if len(new_deck) == 0`). This is an unusual rule — forgetting this and always recycling causes the deck to grow unboundedly, inflating card-draw frequency.
**How to avoid:** Verify the Dart port of `execute_trade` has this exact condition: only prepend traded cards if deck is empty.
**Warning signs:** Late-game players accumulate cards faster than expected; deck never empties.

### Pitfall 8: Advance Armies Logic in Turn.dart

**What goes wrong:** The advance armies logic in `execute_attack_phase` (Python turn.py lines 210–252) is the most complex section. After conquest, the `already_moved` armies are the `num_dice` used (or the blitz default), and the delta adjustment re-balances source/target. Getting `min_armies`, `max_armies`, or the delta sign wrong produces invalid army counts.
**How to avoid:** Translate this section with extra care. Write a dedicated test that exercises:
  - Standard attack: advance exactly `num_dice`, more than `num_dice`, maximum allowed
  - Blitz attack: advance minimum, advance maximum
  - Assert source always >= 1 after advance
**Warning signs:** Negative army counts in territories, or source drops to 0 after conquest.

---

## Code Examples

### Combat Resolution (verified against combat.py)

```dart
// mobile/lib/engine/combat.dart

import 'dart:math';
import 'models/game_state.dart';
import 'actions.dart';

class CombatResult {
  final int attackerLosses;
  final int defenderLosses;
  const CombatResult({required this.attackerLosses, required this.defenderLosses});
}

CombatResult resolveCombat(int attackerDice, int defenderDice, Random rng) {
  // Generate and sort descending (Python: sorted(..., reverse=True))
  final attackerRolls = List.generate(attackerDice, (_) => rng.nextInt(6) + 1)
    ..sort((a, b) => b.compareTo(a));
  final defenderRolls = List.generate(defenderDice, (_) => rng.nextInt(6) + 1)
    ..sort((a, b) => b.compareTo(a));

  int attackerLosses = 0;
  int defenderLosses = 0;

  // Pair highest-first; ties go to defender
  final pairs = attackerRolls.length < defenderRolls.length
      ? attackerRolls.length
      : defenderRolls.length;
  for (int i = 0; i < pairs; i++) {
    if (attackerRolls[i] > defenderRolls[i]) {
      defenderLosses++;
    } else {
      attackerLosses++; // tie or defender higher -> attacker loses
    }
  }
  return CombatResult(attackerLosses: attackerLosses, defenderLosses: defenderLosses);
}
```

### Reinforcement Calculation (verified against reinforcements.py)

```dart
// mobile/lib/engine/reinforcements.dart

import 'dart:math';
import 'map_graph.dart';
import 'models/game_state.dart';

int calculateReinforcements(GameState state, MapGraph mapGraph, int playerIndex) {
  final playerTerritories = state.territories.entries
      .where((e) => e.value.owner == playerIndex)
      .map((e) => e.key)
      .toSet();

  // Base: territory count ~/ 3, minimum 3
  final base = max(playerTerritories.length ~/ 3, 3);

  // Continent bonuses
  int bonus = 0;
  for (final continent in mapGraph.continentNames) {   // needs continentNames getter
    if (mapGraph.controlsContinent(continent, playerTerritories)) {
      bonus += mapGraph.continentBonus(continent);
    }
  }
  return base + bonus;
}
```

### Card Trade Escalation Table (verified against cards.py)

```dart
// mobile/lib/engine/cards_engine.dart

const List<int> _escalationSequence = [4, 6, 8, 10, 12, 15];

int getTradeBonus(int tradeCount) {
  if (tradeCount < _escalationSequence.length) {
    return _escalationSequence[tradeCount];
  }
  return 15 + 5 * (tradeCount - _escalationSequence.length + 1);
}
```

### Set Validation (verified against cards.py)

```dart
bool isValidSet(List<Card> cards) {
  if (cards.length != 3) return false;

  final wildCount = cards.where((c) => c.cardType == CardType.wild).length;
  if (wildCount >= 1) return true; // any wild makes it valid

  // No wilds: 3 matching or one of each
  final types = cards.map((c) => c.cardType).toSet();
  return types.length == 1 || types.length == 3;
}
```

### Starting Armies Lookup (verified against setup.py)

```dart
const Map<int, int> startingArmies = {2: 40, 3: 35, 4: 30, 5: 25, 6: 20};
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Python generator returns tuples via `tuple[A, B, C]` | Dart records `(A, B, C)` | Dart 3.0 (May 2023) | Clean multi-return without wrapper classes |
| `Map<int, List<Card>>` (Python) | `Map<String, List<Card>>` (Dart/JSON) | Phase 6 decision | String keys required for JSON round-trip |
| Python abstract base class (Protocol) | Dart `abstract class PlayerAgent` | N/A | Dart uses nominal types, not structural |
| Python `model_copy(update=...)` (Pydantic) | Dart `.copyWith(...)` (freezed) | Phase 6 | 1:1 equivalent, generated for free |

---

## Open Questions

1. **`MapGraph.continentNames` getter not in Phase 6 implementation**
   - What we know: Phase 6 `MapGraph` has `continentBonus(name)` and `controlsContinent(name, set)` but no way to get all continent names (the `_continentBonuses` map is private)
   - What's unclear: Whether to add this in Phase 7 (as a minor augmentation) or create a separate task
   - Recommendation: Add `List<String> get continentNames => _continentBonuses.keys.toList();` to `MapGraph` as the first task in Phase 7 (it's a 1-line change to a Phase 6 file)

2. **`PlayerAgent` placement in project structure**
   - What we know: Phase 7 needs a `PlayerAgent` abstract class for `turn.dart` to call `agent.chooseAttack()` etc. Phase 8 implements the concrete bots.
   - What's unclear: Whether `player_agent.dart` belongs in `lib/engine/` or `lib/bots/`
   - Recommendation: Create `lib/bots/player_agent.dart` in Phase 7 (abstract interface only, no implementation). The `turn.dart` engine imports it. Phase 8 adds implementations. This matches the Python structure where `bots/` contains the agent protocol.

3. **Golden fixture script: Python environment availability**
   - What we know: The project's Python environment (`risk/` package) is available in the repo
   - What's unclear: Whether a `scripts/` directory exists and how to run the fixture generator as part of the phase workflow
   - Recommendation: Create `scripts/generate_golden_fixtures.py` as part of Phase 7. Run it manually once before implementing the Dart engine. Check generated fixtures into git.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK, already in pubspec.yaml) |
| Config file | none — flutter test auto-discovers `test/` |
| Quick run command | `flutter test test/engine/ --reporter compact` |
| Full suite command | `flutter test --reporter compact` |
| Run from | `mobile/` directory (with Flutter SDK on PATH) |

**Note:** Flutter SDK is at `/home/amiller/flutter-sdk/flutter/bin/flutter`. Tests use `flutter test` not `dart test` because the package imports `package:risk_mobile` which requires Flutter's build system.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DART-01 | Dice rolling, pair highest-first, ties to defender | unit + statistical | `flutter test test/engine/combat_test.dart` | Wave 0 |
| DART-01 | Combat stats match math within 0.5% over 10k trials | statistical | `flutter test test/engine/combat_test.dart -n "statistical"` | Wave 0 |
| DART-02 | Card set validation (3 matching, one-of-each, wilds) | unit | `flutter test test/engine/cards_engine_test.dart` | Wave 0 |
| DART-02 | Deck creation (42 territory + 2 wild, cycling types) | unit | `flutter test test/engine/cards_engine_test.dart` | Wave 0 |
| DART-02 | Trade escalation sequence matches Python constants | golden | `flutter test test/engine/cards_engine_test.dart -n "golden"` | Wave 0 |
| DART-02 | Forced trade at 5+ cards | unit | `flutter test test/engine/turn_test.dart -n "forced_trade"` | Wave 0 |
| DART-03 | Reinforcement calculation (territory/3, min 3, continent bonus) | unit + golden | `flutter test test/engine/reinforcements_test.dart` | Wave 0 |
| DART-04 | Fortify validates connected friendly path via BFS | unit | `flutter test test/engine/fortify_test.dart` | Wave 0 |
| DART-04 | Fortify execution moves armies correctly | unit + golden | `flutter test test/engine/fortify_test.dart` | Wave 0 |
| DART-05 | Turn FSM: reinforce → attack → fortify phases cycle | unit | `flutter test test/engine/turn_test.dart -n "fsm"` | Wave 0 |
| DART-05 | Elimination: player marked dead, cards transferred | unit | `flutter test test/engine/turn_test.dart -n "elimination"` | Wave 0 |
| DART-05 | Victory: single owner detected | unit | `flutter test test/engine/turn_test.dart -n "victory"` | Wave 0 |
| DART-05 | Player rotation skips eliminated players | unit | `flutter test test/engine/turn_test.dart -n "rotation"` | Wave 0 |
| DART-06 | Blitz loops until conquest or attacker has 1 army | unit | `flutter test test/engine/combat_test.dart -n "blitz"` | Wave 0 |
| DART-06 | Blitz conquest leaves minimum legal army count | unit | `flutter test test/engine/combat_test.dart -n "blitz_min"` | Wave 0 |
| ALL | Golden fixture output states match Python | golden | `flutter test test/engine/ -n "golden"` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/engine/ --reporter compact`
- **Per wave merge:** `flutter test --reporter compact`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps (files to create before implementation)

- [ ] `mobile/test/engine/combat_test.dart` — covers DART-01, DART-06
- [ ] `mobile/test/engine/cards_engine_test.dart` — covers DART-02
- [ ] `mobile/test/engine/reinforcements_test.dart` — covers DART-03
- [ ] `mobile/test/engine/fortify_test.dart` — covers DART-04
- [ ] `mobile/test/engine/setup_test.dart` — covers setup_game (supporting)
- [ ] `mobile/test/engine/turn_test.dart` — covers DART-05
- [ ] `mobile/test/engine/fixtures/` directory — golden fixture JSON files
- [ ] `mobile/test/helpers/fake_random.dart` — FakeRandom for controlled-dice tests
- [ ] `scripts/generate_golden_fixtures.py` — Python script to emit fixture JSON

---

## Sources

### Primary (HIGH confidence)

- Python source files read directly: `risk/engine/combat.py`, `risk/engine/cards.py`, `risk/engine/reinforcements.py`, `risk/engine/fortify.py`, `risk/engine/setup.py`, `risk/engine/turn.py` — authoritative source of truth for all rules
- Phase 6 files read directly: `mobile/lib/engine/models/game_state.dart`, `cards.dart`, `map_schema.dart`, `map_graph.dart` — established data contracts
- `mobile/pubspec.yaml` — confirmed `sdk: ">=3.7.0"` (Dart 3.7 supports records and sealed classes)
- `.planning/STATE.md` — confirmed string-key decision for cards map
- `.planning/phases/06-flutter-scaffold-and-data-models/06-02-SUMMARY.md` — confirmed all Phase 6 deliverables

### Secondary (MEDIUM confidence)

- [Dart Records documentation](https://dart.dev/language/records) — confirmed syntax for multi-return tuples in Dart 3.x
- [Dart Sealed Classes](https://dart.dev/language/class-modifiers#sealed) — confirmed pattern for AttackChoice sealed hierarchy
- [dart:math Random API](https://api.dart.dev/dart-math/Random-class.html) — confirmed `nextInt(max)` is exclusive upper bound

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in Phase 6 pubspec; no new packages needed
- Architecture: HIGH — Python source fully read; all 6 modules analyzed; translation patterns are mechanical
- Pitfalls: HIGH — identified from direct source analysis (not speculation); critical string-key pitfall confirmed by Phase 6 STATE.md

**Research date:** 2026-03-15
**Valid until:** 2026-06-15 (stable — Dart 3.x APIs, freezed patterns, and game rules don't change)
