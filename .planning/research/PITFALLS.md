# Pitfalls Research

**Domain:** Risk strategy board game — Flutter mobile port (v1.1)
**Researched:** 2026-03-14
**Confidence:** HIGH (mobile-port section) / HIGH (original game-engine section)

---

# Part I: Mobile Port Pitfalls (v1.1 — Flutter)

Pitfalls specific to porting the existing Python/JS game to a Flutter on-device Dart app.

## Critical Pitfalls

### Pitfall M1: AI Bot Blocking the UI Thread

**What goes wrong:**
The HardAgent runs a multi-factor scoring loop on every turn — neighbor traversal across 42 territories, continent scoring, threat assessment, and a 50-iteration attack-probability estimator. In Python this runs server-side and never touches the browser's event loop. In Flutter, if the same logic runs on the main isolate it blocks the UI thread, causing the map to freeze during every bot turn. On a 6-player game with 5 bots, this happens five consecutive times per round. Players see a jank-frozen map with no visual feedback that anything is happening.

**Why it happens:**
Developers coming from a web-app model (server computes, client renders) port all logic to Dart and call it directly from `setState()` callbacks or `onTap` handlers without realizing Dart's event loop is the same thread as Flutter's rendering pipeline. The HardAgent's O(n * k) per-turn complexity is acceptable in 10ms on a modern CPU but catastrophically visible as a frame drop.

**How to avoid:**
- Run all bot turns (Easy, Medium, Hard) in a Dart `Isolate.run()` or a persistent long-lived `Isolate`. Never invoke agent decision logic on the main isolate.
- Use `Isolate.run()` (Flutter 3.7+) for fire-and-forget bot turns. Use a persistent isolate with a `ReceivePort`/`SendPort` pair for the simulation mode where bots play continuously.
- Pass only the serialized `GameState` + static `MapData` to the isolate (immutable data crosses isolate boundaries by reference, not by copy). Do not try to pass the `MapGraph` object with its graph structure — reconstruct it inside the isolate from the map JSON.
- After the isolate returns the new state, call `setState()` on the main isolate to trigger a repaint.
- Add a minimum display delay (e.g., 300ms) so the UI shows a "thinking" indicator between bot turns rather than instantly snapping to the next state.

**Warning signs:**
- Map freezes briefly between bot turns.
- Flutter DevTools shows frames exceeding 16ms during bot computation.
- `compute()` calls appearing in build methods or gesture callbacks.

**Phase to address:**
Dart game engine + AI port phase. Isolate architecture must be established before the first bot turn is wired to the UI.

---

### Pitfall M2: SVG Map → CustomPainter Performance Collapse at Scale

**What goes wrong:**
The web app uses an SVG map where territory paths are native browser elements with hardware-accelerated hit testing. Flutter has no native SVG hit-test widget — the correct approach is `CustomPainter` drawing paths from the map JSON. However, when 42+ polygon paths are drawn inside an `InteractiveViewer` (for pinch-zoom), every pan/zoom gesture triggers a full repaint of all paths. The Flutter engine has documented performance regressions at 100+ paths under zoom transformation: frame times jump from ~4ms to 80ms+. On a mid-range Android device this produces stuttering zoom and unresponsive touch.

**Why it happens:**
`InteractiveViewer` wraps the entire scene in a transform, which invalidates the rasterization cache on every frame during gestures. Flutter's `RepaintBoundary` does not help here because the boundary is *inside* the transformation. The `isComplex: true` hint on `CustomPaint` helps the rasterizer cache the result, but the cache is invalidated on zoom level change.

**How to avoid:**
- Draw territory fills and outlines as pre-rasterized images at app startup using `ui.PictureRecorder`, then display them as `RawImage`. The raster is fixed; only the transform changes.
- Split the map into two layers: a static background `Image` (territory shapes, continent shading, ocean) and a dynamic overlay `CustomPainter` (army count labels, highlight rings for selected/valid territories). Only the dynamic layer repaints on state changes.
- Use `RepaintBoundary` around the dynamic overlay layer, not around the whole map.
- Profile on a low-end Android device (Pixel 3a equivalent or lower) before finalizing the rendering architecture. The risk is that it looks fine on a developer's high-end phone and breaks on player devices.
- Set `isComplex: true` on the static `CustomPaint` to hint to the engine that rasterization caching is worthwhile.

**Warning signs:**
- Frame rate drops below 30fps during pinch-zoom.
- Flutter DevTools shows "Shader compilation jank" on first render.
- `CustomPainter.paint()` is called on every animation frame during scroll/zoom.

**Phase to address:**
Map rendering phase. Architecture decision (pre-rasterized vs live-paint) must be made before building touch interaction.

---

### Pitfall M3: Touch Target Too Small for Densely-Packed Territories

**What goes wrong:**
Risk territories vary dramatically in visual size on the map. Europe and Southeast Asia have small, densely-packed territories. On a phone screen (360dp wide), territories like Great Britain, Iceland, and Ukraine can render as polygons smaller than 30x30dp — well below the 48dp minimum touch target recommended by Material Design and the 44pt minimum recommended by Apple HIG. Players miss-tap the wrong territory, especially during attack selection where precision matters.

**Why it happens:**
Web SVG maps typically render at 800–1200px wide with mouse cursor precision. A phone shows the same map compressed to a third of that width with a 5–8mm fingertip. The SVG polygon bounds do not change — only the viewport scale changes — and no automatic touch-target expansion occurs.

**How to avoid:**
- Implement hit-test expansion: when performing point-in-polygon testing for touch, expand each territory's hit region by a padding radius (start with 6dp). Use the polygon centroid as a fallback target for very small territories.
- Add a disambiguation UI: if a touch falls within the expanded hit regions of two or more territories, show a small popup asking "Did you mean: [Territory A] or [Territory B]?" rather than silently picking the first match.
- Allow pinch-zoom to larger scales (minimum 2x) so players can zoom into congested regions before tapping. Disable territory selection in very compressed zoom levels and show a tooltip instructing users to zoom in.
- Test touch accuracy on a physical phone, not just the simulator, with a finger (not a stylus). The simulator does not simulate fat-finger misses.
- Override `CustomPainter.hitTest()` to return `true` for an expanded bounding box, then do precise polygon testing in the gesture handler.

**Warning signs:**
- Playtesters repeatedly selecting the wrong territory.
- Territories in Europe/Southeast Asia require multiple tap attempts to select.
- Hit testing works perfectly in the emulator but fails on physical devices.

**Phase to address:**
Map interaction phase. Touch target expansion must be designed into the hit-test architecture, not patched after the fact.

---

### Pitfall M4: Dart Port Logic Drift from Python Source

**What goes wrong:**
The Python game engine is the ground truth. The Dart port is a translation. Subtle differences accumulate: integer division semantics (`//` in Python is floor division, `/` in Dart returns `double`; `~/` is integer division), boolean operator short-circuit behavior differences, dict iteration order assumptions, `sorted()` stability guarantees, and the combat dice comparison (`zip` in Python stops at the shortest iterable — confirmed correct by the existing implementation, but easily mistranslated in Dart). Any of these differences silently produce wrong game outcomes without throwing an error.

**Why it happens:**
Developers port logic by reading Python and rewriting in Dart without setting up a cross-language validation harness. The code "looks correct" and passes unit tests written in Dart, but the Dart tests were written from the same (potentially wrong) mental model. The Python reference tests are never run against the Dart output.

**How to avoid:**
- Before porting, capture a suite of golden test fixtures from the Python engine: given a seeded `random.Random` and a specific `GameState`, record the exact output state after each engine function (`execute_attack`, `execute_fortify`, `calculate_reinforcements`, `execute_trade`). Store these as JSON.
- In Dart, replay the same inputs using a seeded `dart:math.Random` with the same seed. Assert that every output field matches the Python golden output exactly.
- Pay special attention to: integer division (use `~/`), `min()`/`max()` on mixed int/double, the dice sorting and pairing logic in `resolve_combat`, the escalation sequence in `execute_trade`, and the BFS traversal order in `connected_territories`.
- Note: Python's `random.Random` and Dart's `dart:math.Random` use different PRNGs (Mersenne Twister vs platform-dependent). You cannot use the same seed and get the same dice rolls. The golden fixtures must capture the *output states*, not attempt to replay the same random draws. Test logic correctness separately from randomness.

**Warning signs:**
- Dart combat simulation win rates diverge from Python statistical tests (should match within ~0.5% over 10k trials).
- Card trade bonus sequence differs between platforms.
- Continent bonus calculation off by 1 in edge cases.
- Fortification validity differs for specific board states.

**Phase to address:**
Dart engine port phase. Golden fixture test harness must be built before any Dart game logic is considered "done."

---

### Pitfall M5: State Management Complexity for Asynchronous Bot Turns

**What goes wrong:**
The web app uses a synchronous game loop (Python runs a turn, sends the result via WebSocket, JS updates the DOM). In Flutter, the game state must be reactive — UI rebuilds when state changes. The complication is that bot turns are async (running in an isolate), the human player's moves are synchronous, and the simulation mode runs continuously without user input. Naive approaches (a single `StatefulWidget` holding the `GameState` with direct `setState()` calls) produce race conditions when the simulation isolate posts a new state while the user is mid-gesture, or fail to correctly handle the "isolate finished, now UI should show animation, then process next turn" flow.

**Why it happens:**
Developers pick a simple state management approach adequate for small apps (Provider, plain `setState`) and do not account for the concurrency model. The problem only manifests late in development when wiring up bot turns and simulation mode, at which point the state management architecture is deeply entrenched.

**How to avoid:**
- Use Riverpod with `AsyncNotifier` for game state. The `AsyncNotifier` cleanly models "computing" (bot turn in progress), "data" (state ready to display), and "error" states.
- Never mutate `GameState` from multiple code paths simultaneously. All state transitions — human move, bot move, simulation tick — go through a single `GameController` that queues actions and processes them serially.
- Model the bot turn lifecycle explicitly: `(idle) -> (bot thinking) -> (animating result) -> (next player)`. The "bot thinking" state shows a loading indicator and disables all human touch input.
- For simulation mode, use a persistent isolate that receives "run N turns" commands and posts back state snapshots, rather than running individual turns in short-lived isolates (avoids per-turn spawning overhead).

**Warning signs:**
- UI allows player input while bot is still computing.
- Tapping during a bot animation causes a state corruption error.
- Simulation mode frame rate is irregular (isolate spawning jitter).
- `setState()` called after widget is disposed (classic async lifecycle bug).

**Phase to address:**
State management architecture phase (should be established in the project scaffold, before any game logic is wired).

---

### Pitfall M6: App Backgrounding Loses Mid-Game State

**What goes wrong:**
A player receives a phone call, switches apps, or locks the screen mid-game. On iOS, the app may be terminated by the OS to free memory within minutes of backgrounding (especially in a long game where memory usage is elevated). On Android, the app process can be killed during "Don't keep activities" mode or when memory is scarce. Both platforms can produce a total state loss — the player returns to find the game reset to the main menu.

**Why it happens:**
Flutter's `AppLifecycleState` is straightforward but the iOS/Android behaviors differ significantly. On iOS, the `paused` state is final — the app may be killed at any point afterward with no further callbacks. On Android, `AppLifecycleState.paused` maps to `Activity.onStop` (not `onPause`), so `inactive` is the last safe point to persist state. The `hidden` state (added in Flutter 3.13) adds another transition to handle. Developers who only test on one platform miss the other's nuances.

**How to avoid:**
- Implement `WidgetsBindingObserver` and save the full `GameState` to local storage (`shared_preferences` for small state, `path_provider` + JSON file for full game state) on every `AppLifecycleState.inactive` callback — this fires on both iOS and Android before the app is potentially killed.
- On app startup, check for a persisted mid-game state and offer to resume.
- Serialize `GameState` to JSON. The existing Python Pydantic model suggests the Dart equivalent should use `freezed` + `json_serializable` for clean `toJson()`/`fromJson()` round-trips.
- Do not rely on `AppLifecycleState.paused` as the save trigger — by that point it may be too late on iOS.
- Test the full lifecycle: background the app, use another app for 10+ minutes (or force-terminate via Xcode/adb), relaunch, and verify the game resumes correctly.

**Warning signs:**
- Game state not persisted on first backgrounding.
- Save/load tested only on one platform.
- Using `AppLifecycleState.paused` as the exclusive save trigger.
- `json_serializable` roundtrip not tested for all `GameState` fields.

**Phase to address:**
App scaffold / state persistence phase. Must be in place before any real gameplay testing — otherwise every backgrounding event during development is a data loss.

---

### Pitfall M7: iOS vs Android Platform Behavior Differences

**What goes wrong:**
Several Flutter behaviors differ between platforms in ways that affect a game app specifically:

1. **Back gesture**: Android has a hardware/gesture back button; iOS has an edge swipe. A game with modal bottom sheets (for card trading, attack confirmation) must handle accidental dismissal via the back gesture. On iOS, `isDismissible: true` (the default for `showModalBottomSheet`) allows users to swipe down the sheet and lose their in-progress move.

2. **Safe area**: On iPhone with Dynamic Island or notch, `SafeArea` insets must account for the bottom home indicator. Placing game controls at the very bottom edge makes them unreachable. On Android in true fullscreen with system chrome hidden, `SafeArea` always returns 0 padding.

3. **Haptic feedback**: iOS has a rich haptic engine (`HapticFeedback.selectionClick`, `lightImpact`, etc.); Android has basic vibration. Calling iOS-style haptics on Android silently fails, which is fine, but not calling them on iOS makes the game feel unpolished.

4. **App Store review**: iOS requires a valid reason for any background capabilities requested in `Info.plist`. A game with no networking should request nothing, but if the save-state mechanism uses background fetch, it triggers review scrutiny.

**Why it happens:**
Flutter's "write once, run anywhere" promise obscures platform differences. Developers test on one platform, ship to both, and discover issues after release.

**How to avoid:**
- Set `isDismissible: false` and `enableDrag: false` for game action bottom sheets (attack selection, card trade). Only allow explicit cancel buttons.
- Wrap the entire game scaffold in `SafeArea` with explicit `bottom: true`. Test on iPhone 14 Pro (Dynamic Island) and a notch-equipped device.
- Use `HapticFeedback.selectionClick()` for territory selection and `HapticFeedback.mediumImpact()` for conquests — these are cross-platform no-ops where unsupported.
- Test on physical devices for both platforms before any milestone sign-off. The iOS Simulator does not reproduce haptics, gesture speed, or GPU rasterization faithfully.

**Warning signs:**
- Game-critical bottom sheets being accidentally dismissed during testing.
- UI elements clipped by the home indicator on iPhone.
- No haptic feedback on territory selection on a physical iPhone.

**Phase to address:**
UI and interaction phase. Platform adaptation decisions must be made per-widget, not as a post-hoc pass.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Running bot logic on the main isolate | Simpler code, no isolate setup | UI freezes every bot turn; unacceptable gameplay | Never — isolate for bots from day one |
| Using `compute()` for every bot turn | Easy concurrency | Per-call isolate spawn overhead accumulates in simulation mode; less stable performance | Only for occasional one-off computations, not repeated bot turns |
| Skipping golden test fixtures | Faster initial port | Dart logic silently diverges from Python; bugs found during gameplay not tests | Never — golden fixtures are cheap to generate; divergence is expensive to debug |
| Persisting state only on `AppLifecycleState.paused` | Simpler lifecycle code | State loss on iOS (OS can kill before `paused` fires reliably) | Never — use `inactive` as the trigger |
| Implementing hit testing as bounding-box only (no polygon test) | Fast to code | Players select wrong territory in dense regions; unfixable without architecture change | Acceptable as a temporary development scaffold only |
| Single `StatefulWidget` holding `GameState` | Quick to prototype | Race conditions with async bot turns; cannot be cleanly extended to simulation mode | Only in throw-away prototype |
| Drawing all 42 territory paths live in `CustomPainter` | Simple rendering code | Performance collapse on mid-range Android during zoom | Only if app targets high-end phones only |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Dart Isolate ↔ GameState | Passing mutable objects (maps, lists) — they get copied, not shared | Pass only primitively-serializable state (or `Uint8List` encoded JSON); reconstruct complex types inside isolate |
| `freezed` + `json_serializable` for GameState | Missing `@JsonSerializable(explicitToJson: true)` on nested objects — nested objects serialize as `{}` | Add `explicitToJson: true` to all parent classes; run `flutter pub run build_runner build` and inspect the generated JSON |
| `InteractiveViewer` + `CustomPainter` | Calling `controller.value` inside `CustomPainter.paint()` to manually transform hit points — off by a factor when zoom origin is not (0,0) | Use `controller.toScene(localPosition)` to convert touch coordinates back to scene space before polygon hit testing |
| `AppLifecycleObserver` cleanup | Adding `WidgetsBinding.instance.addObserver(this)` without `removeObserver(this)` in `dispose()` — memory leak that grows worse in long game sessions | Always pair `addObserver` / `removeObserver` in `initState` / `dispose` |
| `showModalBottomSheet` dismissal | Default `isDismissible: true` allows swipe-down dismiss during game actions | Set `isDismissible: false`, `enableDrag: false` for all game-critical sheets; provide explicit cancel action |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Live CustomPainter with InteractiveViewer zoom | FPS drops to 30–40 during pinch-zoom on mid-range Android | Pre-rasterize static layer; only repaint dynamic overlay | Always on devices below Pixel 6 / iPhone 12 class |
| Spawning a new isolate per bot turn | Jitter in simulation mode; irregular frame cadence | Use persistent isolate with message loop for simulation mode | Simulation mode with 5 bots; ~5 isolate spawns/round |
| Full widget tree rebuild on every `GameState` change | Unnecessary repaints of map, sidebar, and status bar simultaneously | Use Riverpod `select()` to rebuild only widgets whose slice of state changed | Mid-game with frequent AI turns |
| Polygon hit testing all 42 territories on every touch event | Touch response latency on slow devices | Spatial index (quadtree or grid bucket) the territory centroids; only test nearby polygons | Always — O(42) is fine, but sloppy polygon math is slow |
| Serializing GameState to JSON on every state change | Laggy state updates | Only serialize to JSON on `AppLifecycleState.inactive`; use in-memory immutable objects otherwise | Any frequent state change (every attack roll) |

---

## UX Pitfalls (Mobile-Specific)

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No zoom on map | Players cannot select small territories in Europe / SE Asia | `InteractiveViewer` with pinch-zoom, min 1x, max 4x; snap-to-territory on double-tap |
| Bottom sheet dismissed by back gesture mid-attack | Player loses attack selection; board state intact but player confused | `isDismissible: false`; handle Android back button explicitly with `PopScope` |
| Bot turns instant with no feedback | Board state changes feel jarring and untrackable | Minimum 300ms delay + "Thinking..." indicator + brief territory highlight for conquests |
| Army count labels too small to read at 1x zoom | Player cannot count armies in late game with 20+ per territory | Minimum 14sp text for army counts; scale label size with zoom level |
| No game resume prompt on cold start after backgrounding | Player re-opens app and is dropped to main menu; game lost | Detect persisted state on startup and show "Resume game?" dialog before main menu |
| No disambiguation for dense territory taps | Player selects Madagascar when trying to tap East Africa | Show tap-disambiguation popup when touch falls in overlapping hit-test zones |

---

## "Looks Done But Isn't" Checklist

- [ ] **Bot turn isolation:** Verify bot logic runs in an isolate — add artificial 50ms delay to the main thread and confirm no jank during bot computation
- [ ] **Dart/Python logic parity:** Run the golden fixture test suite; all fixtures pass before any bot is considered "ported"
- [ ] **Touch targets:** Test on a physical phone; tap each of Great Britain, Iceland, Ukraine, Japan, Siam, and New Guinea 5 times and verify correct selection
- [ ] **State persistence:** Background the app for 10 minutes, force-terminate via OS, relaunch — game resumes correctly on both iOS and Android
- [ ] **Bottom sheet dismissal:** Test all game-action bottom sheets with Android back button and iOS downward swipe — none should dismiss accidentally
- [ ] **Safe area:** Verify no UI elements are clipped by Dynamic Island, notch, or home indicator on iPhone and Android devices with gesture navigation
- [ ] **Zoom hit testing:** After pinch-zooming to 3x, tap small territories — hit test coordinates correctly transform through the InteractiveViewer matrix
- [ ] **Simulation mode:** Run 20-game simulation; no frame rate irregularity, no memory growth per game, game ends correctly each time
- [ ] **App lifecycle:** `WidgetsBindingObserver` `removeObserver` called in every widget's `dispose()` that adds an observer

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Bot on main thread discovered after full UI built | HIGH | Requires architectural change to all bot invocation sites; add isolate layer and convert all state updates to message-passing |
| Logic drift found late in integration testing | HIGH | Must trace divergence to specific function, fix, regenerate golden fixtures, retest all dependent functions |
| No state persistence when player reports data loss | MEDIUM | Lifecycle observer and JSON serialization can be added without engine changes; 1–2 days of work |
| Touch target misses on physical devices | MEDIUM | Hit-test expansion is isolated to the map widget's gesture handler; can be tuned without touching other systems |
| Performance collapse under zoom found at QA | HIGH if pre-rasterization not already planned; LOW if architecture is correct | Switch rendering to pre-rasterized approach requires rewriting the map widget from scratch |
| Bottom sheet accidental dismissal reported | LOW | Add `isDismissible: false` to the relevant `showModalBottomSheet` calls |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| AI blocking UI thread | Dart engine + bot isolate architecture (Phase 1 of mobile) | Flutter DevTools: frame time stays < 16ms during bot turn in 5-bot game |
| CustomPainter zoom performance | Map rendering phase | 60fps during pinch-zoom on Pixel 3a or equivalent; DevTools GPU graph clean |
| Touch targets too small | Map interaction phase | Physical device test: 5/5 correct taps on smallest territories in Europe/SE Asia |
| Dart/Python logic drift | Dart engine port phase | Golden fixture test suite passes 100%; Dart combat stats match Python within 0.5% |
| Async state management complexity | App scaffold / state management phase (before game wiring) | No race conditions; no `setState after dispose` errors; simulation mode stable |
| App backgrounding state loss | Lifecycle persistence phase | Resume test on iOS + Android after force-terminate |
| iOS/Android behavioral differences | UI/interaction phase | Manual test checklist on physical devices for both platforms |

---

# Part II: Game Rules Engine Pitfalls (v1.0 — Still Relevant for Port Verification)

These pitfalls were identified during v1.0 development. They remain relevant as verification targets when the Dart port is validated against the Python source.

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
- Implement a `connectedTerritories(player, territory)` function using BFS/DFS on the subgraph of territories owned by that player. This function is also useful for AI decision-making (identifying isolated clusters).
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
- Use an action/command pattern: all game mutations go through a single `executeAction(gameState, action)` function that validates and applies changes atomically. No direct state mutation from UI or AI code.
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

## Technical Debt Patterns (Game Rules)

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoding adjacency data inline | Quick to get started | Impossible to support alternative maps; errors hard to find and fix | Never -- use a data file or structured constant from day one |
| Skipping the turn state machine | Faster initial development | Every new feature (cards, fortification, elimination) introduces phase-related bugs | Never -- the state machine is cheap to build and prevents entire classes of bugs |
| AI that only evaluates single-step actions | Simple to implement | AI can never plan multi-turn strategies (continent completion, card timing) | Acceptable for Easy difficulty only |
| Flat game state (no event/action log) | Less code | Cannot replay games, debug AI decisions, or show "what happened last turn" to the player | Only in prototype; add logging before AI development |
| Coupling UI directly to game state mutations | Faster UI prototyping | Cannot run headless AI-vs-AI games for testing; game logic becomes untestable | Never -- always separate game logic from presentation |

---

## Performance Traps (Game Rules)

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| AI evaluating all possible army distributions during reinforcement | Turn takes 5+ seconds | Filter to border territories only; use greedy allocation heuristic | More than ~15 territories owned |
| Recalculating connected components on every fortification check | Sluggish fortify phase | Cache connected components per player; invalidate on territory ownership change | 6-player games with many territories each |
| Running full combat simulation for every possible attack | AI turn hangs | Pre-compute probability tables for all army matchups (1-30 vs 1-30); use expected-value lookup | Any game with armies > 10 |
| Rendering full map on every state change | UI becomes laggy | Only update changed territories; use incremental updates | Mid-to-late game with frequent AI turns |

---

## UX Pitfalls (Game Rules)

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Not showing what AI did on its turn | Player has no idea why the board changed; feels unfair | Show a turn log: "Red attacked Ukraine from Southern Europe (won), fortified 5 armies to Ukraine" |
| No way to speed up AI turns | Watching 5 AI players take turns one-by-one is tedious | Add a "fast forward" or "skip to my turn" button |
| Map doesn't show cross-ocean connections | Player doesn't know Alaska connects to Kamchatka | Draw dashed lines for sea routes; highlight them on hover |
| No undo for reinforcement placement | Player accidentally places armies on wrong territory, stuck with it | Allow undo during reinforcement phase (before committing) |
| Forcing player to click through every dice roll | Tedious when attacking with 20 vs 3 | Add "auto-resolve" / "attack until won or N armies remain" option |
| No indication of continent bonus values | Player doesn't know which continents to prioritize | Show bonus value on the map or in a sidebar panel |

---

## "Looks Done But Isn't" Checklist (Game Rules)

- [ ] **Adjacency data:** Often missing cross-ocean routes -- verify total edge count is exactly 83 and spot-check Alaska-Kamchatka, North Africa-Brazil, East Africa-Middle East, Greenland-Iceland
- [ ] **Dice combat:** Often has incorrect tie resolution or dice count constraints -- run statistical validation (100k+ simulations)
- [ ] **Card escalation:** Often tracked per-player instead of globally -- verify with a test that has multiple players trading sets and check the reinforcement values match 4, 6, 8, 10, 12, 15, 20, 25...
- [ ] **Card transfer on elimination:** Often forgotten -- verify eliminated player's cards transfer to the eliminator, and forced trade triggers if eliminator now holds 6+
- [ ] **Fortification connectivity:** Often only checks adjacency, not full path -- test moving armies between territories separated by 3+ friendly territories with enemy territory nearby
- [ ] **Minimum army on territory:** Often allows territories to reach 0 armies -- verify every territory always has at least 1 army after any action
- [ ] **Continental bonus calculation:** Often misses one territory in a continent definition -- verify each continent has the correct territory count and correct bonus value
- [ ] **Turn card award:** Often awards card regardless of conquest -- verify card is only awarded when player conquered at least one territory during the attack phase, and only one card per turn maximum

---

## Recovery Strategies (Combined)

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong adjacency data | LOW | Fix the data file; re-run tests. No structural code changes needed if adjacency is data-driven. |
| Dice probability errors | LOW | Fix the comparison logic; re-run statistical tests. Isolated function. |
| Endless AI games | HIGH | Requires rethinking AI evaluation heuristics, aggression tuning, and potentially the card system. Cannot just tweak a parameter. |
| Card rules wrong | MEDIUM | Fix the rules logic, add edge case tests. May need to restructure how game state tracks global trade count. |
| No turn state machine | HIGH | Retrofitting a state machine into existing code requires touching every action handler. Build it first. |
| Coupled UI and game logic | HIGH | Requires extracting game logic into a separate module, rewriting all mutation points. Build separation from day one. |
| Bot on main thread discovered late | HIGH | Requires architectural change to all bot invocation sites; add isolate layer and convert all state updates to message-passing |
| Logic drift found late in integration testing | HIGH | Must trace divergence to specific function, fix, regenerate golden fixtures, retest all dependent functions |
| No state persistence when player reports data loss | MEDIUM | Lifecycle observer and JSON serialization can be added without engine changes; 1–2 days of work |
| Touch target misses on physical devices | MEDIUM | Hit-test expansion is isolated to the map widget's gesture handler; can be tuned without touching other systems |

---

## Pitfall-to-Phase Mapping (Combined)

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| AI blocking UI thread | Dart engine + bot isolate architecture | Flutter DevTools: frame time < 16ms during 5-bot game |
| CustomPainter zoom performance | Map rendering phase | 60fps pinch-zoom on Pixel 3a; DevTools GPU graph clean |
| Touch targets too small | Map interaction phase | Physical device: 5/5 correct taps on Europe/SE Asia territories |
| Dart/Python logic drift | Dart engine port phase | Golden fixture test suite 100% pass; combat stats match within 0.5% |
| Async state management complexity | App scaffold phase (before game wiring) | No race conditions; simulation mode stable |
| App backgrounding state loss | Lifecycle persistence phase | Force-terminate on iOS + Android; game resumes correctly |
| iOS/Android behavioral differences | UI/interaction phase | Manual checklist on physical devices, both platforms |
| Incorrect adjacency data | Phase 1 (Map/Data) | Automated test: 42 territories, 83 edges, bidirectional, all continents correct |
| Dice probability errors | Phase 1 (Combat engine) | Statistical simulation: 100k rounds match known probabilities within 1% |
| Endless AI games | Phase 3 (AI) + Phase 1-2 (card escalation) | 100 AI-only games; average < 200 turns; no game exceeds 500 turns |
| Card trading complexity | Phase 2 (Rules engine) | Unit tests for every edge case: global escalation, forced trade, elimination transfer |
| Fortification path validation | Phase 1-2 (Rules engine) | Unit tests with disconnected player territories |
| Game state consistency | Phase 1 (State machine) | Integration test: full game, assert valid phase transitions |
| AI decision space explosion | Phase 3 (AI) | Profile: AI turn < 100ms; no memory spikes |

---

## Sources

**Mobile / Flutter sources:**
- [Flutter concurrency and isolates documentation](https://docs.flutter.dev/perf/isolates) — Isolate usage, compute() vs persistent isolates
- [Flutter AppLifecycleState API](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html) — Lifecycle state reference
- [Migration guide: AppLifecycleState.hidden](https://docs.flutter.dev/release/breaking-changes/add-applifecyclestate-hidden) — New `hidden` state in Flutter 3.13+
- [Flutter CustomPainter class docs](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html) — hitTest, semanticsBuilder
- [Flutter accessibility guidelines](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility) — 48dp minimum touch target
- [Flutter automatic platform adaptations](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations) — iOS/Android behavior differences
- [Flutter GitHub Issue #72066](https://github.com/flutter/flutter/issues/72066) — CustomPainter + InteractiveViewer path performance regression
- [Flutter GitHub Issue #72718](https://github.com/flutter/flutter/issues/72718) — Zoom/pan path performance degradation confirmed
- [Flutter GitHub Issue #78543](https://github.com/flutter/flutter/issues/78543) — Bezier path performance under transform
- [Flutter GitHub Issue #116715](https://github.com/flutter/flutter/issues/116715) — Dart Isolate slow in release mode background on iOS/Android
- [Dart numbers documentation](https://dart.dev/guides/language/numbers) — Dart integer/float semantics vs Python
- [Dart Random class API](https://api.dart.dev/dart-math/Random-class.html) — Seeded PRNG behavior
- [showModalBottomSheet isDismissible documentation](https://api.flutter.dev/flutter/material/showModalBottomSheet.html) — Dismissal prevention
- [SVG rasterization optimization via Vector Graphics Compiler](https://medium.com/software-genesis-group/supercharging-flutter-vectors-how-i-reduced-svg-rasterization-time-by-98-e5b6c38bc7b7) — Pre-compilation approach
- [MapChart Flutter app experience](https://blog.mapchart.net/app/flutter-for-developing-mapchart-mobile-app/) — Real-world Flutter map app pitfalls
- [Handling app lifecycle background execution (Android 14 / iOS 17)](https://medium.com/@shubhampawar99/handling-background-services-in-flutter-the-right-way-across-android-14-ios-17-b735f3b48af5) — Platform-specific background restrictions
- [Riverpod why immutability](https://docs-v2.riverpod.dev/docs/concepts/why_immutability) — Freezed copyWith efficiency

**Game rules sources (v1.0):**
- [Risk (game) - Wikipedia](https://en.wikipedia.org/wiki/Risk_(game)) — adjacency data, rule variants, historical errors
- [RISK Battle Outcome Odds Calculator](https://riskodds.com/) — combat probability reference
- [Risk dice probability analysis (DataGenetics)](http://www.datagenetics.com/blog/november22011/index.html) — exact per-round expected losses
- [Official Risk Rules (Hasbro PDF)](https://www.hasbro.com/common/instruct/risk.pdf) — authoritative rule reference

---
*Pitfalls research for: Risk mobile Flutter port (v1.1) + game rules reference (v1.0)*
*Researched: 2026-03-14*
