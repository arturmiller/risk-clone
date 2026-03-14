# Project Research Summary

**Project:** Risk Board Game — Flutter Mobile Port (v1.1)
**Domain:** Turn-based strategy board game, mobile (Android + iOS), on-device Dart engine
**Researched:** 2026-03-14
**Confidence:** HIGH

## Executive Summary

This project is a mobile port of an existing, working Python/FastAPI + vanilla JS Risk board game. The v1.1 goal is to eliminate the client-server architecture entirely and deliver a fully on-device Flutter app for Android and iOS. The core game mechanics — 42 territories, 3 AI difficulty levels, card trading, blitz attack, simulation mode — are already validated in Python. The port is therefore a translation problem, not a design problem. The key risks are logic drift during the Python-to-Dart translation, mobile-specific UX gaps (touch targets, orientation, app backgrounding), and performance in the map rendering layer.

The recommended approach is a clean 4-layer architecture: pure Dart game engine (direct port of Python engine), Riverpod `AsyncNotifier` for state orchestration, `CustomPainter` + `InteractiveViewer` for map rendering, and ObjectBox for save-game persistence. The engine layer must be built and validated with golden-fixture tests against the Python source before any UI is wired. Bot turns must run in Dart isolates from day one — retrofitting isolates into an already-wired UI is high-cost.

The greatest technical risks are UI thread blocking from bot AI computation (must use `Isolate.run()`) and CustomPainter performance collapse under pinch-zoom on mid-range Android (must pre-rasterize static map layer). Both require architectural decisions at the start of their respective phases, not as patches. The mobile UX risks — small touch targets in Europe/SE Asia, app backgrounding state loss, bottom sheet accidental dismissal — are well-understood with clear mitigations and can be addressed incrementally.

---

## Key Findings

### Recommended Stack

Flutter 3.41 (current stable, Feb 2026) with Dart 3.11 is the clear choice for a cross-platform mobile board game targeting Android and iOS from a single codebase. The widget toolkit maps well to a turn-based game loop, and Flutter's `CustomPainter` + `GestureDetector` provide the map rendering and hit-detection primitives needed without a game engine framework like Flame (which adds unnecessary overhead for an event-driven board game).

State management uses Riverpod 3.x (`flutter_riverpod ^3.3.1`) with `AsyncNotifier` — the compile-time safety and clean async modeling for bot turns makes this the right choice over BLoC (too verbose for solo project) or Provider (predecessor with known runtime errors). Immutable game state uses `freezed ^3.2.5`, which is the direct Dart equivalent of the Python Pydantic `model_copy()` pattern already in use. For persistence, ObjectBox 5.2 (actively backed) is chosen over Hive and Isar (both abandoned by original author in 2024).

**Core technologies:**
- **Flutter 3.41 / Dart 3.11:** Cross-platform mobile framework — current stable, bundled Dart, single codebase for Android + iOS
- **flutter_riverpod ^3.3.1:** State management — `AsyncNotifier` models bot-turn async cleanly; compile-time safety prevents provider-not-found runtime errors
- **freezed ^3.2.5:** Immutable data classes — direct equivalent of Python's Pydantic `model_copy()`; generates `copyWith`, equality, JSON serialization
- **flutter_svg ^2.2.4 + path_parsing ^1.1.0:** Map rendering — `flutter_svg` for static background; `path_parsing` (Flutter team maintained) for SVG path to Dart `Path` conversion for hit testing
- **objectbox ^5.2.0:** Save-game persistence — ACID-compliant, mobile-optimized, actively maintained (commercial backing); stores `GameState` as JSON string in named save slots
- **shared_preferences ^2.5.4:** App settings — bot speed, haptic toggle, colorblind mode; not for game state

**Critical version requirements:**
- `flutter_riverpod` and `riverpod_annotation` must match major version (both `^3.3.1`)
- `objectbox` and `objectbox_flutter_libs` must match exactly (version mismatch causes runtime crash)
- `freezed` and `freezed_annotation` must match major version

### Expected Features

The feature set divides clearly between mobile table stakes (things users assume exist) and differentiators that improve on the primary competitor, Risk: Global Domination (SMG Studio, 4.34/5, 19M downloads).

**Must have (table stakes) — v1 launch:**
- Touch map interaction: tap-to-select, pinch-to-zoom (min 1x, max 4x), pan — without this the game is not playable on mobile
- Auto-save on every turn end + resume on app restart — mobile users get interrupted; game loss on interruption is unacceptable
- Responsive layout: portrait (map full-width, controls in bottom sheet) and landscape (map + side panel) — users rotate immediately
- Settings screen: bot speed (Slow/Fast/Instant), haptic toggle, colorblind mode (Wong palette) — minimum accessibility and configurability
- Haptic feedback: dice roll, territory capture, invalid action, turn start — differentiates from web; native feel at no implementation cost
- Victory/defeat screen — satisfying close; absence feels like a crash
- Abandon game confirmation via `PopScope` — standard mobile pattern

**Should have — v1.x after validation:**
- Tablet layout: persistent side panel at 600dp+ breakpoint
- Contextual rule hints: one-time tooltips on first card trade, first blitz opportunity
- End-game stats breakdown: turn count, territories held, armies eliminated
- Win/loss local history via `shared_preferences`

**Defer to v2+:**
- Interactive tutorial (requires full game loop complete first; high implementation cost)
- Dark/light theme override in settings (system auto-detection sufficient for launch)
- Dice roll animation (keep it skippable; not essential for gameplay)

**Anti-features (do not build):**
- Undo/take-back: undermines strategic commitment; use pre-commit confirmation dialog instead
- Online multiplayer: requires server infrastructure, auth, disconnect handling — out of scope
- Sound effects/music: explicitly out of scope; haptics cover tactile feedback
- Multiple save slots: enables save-scumming against bots; single auto-save is correct design
- Cloud sync: requires auth, conflict resolution; local-only is sufficient

### Architecture Approach

The architecture is a 4-layer on-device system: **Presentation** (Flutter widgets) → **State** (Riverpod providers) → **Engine** (pure Dart, zero Flutter imports) → **Data** (freezed models, static map JSON). This directly mirrors the Python architecture's separation of concerns and makes the engine layer independently testable with plain `dart test`. The elimination of the FastAPI/WebSocket layer is the core structural change; `GameNotifier` (`AsyncNotifier<GameState>`) replaces the Python game manager and WebSocket event loop.

**Major components:**
1. **GameNotifier** (`AsyncNotifier<GameState>`) — owns canonical game state; orchestrates human moves, bot turns via `Isolate.run()`, and simulation timer; replaces FastAPI game manager + WebSocket layer
2. **MapPainter** (`CustomPainter`) — renders 42 territory paths with color-by-owner, army count labels, selection highlights; pre-parsed SVG paths from `path_parsing`; hit detection via `path.contains(localPosition)`
3. **Engine layer** (`engine/` — pure Dart) — direct port of Python `turn.py`, `combat.py`, `cards.py`, `fortify.py`, `setup.py`; immutable `GameState` with `copyWith`; zero Flutter imports
4. **Bot Agents** (`bots/` — pure Dart) — `EasyAgent`, `MediumAgent`, `HardAgent` implementing `PlayerAgent` interface; run in `Isolate.run()` during gameplay to prevent UI blocking
5. **UIStateNotifier** — ephemeral UI state (selected territory, valid targets); deliberately separate from `GameState` to prevent UI pollution of engine logic
6. **SimModeNotifier** — controls AI-vs-AI simulation: `Timer.periodic` scheduling, speed control, pause/resume

**Key architectural patterns:**
- Engine functions are pure: `(GameState, ...) → GameState`. No side effects, no Flutter dependencies.
- `UIState` (selection, valid targets) is separate from `GameState` (game logic). Never merge them.
- SVG territory paths are parsed once at startup into `Map<String, Path>`; passed to `MapPainter` as constructor parameter. Never parsed inside `paint()`.
- Map renders as two layers: pre-rasterized static background + dynamic overlay `CustomPainter` for army counts and highlights. Only the overlay repaints on state changes.

### Critical Pitfalls

1. **AI bot blocking the UI thread (M1)** — HardAgent's O(n*k) territory scoring runs fine in Python on a server but causes frame drops on Flutter's main isolate. Use `Isolate.run()` for all bot turns from the first wiring. Never invoke agent logic in `onTap` callbacks or `setState`. Recovery cost if retrofitted after full UI is built: HIGH.

2. **CustomPainter zoom performance collapse (M2)** — Drawing all 42 territory paths live in `CustomPainter` inside `InteractiveViewer` causes 80ms+ frame times on mid-range Android during pinch-zoom. Pre-rasterize the static map layer using `ui.PictureRecorder` at startup. Only the dynamic overlay (army counts, highlights) repaints on state changes. Architecture decision must be made before building map interaction; recovery cost if wrong: HIGH.

3. **Dart/Python logic drift (M4)** — Integer division (`~/` not `/`), dice comparison semantics, BFS traversal order, card trade escalation sequence can silently diverge between languages. Capture golden test fixtures from the Python engine (seeded state → output JSON) before porting. All golden fixtures must pass before any engine function is considered done.

4. **App backgrounding state loss (M6)** — iOS can terminate a paused app without further callbacks. Save `GameState` to local storage on `AppLifecycleState.inactive` (fires on both platforms before potential kill), not `paused`. Test by force-terminating via Xcode/adb after 10 minutes backgrounded on both platforms.

5. **Async state management complexity (M5)** — A single `StatefulWidget` holding `GameState` produces race conditions when bot isolates post new state while user is mid-gesture. Use Riverpod `AsyncNotifier` from the start. All state transitions (human move, bot move, simulation tick) go through a single `GameNotifier` that processes actions serially.

6. **Touch targets too small (M3)** — Europe and SE Asia territories render below 30dp on a phone screen. Expand hit regions by 6dp padding; add disambiguation popup when touch falls in multiple expanded regions. Test on a physical device with a finger, not the simulator.

---

## Implications for Roadmap

The architecture research provides an explicit 7-phase build order with clear dependencies. The feature research confirms all game mechanics exist and only the mobile UX layer is net-new. Phase structure follows the dependency graph: engine before providers, providers before widgets, widgets before integration.

### Phase 1: Flutter Project Scaffold + Data Models

**Rationale:** Zero-dependency foundation. All subsequent phases depend on `@freezed` models and the map graph being in place. Code generation setup (build_runner, freezed, json_serializable) must work before any engine code is written.
**Delivers:** Working Flutter project; `pubspec.yaml` configured; `@freezed` `GameState`/`TerritoryState`/`PlayerState`/`Card`/`TurnPhase` models; `MapGraph` with adjacency, BFS, continent queries; bundled `map.json` asset; passing unit tests for all graph queries.
**Addresses:** No user-facing features, but enables everything else. ObjectBox and shared_preferences configured and verified.
**Avoids:** Build system version conflicts caught early; `objectbox`/`objectbox_flutter_libs` version mismatch is a runtime crash if missed.
**Research flag:** Standard patterns — skip research phase. Flutter project setup and freezed code gen are well-documented with official guides.

### Phase 2: Dart Game Engine Port

**Rationale:** Engine must be correct before any UI is built. Golden fixture tests against Python source catch logic drift early when it is cheap to fix. This phase produces pure Dart that can be fully tested without the Flutter runtime.
**Delivers:** Pure Dart port of `combat.py`, `cards.py`, `fortify.py`, `reinforcements.py`, `setup.py`, `turn.py`. Full golden-fixture test suite against Python output. Combat statistics match Python within 0.5% over 10k simulated trials.
**Uses:** `freezed` immutable models, `dart:math.Random` (injected for testability)
**Avoids:** Dart/Python logic drift (Pitfall M4). Golden fixtures catch silent divergence early, when it costs hours not days.
**Research flag:** Standard patterns — skip research phase. Direct algorithmic port; `copyWith` for `model_copy()` is a known 1:1 translation.

### Phase 3: Bot Agents (Dart Port)

**Rationale:** Bots depend on the engine but are independent of the UI. Porting and testing them in isolation ensures the `PlayerAgent` interface is stable before `GameNotifier` orchestrates them. The isolate architecture is established here, not retrofitted.
**Delivers:** `EasyAgent`, `MediumAgent`, `HardAgent` implementing `PlayerAgent` interface. Unit tests with fixed-seed `Random`. Statistical validation (win rates consistent with Python version). `Isolate.run()` pattern established and validated.
**Avoids:** UI thread blocking (Pitfall M1) — isolate architecture built here so it is never an afterthought.
**Research flag:** Standard patterns — skip research phase. Direct port of Python agents; `Isolate.run()` is well-documented in Flutter.

### Phase 4: Riverpod State Providers + Persistence

**Rationale:** `GameNotifier`, `UIStateNotifier`, `SimModeNotifier` are the coordination layer between engine and UI. Must exist before any widget consumes state. Lifecycle persistence belongs here — it must be in place before real gameplay testing begins, or every development session risks data loss.
**Delivers:** `GameNotifier` (`AsyncNotifier<GameState>`), `UIStateNotifier`, `SimModeNotifier`, `mapGraphProvider`. `WidgetsBindingObserver` saving `GameState` to ObjectBox on `AppLifecycleState.inactive`. Resume prompt on cold start. Settings persistence via `shared_preferences`. `ProviderContainer` tests for all notifiers.
**Addresses:** Auto-save/resume (P1 feature), settings storage, async state management complexity (Pitfall M5), app backgrounding state loss (Pitfall M6).
**Avoids:** Race conditions from ad-hoc state management; state loss before first real test session establishes a pattern that is painful to retrofit.
**Research flag:** Standard patterns — skip research phase. Riverpod `AsyncNotifier` and ObjectBox have official documentation with examples.

### Phase 5: Map Widget (Rendering + Touch Interaction)

**Rationale:** The map widget is the critical path to playability — without territory selection there is no game. It is also the highest-risk rendering component. The pre-rasterization architecture decision must be made before any rendering code is written; it cannot be patched in after the fact without a full rewrite.
**Delivers:** SVG territory paths parsed at startup via `path_parsing`. Two-layer map rendering: pre-rasterized static background (`ui.PictureRecorder`) + dynamic overlay `CustomPainter`. `GestureDetector` tap-to-select with polygon hit testing and 6dp hit-region expansion. Disambiguation popup for dense territory regions. `InteractiveViewer` pinch-zoom (1x–4x) and pan. Coordinate transform via `controller.toScene(localPosition)` for correct zoom hit testing.
**Addresses:** Touch map interaction (P1), touch target accessibility (P1), colorblind mode territory color rendering.
**Avoids:** CustomPainter zoom performance (Pitfall M2), touch targets too small (Pitfall M3), InteractiveViewer coordinate transform bug (integration gotcha from PITFALLS.md).
**Research flag:** Needs deeper research — complex rendering architecture; known Flutter performance regression with CustomPainter + InteractiveViewer (GitHub issue #72066); `ui.PictureRecorder` pre-rasterization implementation details need prototyping before coding begins.

### Phase 6: Screens, Widgets, and Mobile UX

**Rationale:** With engine, providers, and map widget in place, the game is playable. This phase assembles the full UI: home screen, game screen, responsive layout, settings, victory/defeat. Platform-specific behavior (bottom sheet dismissal, safe area, haptics) is handled per-widget here.
**Delivers:** `HomeScreen` (player count, difficulty), `GameScreen` (map + sidebar + `ActionPanel` bottom sheet), responsive `LayoutBuilder` breakpoint (portrait bottom sheet vs landscape side panel), `SettingsScreen` (bot speed, haptic toggle, colorblind mode). Victory/defeat modal with stats. `PopScope` abandon game confirmation. Haptic feedback vocabulary (`HapticFeedback.mediumImpact()` for dice, `heavyImpact()` for capture, `vibrate()` for invalid). `isDismissible: false` on all game-critical bottom sheets.
**Addresses:** Responsive layout (P1), settings screen (P1), haptic feedback differentiator (P1), victory/defeat screen (P1), abandon confirmation (P1), colorblind mode (P1).
**Avoids:** iOS/Android behavioral differences (Pitfall M7) — `isDismissible: false`, `SafeArea` bottom insets, back gesture handling all addressed here per-widget.
**Research flag:** Standard patterns — skip research phase. Flutter responsive layouts, Material bottom sheets, and HapticFeedback API are well-documented.

### Phase 7: Simulation Mode + End-to-End Integration

**Rationale:** Simulation mode depends on all prior phases. Integration testing validates the full game loop including bot turns, game-over detection, and resume-after-backgrounding. Performance must be validated on physical hardware before any milestone sign-off.
**Delivers:** `SimModeNotifier` timer loop (persistent isolate for continuous bot play, not per-turn `Isolate.run()`), simulation speed control (Slow/Fast/Instant), tap-to-inspect territory during simulation, end-game stats screen, win/loss local history, full integration test (complete simulated game). Performance validated on low-end Android (Pixel 3a equivalent): 60fps during zoom, <16ms during bot turn, stable memory over 20-game simulation run.
**Addresses:** Simulation mode (parity with web version), end-game stats (P2 feature), win/loss history (P2 feature).
**Avoids:** Simulation mode isolate-spawning jitter — persistent isolate with message loop, not per-turn `Isolate.run()` for the continuous simulation case.
**Research flag:** Standard patterns for Flutter side. Simulation mode logic is a direct port of existing Python/JS behavior.

### Phase Ordering Rationale

- **Engine before providers before widgets** — the dependency graph from ARCHITECTURE.md is unambiguous and matches the successful structure of the Python v1.0 build. Shortcuts here produce hard-to-isolate bugs.
- **Isolate architecture in Phase 3, not Phase 7** — bot isolate wiring belongs to the bot agent phase. Retrofitting isolates after the UI is wired is the single highest-cost recovery scenario identified in PITFALLS.md.
- **Map widget in Phase 5 as its own phase** — the map is the highest-risk component technically (performance architecture decision, hit testing) and the critical path to playability. Isolating it as a dedicated phase ensures the pre-rasterization approach is prototyped and validated before the screen assembly phase begins.
- **State persistence in Phase 4** — lifecycle persistence must be established before real gameplay testing. Every development test session that involves actual gameplay risks data loss without it.
- **Responsive layout built first in Phase 6** — the FEATURES.md dependency graph warns that responsive layout must be the foundation, not retrofitted. The `LayoutBuilder` breakpoint is the first thing built in Phase 6 before any UI elements are placed.

### Research Flags

Phases likely needing `/gsd:research-phase` during planning:
- **Phase 5 (Map Widget):** Complex rendering architecture; known Flutter performance regression with CustomPainter + InteractiveViewer; `ui.PictureRecorder` pre-rasterization approach needs implementation research and a prototype before full implementation begins.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Scaffold + Models):** Flutter project setup, freezed, and build_runner are well-documented with official guides.
- **Phase 2 (Engine Port):** Direct algorithmic translation with well-understood `copyWith` for `model_copy()` pattern.
- **Phase 3 (Bot Agents):** Direct port of Python agents; `Isolate.run()` usage is well-documented in Flutter.
- **Phase 4 (Providers + Persistence):** Riverpod `AsyncNotifier` and ObjectBox have official documentation.
- **Phase 6 (Screens + UX):** Flutter responsive layouts, Material components, and HapticFeedback are well-documented.
- **Phase 7 (Simulation + Integration):** Simulation mode is a direct port; integration testing patterns are standard.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All packages verified on pub.dev with recent publish dates (2026). Flutter 3.41 is current stable. Version compatibility matrix confirmed. All primary sources are official flutter.dev and pub.dev publisher pages. |
| Features | HIGH | Feature table stakes derived from mobile platform guidelines (Apple HIG, Material Design) and competitor analysis (Risk: Global Domination, 19M downloads). Colorblind palette sourced from medical literature. Android orientation restriction changes sourced from official Android Developers blog. |
| Architecture | HIGH | Patterns sourced from official Riverpod, Flutter, and Dart documentation. Build order is logically derivable from the dependency graph. CustomPainter + Isolate patterns confirmed by multiple community sources. The architecture is a direct structural mapping of the existing Python design. |
| Pitfalls | HIGH | Mobile-specific pitfalls (M1–M7) derived from Flutter platform behavior documentation and known GitHub issues. Game engine pitfalls drawn from v1.0 development experience. Concrete warning signs and recovery costs provided for each. |

**Overall confidence:** HIGH

### Gaps to Address

- **Pre-rasterization implementation specifics:** PITFALLS.md describes the two-layer rendering approach (pre-rasterized background + dynamic overlay) as the correct architecture, but the exact implementation using `ui.PictureRecorder` and `RawImage` in Dart needs to be prototyped and benchmarked against a target device. Address in Phase 5 planning research.
- **Territory SVG path coordinate space:** The existing `map.json` / SVG asset's territory path format (whether paths are in SVG coordinate space, normalized, or already in Flutter coordinate space) affects the hit-test coordinate transform implementation. Validate against the actual asset at the start of Phase 5.
- **Dart Random seeding vs Python:** PITFALLS.md notes that Python's Mersenne Twister and Dart's `dart:math.Random` use different PRNGs. Golden fixtures must capture output states, not attempt to replay the same random draws. Requires careful test harness design at the start of Phase 2.
- **ObjectBox `objectbox_flutter_libs` path:** The recommended `pubspec.yaml` references `path: flutter_libs` for the generated native library path. Verify against the actual `dart run objectbox:download-libs` output structure during Phase 1 setup.

---

## Sources

### Primary (HIGH confidence)

- [Flutter 3.41 Release Notes](https://docs.flutter.dev/release/whats-new) — Flutter stable version, Dart bundling
- [flutter_riverpod pub.dev](https://pub.dev/packages/flutter_riverpod) — Version 3.3.1, flutter.dev publisher
- [Riverpod 3.0 What's New](https://riverpod.dev/docs/whats_new) — AsyncNotifier, mutations, offline persistence hooks
- [Riverpod AsyncNotifier guide](https://riverpod.dev/docs/essentials/side_effects) — AsyncNotifier patterns
- [freezed pub.dev](https://pub.dev/packages/freezed) — Version 3.2.5
- [json_serializable pub.dev](https://pub.dev/packages/json_serializable) — Version 6.13.0, Google publisher
- [flutter_svg pub.dev](https://pub.dev/packages/flutter_svg) — Version 2.2.4, flutter.dev publisher
- [path_parsing pub.dev](https://pub.dev/packages/path_parsing) — Version 1.1.0, flutter.dev publisher; successor to abandoned `path_drawing`
- [objectbox pub.dev](https://pub.dev/packages/objectbox) — Version 5.2.0, objectbox.io publisher
- [shared_preferences pub.dev](https://pub.dev/packages/shared_preferences) — Version 2.5.4
- [mocktail pub.dev](https://pub.dev/packages/mocktail) — Version 1.0.4, felangel.dev
- [Flutter CustomPainter docs](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html) — CustomPainter API
- [Dart Isolates — official docs](https://dart.dev/language/isolates) — Isolate.run() and persistent isolates
- [Flutter concurrency and isolates](https://docs.flutter.dev/perf/isolates) — Flutter-specific isolate guidance
- [Flutter HapticFeedback API](https://api.flutter.dev/flutter/services/HapticFeedback-class.html) — platform haptic methods
- [Android 16 orientation/resizability changes](https://android-developers.googleblog.com/2025/01/orientation-and-resizability-changes-in-android-16.html) — forced orientation lock removed at API 36
- [Android 17 orientation/resizability changes](https://android-developers.googleblog.com/2026/02/prepare-your-app-for-resizability-and.html) — opt-out removed for large screens at API 37
- [Flutter CustomPainter performance issue #72066](https://github.com/flutter/flutter/issues/72066) — known regression with complex paths + InteractiveViewer

### Secondary (MEDIUM confidence)

- [Build interactive maps in Flutter with SVG — Appwriters](https://www.appwriters.dev/blog/flutter-interactive-svg-maps) — path-based hit detection pattern
- [Flutter State Management 2025–2026: Riverpod vs BLoC — Foresight Mobile](https://foresightmobile.com/blog/best-flutter-state-management) — ecosystem consensus on Riverpod
- [Hive/Isar abandonment context](https://dinkomarinac.dev/best-local-database-for-flutter-apps-a-complete-guide/) — maintenance status confirmed by multiple sources
- [RISK: Global Domination on Google Play](https://play.google.com/store/apps/details?id=com.hasbro.riskbigscreen&hl=en_US) — competitor feature analysis, 4.34/5, 19M downloads
- [Color Blind Mode in Games — Number Analytics](https://www.numberanalytics.com/blog/ultimate-guide-color-blind-mode-games) — Wong palette for colorblind support
- [Mobile Gaming UX: Haptic Feedback](https://interhaptics.medium.com/mobile-gaming-ux-how-haptic-feedback-can-change-the-game-3ef689f889bc) — haptic vocabulary design for games
- [Apple Developer: Onboarding for Games](https://developer.apple.com/app-store/onboarding-for-games/) — optional tutorial guidance; confirms skip-tutorial as best practice
- [Flutter InteractiveViewer for game maps](https://gladimdim.org/animating-interactiveviewer-in-flutter-or-how-to-animate-map-in-your-game) — TransformationController coordinate transform pattern

---
*Research completed: 2026-03-14*
*Ready for roadmap: yes*
