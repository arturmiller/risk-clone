---
phase: 06-flutter-scaffold-and-data-models
plan: 01
subsystem: infra
tags: [flutter, dart, riverpod, freezed, objectbox, json_serializable, build_runner]

requires: []

provides:
  - Flutter project scaffold in mobile/ with all dependencies pinned (flutter_riverpod 3.3.1, riverpod_generator 4.0.3, freezed 3.2.5, objectbox 5.2.0)
  - pubspec.yaml, analysis_options.yaml, build.yaml with correct code-gen configuration
  - mobile/assets/classic.json (42 territories, copied from risk/data/)
  - Minimal Flutter app entry point: main.dart (ProviderScope), app.dart (MaterialApp), home_screen.dart (placeholder)
  - Wave 0 test stubs: map_graph_test.dart (8 cases), models_test.dart (3 groups), save_slot_test.dart (skipped pending ObjectBox native libs)

affects:
  - 06-02 (MapGraph + @freezed models — builds directly on this scaffold)
  - 06-03 (ObjectBox persistence — SaveSlot test stub ready)
  - 07-dart-engine-port (imports engine/ from this project)
  - All subsequent Flutter phases

tech-stack:
  added:
    - flutter_riverpod ^3.3.1
    - riverpod_annotation ^4.0.2
    - riverpod_generator ^4.0.3 (NOT 2.6.0 — Riverpod 3.x requires 4.x generator)
    - freezed ^3.2.5 + freezed_annotation ^3.0.0
    - json_annotation ^4.9.0 + json_serializable ^6.13.0
    - objectbox ^5.2.0 + objectbox_flutter_libs: any (NOT path dep)
    - objectbox_generator: any
    - shared_preferences ^2.5.4
    - path_parsing ^1.1.0 + flutter_svg ^2.2.4 (installed now, used Phase 10)
    - build_runner ^2.4.0
    - mocktail ^1.0.4
  patterns:
    - analysis_options.yaml must suppress invalid_annotation_target for freezed
    - build.yaml must set explicit_to_json: true for nested @freezed model serialization
    - objectbox_flutter_libs: any (not a path dep) — pub.dev package handles native libs
    - ProviderScope wraps runApp in main.dart for Riverpod

key-files:
  created:
    - mobile/pubspec.yaml
    - mobile/pubspec.lock
    - mobile/analysis_options.yaml
    - mobile/build.yaml
    - mobile/assets/classic.json
    - mobile/lib/main.dart
    - mobile/lib/app.dart
    - mobile/lib/screens/home_screen.dart
    - mobile/test/engine/map_graph_test.dart
    - mobile/test/engine/models_test.dart
    - mobile/test/persistence/save_slot_test.dart
  modified: []

key-decisions:
  - "riverpod_generator: ^4.0.3 (not ^2.6.0 from STACK.md) — Riverpod 3.x requires 4.x generator"
  - "objectbox_flutter_libs: any (not path dep) — pub.dev package, no download-libs command needed"
  - "analysis_options.yaml uses flutter_lints not flutter — per research spec; adds invalid_annotation_target: ignore"
  - "classic.json copied (not symlinked) to mobile/assets/ — symlinks unreliable on Windows build machines"
  - "cards field will use Map<String, List<Card>> not Map<int, List<Card>> — JSON map keys must be strings"

patterns-established:
  - "Pattern: analysis_options.yaml with invalid_annotation_target: ignore for all future Flutter phases"
  - "Pattern: build.yaml with explicit_to_json: true prevents silent nested model serialization failures"
  - "Pattern: objectbox_flutter_libs: any — do not pin version"
  - "Pattern: Wave 0 test stubs define interface contracts before implementation"

requirements-completed:
  - DART-07

duration: 8min
completed: 2026-03-15
---

# Phase 6 Plan 01: Flutter Scaffold and Data Models Summary

**Flutter 3.41.4 project scaffold with all code-gen dependencies pinned (Riverpod 3.x + freezed 3.x + ObjectBox 5.x), correct build toolchain config, classic.json asset, and Wave 0 test stubs defining contracts for Plans 02 and 03**

## Performance

- **Duration:** 8 min (includes Flutter SDK download and extraction)
- **Started:** 2026-03-15T05:56:09Z
- **Completed:** 2026-03-15T06:02:17Z
- **Tasks:** 2
- **Files modified:** 11 new files (plus 120 Flutter scaffold files from flutter create)

## Accomplishments

- Created `mobile/` Flutter project with `flutter create --org com.riskgame --project-name risk_mobile`
- Replaced generated pubspec.yaml with all dependencies pinned per research, correcting two critical version errors from project STACK.md (riverpod_generator 4.x, objectbox_flutter_libs: any)
- Wrote analysis_options.yaml suppressing invalid_annotation_target and build.yaml enabling explicit_to_json — both required for freezed code generation to work correctly
- Copied risk/data/classic.json (42 territories) to mobile/assets/ and declared as Flutter asset
- Wrote minimal Flutter entry point: ProviderScope in main.dart, RiskApp in app.dart, placeholder HomeScreen
- `flutter pub get` exits 0 with all 98 dependencies resolved
- Wrote 3 Wave 0 test stub files defining contracts for MapGraph (8 tests), @freezed models (3 test groups), and ObjectBox SaveSlot

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Flutter project and configure dependencies** - `0916839` (feat)
2. **Task 2: Write test stubs (Wave 0 contracts)** - `c4c5946` (test)

## Files Created/Modified

- `mobile/pubspec.yaml` — All dependencies pinned per research; flutter.assets declares classic.json
- `mobile/pubspec.lock` — Resolved dependency tree (98 packages)
- `mobile/analysis_options.yaml` — invalid_annotation_target: ignore (required for freezed)
- `mobile/build.yaml` — explicit_to_json: true (required for nested model serialization)
- `mobile/assets/classic.json` — 42-territory map data copied from risk/data/classic.json
- `mobile/lib/main.dart` — ProviderScope + runApp(RiskApp())
- `mobile/lib/app.dart` — MaterialApp with Colors.red theme seed
- `mobile/lib/screens/home_screen.dart` — Placeholder "Risk Mobile — Coming Soon"
- `mobile/test/engine/map_graph_test.dart` — 8 test cases with embedded classic.json fixture
- `mobile/test/engine/models_test.dart` — TerritoryState copyWith, PlayerState equality, GameState JSON round-trip
- `mobile/test/persistence/save_slot_test.dart` — SaveSlot field existence check (@Skip for ObjectBox native)

## Decisions Made

- **riverpod_generator: ^4.0.3** — project STACK.md listed 2.6.0 which is incompatible with Riverpod 3.x
- **objectbox_flutter_libs: any** — project STACK.md listed `path: flutter_libs` which is the old approach; current pub.dev package handles native libs automatically
- **classic.json copied, not symlinked** — symlinks unreliable on Windows build machines
- **Map<String, List<Card>> for cards field** — JSON map keys must be strings; avoids custom converter

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Downloaded and installed Flutter SDK 3.41.4**
- **Found during:** Task 1 (flutter create)
- **Issue:** Flutter was not installed on the machine; `flutter` command not found
- **Fix:** Downloaded flutter_linux_3.41.4-stable.tar.xz from storage.googleapis.com and extracted to /home/amiller/flutter-sdk/
- **Files modified:** None in repo
- **Verification:** `flutter --version` shows Flutter 3.41.4, Dart 3.11.1
- **Committed in:** Not committed (SDK is outside the repo)

---

**Total deviations:** 1 auto-fixed (1 blocking — Flutter SDK installation)
**Impact on plan:** Necessary environment setup; no scope creep.

## Issues Encountered

- Flutter SDK not installed at plan start — downloaded 1.4GB tarball, extracted, verified working before proceeding (adds ~6 minutes to timeline)
- `dart test` (not `flutter test`) fails with `dart:ui` not available — expected behavior; tests use flutter_test package which requires the Flutter runner. Users must run `flutter test test/engine/` not `dart test test/engine/`

## User Setup Required

None - no external service configuration required. Flutter SDK was installed locally at `/home/amiller/flutter-sdk/flutter`.

To use Flutter commands, add to PATH:
```bash
export PATH="/home/amiller/flutter-sdk/flutter/bin:$PATH"
```

## Next Phase Readiness

- Plan 02 can proceed immediately: pubspec.yaml has all code-gen deps; build.yaml and analysis_options.yaml are correct; test stubs define the exact interface contracts needed
- Plan 03 can proceed in parallel with Plan 02: SaveSlot test stub written with @Skip
- Flutter SDK at `/home/amiller/flutter-sdk/flutter` — not in system PATH; add to .bashrc for convenience

---
*Phase: 06-flutter-scaffold-and-data-models*
*Completed: 2026-03-15*
