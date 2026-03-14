# Requirements: Risk Strategy Game — Mobile App

**Defined:** 2026-03-14
**Core Value:** AI bots that provide a challenging and fun single-player experience, with the hardest difficulty playing at human-competitive level.

## v1.1 Requirements

Requirements for Flutter mobile port. Each maps to roadmap phases.

### Game Engine (Dart Port)

- [ ] **DART-01**: All combat rules ported (dice rolling, attacker/defender pairing, ties to defender)
- [ ] **DART-02**: Card system ported (deck, drawing, trading with escalating bonus, forced trade at 5+)
- [ ] **DART-03**: Reinforcement calculation ported (territory count / 3 + continent bonuses, minimum 3)
- [ ] **DART-04**: Fortification ported (move armies along connected friendly path)
- [ ] **DART-05**: Turn FSM ported (reinforce → attack → fortify, player rotation, elimination, victory)
- [ ] **DART-06**: Blitz attack mode (auto-resolve until conquest or attacker depleted)
- [ ] **DART-07**: Map graph with BFS connectivity queries (adjacency, connected territories, continent control)

### AI Bots

- [ ] **BOTS-05**: Easy bot ported (random valid moves)
- [ ] **BOTS-06**: Medium bot ported (continent focus, border reinforcement)
- [ ] **BOTS-07**: Hard bot ported (multi-factor heuristic scoring, threat assessment)
- [ ] **BOTS-08**: Bot computation runs in isolate (no UI thread blocking)
- [ ] **BOTS-09**: AI-vs-AI simulation mode (all bots, no human player)

### Map & Interaction

- [ ] **MAPW-01**: Interactive map widget with pinch-zoom and pan
- [ ] **MAPW-02**: Tap territory to select (attack source/target, fortify source/target)
- [ ] **MAPW-03**: Territories colored by owning player with army counts displayed
- [ ] **MAPW-04**: Territory highlighting (valid sources, valid targets, selected)
- [ ] **MAPW-05**: Hit-test expansion for small territories on phone screens

### Mobile UX

- [ ] **MOBX-01**: Game setup screen (player count, difficulty, game mode)
- [ ] **MOBX-02**: Responsive layout for phone and tablet
- [ ] **MOBX-03**: Game action controls (dice selection, blitz, end attack, skip fortify, card trade)
- [ ] **MOBX-04**: Game log showing events (attacks, conquests, eliminations, card trades)
- [ ] **MOBX-05**: Continent info with bonus display
- [ ] **MOBX-06**: Game over screen with new game option

### Persistence

- [ ] **SAVE-01**: Auto-save game state when app is backgrounded
- [ ] **SAVE-02**: Resume game automatically on app relaunch

## v2 Requirements

### Mobile Polish

- **HAPF-01**: Haptic feedback on dice rolls, conquests, and eliminations
- **COLR-01**: Colorblind-accessible color palette option
- **TUTR-01**: Optional skippable tutorial for new players
- **SAVE-03**: Multiple named save slots with manual save/load

### App Distribution

- **DIST-01**: Published to Google Play Store
- **DIST-02**: Published to Apple App Store

## Out of Scope

| Feature | Reason |
|---------|--------|
| Multiplayer (human vs human) | Focus is on bot quality, single-player only |
| Online features / networking | Fully offline, on-device game |
| Sound effects / music | Functional UI is sufficient for v1.1 |
| Custom map editor | Future feature |
| In-app purchases | Free game, no monetization |
| Cloud save sync | Local-only for v1.1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DART-01 | - | Pending |
| DART-02 | - | Pending |
| DART-03 | - | Pending |
| DART-04 | - | Pending |
| DART-05 | - | Pending |
| DART-06 | - | Pending |
| DART-07 | - | Pending |
| BOTS-05 | - | Pending |
| BOTS-06 | - | Pending |
| BOTS-07 | - | Pending |
| BOTS-08 | - | Pending |
| BOTS-09 | - | Pending |
| MAPW-01 | - | Pending |
| MAPW-02 | - | Pending |
| MAPW-03 | - | Pending |
| MAPW-04 | - | Pending |
| MAPW-05 | - | Pending |
| MOBX-01 | - | Pending |
| MOBX-02 | - | Pending |
| MOBX-03 | - | Pending |
| MOBX-04 | - | Pending |
| MOBX-05 | - | Pending |
| MOBX-06 | - | Pending |
| SAVE-01 | - | Pending |
| SAVE-02 | - | Pending |

**Coverage:**
- v1.1 requirements: 25 total
- Mapped to phases: 0
- Unmapped: 25

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 after initial definition*
