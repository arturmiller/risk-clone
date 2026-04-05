# HUD Editor — Design Spec

## Zusammenfassung

Ein webbasierter visueller Editor zum Erstellen und Anpassen des Game-HUD (Heads-Up Display) für das Risk-Spiel. Der Editor erzeugt JSON-Layoutdateien, die später von Claude CLI zu Flutter-Widgets mit Datenbindung umgewandelt werden.

## Ziele

- **Visuelles Grid-Editing** — HUD-Layout per Maus erstellen (Drag & Drop, Grid-Grenzen ziehen, Zellen teilen/mergen)
- **Claude-Chat im Editor** — UI-Elemente per Chat generieren und ändern lassen
- **Unabhängigkeit** — Editor ist eine eigenständige Web-App, unabhängig von Flutter
- **Beschreibungen für Claude CLI** — jedes Element hat ein Description-Feld, das Claude CLI später für die Datenbindung nutzt
- **Zwei Layouts** — Mobile Portrait und Desktop Landscape

## Architektur

### Tech-Stack

- **React + TypeScript** mit Vite als Build-Tool
- **CSS Grid** als Layout-Engine (spiegelt das rekursive Grid-Konzept direkt wider)
- **Zustand** für State Management
- **dnd-kit** für Drag & Drop
- **Node.js/Express** als lokaler Claude-Proxy

### Editor-Layout

Der Editor hat vier Bereiche:

1. **Element Library (links)** — Drag-Source für alle Element-Typen + Layout-Switcher (Mobile/Desktop)
2. **Canvas (mitte)** — Visueller Grid-Editor mit Phone/Desktop-Frame, WYSIWYG-Vorschau
3. **Properties Panel (rechts)** — Eigenschaften des selektierten Elements editieren + Element-Baum
4. **Chat Panel (unten)** — Claude-Chat für Layout-Generierung/-Änderung

### Dateistruktur

```
risk/
├── hud-editor/                 ← Neues Projekt
│   ├── src/                    ← React App
│   │   ├── components/
│   │   ├── store/              ← Zustand State
│   │   └── App.tsx
│   ├── server/                 ← Claude Proxy
│   │   └── proxy.ts
│   ├── package.json
│   └── vite.config.ts
├── hud/                        ← Output-Dateien
│   ├── mobile-portrait.hud.json
│   └── desktop-landscape.hud.json
└── mobile/
    └── lib/widgets/hud/        ← Von Claude CLI generiert (Phase 4)
        ├── mobile_hud.dart
        └── desktop_hud.dart
```

## JSON-Format

Das Herzstück des Editors. Wird sowohl vom Editor als auch von Claude CLI gelesen/geschrieben.

### Struktur

```json
{
  "name": "mobile-portrait",
  "canvasSize": [390, 844],
  "root": {
    "type": "grid",
    "id": "root",
    "rows": ["40px", "1fr", "auto"],
    "cols": ["1fr"],
    "children": [...]
  },
  "theme": {
    "background": "rgba(62,39,12,0.9)",
    "border": "rgba(255,193,7,0.3)",
    "text": "#FFB300",
    "borderRadius": 10
  }
}
```

### Kern-Konzepte

- **Rekursiver Baum** — jedes Element ist entweder ein `grid` (Container mit rows/cols/children) oder ein Leaf-Element
- **CSS Grid Semantik** — `rows` und `cols` nutzen CSS Grid Syntax: `"40px"`, `"1fr"`, `"auto"`
- **Kinder-Positionierung** — children referenzieren ihre Position via `row`/`col`
- **Beschreibung** — jedes Element hat ein optionales `description`-Feld für Claude CLI
- **Stabile IDs** — jedes Element hat eine eindeutige `id`
- **Theme** — globales Objekt für Default-Styles (Farben, Border, Radius)

### Element-Typen

| Typ | Beschreibung |
|-----|-------------|
| `grid` | Container mit rows/cols/children (rekursiv verschachtelbar) |
| `label` | Text-Anzeige (statisch oder mit Platzhalter-Text) |
| `button` | Klickbarer Button mit Text |
| `slider` | Wertebereich-Auswahl (min/max) |
| `icon` | Einzelnes Icon (Material Icons Name) |
| `list` | Scrollbare Liste (Log, Einträge) |
| `cardhand` | Kartenhand-Anzeige mit Selektion |
| `container` | Dekorativer Rahmen (Background/Border) |
| `spacer` | Leerer Platzhalter |

### Element-Properties

Jedes Element hat:
- `type` — Element-Typ (siehe oben)
- `id` — eindeutige ID
- `description` — optionale Beschreibung für Claude CLI (was das Element tun soll)
- `style` — optionales Objekt für individuelle Styles (fontSize, color, background, etc.)
- `row`/`col` — Position im Eltern-Grid

Typ-spezifische Properties:
- `label`: `text`
- `button`: `text`
- `slider`: `min`, `max`, `step`
- `icon`: `name` (Material Icon Name)
- `list`: `maxItems`
- `grid`: `rows`, `cols`, `children`

## Grid-Editing Interaktionen

### 1. Zelle teilen (Split)
- Rechtsklick auf Zelle → "Split horizontal/vertikal"
- Oder Doppelklick auf Zellenrand
- Teilt eine Zelle in zwei gleich große Hälften

### 2. Grenzen verschieben (Resize)
- Hover über Grid-Grenze → Cursor ändert sich (col-resize / row-resize)
- Drag zum Verschieben der Proportion
- Snap an Raster optional

### 3. Element platzieren (Drag & Drop)
- Aus Element Library in eine Grid-Zelle ziehen
- Oder zwischen Zellen verschieben
- Drop-Zone leuchtet blau auf bei Hover
- Leere Zellen sind gültige Drop-Targets

### 4. Zellen zusammenführen (Merge)
- Rechtsklick → "Merge" auf benachbarte leere Zellen
- Oder Grenze zwischen leeren Zellen löschen

### 5. Kontextmenü
- Rechtsklick auf Element: Umbenennen, Duplizieren, In Grid umwandeln, Split H/V, Löschen

### Keyboard Shortcuts
| Shortcut | Aktion |
|----------|--------|
| `Delete` | Element löschen |
| `Ctrl+D` | Duplizieren |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |
| `Ctrl+S` | Speichern |
| `Escape` | Auswahl aufheben |

## Claude Chat Proxy

### Architektur

```
Editor (Browser) → HTTP POST /api/chat → Local Proxy (Node.js, Port 3001)
                                          → claude --print (Subprocess)
                                          → liest/schreibt layout.hud.json
```

### Nachrichtenfluss

1. User tippt im Editor-Chat eine Anweisung
2. Editor sendet an Proxy: User-Message + aktuelles JSON
3. Proxy ruft `claude --print` auf mit System-Prompt + JSON + User-Message
4. Claude antwortet mit modifiziertem JSON + Erklärung
5. Proxy schreibt JSON auf Disk, sendet Response an Editor
6. Editor aktualisiert Canvas mit neuem Layout + zeigt Antwort im Chat

### System-Prompt für Claude

Claude bekommt einen System-Prompt der erklärt:
- Das JSON-Format und alle Element-Typen
- Regeln: bestehende IDs beibehalten, neue eindeutige IDs vergeben, beschreibende Descriptions nutzen, Grid-Struktur valide halten
- Antwortformat: `---message---` Erklärung + `---json---` modifiziertes JSON

### Vorteile von claude --print
- Kein API-Key im Browser nötig
- Nutzt bestehende Claude CLI Authentifizierung
- Kein CORS-Problem
- User behält Kontrolle über Kosten

### Einschränkungen
- Kein Streaming (wartet auf volle Antwort)
- Claude CLI muss installiert sein

## Gesamtworkflow

### Phase 1: Layout bauen im Editor
Grid-Struktur mit der Maus aufbauen. Elemente aus Library per Drag & Drop platzieren. Grenzen ziehen, Zellen teilen, Proportionen anpassen.
→ `hud/mobile-portrait.hud.json`

### Phase 2: Verfeinern mit Editor-Chat
Im Editor-Chat Claude bitten Elemente zu erstellen/ändern. Claude modifiziert das JSON, der Canvas aktualisiert sich.
→ `hud/mobile-portrait.hud.json` (verfeinert, mit Beschreibungen)

### Phase 3: Desktop Layout erstellen
Im Editor auf "Desktop Landscape" wechseln. Zweites Layout bauen mit anderer Grid-Struktur.
→ `hud/desktop-landscape.hud.json`

### Phase 4: Datenbindung mit Claude CLI
Außerhalb des Editors. Claude CLI liest die .hud.json-Dateien, versteht die Beschreibungen, und generiert Flutter-Widgets mit Riverpod-Bindings.
→ `mobile/lib/widgets/hud/mobile_hud.dart`, `desktop_hud.dart`

## Abgrenzung

### Der Editor macht:
- Grid-Layout visuell bauen
- Elemente platzieren und stylen
- Beschreibungen für Claude verfassen
- Zwischen Mobile/Desktop Layout wechseln
- JSON exportieren
- Claude-Chat für Layout-Generierung

### Der Editor macht NICHT:
- Datenbindung an Game State
- Flutter-Code generieren
- Aktionslogik programmieren
- Spiel simulieren/testen
