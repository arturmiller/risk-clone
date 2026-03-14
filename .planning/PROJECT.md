# Risk Strategy Game

## What This Is

A browser-based Risk board game with AI opponents at three difficulty levels. Features the classic world map (42 territories, 6 continents) with faithful Risk rules, interactive SVG map, WebSocket real-time gameplay, and an AI-vs-AI simulation mode. Runs locally via Python/FastAPI backend.

## Core Value

AI bots that provide a challenging and fun single-player experience, with the hardest difficulty playing at human-competitive level.

## Requirements

### Validated

- ✓ Classic Risk world map (42 territories, 6 continents, correct adjacencies) — v1.0
- ✓ Original Risk rules (reinforcement, attack with dice, fortify, territory cards, continent bonuses) — v1.0
- ✓ 3 Bot difficulty levels: Easy, Medium, Hard (Hard = human-level play) — v1.0
- ✓ Flexible player count: 2-6 (1 human + 1-5 bots) — v1.0
- ✓ Random territory distribution at start — v1.0
- ✓ Win condition: eliminate all opponents — v1.0
- ✓ Simple web UI showing territory graph, armies, and all game-relevant info — v1.0
- ✓ Local-only execution (no deployment, no server hosting) — v1.0
- ✓ AI-vs-AI simulation mode (watch bots play) — v1.0

### Active

- [ ] Flutter mobile app for Android and iOS
- [ ] Game engine rewritten in Dart (no backend, runs on-device)
- [ ] Fresh mobile-first UI design (touch interactions, bottom sheets)
- [ ] All v1.0 game features ported (combat, cards, fortify, AI bots, simulation mode)

### Out of Scope

- Multiplayer (human vs human) — focus is on bot quality, single-player only
- Mobile app — future consideration, web-first
- Deployment / hosting — local development only
- Custom map editor — future feature after multi-map support
- Online matchmaking — single-player only
- Sound effects / music — functional UI is sufficient
- Undo/redo — anti-feature: undermines strategic commitment

## Context

Shipped v1.0 with 7,400+ Python LOC + 950 JS LOC.
Tech stack: Python/FastAPI backend, vanilla JS frontend, SVG map, WebSocket communication.
Hard bot achieves 80% win rate against Medium in batch testing.
User-reported bugs fixed during v1.0: fortify path (BFS), advance armies max, card trade UI, continent counts, card recycling.

## Constraints

- **Tech stack**: Python backend (FastAPI + game logic + bots), vanilla HTML/JS/CSS frontend
- **Scope**: No deployment infrastructure, runs locally only
- **Players**: 1 human + bots, or all-bot simulation
- **Rules**: Must match official Risk board game rules faithfully

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Python for backend/AI | Strong ecosystem for game AI, clean logic | ✓ Good |
| 3 bot difficulty levels | Clear differentiation without over-complexity | ✓ Good |
| Classic Risk map first | Proven, well-known baseline before custom maps | ✓ Good |
| No multiplayer | Focus resources on bot quality | ✓ Good |
| NetworkX for graph operations | BFS, adjacency, connected components built-in | ✓ Good |
| Pydantic immutable state | model_copy for state transitions, clean serialization | ✓ Good |
| WebSocket for real-time | Bidirectional communication for async game loop | ✓ Good |
| HardAgent heuristic scoring | Multi-factor weighted scoring vs ML approach | ✓ Good (80% win rate) |

## Current Milestone: v1.1 Mobile App

**Goal:** Port the Risk game to a Flutter mobile app for Android and iOS with a fresh mobile-first UI, rewriting the game engine in Dart.

**Target features:**
- Complete Dart port of game engine (map, combat, cards, reinforcements, fortify, turn FSM)
- All 3 AI difficulty levels ported (Easy, Medium, Hard)
- AI-vs-AI simulation mode
- Touch-first mobile UI with interactive map
- Blitz attack mode

---
*Last updated: 2026-03-14 after v1.1 milestone start*
