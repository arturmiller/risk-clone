---
phase: 3
slug: web-ui-and-game-setup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest >= 8.0 |
| **Config file** | `pyproject.toml [tool.pytest.ini_options]` |
| **Quick run command** | `pytest tests/test_server.py -x --timeout=10` |
| **Full suite command** | `pytest tests/ --timeout=30` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `pytest tests/test_server.py -x --timeout=10`
- **After every plan wave:** Run `pytest tests/ --timeout=30`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SETUP-01 | integration | `pytest tests/test_server.py::test_start_game_creates_correct_players -x` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | MAPV-02 | unit | `pytest tests/test_server.py::test_state_serialization_includes_owners -x` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | MAPV-03 | unit | `pytest tests/test_server.py::test_state_serialization_includes_armies -x` | ❌ W0 | ⬜ pending |
| 03-01-04 | 01 | 1 | MAPV-04 | unit | `pytest tests/test_server.py::test_action_message_parsing -x` | ❌ W0 | ⬜ pending |
| 03-01-05 | 01 | 1 | MAPV-05 | unit | `pytest tests/test_server.py::test_state_includes_phase_and_player -x` | ❌ W0 | ⬜ pending |
| 03-01-06 | 01 | 1 | MAPV-06 | integration | `pytest tests/test_server.py::test_game_events_emitted -x` | ❌ W0 | ⬜ pending |
| 03-01-07 | 01 | 1 | MAPV-07 | unit | `pytest tests/test_server.py::test_continent_data_in_messages -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_server.py` — stubs for SETUP-01, MAPV-02 through MAPV-07 (server-side logic)
- [ ] `tests/test_human_agent.py` — covers HumanWebSocketAgent queue bridging
- [ ] `tests/test_messages.py` — covers WebSocket message serialization/deserialization
- [ ] Framework install: `pip install fastapi uvicorn[standard] httpx pytest-asyncio`
- [ ] `pytest-asyncio` — needed for async test functions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| SVG map renders with correct territory colors | MAPV-02 | Visual rendering in browser | Open browser, start game, verify each territory colored by owner |
| Territory click interaction works | MAPV-04 | Browser DOM interaction | Click source territory, verify highlight; click target, verify action sent |
| Turn phase stepper displays correctly | MAPV-05 | Visual UI element | Verify sidebar shows Reinforce→Attack→Fortify with active highlighted |
| Game log scrolls and shows events | MAPV-06 | Visual scrolling behavior | Play through attacks, verify log entries appear and scroll |
| Continent bonus sidebar is readable | MAPV-07 | Visual layout | Verify bonus values and territory counts display per continent |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
