---
phase: 4
slug: easy-and-medium-bots
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-09
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest (existing) |
| **Config file** | none — runs via `python -m pytest tests/` |
| **Quick run command** | `python -m pytest tests/test_medium_agent.py -x -q` |
| **Full suite command** | `python -m pytest tests/ -x -q` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `python -m pytest tests/test_medium_agent.py -x -q`
- **After every plan wave:** Run `python -m pytest tests/ -x -q`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 0 | BOTS-01, BOTS-02 | unit+integration | `python -m pytest tests/test_medium_agent.py -x -q` | ❌ W0 | ⬜ pending |
| 4-02-01 | 02 | 1 | BOTS-01 | unit | `python -m pytest tests/test_medium_agent.py::TestDifficultyWiring::test_easy_creates_random_agent -x` | ❌ W0 | ⬜ pending |
| 4-02-02 | 02 | 1 | BOTS-02 | unit | `python -m pytest tests/test_medium_agent.py::TestDifficultyWiring::test_medium_creates_medium_agent -x` | ❌ W0 | ⬜ pending |
| 4-03-01 | 03 | 1 | BOTS-02 | unit | `python -m pytest tests/test_medium_agent.py::TestMediumAgentReinforce -x` | ❌ W0 | ⬜ pending |
| 4-03-02 | 03 | 1 | BOTS-02 | unit | `python -m pytest tests/test_medium_agent.py::TestMediumAgentAttack -x` | ❌ W0 | ⬜ pending |
| 4-03-03 | 03 | 1 | BOTS-02 | unit | `python -m pytest tests/test_medium_agent.py::TestMediumAgentFortify -x` | ❌ W0 | ⬜ pending |
| 4-04-01 | 04 | 2 | BOTS-01, BOTS-02 | integration | `python -m pytest tests/test_medium_agent.py::TestFullGameIntegration -x` | ❌ W0 | ⬜ pending |
| 4-04-02 | 04 | 2 | BOTS-01, BOTS-02 | unit | `python -m pytest tests/test_messages.py -x -q` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_medium_agent.py` — stubs for all BOTS-01/BOTS-02 tests (wiring, unit strategy, integration)
- [ ] `risk/bots/__init__.py` — package init (if `risk/bots/` directory created)

*Framework already installed — no new dependencies needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Difficulty dropdown appears on setup screen | BOTS-01, BOTS-02 | Browser UI element | Open http://localhost:8000, verify dropdown shows Easy/Medium options |
| Medium bot visibly pursues continent control | BOTS-02 | Observable strategic behavior | Play a 3-player game, watch bot reinforce and attack to complete continents |
| Mix of Easy/Medium bots playable together | BOTS-01, BOTS-02 | End-to-end browser test | Select Medium, start 4-player game, play to completion |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
