# Risk Map Editor — Design Spec

## Overview

A standalone web-based map editor for creating Risk game maps. Users draw edges on a canvas (optionally over a reference image), and the editor automatically detects closed faces that become territories. The output is a JSON file that the Flutter game app consumes.

**Tech stack:** Pure HTML/JS/Canvas. No framework, no bundler. Separate project in `/editor`.

## Project Structure

```
editor/
  index.html          — Entry point
  style.css           — UI styles
  js/
    app.js            — Entry, event wiring
    canvas.js         — Render loop, zoom/pan, coordinate transforms
    graph.js          — Planar graph data structure (vertices, edges)
    tools.js          — Draw, Select, Pan, Territory tools
    snap.js           — Vertex + edge snapping
    faces.js          — Face detection (planar cycle finding)
    territories.js    — Territory/continent management
    history.js        — Undo/redo stack
    io.js             — Import/export JSON
```

## Data Model

The core data structure is a planar graph:

- **Vertices** — `Map<id, {x, y}>`. Shared between edges. All geometry points live here.
- **Edges** — `Map<id, [vertexId, ...]>`. Polylines as ordered lists of vertex references. Minimum 2 vertices (start + end), additional entries are waypoints. A coastline is one edge with many waypoints. In JSON: `"e0": ["v0", "v1", "v2"]` means a polyline v0→v1→v2.
- **Faces** — `Map<id, {edgeRefs[], territory?}>`. Automatically detected closed regions. `edgeRefs` are ordered edge references with direction (forward/reversed).
- **Territories** — `Map<name, {faceId, color, labelPos}>`. User-confirmed faces with metadata. Color is randomly assigned on creation, user-editable.
- **Continents** — `Map<name, {bonus, territories[]}>`. Groupings of territories with army bonus.
- **Adjacencies** — `Set<[t1, t2]>`. Auto-generated from shared edges, plus manual additions, minus manual removals.

## UI Layout

### Top Toolbar
- Tool buttons: Draw (D), Select (V), Pan (Space+drag), Territory (T)
- Undo (Ctrl+Z) / Redo (Ctrl+Y)
- Load / Save / Export buttons

### Canvas (center)
- Configurable size (default 1200x700)
- Optional background image at 50% opacity (adjustable)
- Grid overlay for alignment
- Renders: edges, vertices, face fills (semi-transparent), snap indicators
- Zoom via mouse wheel, pan via middle-click or Pan tool

### Right Panel
- **Background:** Image upload button + opacity slider (0-100%, default 50%)
- **Canvas:** Width/height inputs
- **Territories:** List of confirmed territories (click to select, edit name/color)
- **Continents:** List with bonus values, drag territories to assign
- **Adjacencies:** Auto-generated list with manual add/remove controls

### Status Bar (bottom)
- Canvas size, zoom level
- Element counts (vertices, edges, faces, territories)
- Active tool, snap status

## Tools

### Draw Tool (D)
- Left-click places vertices connected by edges
- Snaps to existing vertices (within 8px) and existing edges (splits edge, inserts new vertex)
- Closing a path: click on start vertex or double-click to end open path
- Escape cancels current drawing
- Each completed drawing operation is one undo step

### Select Tool (V)
- Click to select vertex or edge (proximity-based hit testing)
- Drag selected vertex to move it (all connected edges follow)
- Delete key removes selected element:
  - Vertex deletion: removes vertex and merges connected edges
  - Edge deletion: removes edge (affected territories may dissolve)
- Click on empty space to deselect

### Pan Tool (Space)
- Drag to pan canvas
- Mouse wheel to zoom (always available regardless of tool)
- Space can be held as modifier in any tool for temporary pan

### Territory Tool (T)
- Click inside a detected face to confirm it as territory
- Opens inline name input + color picker
- Color is randomly assigned initially
- Click existing territory to edit name/color
- Right-click territory to remove confirmation (reverts to unconfirmed face)

## Snapping

- **Vertex snap:** When cursor is within 8px of an existing vertex, snap to it. Visual indicator: highlighted circle.
- **Edge snap:** When cursor is within 8px of an existing edge segment, snap to nearest point on edge. Visual indicator: highlighted point on edge. On click: edge is split at snap point (new vertex inserted), then new edge starts from that vertex.
- Snap distance is in screen pixels (constant regardless of zoom level).

## Face Detection

Uses planar face finding algorithm:

1. For each vertex, sort outgoing edges by angle (counter-clockwise)
2. For each directed edge (u→v), the "next edge" is the clockwise-next edge from v (relative to direction v→u)
3. Follow next-edge pointers to find closed cycles = faces
4. The outer (unbounded) face is identified and excluded

Runs after every draw/edit operation. At typical map complexity (~200 edges) this is <1ms.

Detected but unconfirmed faces are shown with a subtle semi-transparent fill. Confirmed territories get their assigned color.

## Adjacency Rules

- **Auto-adjacent:** Two territories sharing at least one edge are automatically adjacent.
- **Manual add:** For overseas connections (e.g., Alaska-Kamchatka). Shown as dashed line between label positions.
- **Manual remove:** For impassable borders. Stored in `manualNonAdjacencies`.
- **Final adjacency set** = (auto-generated + manual additions) - manual removals.

## Undo/Redo

- Command pattern: each user action (add vertex, move vertex, delete edge, confirm territory, etc.) is a reversible command on a stack.
- Ctrl+Z undoes, Ctrl+Y redoes.
- Stack is unlimited (bounded by memory).
- Drawing a complete polyline (from first click to close/double-click) is one command.

## Export Formats

### Editor Save Format (`.risk.json`)

For re-importing into the editor. Contains full topology:

```json
{
  "name": "Map Name",
  "canvasSize": [1200, 700],
  "vertices": { "v0": [120.0, 30.5] },
  "edges": { "e0": ["v0", "v1", "v2"] },
  "territories": {
    "Alaska": {
      "edges": ["e0", "-e3", "e7"],
      "color": "#E53935",
      "labelPosition": [60, 85]
    }
  },
  "continents": {
    "North America": { "bonus": 5, "territories": ["Alaska"] }
  },
  "manualAdjacencies": [["Alaska", "Kamchatka"]],
  "manualNonAdjacencies": []
}
```

Edge references prefixed with `-` are traversed in reverse. Background image is not saved (local file reference only).

### Game Export Format (`.json`)

For the Flutter app. Resolves topology into simple point lists:

```json
{
  "name": "Map Name",
  "canvasSize": [1200, 700],
  "territories": {
    "Alaska": {
      "path": [[120, 30], [180, 45], [200, 80]],
      "color": "#E53935",
      "labelPosition": [160, 110]
    }
  },
  "continents": [
    { "name": "North America", "bonus": 5, "territories": ["Alaska"] }
  ],
  "adjacencies": [["Alaska", "Kamchatka"]]
}
```

Adjacencies are the final merged set (auto + manual - non-adj).

## Flutter App Changes Required

The game app needs these modifications to consume the new format:

| File | Change |
|------|--------|
| `territory_data.dart` | `Rect rect` → `List<Offset> points` in `TerritoryGeometry`. Build `Path` from points. |
| `map_base_painter.dart` | `canvas.drawPath()` instead of `canvas.drawRect()` |
| `map_overlay_painter.dart` | Same: Path-based fills and selection borders |
| `map_widget.dart` | Hit testing: `path.contains(point)` instead of `rect.contains()` |
| `map_provider.dart` | Load new JSON format, parse path data into `List<Offset>` |
| `classic.json` | Replaced by game export from editor |

The game engine (`map_graph.dart`) stays unchanged — it receives territory names + adjacency pairs regardless of format.

## Workflow

1. **Setup** — Set canvas size, load background image, adjust opacity
2. **Draw continents** — Trace continent outlines with Draw tool
3. **Subdivide** — Draw internal borders (snap to existing edges). Faces appear automatically.
4. **Confirm territories** — Territory tool: click each face, assign name + color
5. **Metadata** — Define continents (assign territories, set bonus), add manual adjacencies (overseas), remove non-adjacencies
6. **Export** — Save editor file (`.risk.json`) for future editing, export game file (`.json`) for Flutter app
