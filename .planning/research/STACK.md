# Stack Research

**Domain:** Flutter mobile board game (Risk port — Android & iOS)
**Researched:** 2026-03-14
**Confidence:** HIGH

> This document covers the v1.1 Flutter/Dart mobile port only.
> The v1.0 Python/FastAPI/JS stack is documented in git history.
> The new app runs entirely on-device — no backend, no network.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter SDK | ^3.41.x (stable) | Cross-platform mobile framework | Flutter 3.41 (Feb 2026) is the current stable release. Targets Android and iOS from a single Dart codebase. Widget toolkit maps well to the turn-based game loop. The SDK bundles Dart ~3.11. |
| Dart SDK | bundled with Flutter | Language runtime | Dart 3.x brings sound null safety, pattern matching, and records — all valuable for a complex game state machine. No separate install needed. |

### State Management

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| flutter_riverpod | ^3.3.1 | Turn-based game state management | Riverpod 3 is the current community consensus for Flutter state in 2026. `NotifierProvider` and `AsyncNotifier` fit a turn FSM directly: each provider owns a slice (current phase, player states, board). Compile-time safety prevents the "provider not found" runtime errors of the older `provider` package. Riverpod 3.0 introduces built-in mutations and offline persistence hooks. Use `@riverpod` code generation macro to reduce boilerplate. |
| riverpod_annotation | ^3.3.1 | Code generation for Riverpod | Required companion for the `@riverpod` macro. Eliminates manual provider wiring. |
| build_runner | ^2.x | Code generation runner | Required to run `riverpod_annotation`, `freezed`, and `json_serializable` code generation. Run with `dart run build_runner build --delete-conflicting-outputs`. |

### Data Modeling (Immutable Game State)

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| freezed | ^3.2.5 | Immutable data classes with `copyWith` and equality | The Python game engine used Pydantic's `model_copy()` for immutable state transitions. Freezed is the Dart equivalent. Generates `copyWith`, `==`, `hashCode`, and union types. Use for `GameState`, `Territory`, `Player`, `TurnPhase` etc. Critical for Riverpod: providers only re-render when state object identity changes. |
| freezed_annotation | ^3.x | Annotation companion for freezed | Required at runtime (not dev-only). |
| json_serializable | ^6.13.0 | JSON serialization for save/load | Generates `fromJson`/`toJson` for all `@JsonSerializable` classes. Combine with `freezed` for full-featured model layer. Required for ObjectBox persistence and any future export features. |
| json_annotation | ^4.x | Annotation companion for json_serializable | Required at runtime. |

### Map Rendering

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| flutter_svg | ^2.2.4 | Render the Risk world map SVG asset | The existing Risk map is an SVG. `flutter_svg` (now published by flutter.dev after the original author's death in 2024) renders SVG as a Flutter widget. Use for static map background rendering. Combine with `InteractiveViewer` for pinch-to-zoom and pan. |
| path_parsing | ^1.1.0 | Parse SVG path data strings into Flutter `Path` objects | Maintained by the Flutter team at Google (forked from the original author's `path_drawing`). Use to convert each territory's SVG `<path d="...">` string into a Dart `Path` object at startup. These baked `Path` objects are used in `CustomPainter.hitTest()` to detect which territory the user tapped. Do NOT use `path_drawing` (3 years unmaintained). |

> **Map rendering architecture:** Render the SVG map image with `flutter_svg` inside `InteractiveViewer` for zoom/pan. Overlay a `CustomPaint` widget (same size) that draws territory color fills, army counts, and selection highlights using pre-parsed `Path` objects from `path_parsing`. Tap detection uses `GestureDetector` + `Path.contains(localPosition)` to identify the tapped territory. This avoids re-parsing SVG on every tap.

### Local Persistence (Save / Load)

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| objectbox | ^5.2.0 | Structured save-game storage | ObjectBox 5.2 is actively maintained by objectbox.io, supports Android + iOS, and is ACID-compliant with 10x faster reads/writes than SQLite alternatives. Explicitly designed for mobile game state (has a dedicated games use-case page). Works with Dart-native objects (no SQL). Use for save slots: serialize `GameState` to JSON via `json_serializable`, store as a string entity with metadata (timestamp, player count, turn number). |
| objectbox_flutter_libs | ^5.2.0 | Native ObjectBox library for Android/iOS | Required companion package. Download pre-built binaries via `flutter pub run objectbox:download-libs`. |
| shared_preferences | ^2.5.4 | App settings storage | For simple, non-critical key-value settings: difficulty preference, simulation speed, last-used player count. Uses `NSUserDefaults` on iOS and `SharedPreferences` on Android. Do NOT use for save-game data (no write guarantees). |

### Build & Packaging Tools (Dev Only)

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| flutter_launcher_icons | ^0.14.4 | Generate adaptive Android and iOS launcher icons from a single source image | Run via `dart run flutter_launcher_icons`. Configure in `pubspec.yaml` under `flutter_launcher_icons:`. Generates adaptive icons (Android 8+) and iOS icon sets automatically. |
| flutter_native_splash | ^2.4.7 | Generate a native splash screen (avoids white flash on startup) | Run via `dart run flutter_native_splash:create`. Configures Android `launch_background.xml` and iOS `LaunchScreen.storyboard`. Configure in `pubspec.yaml`. |

### Testing

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| flutter_test | SDK-bundled | Unit tests (game engine logic) and widget tests | Bundled with Flutter SDK, no separate install. Game engine logic (combat, cards, reinforcements, fortify, FSM) is pure Dart — test with `test()` directly. Widget tests use `WidgetTester` for UI interaction. |
| integration_test | SDK-bundled | On-device integration tests | Bundled with Flutter SDK. Use for end-to-end game flow tests (game starts, turn completes, win is detected). Run with `flutter test integration_test/`. |
| mocktail | ^1.0.4 | Mock dependencies in unit tests | Preferred over `mockito` in 2025-2026: no code generation needed, null-safe by default, simpler API. Use for mocking `ObjectBox` storage in unit tests. Published by felangel.dev (BLoC author). |

---

## Installation

```yaml
# pubspec.yaml

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.41.0"

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^3.3.1

  # Immutable models
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

  # Map rendering
  flutter_svg: ^2.2.4
  path_parsing: ^1.1.0

  # Persistence
  objectbox: ^5.2.0
  objectbox_flutter_libs:
    path: flutter_libs  # generated by download-libs command
  shared_preferences: ^2.5.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^3.2.5
  json_serializable: ^6.13.0

  # Testing
  mocktail: ^1.0.4

  # Build packaging
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.7
```

```bash
# After adding pubspec.yaml dependencies:
flutter pub get

# Download ObjectBox native libraries (one-time per project setup)
dart run objectbox:download-libs

# Run code generation (after any model change)
dart run build_runner build --delete-conflicting-outputs

# Generate launcher icons (after configuring pubspec.yaml)
dart run flutter_launcher_icons

# Generate splash screens
dart run flutter_native_splash:create

# Build Android release (AAB for Play Store)
flutter build appbundle --release

# Build iOS release (requires macOS + Xcode)
flutter build ipa --release
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| flutter_riverpod | bloc | When you have a large team requiring strict event-audit trails. BLoC is more verbose but leaves a paper trail for every state transition. Riverpod is sufficient for a single-developer game project. |
| flutter_riverpod | provider | Never — `provider` is the older predecessor; Riverpod fixes its compile-time bugs without API regression. |
| freezed | manual copyWith | Only for trivially small data classes with 1-2 fields. The game state has 42 territories + player state + turn phase; freezed code gen pays for itself here. |
| objectbox | isar | Isar is faster than ObjectBox in some benchmarks but its original author abandoned it in 2024 and it is now community-maintained with uncertain roadmap. ObjectBox has active commercial backing. |
| objectbox | hive | Hive is also community-maintained post-abandonment. ObjectBox outperforms it significantly and is better suited for structured, queryable game save data. |
| objectbox | sqflite (SQLite) | Only if you need complex relational queries across saves. ObjectBox's object-native API is cleaner for serializing game snapshots. |
| path_parsing | path_drawing | `path_drawing` (dnfield/flutter_path_drawing) has not been updated in 3 years. `path_parsing` is the actively maintained Flutter-team successor, forked to preserve the same API. |
| mocktail | mockito | `mockito` requires code generation (`build_runner`) for each mock class. `mocktail` works without generation and is simpler for a game project where most mocked dependencies are storage/IO. |
| CustomPainter + path_parsing | flutter_svg alone for interactivity | `flutter_svg` does not expose per-path hit testing. For tappable territories you must either (a) layer a custom painter for hit detection or (b) parse the SVG XML yourself. The CustomPainter overlay approach is the established community pattern. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `flame` (Flutter game engine) | Flame is a sprite/animation engine optimized for arcade-style games with a continuous game loop. Risk is turn-based with no animation loop, and Flame's `GameWidget` replaces Flutter's widget tree, making standard UI (bottom sheets, dialogs, navigation) much harder. | Flutter's standard widget tree + CustomPainter for the map |
| `hive` / `isar` | Both were abandoned by their original author in 2024 and are now community-maintained with uncertain long-term support. | `objectbox` |
| `provider` (old package) | The predecessor to Riverpod. Has undetectable compile-time errors (`ProviderNotFoundException` at runtime). Riverpod was built to fix this. | `flutter_riverpod` |
| `get` / GetX | Opinionated framework that merges routing, state, and DI. Tight coupling makes unit testing game logic difficult. | `flutter_riverpod` for state, Flutter's built-in `Navigator` for routing |
| `dart:isolate` for bot AI | The Risk AI bots from v1.0 complete moves in <10ms each (heuristic scoring, not Monte Carlo). Running bots in an isolate adds setup/teardown overhead and complicates state sharing. Profile first; only isolate if bots freeze the UI (>16ms). | Direct synchronous execution; `compute()` only if profiling shows jank |
| `google_maps_flutter` or any geo-map package | These are geographic maps (lat/lon coordinates, tile fetching). The Risk map is a custom fantasy/stylized world map with hardcoded territory polygons. Geo-map packages add network dependencies and irrelevant complexity. | `flutter_svg` + `CustomPainter` |
| Remote backend / REST API | v1.1 goal is fully on-device, no server dependency. Reintroducing a backend would break the "runs anywhere" mobile requirement. | Pure Dart game engine |

---

## Stack Patterns by Variant

**For turn-phase state machine (game FSM):**
- Use a `@riverpod` `Notifier` subclass as the single source of truth for `TurnPhase`
- Expose `phase`, `currentPlayer`, `pendingAction` as derived providers
- Because phase transitions are synchronous, use `Notifier` (not `AsyncNotifier`)

**For bot AI execution:**
- Execute synchronously in the Notifier's `_advanceBotTurn()` method
- If profiling shows >16ms frame drops during AI computation, wrap in `compute()` (Flutter's isolate helper for one-shot tasks)
- Do NOT pre-emptively isolate — the Python v1.0 bots were fast; Dart should be equivalent

**For map territory tap detection:**
- Parse all 42 territory SVG paths at app startup into a `Map<String, Path>` (territory ID → `Path`)
- Store in a Riverpod provider initialized with `ref.watch(mapDataProvider)`
- In `GestureDetector.onTapUp`, iterate paths and call `path.contains(localPosition)` — first match wins
- Z-order paths largest-first to prevent small territories being masked by large neighbors

**For save/load:**
- Serialize `GameState` to JSON string using `json_serializable`
- Store in ObjectBox as a `SaveSlot` entity: `{ id, name, timestamp, gameStateJson, turnNumber }`
- Support 3 named save slots; show in a `showModalBottomSheet` from the game screen

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| flutter_riverpod ^3.3.1 | riverpod_annotation ^3.3.1 | Must match major version. Riverpod 3.x is a breaking change from 2.x. |
| freezed ^3.2.5 | freezed_annotation ^3.x | Must match major version. |
| objectbox ^5.2.0 | objectbox_flutter_libs ^5.2.0 | Must match exactly. Mismatched native lib version causes runtime crashes. |
| flutter_launcher_icons ^0.14.4 | flutter_native_splash ^2.4.7 | These had version conflicts in older releases (args package). Current versions are compatible. |
| Flutter ^3.41.x | Dart ^3.11 | Dart is bundled — do not add a separate Dart SDK constraint beyond what Flutter requires. |

---

## Sources

- [Flutter 3.41 What's New](https://docs.flutter.dev/release/whats-new) — Flutter 3.41 stable (Feb 2026), Dart ~3.11 bundled — HIGH confidence
- [flutter_riverpod pub.dev](https://pub.dev/packages/flutter_riverpod) — Version 3.3.1, published 5 days ago — HIGH confidence
- [Riverpod 3.0 What's New](https://riverpod.dev/docs/whats_new) — Mutations and offline persistence features — HIGH confidence
- [freezed pub.dev](https://pub.dev/packages/freezed) — Version 3.2.5, published 39 days ago — HIGH confidence
- [json_serializable pub.dev](https://pub.dev/packages/json_serializable) — Version 6.13.0 (Google) — HIGH confidence
- [flutter_svg pub.dev](https://pub.dev/packages/flutter_svg) — Version 2.2.4 (flutter.dev publisher) — HIGH confidence
- [path_parsing pub.dev](https://pub.dev/packages/path_parsing) — Version 1.1.0, maintained by flutter.dev — HIGH confidence
- [path_drawing unmaintained notice](https://pub.dev/packages/path_drawing) — Last updated 3 years ago; successor is path_parsing — HIGH confidence
- [objectbox pub.dev](https://pub.dev/packages/objectbox) — Version 5.2.0, objectbox.io publisher — HIGH confidence
- [ObjectBox game use case](https://objectbox.io/games/) — Dedicated mobile game persistence solution — MEDIUM confidence
- [shared_preferences pub.dev](https://pub.dev/packages/shared_preferences) — Version 2.5.4 — HIGH confidence
- [mocktail pub.dev](https://pub.dev/packages/mocktail) — Version 1.0.4, felangel.dev — HIGH confidence
- [flutter_launcher_icons pub.dev](https://pub.dev/packages/flutter_launcher_icons) — Version 0.14.4 — HIGH confidence
- [flutter_native_splash pub.dev](https://pub.dev/packages/flutter_native_splash) — Version 2.4.7 — HIGH confidence
- [Riverpod vs BLoC comparison 2026](https://medium.com/@flutter-app/state-management-in-2026-is-riverpod-replacing-bloc-40e58adcb70f) — Ecosystem consensus — MEDIUM confidence
- [Hive/Isar abandonment context](https://dinkomarinac.dev/best-local-database-for-flutter-apps-a-complete-guide/) — Maintenance concerns confirmed by multiple sources — MEDIUM confidence
- [Flutter InteractiveViewer for game maps](https://gladimdim.org/animating-interactiveviewer-in-flutter-or-how-to-animate-map-in-your-game) — TransformationController pattern — MEDIUM confidence
- [Interactive SVG maps in Flutter](https://www.appwriters.dev/blog/flutter-interactive-svg-maps) — Path-based hit detection pattern — MEDIUM confidence

---

*Stack research for: Flutter mobile Risk board game (v1.1)*
*Researched: 2026-03-14*
