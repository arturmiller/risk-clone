---
phase: 05-hard-bot-and-ai-simulation
plan: 02
subsystem: ai
tags: [hard-bot, heuristic-ai, risk-strategy, tdd, multi-factor-scoring, border-security-ratio]

# Dependency graph
requires:
  - phase: 05-hard-bot-and-ai-simulation
    provides: HardAgent skeleton, ATTACK_PROBABILITIES constants, test stubs with xfail markers
  - phase: 04-easy-and-medium-bots
    provides: MediumAgent pattern, PlayerAgent protocol, run_game, MapGraph API
provides:
  - Full HardAgent with multi-factor heuristic scoring (548 lines)
  - BSR-based reinforcement, multi-priority attack, strategic card timing
  - Context-aware army advancement and interior-to-border fortification
  - Win probability estimation from precomputed dice probabilities
  - All 15 tests passing including 100-game batch (Hard >= 55% vs Medium)
affects: [05-03 simulation-mode, 05-04 tuning-and-polish]

# Tech tracking
tech-stack:
  added: []
  patterns: [multi-factor territory scoring, border security ratio, opponent threat assessment, geometric win probability estimation]

key-files:
  created: []
  modified:
    - risk/bots/hard.py
    - tests/test_hard_agent.py

key-decisions:
  - "Win probability uses geometric approximation from per-roll expected losses rather than Monte Carlo simulation"
  - "Block-opponent-continent check uses territory count threshold (N-2 or 50%+) rather than exact all-but-1 match"
  - "Army preservation check requires at least one viable attack (3+ armies and advantage) rather than aggregate BSR threshold"
  - "Reinforcement splits 2/3 on most vulnerable, 1/3 on second when > 3 armies available"

patterns-established:
  - "Multi-factor scoring: BSR * weight + continent_score for reinforce placement ranking"
  - "Attack priority chain: continent-complete > block-opponent > probability-scored > overwhelming force"
  - "_estimate_win_probability() as reusable probability calculator for attack decisions"

requirements-completed: [BOTS-03]

# Metrics
duration: 6min
completed: 2026-03-10
---

# Phase 5 Plan 2: HardAgent Multi-Factor Strategy Summary

**Full HardAgent with BSR-based reinforcement, 4-priority attack chain, strategic card timing, and context-aware advancement beating Medium 55%+ in 100-game batch**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-10T19:59:29Z
- **Completed:** 2026-03-10T20:05:29Z
- **Tasks:** 2 (TDD: RED + GREEN)
- **Files modified:** 2

## Accomplishments
- Replaced HardAgent skeleton with full multi-factor heuristic scoring (548 lines)
- All 15 HardAgent tests passing: reinforce concentration, attack priorities, card timing, threat assessment, army advancement, full game, batch validation
- Hard bot wins >= 55% against Medium in 100-game batch, and >= 70% against Random in 20-game batch
- Win probability estimation from precomputed ATTACK_PROBABILITIES using geometric approximation

## Task Commits

Each task was committed atomically:

1. **Task 1: RED - Remove xfail markers** - `6ddcdc5` (test)
2. **Task 2: GREEN - Implement all strategy methods** - `84661e4` (feat)

## Files Created/Modified
- `risk/bots/hard.py` - Full HardAgent implementation with 8 strategy methods and 4 private helpers
- `tests/test_hard_agent.py` - Removed all 7 xfail markers; all tests now exercised directly

## Decisions Made
- Win probability uses geometric approximation (expected losses per roll) rather than Monte Carlo -- fast and deterministic
- Block-opponent-continent uses a relaxed threshold (opponent owns >= N-2 territories and >= 50% of continent) to catch near-complete scenarios where bot owns a blocking territory
- Army preservation check is per-attack-viable (need 3+ armies and advantage on at least one front) rather than aggregate BSR -- prevents false negatives when bot has concentrated force on one territory
- Reinforcement splits 2/3 + 1/3 across top 2 vulnerable borders when armies > 3; single target otherwise

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed army preservation threshold false negative**
- **Found during:** Task 2 (GREEN - attack implementation)
- **Issue:** Aggregate BSR threshold incorrectly prevented attacks when bot had concentrated force on 1 territory (8 armies) vs weak defenders (2 each)
- **Fix:** Changed to per-attack viability check: requires at least one territory with 3+ armies and army advantage over a neighbor
- **Files modified:** risk/bots/hard.py
- **Verification:** test_blocks_opponent_continent now passes
- **Committed in:** 84661e4

**2. [Rule 1 - Bug] Fixed _blocks_opponent_continent logic**
- **Found during:** Task 2 (GREEN - attack implementation)
- **Issue:** Original check required opponent to own all territories except the target -- failed when bot owned a blocking territory in the same continent
- **Fix:** Changed to count-based: opponent owns >= N-2 and >= 50% of continent territories
- **Files modified:** risk/bots/hard.py
- **Verification:** test_blocks_opponent_continent passes with South America scenario
- **Committed in:** 84661e4

**3. [Rule 1 - Bug] Fixed _estimate_win_probability edge cases**
- **Found during:** Task 2 (GREEN - full game integration test)
- **Issue:** KeyError when defender armies reached 0 during simulation (int(0) = invalid dice count), and IndexError accessing 3-tuple for 2-tuple probability entry
- **Fix:** Clamp dice counts to min 1, use len(probs) check instead of def_dice for tuple format detection
- **Files modified:** risk/bots/hard.py
- **Verification:** test_completes_game_without_crash passes
- **Committed in:** 84661e4

---

**Total deviations:** 3 auto-fixed (3 bugs)
**Impact on plan:** All fixes necessary for correctness. No scope creep.

## Issues Encountered
None beyond the auto-fixed bugs above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- HardAgent fully functional and tested; ready for simulation mode integration (Plan 03)
- Batch testing infrastructure proven (100-game Hard vs Medium validation)
- Full test suite green: 239 passed, 13 xpassed (simulation stubs from Plan 01)

---
*Phase: 05-hard-bot-and-ai-simulation*
*Completed: 2026-03-10*

## Self-Check: PASSED
