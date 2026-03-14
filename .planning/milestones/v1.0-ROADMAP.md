# Roadmap: Risk Strategy Game

## Overview

This roadmap delivers a browser-based Risk game with AI opponents in 5 phases. We start with the foundational data model (territory graph, game state), build the complete game engine (turns, combat, cards), wire up the web UI for human play, add Easy and Medium bots to validate the AI framework, and culminate with the Hard bot -- the project's core value proposition. Each phase delivers a testable, coherent capability.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Territory data model, adjacency graph, and game state structures
- [x] **Phase 2: Game Engine** - Turn FSM, combat resolution, card system, and victory detection
- [x] **Phase 3: Web UI and Game Setup** - Browser client, interactive SVG map, WebSocket server, and player setup
- [x] **Phase 4: Easy and Medium Bots** - First two AI difficulty tiers validating the bot framework (completed 2026-03-09)
- [x] **Phase 5: Hard Bot and AI Simulation** - Human-competitive AI and bot-vs-bot observation mode (completed 2026-03-14)

## Phase Details

### Phase 1: Foundation
**Goal**: A verified territory graph and game state model that all downstream systems can build on
**Depends on**: Nothing (first phase)
**Requirements**: SETUP-02, SETUP-03, MAPV-01
**Success Criteria** (what must be TRUE):
  1. All 42 territories exist with correct continent assignments (6 continents)
  2. All 83 adjacency edges are present and bidirectional, including cross-ocean routes (Alaska-Kamchatka, North Africa-Brazil, etc.)
  3. Territories can be randomly distributed among N players with correct initial army counts per classic Risk rules
  4. Connected-path queries correctly identify reachable territories through friendly chains
**Plans:** 2/2 plans complete
Plans:
- [x] 01-01-PLAN.md — Project setup, map data JSON, Pydantic schema, NetworkX graph wrapper, and map/graph tests
- [x] 01-02-PLAN.md — Game state models, territory distribution, army placement, and setup tests

### Phase 2: Game Engine
**Goal**: A complete, rules-correct Risk game engine that can run a full game from setup to victory using programmatic inputs
**Depends on**: Phase 1
**Requirements**: ENGI-01, ENGI-02, ENGI-03, ENGI-04, ENGI-05, ENGI-06, ENGI-07, ENGI-08, ENGI-09
**Success Criteria** (what must be TRUE):
  1. A player receives correct reinforcements at turn start (territory count / 3, rounded down, minimum 3, plus continent bonuses)
  2. Combat resolves correctly: attacker rolls 1-3 dice, defender rolls 1-2 dice, highest dice paired, ties go to defender, armies removed accordingly
  3. Card system works end-to-end: cards earned on conquest turns, sets traded for escalating bonus armies, forced trade at 5+ cards, eliminated player's cards transfer to eliminator
  4. A full game can run to completion (one player controls all 42 territories) via programmatic moves without UI
  5. Fortification correctly validates connected friendly paths and allows army movement only along them
**Plans:** 3/3 plans complete
Plans:
- [x] 02-01-PLAN.md — Card/action models, extended GameState, PlayerAgent protocol, reinforcements, and card system
- [x] 02-02-PLAN.md — Combat resolution (single roll + blitz) and fortification with path validation
- [x] 02-03-PLAN.md — Turn execution engine, game runner, and full-game end-to-end test

### Phase 3: Web UI and Game Setup
**Goal**: A human player can set up and play a complete game of Risk in a web browser
**Depends on**: Phase 2
**Requirements**: SETUP-01, MAPV-02, MAPV-03, MAPV-04, MAPV-05, MAPV-06, MAPV-07
**Success Criteria** (what must be TRUE):
  1. Player can select number of players (2-6) and start a new game from the browser
  2. SVG map displays all territories colored by owner with army counts visible on each territory
  3. Player can click territories to perform game actions (select attack source/target, select fortify source/target)
  4. Current turn phase and active player are clearly indicated, and a game log shows attack results, conquests, card trades, and eliminations
  5. Continent bonus information is visible on or near the map
**Plans:** 4/4 plans complete
Plans:
- [x] 03-01-PLAN.md — Server infrastructure: FastAPI app, WebSocket messages, HumanWebSocketAgent, GameManager
- [x] 03-02-PLAN.md — SVG world map asset and HTML/CSS layout (setup screen, game board, sidebar)
- [x] 03-03-PLAN.md — Frontend JavaScript: WebSocket client, map interaction, sidebar updates
- [x] 03-04-PLAN.md — Integration tests, end-to-end wiring, and human verification

### Phase 4: Easy and Medium Bots
**Goal**: AI opponents provide a fun game experience at two difficulty levels, validating the bot framework for the Hard bot
**Depends on**: Phase 3
**Requirements**: BOTS-01, BOTS-02
**Success Criteria** (what must be TRUE):
  1. Easy bot makes valid moves each turn (reinforces, attacks sometimes, fortifies) without crashing or stalling the game
  2. Medium bot visibly pursues continent control, reinforces borders, and attacks when it has favorable odds
  3. A human player can play a full game against 1-5 bots (any mix of Easy/Medium) from setup to victory or defeat in the browser
**Plans:** 7/7 plans complete
Plans:
- [x] 04-01-PLAN.md — Wave 0: test scaffold (test stubs + risk/bots/ package skeleton)
- [x] 04-02-PLAN.md — MediumAgent implementation (TDD, continent-aware strategy) + run_game() injection update
- [x] 04-03-PLAN.md — Full-stack difficulty wiring: StartGameMessage, GameManager, app.py, index.html, app.js
- [x] 04-04-PLAN.md — Test suite gate + human verification checkpoint

### Phase 5: Hard Bot and AI Simulation
**Goal**: The Hard bot plays at human-competitive level, delivering the project's core value, and users can watch bot-only games
**Depends on**: Phase 4
**Requirements**: BOTS-03, BOTS-04
**Success Criteria** (what must be TRUE):
  1. Hard bot demonstrates observable strategic play: prioritizes continent completion, concentrates armies on borders, times card trades for maximum impact, and assesses threats from other players
  2. Hard bot wins against Medium bots significantly more often than chance in batch AI-vs-AI testing
  3. User can start an AI-vs-AI simulation (no human player) and watch bots play a full game to completion
**Plans:** 4/4 plans complete
Plans:
- [ ] 05-01-PLAN.md — Wave 0: HardAgent skeleton, test stubs for BOTS-03 and BOTS-04
- [ ] 05-02-PLAN.md — HardAgent full implementation (TDD, multi-factor heuristic strategy)
- [ ] 05-03-PLAN.md — AI-vs-AI simulation mode (server + frontend)
- [ ] 05-04-PLAN.md — Batch statistical validation + human verification

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete    | 2026-03-08 |
| 2. Game Engine | 3/3 | Complete | 2026-03-08 |
| 3. Web UI and Game Setup | 4/4 | Complete | 2026-03-08 |
| 4. Easy and Medium Bots | 7/7 | Complete   | 2026-03-09 |
| 5. Hard Bot and AI Simulation | 4/4 | Complete   | 2026-03-14 |
