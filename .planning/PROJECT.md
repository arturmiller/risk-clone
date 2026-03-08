# Risk Strategy Game

## What This Is

A digital adaptation of the classic Risk board game, playable locally in a web browser against AI bots. The game features the classic world map (42 territories, 6 continents) with original Risk rules. Focus is on strong AI opponents with multiple difficulty levels, not on multiplayer or deployment.

## Core Value

AI bots that provide a challenging and fun single-player experience, with the hardest difficulty playing at human-competitive level.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Classic Risk world map (42 territories, 6 continents, correct adjacencies)
- [ ] Original Risk rules (reinforcement, attack with dice, fortify, territory cards, continent bonuses)
- [ ] 3 Bot difficulty levels: Easy, Medium, Hard (Hard = human-level play)
- [ ] Flexible player count: 2-6 (1 human + 1-5 bots)
- [ ] Random territory distribution at start
- [ ] Win condition: eliminate all opponents
- [ ] Simple web UI showing territory graph, armies, and all game-relevant info
- [ ] Local-only execution (no deployment, no server hosting)
- [ ] Architecture supports future addition of different world maps

### Out of Scope

- Multiplayer (human vs human) — focus is on bot quality
- Mobile app — future consideration, web-first
- Deployment / hosting — local development only
- Custom map editor — future feature
- Online matchmaking — single-player only
- Animations / polished graphics — functional UI is sufficient

## Context

- Game is a stepping stone toward a full app; current focus is game mechanics and AI
- Classic Risk rules include: initial army placement, reinforcement phase (territory count / 3 + continent bonuses), attack phase (attacker up to 3 dice vs defender up to 2 dice), fortify phase (move armies between connected territories), territory cards (sets of 3 for bonus armies)
- The Hard bot should use strategic concepts: continent control, border defense, threat assessment, army concentration
- Python backend chosen for AI/game logic strengths; simple web frontend for visualization

## Constraints

- **Tech stack**: Python backend (game logic + bots), simple HTML/JS frontend (visualization)
- **Scope**: No deployment infrastructure, runs locally only
- **Players**: Always 1 human player, bots fill remaining slots
- **Rules**: Must match official Risk board game rules faithfully

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Python for backend/AI | Strong ecosystem for game AI, clean logic | — Pending |
| 3 bot difficulty levels | Clear differentiation without over-complexity | — Pending |
| Classic Risk map first | Proven, well-known baseline before custom maps | — Pending |
| No multiplayer | Focus resources on bot quality | — Pending |

---
*Last updated: 2026-03-08 after initialization*
