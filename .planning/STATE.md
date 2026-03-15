---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Mobile App
status: executing
stopped_at: Completed 07-02-PLAN.md
last_updated: "2026-03-15T06:53:53.380Z"
last_activity: 2026-03-15 — Phase 7 Plan 01 complete; Wave 0 test infrastructure — 59 test stubs, FakeRandom, golden fixtures
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 8
  completed_plans: 6
  percent: 86
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** AI bots that provide a challenging and fun single-player experience, with the hardest difficulty playing at human-competitive level.
**Current focus:** Phase 7 — Dart Game Engine Port

## Current Position

Phase: 7 of 7 (Dart Game Engine Port)
Plan: 1 of 4 in current phase (complete)
Status: In progress
Last activity: 2026-03-15 — Phase 7 Plan 01 complete; Wave 0 test infrastructure — 59 test stubs, FakeRandom, golden fixtures

Progress: [████████░░] 86% (v1.1)

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

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 10 flagged for research: CustomPainter + InteractiveViewer has known Flutter perf regression (#72066); pre-rasterization approach needs prototyping before coding.
- Phase 6 blocker RESOLVED: objectbox_flutter_libs: any (pub.dev package) — no download-libs needed.
- Phase 7: Dart `Random` != Python Mersenne Twister — golden fixtures must capture output states, not replay random draws.
- Flutter SDK installed at /home/amiller/flutter-sdk/flutter — not in system PATH; add `export PATH="/home/amiller/flutter-sdk/flutter/bin:$PATH"` to .bashrc

## Session Continuity

Last session: 2026-03-15T06:53:53.373Z
Stopped at: Completed 07-02-PLAN.md
Resume file: None
