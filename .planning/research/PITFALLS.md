# Pitfalls Research

**Domain:** Risk-like strategy board game with AI bots
**Researched:** 2026-03-08
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Incorrect Territory Adjacency Data

**What goes wrong:**
The classic Risk map has 42 territories and 83 adjacency connections, including several non-obvious cross-ocean routes (e.g., North Africa-Brazil, Alaska-Kamchatka, East Africa-Middle East, Greenland-Iceland). Even Hasbro's own 40th Anniversary Edition shipped with the East Africa-Middle East connection missing -- a manufacturing error that persisted into Risk II. Getting even one adjacency wrong breaks game balance, AI pathfinding, fortification validation, and continent control logic.

**Why it happens:**
Developers transcribe adjacencies by hand from a visual map, and cross-ocean connections are easy to miss because they are not visible as shared borders. The map has 83 edges, and verifying all of them manually is tedious and error-prone.

**How to avoid:**
- Define adjacency data as a structured graph (dictionary of territory -> set of neighbors), not as visual/spatial proximity.
- Use a well-known, verified adjacency list from an existing open-source Risk implementation or the Risk wiki as your source of truth.
- Write a comprehensive test suite: assert exactly 42 territories, exactly 83 edges, every adjacency is bidirectional (if A connects to B, B connects to A), every continent has the correct member territories, and the full graph is connected.
- Specifically test the cross-ocean routes: Alaska-Kamchatka, North Africa-Brazil, East Africa-Madagascar, East Africa-Middle East, Greenland-Iceland, Greenland-Northwest Territory, Western Europe-North Africa, Southern Europe-North Africa, Southern Europe-Middle East, Indonesia-Siam.

**Warning signs:**
- AI never attacks across oceans.
- Fortification between continents fails unexpectedly.
- Continent bonus calculations differ from official rules.
- Total edge count in the graph is not 83.

**Phase to address:**
Core game engine / map data (Phase 1). This is foundational -- everything depends on correct adjacency.

---

### Pitfall 2: Dice Combat Probability Errors

**What goes wrong:**
Risk combat uses a specific dice comparison mechanic: attacker rolls up to 3 dice, defender rolls up to 2, then the highest dice are compared pairwise with ties going to the defender. The exact probabilities matter enormously for game balance and AI decision-making. Common errors: comparing dice incorrectly (not sorting and pairing highest-to-highest), giving ties to the attacker, allowing attacker to roll 3 dice when they only have 3 armies (need at least 4 to roll 3), or allowing defender to roll 2 dice when they only have 1 army.

The correct single-round probabilities for 3v2 are: attacker loses 2 (~29.3%), each loses 1 (~33.6%), defender loses 2 (~37.2%). The attacker has a slight edge per round (expected loss ratio: attacker ~0.921 armies vs defender ~1.079 armies per round). Getting this wrong makes the game either too easy or impossibly hard.

**Why it happens:**
The dice comparison is more complex than it appears. Developers implement naive comparisons (e.g., sum of dice, or comparing all dice instead of top pairs). The army-count constraints on dice count are easy to forget.

**How to avoid:**
- Implement dice resolution as: sort attacker dice descending, sort defender dice descending, compare pairwise for min(attacker_count, defender_count) pairs. Ties go to defender.
- Enforce: attacker must leave at least 1 army behind (so rolling 3 dice requires 4+ armies on the territory). Defender rolls min(2, armies_on_territory).
- Write a statistical test: simulate 100,000+ rounds of 3v2 combat and assert the probabilities match known values within a small tolerance (attacker wins both ~37.2%, split ~33.6%, defender wins both ~29.3%).
- Pre-compute or cache the probability tables for AI use -- the AI needs accurate expected losses to make good attack decisions.

**Warning signs:**
- Simulated win rates diverge from known mathematical values.
- Games feel consistently too easy or too hard for the human player.
- AI makes obviously bad attack decisions (attacking 5v10, or refusing to attack 20v2).

**Phase to address:**
Core game engine (Phase 1). Combat is the most fundamental mechanic.

---

### Pitfall 3: AI That Produces Endless, Boring Games

**What goes wrong:**
This is the single most common failure mode in Risk implementations. AI agents that are too passive (turtling, never attacking unless overwhelming advantage) create games that stall for hundreds of turns with no progress. The game becomes a tedious slog where nobody can gain enough advantage to break through. Conversely, AI that is too aggressive (attacking everywhere with thin margins) self-destructs and gets eliminated early, leaving a boring 1v1 or even just the human player winning by default.

**Why it happens:**
Risk's decision space is enormous (estimated state space of ~2^42). Simple heuristics tend to either over-value defense (leading to passivity) or under-value positional strength (leading to reckless attacks). The game's reinforcement mechanics create a positive feedback loop -- whoever controls more territory gets more armies -- but the tipping point is hard for AI to identify. Without explicit "game progression" logic, AI agents reach equilibrium states where no agent has enough advantage to attack, and the game stalls indefinitely.

**How to avoid:**
- Implement escalating card trade-in values (this is a rules requirement anyway). The escalating reinforcement from cards is Risk's built-in anti-stalemate mechanism. Without it, games genuinely can be endless.
- Give AI agents explicit aggression parameters that vary by difficulty level. Easy AI can be somewhat random; Medium should pursue continent control; Hard should evaluate continent-denial (attacking opponents who are close to completing continents).
- Implement threat assessment: Border Security Ratio (BSR) = enemy armies adjacent to territory / friendly armies on territory. AI should reinforce high-BSR borders and attack when BSR is favorable.
- Add a "momentum" heuristic: after conquering a territory (earning a card), evaluate whether to continue attacking or consolidate. Good Risk play involves surgical strikes, not constant all-out war.
- Set maximum game length (e.g., 500 turns) with a tiebreaker (most territories) to prevent genuinely infinite games during development and testing.
- Test AI-only games (no human) at 100x speed to detect stalemate patterns before they waste human playtime.

**Warning signs:**
- AI-only games averaging more than 200 turns.
- AI never initiating attacks unless it has 5:1 army advantage.
- AI spreading armies evenly across all territories instead of concentrating on borders.
- No AI player ever completing a continent.

**Phase to address:**
AI implementation (Phase 3 or wherever AI is built). But the escalating card mechanic must be in the rules engine first (Phase 1-2).

---

### Pitfall 4: Territory Card Trading Rules Complexity

**What goes wrong:**
The card trading system is the most rules-complex part of Risk and the most commonly implemented incorrectly. Key errors: tracking escalation per-player instead of globally (the Nth set traded in the game, not the Nth set that player has traded), not forcing trades when a player holds 5+ cards at the start of their turn, not awarding the 2 bonus armies when a traded card matches a territory the player owns, not transferring cards when a player is eliminated (the eliminator gets the victim's cards and may be forced to trade immediately if they now hold 6+).

The escalation sequence is: 4, 6, 8, 10, 12, 15, 20, 25, 30, ... (after 15, it increases by 5 each time). Getting this sequence wrong or tracking it per-player instead of globally breaks game pacing.

**Why it happens:**
The rules are genuinely complex with many edge cases. Different Risk editions have slightly different card rules, causing confusion. The global vs per-player escalation distinction is subtle and many implementations get it wrong. The "forced trade when holding 5+ cards" and "inherit cards on elimination" rules are easily overlooked.

**How to avoid:**
- Implement a global card trade counter on the game state, not per player.
- Encode the exact escalation sequence: `[4, 6, 8, 10, 12, 15]` then `+5` for each subsequent trade.
- Implement card types explicitly: Infantry, Cavalry, Artillery, Wild. Valid sets: 3 of same type, 1 of each type, any 2 + wild.
- Handle edge cases in order: (1) start of turn, check if player has 5+ cards, force trade; (2) after trade, award 2 bonus armies if any traded card depicts a territory the player controls; (3) on player elimination, transfer all cards to the eliminating player; (4) if eliminator now has 6+ cards, force immediate trade(s).
- Write tests for every edge case, especially the elimination-transfer-forced-trade chain.

**Warning signs:**
- Card reinforcements feel too weak late-game (per-player tracking instead of global).
- Players accumulate 7+ cards without being forced to trade.
- Eliminated players' cards vanish instead of transferring.
- No bonus armies awarded for territory matches on traded cards.

**Phase to address:**
Rules engine (Phase 2, after core combat). Cards interact with turn structure, elimination, and reinforcement -- they touch everything.

---

### Pitfall 5: Fortification Without Connected Path Validation

**What goes wrong:**
Fortification (the end-of-turn army movement) requires that the source and destination territories be connected through a continuous chain of territories all owned by the moving player. Developers either skip this validation entirely (allowing teleportation of armies) or implement it incorrectly (only checking direct adjacency, not full path connectivity).

**Why it happens:**
Direct adjacency is simpler to check than path connectivity. The rule is sometimes confused with "move to adjacent territory only" (which is an older variant rule). Implementing BFS/DFS on a subgraph of player-owned territories feels like overkill for a single move, so it gets deferred and then forgotten.

**How to avoid:**
- Implement a `find_connected_territories(player, territory)` function using BFS/DFS on the subgraph of territories owned by that player. This function is also useful for AI decision-making (identifying isolated clusters).
- Fortification validation: destination must be in the connected component of the source territory within the player's owned subgraph.
- This same connectivity function is needed for AI strategic assessment (identifying which territories can reinforce each other), so build it as a reusable utility, not a one-off check.
- Only one fortification move per turn, and at least 1 army must remain on the source territory.

**Warning signs:**
- Armies appearing on territories that have no friendly path to their origin.
- AI moving armies across enemy-controlled chokepoints.
- Fortification working between territories that are owned by the player but separated by enemy territory.

**Phase to address:**
Core game engine (Phase 1-2). This is a rules validation function that the AI also depends on.

---

### Pitfall 6: Game State Consistency and Phase Management Bugs

**What goes wrong:**
A Risk turn has distinct phases: Reinforce -> Attack -> Fortify. Each phase has different legal actions, and transitions between phases have specific rules (e.g., you get a card only if you conquered at least one territory during the attack phase). Common bugs: allowing attacks during reinforcement phase, allowing multiple fortifications, not tracking "conquered at least one territory this turn" for card awards, letting a player act out of turn, not handling player elimination mid-turn (the eliminated player's territories and cards transfer immediately).

**Why it happens:**
Developers model the game state as a flat structure without explicit phase tracking. Without a state machine, it is easy for the UI or AI to issue invalid actions that corrupt the game state. The interaction between phases creates subtle bugs -- for example, if a player conquers a territory, they must move armies into it before continuing to attack, which is a sub-state within the attack phase.

**How to avoid:**
- Model the turn as an explicit state machine: `REINFORCE -> ATTACK -> FORTIFY -> END_TURN`. Add sub-states: `ATTACK_RESULT` (must move armies into conquered territory before next action), `MUST_TRADE_CARDS` (when holding 5+ at turn start).
- Every action should be validated against the current phase. Reject invalid actions with clear error messages.
- Track per-turn flags: `conquered_territory_this_turn` (for card award), `cards_traded_this_turn` (limit per turn).
- Use an action/command pattern: all game mutations go through a single `execute_action(game_state, action)` function that validates and applies changes atomically. No direct state mutation from UI or AI code.
- Write integration tests that play through full games, checking state consistency after every action.

**Warning signs:**
- Players receiving cards without conquering territory.
- Multiple fortifications in a single turn.
- Game crashing when a player is eliminated.
- AI making moves that are illegal for the current phase.

**Phase to address:**
Core game engine (Phase 1). The state machine is the skeleton of the game.

---

### Pitfall 7: AI Decision Space Explosion

**What goes wrong:**
Risk's branching factor is enormous. During reinforcement, a player with 10 bonus armies can distribute them across any combination of their territories. During attack, they can choose any territory to attack from, any adjacent enemy territory to attack, and how many dice to roll. During fortification, they can move armies between any two connected territories. Naive AI implementations that try to evaluate all possible actions either freeze (exponential computation) or make random choices (poor play).

**Why it happens:**
Developers underestimate the combinatorial explosion. Reinforcement alone for a player with 20 territories and 10 armies has C(29,9) = 10,015,005 possible distributions. Minimax/alpha-beta pruning is infeasible for the full action space without aggressive pruning.

**How to avoid:**
- Do not use tree search (minimax/MCTS) as the primary strategy. Use heuristic evaluation with hand-crafted strategic priorities.
- Constrain the AI's decision space with strategic filters: for reinforcement, only consider placing armies on border territories (territories adjacent to enemies). For attacks, only consider territories where the attacker has a meaningful advantage (e.g., 3:1 ratio or better). For fortification, only consider moving armies from interior territories to border territories.
- Implement difficulty tiers through decision quality, not search depth: Easy AI makes random choices from valid actions; Medium AI uses basic heuristics (reinforce weakest border, attack weakest neighbor); Hard AI uses strategic evaluation (continent control value, threat assessment, card timing).
- Profile AI turn time early. If a single AI turn takes more than 100ms, the decision space filtering is insufficient.

**Warning signs:**
- AI turns taking more than 1 second.
- AI distributing armies evenly across all territories (no filtering).
- AI attacking random territories instead of strategic targets.
- Memory usage spiking during AI turns.

**Phase to address:**
AI implementation (Phase 3). But the game engine must expose efficient queries (e.g., "border territories for player X", "connected components for player X") to support AI filtering -- build those in Phase 1-2.

---

### Pitfall 8: UI That Fails to Convey Game-Critical Information

**What goes wrong:**
Risk has a lot of state that the player needs to see at a glance: army counts on every territory, territory ownership (color), continent boundaries, adjacency connections (especially cross-ocean), current phase of turn, cards in hand, card trade-in value, continent bonuses, and which territories are valid targets for the current action. Implementations that show just a colored map with numbers leave the player guessing.

**Why it happens:**
Developers focus on making the map look good and treat the information layer as secondary. The classic Risk board communicates a lot through physical components (cards in hand, dice on the table, the rulebook nearby) that a digital version must replicate explicitly.

**How to avoid:**
- Display army counts prominently on every territory (large, readable numbers, not tiny text).
- Use distinct, colorblind-friendly colors for player ownership (6 players need 6 distinguishable colors).
- Show continent boundaries clearly (outline or shading).
- Display current turn phase prominently: "REINFORCE (5 armies remaining)" / "ATTACK" / "FORTIFY".
- Show cards in hand and current trade-in value.
- Highlight valid actions: during attack, highlight territories the player can attack from and valid targets. During fortify, show connected territories.
- Show a game log of recent actions (what the AI did on its turn).
- Display continent bonus table somewhere accessible.

**Warning signs:**
- Players can't tell which territories are theirs at a glance.
- Players don't know how many armies they have to place.
- Players can't figure out which territories they can attack.
- Players don't know what cards they have or what they're worth.

**Phase to address:**
UI implementation (Phase 2-3). But the information requirements should be defined in Phase 1 so the game engine exposes the right data.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoding adjacency data inline | Quick to get started | Impossible to support alternative maps; errors hard to find and fix | Never -- use a data file or structured constant from day one |
| Skipping the turn state machine | Faster initial development | Every new feature (cards, fortification, elimination) introduces phase-related bugs | Never -- the state machine is cheap to build and prevents entire classes of bugs |
| AI that only evaluates single-step actions | Simple to implement | AI can never plan multi-turn strategies (continent completion, card timing) | Acceptable for Easy difficulty only |
| Flat game state (no event/action log) | Less code | Cannot replay games, debug AI decisions, or show "what happened last turn" to the player | Only in prototype; add logging before AI development |
| Coupling UI directly to game state mutations | Faster UI prototyping | Cannot run headless AI-vs-AI games for testing; game logic becomes untestable | Never -- always separate game logic from presentation |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| AI evaluating all possible army distributions during reinforcement | Turn takes 5+ seconds | Filter to border territories only; use greedy allocation heuristic | More than ~15 territories owned |
| Recalculating connected components on every fortification check | Sluggish fortify phase | Cache connected components per player; invalidate on territory ownership change | 6-player games with many territories each |
| Running full combat simulation for every possible attack | AI turn hangs | Pre-compute probability tables for all army matchups (1-30 vs 1-30); use expected-value lookup | Any game with armies > 10 |
| Rendering full map SVG on every state change | UI becomes laggy | Only update changed territories; use incremental DOM updates | Mid-to-late game with frequent AI turns |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Not showing what AI did on its turn | Player has no idea why the board changed; feels unfair | Show a turn log: "Red attacked Ukraine from Southern Europe (won), fortified 5 armies to Ukraine" |
| No way to speed up AI turns | Watching 5 AI players take turns one-by-one is tedious | Add a "fast forward" or "skip to my turn" button |
| Map doesn't show cross-ocean connections | Player doesn't know Alaska connects to Kamchatka | Draw dashed lines for sea routes; highlight them on hover |
| No undo for reinforcement placement | Player accidentally places armies on wrong territory, stuck with it | Allow undo during reinforcement phase (before committing) |
| Forcing player to click through every dice roll | Tedious when attacking with 20 vs 3 | Add "auto-resolve" / "attack until won or N armies remain" option |
| No indication of continent bonus values | Player doesn't know which continents to prioritize | Show bonus value on the map or in a sidebar panel |

## "Looks Done But Isn't" Checklist

- [ ] **Adjacency data:** Often missing cross-ocean routes -- verify total edge count is exactly 83 and spot-check Alaska-Kamchatka, North Africa-Brazil, East Africa-Middle East, Greenland-Iceland
- [ ] **Dice combat:** Often has incorrect tie resolution or dice count constraints -- run statistical validation (100k+ simulations)
- [ ] **Card escalation:** Often tracked per-player instead of globally -- verify with a test that has multiple players trading sets and check the reinforcement values match 4, 6, 8, 10, 12, 15, 20, 25...
- [ ] **Card transfer on elimination:** Often forgotten -- verify eliminated player's cards transfer to the eliminator, and forced trade triggers if eliminator now holds 6+
- [ ] **Fortification connectivity:** Often only checks adjacency, not full path -- test moving armies between territories separated by 3+ friendly territories with enemy territory nearby
- [ ] **Minimum army on territory:** Often allows territories to reach 0 armies -- verify every territory always has at least 1 army after any action
- [ ] **Continental bonus calculation:** Often misses one territory in a continent definition -- verify each continent has the correct territory count and correct bonus value
- [ ] **Turn card award:** Often awards card regardless of conquest -- verify card is only awarded when player conquered at least one territory during the attack phase, and only one card per turn maximum

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong adjacency data | LOW | Fix the data file; re-run tests. No structural code changes needed if adjacency is data-driven. |
| Dice probability errors | LOW | Fix the comparison logic; re-run statistical tests. Isolated function. |
| Endless AI games | HIGH | Requires rethinking AI evaluation heuristics, aggression tuning, and potentially the card system. Cannot just tweak a parameter. |
| Card rules wrong | MEDIUM | Fix the rules logic, add edge case tests. May need to restructure how game state tracks global trade count. |
| No turn state machine | HIGH | Retrofitting a state machine into existing code requires touching every action handler. Build it first. |
| Coupled UI and game logic | HIGH | Requires extracting game logic into a separate module, rewriting all mutation points. Build separation from day one. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Incorrect adjacency data | Phase 1 (Map/Data) | Automated test: 42 territories, 83 edges, bidirectional, all continents correct |
| Dice probability errors | Phase 1 (Combat engine) | Statistical simulation test: 100k rounds match known probabilities within 1% |
| Endless AI games | Phase 3 (AI) + Phase 1-2 (card escalation) | Run 100 AI-only games; average game length < 200 turns; no game exceeds 500 turns |
| Card trading complexity | Phase 2 (Rules engine) | Unit tests for every edge case: global escalation, forced trade, elimination transfer, territory bonus |
| Fortification path validation | Phase 1-2 (Rules engine) | Unit tests with disconnected player territories; BFS/DFS path verification |
| Game state consistency | Phase 1 (State machine) | Integration test: play full game, assert valid phase transitions, no illegal actions accepted |
| AI decision space explosion | Phase 3 (AI) | Profile: AI turn < 100ms; no memory spikes; filtered action space |
| UI information gaps | Phase 2-3 (UI) | Manual checklist: army counts visible, phase shown, cards shown, valid actions highlighted |

## Sources

- [Risk (game) - Wikipedia](https://en.wikipedia.org/wiki/Risk_(game)) - adjacency data, rule variants, historical errors
- [CS 473 Report - An Intelligent Agent for Risk (Cornell)](https://www.cs.cornell.edu/boom/2001sp/Choi/473repo.html) - AI challenges, state space complexity, TD learning limitations
- [A Risky Proposal: Designing a Risk Game Playing Agent (Stanford CS229)](https://cs229.stanford.edu/proj2012/LozanoBratz-ARiskyProposalDesigningARiskGamePlayingAgent.pdf) - AI heuristics, decision space
- [Evaluating Heuristics in the Game Risk (Maastricht)](https://project.dke.maastrichtuniversity.nl/games/files/bsc/Hahn_Bsc-paper.pdf) - BSR/BST metrics, continent control evaluation
- [Playing the Game of Risk with an AlphaZero Agent](https://www.diva-portal.org/smash/get/diva2:1514096/FULLTEXT01.pdf) - branching factor, MCTS limitations
- [RISK Battle Outcome Odds Calculator](https://riskodds.com/) - combat probability reference
- [Risk dice probability analysis (DataGenetics)](http://www.datagenetics.com/blog/november22011/index.html) - exact per-round expected losses
- [Domination (Risk) Bug Tracker](https://sourceforge.net/p/domination/bugs/) - real-world implementation bugs
- [Official Risk Rules (Hasbro PDF)](https://www.hasbro.com/common/instruct/risk.pdf) - authoritative rule reference
- [How to play Risk (UltraBoardGames)](https://www.ultraboardgames.com/risk/game-rules.php) - card trading rules, escalation sequence
- [Risk FAQ (Kent)](https://www.kent.ac.uk/smsas/personal/odl/riskfaq.htm) - fortification variants, edge cases
- [SMG Studio Risk AI](https://smgstudio.freshdesk.com/support/solutions/articles/11000077687-our-risk-ai) - commercial Risk AI approach

---
*Pitfalls research for: Risk-like strategy board game with AI bots*
*Researched: 2026-03-08*
