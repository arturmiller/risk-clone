# HUD Runtime: game renders from hud.json

**Status:** Design
**Date:** 2026-04-19
**Related:** `docs/superpowers/specs/2026-04-05-hud-editor-design.md` (the editor that produces the JSON consumed here)

## Problem

`hud/hud.json` is currently produced by the HUD editor but consumed by nothing. The Flutter game in `mobile/` still renders its HUD from hand-coded widgets (`MobileGameOverlay`, `_PortraitLayout`, `_LandscapeLayout`, `PlayerInfoBar`, `MobileActionBar`, etc.). Any layout change made in the editor has no effect on the game.

This spec makes `hud.json` load-bearing: the editor's output becomes the single source of truth for the game's HUD. Portrait mode is removed entirely (the editor does not produce a portrait layout, and the game commits to landscape-only going forward).

## Goals

- Game renders its in-game HUD by loading and interpreting `hud.json` at startup.
- Editing `hud.json` in the HUD editor and restarting the app is sufficient to see the change in the game — no new Dart code required for layout, styling, or binding changes covered by the existing schema.
- Both `mobile-landscape` and `desktop-landscape` layouts in `hud.json` are rendered; the runtime selects between them by screen width.
- All old hand-coded HUD widgets and their portrait-specific paths are deleted. `hud.json` is the truth; nothing else.

## Non-goals

- Portrait layout. Removed, not redesigned. The game runs landscape-only on every platform.
- A general expression language inside bindings. Only plain path lookups (`players[0].name`) plus a single narrow form of equality comparison (`selectedWhen`). Anything more expressive is a future concern.
- Hot-reload of `hud.json` from disk while the game is running. A Flutter hot restart is acceptable for dev iteration.
- Runtime editing of `hud.json` from inside the game. The editor is the only writer.
- Replacing the map widget or any engine code. Scope is strictly the HUD layer.

## Architecture

A new module `mobile/lib/hud/` owns the runtime. It has four pieces, each with one job:

### 1. Loader — `mobile/lib/hud/hud_loader.dart`

Reads `assets/hud.json` at app start via `rootBundle.loadString`, parses the JSON, and validates it into Freezed models:

- `HudConfig` — top-level (`version`, `theme`, `layouts`).
- `HudTheme` — `background`, `border`, `text`, `borderRadius`.
- `HudLayout` — `canvasSize`, `root`.
- `HudElement` — sealed union: `HudGrid`, `HudLabel`, `HudButton`, `HudIcon`, `HudList`, `HudCardHand`.

Validation happens once, at load time. Invalid JSON (unknown element type, malformed track string, missing required field) throws in debug and, in release, produces a full-screen "HUD failed to load" widget — no silent fallback. The game cannot start with a broken HUD config.

A single `hudConfigProvider` Riverpod provider holds the parsed config for the rest of the app.

### 2. Binding registry — `mobile/lib/hud/bindings.dart`

A hand-written function:

```dart
Object? resolveBinding(String path, WidgetRef ref);
```

Internally a switch over the set of paths used in the current `hud.json`. Each case calls `ref.watch(...)` on the appropriate provider so consuming widgets rebuild correctly when state changes. Initial coverage:

| Path | Source provider | Resolves to |
|---|---|---|
| `players[i].name` | `gameProvider` | Player display name |
| `players[i].stats` | `gameProvider` | Territories + armies as an emoji string (mobile-landscape chip) |
| `players[i].summary` | `gameProvider` | Name + stats combined (desktop sidebar chip) |
| `activePlayer.cardsLabel` | `gameProvider` | `CARDS (n)` string |
| `game.phaseLabel` | `gameProvider` | `REINFORCE PHASE` / `ATTACK PHASE` / `FORTIFY PHASE` |
| `game.phaseHint` | `gameProvider` | Contextual subtitle for the current phase |
| `game.battleLog` | `gameLogProvider` | List of battle log entry strings |
| `ui.diceCount` | `uIStateProvider` | Selected dice count (1-3), used by `selectedWhen` |

A binding path not present in the registry logs a debug error and renders as empty string / null — see Error handling.

### 3. Action registry — `mobile/lib/hud/actions.dart`

A hand-written function:

```dart
void dispatchAction(String action, WidgetRef ref);
```

Mapping action strings (from the new `action` field on `button` elements) to existing game callbacks:

| Action | Effect |
|---|---|
| `attack` | Call the existing attack handler with current selected dice count |
| `blitz` | Call the existing blitz handler |
| `endPhase` | Advance turn phase (attack → fortify, fortify → next player) |
| `selectDice:1` / `selectDice:2` / `selectDice:3` | Set `ui.diceCount` in UI provider |
| `openCards` | Toggle the card hand panel (mobile-landscape `cards-btn`) |

Unknown action strings log a debug warning and are a no-op in both debug and release — a typo in the editor never crashes the game.

### 4. Renderer — `mobile/lib/hud/hud_renderer.dart`

A `ConsumerWidget` that walks the element tree and produces Flutter widgets. Layout containers are generic; rich elements dispatch to a type registry (below).

## JSON schema additions

Two extensions to the schema the editor already produces. Everything else in the existing `hud.json` stays identical.

### `action` field on `button` (new)

Type: string. Optional.

Names a behavior from the action registry. A button with no `action` renders normally but its tap is a no-op (decorative). Initial vocabulary matches the Action registry table above.

### `selectedWhen` field on `button` (new)

Type: string. Optional.

A binding that resolves to `true` / `false`. When `true`, the button renders with its "selected" style (an optional `selectedStyle` block is merged over `style`; if `selectedStyle` is absent, the base `background` and `color` are inverted as a fallback).

This replaces the design-time `selected: true` hard-coded flag on `dice-3` in the current `hud.json` with a real state binding. Example for the dice group:

```json
{ "id": "dice-1", "type": "button", "text": "1", "action": "selectDice:1", "selectedWhen": "ui.diceCount == 1", "selectedStyle": { "background": "#C62828", "color": "#FFFFFF" }, ... }
{ "id": "dice-2", "type": "button", "text": "2", "action": "selectDice:2", "selectedWhen": "ui.diceCount == 2", ... }
{ "id": "dice-3", "type": "button", "text": "3", "action": "selectDice:3", "selectedWhen": "ui.diceCount == 3", ... }
```

`selectedWhen` is the only place the runtime evaluates anything beyond plain path lookup. The evaluator supports exactly one shape: `<binding_path> == <literal>` where `<literal>` is a string (`"ATTACK"`) or integer (`3`). Implemented in ~10 lines — no general parser. Anything beyond this form is a validation error at load.

### What stays as-is

- `group` field on buttons is kept for editor display only. The runtime doesn't use it for radio-group logic — `selectedWhen` expresses that directly.
- The design-time `selected: true` flag on individual elements is ignored at runtime. It remains a preview hint inside the editor.
- `list` keeps its `itemBinding` + `maxItems`. No item-template field — rendering each item is the responsibility of the `list`-type widget in the registry.
- Theme tokens (`{text}`, `{border}`, `{background}`) continue to resolve against the top-level `theme` block.

### Editor consequences

Explicitly in scope for the implementation plan:

- Properties panel gains an `action` dropdown on `button` elements, populated from the vocabulary above.
- Properties panel gains a `selectedWhen` text field on `button` elements, next to the existing `binding` field.
- Optional `selectedStyle` block in the style editor (can be a follow-up task).
- The two existing button groups in `hud.json` are updated: dice buttons get `selectedWhen` bindings, action buttons get `action` strings.

## Grid layout engine

Flutter has no built-in CSS-grid equivalent. A small one is implemented in `mobile/lib/hud/grid_layout.dart`, scoped strictly to what `hud.json` uses.

### Track sizing

Each entry in `rows` / `cols` is one of:

- `"40px"` / `"280px"` — fixed pixel size
- `"1fr"` / `"2fr"` — flex unit; all `fr` tracks share leftover space proportionally
- `"auto"` — intrinsic size of children in that track

### Algorithm

Implemented as a `CustomMultiChildLayout` with a custom `MultiChildLayoutDelegate`:

1. Resolve fixed tracks first (`px`).
2. Measure `auto` tracks from children's intrinsic sizes.
3. Divide remaining space across `fr` tracks by their flex weight.
4. Place each child at `[row, col]` respecting `rowSpan` / `colSpan` (default 1).
5. Apply `gap` (single number) between tracks.
6. Apply child `alignSelf` / `justifySelf` (`start`, `center`, `end`, `stretch`) within their cell.

### Style application

A `HudStyleBox` widget wraps any element and reads its `style` map, composing:

- `background` — `BoxDecoration.color` (rgba/hex) OR `BoxDecoration.gradient` (linear-gradient).
- `border` — `Border.all` parsed from `"1px solid rgba(...)"`. No broader CSS shorthand.
- `borderRadius`, `padding` — direct mapping.
- `gap` — passed through to the grid layout.
- Text-specific (`fontSize`, `fontWeight`, `color`, `textAlign`) — used by `label` / `button` text rendering.

Two helpers: `parseColor(String)` handles `#RRGGBB`, `#RRGGBBAA`, `rgb(...)`, `rgba(...)`, and theme tokens (`{text}`, `{border}`, `{background}`). `parseGradient(String)` handles `linear-gradient(Ndeg, c1, c2, c3)`.

Leaf elements reuse `HudStyleBox`, so the grid-vs-leaf distinction is only about the presence of children.

### Explicitly unsupported

Validated at load time; any appearance is a loud debug error:

- `minmax()`, `repeat()`, named grid lines
- Percentage tracks, `calc()`
- Separate row-gap and column-gap
- `style` properties beyond those listed (shadows, transforms, animations)

If the editor starts producing something new, the runtime has to grow support explicitly. Silence is never acceptable.

## Widget registry

`mobile/lib/hud/widgets/`. A map keyed by element `type` plus, for `list`, a secondary key on `itemBinding`. Rich widgets are normal Flutter widgets that pull their own state off Riverpod — no JSON indirection inside them:

| type / itemBinding | Widget | Notes |
|---|---|---|
| `list` + `game.battleLog` | `AttackLogWidget` | Renders one text line per entry; `maxItems` and style come from the JSON element |
| `cardhand` | `CardHandWidget` | Lifted from the existing card panel code; hand-display portion only |
| `label`, `icon`, `button`, `grid` | Rendered by the generic renderer | Not in the widget registry |

Unknown `type`, or `list` with an unknown `itemBinding`, produces a debug error with the element id and a visible red placeholder; release renders an empty `SizedBox`.

## Data flow

Every bound widget is a `ConsumerWidget` that calls `resolveBinding(path, ref)` inside its `build`. The resolver internally watches the right provider. Rebuilds are naturally scoped to whatever providers a binding reads — no manual subscription bookkeeping.

`dispatchAction(action, ref)` mutates providers directly (`ref.read(uIStateProvider.notifier).setDiceCount(n)`, etc.), matching the pattern used by the existing hand-coded widgets. Actions are synchronous; anything long-running is delegated to the existing game/turn providers as before.

## Layout selection

`HudRenderer` reads `MediaQuery.sizeOf(context).width` and selects the layout key:

- `width < 900` → `mobile-landscape`
- `width >= 900` → `desktop-landscape`

Rebuilds automatically when the window resizes on desktop. Orientation is locked landscape on mobile via `SystemChrome.setPreferredOrientations` in `main.dart`.

## Integration point

`GameScreen.build` collapses to:

```dart
Stack(children: [MapWidget(...), HudRenderer(config: hudConfig)])
```

No more `_PortraitLayout`, no more `_LandscapeLayout`. The HUD is a sibling of the map in a `Stack` on every platform.

## Deletions

`hud.json` is the truth, so the old hand-coded HUD is removed outright. Files deleted:

- `mobile/lib/widgets/mobile_game_overlay.dart`
- `mobile/lib/widgets/player_info_bar.dart`
- `mobile/lib/widgets/mobile_action_bar.dart`
- `_PortraitLayout` and `_LandscapeLayout` private widgets inside `mobile/lib/screens/game_screen.dart`
- `ActionPanel`, `GameLogWidget`, `ContinentPanel` (former sidebar pieces) — the implementation plan verifies via grep that no other screen uses them before deletion

`CardHandWidget` is the one widget kept, moved to `mobile/lib/hud/widgets/card_hand.dart` because `cardhand` in the JSON delegates to it.

`hud/hud.json` at the repo root moves to `mobile/assets/hud.json`. The HUD editor's load/save path (currently `hud-editor/public/hud.json`) is repointed so the editor and the game share the same on-disk file. `mobile/pubspec.yaml` registers `assets/hud.json` under `flutter/assets`.

## Error handling

Three distinct levels, each with different policy:

1. **Schema invalid at load** (unknown element type, malformed track string, unsupported style key, missing required field) — `debugPrint` full error and throw in debug; full-screen "HUD failed to load" widget in release. The game does not start with a broken config.
2. **Unknown binding path** at render — debug-only red badge on the widget showing the offending path; release renders empty string / null. Degraded but not broken.
3. **Unknown action** at tap — `debugPrint` warning, tap is a no-op in both debug and release. A typo in the editor never crashes the game.

## Testing

New tests under `mobile/test/hud/`:

- `hud_loader_test.dart` — fixture JSON files: valid, malformed, unknown type, unknown track spec, unknown style key. Asserts that each invalid case throws in debug with a useful message.
- `hud_grid_layout_test.dart` — grid places children at the correct offsets across `fr` / `px` / `auto` combinations; respects span, gap, and align.
- `bindings_test.dart` — every binding path in today's `hud.json` resolves against a stubbed `GameState` / `UIState`.
- `actions_test.dart` — every action string dispatches to the expected provider mutation.
- `hud_renderer_golden_test.dart` — two goldens: render `mobile-landscape` and `desktop-landscape` against a fixed `GameState` fixture, compare against committed PNGs. These are the regression net for editor-driven layout changes.
- `game_screen_smoke_test.dart` — pumps `GameScreen` with a fixture provider container, asserts `HudRenderer` is in the tree and does not throw.

No engine tests change.

## Open questions

None blocking. Deferred to implementation:

- Exact shape of `selectedStyle` in the editor's Properties panel (simple inline overrides vs. a full nested style editor) — can ship `selectedWhen` first and add editor UI in a follow-up.
- Whether the editor's load/save path move requires a migration step for other repo users. Likely not — it's a single file move plus a path-change in `hud-editor/src/utils/json-io.ts`.
