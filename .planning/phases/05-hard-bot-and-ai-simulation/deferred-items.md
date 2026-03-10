# Deferred Items - Phase 05

## Pre-existing Test Failures (HardAgent - Plan 05-02 scope)

1. **test_blocks_opponent_continent** - HardAgent skeleton doesn't implement continent-blocking attack logic yet
2. **test_completes_game_without_crash** - KeyError in `_estimate_win_probability` when `d` reaches 0 before the `d <= 0` check (key `(N, 0)` not in ATTACK_PROBABILITIES)
3. **test_hard_vs_random_wins** - Same KeyError as above

Root cause: `_estimate_win_probability` in `risk/bots/hard.py` can produce `def_dice = min(2, int(d))` where `d` has been decremented to 0 by float arithmetic, yielding key `(N, 0)` which is not in the lookup table. The `d <= 0` check at loop top doesn't catch fractional values that round to 0 for `int(d)`.

These are all plan 05-02 scope and will be fixed when HardAgent strategy is fully implemented.
