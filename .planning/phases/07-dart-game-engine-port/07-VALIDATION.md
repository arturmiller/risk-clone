---
phase: 07
slug: dart-game-engine-port
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | dart test (built-in) |
| **Config file** | mobile/pubspec.yaml |
| **Quick run command** | `cd mobile && dart test test/engine/` |
| **Full suite command** | `cd mobile && dart test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mobile && dart test test/engine/`
- **After every plan wave:** Run `cd mobile && dart test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | DART-01 | unit | `cd mobile && dart test test/engine/combat_test.dart` | ❌ W0 | ⬜ pending |
| 07-01-02 | 01 | 1 | DART-06 | unit | `cd mobile && dart test test/engine/combat_test.dart` | ❌ W0 | ⬜ pending |
| 07-02-01 | 02 | 1 | DART-02, DART-03 | unit | `cd mobile && dart test test/engine/cards_test.dart test/engine/reinforcements_test.dart` | ❌ W0 | ⬜ pending |
| 07-02-02 | 02 | 1 | DART-04 | unit | `cd mobile && dart test test/engine/fortify_test.dart` | ❌ W0 | ⬜ pending |
| 07-03-01 | 03 | 2 | DART-05 | unit | `cd mobile && dart test test/engine/turn_test.dart` | ❌ W0 | ⬜ pending |
| 07-03-02 | 03 | 2 | DART-05 | golden | `cd mobile && dart test test/engine/golden_fixture_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mobile/test/engine/combat_test.dart` — stubs for combat resolution and blitz
- [ ] `mobile/test/engine/cards_test.dart` — stubs for card system
- [ ] `mobile/test/engine/reinforcements_test.dart` — stubs for reinforcement calculation
- [ ] `mobile/test/engine/fortify_test.dart` — stubs for fortification
- [ ] `mobile/test/engine/turn_test.dart` — stubs for turn FSM
- [ ] `mobile/test/engine/golden_fixture_test.dart` — stubs for golden fixture validation
- [ ] `mobile/test/helpers/fake_random.dart` — FakeRandom helper for deterministic tests

---

## Manual-Only Verifications

None — all phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
