# Risk - Mobile Strategy Game

A single-player Risk board game for Android and iOS, built with Flutter. Features three AI difficulty levels, an interactive polygon-based map, and an AI-vs-AI simulation mode. Runs entirely on-device with no backend required.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.41.0+ (includes Dart 3.7.0+)
- Android SDK or Xcode (for iOS)
- An emulator or physical device

## Getting Started

```bash
cd mobile

# Install dependencies
flutter pub get

# Run code generation (freezed models, riverpod providers, objectbox)
dart run build_runner build --delete-conflicting-outputs

# Launch on a connected device or emulator
flutter run
```

## Running Tests

```bash
cd mobile
flutter test
```

## Map Editor

A web-based tool for creating and editing territory polygons.

```bash
cd editor
python server.py
# Open http://localhost:8766
```

Requires Python 3.

## HUD Editor

A web-based visual editor for designing the game's HUD (Heads-Up Display). Build grid layouts with drag & drop, style elements, and use the integrated Claude chat to generate UI.

```bash
cd hud-editor

# Install dependencies (first time only)
npm install

# Start the editor
npm run dev
# Open http://localhost:3000

# Start the Claude chat proxy (separate terminal)
npm run proxy
```

Requires Node.js 18+. The Claude chat proxy requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed.

The editor outputs `.hud.json` layout files to the `hud/` directory. These are later converted to Flutter widgets by Claude CLI.

## Project Structure

```
mobile/          Flutter app (main project)
  lib/
    engine/      Game logic (turns, combat, cards, fortification)
    bots/        AI agents (easy, medium, hard)
    screens/     Home and game screens
    widgets/     Reusable UI components
    providers/   Riverpod state management
    persistence/ ObjectBox local storage
  assets/        Map data (JSON)
  test/          Unit and widget tests
editor/          Web-based map polygon editor
hud-editor/      Web-based HUD layout editor (React + TypeScript)
hud/             HUD layout files (.hud.json)
maps/            Source map data files
```
