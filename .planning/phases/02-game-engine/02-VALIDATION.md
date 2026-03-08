---
phase: 2
slug: game-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest >=8.0 |
| **Config file** | pyproject.toml [tool.pytest.ini_options] |
| **Quick run command** | `pytest tests/ -x -q` |
| **Full suite command** | `pytest tests/ -v` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `pytest tests/ -x -q`
- **After every plan wave:** Run `pytest tests/ -v`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | ENGI-01 | unit | `pytest tests/test_reinforcements.py -x` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | ENGI-02 | unit | `pytest tests/test_combat.py::test_single_combat -x` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 1 | ENGI-03 | unit | `pytest tests/test_combat.py::test_blitz -x` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 1 | ENGI-04 | unit | `pytest tests/test_fortify.py -x` | ❌ W0 | ⬜ pending |
| 02-01-05 | 01 | 1 | ENGI-05 | unit | `pytest tests/test_cards.py::test_card_earning -x` | ❌ W0 | ⬜ pending |
| 02-01-06 | 01 | 1 | ENGI-06 | unit | `pytest tests/test_cards.py::test_card_trading -x` | ❌ W0 | ⬜ pending |
| 02-01-07 | 01 | 1 | ENGI-07 | unit | `pytest tests/test_cards.py::test_forced_trade -x` | ❌ W0 | ⬜ pending |
| 02-01-08 | 01 | 1 | ENGI-08 | unit+integration | `pytest tests/test_turn.py::test_elimination_card_transfer -x` | ❌ W0 | ⬜ pending |
| 02-01-09 | 01 | 1 | ENGI-09 | unit | `pytest tests/test_turn.py::test_victory -x` | ❌ W0 | ⬜ pending |
| 02-E2E | 01 | 1 | E2E | integration | `pytest tests/test_full_game.py -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_reinforcements.py` — stubs for ENGI-01
- [ ] `tests/test_combat.py` — stubs for ENGI-02, ENGI-03
- [ ] `tests/test_cards.py` — stubs for ENGI-05, ENGI-06, ENGI-07
- [ ] `tests/test_fortify.py` — stubs for ENGI-04
- [ ] `tests/test_turn.py` — stubs for ENGI-08, ENGI-09
- [ ] `tests/test_full_game.py` — E2E full game simulation
- [ ] `tests/conftest.py` update — mid-game state fixtures, seeded RNG fixtures

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
