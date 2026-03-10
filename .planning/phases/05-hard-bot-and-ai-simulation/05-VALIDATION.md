---
phase: 05
slug: hard-bot-and-ai-simulation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest (existing) |
| **Config file** | pyproject.toml (existing) |
| **Quick run command** | `python -m pytest tests/test_hard_agent.py tests/test_simulation.py -x -q` |
| **Full suite command** | `python -m pytest tests/ -x -q` |
| **Estimated runtime** | ~10 seconds (unit), ~60 seconds (batch) |

---

## Sampling Rate

- **After every task commit:** Run `python -m pytest tests/test_hard_agent.py tests/test_simulation.py -x -q`
- **After every plan wave:** Run `python -m pytest tests/ -x -q`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 0 | BOTS-03 | unit stubs | `python -m pytest tests/test_hard_agent.py -x` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 0 | BOTS-04 | integration stubs | `python -m pytest tests/test_simulation.py -x` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | BOTS-03 | unit | `python -m pytest tests/test_hard_agent.py::TestHardReinforce -x` | ❌ W0 | ⬜ pending |
| 05-02-02 | 02 | 1 | BOTS-03 | unit | `python -m pytest tests/test_hard_agent.py::TestHardAttack -x` | ❌ W0 | ⬜ pending |
| 05-02-03 | 02 | 1 | BOTS-03 | unit | `python -m pytest tests/test_hard_agent.py::TestHardCardTiming -x` | ❌ W0 | ⬜ pending |
| 05-02-04 | 02 | 1 | BOTS-03 | unit | `python -m pytest tests/test_hard_agent.py::TestHardThreat -x` | ❌ W0 | ⬜ pending |
| 05-03-01 | 03 | 1 | BOTS-04 | integration | `python -m pytest tests/test_simulation.py::TestSimulationMode -x` | ❌ W0 | ⬜ pending |
| 05-03-02 | 03 | 1 | BOTS-04 | integration | `python -m pytest tests/test_simulation.py::TestSimulationCompletion -x` | ❌ W0 | ⬜ pending |
| 05-04-01 | 04 | 2 | BOTS-03 | integration | `python -m pytest tests/test_hard_agent.py::TestHardBatch -x` | ❌ W0 | ⬜ pending |
| 05-04-02 | 04 | 2 | BOTS-03 | integration | `python -m pytest tests/test_hard_agent.py::TestHardFullGame -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_hard_agent.py` — stubs for BOTS-03 (unit + batch integration)
- [ ] `tests/test_simulation.py` — stubs for BOTS-04 (simulation mode integration)
- [ ] No new framework install needed — pytest already available

*Existing infrastructure covers framework requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Setup screen offers simulation mode option | BOTS-04 | Browser UI verification | Open setup screen, verify "AI vs AI" option appears in game mode selector |
| Simulation game plays visually to completion | BOTS-04 | Visual/UX verification | Start AI-vs-AI game, confirm turns animate and game_over overlay shows |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
