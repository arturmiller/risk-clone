# Requirements: Risk Strategy Game

**Defined:** 2026-03-08
**Core Value:** AI bots that provide a challenging and fun single-player experience, with the hardest difficulty playing at human-competitive level.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Game Setup

- [ ] **SETUP-01**: Player can select number of players (2-6)
- [ ] **SETUP-02**: Territories are randomly distributed among all players
- [ ] **SETUP-03**: Initial armies are placed according to classic Risk rules

### Game Engine

- [ ] **ENGI-01**: Player receives reinforcements at turn start (territory count/3 + continent bonuses, minimum 3)
- [ ] **ENGI-02**: Player can attack adjacent enemy territory with 1-3 dice vs 1-2 dice
- [ ] **ENGI-03**: Player can use blitz mode to auto-resolve combat until one side is eliminated
- [ ] **ENGI-04**: Player can fortify by moving armies along connected friendly path at end of turn
- [ ] **ENGI-05**: Player earns territory card when capturing at least one territory per turn
- [ ] **ENGI-06**: Player can trade card sets for bonus armies (escalating global sequence)
- [ ] **ENGI-07**: Player must trade cards if holding 5+ cards at start of turn
- [ ] **ENGI-08**: Eliminated player's cards transfer to the eliminator
- [ ] **ENGI-09**: Game ends when one player controls all 42 territories

### Map & Visualization

- [ ] **MAPV-01**: SVG map displays all 42 territories with correct adjacencies
- [ ] **MAPV-02**: Territories are colored by owning player
- [ ] **MAPV-03**: Army count is displayed on each territory
- [ ] **MAPV-04**: Territories are clickable for game actions (attack source/target, fortify)
- [ ] **MAPV-05**: Current turn phase and active player are clearly indicated
- [ ] **MAPV-06**: Game log shows event history (attacks, conquests, card trades, eliminations)
- [ ] **MAPV-07**: Continent bonus information is displayed on the map

### AI Bots

- [ ] **BOTS-01**: Easy bot makes random valid moves
- [ ] **BOTS-02**: Medium bot uses basic strategy (continent focus, reasonable attack decisions)
- [ ] **BOTS-03**: Hard bot plays at human-competitive level (threat assessment, army concentration, card timing, continent control)
- [ ] **BOTS-04**: AI-vs-AI simulation mode (watch bots play without human player)

## v2 Requirements

### Game Setup

- **SETUP-04**: Player can choose bot difficulty individually per bot
- **SETUP-05**: Player can select custom colors
- **SETUP-06**: Player can choose from multiple world maps

### UI Enhancements

- **UIEN-01**: Bot turn speed controls (slow/normal/fast/instant)
- **UIEN-02**: Attack animations/indications
- **UIEN-03**: End-game summary with statistics

### AI Enhancements

- **AIEN-01**: AI personality/play style variations (aggressive, defensive, opportunistic)
- **AIEN-02**: AI difficulty auto-adjustment based on player skill

## Out of Scope

| Feature | Reason |
|---------|--------|
| Multiplayer (human vs human) | Focus is on bot quality, single-player only |
| Mobile app | Future consideration, web-first |
| Deployment / hosting | Local development only |
| Custom map editor | Future feature after multi-map support |
| Online matchmaking | Single-player only |
| Undo/redo | Anti-feature: undermines strategic commitment |
| Save/load game | Defer to v2; in-memory state sufficient for v1 |
| Sound effects / music | Functional UI is sufficient |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SETUP-01 | Phase 3 | Pending |
| SETUP-02 | Phase 1 | Pending |
| SETUP-03 | Phase 1 | Pending |
| ENGI-01 | Phase 2 | Pending |
| ENGI-02 | Phase 2 | Pending |
| ENGI-03 | Phase 2 | Pending |
| ENGI-04 | Phase 2 | Pending |
| ENGI-05 | Phase 2 | Pending |
| ENGI-06 | Phase 2 | Pending |
| ENGI-07 | Phase 2 | Pending |
| ENGI-08 | Phase 2 | Pending |
| ENGI-09 | Phase 2 | Pending |
| MAPV-01 | Phase 1 | Pending |
| MAPV-02 | Phase 3 | Pending |
| MAPV-03 | Phase 3 | Pending |
| MAPV-04 | Phase 3 | Pending |
| MAPV-05 | Phase 3 | Pending |
| MAPV-06 | Phase 3 | Pending |
| MAPV-07 | Phase 3 | Pending |
| BOTS-01 | Phase 4 | Pending |
| BOTS-02 | Phase 4 | Pending |
| BOTS-03 | Phase 5 | Pending |
| BOTS-04 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0

---
*Requirements defined: 2026-03-08*
*Last updated: 2026-03-08 after roadmap creation*
