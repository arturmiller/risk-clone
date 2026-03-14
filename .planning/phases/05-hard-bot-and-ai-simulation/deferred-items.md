# Deferred Items - Phase 05

## Pre-existing Test Failures (HardAgent - Plan 05-02 scope)

1. **test_blocks_opponent_continent** - HardAgent skeleton doesn't implement continent-blocking attack logic yet
2. **test_completes_game_without_crash** - KeyError in `_estimate_win_probability` when `d` reaches 0 before the `d <= 0` check (key `(N, 0)` not in ATTACK_PROBABILITIES)
3. **test_hard_vs_random_wins** - Same KeyError as above

Root cause: `_estimate_win_probability` in `risk/bots/hard.py` can produce `def_dice = min(2, int(d))` where `d` has been decremented to 0 by float arithmetic, yielding key `(N, 0)` which is not in the lookup table. The `d <= 0` check at loop top doesn't catch fractional values that round to 0 for `int(d)`.

These are all plan 05-02 scope and will be fixed when HardAgent strategy is fully implemented.

## Reverted Engine Changes (Plan 05-04 execution)

During plan 05-04 execution, the working tree contained uncommitted changes to:
- `risk/engine/cards.py`: Card recycling feature (traded cards returned to deck using non-seeded `random.shuffle`)
- `risk/engine/turn.py`: BlitzAction support and advance bounds fix

The `cards.py` change caused game-breaking army explosion: with recycled cards, players accumulated infinite armies via card trading, causing 3-player games to exceed 5000 turns (never completing). These changes were reverted (`git checkout -- risk/engine/cards.py risk/engine/turn.py`).

These changes should be reviewed and fixed before re-applying:
1. `cards.py`: Use seeded RNG (passed as parameter) instead of global `random.shuffle`
2. Verify the card recycling mechanic doesn't cause unbounded army growth
3. `turn.py`: BlitzAction support looks correct but needs the card fix first
