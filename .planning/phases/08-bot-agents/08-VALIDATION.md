---
phase: 08
slug: bot-agents
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | dart test (built-in) |
| **Config file** | mobile/pubspec.yaml |
| **Quick run command** | `cd mobile && dart test test/bots/` |
| **Full suite command** | `cd mobile && dart test` |
| **Estimated runtime** | ~30 seconds (includes batch statistical tests) |

---

## Sampling Rate

- **After every task commit:** Run `cd mobile && dart test test/bots/`
- **After every plan wave:** Run `cd mobile && dart test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | BOTS-05 | unit | `cd mobile && dart test test/bots/easy_agent_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-01 | 02 | 2 | BOTS-06 | unit | `cd mobile && dart test test/bots/medium_agent_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-02 | 02 | 2 | BOTS-07 | unit+batch | `cd mobile && dart test test/bots/hard_agent_test.dart` | ❌ W0 | ⬜ pending |
| 08-03-01 | 03 | 3 | BOTS-08 | unit | `cd mobile && dart test test/bots/isolate_test.dart` | ❌ W0 | ⬜ pending |
| 08-03-02 | 03 | 3 | — | integration | `cd mobile && dart test test/engine/simulation_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mobile/test/bots/easy_agent_test.dart` — stubs for EasyAgent
- [ ] `mobile/test/bots/medium_agent_test.dart` — stubs for MediumAgent
- [ ] `mobile/test/bots/hard_agent_test.dart` — stubs for HardAgent + batch test
- [ ] `mobile/test/bots/isolate_test.dart` — stubs for Isolate.run() verification
- [ ] `mobile/test/engine/simulation_test.dart` — stubs for runGame() simulation

---

## Manual-Only Verifications

None — all phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
