# HUD Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Flutter game render its in-game HUD from `hud.json`, delete the old hand-coded HUD and portrait layout entirely.

**Architecture:** A new `mobile/lib/hud/` module that loads `assets/hud.json` at startup, parses it to Freezed models, and renders it via a recursive `ConsumerWidget` tree. Data bindings (e.g. `players[0].name`) resolve against existing Riverpod providers through a hand-written registry; button taps dispatch to an action registry. A custom grid layout engine implements CSS-grid-style tracks (`1fr`, `40px`, `auto`). Two layouts (`mobile-landscape`, `desktop-landscape`) are selected by screen width.

**Tech Stack:** Flutter 3.41, Dart 3.7, Riverpod 3, Freezed, flutter_test, mocktail, `CustomMultiChildLayout`.

**Spec:** `docs/superpowers/specs/2026-04-19-hud-runtime-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `mobile/assets/hud.json` | Create (move from `hud/hud.json`) | Single source of truth for HUD layout |
| `hud/hud.json` | Delete after move | Old location |
| `mobile/pubspec.yaml` | Modify | Register `assets/hud.json` |
| `hud-editor/server/proxy.ts` | Modify | Save/load the moved file |
| `hud-editor/src/utils/json-io.ts` | Modify | Default download filename + comment about location |
| `hud-editor/src/components/Toolbar.tsx` | Modify | Add "action" dropdown + "selectedWhen" field (via PropertiesPanel) |
| `hud-editor/src/types.ts` | Modify | Add `action`, `selectedWhen`, `selectedStyle` to button type |
| `hud-editor/src/components/PropertiesPanel.tsx` | Modify | Render new button fields |
| `hud-editor/src/utils/validate.ts` | Modify | Validate new fields |
| `mobile/lib/hud/models.dart` | Create | Freezed HUD config models |
| `mobile/lib/hud/hud_loader.dart` | Create | Load + parse `assets/hud.json`; Riverpod provider |
| `mobile/lib/hud/style.dart` | Create | `parseColor`, `parseGradient`, theme-token resolution |
| `mobile/lib/hud/style_box.dart` | Create | `HudStyleBox` widget applies `style` map to a child |
| `mobile/lib/hud/grid_layout.dart` | Create | `HudGridLayout` — CSS-grid-style track layout |
| `mobile/lib/hud/bindings.dart` | Create | `resolveBinding(String, WidgetRef)` registry |
| `mobile/lib/hud/actions.dart` | Create | `dispatchAction(String, WidgetRef)` registry |
| `mobile/lib/hud/selected_when.dart` | Create | Mini-evaluator for `<binding> == <literal>` |
| `mobile/lib/hud/elements/generic.dart` | Create | Generic renderers for `label`, `icon`, `button`, `grid` |
| `mobile/lib/hud/widgets/attack_log.dart` | Create | `list` + `itemBinding: game.battleLog` renderer |
| `mobile/lib/hud/widgets/card_hand.dart` | Create (lifted from old code) | `cardhand` element widget |
| `mobile/lib/hud/hud_renderer.dart` | Create | Root `HudRenderer` + layout selection |
| `mobile/lib/screens/game_screen.dart` | Modify | Collapse to `Stack(children: [MapWidget, HudRenderer])` |
| `mobile/lib/main.dart` | Modify | Lock landscape orientation |
| `mobile/lib/widgets/mobile_game_overlay.dart` | Delete | Old HUD |
| `mobile/lib/widgets/player_info_bar.dart` | Delete | Old HUD |
| `mobile/lib/widgets/mobile_action_bar.dart` | Delete | Old HUD |
| `mobile/lib/widgets/action_panel.dart` | Delete (verify unused) | Old desktop sidebar piece |
| `mobile/lib/widgets/game_log.dart` | Delete (verify unused) | Old desktop sidebar piece |
| `mobile/lib/widgets/continent_panel.dart` | Delete (verify unused) | Old desktop sidebar piece |
| `mobile/test/hud/hud_loader_test.dart` | Create | Loader + validation tests |
| `mobile/test/hud/style_test.dart` | Create | Color/gradient parsing tests |
| `mobile/test/hud/grid_layout_test.dart` | Create | Grid track layout tests |
| `mobile/test/hud/bindings_test.dart` | Create | Binding registry tests |
| `mobile/test/hud/actions_test.dart` | Create | Action dispatch tests |
| `mobile/test/hud/selected_when_test.dart` | Create | Mini-evaluator tests |
| `mobile/test/hud/hud_renderer_golden_test.dart` | Create | Golden tests for both layouts |
| `mobile/test/hud/game_screen_smoke_test.dart` | Create | GameScreen smoke test |

---

## Task 1: Move hud.json into mobile/assets and register as Flutter asset

**Files:**
- Create: `mobile/assets/hud.json` (copied content from `hud/hud.json`)
- Delete: `hud/hud.json`
- Modify: `mobile/pubspec.yaml`

- [ ] **Step 1: Move the file**

```bash
git mv hud/hud.json mobile/assets/hud.json
```

Expected: `git status` shows a rename, not a delete+add.

- [ ] **Step 2: Confirm `mobile/assets/` exists and list contents**

Run: `ls mobile/assets/`
Expected: Includes `hud.json` and any existing map assets.

- [ ] **Step 3: Register the JSON asset in pubspec**

Modify `mobile/pubspec.yaml`. The existing `flutter:` block reads:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/
```

The directory-level `- assets/` already recursively registers `assets/hud.json`. No change required. Verify by running:

Run: `cd mobile && flutter pub get && flutter clean`
Expected: No errors. `flutter pub get` succeeds.

- [ ] **Step 4: Verify the asset loads from bundle**

Create a throwaway check inside `mobile/test/hud/asset_smoke_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hud.json asset loads and parses', () async {
    final raw = await rootBundle.loadString('assets/hud.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    expect(json['version'], 1);
    expect(json['layouts'], isA<Map>());
    expect((json['layouts'] as Map).keys,
        containsAll(['mobile-landscape', 'desktop-landscape']));
  });
}
```

Run: `cd mobile && flutter test test/hud/asset_smoke_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/assets/hud.json mobile/test/hud/asset_smoke_test.dart
git rm hud/hud.json 2>/dev/null || true
git commit -m "feat(hud): move hud.json into mobile/assets as single source of truth"
```

Expected: Commit succeeds. Note: `asset_smoke_test.dart` is intentionally kept — it pins the schema's top-level invariants going forward.

---

## Task 2: Update hud-editor to load/save the moved file

**Files:**
- Modify: `hud-editor/server/proxy.ts`
- Modify: `hud-editor/src/utils/json-io.ts`

- [ ] **Step 1: Read the proxy to find the save/load paths**

Run the Read tool on `hud-editor/server/proxy.ts`. Locate any `fs.writeFileSync`, `fs.readFileSync`, or path references that include `hud/hud.json`, `public/hud.json`, or similar.

- [ ] **Step 2: Update the proxy's save endpoint path**

In `hud-editor/server/proxy.ts`, change every filesystem reference from the old location to `../mobile/assets/hud.json` (relative to `hud-editor/`). If the file reads from `../hud/hud.json` or `public/hud.json`, change the string literal. Example diff (adjust to actual file contents):

```typescript
// BEFORE
const HUD_PATH = path.join(__dirname, '..', 'public', 'hud.json');

// AFTER
const HUD_PATH = path.join(__dirname, '..', '..', 'mobile', 'assets', 'hud.json');
```

- [ ] **Step 3: Delete the now-stale `hud-editor/public/hud.json` if it exists**

Run: `ls hud-editor/public/hud.json 2>/dev/null && echo exists || echo absent`

If it exists, delete it and remove any Vite `publicDir` references that pinned it:

```bash
rm -f hud-editor/public/hud.json
```

- [ ] **Step 4: Start the editor and verify it loads the moved file**

Run: `cd hud-editor && npm run dev` (in a separate terminal)
Expected: The editor starts, the canvas loads with the existing HUD (both mobile-landscape and desktop-landscape visible via the layout switcher). No 404 in devtools.

Save a trivial edit (move one element by 1px) and reload the page.
Expected: The edit persists. Check `mobile/assets/hud.json` on disk shows the change.

Revert the trivial edit so the file on disk is unchanged from Task 1.

- [ ] **Step 5: Commit**

```bash
git add hud-editor/
git commit -m "feat(hud-editor): read and write mobile/assets/hud.json directly"
```

---

## Task 3: Add `action` / `selectedWhen` / `selectedStyle` to the editor schema

**Files:**
- Modify: `hud-editor/src/types.ts`
- Modify: `hud-editor/src/utils/validate.ts`
- Modify: `hud-editor/src/components/PropertiesPanel.tsx`
- Modify: `mobile/assets/hud.json` (wire real values into existing buttons)

- [ ] **Step 1: Extend the ButtonElement type**

Open `hud-editor/src/types.ts` and locate the button element type (likely `ButtonElement`). Add three optional fields:

```typescript
export interface ButtonElement extends BaseElement {
  type: 'button';
  text?: string;
  binding?: string;
  group?: string;
  selected?: boolean;
  action?: string;           // NEW: action name dispatched on tap
  selectedWhen?: string;     // NEW: binding that resolves to true/false
  selectedStyle?: Style;     // NEW: style merged when selectedWhen is true
  // ...existing fields
}
```

(Match the existing shape — do not reshape unrelated fields.)

- [ ] **Step 2: Extend the validator**

Open `hud-editor/src/utils/validate.ts`. Find where button-specific fields are validated. Add:

```typescript
// action: optional, must be one of the known strings (or any string — editor is permissive)
if (button.action !== undefined && typeof button.action !== 'string') {
  errors.push(`button ${button.id}: action must be a string`);
}

// selectedWhen: optional, must be a string
if (button.selectedWhen !== undefined && typeof button.selectedWhen !== 'string') {
  errors.push(`button ${button.id}: selectedWhen must be a string`);
}

// selectedStyle: optional, must be an object if present
if (button.selectedStyle !== undefined && (typeof button.selectedStyle !== 'object' || button.selectedStyle === null)) {
  errors.push(`button ${button.id}: selectedStyle must be an object`);
}
```

- [ ] **Step 3: Surface the new fields in PropertiesPanel**

Open `hud-editor/src/components/PropertiesPanel.tsx`. Find the branch that renders button-specific fields (alongside `text`, `binding`, `group`, `selected`). Add two text inputs — `action` and `selectedWhen` — following the exact pattern used by existing inputs. `selectedStyle` as a structured editor is deferred (an `Other: open raw JSON` follow-up); the field is still in the type so hand-edited JSON works.

Exact change depends on the existing panel structure. The template for one field (copy the existing `binding` input and change the key):

```tsx
<label>
  Action
  <input
    type="text"
    value={element.action ?? ''}
    onChange={(e) => updateSelected({ action: e.target.value || undefined })}
  />
</label>
<label>
  Selected When
  <input
    type="text"
    value={element.selectedWhen ?? ''}
    onChange={(e) => updateSelected({ selectedWhen: e.target.value || undefined })}
  />
</label>
```

- [ ] **Step 4: Update `mobile/assets/hud.json` to use the new fields**

Edit `mobile/assets/hud.json` by hand to:

1. On each of `dice-1`, `dice-2`, `dice-3` (mobile-landscape):
   - Add `"action": "selectDice:1"` / `"selectDice:2"` / `"selectDice:3"`.
   - Add `"selectedWhen": "ui.diceCount == 1"` / `"... == 2"` / `"... == 3"`.
   - Add `"selectedStyle": { "background": "#C62828", "color": "#FFFFFF" }`.
   - Remove the hard-coded `"selected": true` on `dice-3`.
   - Change `dice-3`'s base `style.background` from `"#C62828"` to `"rgba(255,255,255,0.15)"` and base `style.color` to `"rgba(255,255,255,0.6)"` (the selected state is now driven by `selectedWhen`).
2. On `attack-btn` and `attack-btn-desktop`: add `"action": "attack"`.
3. On `blitz-btn` and `blitz-btn-desktop`: add `"action": "blitz"`.
4. On `end-btn` and `end-btn-desktop`: add `"action": "endPhase"`.
5. The mobile-landscape `cards-btn` is a `grid`, not a button. Keep it as is for now — Task 12 will wire its tap through the cardhand widget.

- [ ] **Step 5: Reload the editor, verify the JSON parses**

Run: `cd hud-editor && npm run dev`
Expected: Both layouts render without validation errors. The new fields are visible and editable in the Properties panel for buttons.

- [ ] **Step 6: Commit**

```bash
git add hud-editor/ mobile/assets/hud.json
git commit -m "feat(hud): add action / selectedWhen / selectedStyle to button schema"
```

---

## Task 4: Freezed HUD models

**Files:**
- Create: `mobile/lib/hud/models.dart`
- Test: `mobile/test/hud/models_test.dart`

- [ ] **Step 1: Write the failing test for model parsing**

Create `mobile/test/hud/models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/models.dart';

void main() {
  group('HudConfig.fromJson', () {
    test('parses a minimal valid config', () {
      final json = {
        'version': 1,
        'theme': {
          'background': '#000000',
          'border': '#FFFFFF',
          'text': '#FF0000',
          'borderRadius': 10,
        },
        'layouts': {
          'mobile-landscape': {
            'canvasSize': [844, 390],
            'root': {
              'type': 'grid',
              'id': 'root',
              'rows': ['1fr'],
              'cols': ['1fr'],
              'children': [],
            },
          },
        },
      };
      final config = HudConfig.fromJson(json);
      expect(config.version, 1);
      expect(config.theme.text, '#FF0000');
      expect(config.layouts.keys, ['mobile-landscape']);
      final root = config.layouts['mobile-landscape']!.root;
      expect(root, isA<HudGrid>());
      expect((root as HudGrid).id, 'root');
    });

    test('parses a label element', () {
      final json = _wrapInRoot({
        'type': 'label',
        'id': 'hello',
        'text': 'Hello',
        'row': 0,
        'col': 0,
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudLabel>());
      expect((el as HudLabel).text, 'Hello');
    });

    test('parses a button with action and selectedWhen', () {
      final json = _wrapInRoot({
        'type': 'button',
        'id': 'b',
        'text': 'GO',
        'row': 0,
        'col': 0,
        'action': 'attack',
        'selectedWhen': 'ui.diceCount == 3',
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudButton>());
      expect((el as HudButton).action, 'attack');
      expect(el.selectedWhen, 'ui.diceCount == 3');
    });

    test('parses a list element', () {
      final json = _wrapInRoot({
        'type': 'list',
        'id': 'log',
        'maxItems': 4,
        'itemBinding': 'game.battleLog',
        'row': 0,
        'col': 0,
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudList>());
      expect((el as HudList).itemBinding, 'game.battleLog');
      expect(el.maxItems, 4);
    });

    test('parses a cardhand element', () {
      final json = _wrapInRoot({
        'type': 'cardhand',
        'id': 'ch',
        'row': 0,
        'col': 0,
      });
      final el = _firstChild(HudConfig.fromJson(json));
      expect(el, isA<HudCardHand>());
    });

    test('throws on unknown element type', () {
      final json = _wrapInRoot({
        'type': 'unknown',
        'id': 'x',
        'row': 0,
        'col': 0,
      });
      expect(() => HudConfig.fromJson(json), throwsA(isA<FormatException>()));
    });
  });
}

Map<String, dynamic> _wrapInRoot(Map<String, dynamic> child) => {
      'version': 1,
      'theme': {
        'background': '#000',
        'border': '#000',
        'text': '#000',
        'borderRadius': 0,
      },
      'layouts': {
        'mobile-landscape': {
          'canvasSize': [844, 390],
          'root': {
            'type': 'grid',
            'id': 'root',
            'rows': ['1fr'],
            'cols': ['1fr'],
            'children': [child],
          },
        },
      },
    };

HudElement _firstChild(HudConfig c) =>
    (c.layouts['mobile-landscape']!.root as HudGrid).children.first;
```

- [ ] **Step 2: Run the failing test**

Run: `cd mobile && flutter test test/hud/models_test.dart`
Expected: FAIL (models don't exist).

- [ ] **Step 3: Create the Freezed models**

Create `mobile/lib/hud/models.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

@freezed
abstract class HudConfig with _$HudConfig {
  const factory HudConfig({
    required int version,
    required HudTheme theme,
    required Map<String, HudLayout> layouts,
  }) = _HudConfig;

  factory HudConfig.fromJson(Map<String, dynamic> json) {
    return HudConfig(
      version: json['version'] as int,
      theme: HudTheme.fromJson(json['theme'] as Map<String, dynamic>),
      layouts: (json['layouts'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, HudLayout.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

@freezed
abstract class HudTheme with _$HudTheme {
  const factory HudTheme({
    required String background,
    required String border,
    required String text,
    required num borderRadius,
  }) = _HudTheme;

  factory HudTheme.fromJson(Map<String, dynamic> json) => HudTheme(
        background: json['background'] as String,
        border: json['border'] as String,
        text: json['text'] as String,
        borderRadius: json['borderRadius'] as num,
      );
}

@freezed
abstract class HudLayout with _$HudLayout {
  const factory HudLayout({
    required List<num> canvasSize,
    required HudElement root,
  }) = _HudLayout;

  factory HudLayout.fromJson(Map<String, dynamic> json) => HudLayout(
        canvasSize: (json['canvasSize'] as List).cast<num>(),
        root: HudElement.fromJson(json['root'] as Map<String, dynamic>),
      );
}

sealed class HudElement {
  const HudElement();

  String get id;
  int? get row;
  int? get col;
  int? get rowSpan;
  int? get colSpan;
  Map<String, dynamic>? get style;
  String? get description;

  factory HudElement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'grid':
        return HudGrid.fromJson(json);
      case 'label':
        return HudLabel.fromJson(json);
      case 'button':
        return HudButton.fromJson(json);
      case 'icon':
        return HudIcon.fromJson(json);
      case 'list':
        return HudList.fromJson(json);
      case 'cardhand':
        return HudCardHand.fromJson(json);
      default:
        throw FormatException('Unknown HUD element type: $type (id=${json['id']})');
    }
  }
}

class HudGrid extends HudElement {
  @override
  final String id;
  final List<String> rows;
  final List<String> cols;
  final List<HudElement> children;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudGrid({
    required this.id,
    required this.rows,
    required this.cols,
    required this.children,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudGrid.fromJson(Map<String, dynamic> json) => HudGrid(
        id: json['id'] as String,
        rows: (json['rows'] as List).cast<String>(),
        cols: (json['cols'] as List).cast<String>(),
        children: (json['children'] as List? ?? [])
            .map((c) => HudElement.fromJson(c as Map<String, dynamic>))
            .toList(),
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudLabel extends HudElement {
  @override
  final String id;
  final String? text;
  final String? binding;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudLabel({
    required this.id,
    this.text,
    this.binding,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudLabel.fromJson(Map<String, dynamic> json) => HudLabel(
        id: json['id'] as String,
        text: json['text'] as String?,
        binding: json['binding'] as String?,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudButton extends HudElement {
  @override
  final String id;
  final String? text;
  final String? action;
  final String? selectedWhen;
  final Map<String, dynamic>? selectedStyle;
  final String? group;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudButton({
    required this.id,
    this.text,
    this.action,
    this.selectedWhen,
    this.selectedStyle,
    this.group,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudButton.fromJson(Map<String, dynamic> json) => HudButton(
        id: json['id'] as String,
        text: json['text'] as String?,
        action: json['action'] as String?,
        selectedWhen: json['selectedWhen'] as String?,
        selectedStyle: json['selectedStyle'] as Map<String, dynamic>?,
        group: json['group'] as String?,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudIcon extends HudElement {
  @override
  final String id;
  final String name;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudIcon({
    required this.id,
    required this.name,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudIcon.fromJson(Map<String, dynamic> json) => HudIcon(
        id: json['id'] as String,
        name: json['name'] as String,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudList extends HudElement {
  @override
  final String id;
  final int maxItems;
  final String itemBinding;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudList({
    required this.id,
    required this.maxItems,
    required this.itemBinding,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudList.fromJson(Map<String, dynamic> json) => HudList(
        id: json['id'] as String,
        maxItems: json['maxItems'] as int,
        itemBinding: json['itemBinding'] as String,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudCardHand extends HudElement {
  @override
  final String id;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudCardHand({
    required this.id,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudCardHand.fromJson(Map<String, dynamic> json) => HudCardHand(
        id: json['id'] as String,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}
```

Note: `HudConfig`, `HudTheme`, and `HudLayout` use `@freezed` for value-equality. `HudElement` and its subclasses are plain `sealed`/regular classes so the switch-on-type-tag parser stays readable. No Freezed codegen is needed for the subclasses (they're immutable by construction).

Because `HudConfig` / `HudTheme` / `HudLayout` have custom `fromJson`, remove the `part 'models.g.dart'` — no json_serializable needed.

- [ ] **Step 4: Run build_runner to generate freezed parts**

Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `models.freezed.dart` is generated. No errors.

- [ ] **Step 5: Run the tests**

Run: `cd mobile && flutter test test/hud/models_test.dart`
Expected: All 6 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/hud/models.dart mobile/lib/hud/models.freezed.dart mobile/test/hud/models_test.dart
git commit -m "feat(hud): add Freezed HUD config models"
```

---

## Task 5: Style parsing helpers (parseColor, parseGradient, theme tokens)

**Files:**
- Create: `mobile/lib/hud/style.dart`
- Test: `mobile/test/hud/style_test.dart`

- [ ] **Step 1: Write failing tests**

Create `mobile/test/hud/style_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/models.dart';
import 'package:risk_mobile/hud/style.dart';

void main() {
  const theme = HudTheme(
    background: 'rgba(62,39,12,0.9)',
    border: 'rgba(255,193,7,0.3)',
    text: '#FFB300',
    borderRadius: 10,
  );

  group('parseColor', () {
    test('hex RRGGBB', () {
      expect(parseColor('#FF0000', theme), const Color(0xFFFF0000));
    });

    test('hex RRGGBBAA', () {
      expect(parseColor('#FF000080', theme), const Color(0x80FF0000));
    });

    test('rgba', () {
      expect(parseColor('rgba(255,0,0,0.5)', theme),
          Color.fromRGBO(255, 0, 0, 0.5));
    });

    test('rgb', () {
      expect(parseColor('rgb(255,0,0)', theme), const Color(0xFFFF0000));
    });

    test('theme token {text}', () {
      expect(parseColor('{text}', theme), const Color(0xFFFFB300));
    });

    test('theme token {border}', () {
      expect(parseColor('{border}', theme), parseColor(theme.border, theme));
    });

    test('throws on unknown format', () {
      expect(() => parseColor('hotpink', theme), throwsA(isA<FormatException>()));
    });
  });

  group('parseGradient', () {
    test('linear-gradient 2 stops', () {
      final g = parseGradient('linear-gradient(90deg, #FF0000, #0000FF)', theme);
      expect(g, isA<LinearGradient>());
      expect(g.colors, [const Color(0xFFFF0000), const Color(0xFF0000FF)]);
    });

    test('linear-gradient 3 stops', () {
      final g = parseGradient(
          'linear-gradient(180deg, #FF0000, #00FF00, #0000FF)', theme);
      expect(g.colors.length, 3);
    });

    test('throws on non-gradient input', () {
      expect(() => parseGradient('#FF0000', theme),
          throwsA(isA<FormatException>()));
    });
  });
}
```

- [ ] **Step 2: Run failing tests**

Run: `cd mobile && flutter test test/hud/style_test.dart`
Expected: FAIL (file not found).

- [ ] **Step 3: Implement `mobile/lib/hud/style.dart`**

```dart
import 'package:flutter/material.dart';
import 'models.dart';

Color parseColor(String input, HudTheme theme) {
  final trimmed = input.trim();

  // Theme tokens: {text}, {border}, {background}
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    final token = trimmed.substring(1, trimmed.length - 1);
    switch (token) {
      case 'text':
        return parseColor(theme.text, theme);
      case 'border':
        return parseColor(theme.border, theme);
      case 'background':
        return parseColor(theme.background, theme);
      default:
        throw FormatException('Unknown theme token: $token');
    }
  }

  // Hex: #RRGGBB or #RRGGBBAA
  if (trimmed.startsWith('#')) {
    final hex = trimmed.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      // Input is RRGGBBAA, Flutter wants AARRGGBB
      final rgb = hex.substring(0, 6);
      final alpha = hex.substring(6);
      return Color(int.parse('$alpha$rgb', radix: 16));
    }
    throw FormatException('Invalid hex color: $trimmed');
  }

  // rgba(r,g,b,a) or rgb(r,g,b)
  final rgbaMatch = RegExp(r'^rgba?\(([^)]+)\)$').firstMatch(trimmed);
  if (rgbaMatch != null) {
    final parts = rgbaMatch.group(1)!.split(',').map((s) => s.trim()).toList();
    if (parts.length == 3) {
      return Color.fromRGBO(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        1.0,
      );
    }
    if (parts.length == 4) {
      return Color.fromRGBO(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        double.parse(parts[3]),
      );
    }
  }

  throw FormatException('Unrecognized color: $trimmed');
}

LinearGradient parseGradient(String input, HudTheme theme) {
  final trimmed = input.trim();
  final match = RegExp(r'^linear-gradient\(([^)]+)\)$').firstMatch(trimmed);
  if (match == null) {
    throw FormatException('Not a linear-gradient: $trimmed');
  }
  final parts = match.group(1)!.split(',').map((s) => s.trim()).toList();
  if (parts.isEmpty) {
    throw FormatException('Empty linear-gradient args');
  }

  // First part is the angle: "90deg" or "180deg"
  final angleMatch = RegExp(r'^(-?\d+)deg$').firstMatch(parts.first);
  if (angleMatch == null) {
    throw FormatException('Missing angle in linear-gradient');
  }
  final angleDeg = int.parse(angleMatch.group(1)!);
  final (begin, end) = _anglePoints(angleDeg);

  final colors = parts.skip(1).map((c) => parseColor(c, theme)).toList();
  if (colors.length < 2) {
    throw FormatException('linear-gradient needs at least 2 color stops');
  }
  return LinearGradient(begin: begin, end: end, colors: colors);
}

(Alignment, Alignment) _anglePoints(int deg) {
  // CSS gradient angles: 0deg = to top, 90deg = to right, 180deg = to bottom.
  // Flutter Alignment has y inverted (top is -1).
  final norm = ((deg % 360) + 360) % 360;
  switch (norm) {
    case 0:
      return (Alignment.bottomCenter, Alignment.topCenter);
    case 90:
      return (Alignment.centerLeft, Alignment.centerRight);
    case 180:
      return (Alignment.topCenter, Alignment.bottomCenter);
    case 270:
      return (Alignment.centerRight, Alignment.centerLeft);
    default:
      // Rough fallback: rotate from top-center.
      final rad = norm * 3.14159265 / 180.0;
      final dx = 0.5 * _sin(rad);
      final dy = -0.5 * _cos(rad);
      return (Alignment(-dx, -dy), Alignment(dx, dy));
  }
}

double _sin(double x) {
  // Avoid importing dart:math to keep this file dependency-free;
  // Taylor approximation is enough for gradient angles we actually use.
  var term = x;
  var sum = x;
  for (var n = 1; n < 10; n++) {
    term *= -x * x / ((2 * n) * (2 * n + 1));
    sum += term;
  }
  return sum;
}

double _cos(double x) {
  var term = 1.0;
  var sum = 1.0;
  for (var n = 1; n < 10; n++) {
    term *= -x * x / ((2 * n - 1) * (2 * n));
    sum += term;
  }
  return sum;
}
```

If the "avoid dart:math" trick feels silly, import `dart:math` and use `sin`/`cos` directly — the Taylor version is only in case of lint complaints about unused imports elsewhere. Replace with:

```dart
import 'dart:math' as math;
// ...
final dx = 0.5 * math.sin(rad);
final dy = -0.5 * math.cos(rad);
```

- [ ] **Step 4: Run tests**

Run: `cd mobile && flutter test test/hud/style_test.dart`
Expected: All 10 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/hud/style.dart mobile/test/hud/style_test.dart
git commit -m "feat(hud): add parseColor and parseGradient helpers with theme tokens"
```

---

## Task 6: HudStyleBox widget

**Files:**
- Create: `mobile/lib/hud/style_box.dart`
- Test: `mobile/test/hud/style_box_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `mobile/test/hud/style_box_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/models.dart';
import 'package:risk_mobile/hud/style_box.dart';

const _theme = HudTheme(
  background: '#111111',
  border: '#222222',
  text: '#333333',
  borderRadius: 4,
);

void main() {
  testWidgets('applies background color from style map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {'background': '#FF0000'},
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final box = tester.widget<Container>(find.byType(Container));
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, const Color(0xFFFF0000));
  });

  testWidgets('applies linear-gradient background', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {
            'background': 'linear-gradient(90deg, #FF0000, #0000FF)',
          },
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final deco = tester.widget<Container>(find.byType(Container)).decoration
        as BoxDecoration;
    expect(deco.gradient, isA<LinearGradient>());
  });

  testWidgets('applies 1px solid border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {'border': '1px solid rgba(255,160,0,0.4)'},
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final deco = tester.widget<Container>(find.byType(Container)).decoration
        as BoxDecoration;
    expect(deco.border, isNotNull);
  });

  testWidgets('applies borderRadius and padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HudStyleBox(
          theme: _theme,
          style: const {'borderRadius': 8, 'padding': '4px 8px'},
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );
    final container = tester.widget<Container>(find.byType(Container));
    final deco = container.decoration as BoxDecoration;
    expect(deco.borderRadius, BorderRadius.circular(8));
    expect(container.padding, const EdgeInsets.symmetric(vertical: 4, horizontal: 8));
  });
}
```

- [ ] **Step 2: Run failing tests**

Run: `cd mobile && flutter test test/hud/style_box_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `mobile/lib/hud/style_box.dart`**

```dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'style.dart';

class HudStyleBox extends StatelessWidget {
  final HudTheme theme;
  final Map<String, dynamic>? style;
  final Widget child;

  const HudStyleBox({
    super.key,
    required this.theme,
    required this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final s = style ?? const {};

    Color? bgColor;
    Gradient? gradient;
    final bg = s['background'];
    if (bg is String) {
      if (bg.startsWith('linear-gradient')) {
        gradient = parseGradient(bg, theme);
      } else {
        bgColor = parseColor(bg, theme);
      }
    }

    BoxBorder? border;
    final b = s['border'];
    if (b is String) {
      border = _parseBorder(b, theme);
    }

    BorderRadius? borderRadius;
    final br = s['borderRadius'];
    if (br is num) {
      borderRadius = BorderRadius.circular(br.toDouble());
    }

    EdgeInsets? padding;
    final p = s['padding'];
    if (p is num) {
      padding = EdgeInsets.all(p.toDouble());
    } else if (p is String) {
      padding = _parsePadding(p);
    }

    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        border: border,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    return decorated;
  }
}

BoxBorder? _parseBorder(String input, HudTheme theme) {
  // "1px solid rgba(...)" — only form we support
  final match = RegExp(r'^(\d+)px\s+solid\s+(.+)$').firstMatch(input.trim());
  if (match == null) {
    throw FormatException('Unsupported border: $input');
  }
  final width = double.parse(match.group(1)!);
  final color = parseColor(match.group(2)!, theme);
  return Border.all(color: color, width: width);
}

EdgeInsets _parsePadding(String input) {
  // "Xpx", "Xpx Ypx", "Xpx Ypx Zpx Wpx"; or unitless numbers.
  final parts = input.trim().split(RegExp(r'\s+'));
  final vals = parts.map((p) {
    final m = RegExp(r'^(-?\d+(?:\.\d+)?)(px)?$').firstMatch(p.trim());
    if (m == null) {
      throw FormatException('Unparseable padding value: $p');
    }
    return double.parse(m.group(1)!);
  }).toList();
  switch (vals.length) {
    case 1:
      return EdgeInsets.all(vals[0]);
    case 2:
      return EdgeInsets.symmetric(vertical: vals[0], horizontal: vals[1]);
    case 4:
      return EdgeInsets.fromLTRB(vals[3], vals[0], vals[1], vals[2]);
    default:
      throw FormatException('Unsupported padding arity: $input');
  }
}
```

- [ ] **Step 4: Run tests**

Run: `cd mobile && flutter test test/hud/style_box_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/hud/style_box.dart mobile/test/hud/style_box_test.dart
git commit -m "feat(hud): add HudStyleBox widget applying style maps"
```

---

## Task 7: Grid layout engine

**Files:**
- Create: `mobile/lib/hud/grid_layout.dart`
- Test: `mobile/test/hud/grid_layout_test.dart`

- [ ] **Step 1: Write failing tests**

Create `mobile/test/hud/grid_layout_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/grid_layout.dart';

Widget _childAt({
  required int row,
  required int col,
  int rowSpan = 1,
  int colSpan = 1,
  String? alignSelf,
  String? justifySelf,
  required Widget child,
  required String id,
}) =>
    LayoutId(
      id: id,
      child: HudGridCell(
        row: row,
        col: col,
        rowSpan: rowSpan,
        colSpan: colSpan,
        alignSelf: alignSelf,
        justifySelf: justifySelf,
        child: child,
      ),
    );

void main() {
  testWidgets('lays out fixed px tracks', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 200,
        height: 100,
        child: HudGridLayout(
          rows: const ['100px'],
          cols: const ['50px', '50px'],
          gap: 0,
          children: [
            _childAt(id: 'a', row: 0, col: 0, child: const SizedBox.expand(key: ValueKey('a'))),
            _childAt(id: 'b', row: 0, col: 1, child: const SizedBox.expand(key: ValueKey('b'))),
          ],
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(a.width, 50);
    expect(b.left - a.left, 50);
  });

  testWidgets('distributes fr tracks', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 300,
        height: 100,
        child: HudGridLayout(
          rows: const ['1fr'],
          cols: const ['1fr', '2fr'],
          gap: 0,
          children: [
            _childAt(id: 'a', row: 0, col: 0, child: const SizedBox.expand(key: ValueKey('a'))),
            _childAt(id: 'b', row: 0, col: 1, child: const SizedBox.expand(key: ValueKey('b'))),
          ],
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(a.width, 100); // 1/3 of 300
    expect(b.width, 200); // 2/3 of 300
  });

  testWidgets('respects rowSpan', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 100,
        height: 200,
        child: HudGridLayout(
          rows: const ['100px', '100px'],
          cols: const ['1fr'],
          gap: 0,
          children: [
            _childAt(id: 'a', row: 0, col: 0, rowSpan: 2,
              child: const SizedBox.expand(key: ValueKey('a'))),
          ],
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    expect(a.height, 200);
  });

  testWidgets('applies gap between tracks', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 210,
        height: 100,
        child: HudGridLayout(
          rows: const ['100px'],
          cols: const ['100px', '100px'],
          gap: 10,
          children: [
            _childAt(id: 'a', row: 0, col: 0,
                child: const SizedBox.expand(key: ValueKey('a'))),
            _childAt(id: 'b', row: 0, col: 1,
                child: const SizedBox.expand(key: ValueKey('b'))),
          ],
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('a')));
    final b = tester.getRect(find.byKey(const ValueKey('b')));
    expect(b.left - a.right, 10);
  });
}
```

- [ ] **Step 2: Run failing tests**

Run: `cd mobile && flutter test test/hud/grid_layout_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `mobile/lib/hud/grid_layout.dart`**

```dart
import 'package:flutter/material.dart';

/// Marker widget wrapping each grid child with its placement info.
class HudGridCell extends StatelessWidget {
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
  final String? alignSelf;
  final String? justifySelf;
  final Widget child;

  const HudGridCell({
    super.key,
    required this.row,
    required this.col,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.alignSelf,
    this.justifySelf,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}

class HudGridLayout extends StatelessWidget {
  final List<String> rows;
  final List<String> cols;
  final double gap;
  final List<Widget> children; // each must be a LayoutId wrapping a HudGridCell

  const HudGridLayout({
    super.key,
    required this.rows,
    required this.cols,
    required this.gap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _HudGridDelegate(
        rows: rows,
        cols: cols,
        gap: gap,
        cells: _collectCells(children),
      ),
      children: children,
    );
  }

  List<_CellInfo> _collectCells(List<Widget> children) {
    return children.map((w) {
      if (w is! LayoutId) {
        throw StateError('HudGridLayout children must be LayoutId-wrapped');
      }
      final cell = _findCell(w.child);
      return _CellInfo(
        id: w.id,
        row: cell.row,
        col: cell.col,
        rowSpan: cell.rowSpan,
        colSpan: cell.colSpan,
        alignSelf: cell.alignSelf,
        justifySelf: cell.justifySelf,
      );
    }).toList();
  }

  HudGridCell _findCell(Widget w) {
    if (w is HudGridCell) return w;
    throw StateError('LayoutId child must be HudGridCell (got ${w.runtimeType})');
  }
}

class _CellInfo {
  final Object id;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
  final String? alignSelf;
  final String? justifySelf;

  _CellInfo({
    required this.id,
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
    this.alignSelf,
    this.justifySelf,
  });
}

class _HudGridDelegate extends MultiChildLayoutDelegate {
  final List<String> rows;
  final List<String> cols;
  final double gap;
  final List<_CellInfo> cells;

  _HudGridDelegate({
    required this.rows,
    required this.cols,
    required this.gap,
    required this.cells,
  });

  @override
  void performLayout(Size size) {
    final colSizes = _resolveTracks(cols, size.width - gap * (cols.length - 1));
    final rowSizes = _resolveTracks(rows, size.height - gap * (rows.length - 1));

    // Compute cumulative offsets per track.
    final colOffsets = _cumulative(colSizes, gap);
    final rowOffsets = _cumulative(rowSizes, gap);

    for (final cell in cells) {
      final x = colOffsets[cell.col];
      final y = rowOffsets[cell.row];
      double w = 0;
      double h = 0;
      for (int i = 0; i < cell.colSpan; i++) {
        w += colSizes[cell.col + i];
        if (i > 0) w += gap;
      }
      for (int i = 0; i < cell.rowSpan; i++) {
        h += rowSizes[cell.row + i];
        if (i > 0) h += gap;
      }

      // Let the child measure itself up to the cell; default stretch.
      final alignSelf = cell.alignSelf ?? 'stretch';
      final justifySelf = cell.justifySelf ?? 'stretch';
      final loose = alignSelf != 'stretch' || justifySelf != 'stretch';

      final childSize = layoutChild(
        cell.id,
        loose
            ? BoxConstraints(maxWidth: w, maxHeight: h)
            : BoxConstraints.tightFor(width: w, height: h),
      );

      double dx = x;
      double dy = y;
      if (justifySelf == 'center') dx = x + (w - childSize.width) / 2;
      if (justifySelf == 'end') dx = x + (w - childSize.width);
      if (alignSelf == 'center') dy = y + (h - childSize.height) / 2;
      if (alignSelf == 'end') dy = y + (h - childSize.height);

      positionChild(cell.id, Offset(dx, dy));
    }
  }

  List<double> _resolveTracks(List<String> specs, double available) {
    final sizes = List<double>.filled(specs.length, 0);
    double remaining = available;
    double frTotal = 0;
    final autoIndices = <int>[];

    for (int i = 0; i < specs.length; i++) {
      final spec = specs[i].trim();
      if (spec.endsWith('px')) {
        final v = double.parse(spec.substring(0, spec.length - 2));
        sizes[i] = v;
        remaining -= v;
      } else if (spec.endsWith('fr')) {
        final v = double.parse(spec.substring(0, spec.length - 2));
        sizes[i] = -v; // negative marker; fill later
        frTotal += v;
      } else if (spec == 'auto') {
        autoIndices.add(i);
      } else {
        throw FormatException('Unsupported track spec: $spec');
      }
    }

    // Auto tracks: for now, give them 0 (children will pack); refine later if needed.
    // This is enough for the current hud.json (auto is always for chips with intrinsic content).
    for (final i in autoIndices) {
      sizes[i] = 0;
    }

    if (frTotal > 0 && remaining > 0) {
      final per = remaining / frTotal;
      for (int i = 0; i < sizes.length; i++) {
        if (sizes[i] < 0) sizes[i] = per * -sizes[i];
      }
    }
    for (int i = 0; i < sizes.length; i++) {
      if (sizes[i] < 0) sizes[i] = 0;
    }
    return sizes;
  }

  List<double> _cumulative(List<double> sizes, double gap) {
    final offs = <double>[0];
    double acc = 0;
    for (int i = 0; i < sizes.length - 1; i++) {
      acc += sizes[i] + gap;
      offs.add(acc);
    }
    return offs;
  }

  @override
  bool shouldRelayout(_HudGridDelegate old) =>
      !_listEq(old.rows, rows) ||
      !_listEq(old.cols, cols) ||
      old.gap != gap ||
      old.cells.length != cells.length;

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
```

Note: `auto` track sizing is intentionally simplified (tracks collapse to 0 and rely on child intrinsic content filling visible via `alignSelf: center` behavior). The current hud.json uses `auto` rows in the chip grids where the content is tiny and the outer grid is bounded by siblings — this works for that case. If a golden test later reveals a broken auto layout, revisit here with a measure-pass.

- [ ] **Step 4: Run tests**

Run: `cd mobile && flutter test test/hud/grid_layout_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/hud/grid_layout.dart mobile/test/hud/grid_layout_test.dart
git commit -m "feat(hud): add HudGridLayout with fr/px/auto track sizing"
```

---

## Task 8: Binding registry

**Files:**
- Create: `mobile/lib/hud/bindings.dart`
- Test: `mobile/test/hud/bindings_test.dart`

- [ ] **Step 1: Write failing tests**

Create `mobile/test/hud/bindings_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/engine/models/log_entry.dart';
import 'package:risk_mobile/engine/models/ui_state.dart';
import 'package:risk_mobile/hud/bindings.dart';
import 'package:risk_mobile/providers/game_log_provider.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/providers/ui_provider.dart';

class _Probe extends ConsumerWidget {
  final String path;
  final void Function(Object?) onResolved;
  const _Probe({required this.path, required this.onResolved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onResolved(resolveBinding(path, ref));
    return const SizedBox();
  }
}

Future<Object?> _resolve(WidgetTester t, String path, List<Override> overrides) async {
  Object? captured;
  await t.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: _Probe(path: path, onResolved: (v) => captured = v),
    ),
  );
  return captured;
}

void main() {
  final testState = GameState(
    territories: const {},
    players: const [
      PlayerState(index: 0, name: 'Alice'),
      PlayerState(index: 1, name: 'Bot'),
    ],
    currentPlayerIndex: 0,
    turnPhase: TurnPhase.attack,
  );

  testWidgets('players[0].name', (t) async {
    final result = await _resolve(t, 'players[0].name', [
      gameProvider.overrideWith(() => _FakeGame(testState)),
    ]);
    expect(result, 'Alice');
  });

  testWidgets('players[1].name', (t) async {
    final result = await _resolve(t, 'players[1].name', [
      gameProvider.overrideWith(() => _FakeGame(testState)),
    ]);
    expect(result, 'Bot');
  });

  testWidgets('game.phaseLabel for attack', (t) async {
    final result = await _resolve(t, 'game.phaseLabel', [
      gameProvider.overrideWith(() => _FakeGame(testState)),
    ]);
    expect(result, 'ATTACK PHASE');
  });

  testWidgets('game.battleLog returns log entry strings', (t) async {
    final result = await _resolve(t, 'game.battleLog', [
      gameLogProvider.overrideWith(() => _FakeLog([
            LogEntry(message: 'A attacked B', timestamp: DateTime(2026)),
            LogEntry(message: 'B lost', timestamp: DateTime(2026)),
          ])),
    ]);
    expect(result, ['A attacked B', 'B lost']);
  });

  testWidgets('ui.diceCount returns a number', (t) async {
    final result = await _resolve(t, 'ui.diceCount', []);
    expect(result, isA<int>());
  });

  testWidgets('unknown path returns null', (t) async {
    final result = await _resolve(t, 'some.bogus.path', []);
    expect(result, isNull);
  });
}

class _FakeGame extends GameNotifier {
  final GameState _s;
  _FakeGame(this._s);
  @override
  Future<GameState?> build() async => _s;
}

class _FakeLog extends GameLog {
  final List<LogEntry> _entries;
  _FakeLog(this._entries);
  @override
  List<LogEntry> build() => _entries;
}
```

- [ ] **Step 2: Run failing tests**

Run: `cd mobile && flutter test test/hud/bindings_test.dart`
Expected: FAIL.

- [ ] **Step 3: Extend UIState with diceCount**

Open `mobile/lib/engine/models/ui_state.dart` and add `diceCount`:

```dart
@freezed
abstract class UIState with _$UIState {
  const factory UIState({
    String? selectedTerritory,
    String? selectedTarget,
    @Default({}) Set<String> validTargets,
    @Default({}) Set<String> validSources,
    @Default(0) int pendingArmies,
    @Default({}) Map<String, int> proposedPlacements,
    String? advanceSource,
    String? advanceTarget,
    @Default(0) int advanceMin,
    @Default(0) int advanceMax,
    @Default(3) int diceCount,   // NEW
  }) = _UIState;

  factory UIState.empty() => const UIState();
}
```

Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `ui_state.freezed.dart` regenerates without errors.

- [ ] **Step 4: Implement the binding registry**

Create `mobile/lib/hud/bindings.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/models/cards.dart';
import '../engine/models/game_state.dart';
import '../providers/game_log_provider.dart';
import '../providers/game_provider.dart';
import '../providers/ui_provider.dart';

/// Resolves a binding path (e.g. "players[0].name") against the current
/// Riverpod state. Returns null for unknown paths.
Object? resolveBinding(String path, WidgetRef ref) {
  switch (path) {
    case 'ui.diceCount':
      return ref.watch(uIStateProvider).diceCount;
  }

  // game.* paths
  final gameAsync = ref.watch(gameProvider);
  final gs = gameAsync.value;

  if (path == 'game.phaseLabel') return _phaseLabel(gs);
  if (path == 'game.phaseHint') return _phaseHint(gs);
  if (path == 'game.battleLog') {
    final log = ref.watch(gameLogProvider);
    return log.map((e) => e.message).toList();
  }

  // activePlayer.cardsLabel
  if (path == 'activePlayer.cardsLabel') {
    if (gs == null) return 'CARDS (0)';
    final hand = gs.cards[gs.currentPlayerIndex.toString()] ?? const <Card>[];
    return 'CARDS (${hand.length})';
  }

  // players[i].* — parse the index
  final m = RegExp(r'^players\[(\d+)\]\.(.+)$').firstMatch(path);
  if (m != null) {
    final index = int.parse(m.group(1)!);
    final field = m.group(2)!;
    if (gs == null || index >= gs.players.length) return null;
    final p = gs.players[index];
    final territoryCount =
        gs.territories.values.where((t) => t.owner == index).length;
    final armyCount =
        gs.territories.values.where((t) => t.owner == index).fold<int>(
              0,
              (a, t) => a + t.armies,
            );
    switch (field) {
      case 'name':
        return p.name;
      case 'stats':
        return '🏴 $territoryCount  🛡️ $armyCount';
      case 'summary':
        return '${p.name} — 🏴 $territoryCount  🛡️ $armyCount';
      default:
        return null;
    }
  }

  if (kDebugMode) {
    debugPrint('[hud.bindings] Unknown path: $path');
  }
  return null;
}

String _phaseLabel(GameState? gs) {
  if (gs == null) return '';
  switch (gs.turnPhase) {
    case TurnPhase.reinforce:
      return 'REINFORCE PHASE';
    case TurnPhase.attack:
      return 'ATTACK PHASE';
    case TurnPhase.fortify:
      return 'FORTIFY PHASE';
  }
}

String _phaseHint(GameState? gs) {
  if (gs == null) return '';
  switch (gs.turnPhase) {
    case TurnPhase.reinforce:
      return 'Place your reinforcements';
    case TurnPhase.attack:
      return 'Select attacker, then target';
    case TurnPhase.fortify:
      return 'Move armies between your territories';
  }
}

```

- [ ] **Step 5: Run tests**

Run: `cd mobile && flutter test test/hud/bindings_test.dart`
Expected: All 6 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/hud/bindings.dart mobile/lib/engine/models/ui_state.dart mobile/lib/engine/models/ui_state.freezed.dart mobile/test/hud/bindings_test.dart
git commit -m "feat(hud): binding registry resolving paths to Riverpod state"
```

---

## Task 9: Action registry

**Files:**
- Create: `mobile/lib/hud/actions.dart`
- Test: `mobile/test/hud/actions_test.dart`
- Modify: `mobile/lib/providers/ui_provider.dart` (add `setDiceCount`)

- [ ] **Step 1: Add `setDiceCount` to UIStateNotifier**

Open `mobile/lib/providers/ui_provider.dart` and add a method to the `UIStateNotifier` class:

```dart
/// Set the dice count for the attack phase (1, 2, or 3).
void setDiceCount(int count) {
  if (count < 1 || count > 3) return;
  state = state.copyWith(diceCount: count);
}
```

- [ ] **Step 2: Write failing tests**

Create `mobile/test/hud/actions_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/actions.dart';
import 'package:risk_mobile/providers/ui_provider.dart';

class _Trigger extends ConsumerWidget {
  final String action;
  const _Trigger(this.action);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => dispatchAction(action, ref),
      child: const SizedBox(width: 100, height: 100),
    );
  }
}

void main() {
  testWidgets('selectDice:2 updates UI state', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: _Trigger('selectDice:2'),
      ),
    ));

    expect(container.read(uIStateProvider).diceCount, 3); // default
    await t.tap(find.byType(GestureDetector));
    expect(container.read(uIStateProvider).diceCount, 2);
  });

  testWidgets('unknown action is a no-op', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: _Trigger('bogus.action'),
      ),
    ));
    await t.tap(find.byType(GestureDetector)); // no throw
  });
}
```

- [ ] **Step 3: Run failing tests**

Run: `cd mobile && flutter test test/hud/actions_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement `mobile/lib/hud/actions.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/actions.dart' as ga;
import '../engine/models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/ui_provider.dart';

/// Dispatches a declarative action string to the appropriate game mutation.
void dispatchAction(String action, WidgetRef ref) {
  // selectDice:N
  final diceMatch = RegExp(r'^selectDice:(\d+)$').firstMatch(action);
  if (diceMatch != null) {
    final n = int.parse(diceMatch.group(1)!);
    ref.read(uIStateProvider.notifier).setDiceCount(n);
    return;
  }

  switch (action) {
    case 'attack':
      _doAttack(ref);
      return;
    case 'blitz':
      _doBlitz(ref);
      return;
    case 'endPhase':
      _doEndPhase(ref);
      return;
    case 'openCards':
      // Card hand visibility is owned by CardHandWidget's internal state;
      // Task 12 wires this to a ValueNotifier exposed by that widget.
      _openCards(ref);
      return;
  }

  if (kDebugMode) {
    debugPrint('[hud.actions] Unknown action: $action');
  }
}

void _doAttack(WidgetRef ref) {
  final ui = ref.read(uIStateProvider);
  final src = ui.selectedTerritory;
  final tgt = ui.selectedTarget;
  if (src == null || tgt == null) return;
  ref.read(gameProvider.notifier).humanMove(
        ga.AttackAction(source: src, target: tgt, numDice: ui.diceCount),
      );
}

void _doBlitz(WidgetRef ref) {
  final ui = ref.read(uIStateProvider);
  final src = ui.selectedTerritory;
  final tgt = ui.selectedTarget;
  if (src == null || tgt == null) return;
  ref.read(gameProvider.notifier).humanMove(
        ga.BlitzAction(source: src, target: tgt),
      );
}

void _doEndPhase(WidgetRef ref) {
  final gs = ref.read(gameProvider).value;
  if (gs == null) return;
  // Null action → end attack OR skip fortify, depending on current phase.
  ref.read(gameProvider.notifier).humanMove(null);
}

void _openCards(WidgetRef ref) {
  // Implemented in Task 12 via cardHandVisibilityProvider.
  // For now, a no-op; Task 12 replaces this body.
}
```

- [ ] **Step 5: Run tests**

Run: `cd mobile && flutter test test/hud/actions_test.dart`
Expected: Both tests PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/hud/actions.dart mobile/lib/providers/ui_provider.dart mobile/lib/providers/ui_provider.g.dart mobile/test/hud/actions_test.dart
git commit -m "feat(hud): action registry dispatching to existing game mutations"
```

---

## Task 10: selectedWhen evaluator

**Files:**
- Create: `mobile/lib/hud/selected_when.dart`
- Test: `mobile/test/hud/selected_when_test.dart`

- [ ] **Step 1: Write failing tests**

Create `mobile/test/hud/selected_when_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/selected_when.dart';

class _Probe extends ConsumerWidget {
  final String expr;
  final void Function(bool) onEval;
  const _Probe({required this.expr, required this.onEval});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onEval(evaluateSelectedWhen(expr, ref));
    return const SizedBox();
  }
}

Future<bool> _eval(WidgetTester t, String expr) async {
  bool captured = false;
  await t.pumpWidget(ProviderScope(
    child: _Probe(expr: expr, onEval: (v) => captured = v),
  ));
  return captured;
}

void main() {
  testWidgets('ui.diceCount == 3 matches default', (t) async {
    expect(await _eval(t, 'ui.diceCount == 3'), isTrue);
  });

  testWidgets('ui.diceCount == 2 does not match default', (t) async {
    expect(await _eval(t, 'ui.diceCount == 2'), isFalse);
  });

  testWidgets('string literal comparison', (t) async {
    expect(await _eval(t, 'game.phaseLabel == "ATTACK PHASE"'), isFalse); // no game state
  });

  testWidgets('malformed expression returns false', (t) async {
    expect(await _eval(t, 'garbage'), isFalse);
  });
}
```

- [ ] **Step 2: Run failing tests**

Run: `cd mobile && flutter test test/hud/selected_when_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement the evaluator**

Create `mobile/lib/hud/selected_when.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bindings.dart';

/// Evaluates a `<binding> == <literal>` expression. Only this shape is supported.
bool evaluateSelectedWhen(String expr, WidgetRef ref) {
  final match = RegExp(r'^\s*(.+?)\s*==\s*(.+?)\s*$').firstMatch(expr);
  if (match == null) {
    if (kDebugMode) debugPrint('[hud.selectedWhen] Bad expression: $expr');
    return false;
  }
  final left = resolveBinding(match.group(1)!, ref);
  final rhs = match.group(2)!.trim();

  // String literal ("X")
  if (rhs.length >= 2 && rhs.startsWith('"') && rhs.endsWith('"')) {
    final str = rhs.substring(1, rhs.length - 1);
    return left?.toString() == str;
  }

  // Integer literal
  final n = int.tryParse(rhs);
  if (n != null) {
    return left == n;
  }

  if (kDebugMode) {
    debugPrint('[hud.selectedWhen] Unsupported literal: $rhs');
  }
  return false;
}
```

- [ ] **Step 4: Run tests**

Run: `cd mobile && flutter test test/hud/selected_when_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/hud/selected_when.dart mobile/test/hud/selected_when_test.dart
git commit -m "feat(hud): selectedWhen evaluator for ==literal expressions"
```

---

## Task 11: HUD loader and Riverpod provider

**Files:**
- Create: `mobile/lib/hud/hud_loader.dart`
- Test: `mobile/test/hud/hud_loader_test.dart`

- [ ] **Step 1: Write failing tests**

Create `mobile/test/hud/hud_loader_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/hud_loader.dart';
import 'package:risk_mobile/hud/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const valid = {
    'version': 1,
    'theme': {
      'background': '#000',
      'border': '#111',
      'text': '#FFB300',
      'borderRadius': 10,
    },
    'layouts': {
      'mobile-landscape': {
        'canvasSize': [844, 390],
        'root': {
          'type': 'grid',
          'id': 'root',
          'rows': ['1fr'],
          'cols': ['1fr'],
          'children': [],
        },
      },
    },
  };

  test('parses valid HUD JSON from string', () async {
    final config = parseHudConfig(jsonEncode(valid));
    expect(config.version, 1);
  });

  test('throws with friendly message on malformed JSON', () {
    expect(() => parseHudConfig('{not json'), throwsA(isA<FormatException>()));
  });

  test('throws on unknown element type', () {
    final bad = Map<String, dynamic>.from(valid);
    bad['layouts'] = {
      'mobile-landscape': {
        'canvasSize': [100, 100],
        'root': {
          'type': 'unknown',
          'id': 'x',
        },
      },
    };
    expect(() => parseHudConfig(jsonEncode(bad)), throwsA(isA<FormatException>()));
  });

  testWidgets('hudConfigProvider loads the real asset', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final config = await container.read(hudConfigProvider.future);
    expect(config.layouts.keys, containsAll(['mobile-landscape', 'desktop-landscape']));
  });
}
```

- [ ] **Step 2: Run failing tests**

Run: `cd mobile && flutter test test/hud/hud_loader_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement the loader**

Create `mobile/lib/hud/hud_loader.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models.dart';

part 'hud_loader.g.dart';

/// Synchronously parse HUD config from a JSON string. Throws FormatException
/// with a specific message on any parsing or validation failure.
HudConfig parseHudConfig(String raw) {
  late final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    throw FormatException('Invalid HUD JSON: $e');
  }
  try {
    return HudConfig.fromJson(json);
  } on FormatException {
    rethrow;
  } catch (e, st) {
    throw FormatException('Failed to build HudConfig: $e\n$st');
  }
}

@Riverpod(keepAlive: true)
Future<HudConfig> hudConfig(Ref ref) async {
  final raw = await rootBundle.loadString('assets/hud.json');
  return parseHudConfig(raw);
}
```

Run codegen: `cd mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run tests**

Run: `cd mobile && flutter test test/hud/hud_loader_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/hud/hud_loader.dart mobile/lib/hud/hud_loader.g.dart mobile/test/hud/hud_loader_test.dart
git commit -m "feat(hud): loader and Riverpod provider for assets/hud.json"
```

---

## Task 12: Generic element renderers (label, icon, button, grid)

**Files:**
- Create: `mobile/lib/hud/elements/generic.dart`

- [ ] **Step 1: Create the generic renderer file**

Create `mobile/lib/hud/elements/generic.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../actions.dart';
import '../bindings.dart';
import '../grid_layout.dart';
import '../models.dart';
import '../selected_when.dart';
import '../style.dart';
import '../style_box.dart';

/// Top-level dispatch: given any HudElement, produce a widget.
Widget renderElement(HudElement el, HudTheme theme) {
  if (el is HudGrid) return _Grid(grid: el, theme: theme);
  if (el is HudLabel) return _Label(label: el, theme: theme);
  if (el is HudIcon) return _Icon(icon: el, theme: theme);
  if (el is HudButton) return _Button(button: el, theme: theme);
  if (el is HudList) return _listWidget(el, theme);
  if (el is HudCardHand) return _cardHandWidget(el, theme);
  return const SizedBox();
}

/// Wrap a child with grid placement data so HudGridLayout sees it.
Widget _placed(HudElement el, Widget child) {
  return LayoutId(
    id: el.id,
    child: HudGridCell(
      row: el.row ?? 0,
      col: el.col ?? 0,
      rowSpan: el.rowSpan ?? 1,
      colSpan: el.colSpan ?? 1,
      alignSelf: (el.style?['alignSelf']) as String?,
      justifySelf: (el.style?['justifySelf']) as String?,
      child: child,
    ),
  );
}

class _Grid extends StatelessWidget {
  final HudGrid grid;
  final HudTheme theme;
  const _Grid({required this.grid, required this.theme});

  @override
  Widget build(BuildContext context) {
    final gap = (grid.style?['gap'] is num)
        ? (grid.style!['gap'] as num).toDouble()
        : 0.0;
    final inner = HudGridLayout(
      rows: grid.rows,
      cols: grid.cols,
      gap: gap,
      children: grid.children.map((c) => _placed(c, renderElement(c, theme))).toList(),
    );
    return HudStyleBox(theme: theme, style: grid.style, child: inner);
  }
}

class _Label extends ConsumerWidget {
  final HudLabel label;
  final HudTheme theme;
  const _Label({required this.label, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bound = label.binding != null
        ? resolveBinding(label.binding!, ref)?.toString()
        : null;
    final text = bound ?? label.text ?? '';
    return HudStyleBox(
      theme: theme,
      style: label.style,
      child: Text(text, style: _textStyleFrom(label.style, theme)),
    );
  }
}

class _Icon extends StatelessWidget {
  final HudIcon icon;
  final HudTheme theme;
  const _Icon({required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    final mat = _materialIconFromName(icon.name);
    final color = (icon.style?['color'] is String)
        ? parseColor(icon.style!['color'] as String, theme)
        : null;
    final size = (icon.style?['fontSize'] is num)
        ? (icon.style!['fontSize'] as num).toDouble()
        : 14.0;
    return HudStyleBox(
      theme: theme,
      style: icon.style,
      child: Icon(mat, color: color, size: size),
    );
  }
}

class _Button extends ConsumerWidget {
  final HudButton button;
  final HudTheme theme;
  const _Button({required this.button, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = button.selectedWhen != null
        ? evaluateSelectedWhen(button.selectedWhen!, ref)
        : false;
    final style = selected && button.selectedStyle != null
        ? {...?button.style, ...button.selectedStyle!}
        : button.style;
    return HudStyleBox(
      theme: theme,
      style: style,
      child: InkWell(
        onTap: button.action != null
            ? () => dispatchAction(button.action!, ref)
            : null,
        child: Center(
          child: Text(button.text ?? '', style: _textStyleFrom(style, theme)),
        ),
      ),
    );
  }
}

TextStyle _textStyleFrom(Map<String, dynamic>? s, HudTheme theme) {
  if (s == null) return const TextStyle();
  final color = s['color'] is String ? parseColor(s['color'] as String, theme) : null;
  final fontSize = s['fontSize'] is num ? (s['fontSize'] as num).toDouble() : null;
  FontWeight? fw;
  if (s['fontWeight'] == 'bold') fw = FontWeight.bold;
  TextAlign? ta;
  // TextAlign isn't a TextStyle field; handle at widget level if needed.
  return TextStyle(color: color, fontSize: fontSize, fontWeight: fw);
}

IconData _materialIconFromName(String name) {
  switch (name) {
    case 'person':
      return Icons.person;
    case 'smart_toy':
      return Icons.smart_toy;
    case 'style':
      return Icons.style;
    default:
      return Icons.help_outline;
  }
}

// Forward declarations for widgets in other files.
// Task 13 defines _listWidget and _cardHandWidget as real imports.
Widget _listWidget(HudList el, HudTheme theme) => const SizedBox();
Widget _cardHandWidget(HudCardHand el, HudTheme theme) => const SizedBox();
```

(Task 13 replaces the two trailing stubs with real imports.)

- [ ] **Step 2: Smoke test — render a trivial tree**

Create `mobile/test/hud/generic_elements_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/elements/generic.dart';
import 'package:risk_mobile/hud/models.dart';

const _theme = HudTheme(
  background: '#000',
  border: '#111',
  text: '#FFB300',
  borderRadius: 10,
);

void main() {
  testWidgets('renders a label with static text', (t) async {
    final label = const HudLabel(
      id: 'l',
      text: 'Hello',
      row: 0,
      col: 0,
      style: {'fontSize': 12, 'color': '#FF0000'},
    );
    await t.pumpWidget(ProviderScope(child: MaterialApp(
      home: Scaffold(body: renderElement(label, _theme)),
    )));
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('renders a grid with a child label', (t) async {
    final root = const HudGrid(
      id: 'root',
      rows: ['1fr'],
      cols: ['1fr'],
      children: [
        HudLabel(id: 'l', text: 'Inside', row: 0, col: 0),
      ],
    );
    await t.pumpWidget(ProviderScope(child: MaterialApp(
      home: Scaffold(body: renderElement(root, _theme)),
    )));
    expect(find.text('Inside'), findsOneWidget);
  });
}
```

Run: `cd mobile && flutter test test/hud/generic_elements_test.dart`
Expected: Both PASS.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/hud/elements/generic.dart mobile/test/hud/generic_elements_test.dart
git commit -m "feat(hud): generic renderers for grid/label/icon/button"
```

---

## Task 13: Rich widgets (attack log + card hand)

**Files:**
- Create: `mobile/lib/hud/widgets/attack_log.dart`
- Create: `mobile/lib/hud/widgets/card_hand.dart`
- Modify: `mobile/lib/hud/elements/generic.dart` (replace stubs)
- Test: `mobile/test/hud/attack_log_test.dart`

- [ ] **Step 1: Write failing test for AttackLogWidget**

Create `mobile/test/hud/attack_log_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/log_entry.dart';
import 'package:risk_mobile/hud/models.dart';
import 'package:risk_mobile/hud/widgets/attack_log.dart';
import 'package:risk_mobile/providers/game_log_provider.dart';

const _theme = HudTheme(
  background: '#000', border: '#111', text: '#FFB300', borderRadius: 10,
);

class _FakeLog extends GameLog {
  final List<LogEntry> _e;
  _FakeLog(this._e);
  @override
  List<LogEntry> build() => _e;
}

void main() {
  testWidgets('renders up to maxItems most recent log lines', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        gameLogProvider.overrideWith(() => _FakeLog([
              LogEntry(message: 'one', timestamp: DateTime(2026)),
              LogEntry(message: 'two', timestamp: DateTime(2026)),
              LogEntry(message: 'three', timestamp: DateTime(2026)),
              LogEntry(message: 'four', timestamp: DateTime(2026)),
              LogEntry(message: 'five', timestamp: DateTime(2026)),
            ])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AttackLogWidget(
            element: const HudList(
              id: 'log', maxItems: 3, itemBinding: 'game.battleLog', row: 0, col: 0,
            ),
            theme: _theme,
          ),
        ),
      ),
    ));
    expect(find.text('three'), findsOneWidget);
    expect(find.text('four'), findsOneWidget);
    expect(find.text('five'), findsOneWidget);
    expect(find.text('one'), findsNothing);
  });
}
```

- [ ] **Step 2: Run failing test**

Run: `cd mobile && flutter test test/hud/attack_log_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement AttackLogWidget**

Create `mobile/lib/hud/widgets/attack_log.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bindings.dart';
import '../models.dart';
import '../style.dart';
import '../style_box.dart';

class AttackLogWidget extends ConsumerWidget {
  final HudList element;
  final HudTheme theme;
  const AttackLogWidget({super.key, required this.element, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = resolveBinding(element.itemBinding, ref);
    final items = raw is List ? raw.cast<String>() : const <String>[];
    final recent = items.length > element.maxItems
        ? items.sublist(items.length - element.maxItems)
        : items;
    final fontSize = (element.style?['fontSize'] is num)
        ? (element.style!['fontSize'] as num).toDouble()
        : 10.0;
    final color = (element.style?['color'] is String)
        ? parseColor(element.style!['color'] as String, theme)
        : Colors.white70;

    return HudStyleBox(
      theme: theme,
      style: element.style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: recent
            .map((line) => Text(line,
                style: TextStyle(fontSize: fontSize, color: color)))
            .toList(),
      ),
    );
  }
}
```

- [ ] **Step 4: Move the existing card hand code into a new widget**

Locate the current card-panel implementation referenced by `_FloatingCardsButton` in `mobile/lib/widgets/mobile_game_overlay.dart`. Read it. Lift the visual-hand rendering (not the floating button) into `mobile/lib/hud/widgets/card_hand.dart` as a `ConsumerWidget` with signature:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../style_box.dart';

class CardHandWidget extends ConsumerWidget {
  final HudCardHand element;
  final HudTheme theme;
  const CardHandWidget({super.key, required this.element, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: reference the extracted card-hand rendering from mobile_game_overlay.dart.
    // Wrap in HudStyleBox for consistent margin/padding.
    return HudStyleBox(
      theme: theme,
      style: element.style,
      child: /* copied card hand rendering — preserve existing semantics */
          const Placeholder(),
    );
  }
}
```

Replace the `Placeholder` with the exact card-list + trade-in rendering from the old widget. Do not change any card-handling semantics — only move the widget code.

- [ ] **Step 5: Wire the rich widgets into the generic renderer**

Open `mobile/lib/hud/elements/generic.dart` and replace the two trailing stubs with real imports:

```dart
import '../widgets/attack_log.dart';
import '../widgets/card_hand.dart';

// Replace the stub functions at the bottom:
Widget _listWidget(HudList el, HudTheme theme) {
  if (el.itemBinding == 'game.battleLog') {
    return AttackLogWidget(element: el, theme: theme);
  }
  assert(false, 'Unknown itemBinding: ${el.itemBinding}');
  return const SizedBox();
}

Widget _cardHandWidget(HudCardHand el, HudTheme theme) =>
    CardHandWidget(element: el, theme: theme);
```

- [ ] **Step 6: Wire `openCards` action into a visibility provider**

Create `mobile/lib/hud/widgets/card_hand_visibility_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_hand_visibility_provider.g.dart';

@Riverpod(keepAlive: true)
class CardHandVisibility extends _$CardHandVisibility {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
```

Run codegen: `cd mobile && dart run build_runner build --delete-conflicting-outputs`

Update `_openCards` in `mobile/lib/hud/actions.dart`:

```dart
import 'widgets/card_hand_visibility_provider.dart';
// ...
void _openCards(WidgetRef ref) =>
    ref.read(cardHandVisibilityProvider.notifier).toggle();
```

In `CardHandWidget`, watch `cardHandVisibilityProvider` and collapse when false:

```dart
final visible = ref.watch(cardHandVisibilityProvider);
if (!visible) return const SizedBox.shrink();
```

- [ ] **Step 7: Run the attack-log tests**

Run: `cd mobile && flutter test test/hud/attack_log_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/hud/widgets/ mobile/lib/hud/elements/generic.dart mobile/lib/hud/actions.dart mobile/test/hud/attack_log_test.dart
git commit -m "feat(hud): attack log + card hand rich widgets wired into renderer"
```

---

## Task 14: HudRenderer root widget + layout selection

**Files:**
- Create: `mobile/lib/hud/hud_renderer.dart`

- [ ] **Step 1: Implement the root renderer**

Create `mobile/lib/hud/hud_renderer.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'elements/generic.dart';
import 'hud_loader.dart';
import 'models.dart';

class HudRenderer extends ConsumerWidget {
  const HudRenderer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hudConfigProvider);
    return async.when(
      data: (config) => _HudRootLayout(config: config),
      loading: () => const SizedBox(),
      error: (e, st) => _HudErrorWidget(error: e),
    );
  }
}

class _HudRootLayout extends StatelessWidget {
  final HudConfig config;
  const _HudRootLayout({required this.config});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final key = width < 900 ? 'mobile-landscape' : 'desktop-landscape';
    final layout = config.layouts[key] ?? config.layouts.values.first;
    return IgnorePointer(
      ignoring: false,
      child: renderElement(layout.root, config.theme),
    );
  }
}

class _HudErrorWidget extends StatelessWidget {
  final Object error;
  const _HudErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'HUD failed to load\n\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/hud/hud_renderer.dart
git commit -m "feat(hud): HudRenderer root widget with width-based layout selection"
```

---

## Task 15: Integrate into GameScreen + landscape lock

**Files:**
- Modify: `mobile/lib/screens/game_screen.dart`
- Modify: `mobile/lib/main.dart`

- [ ] **Step 1: Lock landscape in main.dart**

Open `mobile/lib/main.dart` and find the `main()` function. Before `runApp(...)`, add:

```dart
import 'package:flutter/services.dart';
// ...
WidgetsFlutterBinding.ensureInitialized();
await SystemChrome.setPreferredOrientations([
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
]);
```

- [ ] **Step 2: Simplify GameScreen.build**

Open `mobile/lib/screens/game_screen.dart`. Replace the body so the final return reads:

```dart
return PopScope(
  canPop: false,
  onPopInvokedWithResult: _handlePop,
  child: Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: MapWidget(/* pass existing args */)),
          const Positioned.fill(child: HudRenderer()),
        ],
      ),
    ),
  ),
);
```

Remove the `_PortraitLayout` usage entirely. Remove the import of `../widgets/mobile_game_overlay.dart` and any other old HUD imports the screen references.

Add: `import '../hud/hud_renderer.dart';`

- [ ] **Step 3: Run the app and smoke-test manually**

Run: `cd mobile && flutter run -d <device>` (or `flutter run -d windows`).

Expected:
- App opens in landscape.
- The map renders.
- The HUD renders: two player chips, phase label/hint, dice buttons, ATTACK/BLITZ/END buttons, attack log in the appropriate corner.
- Tapping ATTACK/BLITZ/END with a selected attacker and target triggers the same game behavior as before.
- Tapping dice 1/2/3 visibly selects that button (via `selectedWhen`).

If anything is missing or wrong, fix it in place before moving on.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/screens/game_screen.dart mobile/lib/main.dart
git commit -m "feat(hud): game screen renders HUD from hud.json; lock landscape"
```

---

## Task 16: Golden tests for both layouts

**Files:**
- Test: `mobile/test/hud/hud_renderer_golden_test.dart`

- [ ] **Step 1: Write the golden test**

Create `mobile/test/hud/hud_renderer_golden_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/cards.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/hud/hud_renderer.dart';
import 'package:risk_mobile/providers/game_provider.dart';

class _FakeGame extends GameNotifier {
  final GameState _s;
  _FakeGame(this._s);
  @override
  Future<GameState?> build() async => _s;
}

GameState _fixture() => const GameState(
      territories: {
        'Alaska': TerritoryState(owner: 0, armies: 3),
        'Siberia': TerritoryState(owner: 1, armies: 2),
      },
      players: [
        PlayerState(index: 0, name: 'Player 1'),
        PlayerState(index: 1, name: 'Bot Player'),
      ],
      currentPlayerIndex: 0,
      turnPhase: TurnPhase.attack,
    );

void main() {
  testWidgets('mobile-landscape golden', (t) async {
    await t.binding.setSurfaceSize(const Size(844, 390));
    await t.pumpWidget(ProviderScope(
      overrides: [gameProvider.overrideWith(() => _FakeGame(_fixture()))],
      child: const MaterialApp(home: Scaffold(body: HudRenderer())),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byType(HudRenderer),
      matchesGoldenFile('goldens/hud_mobile_landscape.png'),
    );
  });

  testWidgets('desktop-landscape golden', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 700));
    await t.pumpWidget(ProviderScope(
      overrides: [gameProvider.overrideWith(() => _FakeGame(_fixture()))],
      child: const MaterialApp(home: Scaffold(body: HudRenderer())),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byType(HudRenderer),
      matchesGoldenFile('goldens/hud_desktop_landscape.png'),
    );
  });
}
```

- [ ] **Step 2: Generate the golden PNGs**

Run: `cd mobile && flutter test test/hud/hud_renderer_golden_test.dart --update-goldens`
Expected: `mobile/test/hud/goldens/hud_mobile_landscape.png` and `hud_desktop_landscape.png` are created.

- [ ] **Step 3: Inspect the goldens by eye**

Open both PNG files. Confirm:
- The `mobile-landscape` PNG shows the top player bar + floating attack log + bottom action bar.
- The `desktop-landscape` PNG shows the map area (empty in this fixture — that's fine) + sidebar on the right with both player chips, phase label, ATTACK/BLITZ/END.

If the PNGs look broken, fix the underlying renderer/layout bug; don't "fix" by re-capturing.

- [ ] **Step 4: Re-run the tests to verify they pass against the committed goldens**

Run: `cd mobile && flutter test test/hud/hud_renderer_golden_test.dart`
Expected: Both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/test/hud/hud_renderer_golden_test.dart mobile/test/hud/goldens/
git commit -m "test(hud): golden tests for mobile and desktop landscape layouts"
```

---

## Task 17: Smoke test pumping GameScreen

**Files:**
- Test: `mobile/test/hud/game_screen_smoke_test.dart`

- [ ] **Step 1: Write the smoke test**

Create `mobile/test/hud/game_screen_smoke_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/engine/models/game_config.dart';
import 'package:risk_mobile/engine/models/game_state.dart';
import 'package:risk_mobile/hud/hud_renderer.dart';
import 'package:risk_mobile/providers/game_provider.dart';
import 'package:risk_mobile/screens/game_screen.dart';

class _FakeGame extends GameNotifier {
  @override
  Future<GameState?> build() async => const GameState(
        territories: {},
        players: [
          PlayerState(index: 0, name: 'P1'),
          PlayerState(index: 1, name: 'P2'),
        ],
      );
}

void main() {
  testWidgets('GameScreen renders HudRenderer and does not throw', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 700));
    await t.pumpWidget(ProviderScope(
      overrides: [gameProvider.overrideWith(() => _FakeGame())],
      child: const MaterialApp(home: GameScreen(gameMode: GameMode.vsBot)),
    ));
    await t.pumpAndSettle();
    expect(find.byType(HudRenderer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run the smoke test**

Run: `cd mobile && flutter test test/hud/game_screen_smoke_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add mobile/test/hud/game_screen_smoke_test.dart
git commit -m "test(hud): smoke test that GameScreen mounts HudRenderer cleanly"
```

---

## Task 18: Delete the old HUD code

**Files:**
- Delete: `mobile/lib/widgets/mobile_game_overlay.dart`
- Delete: `mobile/lib/widgets/player_info_bar.dart`
- Delete: `mobile/lib/widgets/mobile_action_bar.dart`
- Delete (verify unused): `mobile/lib/widgets/action_panel.dart`
- Delete (verify unused): `mobile/lib/widgets/game_log.dart`
- Delete (verify unused): `mobile/lib/widgets/continent_panel.dart`
- Modify: `mobile/lib/screens/game_screen.dart` (remove any `_PortraitLayout`/`_LandscapeLayout` private classes + related methods)

- [ ] **Step 1: Verify nothing outside these files imports them**

Run one grep per candidate file:

```bash
# Each of these should produce only the file's own line (it imports itself? no — nothing).
grep -rn "mobile_game_overlay" mobile/lib mobile/test
grep -rn "player_info_bar" mobile/lib mobile/test
grep -rn "mobile_action_bar" mobile/lib mobile/test
grep -rn "action_panel" mobile/lib mobile/test
grep -rn "game_log.dart" mobile/lib mobile/test   # filename is game_log.dart (a widget), not game_log_provider.dart
grep -rn "continent_panel" mobile/lib mobile/test
```

Expected: Only matches inside the file being deleted itself, or references inside `game_screen.dart` that we're about to clean up. No matches from elsewhere.

If a match appears in a file we don't plan to touch, either (a) the file is still needed, in which case stop and report it, or (b) update the usage site.

- [ ] **Step 2: Delete the files**

```bash
git rm mobile/lib/widgets/mobile_game_overlay.dart
git rm mobile/lib/widgets/player_info_bar.dart
git rm mobile/lib/widgets/mobile_action_bar.dart
git rm mobile/lib/widgets/action_panel.dart
git rm mobile/lib/widgets/game_log.dart
git rm mobile/lib/widgets/continent_panel.dart
```

- [ ] **Step 3: Clean up game_screen.dart**

Open `mobile/lib/screens/game_screen.dart`. Remove the private classes `_PortraitLayout` and `_LandscapeLayout` (and any helpers used only by them) if they still exist. Remove the stale imports:

```dart
// DELETE these lines:
import '../widgets/action_panel.dart';
import '../widgets/continent_panel.dart';
import '../widgets/game_log.dart';
import '../widgets/mobile_game_overlay.dart';
```

The file should now only import what it actually uses.

- [ ] **Step 4: Analyze and test**

Run:
```bash
cd mobile && flutter analyze
cd mobile && flutter test
```

Expected: `flutter analyze` reports no errors. `flutter test` runs the full suite and all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/screens/game_screen.dart
git commit -m "refactor(hud): delete old hand-coded HUD widgets and portrait layout"
```

---

## Self-review notes

- Every task has a failing-test → implementation → passing-test → commit rhythm where behavior is being introduced. Pure-structural tasks (1, 2, 3, 15, 18) still end in a verification step (asset loads, analyzer clean, tests pass).
- Types used across tasks: `HudConfig`, `HudTheme`, `HudLayout`, `HudElement` (sealed), `HudGrid`, `HudLabel`, `HudButton`, `HudIcon`, `HudList`, `HudCardHand`. All defined in Task 4 and referenced consistently afterward.
- Function names: `parseColor`, `parseGradient` (Task 5), `HudStyleBox` (Task 6), `HudGridLayout` / `HudGridCell` (Task 7), `resolveBinding` (Task 8), `dispatchAction` (Task 9), `evaluateSelectedWhen` (Task 10), `parseHudConfig` + `hudConfigProvider` (Task 11), `renderElement` (Task 12), `HudRenderer` (Task 14). Consistent.
- Spec coverage: asset location (Task 1), editor schema extension (Tasks 2-3), models (4), style parsing (5-6), grid engine (7), bindings (8), actions (9), selectedWhen (10), loader (11), element renderers (12), rich widgets (13), layout selection (14), integration (15), goldens (16), smoke (17), deletions (18). All spec sections represented.
- The `diceCount` addition to `UIState` is Task 8, Step 4 — a minor model change justified by the binding registry's need for `ui.diceCount`. Added inline rather than a separate task to avoid a partial-state commit.
