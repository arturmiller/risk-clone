# Phase 6: Flutter Scaffold and Data Models - Research

**Researched:** 2026-03-14
**Domain:** Flutter project setup, @freezed code generation, ObjectBox persistence, Riverpod scaffolding, Dart BFS graph
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None — user granted full discretion on all infrastructure decisions.

### Claude's Discretion
- **Project structure**: Feature-first folder layout (engine/, models/, providers/, widgets/, screens/) with pure Dart engine layer having zero Flutter imports
- **Map data format**: Reuse classic.json structure from Python project, bundled as Flutter asset. Territory paths for rendering can be added separately when needed in Phase 10
- **Model design**: Mirror Python Pydantic models closely with @freezed (GameState, TerritoryState, PlayerState, Card, TurnPhase enum). Use copyWith as direct replacement for model_copy. Keep same field names for consistency
- **Graph implementation**: Manual adjacency Map<String, Set<String>> with BFS — no external graph library needed (~60 lines)
- **Persistence setup**: ObjectBox configured with a simple GameState JSON blob entity for save/resume
- **State management**: Riverpod providers scaffolded but minimal — just enough to verify the dependency works
- **Testing**: Pure Dart unit tests for models and map graph, runnable without Flutter simulator

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DART-07 | Map graph with BFS connectivity queries (adjacency, connected territories, continent control) | MapGraph implementation pattern from Python port; BFS in pure Dart without NetworkX; see Graph Implementation section |
</phase_requirements>

---

## Summary

This phase creates the zero-dependency Flutter foundation: a compiling project with all data models, the map graph, ObjectBox persistence, and minimal Riverpod scaffolding. No user-facing features are delivered — the goal is a stable base every subsequent phase can build on without restructuring.

The technical work is well-understood translation from the existing Python codebase. Python's Pydantic `BaseModel` maps 1:1 to Dart's `@freezed` classes. Python's NetworkX `MapGraph` maps to ~65 lines of pure Dart using `Map<String, Set<String>>` adjacency and manual BFS. Python's `classic.json` is used verbatim as a Flutter asset with no changes to the data format.

The primary setup risk is getting the code generation toolchain (build_runner + freezed + json_serializable + objectbox_generator) configured correctly on the first try. Version mismatches between these tools are the most common cause of stalled scaffold phases. This research documents the exact versions and pubspec.yaml structure to use.

**Primary recommendation:** Run `flutter pub get` and a full `dart run build_runner build --delete-conflicting-outputs` before writing any model code to confirm code generation works end-to-end, then proceed model by model.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | ^3.41.x (stable) | Cross-platform mobile framework | Current stable (Feb 2026); bundles Dart 3.11 |
| flutter_riverpod | ^3.3.1 | State management scaffolding | Chosen in project research; minimal scaffolding only in this phase |
| riverpod_annotation | ^4.0.2 | @riverpod code gen macro | Required companion — note: version is 4.x not 3.x |
| freezed | ^3.2.5 | Immutable model code generation | Direct equivalent of Pydantic model_copy; generates copyWith, equality, JSON |
| freezed_annotation | ^3.0.0 | Runtime annotations for freezed | Required at runtime (not dev-only) |
| json_serializable | ^6.13.0 | JSON fromJson/toJson generation | Required for ObjectBox JSON blob persistence |
| json_annotation | ^4.9.0 | Runtime annotations for json_serializable | Required at runtime |
| objectbox | ^5.2.0 | Save-game persistence | Actively maintained; Android + iOS; stores GameState as JSON string |
| objectbox_flutter_libs | any | Native ObjectBox binaries for mobile | Required companion; use `any` not a version pin |
| shared_preferences | ^2.5.4 | App settings | For non-critical key-value settings (difficulty preference, etc.) |

### Dev Dependencies

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| build_runner | ^2.4.0 | Runs all code generators | Required: freezed, json_serializable, riverpod_generator, objectbox_generator |
| riverpod_generator | ^4.0.3 | @riverpod macro processor | Required companion to riverpod_annotation |
| freezed | ^3.2.5 | freezed code generator | Listed in both deps and dev_deps (annotation at runtime, generator at dev) |
| json_serializable | ^6.13.0 | json_serializable generator | Dev only — annotation is in runtime deps |
| objectbox_generator | any | ObjectBox entity code generator | Dev only; use `any` not a version pin |
| mocktail | ^1.0.4 | Mocking in unit tests | No code gen needed, unlike mockito |
| flutter_test | SDK | Widget and unit tests | Bundled with Flutter SDK |

### Version Compatibility Matrix

| Pair | Constraint | Consequence of Mismatch |
|------|-----------|------------------------|
| riverpod_annotation ^4.0.2 + riverpod_generator ^4.0.3 | Must match major (4.x) | Generator won't recognize annotations |
| flutter_riverpod ^3.3.1 | Requires riverpod 3.2.1 transitively | Resolved automatically by pub |
| freezed ^3.2.5 + freezed_annotation ^3.0.0 | Must match major (3.x) | Runtime annotation mismatch |
| objectbox ^5.2.0 + objectbox_flutter_libs any | objectbox_flutter_libs fetches matching native lib | Mismatched native version = runtime crash |
| freezed ^3.2.5 + json_serializable ^6.13.0 | analyzer version overlap required | freezed 3.2.3+ needs analyzer >=7.5.9 <9.0.0; json_serializable 6.11.3+ needs analyzer ^9.0.0. Use freezed ^3.2.5 and json_serializable ^6.13.0 which are compatible |

**CRITICAL NOTE on riverpod_generator version:** The project STACK.md documents `riverpod_generator: ^2.6.0` — this is incorrect for Riverpod 3.x. The correct version is `riverpod_generator: ^4.0.3` (published 39 days ago). Using 2.x with Riverpod 3.x annotation will break code generation.

**CRITICAL NOTE on objectbox_flutter_libs:** The project STACK.md documents `objectbox_flutter_libs: path: flutter_libs` (a path dependency). This is incorrect. The current official setup is `objectbox_flutter_libs: any` as a regular pub.dev package. The `dart run objectbox:download-libs` command no longer exists; use `flutter pub add objectbox_flutter_libs:any` instead.

### Installation

```bash
# Create Flutter project (run from repo root)
flutter create --org com.riskgame --project-name risk_mobile mobile

# Add runtime dependencies
cd mobile
flutter pub add flutter_riverpod riverpod_annotation freezed_annotation json_annotation objectbox shared_preferences path_parsing flutter_svg

# Add objectbox_flutter_libs with 'any' version
flutter pub add objectbox_flutter_libs:any

# Add dev dependencies
flutter pub add --dev build_runner riverpod_generator freezed json_serializable objectbox_generator:any mocktail

# Verify setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Full `pubspec.yaml` dependencies section:

```yaml
environment:
  sdk: ">=3.7.0 <4.0.0"
  flutter: ">=3.41.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0
  objectbox: ^5.2.0
  objectbox_flutter_libs: any
  shared_preferences: ^2.5.4
  path_parsing: ^1.1.0    # install now; used for hit-testing in Phase 10
  flutter_svg: ^2.2.4     # install now; used for map rendering in Phase 10

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^4.0.3
  freezed: ^3.2.5
  json_serializable: ^6.13.0
  objectbox_generator: any
  mocktail: ^1.0.4
```

---

## Architecture Patterns

### Recommended Project Structure

```
mobile/                          # Flutter project root (created by flutter create)
├── pubspec.yaml
├── analysis_options.yaml        # Must suppress invalid_annotation_target
├── build.yaml                   # Must set explicit_to_json: true for nested models
├── assets/
│   └── classic.json             # Copied from risk/data/classic.json verbatim
├── lib/
│   ├── main.dart                # runApp(ProviderScope(child: RiskApp()))
│   ├── app.dart                 # MaterialApp
│   │
│   ├── engine/                  # Pure Dart — zero Flutter imports enforced
│   │   ├── models/
│   │   │   ├── game_state.dart  # @freezed GameState, TerritoryState, PlayerState
│   │   │   ├── cards.dart       # @freezed Card, CardType enum, TurnPhase enum
│   │   │   ├── actions.dart     # @freezed AttackAction, FortifyAction, etc.
│   │   │   └── map_schema.dart  # @freezed MapData, ContinentData
│   │   └── map_graph.dart       # MapGraph: adjacency Map, BFS, continent queries
│   │
│   ├── providers/               # Riverpod providers (minimal scaffolding this phase)
│   │   └── map_provider.dart    # mapGraphProvider (loaded once from assets)
│   │
│   ├── persistence/             # ObjectBox store and entities
│   │   ├── app_store.dart       # ObjectBox store initialization
│   │   └── save_slot.dart       # @Entity SaveSlot with JSON blob
│   │
│   └── screens/                 # Placeholder screens (Phase 11 fills these)
│       └── home_screen.dart     # Minimal MaterialApp home
│
└── test/
    ├── engine/
    │   ├── map_graph_test.dart   # Port of tests/test_map_graph.py — all 12 cases
    │   └── models_test.dart      # copyWith, equality, JSON round-trip
    └── persistence/
        └── save_slot_test.dart   # ObjectBox write/read round-trip
```

### Pattern 1: @freezed Model Definition

**What:** Each Pydantic model becomes a `@freezed` class with `@JsonSerializable`. The `part` directives are mandatory. Field names match Python exactly for golden fixture compatibility in Phase 7.

**When to use:** All game state models: GameState, TerritoryState, PlayerState, Card, AttackAction, FortifyAction, etc.

**Example — direct port of Python TerritoryState:**

```dart
// Source: freezed pub.dev official README + Python game_state.py
// lib/engine/models/game_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
class TerritoryState with _$TerritoryState {
  const factory TerritoryState({
    required int owner,
    required int armies,
  }) = _TerritoryState;

  factory TerritoryState.fromJson(Map<String, dynamic> json) =>
      _$TerritoryStateFromJson(json);
}

@freezed
class PlayerState with _$PlayerState {
  const factory PlayerState({
    required int index,
    required String name,
    @Default(true) bool isAlive,
  }) = _PlayerState;

  factory PlayerState.fromJson(Map<String, dynamic> json) =>
      _$PlayerStateFromJson(json);
}

// GameState has Map<String, TerritoryState> — requires explicitToJson in build.yaml
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

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}
```

**CRITICAL: Field naming for Phase 7 compatibility.** Python uses `snake_case` (e.g., `current_player_index`). Dart convention is `camelCase` (e.g., `currentPlayerIndex`). Use Dart camelCase in the Dart model but add `@JsonKey(name: 'current_player_index')` annotations for JSON compatibility, OR accept that JSON keys will be camelCase in Dart and handle translation in the Phase 7 golden fixture test harness. The CONTEXT.md says "keep same field names for consistency" — interpret as same logical names, adapting case to language convention.

### Pattern 2: MapGraph — Pure Dart BFS (No NetworkX)

**What:** A direct port of Python's `MapGraph` replacing NetworkX with `Map<String, Set<String>>` adjacency and manual BFS. The Python implementation is ~80 lines; the Dart port is approximately the same.

**Python → Dart translation map:**

| Python (NetworkX) | Dart (manual) |
|-------------------|--------------|
| `nx.Graph()` | `Map<String, Set<String>> _adjacency = {}` |
| `graph.add_edges_from(...)` | Iterate adjacencies list, add to both directions |
| `graph.has_edge(t1, t2)` | `_adjacency[t1]?.contains(t2) ?? false` |
| `list(graph.neighbors(t))` | `_adjacency[t]?.toList() ?? []` |
| `nx.node_connected_component(subgraph, start)` | Manual BFS over friendly-only set |

**Example:**

```dart
// lib/engine/map_graph.dart
// Source: direct port of risk/engine/map_graph.py

class MapGraph {
  final Map<String, Set<String>> _adjacency = {};
  final Map<String, String> _continentByTerritory = {};
  final Map<String, Set<String>> _continentTerritories = {};
  final Map<String, int> _continentBonuses = {};

  MapGraph(MapData mapData) {
    // Initialize adjacency for all territories
    for (final t in mapData.territories) {
      _adjacency[t] = {};
    }
    // Add bidirectional edges
    for (final edge in mapData.adjacencies) {
      _adjacency[edge[0]]!.add(edge[1]);
      _adjacency[edge[1]]!.add(edge[0]);
    }
    // Build continent lookups
    for (final continent in mapData.continents) {
      _continentTerritories[continent.name] = Set.from(continent.territories);
      _continentBonuses[continent.name] = continent.bonus;
      for (final t in continent.territories) {
        _continentByTerritory[t] = continent.name;
      }
    }
  }

  List<String> get allTerritories => _adjacency.keys.toList();

  bool areAdjacent(String t1, String t2) =>
      _adjacency[t1]?.contains(t2) ?? false;

  List<String> neighbors(String territory) =>
      _adjacency[territory]?.toList() ?? [];

  /// BFS over friendly-only subgraph — direct port of NetworkX connected_component
  Set<String> connectedTerritories(String start, Set<String> friendly) {
    if (!friendly.contains(start)) return {};
    final visited = <String>{start};
    final queue = Queue<String>()..add(start);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final neighbor in _adjacency[current] ?? <String>{}) {
        if (friendly.contains(neighbor) && !visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
    return visited;
  }

  Set<String> continentTerritories(String continent) =>
      _continentTerritories[continent] ?? {};

  bool controlsContinent(String continent, Set<String> playerTerritories) =>
      continentTerritories(continent).every(playerTerritories.contains);

  int continentBonus(String continent) => _continentBonuses[continent] ?? 0;
}
```

**Import needed:** `import 'dart:collection';` for `Queue`.

### Pattern 3: Asset Loading at Startup

**What:** `classic.json` is declared as a Flutter asset and loaded once at startup via a Riverpod `FutureProvider`. The loaded `MapGraph` is cached in a `Provider` for use throughout the app.

**Example:**

```dart
// lib/providers/map_provider.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_provider.g.dart';

@riverpod
Future<MapGraph> mapGraph(MapGraphRef ref) async {
  final jsonString = await rootBundle.loadString('assets/classic.json');
  final mapData = MapData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  return MapGraph(mapData);
}
```

**In `pubspec.yaml` flutter section:**

```yaml
flutter:
  assets:
    - assets/classic.json
```

### Pattern 4: ObjectBox Entity for Save Slot

**What:** ObjectBox stores game state as a JSON string inside a simple `SaveSlot` entity. This avoids mapping the entire `GameState` tree to ObjectBox properties and lets `json_serializable` handle serialization.

**Example:**

```dart
// lib/persistence/save_slot.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class SaveSlot {
  @Id()
  int id = 0;

  @Property()
  String gameStateJson = '';

  @Property()
  int turnNumber = 0;

  @Property()
  String timestamp = '';
}
```

**ObjectBox store initialization in `main.dart`:**

```dart
// lib/persistence/app_store.dart
import 'package:objectbox/objectbox.dart';
import 'objectbox.g.dart';  // generated by objectbox_generator

late final Store _store;

Future<Store> openStore() async {
  _store = await openStore(directory: 'obx-risk');
  return _store;
}
```

**main.dart pattern:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openStore();
  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
      ],
      child: const RiskApp(),
    ),
  );
}
```

### Pattern 5: Required Configuration Files

**`analysis_options.yaml` (required for freezed + json_serializable):**

```yaml
# analysis_options.yaml — place at Flutter project root
include: package:flutter/analysis_options.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore
```

**`build.yaml` (required for nested model serialization):**

```yaml
# build.yaml — place at Flutter project root next to pubspec.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
```

Without `explicit_to_json: true`, nested `@freezed` objects (like `Map<String, TerritoryState>` inside `GameState`) will serialize as `Map<String, dynamic>` instead of calling `toJson()` recursively. This will silently break ObjectBox round-trip tests.

### Anti-Patterns to Avoid

- **Flutter imports in engine/:** Any `import 'package:flutter/...'` in `lib/engine/` or `lib/bots/` breaks the pure-Dart invariant. This breaks the ability to run engine tests without the Flutter toolchain and complicates Isolate data passing.
- **Version-pinning objectbox_flutter_libs:** The `objectbox_flutter_libs: any` constraint is intentional. Pinning to a specific version can cause native library version mismatches that produce cryptic runtime crashes.
- **Running build_runner without `--delete-conflicting-outputs`:** Stale generated files cause confusing "duplicate class" errors. Always use the flag.
- **Forgetting `part` directives:** A `@freezed` file without the two `part` directives (`.freezed.dart` and `.g.dart`) will silently fail to generate with no clear error message.
- **Putting UIState inside GameState:** See ARCHITECTURE.md — selection state belongs in `UIStateNotifier`, not `GameState`. Even though UIState providers aren't built this phase, the `GameState` model must not include UI fields.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Immutable copyWith | Custom copy constructors | @freezed | Code gen handles all fields including Map/List; handles equality correctly for Riverpod re-render detection |
| JSON serialization | Manual `toJson`/`fromJson` | json_serializable | Map<String, TerritoryState> serialization has edge cases with null safety; code gen handles them |
| ObjectBox entity code | Manual ObjectBox schema | objectbox_generator | Generator produces `objectbox.g.dart` with `openStore()` and box access patterns |
| Riverpod provider boilerplate | Manual `Provider(...)` definitions | @riverpod + riverpod_generator | Eliminates ~20 lines of wiring per provider; enforces correct typing |

**Key insight:** The entire point of this phase is getting the code generation pipeline right. The actual model logic is trivial; the build toolchain configuration is where phase failures happen.

---

## Common Pitfalls

### Pitfall 1: riverpod_generator Version Mismatch (Likely Blocker)

**What goes wrong:** `dart run build_runner build` exits with errors about unrecognized annotations or missing generated class names.

**Why it happens:** The project STACK.md documents `riverpod_generator: ^2.6.0`. Riverpod 3.x requires `riverpod_generator: ^4.0.3`. These are incompatible.

**How to avoid:** Use `riverpod_generator: ^4.0.3` in pubspec.yaml as documented here. Verify with `flutter pub deps | grep riverpod_generator`.

**Warning signs:** Error messages referencing `@riverpod` annotation not recognized; generated file is missing `_$ProviderName` class.

### Pitfall 2: objectbox_flutter_libs Path Dependency (Build Failure)

**What goes wrong:** `flutter pub get` fails with "package not found at flutter_libs path" or platform build fails with missing native library symbol.

**Why it happens:** The project STACK.md documents `objectbox_flutter_libs: path: flutter_libs`. This was a historical approach requiring `dart run objectbox:download-libs` to download native libs to a local path. The current (2026) approach uses the pub.dev package directly with `any` version.

**How to avoid:** Use `objectbox_flutter_libs: any` in pubspec.yaml. No download command needed.

**Warning signs:** pubspec.yaml has `path: flutter_libs`; `flutter pub get` complains about missing path dependency.

### Pitfall 3: Missing explicit_to_json (Silent Data Corruption)

**What goes wrong:** ObjectBox write/read test passes but restored `GameState` has empty `TerritoryState` objects (serialized as `{}` not `{"owner": 1, "armies": 3}`).

**Why it happens:** Without `explicit_to_json: true` in `build.yaml`, `json_serializable` does not call `.toJson()` on nested objects; it converts them with `toString()` which produces unusable output.

**How to avoid:** Add `build.yaml` with `explicit_to_json: true` before running code generation. Catch this early with the ObjectBox round-trip test.

**Warning signs:** `GameState.toJson()` produces `Map<String, dynamic>` where territory values are not Maps; round-trip test fails on `TerritoryState` equality.

### Pitfall 4: Map<int, List<Card>> JSON Serialization

**What goes wrong:** `GameState.fromJson` fails at runtime with `type 'String' is not a subtype of type 'int'` when deserializing the `cards` field.

**Why it happens:** JSON map keys are always strings. `Map<int, List<Card>>` has integer keys in Dart but string keys in JSON. `json_serializable` doesn't automatically convert `"0"` → `0` for map keys without a custom converter.

**How to avoid:** Either (a) change `cards` to `Map<String, List<Card>>` in the Dart model (requires updating all usages), or (b) use a custom `JsonConverter` for the int→string key conversion, or (c) store the entire `GameState` as a JSON blob via `jsonEncode(gameState.toJson())` in the `SaveSlot` without trying to deserialize the `cards` field independently.

**Recommendation:** The simplest fix is changing `cards` to `Map<String, List<Card>>` since JSON doesn't have integer keys. Index with `cards['0']` instead of `cards[0]`.

**Warning signs:** Runtime exception during `GameState.fromJson`; error mentions map key type mismatch.

### Pitfall 5: build_runner Partial Regeneration

**What goes wrong:** After adding a new `@freezed` class, old generated files conflict with new ones. Errors like "class _$GameState is defined multiple times."

**Why it happens:** `build_runner build` without `--delete-conflicting-outputs` leaves stale `.freezed.dart` and `.g.dart` files from previous runs.

**How to avoid:** Always run `dart run build_runner build --delete-conflicting-outputs`. Set this as the standard command in the project README and any CI scripts.

**Warning signs:** Compilation errors about duplicate class definitions immediately after adding a new model; errors reference `.freezed.dart` files.

### Pitfall 6: Queue Import for BFS

**What goes wrong:** Dart `Queue` is not in `dart:core`; using it without the import produces a "Queue is not defined" compilation error.

**Why it happens:** `Queue` lives in `dart:collection`, not `dart:core`. It's easy to miss because Python's `collections.deque` is automatically available.

**How to avoid:** Add `import 'dart:collection';` to `map_graph.dart`. Unit tests will immediately catch this.

---

## Code Examples

### Dart Enum (port of Python Enum with auto())

```dart
// Source: Dart language docs + direct port of risk/models/cards.py

enum CardType { infantry, cavalry, artillery, wild }
enum TurnPhase { reinforce, attack, fortify }
```

Python's `auto()` → Dart enum values are ordinal by default. No explicit value assignment needed unless JSON compatibility requires it.

**JSON serialization of enums with @freezed:** `json_serializable` serializes enums as their `name` string by default (e.g., `"reinforce"`). Python's `auto()` serializes as integer (1, 2, 3). This means JSON round-trip of `TurnPhase` will differ between Python and Dart. For Phase 7 golden fixtures, capture the Python state as a game snapshot and translate enum values explicitly. This is expected and documented.

### MapData Freezed Model (port of Python map_schema.py)

```dart
// lib/engine/models/map_schema.dart
@freezed
class ContinentData with _$ContinentData {
  const factory ContinentData({
    required String name,
    required List<String> territories,
    required int bonus,
  }) = _ContinentData;

  factory ContinentData.fromJson(Map<String, dynamic> json) =>
      _$ContinentDataFromJson(json);
}

@freezed
class MapData with _$MapData {
  const factory MapData({
    required String name,
    required List<String> territories,
    required List<ContinentData> continents,
    required List<List<String>> adjacencies,  // classic.json has [[t1,t2], ...]
  }) = _MapData;

  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
}
```

**Note:** Python `MapData` uses `list[tuple[str, str]]` for adjacencies. JSON doesn't have tuple type; `classic.json` stores them as `[[t1, t2], ...]`. Dart model uses `List<List<String>>` to match the JSON format directly.

### Unit Test Structure (port of tests/test_map_graph.py)

```dart
// test/engine/map_graph_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/map_graph.dart';
import 'package:risk_mobile/engine/models/map_schema.dart';

// Load test fixture inline (not from assets — pure Dart test)
MapData get classicMap => MapData.fromJson(classicJson);

void main() {
  late MapGraph mapGraph;

  setUp(() {
    mapGraph = MapGraph(classicMap);
  });

  group('adjacency', () {
    test('42 territories loaded', () {
      expect(mapGraph.allTerritories.length, equals(42));
    });

    test('bidirectional adjacency', () {
      expect(mapGraph.areAdjacent('Alaska', 'Kamchatka'), isTrue);
      expect(mapGraph.areAdjacent('Kamchatka', 'Alaska'), isTrue);
    });

    test('non-adjacent territories', () {
      expect(mapGraph.areAdjacent('Alaska', 'Brazil'), isFalse);
    });
  });

  group('BFS connected territories', () {
    test('isolated friendly territory returns only itself', () {
      final result = mapGraph.connectedTerritories('Alaska', {'Alaska', 'Brazil'});
      expect(result, equals({'Alaska'}));
    });

    test('full continent reachable', () {
      const sa = {'Venezuela', 'Peru', 'Brazil', 'Argentina'};
      final result = mapGraph.connectedTerritories('Venezuela', sa);
      expect(result, equals(sa));
    });
  });

  group('continent queries', () {
    test('Australia bonus is 2', () {
      expect(mapGraph.continentBonus('Australia'), equals(2));
    });

    test('controls continent when owning all territories', () {
      const australia = {'Indonesia', 'New Guinea', 'Western Australia', 'Eastern Australia'};
      expect(mapGraph.controlsContinent('Australia', australia), isTrue);
    });
  });
}
```

**Note on test data:** The unit tests should embed the classic.json data as a Dart `const Map` or load it from a test fixture file, not via `rootBundle.loadString` (which requires the Flutter test environment). Pure Dart tests run faster and don't need the Flutter test runner.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `riverpod_generator: ^2.6.0` | `riverpod_generator: ^4.0.3` | Riverpod 3.0 release | Version in STACK.md is wrong; use 4.x |
| `objectbox_flutter_libs: path: flutter_libs` | `objectbox_flutter_libs: any` | ObjectBox 4.x+ | No more download-libs script needed |
| `dart run objectbox:download-libs` | `flutter pub add objectbox_flutter_libs:any` | ObjectBox 4.x+ | pub.dev package handles native libs |
| `dart run objectbox:download-libs` still needed for native unit tests (non-Flutter) | `bash <(curl -s https://raw.githubusercontent.com/objectbox/objectbox-dart/main/install.sh)` | Current | Only needed if running dart test (not flutter test) on the machine |

**Deprecated/outdated (from project STACK.md):**

- `riverpod_generator: ^2.6.0`: Use `^4.0.3` for Riverpod 3.x.
- `objectbox_flutter_libs: path: flutter_libs`: Use `objectbox_flutter_libs: any` instead.

---

## Open Questions

1. **JSON key format for `Map<int, List<Card>>` (cards field)**
   - What we know: JSON map keys must be strings; Dart `Map<int, ...>` doesn't round-trip through JSON without a converter
   - What's unclear: Whether to change the Dart model to `Map<String, List<Card>>` or use a custom converter
   - Recommendation: Change to `Map<String, List<Card>>` — simpler, no custom converter needed, access with `cards['0']` or `cards[playerIndex.toString()]`

2. **Flutter project location in repo**
   - What we know: No Flutter project exists yet; the repo root contains the Python project
   - What's unclear: Whether to put the Flutter app in `mobile/` subdirectory or a sibling directory
   - Recommendation: Create `mobile/` subdirectory inside the existing repo — keeps related projects together, mirrors the existing structure without polluting the Python project root

3. **classic.json in Flutter assets vs symlink**
   - What we know: `risk/data/classic.json` is the source of truth; Flutter needs it as an asset
   - What's unclear: Whether to copy it or symlink it for DRY maintenance
   - Recommendation: Copy it to `mobile/assets/classic.json` as part of Phase 6. Document that changes to the Python source must be manually mirrored. Symlinks in Flutter assets work on some platforms but are unreliable on Windows build machines.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK-bundled) + dart test (for pure Dart files) |
| Config file | None required for basic setup |
| Quick run command | `flutter test test/engine/` (pure Dart, no device needed) |
| Full suite command | `flutter test` (all tests) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DART-07 | MapGraph loads 42 territories from classic.json | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| DART-07 | areAdjacent returns true for known adjacent pairs | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| DART-07 | areAdjacent returns false for non-adjacent pairs | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| DART-07 | neighbors returns correct set for Alaska (3 neighbors) | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| DART-07 | connectedTerritories BFS with isolated start | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| DART-07 | connectedTerritories BFS for full continent | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| DART-07 | controlsContinent when all territories owned | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| DART-07 | continentBonus returns correct values for all 6 continents | unit | `flutter test test/engine/map_graph_test.dart -x` | ❌ Wave 0 |
| (infra) | @freezed models generate with copyWith and equality | unit | `flutter test test/engine/models_test.dart -x` | ❌ Wave 0 |
| (infra) | ObjectBox write/read round-trip for SaveSlot | unit | `flutter test test/persistence/save_slot_test.dart -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/engine/map_graph_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/engine/map_graph_test.dart` — covers DART-07 (all 8 MapGraph behaviors from Python test_map_graph.py)
- [ ] `test/engine/models_test.dart` — covers @freezed copyWith, equality, JSON round-trip
- [ ] `test/persistence/save_slot_test.dart` — covers ObjectBox write/read
- [ ] `mobile/assets/classic.json` — copied from `risk/data/classic.json`
- [ ] `mobile/analysis_options.yaml` — with `invalid_annotation_target: ignore`
- [ ] `mobile/build.yaml` — with `explicit_to_json: true`

---

## Sources

### Primary (HIGH confidence)

- [freezed pub.dev](https://pub.dev/packages/freezed) — Version 3.2.5, analysis_options.yaml config, part directives, build.yaml setup
- [flutter_riverpod pub.dev](https://pub.dev/packages/flutter_riverpod) — Version 3.3.1 confirmed current
- [riverpod_annotation pub.dev](https://pub.dev/packages/riverpod_annotation) — Version 4.0.2 confirmed (not 3.x)
- [riverpod_generator pub.dev](https://pub.dev/packages/riverpod_generator) — Version 4.0.3 confirmed (not 2.6.0 as in STACK.md)
- [riverpod.dev getting started](https://riverpod.dev/docs/introduction/getting_started) — Exact pubspec.yaml for Flutter with code gen; ProviderScope setup
- [objectbox pub.dev](https://pub.dev/packages/objectbox) — Version 5.2.0 confirmed
- [objectbox_flutter_libs pub.dev](https://pub.dev/packages/objectbox_flutter_libs) — Version 5.2.0; confirmed `any` not path dependency
- [ObjectBox Getting Started Docs](https://docs.objectbox.io/getting-started) — `flutter pub add objectbox_flutter_libs:any`; no download-libs command

### Secondary (MEDIUM confidence)

- [Flutter 3.41 What's New blog](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632) — Flutter 3.41 stable Feb 2026, Dart 3.11 bundled
- [Dart 3.11 announcement](https://blog.dart.dev/announcing-dart-3-11-b6529be4203a) — SDK 3.7.0 minimum for Riverpod 3.x pubspec constraint
- [freezed + json_serializable analyzer compatibility issue #1326](https://github.com/rrousselGit/freezed/issues/1326) — version compatibility constraint between freezed 3.2.3 and json_serializable 6.11.3; use ^6.13.0

### Tertiary (LOW confidence)

- Multiple community tutorials on ObjectBox Flutter setup (2024-2025) — confirmed `any` version for objectbox_flutter_libs is standard across all recent guides

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all package versions verified on pub.dev; official docs consulted
- Architecture: HIGH — direct port of well-understood Python codebase; patterns from official Riverpod and freezed docs
- Pitfalls: HIGH — two critical version errors in existing STACK.md caught and corrected against official sources; JSON serialization edge cases verified against freezed issues

**Key corrections vs project STACK.md:**
1. `riverpod_generator: ^2.6.0` → `^4.0.3` (Riverpod 3.x requires 4.x generator)
2. `objectbox_flutter_libs: path: flutter_libs` → `objectbox_flutter_libs: any` (pub.dev package, no path dependency)

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable packages; riverpod_generator version is the most likely to update)
