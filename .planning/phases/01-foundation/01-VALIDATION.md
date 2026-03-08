---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.x |
| **Config file** | none — Wave 0 creates pyproject.toml |
| **Quick run command** | `pytest tests/ -x -q` |
| **Full suite command** | `pytest tests/ -v` |
| **Estimated runtime** | ~2 seconds |

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
| 01-01-01 | 01 | 0 | MAPV-01 | unit | `pytest tests/test_map_data.py -x` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 0 | SETUP-02 | unit | `pytest tests/test_setup.py -x` | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 0 | SETUP-03 | unit | `pytest tests/test_setup.py -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pyproject.toml` — project config with pytest settings and dependencies
- [ ] `tests/conftest.py` — shared fixtures (loaded map data, built graph, sample game state)
- [ ] `tests/test_map_data.py` — validates classic.json: all 42 territories, all edges, continent membership
- [ ] `tests/test_map_graph.py` — tests adjacency queries, reachability, continent control
- [ ] `tests/test_game_state.py` — tests Pydantic model validation
- [ ] `tests/test_setup.py` — tests territory distribution and army placement

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
