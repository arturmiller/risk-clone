---
phase: 04-easy-and-medium-bots
plan: 05
subsystem: bots
tags: [medium-bot, reinforcement, continent-strategy, tdd]

# Dependency graph
requires:
  - phase: 04-easy-and-medium-bots
    provides: MediumAgent implementation (plans 02-04)
provides:
  - Two-tier border selection in choose_reinforcement_placement (external-facing borders preferred)
  - Full test suite green with zero xfails in test_medium_agent.py
affects: [phase-05-hard-bot]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Two-tier border candidate selection: external_borders (enemy neighbors outside continent) preferred over cont_borders (any enemy neighbor within continent)

key-files:
  created: []
  modified:
    - risk/bots/medium.py
    - tests/test_medium_agent.py

key-decisions:
  - "external_borders filter: enemy neighbor must be outside cont_terrs AND not owned by player — correctly identifies Indonesia (Siam is outside Australia) vs New Guinea/Western Australia (Eastern Australia is inside Australia)"
  - "xfail marker removed only from TestMediumAgentReinforce; other classes retain strict=False xfail (XPASS is not an error)"

patterns-established:
  - "Continent border tiering: check if any non-player neighbor of a cont_border is outside cont_terrs to identify cross-continent-facing territories"

requirements-completed: [BOTS-02]

# Metrics
duration: 1min
completed: 2026-03-09
---

# Phase 4 Plan 05: Fix MediumAgent Reinforcement Border Selection Summary

**Two-tier continent border selection in MediumAgent.choose_reinforcement_placement: external-facing borders (enemy outside continent) preferred over internal cont_borders, fixing Indonesia selection over Western Australia in Australia scenario**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-09T20:52:51Z
- **Completed:** 2026-03-09T20:53:46Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Fixed choose_reinforcement_placement to compute `external_borders` — cont_borders whose enemy neighbor is outside the target continent's territory set
- Removed `@pytest.mark.xfail` from `TestMediumAgentReinforce` class; `test_reinforce_places_on_border_of_top_continent` now passes as a regular PASSED test
- Full test suite: 220 passed, 13 xpassed, 0 xfailed, exit 0 — zero regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix choose_reinforcement_placement to prefer external-facing borders** - `9c6c175` (feat)
2. **Task 2: Confirm full suite green with zero remaining xfails** - verification only, no commit needed

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `risk/bots/medium.py` - Added `cont_terrs` and `external_borders` two-tier filter inside `cont_borders` branch; replaced `min(cont_borders, ...)` with `min(final_candidates, ...)`
- `tests/test_medium_agent.py` - Removed `@pytest.mark.xfail(reason="MediumAgent not yet implemented", strict=False)` decorator from `TestMediumAgentReinforce` class

## Decisions Made
- The `external_borders` filter checks: for each territory in `cont_borders`, does any of its enemy-owned neighbors fall outside `cont_terrs`? This correctly handles the Australia scenario where Indonesia borders Siam (outside Australia) but New Guinea and Western Australia only border Eastern Australia (inside Australia).
- Retained `xfail(strict=False)` on `TestDifficultyWiring`, `TestMediumAgentAttack`, `TestMediumAgentFortify`, and `TestFullGameIntegration` — these all XPASS which is acceptable under strict=False.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- BOTS-02 requirement fully satisfied: MediumAgent visibly pursues continent control by reinforcing at the strategic external-facing border
- Phase 4 verification gap closed — all test_medium_agent.py tests pass without xfail markers on the reinforce class
- Phase 5 (Hard bot) can begin; no blockers

---
*Phase: 04-easy-and-medium-bots*
*Completed: 2026-03-09*
