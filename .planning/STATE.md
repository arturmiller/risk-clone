---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Mobile App
status: completed
stopped_at: Completed 09-03-PLAN.md
last_updated: "2026-03-15T19:52:52.577Z"
last_activity: 2026-03-15 — Phase 9 Plan 02 complete; GameNotifier + UIStateNotifier providers + 14 ProviderContainer tests — 157/157 tests green, SAVE-01 and SAVE-02 implemented
progress:
  total_phases: 7
  completed_phases: 4
  total_plans: 14
  completed_plans: 14
  percent: 97
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** AI bots that provide a challenging and fun single-player experience, with the hardest difficulty playing at human-competitive level.
**Current focus:** Phase 9 — Riverpod Providers and Persistence

## Current Position

Phase: 9 (Riverpod Providers and Persistence) — In Progress
Plan: 2 of 3 complete
Status: Plan 02 complete — GameNotifier + UIStateNotifier providers + 14 ProviderContainer tests
Last activity: 2026-03-15 — Phase 9 Plan 02 complete; GameNotifier + UIStateNotifier providers + 14 ProviderContainer tests — 157/157 tests green, SAVE-01 and SAVE-02 implemented

Progress: [██████████] 97% (v1.1)

## Accumulated Context

### Decisions

- [v1.0]: Python/FastAPI + vanilla JS shipped with 80% HardAgent win rate vs Medium
- [v1.1]: Eliminate client-server architecture; pure Dart on-device engine
- [v1.1]: Flutter 3.41 + Riverpod 3.x (AsyncNotifier) + freezed + ObjectBox (see research/SUMMARY.md)
- [v1.1]: Engine validated with golden fixtures before any UI is wired (prevents logic drift)
- [v1.1]: Bot isolate architecture established in Phase 8, not retrofitted later
- [06-01]: riverpod_generator: ^4.0.3 (not ^2.6.0 from STACK.md) — Riverpod 3.x requires 4.x generator
- [06-01]: objectbox_flutter_libs: any (not path dep) — pub.dev package, no download-libs command
- [06-01]: cards field uses Map<String, List<Card>> not Map<int, List<Card>> — JSON keys must be strings
- [06-01]: classic.json copied (not symlinked) to mobile/assets/ — symlinks unreliable on Windows
- [Phase 06]: objectbox.g.dart generated into lib/ not project root; import path '../objectbox.g.dart' from lib/persistence/ is correct
- [Phase 06]: ObjectBox @Entity classes require plain Dart mutable fields — cannot use freezed
- [Phase 06]: freezed 3.x requires abstract class declaration — plain class causes compiler errors for missing mixin implementations
- [07-01]: Test stubs use commented imports (// ignore_for_file: unused_import) — compiles cleanly before implementation files exist
- [07-01]: FakeRandom returns (value-1) for nextInt(max) — nextInt(6)+1 == die face value
- [07-01]: golden_turn_sequence.json uses check_victory/check_elimination directly (no full FSM needed for Wave 0)
- [Phase 07-03]: Dart records used for executeTrade return: (GameState, int, Map<String,int>) — avoids ad-hoc result class
- [Phase 07-03]: continentNames getter added to map_graph.dart now (Plan 02 planned addition) — unblocked reinforcements.dart
- [Phase 07-03]: String key pattern enforced: cards[playerIndex.toString()] throughout cards_engine.dart
- [Phase 07]: Statistical tests use 100000 trials (not 10000) — 10k with seed 42 gave 0.3659 vs 0.3717 target, outside 0.5% tolerance; 100k converges reliably
- [Phase 07]: validateAttack throws ArgumentError (not ValueError) — idiomatic Dart uses ArgumentError for invalid argument preconditions
- [07-04]: FakeRandom.attackerWins() uses [5,5,5,0,0] sequence — attacker dice=6, defender dice=1, deterministic blitz conquest in tests
- [07-04]: executeTurn takes Map<int, PlayerAgent> agents (indexed by player index) — supports multi-player game loop
- [07-04]: PlayerAgent abstract class (5 methods) is the Phase 8/9 seam — bots implement it, HumanAgent wires through Riverpod
- [07-05]: Fixtures embed full GameState JSON (state_to_dart_json) — Dart uses GameState.fromJson() directly, no state reconstruction
- [07-05]: Fixture target_armies must match intended defender dice count — Python's defender_dice override not passed to Dart engine
- [07-05]: golden_fixture_test.dart iterates fixtures in single parametric test per group — Flutter test dynamic registration limitation
- [08-01]: EasyAgent uses nextInt(2)==1 for 50% fortify skip — Python rng.random() replaced for FakeRandom compatibility (FakeRandom throws on nextDouble)
- [08-01]: EasyAgent uses nextInt(100)<15 for 15% attack abort — same reason; FakeRandom-safe API requires nextInt() variants only in bot logic
- [08-01]: simulation.dart uses Fisher-Yates shuffle inline to consume the provided rng parameter
- [Phase 08-bot-agents]: attackProbabilities and _estimateWinProbability placed at file scope (not class scope) for Isolate.run() compatibility
- [Phase 08-bot-agents]: MediumAgent/HardAgent tests are deterministic without FakeRandom — all choices are pure logic (unlike EasyAgent which shuffles/skips randomly)
- [Phase 08-bot-agents]: win_rate_test.dart: File('assets/classic.json') path used — flutter test cwd is mobile/; Isolate.run() boundary confirmed for freezed GameState + MapGraph without JSON round-trip
- [Phase 09-01]: UIState includes validSources alongside validTargets — map widget (Phase 10) needs both attack source and target highlighting without extra provider queries
- [Phase 09-01]: GameConfig is plain Dart (not freezed) — one-shot parameter object, never stored or compared for equality
- [Phase 09-02]: Generated provider names are gameProvider/uIStateProvider (not gameNotifierProvider/uIStateNotifierProvider) — Riverpod 3.x generator strips Notifier suffix
- [Phase 09-02]: ref.mounted guard required after Isolate.run — isAutoDispose provider can dispose during async Isolate gap
- [Phase 09-02]: saveNow() public method added as test seam for AppLifecycleListener._saveState() (lifecycle not triggerable in unit tests)
- [Phase 09-03]: HomeScreen uses gameProvider (Riverpod 3.x generated name) not gameNotifierProvider
- [Phase 09-03]: Human lifecycle test deferred to Phase 11 — SAVE-01/SAVE-02 validated by 14 ProviderContainer unit tests with real ObjectBox

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 10 flagged for research: CustomPainter + InteractiveViewer has known Flutter perf regression (#72066); pre-rasterization approach needs prototyping before coding.
- Phase 6 blocker RESOLVED: objectbox_flutter_libs: any (pub.dev package) — no download-libs needed.
- Phase 7: Dart `Random` != Python Mersenne Twister — golden fixtures must capture output states, not replay random draws.
- Flutter SDK installed at /home/amiller/flutter-sdk/flutter — not in system PATH; add `export PATH="/home/amiller/flutter-sdk/flutter/bin:$PATH"` to .bashrc

## Session Continuity

Last session: 2026-03-15T19:52:52.563Z
Stopped at: Completed 09-03-PLAN.md
Resume file: None
