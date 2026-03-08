# Project Research Summary

**Project:** Risk Strategy Game
**Domain:** Turn-based strategy board game with AI opponents (browser-based)
**Researched:** 2026-03-08
**Confidence:** HIGH

## Executive Summary

This is a browser-based implementation of the classic Risk board game where a single human player competes against 1-5 AI bots of configurable difficulty. The proven approach for this type of game is a server-authoritative architecture: Python owns all game state and rules, the browser is a thin rendering layer connected via WebSocket, and the game loop is driven by an explicit finite state machine (FSM) that manages turn phases. The technology choices are straightforward and high-confidence -- FastAPI for the async server, SVG for the territory map, NetworkX for the adjacency graph, and NumPy for vectorized dice simulation.

The core technical challenge is not the web stack or the UI -- it is building AI bots that produce fun, competitive games. Risk's decision space is enormous (estimated state space ~2^42), making tree-search approaches infeasible. The established approach from academic literature is heuristic evaluation: bots score possible actions using weighted factors like continent control progress, border security ratios, and threat assessment. The three difficulty tiers (Easy, Medium, Hard) should be implemented incrementally, with Easy using random valid moves, Medium using basic heuristics, and Hard using tuned strategic evaluation with Monte Carlo combat simulation.

The biggest risks are: (1) incorrect territory adjacency data silently breaking the entire game -- the classic Risk map has 83 edges including non-obvious cross-ocean routes, and even Hasbro shipped an edition with a missing connection; (2) AI that produces endless, boring games through excessive passivity or self-destructive aggression; and (3) the card trading system, which is the most rules-complex part of Risk with subtle edge cases around global escalation tracking, forced trades, and elimination card transfers. All three are mitigated through rigorous automated testing: statistical validation of dice probabilities, graph property assertions for adjacency data, and headless AI-vs-AI batch games to detect stalemate patterns before they waste human playtime.

## Key Findings

### Recommended Stack

The stack is lean and dependency-light. Python 3.12+ for the backend with FastAPI as the async web framework, serving a single-page frontend built with vanilla JavaScript and inline SVG for the territory map. No frontend build tooling, no database, no task queues.

**Core technologies:**
- **FastAPI + Uvicorn:** Async HTTP/WebSocket server -- native WebSocket support for real-time state push, Pydantic integration for typed game state serialization
- **Pydantic v2:** Game state models and validation -- automatic JSON serialization for WebSocket transmission, enforces data contracts between components
- **NetworkX:** Territory adjacency graph -- mature graph library providing pathfinding (fortification validation), subgraph operations (continent detection), and adjacency queries for 42 nodes / 83 edges
- **NumPy:** Vectorized dice simulation -- 10-100x faster than stdlib random for batch Monte Carlo combat evaluation used by Hard bot
- **SVG (inline):** Territory map rendering -- DOM-native click/hover events, resolution-independent, each territory is a colorable/clickable path element
- **Vanilla JS (ES6+):** Frontend interactivity -- no build tooling needed, the UI is simple enough (~3 views: map, sidebar, action controls)
- **uv + Ruff:** Project tooling -- modern Python package management and linting

### Expected Features

**Must have (table stakes) -- v1 launch:**
- Territory data model (42 territories, 6 continents, adjacencies) and SVG map display
- Game setup: random territory distribution, configurable player count (1 human + 1-5 bots), bot difficulty selection
- All three turn phases: draft (reinforcement + continent bonuses), attack (dice rolling, conquest), fortify (connected-path movement)
- Territory card system: collection, set trading with escalating bonuses, forced trade at 5+, territory match bonus
- Player elimination with card transfer, victory detection
- Easy bot AI (random/simple heuristic)
- Clickable territory interaction, phase indicators, skip/end phase buttons

**Should have (differentiators) -- v1.x:**
- Medium and Hard bot AI (the core value proposition per PROJECT.md)
- Blitz/auto-resolve combat and attack-until-X-remain
- Bot turn speed control (instant/fast/normal)
- Game log / event history (essential when bots move fast)
- Win probability display before attacks
- End-game summary screen

**Defer (v2+):**
- Bot personality styles (aggressive, defensive, expansionist)
- Per-game statistics and charts
- Game history / win-loss tracking (requires persistence)
- Manual territory draft, alternative maps, save/load

### Architecture Approach

Server-authoritative, state-machine-driven architecture with strict separation between game logic, AI, and presentation. The Python backend owns all state and rule enforcement. The browser client is a dumb terminal that sends action intents and renders state updates received via WebSocket. Bots and humans implement the same abstract Player interface, making them interchangeable from the Turn Engine's perspective.

**Major components:**
1. **Map/Graph Module** -- territory definitions, adjacency graph (NetworkX), continent groupings, pathfinding for fortification
2. **Game State Container** -- single source of truth for territory ownership, army counts, player hands, turn order; Pydantic models with JSON serialization
3. **Turn Engine (FSM)** -- drives the game loop through REINFORCE -> ATTACK -> FORTIFY -> END_TURN phases with sub-states for post-conquest army movement and forced card trades
4. **Combat Resolver** -- dice rolling, pairwise comparison (ties to defender), army loss calculation, territory capture
5. **Action Validator / Rule Engine** -- validates every action against current phase and game state before execution; single gate for all mutations
6. **Player Interface (ABC)** -- abstract base class with `choose_reinforcement()`, `choose_attack()`, `choose_fortify()` methods; HumanPlayer bridges to WebSocket, Bot implementations run AI logic
7. **Bot AI Implementations** -- Easy (random valid moves), Medium (weighted heuristics), Hard (strategic evaluation + Monte Carlo combat sim)
8. **WebSocket Server (FastAPI)** -- bridges backend to browser, sends state updates, receives human actions
9. **Browser Client** -- SVG map renderer, game info panel, action controls; zero game logic

### Critical Pitfalls

1. **Incorrect territory adjacency data** -- The classic map has 83 edges including cross-ocean routes that are easy to miss. Use a verified adjacency list from an established source, write tests asserting exactly 42 territories, exactly 83 bidirectional edges, and spot-check all cross-ocean connections (Alaska-Kamchatka, North Africa-Brazil, etc.).

2. **AI producing endless/boring games** -- The most common failure mode. Passive AI creates stalemates; reckless AI self-destructs. Mitigate with escalating card trade-in values (Risk's built-in anti-stalemate mechanic), explicit aggression parameters per difficulty, threat assessment heuristics, and batch-testing AI-only games at 100x speed to detect stalemate patterns.

3. **Card trading rules complexity** -- Most commonly implemented incorrectly. Key traps: global (not per-player) escalation tracking, forced trade at 5+ cards, card transfer on elimination with forced trade if eliminator hits 6+, territory match bonus of +2 armies. Test every edge case explicitly.

4. **Dice combat probability errors** -- Incorrect tie resolution or dice count constraints silently break game balance. Correct 3v2 probabilities: attacker wins both ~37.2%, split ~33.6%, defender wins both ~29.3%. Validate with 100k+ simulation runs.

5. **Fortification without connected path validation** -- Must verify source and destination are connected through a chain of player-owned territories (BFS/DFS on owned subgraph), not just adjacent. Build this as a reusable utility since AI also needs it.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation -- Data Models, Map, and Game State

**Rationale:** Everything depends on correct territory data and a well-structured game state. The adjacency graph is the single most critical data structure -- if it is wrong, everything downstream breaks. Build and exhaustively test this first.
**Delivers:** Territory data model (42 territories, 6 continents, 83 edges), NetworkX adjacency graph, Pydantic game state models, action type definitions, game map module with adjacency checks, connected-territory pathfinding, and continent control verification.
**Addresses:** Territory data model, map data structure (from FEATURES P1)
**Avoids:** Pitfall 1 (incorrect adjacency), Pitfall 5 (fortification path validation)

### Phase 2: Game Engine -- Turn FSM, Combat, Rules, and Cards

**Rationale:** The turn state machine is the skeleton of the game. Combat resolution, the card system, and action validation are tightly coupled to the FSM and must be built together. The card system is complex enough to warrant dedicated attention alongside the engine, not as an afterthought.
**Delivers:** Turn Engine (FSM with sub-states), Combat Resolver (dice rolling with statistical validation), Action Validator, card collection/trading with escalating bonuses, player elimination with card transfer, victory detection.
**Addresses:** All turn phases, combat resolution, card system, player elimination, victory detection (from FEATURES P1)
**Avoids:** Pitfall 2 (dice errors), Pitfall 4 (card complexity), Pitfall 6 (phase management bugs)

### Phase 3: Player Interface, WebSocket Server, and Basic UI

**Rationale:** With the game engine complete and testable via mock players, wire up the communication layer and build a functional (not polished) UI. The Player Interface ABC must exist before any bots, and the WebSocket bridge must exist before the human can play.
**Delivers:** Player Interface ABC, HumanPlayer WebSocket adapter, FastAPI WebSocket server, static HTML/CSS/JS frontend with SVG map rendering, clickable territories, phase indicators, army count display, basic action controls (dice roll, skip phase).
**Addresses:** Map display, clickable territories, phase indicators, army counts, color-coded territories (from FEATURES P1)
**Avoids:** Anti-Pattern 1 (client-side game logic), Pitfall 8 (UI information gaps)

### Phase 4: Bot AI -- Easy and Medium Difficulty

**Rationale:** Now that the game is playable by a human, add AI opponents. Easy bot first to validate the Player Interface contract works, then Medium bot to prove the heuristic framework. These must be built before Hard bot because each tier informs the next.
**Delivers:** Easy bot (random valid moves with basic heuristics), Medium bot (weighted heuristics: continent pursuit, border reinforcement, favorable-odds attacks), bot turn execution integrated into the game loop.
**Addresses:** Easy bot AI, bot turn execution (from FEATURES P1); Medium bot AI (from FEATURES P2)
**Avoids:** Pitfall 3 (endless games -- validate via AI-only batch testing), Pitfall 7 (decision space explosion -- filter action space with strategic constraints)

### Phase 5: Hard Bot AI and Combat Enhancements

**Rationale:** Hard bot is the core value proposition but requires the heuristic framework from Phase 4 and tuned Monte Carlo combat evaluation. Ship alongside blitz/auto-resolve since both use the same probability math. Bot speed controls and game log ship here because they become necessary when Hard bots play full games.
**Delivers:** Hard bot (strategic evaluation: continent control, threat assessment, card timing, Monte Carlo combat simulation), blitz/auto-resolve combat, bot turn speed control, game log, win probability display.
**Addresses:** Hard bot AI, blitz combat, bot speed control, game log, win probability (from FEATURES P2)
**Avoids:** Pitfall 3 (endless games -- tune aggression parameters, validate with batch testing), Pitfall 7 (decision space -- profile AI turn time, target <100ms)

### Phase 6: Polish and Quality of Life

**Rationale:** After core gameplay and AI are solid, add polish features that improve the experience but are not essential for a playable game.
**Delivers:** End-game summary screen, reinforcement undo (before committing), cross-ocean route visual indicators, colorblind-friendly palette validation, manual territory draft option.
**Addresses:** End-game summary, setup enhancements (from FEATURES P2/P3)

### Phase Ordering Rationale

- **Phases 1-2 are strictly sequential:** The engine cannot exist without the data models, and the engine must be testable before any UI or AI work begins. This matches the architecture's bottom-up dependency chain.
- **Phase 3 depends on Phase 2** but can overlap slightly: the SVG map can be prototyped while the engine is being finalized.
- **Phase 4 is independent of Phase 3's polish** but requires the Player Interface from Phase 3. In practice, build them close together.
- **Phase 5 builds on Phase 4's heuristic framework.** Do not attempt Hard bot without validating the approach on Easy and Medium first.
- **Phase 6 is truly independent** and can be interleaved as needed.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Card System):** The edge cases around card trading, escalation, and elimination transfers are numerous and subtle. Recommend pulling the official Hasbro rules PDF and cross-referencing with multiple community rule clarifications before implementation.
- **Phase 4-5 (Bot AI):** Heuristic tuning for Medium and Hard bots requires iteration. Plan for AI-vs-AI batch testing infrastructure early. The academic papers (Maastricht BSR/BST metrics, Cornell Risk agent) should be referenced during implementation.

Phases with standard patterns (skip deep research):
- **Phase 1 (Data Models):** Well-established patterns. The adjacency data is available from multiple open-source implementations. NetworkX API is well-documented.
- **Phase 3 (WebSocket + UI):** FastAPI WebSocket documentation is comprehensive. SVG territory interaction is a solved problem.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies are mature, well-documented, and widely used. No exotic dependencies. Version requirements are clear. |
| Features | HIGH | Risk is a 65-year-old game with canonical rules. Feature scope is well-defined by the game itself and validated against commercial implementations (SMG Studio). |
| Architecture | HIGH | Server-authoritative FSM-driven architecture is the standard pattern for turn-based games. Multiple academic and open-source implementations confirm the approach. |
| Pitfalls | HIGH | Pitfalls are well-documented across academic papers, open-source bug trackers, and community implementations. The specific failure modes (adjacency errors, AI stalemates, card rule complexity) are recurring and predictable. |

**Overall confidence:** HIGH

### Gaps to Address

- **SVG map asset:** The 42-territory SVG map with clickable path elements needs to be created or sourced. This is a non-trivial asset that affects Phase 3 timeline. Consider finding an existing open-source Risk SVG map and adapting it, or generating territory paths from coordinate data.
- **Hard bot tuning methodology:** While the heuristic approach is well-established, the specific weight tuning for the Hard bot will require experimentation. Plan for an iterative tuning cycle with AI-vs-AI batch testing. No amount of upfront research replaces playtesting.
- **Cross-ocean route visualization:** How to visually represent Alaska-Kamchatka and other sea routes on the SVG map is a UX design question that research did not fully resolve. Dashed lines between non-adjacent map regions is the common approach.
- **Game setup UX flow:** The research covers game mechanics thoroughly but the setup screen flow (choosing player count, bot difficulties, starting the game) needs UX design during Phase 3 planning.

## Sources

### Primary (HIGH confidence)
- [Official Risk Rules (Hasbro PDF)](https://www.hasbro.com/common/instruct/risk.pdf) -- canonical rule reference
- [FastAPI WebSocket Documentation](https://fastapi.tiangolo.com/advanced/websockets/) -- server implementation
- [NetworkX 3.6.1 Documentation](https://networkx.org/documentation/stable/tutorial.html) -- graph library API
- [Risk Battle Outcome Odds Calculator](https://riskodds.com/) -- combat probability reference
- [Risk dice probability analysis (DataGenetics)](http://www.datagenetics.com/blog/november22011/index.html) -- exact per-round expected losses

### Secondary (MEDIUM confidence)
- [Evaluating Heuristics in the Game Risk (Maastricht)](https://project.dke.maastrichtuniversity.nl/games/files/bsc/Hahn_Bsc-paper.pdf) -- BSR/BST metrics, AI heuristic evaluation
- [RISK AI Project (Gettysburg)](http://modelai.gettysburg.edu/2019/risk/RISK_AI_Handout.pdf) -- heuristic bot implementation guide
- [CS Cornell - An Intelligent Agent for Risk](https://www.cs.cornell.edu/boom/2001sp/Choi/473repo.html) -- AI challenges, state space analysis
- [SMG Studio Risk AI](https://smgstudio.freshdesk.com/support/solutions/articles/11000077687-our-risk-ai) -- commercial AI persona system
- [Game Programming Patterns: State](https://gameprogrammingpatterns.com/state.html) -- FSM patterns
- [Turn-Based Game Architecture Guide](https://outscal.com/blog/turn-based-game-architecture) -- architecture patterns

### Tertiary (LOW confidence)
- [Playing the Game of Risk with an AlphaZero Agent](https://www.diva-portal.org/smash/get/diva2:1514096/FULLTEXT01.pdf) -- confirms neural approach is overkill, useful for branching factor data
- [PyRisk on GitHub](https://github.com/chronitis/pyrisk) -- open source reference implementation

---
*Research completed: 2026-03-08*
*Ready for roadmap: yes*
