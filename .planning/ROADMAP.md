# Roadmap: Risk Strategy Game

## Milestones

- ✅ **v1.0 MVP** — Phases 1-5 (shipped 2026-03-14)
- 🚧 **v1.1 Mobile App** — Phases 6-12 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) — SHIPPED 2026-03-14</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-03-08
- [x] Phase 2: Game Engine (3/3 plans) — completed 2026-03-08
- [x] Phase 3: Web UI and Game Setup (4/4 plans) — completed 2026-03-08
- [x] Phase 4: Easy and Medium Bots (7/7 plans) — completed 2026-03-09
- [x] Phase 5: Hard Bot and AI Simulation (4/4 plans) — completed 2026-03-14

</details>

### 🚧 v1.1 Mobile App (In Progress)

**Milestone Goal:** Port Risk to a fully on-device Flutter app for Android and iOS with a fresh mobile-first UI, rewriting the game engine in Dart and eliminating the Python/WebSocket backend entirely.

- [x] **Phase 6: Flutter Scaffold and Data Models** — Working Flutter project with freezed models, map graph, and code generation (completed 2026-03-15)
- [x] **Phase 7: Dart Game Engine Port** — Complete pure-Dart port of all game rules with golden-fixture test validation (completed 2026-03-15)
- [x] **Phase 8: Bot Agents** — All three AI difficulty levels ported to Dart with isolate execution (completed 2026-03-15)
- [ ] **Phase 9: Riverpod Providers and Persistence** — State coordination layer with auto-save on app backgrounding
- [ ] **Phase 10: Map Widget** — Interactive territory map with CustomPainter rendering, pinch-zoom, and touch hit-testing
- [ ] **Phase 11: Screens, Widgets, and Mobile UX** — Complete game UI: setup, gameplay controls, sidebar, responsive layout, game over
- [ ] **Phase 12: Simulation Mode and Integration** — All-bot simulation mode wired end-to-end with performance validation

## Phase Details

### Phase 6: Flutter Scaffold and Data Models
**Goal**: A compiling Flutter project with all data models, dependencies, and the map graph in place so every subsequent phase can build on a stable foundation.
**Depends on**: Nothing (first v1.1 phase)
**Requirements**: DART-07
**Success Criteria** (what must be TRUE):
  1. `flutter run` produces a running app on both Android and iOS targets without build errors
  2. All `@freezed` models (`GameState`, `TerritoryState`, `PlayerState`, `Card`, `TurnPhase`) generate without errors and have working `copyWith`/equality
  3. `MapGraph` answers adjacency, BFS connectivity, and continent control queries correctly in unit tests
  4. ObjectBox and shared_preferences are configured and verified with a round-trip write/read test
  5. `map.json` is bundled as a Flutter asset and loads at startup with all 42 territories and adjacency edges present
**Plans**: 3 plans

Plans:
- [ ] 06-01-PLAN.md — Flutter project scaffold, dependencies, config files, test stubs
- [ ] 06-02-PLAN.md — @freezed data models, MapGraph BFS implementation, mapGraphProvider
- [ ] 06-03-PLAN.md — ObjectBox SaveSlot entity, AppStore, main.dart wiring, persistence tests

### Phase 7: Dart Game Engine Port
**Goal**: A pure-Dart game engine that faithfully replicates all Python game rules, validated by golden-fixture tests against the Python source so logic drift is caught before any UI is built.
**Depends on**: Phase 6
**Requirements**: DART-01, DART-02, DART-03, DART-04, DART-05, DART-06
**Success Criteria** (what must be TRUE):
  1. All golden fixtures (seeded Python game state → output JSON) pass against the Dart engine
  2. Combat statistics match Python within 0.5% over 10,000 simulated trials with injected seeded `Random`
  3. Blitz attack auto-resolves a conquest correctly and leaves the attacker with the minimum legal army count
  4. Card trading escalates bonus amounts in sequence and forces trade at 5+ cards, matching Python behavior
  5. Turn FSM correctly cycles reinforce → attack → fortify, handles player elimination, and detects victory
**Plans**: 5 plans

Plans:
- [ ] 07-01-PLAN.md — Wave 0 test infrastructure: 6 test stubs, FakeRandom helper, Python golden fixture generator
- [ ] 07-02-PLAN.md — actions.dart sealed hierarchy, combat.dart (DART-01 + DART-06), setup.dart, MapGraph.continentNames
- [ ] 07-03-PLAN.md — cards_engine.dart (DART-02), reinforcements.dart (DART-03), fortify.dart (DART-04)
- [ ] 07-04-PLAN.md — PlayerAgent abstract class, turn.dart FSM (DART-05)
- [ ] 07-05-PLAN.md — Run Python fixture generator, golden_fixture_test.dart validating Python-Dart parity

### Phase 8: Bot Agents
**Goal**: All three AI difficulty levels running in Dart isolates, producing win-rate statistics consistent with the Python bots and without blocking the UI thread.
**Depends on**: Phase 7
**Requirements**: BOTS-05, BOTS-06, BOTS-07, BOTS-08
**Success Criteria** (what must be TRUE):
  1. EasyAgent makes only legal random moves across all game phases (reinforce, attack, fortify)
  2. MediumAgent focuses reinforcements on continent borders and prioritizes continent completion in attacks
  3. HardAgent achieves a win rate within 5 percentage points of the Python HardAgent (baseline: ~80% vs Medium) over 500 simulated games
  4. Bot turns execute via `Isolate.run()` and the main isolate remains responsive (no UI frame drops) during bot computation
**Plans**: 3 plans

Plans:
- [ ] 08-01-PLAN.md — Wave 0 test stubs, EasyAgent (BOTS-05), runGame() simulation helper
- [ ] 08-02-PLAN.md — MediumAgent (BOTS-06), HardAgent (BOTS-07)
- [ ] 08-03-PLAN.md — Win rate statistical test, Isolate.run() boundary validation (BOTS-08)

### Phase 9: Riverpod Providers and Persistence
**Goal**: A fully wired state layer where `GameNotifier` owns canonical game state, all human and bot actions flow through it serially, and game state survives app backgrounding and cold restart.
**Depends on**: Phase 8
**Requirements**: SAVE-01, SAVE-02
**Success Criteria** (what must be TRUE):
  1. `GameNotifier` processes human moves and bot turns without race conditions under concurrent isolate callbacks
  2. Backgrounding the app (home button or phone call) saves current `GameState` to ObjectBox before the app is potentially killed
  3. Relaunching the app after backgrounding prompts the user to resume and restores the exact game state
  4. All notifier state transitions are covered by `ProviderContainer` unit tests
**Plans**: 3 plans

Plans:
- [ ] 09-01-PLAN.md — GameConfig + UIState models, Wave 0 test stubs, build_runner generation
- [ ] 09-02-PLAN.md — GameNotifier + UIStateNotifier implementation, ProviderContainer tests green
- [ ] 09-03-PLAN.md — HomeScreen provider wiring, human-verify lifecycle save/restore checkpoint

### Phase 10: Map Widget
**Goal**: An interactive territory map that renders all 42 territories with correct owner colors and army counts, supports pinch-zoom and pan, and correctly identifies which territory the user tapped — including in dense regions on small phone screens.
**Depends on**: Phase 9
**Requirements**: MAPW-01, MAPW-02, MAPW-03, MAPW-04, MAPW-05
**Success Criteria** (what must be TRUE):
  1. Pinch-zoom works smoothly from 1x to 4x and pan tracks finger position with no perceptible lag on mid-range Android hardware
  2. Tapping a territory selects it correctly across all zoom levels using coordinate-transformed hit testing
  3. All territories display their owner's color and current army count, updating immediately when game state changes
  4. Selected territory, valid attack/fortify sources, and valid targets are visually distinct from unselected territories
  5. Dense territories in Europe and SE Asia are tappable with a finger on a phone screen (6dp hit-region expansion; disambiguation popup when needed)
**Plans**: TBD

### Phase 11: Screens, Widgets, and Mobile UX
**Goal**: A complete, playable game UI from setup through game over, with responsive layout, accessible controls, and correct platform behavior on both iOS and Android.
**Depends on**: Phase 10
**Requirements**: MOBX-01, MOBX-02, MOBX-03, MOBX-04, MOBX-05, MOBX-06
**Success Criteria** (what must be TRUE):
  1. Player can configure player count, bot difficulty, and game mode from the setup screen and start a game
  2. The game is fully playable in portrait (map full-width, controls in bottom sheet) and landscape (map + side panel) without layout overflow or hidden controls
  3. All game actions — place armies, attack (single and blitz), end attack, skip fortify, trade cards — are accessible via on-screen controls and execute correctly
  4. The game log updates in real time showing attacks, conquests, eliminations, and card trades in readable form
  5. The game over screen appears when a player wins or the human is eliminated, shows the winner, and offers a new game option
**Plans**: TBD

### Phase 12: Simulation Mode and Integration
**Goal**: A fully functional AI-vs-AI simulation mode wired through the complete stack, with end-to-end integration validated and performance confirmed on target hardware.
**Depends on**: Phase 11
**Requirements**: BOTS-09
**Success Criteria** (what must be TRUE):
  1. Simulation mode runs a complete game from setup to victory using only bot players with no human input required
  2. The user can watch the simulation at configurable speeds (Slow/Fast/Instant) and tap any territory to inspect its state
  3. A complete simulated game runs start-to-finish without crashes, state corruption, or premature victory detection
  4. Performance on low-end Android (Pixel 3a equivalent) meets targets: 60fps during map zoom, under 16ms per bot turn, stable memory over a 20-game simulation run
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-03-08 |
| 2. Game Engine | v1.0 | 3/3 | Complete | 2026-03-08 |
| 3. Web UI and Game Setup | v1.0 | 4/4 | Complete | 2026-03-08 |
| 4. Easy and Medium Bots | v1.0 | 7/7 | Complete | 2026-03-09 |
| 5. Hard Bot and AI Simulation | v1.0 | 4/4 | Complete | 2026-03-14 |
| 6. Flutter Scaffold and Data Models | 3/3 | Complete   | 2026-03-15 | - |
| 7. Dart Game Engine Port | 5/5 | Complete   | 2026-03-15 | - |
| 8. Bot Agents | 3/3 | Complete   | 2026-03-15 | - |
| 9. Riverpod Providers and Persistence | 2/3 | In Progress|  | - |
| 10. Map Widget | v1.1 | 0/TBD | Not started | - |
| 11. Screens, Widgets, and Mobile UX | v1.1 | 0/TBD | Not started | - |
| 12. Simulation Mode and Integration | v1.1 | 0/TBD | Not started | - |
