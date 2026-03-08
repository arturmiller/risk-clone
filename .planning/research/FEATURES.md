# Feature Research

**Domain:** Digital Risk-like strategy board game with AI bots
**Researched:** 2026-03-08
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

#### Game Setup

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Random territory distribution | Core Risk rule; standard starting mode | LOW | Randomly assign all 42 territories to players, then place initial armies |
| Configurable player count (2-6) | Board game supports 2-6; users expect the same | LOW | 1 human + 1-5 bots per PROJECT.md |
| Initial army placement | Core rule: players place starting armies on owned territories | MEDIUM | Auto-place for bots; let human place one-by-one or auto-distribute |
| Bot difficulty selection per bot | Users want to mix difficulties for varied challenge | LOW | Dropdown per bot slot: Easy, Medium, Hard |

#### Turn Phases

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Draft/Reinforcement phase | Core Risk mechanic: floor(territories/3) + continent bonuses + card trade-ins | MEDIUM | Must correctly calculate all bonus sources |
| Attack phase | Core mechanic: attacker rolls 1-3 dice vs defender 1-2 dice, compare highest | MEDIUM | Dice comparison logic, army removal, territory capture |
| Fortify phase | Core mechanic: move armies between connected owned territories once per turn | MEDIUM | Requires connected-territory pathfinding |
| Clear phase indicators | User must know which phase they are in at all times | LOW | Visual indicator: "DRAFT > ATTACK > FORTIFY" with current highlighted |
| Skip/End phase buttons | Player may want to skip attacking or fortifying | LOW | "End Attack" and "Skip Fortify" buttons |

#### Combat Resolution

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Dice rolling with results shown | Visual feedback of combat; core to the Risk experience | LOW | Show attacker dice vs defender dice, highlight winners |
| Attacker chooses number of dice (1-3) | Core rule: attacker picks 1-3 dice (max = armies - 1, capped at 3) | LOW | Dice count selector before each roll |
| Defender auto-rolls max dice | Standard digital Risk: defender always rolls max (1 or 2) | LOW | Automatic; no defender input needed for bots |
| Army movement after conquest | Core rule: must move at least as many armies as dice used into conquered territory | LOW | Slider or input for army count to move in |
| Territory card awarded on conquest | Core rule: earn 1 card per turn if you captured at least 1 territory | LOW | Track "captured this turn" flag, award card at turn end |

#### Territory Cards

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Card collection and hand display | Players need to see their cards | LOW | Show cards with territory name + troop type symbol |
| Card set trading for bonus armies | Core rule: trade sets of 3 matching or 1-of-each for bonus armies | MEDIUM | Validate set rules, calculate escalating bonus values |
| Escalating trade-in values | Classic Risk rule: 4, 6, 8, 10, 12, 15, 20, 25... | LOW | Simple counter tracking global trade-in count |
| Forced trade-in at 5 cards | Core rule: must trade if holding 5+ cards at start of turn | LOW | Enforce before draft phase |
| Territory bonus on card trade | Core rule: +2 armies on depicted territory if you own it | LOW | Check ownership, auto-place bonus |

#### Core UI

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Map display with territory boundaries | Users need to see the board | HIGH | 42 territories with clear boundaries, labels, army counts |
| Territory army counts visible | Must see troop strength at a glance | LOW | Number overlay on each territory |
| Color-coded player territories | Instant visual of who owns what | LOW | Distinct color per player |
| Current player and phase indicator | Know whose turn it is and what phase | LOW | Header bar or sidebar |
| Clickable territories for actions | Primary interaction method | MEDIUM | Click to select source/target for draft, attack, fortify |
| Continent bonus display | Users need to know what continents are worth | LOW | Reference panel showing continent names and bonus values |

#### Win Condition

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Player elimination | Core rule: eliminated when losing all territories | LOW | Remove player, transfer cards to conqueror |
| Victory detection | Game ends when one player holds all 42 territories | LOW | Check after each conquest |
| Card transfer on elimination | Core rule: conquering player gets eliminated player's cards | LOW | Force immediate trade-in if hand exceeds 5 |

#### Bot Behavior (Basics)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Bots that take valid turns | Bots must follow all rules correctly | MEDIUM | Draft, attack, fortify phases executed legally |
| Bots that finish turns in reasonable time | No infinite loops or hangs | LOW | Timeout/move-limit safety net |
| Easy bots that are beatable | New players need a winnable opponent | LOW | Random or weakly-heuristic decisions |
| Hard bots that challenge experienced players | Core value proposition per PROJECT.md | HIGH | Strategic play: continent control, threat assessment, army concentration |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

#### Combat Speed Controls

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Blitz/auto-resolve attack | Resolves entire battle instantly instead of roll-by-roll; massive time saver | MEDIUM | Simulate all dice rolls at once, show final result. Risk: Global Domination defaults to this mode |
| Attack-until-X-armies-remain | Let player set a threshold (e.g., stop when attacker has 3 armies left) | LOW | Simple loop with exit condition on the blitz |
| Blitz win probability display | Show estimated win chance before committing to an attack | MEDIUM | Pre-calculate odds based on attacker/defender army counts; well-known probability tables exist |

#### Game Flow Controls

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Bot turn speed control (fast/instant) | Skip watching bot animations; critical when playing against 4-5 bots | LOW | Configurable delay between bot actions: instant, fast, normal |
| Auto-draft option for human | Place all reinforcements on one territory quickly | LOW | Click territory to dump all armies, or distribute manually |
| Game log / event history | Scroll back to see what happened; essential when bots move fast | MEDIUM | Append-only log: "Red attacked Blue's Brazil from North Africa (3v2): Red wins, 1 army lost" |

#### Bot Intelligence

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Bot personality/strategy styles | Different bots play differently (aggressive, defensive, expansionist) beyond just difficulty | HIGH | Each difficulty level could have sub-styles; SMG Studio uses ~40 attributes per persona |
| Bot threat assessment | Hard bots recognize and respond to the leading player | HIGH | Evaluate relative strength, gang up on leader, form implicit alliances |
| Bot continent prioritization | Hard bots pursue and defend continents strategically | MEDIUM | Value continents by bonus/border-count ratio; Australia and South America are strong early targets |

#### Statistics and Feedback

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| End-game summary screen | Show winner, territories conquered, armies lost, turns played | LOW | Aggregate stats collected during game |
| Per-game statistics | Track dice luck, territories held over time, army count over time | MEDIUM | Collect per-turn snapshots, display as simple charts |
| Game history (win/loss record) | Track record across multiple games; motivates replay | LOW | Persist basic game results to local storage |

#### Setup Enhancements

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Manual territory draft | Players take turns claiming territories one-by-one instead of random assignment | MEDIUM | Alternate picking; bots need draft strategy |
| Card bonus mode selection | Choose between escalating (classic) and fixed card bonuses | LOW | Configuration toggle at game setup |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Undo/take-back moves | "I misclicked" or "I changed my mind" | Undermines strategic commitment; creates save-scumming against bots; complex to implement with dice already rolled | Confirmation dialogs on attack targets; clear click-to-confirm flow before dice roll |
| Multiplayer (human vs human) | Social gaming appeal | Massive scope increase (networking, turns/timers, disconnects, cheating); out of scope per PROJECT.md; dilutes focus on bot quality | Focus on great bot AI; consider multiplayer only after core is validated |
| Animated dice rolling / 3D graphics | Visual appeal | Significant UI complexity for marginal gameplay value; PROJECT.md explicitly scopes out polished graphics | Simple dice result display with brief visual feedback; focus on clear, readable UI |
| Fog of war mode | Adds strategic depth | Changes the fundamental game significantly; requires hidden information system; complicates bot AI substantially | Build as a future game mode variant only after classic rules work perfectly |
| Save/load mid-game | "I want to pause and resume" | Serializing full game state is moderately complex; tempts save-scumming | Auto-save game state to allow resume on browser refresh; single save slot, no manual save/load menu |
| Custom map editor | User-generated content | Very high complexity; requires map validation, adjacency definition UI, playtesting tools; out of scope per PROJECT.md | Architecture should support loading different maps from data files for future extensibility |
| Real-time attacks / simultaneous turns | Speed up gameplay | Fundamentally changes Risk into a different game; breaks turn-based strategy model | Bot speed controls solve the "game takes too long" problem without changing core mechanics |
| Online matchmaking / leaderboards | Competitive motivation | Requires server infrastructure; out of scope per PROJECT.md | Local game history and win/loss tracking provides enough motivation |

## Feature Dependencies

```
[Map Display (42 territories)]
    +--requires--> [Territory Data Model (adjacencies, continents)]
    +--requires--> [Player/Color Assignment]

[Attack Phase]
    +--requires--> [Map Display]
    +--requires--> [Dice Rolling Logic]
    +--requires--> [Adjacency Validation]
    +--enables---> [Territory Card Award]
    +--enables---> [Blitz/Auto-Resolve]

[Draft Phase]
    +--requires--> [Territory Counting + Continent Bonus Calc]
    +--requires--> [Card Trading System]

[Card Trading System]
    +--requires--> [Card Collection (from Attack Phase)]
    +--requires--> [Escalating Bonus Tracker]

[Fortify Phase]
    +--requires--> [Connected Territory Pathfinding]

[Bot AI (any level)]
    +--requires--> [All Turn Phases working]
    +--requires--> [Valid Move Generation]

[Hard Bot AI]
    +--requires--> [Bot AI (basic)]
    +--requires--> [Threat Assessment Logic]
    +--requires--> [Continent Valuation Logic]

[Blitz/Auto-Resolve]
    +--requires--> [Dice Rolling Logic]
    +--enhances--> [Attack Phase]

[Win Probability Display]
    +--requires--> [Blitz/Auto-Resolve] (uses same probability math)
    +--enhances--> [Attack Phase]

[Game Log]
    +--enhances--> [All Turn Phases]
    +--enhances--> [Bot Turn Speed Control] (need log when bots move fast)

[End-Game Summary]
    +--requires--> [Victory Detection]
    +--requires--> [Statistics Collection (during game)]

[Player Elimination]
    +--requires--> [Card Transfer Logic]
    +--triggers--> [Victory Detection]
```

### Dependency Notes

- **Draft Phase requires Card Trading:** Card trade-ins happen at the start of the draft phase, so the card system must exist before draft is fully functional. However, draft can work without cards initially (just territory count + continent bonuses).
- **Blitz requires Dice Rolling Logic:** Blitz is a batch execution of the same dice comparison used in manual rolling, so the core dice logic must exist first.
- **Game Log enhances Bot Speed Control:** When bots play instantly, the log is the only way to understand what happened. These should ship together.
- **Hard Bot requires Basic Bot:** Difficulty levels should be built incrementally -- Easy first (random/simple heuristics), then Medium (basic strategy), then Hard (full strategic play).

## MVP Definition

### Launch With (v1)

Minimum viable product -- what's needed to validate the concept.

- [ ] Territory data model (42 territories, 6 continents, adjacencies) -- foundation for everything
- [ ] Map display with color-coded territories and army counts -- must see the board
- [ ] Game setup: random territory distribution, initial army placement -- must start a game
- [ ] All three turn phases: draft, attack (manual roll), fortify -- core game loop
- [ ] Territory cards: collection, set trading, escalating bonuses -- core rule
- [ ] Player elimination and victory detection -- must be able to win
- [ ] Easy bot AI (random/simple heuristic decisions) -- must have an opponent
- [ ] Clickable territory interaction for all phases -- must be able to play
- [ ] Phase indicators and skip/end phase buttons -- must navigate turns

### Add After Validation (v1.x)

Features to add once core game loop works.

- [ ] Medium bot AI -- once Easy bot proves the AI framework works
- [ ] Hard bot AI with strategic play -- core value proposition; add after Medium validates the approach
- [ ] Blitz/auto-resolve combat -- quality of life once manual combat works
- [ ] Bot turn speed control -- needed once multiple bots are playing
- [ ] Game log -- needed when bots play fast
- [ ] End-game summary screen -- polish after core loop is fun
- [ ] Win probability display -- nice feedback during attack decisions
- [ ] Manual territory draft option -- alternative setup mode

### Future Consideration (v2+)

Features to defer until core game is solid.

- [ ] Bot personality styles (aggressive, defensive, etc.) -- complexity beyond difficulty levels
- [ ] Per-game statistics and charts -- nice to have, not core
- [ ] Game history / win-loss tracking -- requires persistence layer
- [ ] Card bonus mode selection (escalating vs fixed) -- variant rule
- [ ] Auto-save / resume on refresh -- requires game state serialization
- [ ] Alternative maps -- architecture should support this but implementation is future

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Territory data model + adjacencies | HIGH | MEDIUM | P1 |
| Map display (territories, armies, colors) | HIGH | HIGH | P1 |
| Game setup (random distribution, army placement) | HIGH | LOW | P1 |
| Draft phase (reinforcements + continent bonuses) | HIGH | MEDIUM | P1 |
| Attack phase (dice rolling, conquest) | HIGH | MEDIUM | P1 |
| Fortify phase (connected movement) | HIGH | MEDIUM | P1 |
| Territory card system | HIGH | MEDIUM | P1 |
| Player elimination + victory | HIGH | LOW | P1 |
| Easy bot AI | HIGH | MEDIUM | P1 |
| Phase indicators + UI navigation | HIGH | LOW | P1 |
| Medium bot AI | HIGH | MEDIUM | P2 |
| Hard bot AI (strategic) | HIGH | HIGH | P2 |
| Blitz/auto-resolve combat | MEDIUM | MEDIUM | P2 |
| Bot turn speed control | MEDIUM | LOW | P2 |
| Game log | MEDIUM | LOW | P2 |
| End-game summary | MEDIUM | LOW | P2 |
| Win probability display | MEDIUM | MEDIUM | P2 |
| Manual territory draft | LOW | MEDIUM | P3 |
| Bot personality styles | LOW | HIGH | P3 |
| Per-game statistics | LOW | MEDIUM | P3 |
| Game history tracking | LOW | LOW | P3 |

**Priority key:**
- P1: Must have for launch -- core game loop and minimum playability
- P2: Should have, add when possible -- quality of life and core value (bot AI)
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Risk: Global Domination (SMG Studio) | Open Source (PyRisk, etc.) | Our Approach |
|---------|--------------------------------------|---------------------------|--------------|
| Map display | Polished 2D/3D with animations | Terminal/ncurses text-based | Clean 2D web UI: functional, readable, no animations needed |
| Bot AI | ~40 attributes per persona, multiple personas per difficulty, extensively tested via overnight simulations | Basic heuristic bots, often random | 3 clear difficulty tiers; Hard bot uses strategic heuristics (continent control, threat assessment, border defense) |
| Dice modes | Blitz (default), manual roll, balanced blitz | Manual only or auto-resolve | Manual roll for v1, add blitz in v1.x |
| Game speed | Camera animation toggle, blitz speed, turn timer (60s in multiplayer) | Instant (terminal) | Bot speed slider: instant/fast/normal |
| Cards | Full card system with escalating bonuses | Often simplified or omitted | Full classic card system with escalating bonuses |
| Game modes | 6+ modes (Fog of War, Zombies, Capitals, etc.) | Classic only | Classic only; architecture supports future modes |
| Maps | 120+ maps | Classic only | Classic map; data-driven architecture for future maps |
| Statistics | Online leaderboards, rankings | None | Local game summary and history |
| Monetization | Free-to-play with ads and map pack purchases | Free | Free, local-only, no monetization |

## Sources

- [Risk: Global Domination on Steam](https://store.steampowered.com/app/1128810/RISK_Global_Domination/) -- primary commercial competitor
- [SMG Studio Risk AI documentation](https://smgstudio.freshdesk.com/support/solutions/articles/11000077687-our-risk-ai) -- AI persona system details
- [Risk: Global Domination Wiki - Dice, Blitz and Slow Roll](https://risk-global-domination.fandom.com/wiki/Dice,_Blitz_and_Slow_Roll) -- combat speed controls
- [SMG Studio - Draft wiki](https://smgstudio.freshdesk.com/support/solutions/articles/11000121587-wiki-draft) -- manual territory draft feature
- [Creating an AI for Risk board game - Martin Sonesson](https://martinsonesson.wordpress.com/2018/01/07/creating-an-ai-for-risk-board-game/) -- AI implementation approaches
- [CS Cornell - An Intelligent Agent for Risk](https://www.cs.cornell.edu/boom/2001sp/Choi/473repo.html) -- academic Risk AI research
- [PyRisk on GitHub](https://github.com/chronitis/pyrisk) -- open source Python Risk implementation
- [Risk official rules (Hasbro)](https://www.hasbro.com/common/instruct/risk.pdf) -- canonical rule reference
- [UltraBoardGames - How to Play Risk](https://www.ultraboardgames.com/risk/game-rules.php) -- rules reference
- [Risk card trade-in values](https://miexto.com/boardgames/risk-card-trade-in-values-to-trade-in-cards/) -- escalating bonus schedule

---
*Feature research for: Digital Risk-like strategy board game with AI bots*
*Researched: 2026-03-08*
