---
phase: 06
slug: flutter-scaffold-and-data-models
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | dart test (built-in) |
| **Config file** | mobile/pubspec.yaml |
| **Quick run command** | `cd mobile && dart test` |
| **Full suite command** | `cd mobile && dart test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mobile && dart test`
- **After every plan wave:** Run `cd mobile && dart test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | DART-07 | unit | `cd mobile && dart test test/models/` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | DART-07 | unit | `cd mobile && dart test test/engine/map_graph_test.dart` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | — | integration | `cd mobile && dart test test/persistence/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mobile/test/models/game_state_test.dart` — stubs for freezed model tests
- [ ] `mobile/test/engine/map_graph_test.dart` — stubs for MapGraph BFS/adjacency tests
- [ ] `mobile/test/persistence/objectbox_test.dart` — stubs for ObjectBox round-trip test

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App compiles and runs | — | Requires emulator/device | `flutter run` on Android and iOS targets |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
