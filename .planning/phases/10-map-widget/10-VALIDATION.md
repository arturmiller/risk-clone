---
phase: 10
slug: map-widget
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test (built-in) |
| **Config file** | mobile/pubspec.yaml |
| **Quick run command** | `cd mobile && flutter test test/widgets/` |
| **Full suite command** | `cd mobile && flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mobile && flutter test test/widgets/`
- **After every plan wave:** Run `cd mobile && flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | MAPW-01 | widget | `cd mobile && flutter test test/widgets/map_widget_test.dart` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | MAPW-03 | widget | `cd mobile && flutter test test/widgets/map_widget_test.dart` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 2 | MAPW-02, MAPW-04 | widget | `cd mobile && flutter test test/widgets/map_interaction_test.dart` | ❌ W0 | ⬜ pending |
| 10-02-02 | 02 | 2 | MAPW-05 | widget | `cd mobile && flutter test test/widgets/map_interaction_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mobile/test/widgets/map_widget_test.dart` — stubs for rendering, zoom, colors, army counts
- [ ] `mobile/test/widgets/map_interaction_test.dart` — stubs for tap selection, highlighting, hit-test expansion

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Smooth pinch-zoom on mid-range Android | MAPW-01 | Requires physical device GPU | flutter run on device, pinch-zoom map |
| Dense territory tap on phone screen | MAPW-05 | Requires physical touch input | Tap European territories on phone |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
