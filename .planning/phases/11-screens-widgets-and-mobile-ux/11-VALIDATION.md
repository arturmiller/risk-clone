---
phase: 11
slug: screens-widgets-and-mobile-ux
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test (built-in) |
| **Config file** | mobile/pubspec.yaml |
| **Quick run command** | `cd mobile && flutter test test/screens/ test/widgets/` |
| **Full suite command** | `cd mobile && flutter test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mobile && flutter test test/screens/ test/widgets/`
- **After every plan wave:** Run `cd mobile && flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 11-01 | 01 | 1 | MOBX-01 | widget | `cd mobile && flutter test test/screens/setup_screen_test.dart` | ❌ W0 | ⬜ pending |
| 11-02 | 02 | 2 | MOBX-03 | widget | `cd mobile && flutter test test/screens/game_screen_test.dart` | ❌ W0 | ⬜ pending |
| 11-03 | 03 | 2 | MOBX-04, MOBX-05 | widget | `cd mobile && flutter test test/widgets/` | ❌ W0 | ⬜ pending |
| 11-04 | 04 | 3 | MOBX-02, MOBX-06 | widget | `cd mobile && flutter test test/screens/` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `mobile/test/screens/setup_screen_test.dart` — stubs
- [ ] `mobile/test/screens/game_screen_test.dart` — stubs
- [ ] `mobile/test/screens/game_over_screen_test.dart` — stubs

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Portrait/landscape layout | MOBX-02 | Requires device rotation | Rotate device, verify no overflow |
| Full game playthrough | MOBX-03 | End-to-end human interaction | Play a complete game from setup to win/loss |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
