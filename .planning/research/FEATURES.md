# Feature Research

**Domain:** Flutter mobile port of an existing Python/JS Risk board game (Android + iOS)
**Researched:** 2026-03-14
**Confidence:** HIGH

## Context

This file covers **mobile-specific features** for the Flutter port. The game mechanics (42 territories, dice combat, cards, 3 AI levels, simulation mode, blitz attack) are already built and validated in the Python/JS version. The question here is: what do mobile users expect that the web version did not need to address?

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features mobile users assume exist. Missing these = app feels unfinished or broken.

#### Touch Interaction with the Map

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Tap to select territory | Primary interaction on mobile; no mouse hover or click | MEDIUM | Tap source territory, then tap target; highlight valid targets after first tap |
| Pinch-to-zoom on map | Standard mobile map interaction since 2011; users will pinch immediately | MEDIUM | Flutter `InteractiveViewer` handles this; min scale ~1x, max ~4x for territory legibility |
| Pan/drag to scroll map | Map won't fit on phone screen without scrolling | LOW | Comes with `InteractiveViewer`; needs to coexist with tap-to-select without conflicts |
| Visual tap feedback (highlight/ring) | User must know their tap registered on a small touch target | LOW | Highlight ring or glow on selected territory; scale up army count badge |
| Large enough tap targets | 42 territories on a phone screen means small hit areas | MEDIUM | Expand tap hitbox beyond visual territory boundary; min 44pt iOS / 48dp Android |

#### Game Save and Resume

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Auto-save in-progress game | Mobile users get interrupted constantly (calls, notifications, app switches) | MEDIUM | Serialize full game state to local storage on every turn end; restore on app launch |
| Resume on app restart | App killed by OS, user returns tomorrow; game must still be there | LOW | If saved game exists on launch, offer "Continue" and "New Game" buttons |
| Single active game slot | Users don't need multiple simultaneous saves; one game at a time is sufficient | LOW | Overwrite previous save on new game start after confirmation prompt |

#### Settings Screen

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Bot speed control | With 5 bots, watching each one animate takes 80% of game time | LOW | Slider or segmented control: Slow / Fast / Instant; persist across games |
| Bot difficulty presets per slot | User must configure their opponents before starting | LOW | Already in existing web UI; translate to mobile bottom sheet or setup screen |
| Haptic feedback toggle | Some users find vibration annoying; must be disableable | LOW | Global on/off toggle; default ON |
| Colorblind mode | Risk uses player colors to distinguish territories; ~8% of males are colorblind | MEDIUM | Swap territory colors to a colorblind-safe palette (e.g., Wong palette: orange, sky blue, vermillion, bluish-green, yellow, reddish-purple) |
| App theme (dark/light) | System dark mode is expected by default on modern Android/iOS | LOW | Respect system `Brightness`; optionally override in settings |

#### Orientation and Screen Size

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Landscape support | Strategy games with maps are far more comfortable in landscape; users rotate naturally | MEDIUM | Map has a wide aspect ratio; sidebar content moves to bottom drawer in portrait, side panel in landscape |
| Portrait support (phone) | Users will play one-handed; forcing landscape is jarring | MEDIUM | Responsive layout: map takes full width, phase controls in bottom sheet |
| Tablet layout | Tablets have screen real estate the phone layout wastes; side-by-side map + sidebar | MEDIUM | Breakpoint at 600dp: show persistent side panel instead of bottom sheet; Flutter's `LayoutBuilder` handles this |

#### End of Session Clarity

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Victory / defeat screen | Satisfying close to the game; missing = feels like app crashed | LOW | Full-screen modal with winner name, game duration, armies defeated; "Play Again" and "Menu" buttons |
| Abandon game confirmation | Tapping back during a game should ask "are you sure?" not silently exit | LOW | `WillPopScope` / `PopScope` with dialog; save state is preserved either way |

#### Accessibility

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Minimum touch target sizes | Apple HIG requires 44pt; Google requires 48dp; smaller = user misses taps | MEDIUM | Critical for territory selection on phone; use invisible hit-test padding |
| Text contrast 4.5:1 minimum | WCAG AA; system fonts on colored territory backgrounds may fail | LOW | Test army count numbers against all 6 player colors; use white text with drop shadow |
| Don't rely on color alone | 8% of males can't distinguish red/green; can't tell player territories apart | MEDIUM | Add player initials or distinct icons overlaid on territories in addition to color |

---

### Differentiators (Competitive Advantage)

Features that set this app apart. Not required, but high value for the target audience.

#### Haptic Feedback

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Dice roll haptic burst | Makes combat feel tactile and satisfying; Risk: Global Domination doesn't do this well | LOW | `HapticFeedback.mediumImpact()` on each die resolution; heavier for wins, lighter for losses |
| Territory conquest haptic | Distinct "capture" feel reinforces the moment of victory in combat | LOW | `HapticFeedback.heavyImpact()` on territory capture |
| Turn start haptic | Subtle nudge when control returns to human player | LOW | `HapticFeedback.selectionClick()` at start of human turn |
| Invalid action haptic | Tapping a non-adjacent territory during attack: warn the user | LOW | `HapticFeedback.vibrate()` (short buzz) for invalid selections |

#### Tutorial / Onboarding

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Optional interactive tutorial | Risk rules are complex; a 5-minute guided game teaches mechanics in context | HIGH | Step-by-step guided game: highlight UI elements, explain each phase, provide a pre-set board state |
| Skip for experienced players | Forcing tutorial on returning players is a top complaint in Risk: Global Domination reviews | LOW | "Skip tutorial" on first launch; accessible from Settings later |
| Contextual rule hints | First time a player can trade cards, offer a tooltip explaining what sets are valid | MEDIUM | One-time tooltips keyed to game events (first card, first blitz opportunity, etc.) |

#### Simulation Mode (AI vs AI Watch Mode)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Watch mode with speed slider | See AI strategies play out; already exists in Python/JS version | LOW | Port existing simulation mode; add speed slider for mobile (Instant is most useful) |
| Tap to inspect territory during sim | Pause-on-tap to read army counts without stopping simulation | LOW | Tap a territory shows a popup with territory name, owner, army count; resumes automatically |

#### Game Summary and Stats

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| End-game breakdown screen | Shows winner, turn count, territories held per player, armies eliminated | LOW | Aggregate stats during game; display after victory/defeat |
| Win/loss history (local) | Motivates replay; shows improvement over time | LOW | Persist last N game results to local storage with `shared_preferences` |

#### Polish

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Smooth territory selection animation | Selected territory visually pops; feels responsive and polished | LOW | Scale + glow animation on tap, 150ms |
| Dice result animation | Brief animated dice before showing result; adds tension to combat | MEDIUM | 500ms max; fast enough to not feel slow. Must be skippable |
| Bot "thinking" indicator | A subtle spinner or animation during bot turn prevents the UI from appearing frozen | LOW | Show animated dots or progress indicator during bot computation |

---

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create specific problems in a mobile context.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Undo / take-back | "I mis-tapped the wrong territory" | Undermines strategic commitment; complex to implement with dice already resolved; already flagged as anti-feature in PROJECT.md | Confirmation step before committing an attack: "Attack Brazil with 3 armies?" — prevents accidental taps |
| Multiplayer (online, human vs human) | Social appeal; board games are multiplayer by nature | Requires server infrastructure, auth, turn timers, disconnection handling; out of scope per PROJECT.md | Focus on AI quality; AI opponents provide challenge without infrastructure |
| Sound effects and background music | Atmosphere and immersion | Explicitly out of scope in PROJECT.md; adds asset weight and licensing complexity | Haptic feedback provides tactile response without audio assets |
| Animated dice rolling (3D physics) | Visual spectacle; Risk: Global Domination has this | High rendering cost; significant implementation time for marginal gameplay value | Show dice face results with a brief 150ms entrance animation; focus on speed |
| Push notifications for bot turns | "Let me know when it's my turn" | Not needed — bots take turns instantly; only relevant for async human multiplayer which is out of scope | Bot "thinking" indicator is sufficient |
| Forced landscape lock | "Map is bigger in landscape" | Android 16 (API 36, 2025) removes forced orientation restrictions for large screens; locking causes rejection on modern Android | Support both orientations with responsive layout |
| Multiple save slots | "Save before a risky attack" | Enables save-scumming against bots; undermines strategic commitment | Single auto-save slot that overwrites on each turn end; no manual save |
| Cloud sync / iCloud / Google Play Games | "Play on my tablet and phone" | Requires auth, conflict resolution, backend; massive scope increase | Local-only is sufficient for single-player AI game |

---

## Feature Dependencies

```
[Auto-save / Resume]
    +--requires--> [Game State Serialization (Dart)]
    +--requires--> [Local Storage (shared_preferences or Hive)]

[Touch Map Interaction]
    +--requires--> [Interactive map widget (InteractiveViewer or CustomPainter)]
    +--requires--> [Territory hit-test logic (tap coordinate -> territory ID)]
    +--enhances--> [Attack / Draft / Fortify phase UI]

[Responsive Layout (portrait + landscape)]
    +--requires--> [LayoutBuilder breakpoint logic]
    +--requires--> [Bottom sheet for portrait, side panel for landscape]

[Haptic Feedback]
    +--requires--> [Flutter HapticFeedback API or haptic_feedback package]
    +--enhances--> [Dice roll, territory capture, invalid action events]

[Colorblind Mode]
    +--requires--> [Player color theme system (not hardcoded colors)]
    +--enhances--> [Map territory color rendering]

[Tutorial / Onboarding]
    +--requires--> [Full game loop working]
    +--requires--> [Pre-set board state capability]

[Tablet Layout]
    +--requires--> [Responsive layout breakpoint logic]
    +--enhances--> [Landscape layout]

[Settings Screen]
    +--requires--> [Local persistence (shared_preferences)]
    +--enhances--> [All configurable features (bot speed, haptics, colorblind, theme)]

[Win/Loss History]
    +--requires--> [End-game summary data]
    +--requires--> [Local persistence (shared_preferences)]
```

### Dependency Notes

- **Touch map interaction is the foundation.** Every gameplay action flows through it. It must be working before any turn-phase UI is built.
- **Responsive layout affects everything.** Build the layout system first, then place UI components inside it, or retrofitting is very painful.
- **Auto-save requires Dart game state serialization.** The game engine port to Dart (from Python) must be JSON-serializable before save/resume can work.
- **Tutorial requires full game loop.** It cannot be built until the game is fully playable; it wraps the real game with an overlay.
- **Colorblind mode requires a theme system.** Player colors cannot be hardcoded constants; they must be resolved through a theme map that can be swapped.
- **Haptics are independent.** They can be added at any point; they are enhancements, not prerequisites.

---

## MVP Definition

### Launch With (v1 — mobile port)

Minimum viable product that proves the Flutter port is a real, playable game.

- [ ] Touch map interaction (tap-to-select, pinch-zoom, pan) — without this, the game is not playable on mobile
- [ ] Responsive layout (portrait phone + landscape phone) — users will rotate immediately
- [ ] All game mechanics ported from Python/JS (draft, attack, fortify, cards, bots, simulation) — parity with web version is the goal
- [ ] Auto-save / resume — mobile users will be interrupted; crash = game lost is unacceptable
- [ ] Settings screen with bot speed, haptic toggle, colorblind mode — minimum accessibility and configurability
- [ ] Haptic feedback on key events (dice, capture, invalid) — differentiates from web; feels native
- [ ] Victory / defeat screen — satisfying close to each game
- [ ] Abandon game confirmation — standard mobile navigation pattern

### Add After Validation (v1.x)

Add once core gameplay is stable and users have tried it.

- [ ] Tablet layout (persistent side panel at 600dp+) — tablet users will notice immediately but it's not blocker for phone launch
- [ ] Tutorial / onboarding flow — high value but high cost; needs full game loop working first
- [ ] Contextual rule hints (first card, first blitz) — polish pass after core UX works
- [ ] End-game stats breakdown — add after confirming win/loss screen works
- [ ] Win/loss history — requires persistence but minimal code once settings storage exists

### Future Consideration (v2+)

Defer until core game is solid and user-validated.

- [ ] Interactive tutorial — significant investment; validate basic play first
- [ ] Dark/light theme override in settings — system theme auto-detection is sufficient for launch
- [ ] Dice roll animation — polish for post-launch; keep it skippable

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Touch map (tap, pinch-zoom, pan) | HIGH | MEDIUM | P1 |
| Auto-save / resume | HIGH | MEDIUM | P1 |
| Portrait + landscape layout | HIGH | MEDIUM | P1 |
| Settings screen (bot speed, haptic toggle) | HIGH | LOW | P1 |
| Haptic feedback (dice, capture, invalid) | HIGH | LOW | P1 |
| Victory / defeat screen | HIGH | LOW | P1 |
| Abandon game confirmation | MEDIUM | LOW | P1 |
| Colorblind mode | MEDIUM | MEDIUM | P1 |
| Tablet layout (side panel at 600dp+) | MEDIUM | MEDIUM | P2 |
| Contextual rule hints | MEDIUM | MEDIUM | P2 |
| End-game stats breakdown | MEDIUM | LOW | P2 |
| Win/loss history | LOW | LOW | P2 |
| Interactive tutorial | HIGH | HIGH | P3 |
| Dark/light theme override | LOW | LOW | P3 |
| Dice roll animation | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch — game is broken or unusable without it
- P2: Should have — quality of life; adds significantly to experience
- P3: Nice to have — polish; defer until P1/P2 are validated

---

## Competitor Feature Analysis

| Feature | Risk: Global Domination (SMG Studio) | Our Flutter Port |
|---------|--------------------------------------|-----------------|
| Touch map | Pinch-zoom, tap-to-select; polished | InteractiveViewer + GestureDetector; functional |
| Save/resume | Yes; auto-saves mid-game | Auto-save on every turn end to local storage |
| Haptic feedback | Minimal / absent per user reports | Deliberate haptic vocabulary: dice, capture, invalid, turn start |
| Tutorial | Yes, but forced (top complaint) | Optional; accessible from settings; skippable |
| Orientation | Landscape-only on phone | Both portrait and landscape; responsive layout |
| Tablet support | Yes, with adapted layout | Side panel layout at 600dp+ breakpoint |
| Colorblind mode | Not present per reviews | Wong palette swap via settings |
| Bot speed control | Present | Present (Slow / Fast / Instant) |
| Monetization | Free-to-play with ads and IAP | None; local-only free app |
| Multiplayer | Core feature (online) | Not planned; single-player AI focus |

---

## Sources

- [Flutter GestureDetector documentation](https://docs.flutter.dev/ui/interactivity/gestures) — tap, scale, pan gesture handling
- [Flutter InteractiveViewer API](https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html) — pinch-zoom and pan widget
- [flutter_interactive_svg on GitHub](https://github.com/roopepal/flutter_interactive_svg) — SVG map + InteractiveViewer pattern
- [Flutter CustomPainter performance issue #72066](https://github.com/flutter/flutter/issues/72066) — known perf issue with complex paths + InteractiveViewer
- [Flutter HapticFeedback API](https://api.flutter.dev/flutter/services/HapticFeedback-class.html) — built-in haptic class (light/medium/heavy/selection/success/warning)
- [haptic_feedback Flutter package](https://pub.dev/packages/haptic_feedback) — cross-platform consistent haptics; falls back gracefully on older Android
- [RISK: Global Domination on Google Play](https://play.google.com/store/apps/details?id=com.hasbro.riskbigscreen&hl=en_US) — primary mobile competitor; 4.34/5, 19M downloads
- [Risk: Global Domination App Review — Common Sense Media](https://www.commonsensemedia.org/app-reviews/risk-global-domination) — user feedback and feature notes
- [Android 16 orientation/resizability changes](https://android-developers.googleblog.com/2025/01/orientation-and-resizability-changes-in-android-16.html) — forced orientation lock removed at API 36
- [Android 17 orientation/resizability changes](https://android-developers.googleblog.com/2026/02/prepare-your-app-for-resizability-and.html) — opt-out removed for large screens at API 37
- [Mobile Gaming UX: Haptic Feedback](https://interhaptics.medium.com/mobile-gaming-ux-how-haptic-feedback-can-change-the-game-3ef689f889bc) — haptic design patterns for games
- [Games UX: Onboarding experience](https://uxdesign.cc/games-ux-building-the-right-onboarding-experience-a6e99cf4aaea) — board game onboarding best practices
- [Apple Developer: Onboarding for Games](https://developer.apple.com/app-store/onboarding-for-games/) — Apple's official guidance on game tutorials
- [Color Blind Mode in Games — Number Analytics](https://www.numberanalytics.com/blog/ultimate-guide-color-blind-mode-games) — colorblind palette approaches
- [Offline Storage in Flutter: Hive, SharedPreferences, SQLite](https://medium.com/@ankitahuja007/offline-storage-in-flutter-hive-sharedpreferences-and-sqlite-explained-33850adced2f) — persistence options for game state
- [2025 Guide to Haptics: Enhancing Mobile UX](https://saropa-contacts.medium.com/2025-guide-to-haptics-enhancing-mobile-ux-with-tactile-feedback-676dd5937774) — haptic vocabulary design

---
*Feature research for: Flutter mobile port of Risk board game (Android + iOS)*
*Researched: 2026-03-14*
