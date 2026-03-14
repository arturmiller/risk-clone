# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-14
**Phases:** 5 | **Plans:** 20 | **Commits:** 100

### What Was Built
- Complete Risk game engine with all official rules (combat, cards, reinforcements, fortification)
- Interactive browser UI with SVG world map, WebSocket real-time gameplay
- Three AI difficulty levels (Easy random, Medium continent-focused, Hard multi-factor heuristic)
- AI-vs-AI simulation observation mode
- 238 automated tests covering all game systems

### What Worked
- Pydantic immutable state with model_copy made state transitions clean and debuggable
- TDD approach for bot strategies caught edge cases early
- Wave-based plan execution allowed parallel development of independent features
- NetworkX graph wrapper simplified territory connectivity queries

### What Was Inefficient
- Executor agents sometimes overwrote manual bug fixes (blitz handling, card recycling reverted by Phase 5 executor)
- Card recycling required multiple iterations (immediate recycle → deck-empty-only recycle) to balance gameplay
- Browser caching caused confusion during iterative UI fixes — needed cache-busting query params

### Patterns Established
- Cache-busting `?v=N` params on static assets for development
- `cloneNode(true)` pattern for replacing DOM elements with fresh event listeners
- BFS traversal for connected territory computation (both Python and JS)
- `model_dump(mode="json")` for Pydantic → WebSocket serialization

### Key Lessons
1. Executor subagents can silently revert working tree changes — always verify critical files after execution
2. Card recycling in deck-based games needs careful balance: recycle only when deck is empty to prevent inflation
3. Frontend state (DOM references, event handlers) is fragile — prefer rebuilding DOM sections over querySelector updates

### Cost Observations
- Model mix: ~70% sonnet (executors), ~30% opus (orchestration, debugging)
- Sessions: ~8 across 6 days
- Notable: Phase 4 had 7 plans due to TDD scaffold splitting — could consolidate in future

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Commits | Phases | Key Change |
|-----------|---------|--------|------------|
| v1.0 | 100 | 5 | Initial release, established GSD workflow patterns |

### Cumulative Quality

| Milestone | Tests | Key Metric |
|-----------|-------|------------|
| v1.0 | 238 | Hard bot 80% win rate vs Medium |

### Top Lessons (Verified Across Milestones)

1. Immutable state patterns prevent entire categories of bugs in game engines
2. Always verify subagent output against critical working tree changes
