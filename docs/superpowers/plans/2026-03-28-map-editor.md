# Risk Map Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone web-based map editor where users draw edges on a canvas to create Risk game maps with automatic face detection, territory confirmation, and JSON export.

**Architecture:** Pure HTML/JS/Canvas app in `/editor`. A planar graph data model (vertices, edges) feeds a face-detection algorithm that finds closed regions. Users confirm faces as territories, group them into continents, and export to JSON for the Flutter game app.

**Tech Stack:** Vanilla HTML/CSS/JS, HTML5 Canvas API, ES modules (no bundler)

---

## File Structure

```
editor/
  index.html              — Entry point, loads CSS + JS modules
  style.css               — All UI styles (toolbar, panel, canvas, status bar)
  js/
    app.js                — Entry module: wires DOM events, creates instances, runs render loop
    graph.js              — PlanarGraph class: vertices, edges, add/remove/split operations
    faces.js              — findFaces(graph): planar face detection algorithm
    snap.js               — findSnap(graph, point, threshold): vertex + edge snap logic
    tools/
      draw-tool.js        — DrawTool class: click-to-place polyline drawing
      select-tool.js      — SelectTool class: select, drag, delete vertices/edges
      pan-tool.js         — PanTool class: drag-to-pan, space modifier
      territory-tool.js   — TerritoryTool class: click face to confirm territory
    renderer.js           — Renders graph, faces, background, snap indicators to canvas
    history.js            — UndoStack class: command pattern with undo/redo
    territories.js        — TerritoryManager class: territories, continents, adjacencies
    io.js                 — save/load (.risk.json), export (game .json)
    ui-panel.js           — Right panel DOM updates: territory list, continent list, controls
```

---

### Task 1: HTML Shell + Canvas with Pan/Zoom

**Files:**
- Create: `editor/index.html`
- Create: `editor/style.css`
- Create: `editor/js/app.js`
- Create: `editor/js/renderer.js`
- Create: `editor/js/tools/pan-tool.js`

- [ ] **Step 1: Create index.html with layout structure**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Risk Map Editor</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div id="toolbar">
    <span class="brand">Risk Map Editor</span>
    <div class="tool-group">
      <button class="tool-btn" data-tool="draw" title="Draw (D)">&#9999; Draw</button>
      <button class="tool-btn" data-tool="select" title="Select (V)">&#8598; Select</button>
      <button class="tool-btn active" data-tool="pan" title="Pan (Space)">&#9995; Pan</button>
      <button class="tool-btn" data-tool="territory" title="Territory (T)">&#127912; Territory</button>
    </div>
    <div class="tool-group right">
      <button id="btn-undo" title="Undo (Ctrl+Z)">&#8617; Undo</button>
      <button id="btn-redo" title="Redo (Ctrl+Y)">&#8618; Redo</button>
    </div>
    <div class="tool-group right">
      <button id="btn-load">&#128194; Load</button>
      <button id="btn-save">&#128190; Save</button>
      <button id="btn-export">&#128228; Export</button>
    </div>
  </div>

  <div id="main">
    <div id="canvas-container">
      <canvas id="editor-canvas"></canvas>
    </div>
    <div id="panel">
      <section id="panel-background">
        <h3>Background</h3>
        <button id="btn-load-image">Load Image...</button>
        <div class="slider-row">
          <label>Opacity</label>
          <input type="range" id="bg-opacity" min="0" max="100" value="50">
          <span id="bg-opacity-val">50%</span>
        </div>
      </section>
      <section id="panel-canvas">
        <h3>Canvas</h3>
        <div class="input-row">
          <label>Width</label>
          <input type="number" id="canvas-width" value="1200" min="100" max="4000">
        </div>
        <div class="input-row">
          <label>Height</label>
          <input type="number" id="canvas-height" value="700" min="100" max="4000">
        </div>
      </section>
      <section id="panel-territories">
        <h3>Territories</h3>
        <div id="territory-list"></div>
      </section>
      <section id="panel-continents">
        <h3>Continents</h3>
        <div id="continent-list"></div>
        <button id="btn-add-continent">+ Add Continent</button>
      </section>
      <section id="panel-adjacencies">
        <h3>Adjacencies</h3>
        <div id="adjacency-list"></div>
        <button id="btn-add-adjacency">+ Add Adjacency</button>
      </section>
    </div>
  </div>

  <div id="statusbar">
    <span id="status-canvas">Canvas: 1200 × 700</span>
    <span id="status-counts">V: 0 | E: 0 | F: 0 | T: 0</span>
    <span id="status-tool">Tool: Pan | Snap: ON</span>
  </div>

  <input type="file" id="file-image" accept="image/*" style="display:none">
  <input type="file" id="file-load" accept=".risk.json" style="display:none">

  <script type="module" src="js/app.js"></script>
</body>
</html>
```

- [ ] **Step 2: Create style.css**

```css
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: #1a1a2e;
  color: #ccc;
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
}

/* Toolbar */
#toolbar {
  background: #16213e;
  padding: 6px 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  border-bottom: 1px solid #333;
  flex-shrink: 0;
}
.brand { color: #e94560; font-weight: bold; font-size: 14px; }
.tool-group { display: flex; gap: 4px; }
.tool-group.right { margin-left: auto; }
.tool-group.right + .tool-group.right { margin-left: 8px; }

#toolbar button, .tool-btn {
  background: #0f3460;
  color: #999;
  border: 2px solid transparent;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
}
#toolbar button:hover, .tool-btn:hover { color: #ccc; }
.tool-btn.active { border-color: #e94560; color: #e94560; }

/* Main area */
#main {
  display: flex;
  flex: 1;
  overflow: hidden;
}

#canvas-container {
  flex: 1;
  position: relative;
  overflow: hidden;
  cursor: grab;
}
#canvas-container.drawing { cursor: crosshair; }
#canvas-container.selecting { cursor: default; }

#editor-canvas {
  position: absolute;
  top: 0;
  left: 0;
}

/* Right panel */
#panel {
  width: 240px;
  background: #16213e;
  border-left: 1px solid #333;
  overflow-y: auto;
  flex-shrink: 0;
}
#panel section {
  padding: 12px;
  border-bottom: 1px solid #222;
}
#panel h3 {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: #888;
  margin-bottom: 8px;
}
#panel button {
  background: #0f3460;
  color: #ccc;
  border: none;
  padding: 6px 10px;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  width: 100%;
}
#panel button:hover { background: #1a4a8a; }

.slider-row, .input-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
}
.slider-row label, .input-row label {
  font-size: 11px;
  color: #888;
  min-width: 50px;
}
.slider-row input[type="range"] { flex: 1; }
.slider-row span { font-size: 11px; min-width: 30px; }
.input-row input[type="number"] {
  background: #0f3460;
  border: 1px solid #333;
  color: #ccc;
  padding: 3px 6px;
  border-radius: 3px;
  width: 70px;
  font-size: 12px;
}

/* Status bar */
#statusbar {
  background: #16213e;
  padding: 4px 12px;
  font-size: 11px;
  color: #888;
  display: flex;
  justify-content: space-between;
  border-top: 1px solid #333;
  flex-shrink: 0;
}

/* Territory list items */
.territory-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 6px;
  border-radius: 3px;
  font-size: 12px;
  cursor: pointer;
}
.territory-item:hover { background: #0f3460; }
.territory-item .color-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}
.territory-item .name { flex: 1; }

/* Continent items */
.continent-item {
  padding: 6px;
  margin-bottom: 4px;
  background: #0f3460;
  border-radius: 4px;
  font-size: 12px;
}
.continent-item .header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}
.continent-item input {
  background: transparent;
  border: none;
  color: #ccc;
  font-size: 12px;
  width: 100px;
}
.continent-item .bonus-input {
  width: 30px;
  text-align: center;
  background: #16213e;
  border: 1px solid #333;
  border-radius: 3px;
  color: #ccc;
  padding: 2px;
}
.continent-item .territories {
  font-size: 10px;
  color: #666;
}
```

- [ ] **Step 3: Create renderer.js with pan/zoom transform**

```js
// editor/js/renderer.js
export class Renderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.mapWidth = 1200;
    this.mapHeight = 700;
    this.offsetX = 0;
    this.offsetY = 0;
    this.zoom = 1;
    this.bgImage = null;
    this.bgOpacity = 0.5;
    this._resizeCanvas();
    this._resizeObserver = new ResizeObserver(() => this._resizeCanvas());
    this._resizeObserver.observe(canvas.parentElement);
  }

  _resizeCanvas() {
    const container = this.canvas.parentElement;
    this.canvas.width = container.clientWidth;
    this.canvas.height = container.clientHeight;
  }

  setMapSize(w, h) {
    this.mapWidth = w;
    this.mapHeight = h;
  }

  setBackgroundImage(img) {
    this.bgImage = img;
  }

  setBackgroundOpacity(opacity) {
    this.bgOpacity = opacity;
  }

  /** Convert screen coordinates to map coordinates */
  screenToMap(sx, sy) {
    return {
      x: (sx - this.offsetX) / this.zoom,
      y: (sy - this.offsetY) / this.zoom,
    };
  }

  /** Convert map coordinates to screen coordinates */
  mapToScreen(mx, my) {
    return {
      x: mx * this.zoom + this.offsetX,
      y: my * this.zoom + this.offsetY,
    };
  }

  /** Zoom centered on a screen point */
  zoomAt(sx, sy, delta) {
    const oldZoom = this.zoom;
    this.zoom = Math.max(0.1, Math.min(10, this.zoom * (1 - delta * 0.001)));
    const ratio = this.zoom / oldZoom;
    this.offsetX = sx - (sx - this.offsetX) * ratio;
    this.offsetY = sy - (sy - this.offsetY) * ratio;
  }

  pan(dx, dy) {
    this.offsetX += dx;
    this.offsetY += dy;
  }

  /** Fit map in canvas with padding */
  fitToView() {
    const container = this.canvas.parentElement;
    const pad = 40;
    const scaleX = (container.clientWidth - pad * 2) / this.mapWidth;
    const scaleY = (container.clientHeight - pad * 2) / this.mapHeight;
    this.zoom = Math.min(scaleX, scaleY);
    this.offsetX = (container.clientWidth - this.mapWidth * this.zoom) / 2;
    this.offsetY = (container.clientHeight - this.mapHeight * this.zoom) / 2;
  }

  render(graph, faces, territories, snap, activeTool) {
    const ctx = this.ctx;
    const w = this.canvas.width;
    const h = this.canvas.height;

    ctx.clearRect(0, 0, w, h);
    ctx.save();
    ctx.translate(this.offsetX, this.offsetY);
    ctx.scale(this.zoom, this.zoom);

    // Map boundary
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 1 / this.zoom;
    ctx.strokeRect(0, 0, this.mapWidth, this.mapHeight);

    // Background image
    if (this.bgImage) {
      ctx.globalAlpha = this.bgOpacity;
      ctx.drawImage(this.bgImage, 0, 0, this.mapWidth, this.mapHeight);
      ctx.globalAlpha = 1;
    }

    // Face fills
    if (faces) {
      for (const face of faces) {
        if (face.outer) continue;
        const territory = territories?.getByFaceId(face.id);
        ctx.beginPath();
        const pts = face.points;
        if (pts.length < 3) continue;
        ctx.moveTo(pts[0].x, pts[0].y);
        for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i].x, pts[i].y);
        ctx.closePath();
        if (territory) {
          ctx.fillStyle = territory.color + '66'; // 40% alpha
        } else {
          ctx.fillStyle = 'rgba(255,255,255,0.08)';
        }
        ctx.fill();
      }
    }

    // Edges
    for (const [, edge] of graph.edges) {
      const verts = edge.vertices.map(vid => graph.vertices.get(vid));
      if (verts.some(v => !v)) continue;
      ctx.beginPath();
      ctx.moveTo(verts[0].x, verts[0].y);
      for (let i = 1; i < verts.length; i++) ctx.lineTo(verts[i].x, verts[i].y);
      ctx.strokeStyle = '#e94560';
      ctx.lineWidth = 2 / this.zoom;
      ctx.stroke();
    }

    // Vertices
    const vertexRadius = 4 / this.zoom;
    for (const [, v] of graph.vertices) {
      ctx.beginPath();
      ctx.arc(v.x, v.y, vertexRadius, 0, Math.PI * 2);
      ctx.fillStyle = '#fff';
      ctx.fill();
      ctx.strokeStyle = '#e94560';
      ctx.lineWidth = 2 / this.zoom;
      ctx.stroke();
    }

    // Snap indicator
    if (snap) {
      ctx.beginPath();
      ctx.arc(snap.x, snap.y, 10 / this.zoom, 0, Math.PI * 2);
      ctx.strokeStyle = '#ff9800';
      ctx.lineWidth = 1.5 / this.zoom;
      ctx.setLineDash([4 / this.zoom, 4 / this.zoom]);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // Territory labels
    if (territories) {
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const fontSize = 11 / this.zoom;
      ctx.font = `bold ${fontSize}px sans-serif`;
      for (const [name, t] of territories.territories) {
        ctx.fillStyle = '#fff';
        ctx.fillText(name, t.labelPosition.x, t.labelPosition.y);
      }
    }

    ctx.restore();
  }
}
```

- [ ] **Step 4: Create pan-tool.js**

```js
// editor/js/tools/pan-tool.js
export class PanTool {
  constructor(renderer) {
    this.renderer = renderer;
    this.dragging = false;
    this.lastX = 0;
    this.lastY = 0;
  }

  get name() { return 'pan'; }
  get cursor() { return this.dragging ? 'grabbing' : 'grab'; }

  onMouseDown(e) {
    this.dragging = true;
    this.lastX = e.clientX;
    this.lastY = e.clientY;
  }

  onMouseMove(e) {
    if (!this.dragging) return;
    const dx = e.clientX - this.lastX;
    const dy = e.clientY - this.lastY;
    this.renderer.pan(dx, dy);
    this.lastX = e.clientX;
    this.lastY = e.clientY;
  }

  onMouseUp() {
    this.dragging = false;
  }

  onKeyDown() {}
  onKeyUp() {}
}
```

- [ ] **Step 5: Create app.js — wire up canvas, pan tool, render loop**

```js
// editor/js/app.js
import { Renderer } from './renderer.js';
import { PanTool } from './tools/pan-tool.js';

const canvas = document.getElementById('editor-canvas');
const container = document.getElementById('canvas-container');
const renderer = new Renderer(canvas);

// Minimal graph stub for initial render
const graph = { vertices: new Map(), edges: new Map() };

let activeTool = new PanTool(renderer);
let snap = null;

// Tool switching
function setTool(tool) {
  activeTool = tool;
  document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`[data-tool="${tool.name}"]`)?.classList.add('active');
  updateStatus();
}

// Canvas events
canvas.addEventListener('mousedown', e => activeTool.onMouseDown(e));
canvas.addEventListener('mousemove', e => activeTool.onMouseMove(e));
canvas.addEventListener('mouseup', e => activeTool.onMouseUp(e));
canvas.addEventListener('wheel', e => {
  e.preventDefault();
  const rect = canvas.getBoundingClientRect();
  renderer.zoomAt(e.clientX - rect.left, e.clientY - rect.top, e.deltaY);
}, { passive: false });

// Keyboard shortcuts
document.addEventListener('keydown', e => {
  if (e.key === 'd' && !e.ctrlKey) setTool(new PanTool(renderer)); // placeholder
  activeTool.onKeyDown(e);
});

// Canvas size inputs
document.getElementById('canvas-width').addEventListener('change', e => {
  renderer.setMapSize(parseInt(e.target.value) || 1200, renderer.mapHeight);
  updateStatus();
});
document.getElementById('canvas-height').addEventListener('change', e => {
  renderer.setMapSize(renderer.mapWidth, parseInt(e.target.value) || 700);
  updateStatus();
});

// Background image
document.getElementById('btn-load-image').addEventListener('click', () => {
  document.getElementById('file-image').click();
});
document.getElementById('file-image').addEventListener('change', e => {
  const file = e.target.files[0];
  if (!file) return;
  const img = new Image();
  img.onload = () => renderer.setBackgroundImage(img);
  img.src = URL.createObjectURL(file);
});
document.getElementById('bg-opacity').addEventListener('input', e => {
  const val = parseInt(e.target.value);
  renderer.setBackgroundOpacity(val / 100);
  document.getElementById('bg-opacity-val').textContent = val + '%';
});

// Status bar
function updateStatus() {
  document.getElementById('status-canvas').textContent =
    `Canvas: ${renderer.mapWidth} × ${renderer.mapHeight} | Zoom: ${Math.round(renderer.zoom * 100)}%`;
  document.getElementById('status-counts').textContent =
    `V: ${graph.vertices.size} | E: ${graph.edges.size} | F: 0 | T: 0`;
  document.getElementById('status-tool').textContent =
    `Tool: ${activeTool.name} | Snap: ON`;
}

// Render loop
function frame() {
  renderer.render(graph, null, null, snap, activeTool);
  updateStatus();
  requestAnimationFrame(frame);
}

renderer.fitToView();
requestAnimationFrame(frame);
```

- [ ] **Step 6: Open in browser, verify pan/zoom works**

Open `editor/index.html` in a browser. Verify:
- Dark UI with toolbar, canvas area, right panel, status bar
- Mouse wheel zooms in/out
- Drag to pan the canvas
- Map boundary rectangle is visible and moves with pan/zoom
- Background image can be loaded via panel button
- Opacity slider adjusts image transparency
- Canvas size inputs update the map boundary

- [ ] **Step 7: Commit**

```bash
git add editor/
git commit -m "feat(editor): scaffold HTML shell with canvas pan/zoom and background image"
```

---

### Task 2: Planar Graph Data Structure

**Files:**
- Create: `editor/js/graph.js`

- [ ] **Step 1: Implement PlanarGraph class**

```js
// editor/js/graph.js
let nextVertexId = 0;
let nextEdgeId = 0;

export class PlanarGraph {
  constructor() {
    /** @type {Map<string, {x: number, y: number}>} */
    this.vertices = new Map();
    /** @type {Map<string, {vertices: string[]}>} */
    this.edges = new Map();
  }

  addVertex(x, y) {
    const id = 'v' + (nextVertexId++);
    this.vertices.set(id, { x, y });
    return id;
  }

  removeVertex(id) {
    // Find and remove all edges that reference this vertex
    const toRemove = [];
    for (const [eid, edge] of this.edges) {
      if (edge.vertices.includes(id)) toRemove.push(eid);
    }
    for (const eid of toRemove) this.edges.delete(eid);
    this.vertices.delete(id);
    return toRemove; // return removed edge ids for undo
  }

  moveVertex(id, x, y) {
    const v = this.vertices.get(id);
    if (v) { v.x = x; v.y = y; }
  }

  addEdge(vertexIds) {
    if (vertexIds.length < 2) return null;
    // Verify all vertices exist
    for (const vid of vertexIds) {
      if (!this.vertices.has(vid)) return null;
    }
    const id = 'e' + (nextEdgeId++);
    this.edges.set(id, { vertices: [...vertexIds] });
    return id;
  }

  removeEdge(id) {
    const edge = this.edges.get(id);
    this.edges.delete(id);
    return edge; // return for undo
  }

  /**
   * Split an edge at a point, inserting a new vertex.
   * The edge e with vertices [v0, v1, ..., vN] gets split at segment index segIdx.
   * Returns { vertexId, newEdgeIds: [id1, id2] }.
   */
  splitEdge(edgeId, segmentIndex, x, y) {
    const edge = this.edges.get(edgeId);
    if (!edge) return null;

    const vid = this.addVertex(x, y);
    const verts = edge.vertices;

    // Split into two edges at the segment
    const leftVerts = verts.slice(0, segmentIndex + 1).concat(vid);
    const rightVerts = [vid].concat(verts.slice(segmentIndex + 1));

    this.edges.delete(edgeId);
    const eid1 = this.addEdge(leftVerts);
    const eid2 = this.addEdge(rightVerts);

    return { vertexId: vid, newEdgeIds: [eid1, eid2], oldEdge: edge };
  }

  /**
   * Get all edges connected to a vertex (as start, end, or waypoint).
   */
  edgesOf(vertexId) {
    const result = [];
    for (const [eid, edge] of this.edges) {
      if (edge.vertices.includes(vertexId)) result.push(eid);
    }
    return result;
  }

  /**
   * Get the "neighbor" vertex ids reachable from a vertex via edges.
   * For face detection, we care about the first/last vertices of edges.
   */
  adjacentEndpoints(vertexId) {
    const neighbors = [];
    for (const [eid, edge] of this.edges) {
      const verts = edge.vertices;
      const first = verts[0];
      const last = verts[verts.length - 1];
      if (first === vertexId) neighbors.push({ edgeId: eid, to: last, forward: true });
      if (last === vertexId) neighbors.push({ edgeId: eid, to: first, forward: false });
    }
    return neighbors;
  }

  /** Deep clone for undo snapshots */
  clone() {
    const g = new PlanarGraph();
    for (const [id, v] of this.vertices) g.vertices.set(id, { ...v });
    for (const [id, e] of this.edges) g.edges.set(id, { vertices: [...e.vertices] });
    return g;
  }

  /** Reset ID counters (for load) */
  static resetIds(vMax, eMax) {
    nextVertexId = vMax;
    nextEdgeId = eMax;
  }
}
```

- [ ] **Step 2: Verify in browser console**

Open browser console on `editor/index.html` and test:
```js
import('./js/graph.js').then(m => {
  const g = new m.PlanarGraph();
  const v0 = g.addVertex(0, 0);
  const v1 = g.addVertex(100, 0);
  const v2 = g.addVertex(100, 100);
  g.addEdge([v0, v1]);
  g.addEdge([v1, v2]);
  console.log('vertices:', g.vertices.size, 'edges:', g.edges.size);
  console.log('adjacent to v1:', g.adjacentEndpoints(v1));
});
```
Expected: `vertices: 3 edges: 2`, adjacentEndpoints returns v0 and v2.

- [ ] **Step 3: Commit**

```bash
git add editor/js/graph.js
git commit -m "feat(editor): add PlanarGraph data structure with vertex/edge CRUD and split"
```

---

### Task 3: Snap System

**Files:**
- Create: `editor/js/snap.js`

- [ ] **Step 1: Implement snap logic**

```js
// editor/js/snap.js

/**
 * Find the closest snap target within threshold (screen pixels).
 * Returns { type: 'vertex'|'edge', x, y, vertexId?, edgeId?, segmentIndex? } or null.
 */
export function findSnap(graph, mapPoint, threshold, renderer) {
  // Threshold in map coordinates
  const mapThreshold = threshold / renderer.zoom;

  let bestDist = mapThreshold;
  let best = null;

  // Check vertices first (higher priority)
  for (const [vid, v] of graph.vertices) {
    const d = Math.hypot(v.x - mapPoint.x, v.y - mapPoint.y);
    if (d < bestDist) {
      bestDist = d;
      best = { type: 'vertex', x: v.x, y: v.y, vertexId: vid };
    }
  }

  // If we found a vertex snap, prefer it
  if (best) return best;

  // Check edge segments
  for (const [eid, edge] of graph.edges) {
    const verts = edge.vertices;
    for (let i = 0; i < verts.length - 1; i++) {
      const a = graph.vertices.get(verts[i]);
      const b = graph.vertices.get(verts[i + 1]);
      if (!a || !b) continue;

      const closest = closestPointOnSegment(mapPoint, a, b);
      const d = Math.hypot(closest.x - mapPoint.x, closest.y - mapPoint.y);
      if (d < bestDist) {
        bestDist = d;
        best = {
          type: 'edge',
          x: closest.x,
          y: closest.y,
          edgeId: eid,
          segmentIndex: i,
        };
      }
    }
  }

  return best;
}

function closestPointOnSegment(p, a, b) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lenSq = dx * dx + dy * dy;
  if (lenSq === 0) return { x: a.x, y: a.y };
  let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));
  return { x: a.x + t * dx, y: a.y + t * dy };
}

/**
 * Check if a point is inside a polygon (for face/territory clicking).
 */
export function pointInPolygon(point, polygon) {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].x, yi = polygon[i].y;
    const xj = polygon[j].x, yj = polygon[j].y;
    if (((yi > point.y) !== (yj > point.y)) &&
        (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}
```

- [ ] **Step 2: Commit**

```bash
git add editor/js/snap.js
git commit -m "feat(editor): add snap system with vertex/edge snapping and point-in-polygon"
```

---

### Task 4: Draw Tool

**Files:**
- Create: `editor/js/tools/draw-tool.js`
- Modify: `editor/js/app.js`

- [ ] **Step 1: Implement DrawTool**

```js
// editor/js/tools/draw-tool.js
import { findSnap } from '../snap.js';

export class DrawTool {
  constructor(renderer, graph, onComplete) {
    this.renderer = renderer;
    this.graph = graph;
    this.onComplete = onComplete; // callback after finishing a polyline
    this.currentVertices = []; // vertex IDs placed so far
    this.previewPoint = null;  // current mouse position in map coords
    this.snapResult = null;
  }

  get name() { return 'draw'; }
  get cursor() { return 'crosshair'; }

  onMouseDown(e) {
    if (e.button !== 0) return;
    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);

    let vid;
    const snap = findSnap(this.graph, mapPt, 8, this.renderer);

    if (snap?.type === 'vertex') {
      vid = snap.vertexId;

      // If clicking the start vertex and we have 2+ vertices, close the polygon
      if (this.currentVertices.length >= 2 && vid === this.currentVertices[0]) {
        this.currentVertices.push(vid);
        this._finishPolyline();
        return;
      }
    } else if (snap?.type === 'edge') {
      // Split the edge and use the new vertex
      const result = this.graph.splitEdge(snap.edgeId, snap.segmentIndex, snap.x, snap.y);
      if (result) vid = result.vertexId;
    }

    if (!vid) {
      vid = this.graph.addVertex(mapPt.x, mapPt.y);
    }

    // Add edge from previous vertex to this one
    if (this.currentVertices.length > 0) {
      const prev = this.currentVertices[this.currentVertices.length - 1];
      if (prev !== vid) {
        this.graph.addEdge([prev, vid]);
      }
    }

    this.currentVertices.push(vid);
  }

  onMouseMove(e) {
    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);
    this.previewPoint = mapPt;
    this.snapResult = findSnap(this.graph, mapPt, 8, this.renderer);
  }

  onMouseUp() {}

  onDblClick(e) {
    // Double-click finishes the polyline without closing
    if (this.currentVertices.length >= 2) {
      this._finishPolyline();
    }
  }

  onKeyDown(e) {
    if (e.key === 'Escape') {
      this._cancel();
    }
  }

  onKeyUp() {}

  _finishPolyline() {
    if (this.onComplete) this.onComplete(this.currentVertices);
    this.currentVertices = [];
  }

  _cancel() {
    // Remove vertices/edges added during this incomplete drawing
    // For simplicity: just clear the current chain. Undo will handle cleanup.
    this.currentVertices = [];
  }

  /** Get snap indicator for renderer */
  getSnap() {
    return this.snapResult ? { x: this.snapResult.x, y: this.snapResult.y } : null;
  }

  /** Get preview line from last vertex to cursor for renderer */
  getPreviewLine() {
    if (this.currentVertices.length === 0 || !this.previewPoint) return null;
    const lastVid = this.currentVertices[this.currentVertices.length - 1];
    const lastV = this.graph.vertices.get(lastVid);
    if (!lastV) return null;
    const target = this.snapResult || this.previewPoint;
    return { from: lastV, to: { x: target.x, y: target.y } };
  }
}
```

- [ ] **Step 2: Update app.js to wire up DrawTool and tool switching**

Add to `app.js` — replace the graph stub and tool setup:

```js
// At top, add imports:
import { PlanarGraph } from './graph.js';
import { DrawTool } from './tools/draw-tool.js';

// Replace graph stub with:
const graph = new PlanarGraph();

// Add tool switching by keyboard:
function createDrawTool() {
  return new DrawTool(renderer, graph, (vertices) => {
    // Drawing complete callback — faces will be recomputed
  });
}

document.addEventListener('keydown', e => {
  if (e.target.tagName === 'INPUT') return; // don't intercept input fields
  switch (e.key) {
    case 'd': setTool(createDrawTool()); break;
    case 'v': /* select tool later */ break;
    case 't': /* territory tool later */ break;
  }
  activeTool.onKeyDown(e);
});

// Add dblclick handler:
canvas.addEventListener('dblclick', e => {
  if (activeTool.onDblClick) activeTool.onDblClick(e);
});

// Update toolbar buttons:
document.querySelectorAll('.tool-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const toolName = btn.dataset.tool;
    switch (toolName) {
      case 'draw': setTool(createDrawTool()); break;
      case 'pan': setTool(new PanTool(renderer)); break;
    }
  });
});

// Update render loop to pass draw tool preview:
function frame() {
  const snap = activeTool.getSnap?.() || null;
  renderer.render(graph, null, null, snap, activeTool);

  // Draw preview line if draw tool
  if (activeTool.getPreviewLine) {
    const line = activeTool.getPreviewLine();
    if (line) {
      const ctx = renderer.ctx;
      ctx.save();
      ctx.translate(renderer.offsetX, renderer.offsetY);
      ctx.scale(renderer.zoom, renderer.zoom);
      ctx.beginPath();
      ctx.moveTo(line.from.x, line.from.y);
      ctx.lineTo(line.to.x, line.to.y);
      ctx.strokeStyle = '#e94560';
      ctx.lineWidth = 1.5 / renderer.zoom;
      ctx.setLineDash([6 / renderer.zoom, 4 / renderer.zoom]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();
    }
  }

  updateStatus();
  requestAnimationFrame(frame);
}
```

- [ ] **Step 3: Test drawing in browser**

Open `editor/index.html`, press D to switch to Draw tool:
- Click multiple points — edges should appear between them
- Hover near an existing vertex — orange snap circle appears
- Click on start vertex — polygon closes
- Double-click — polyline ends without closing
- Escape — cancels current drawing

- [ ] **Step 4: Commit**

```bash
git add editor/js/tools/draw-tool.js editor/js/app.js
git commit -m "feat(editor): add draw tool with polyline drawing and snap preview"
```

---

### Task 5: Face Detection Algorithm

**Files:**
- Create: `editor/js/faces.js`

- [ ] **Step 1: Implement planar face detection**

```js
// editor/js/faces.js

let nextFaceId = 0;

/**
 * Find all faces in a planar graph using the "next edge" algorithm.
 * Returns array of { id, edgeRefs: [{edgeId, forward}], points: [{x,y}], outer: bool }
 */
export function findFaces(graph) {
  nextFaceId = 0;
  const faces = [];

  // Build adjacency: for each vertex, sorted outgoing half-edges by angle
  const halfEdges = []; // { from, to, edgeId, forward, angle }
  for (const [eid, edge] of graph.edges) {
    const verts = edge.vertices;
    const first = verts[0];
    const last = verts[verts.length - 1];
    if (first === last) continue; // skip self-loops

    const vFirst = graph.vertices.get(first);
    const vLast = graph.vertices.get(last);
    if (!vFirst || !vLast) continue;

    // Forward half-edge: first→last
    halfEdges.push({
      from: first,
      to: last,
      edgeId: eid,
      forward: true,
      angle: Math.atan2(vLast.y - vFirst.y, vLast.x - vFirst.x),
    });
    // Backward half-edge: last→first
    halfEdges.push({
      from: last,
      to: first,
      edgeId: eid,
      forward: false,
      angle: Math.atan2(vFirst.y - vLast.y, vFirst.x - vLast.x),
    });
  }

  // Group by "from" vertex, sort by angle
  const byVertex = new Map();
  for (const he of halfEdges) {
    if (!byVertex.has(he.from)) byVertex.set(he.from, []);
    byVertex.get(he.from).push(he);
  }
  for (const [, list] of byVertex) {
    list.sort((a, b) => a.angle - b.angle);
  }

  // Build "next half-edge" map: for half-edge (u→v), the next is the
  // clockwise-next half-edge departing from v after the direction v→u.
  // That is: find (v→u) in v's sorted list, then pick the PREVIOUS entry
  // (wrapping around) — that's the next CW half-edge from v.
  const nextMap = new Map(); // key: "edgeId:forward" → next half-edge
  const heKey = (he) => `${he.edgeId}:${he.forward}`;

  for (const he of halfEdges) {
    // The reverse of this half-edge departs from he.to going to he.from
    const reverseAngle = Math.atan2(
      graph.vertices.get(he.from).y - graph.vertices.get(he.to).y,
      graph.vertices.get(he.from).x - graph.vertices.get(he.to).x,
    );

    const siblings = byVertex.get(he.to);
    if (!siblings || siblings.length === 0) continue;

    // Find the half-edge from he.to whose angle is just before reverseAngle (CW next)
    // "Just before" = the previous entry in CCW-sorted list after the reverse direction
    let idx = -1;
    for (let i = 0; i < siblings.length; i++) {
      if (siblings[i].edgeId === he.edgeId && siblings[i].forward !== he.forward) {
        idx = i;
        break;
      }
    }

    if (idx === -1) continue;

    // The next half-edge in the face is the one just before this in the sorted list
    const nextIdx = (idx - 1 + siblings.length) % siblings.length;
    nextMap.set(heKey(he), siblings[nextIdx]);
  }

  // Trace cycles
  const visited = new Set();

  for (const he of halfEdges) {
    const key = heKey(he);
    if (visited.has(key)) continue;

    const cycle = [];
    let current = he;
    let steps = 0;
    const maxSteps = halfEdges.length + 1;

    while (steps < maxSteps) {
      const k = heKey(current);
      if (visited.has(k)) break;
      visited.add(k);
      cycle.push({ edgeId: current.edgeId, forward: current.forward });

      const next = nextMap.get(k);
      if (!next) break;
      if (heKey(next) === heKey(he)) {
        // Completed the cycle
        break;
      }
      current = next;
      steps++;
    }

    if (cycle.length >= 3) {
      // Resolve cycle to points
      const points = resolvePoints(graph, cycle);
      const area = signedArea(points);
      faces.push({
        id: 'f' + (nextFaceId++),
        edgeRefs: cycle,
        points,
        outer: area > 0, // CW = outer face (in screen coords where Y goes down)
      });
    }
  }

  return faces;
}

function resolvePoints(graph, edgeRefs) {
  const points = [];
  for (const ref of edgeRefs) {
    const edge = graph.edges.get(ref.edgeId);
    if (!edge) continue;
    const verts = ref.forward ? edge.vertices : [...edge.vertices].reverse();
    // Skip first vertex (it's the same as last vertex of previous edge) except for first edge
    const start = points.length === 0 ? 0 : 1;
    for (let i = start; i < verts.length; i++) {
      const v = graph.vertices.get(verts[i]);
      if (v) points.push({ x: v.x, y: v.y });
    }
  }
  return points;
}

function signedArea(points) {
  let area = 0;
  for (let i = 0; i < points.length; i++) {
    const j = (i + 1) % points.length;
    area += points[i].x * points[j].y;
    area -= points[j].x * points[i].y;
  }
  return area / 2;
}
```

- [ ] **Step 2: Wire face detection into app.js**

Add to `app.js`:

```js
import { findFaces } from './faces.js';

let faces = [];

function recomputeFaces() {
  faces = findFaces(graph);
  updateStatus();
}

// Call recomputeFaces after every draw/edit operation.
// Update the DrawTool completion callback:
function createDrawTool() {
  return new DrawTool(renderer, graph, (vertices) => {
    recomputeFaces();
  });
}

// Update render call:
function frame() {
  const snap = activeTool.getSnap?.() || null;
  renderer.render(graph, faces, null, snap, activeTool);
  // ... rest of frame
}

// Update status counts to show face count:
function updateStatus() {
  const tCount = 0; // territories later
  document.getElementById('status-counts').textContent =
    `V: ${graph.vertices.size} | E: ${graph.edges.size} | F: ${faces.filter(f => !f.outer).length} | T: ${tCount}`;
  // ...
}
```

- [ ] **Step 3: Test face detection in browser**

Draw a triangle (3 clicks + click back on first vertex). Verify:
- The closed area gets a subtle semi-transparent fill
- Status bar shows F: 1
- Drawing a line through the triangle creates 2 faces
- Face count updates correctly

- [ ] **Step 4: Commit**

```bash
git add editor/js/faces.js editor/js/app.js
git commit -m "feat(editor): add planar face detection algorithm"
```

---

### Task 6: Select Tool (Move, Delete)

**Files:**
- Create: `editor/js/tools/select-tool.js`
- Modify: `editor/js/app.js`

- [ ] **Step 1: Implement SelectTool**

```js
// editor/js/tools/select-tool.js
import { findSnap } from '../snap.js';

export class SelectTool {
  constructor(renderer, graph, onChange) {
    this.renderer = renderer;
    this.graph = graph;
    this.onChange = onChange; // called after any modification
    this.selectedVertex = null;
    this.selectedEdge = null;
    this.dragging = false;
    this.snapResult = null;
  }

  get name() { return 'select'; }
  get cursor() { return 'default'; }

  onMouseDown(e) {
    if (e.button !== 0) return;
    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);
    const snap = findSnap(this.graph, mapPt, 8, this.renderer);

    this.selectedVertex = null;
    this.selectedEdge = null;

    if (snap?.type === 'vertex') {
      this.selectedVertex = snap.vertexId;
      this.dragging = true;
    } else if (snap?.type === 'edge') {
      this.selectedEdge = snap.edgeId;
    }
  }

  onMouseMove(e) {
    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);

    if (this.dragging && this.selectedVertex) {
      this.graph.moveVertex(this.selectedVertex, mapPt.x, mapPt.y);
      if (this.onChange) this.onChange();
    }

    this.snapResult = findSnap(this.graph, mapPt, 8, this.renderer);
  }

  onMouseUp() {
    if (this.dragging) {
      this.dragging = false;
      if (this.onChange) this.onChange();
    }
  }

  onKeyDown(e) {
    if (e.key === 'Delete' || e.key === 'Backspace') {
      if (this.selectedVertex) {
        this.graph.removeVertex(this.selectedVertex);
        this.selectedVertex = null;
        if (this.onChange) this.onChange();
      } else if (this.selectedEdge) {
        this.graph.removeEdge(this.selectedEdge);
        this.selectedEdge = null;
        if (this.onChange) this.onChange();
      }
    }
    if (e.key === 'Escape') {
      this.selectedVertex = null;
      this.selectedEdge = null;
    }
  }

  onKeyUp() {}

  getSnap() {
    return this.snapResult ? { x: this.snapResult.x, y: this.snapResult.y } : null;
  }

  /** Return selection info for renderer to highlight */
  getSelection() {
    return {
      vertexId: this.selectedVertex,
      edgeId: this.selectedEdge,
    };
  }
}
```

- [ ] **Step 2: Wire SelectTool into app.js**

Add import and tool creation:

```js
import { SelectTool } from './tools/select-tool.js';

function createSelectTool() {
  return new SelectTool(renderer, graph, () => recomputeFaces());
}

// In keyboard handler, add:
case 'v': setTool(createSelectTool()); break;

// In toolbar click handler, add:
case 'select': setTool(createSelectTool()); break;
```

Add selection highlight rendering in the render loop:

```js
// After main render, draw selection highlight
if (activeTool.getSelection) {
  const sel = activeTool.getSelection();
  const ctx = renderer.ctx;
  ctx.save();
  ctx.translate(renderer.offsetX, renderer.offsetY);
  ctx.scale(renderer.zoom, renderer.zoom);

  if (sel.vertexId) {
    const v = graph.vertices.get(sel.vertexId);
    if (v) {
      ctx.beginPath();
      ctx.arc(v.x, v.y, 6 / renderer.zoom, 0, Math.PI * 2);
      ctx.strokeStyle = '#00e5ff';
      ctx.lineWidth = 2 / renderer.zoom;
      ctx.stroke();
    }
  }
  if (sel.edgeId) {
    const edge = graph.edges.get(sel.edgeId);
    if (edge) {
      const verts = edge.vertices.map(vid => graph.vertices.get(vid)).filter(Boolean);
      ctx.beginPath();
      ctx.moveTo(verts[0].x, verts[0].y);
      for (let i = 1; i < verts.length; i++) ctx.lineTo(verts[i].x, verts[i].y);
      ctx.strokeStyle = '#00e5ff';
      ctx.lineWidth = 3 / renderer.zoom;
      ctx.stroke();
    }
  }
  ctx.restore();
}
```

- [ ] **Step 3: Test in browser**

Press V to switch to Select tool:
- Click a vertex → highlighted in cyan
- Drag vertex → moves, connected edges follow, faces update
- Click an edge → highlighted in cyan
- Press Delete → selected element removed, faces recompute
- Escape → deselects

- [ ] **Step 4: Commit**

```bash
git add editor/js/tools/select-tool.js editor/js/app.js
git commit -m "feat(editor): add select tool with vertex drag, edge select, and delete"
```

---

### Task 7: Undo/Redo System

**Files:**
- Create: `editor/js/history.js`
- Modify: `editor/js/app.js`

- [ ] **Step 1: Implement snapshot-based undo stack**

```js
// editor/js/history.js

/**
 * Snapshot-based undo/redo. Stores full graph clones.
 * Simpler than command pattern and handles all operations uniformly.
 */
export class UndoStack {
  constructor(maxSize = 100) {
    this.stack = [];
    this.index = -1;
    this.maxSize = maxSize;
  }

  /** Push a new snapshot (clone of current state) */
  push(graphClone, territoriesClone) {
    // Discard any redo states
    this.stack.length = this.index + 1;
    this.stack.push({ graph: graphClone, territories: territoriesClone });
    if (this.stack.length > this.maxSize) {
      this.stack.shift();
    } else {
      this.index++;
    }
  }

  canUndo() { return this.index > 0; }
  canRedo() { return this.index < this.stack.length - 1; }

  /** Returns the previous snapshot or null */
  undo() {
    if (!this.canUndo()) return null;
    this.index--;
    return this.stack[this.index];
  }

  /** Returns the next snapshot or null */
  redo() {
    if (!this.canRedo()) return null;
    this.index++;
    return this.stack[this.index];
  }
}
```

- [ ] **Step 2: Wire undo/redo into app.js**

```js
import { UndoStack } from './history.js';

const undoStack = new UndoStack();

// Save initial state
undoStack.push(graph.clone(), null);

function saveSnapshot() {
  undoStack.push(graph.clone(), null); // territories added later
}

function restoreSnapshot(snapshot) {
  // Copy snapshot graph data into current graph
  graph.vertices.clear();
  graph.edges.clear();
  for (const [id, v] of snapshot.graph.vertices) graph.vertices.set(id, { ...v });
  for (const [id, e] of snapshot.graph.edges) graph.edges.set(id, { vertices: [...e.vertices] });
  recomputeFaces();
}

// Update draw tool callback:
function createDrawTool() {
  return new DrawTool(renderer, graph, (vertices) => {
    recomputeFaces();
    saveSnapshot();
  });
}

// Update select tool callback:
function createSelectTool() {
  return new SelectTool(renderer, graph, () => {
    recomputeFaces();
    saveSnapshot();
  });
}

// Wire buttons and keyboard:
document.getElementById('btn-undo').addEventListener('click', () => {
  const s = undoStack.undo();
  if (s) restoreSnapshot(s);
});
document.getElementById('btn-redo').addEventListener('click', () => {
  const s = undoStack.redo();
  if (s) restoreSnapshot(s);
});

document.addEventListener('keydown', e => {
  if (e.ctrlKey && e.key === 'z') { e.preventDefault(); const s = undoStack.undo(); if (s) restoreSnapshot(s); }
  if (e.ctrlKey && e.key === 'y') { e.preventDefault(); const s = undoStack.redo(); if (s) restoreSnapshot(s); }
});
```

- [ ] **Step 3: Test in browser**

Draw some edges, then:
- Ctrl+Z undoes the last drawing → edges disappear
- Ctrl+Z again → previous state
- Ctrl+Y redoes → edges reappear
- Drawing after undo discards redo stack

- [ ] **Step 4: Commit**

```bash
git add editor/js/history.js editor/js/app.js
git commit -m "feat(editor): add snapshot-based undo/redo system"
```

---

### Task 8: Territory Tool + Territory Manager

**Files:**
- Create: `editor/js/territories.js`
- Create: `editor/js/tools/territory-tool.js`
- Modify: `editor/js/app.js`

- [ ] **Step 1: Implement TerritoryManager**

```js
// editor/js/territories.js

export class TerritoryManager {
  constructor() {
    /** @type {Map<string, {faceId: string, color: string, labelPosition: {x:number, y:number}}>} */
    this.territories = new Map();
    /** @type {Map<string, {bonus: number, territories: string[]}>} */
    this.continents = new Map();
    /** @type {[string, string][]} */
    this.manualAdjacencies = [];
    /** @type {[string, string][]} */
    this.manualNonAdjacencies = [];
  }

  addTerritory(name, faceId, color, labelPosition) {
    this.territories.set(name, { faceId, color, labelPosition });
  }

  removeTerritory(name) {
    this.territories.delete(name);
    // Remove from continents
    for (const [, cont] of this.continents) {
      const idx = cont.territories.indexOf(name);
      if (idx !== -1) cont.territories.splice(idx, 1);
    }
  }

  renameTerritory(oldName, newName) {
    const t = this.territories.get(oldName);
    if (!t) return;
    this.territories.delete(oldName);
    this.territories.set(newName, t);
    // Update continent references
    for (const [, cont] of this.continents) {
      const idx = cont.territories.indexOf(oldName);
      if (idx !== -1) cont.territories[idx] = newName;
    }
    // Update adjacency references
    const updateAdj = (list) => {
      for (const pair of list) {
        if (pair[0] === oldName) pair[0] = newName;
        if (pair[1] === oldName) pair[1] = newName;
      }
    };
    updateAdj(this.manualAdjacencies);
    updateAdj(this.manualNonAdjacencies);
  }

  getByFaceId(faceId) {
    for (const [name, t] of this.territories) {
      if (t.faceId === faceId) return { name, ...t };
    }
    return null;
  }

  addContinent(name, bonus) {
    this.continents.set(name, { bonus, territories: [] });
  }

  removeContinent(name) {
    this.continents.delete(name);
  }

  /**
   * Compute final adjacencies: auto (from shared edges) + manual - nonAdj.
   */
  computeAdjacencies(faces) {
    const auto = new Set();

    // Two territories are adjacent if their faces share an edge
    const faceByEdge = new Map(); // edgeId → [faceId, ...]
    for (const face of faces) {
      if (face.outer) continue;
      for (const ref of face.edgeRefs) {
        if (!faceByEdge.has(ref.edgeId)) faceByEdge.set(ref.edgeId, []);
        faceByEdge.get(ref.edgeId).push(face.id);
      }
    }

    for (const [, faceIds] of faceByEdge) {
      if (faceIds.length !== 2) continue;
      const t1 = this.getByFaceId(faceIds[0]);
      const t2 = this.getByFaceId(faceIds[1]);
      if (t1 && t2 && t1.name !== t2.name) {
        const key = [t1.name, t2.name].sort().join('|');
        auto.add(key);
      }
    }

    // Add manual
    for (const [a, b] of this.manualAdjacencies) {
      auto.add([a, b].sort().join('|'));
    }

    // Remove non-adjacencies
    for (const [a, b] of this.manualNonAdjacencies) {
      auto.delete([a, b].sort().join('|'));
    }

    return [...auto].map(k => k.split('|'));
  }

  /** Deep clone for undo */
  clone() {
    const tm = new TerritoryManager();
    for (const [n, t] of this.territories) {
      tm.territories.set(n, { ...t, labelPosition: { ...t.labelPosition } });
    }
    for (const [n, c] of this.continents) {
      tm.continents.set(n, { bonus: c.bonus, territories: [...c.territories] });
    }
    tm.manualAdjacencies = this.manualAdjacencies.map(p => [...p]);
    tm.manualNonAdjacencies = this.manualNonAdjacencies.map(p => [...p]);
    return tm;
  }

  static randomColor() {
    const colors = [
      '#E53935', '#1E88E5', '#43A047', '#FDD835',
      '#8E24AA', '#FF7043', '#00ACC1', '#3949AB',
      '#7CB342', '#F4511E', '#6D4C41', '#546E7A',
    ];
    return colors[Math.floor(Math.random() * colors.length)];
  }
}
```

- [ ] **Step 2: Implement TerritoryTool**

```js
// editor/js/tools/territory-tool.js
import { pointInPolygon } from '../snap.js';
import { TerritoryManager } from '../territories.js';

export class TerritoryTool {
  constructor(renderer, graph, faces, territories, onChange) {
    this.renderer = renderer;
    this.graph = graph;
    this.faces = faces;
    this.territories = territories;
    this.onChange = onChange;
  }

  get name() { return 'territory'; }
  get cursor() { return 'crosshair'; }

  onMouseDown(e) {
    if (e.button === 2) {
      // Right-click: remove territory
      this._handleRightClick(e);
      return;
    }
    if (e.button !== 0) return;

    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);

    // Find which face was clicked
    for (const face of this.faces) {
      if (face.outer) continue;
      if (pointInPolygon(mapPt, face.points)) {
        const existing = this.territories.getByFaceId(face.id);
        if (existing) {
          // Edit existing: prompt for new name
          const newName = prompt('Territory name:', existing.name);
          if (newName && newName !== existing.name) {
            this.territories.renameTerritory(existing.name, newName);
          }
          const newColor = prompt('Color (hex):', existing.color);
          if (newColor) {
            this.territories.territories.get(newName || existing.name).color = newColor;
          }
        } else {
          // New territory
          const name = prompt('Territory name:');
          if (!name) return;
          const color = TerritoryManager.randomColor();
          // Label position = centroid of face
          const cx = face.points.reduce((s, p) => s + p.x, 0) / face.points.length;
          const cy = face.points.reduce((s, p) => s + p.y, 0) / face.points.length;
          this.territories.addTerritory(name, face.id, color, { x: cx, y: cy });
        }
        if (this.onChange) this.onChange();
        return;
      }
    }
  }

  _handleRightClick(e) {
    e.preventDefault();
    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);

    for (const face of this.faces) {
      if (face.outer) continue;
      if (pointInPolygon(mapPt, face.points)) {
        const existing = this.territories.getByFaceId(face.id);
        if (existing && confirm(`Remove territory "${existing.name}"?`)) {
          this.territories.removeTerritory(existing.name);
          if (this.onChange) this.onChange();
        }
        return;
      }
    }
  }

  onMouseMove() {}
  onMouseUp() {}
  onKeyDown() {}
  onKeyUp() {}
  getSnap() { return null; }
}
```

- [ ] **Step 3: Wire into app.js**

```js
import { TerritoryManager } from './territories.js';
import { TerritoryTool } from './tools/territory-tool.js';

const territories = new TerritoryManager();

function createTerritoryTool() {
  return new TerritoryTool(renderer, graph, faces, territories, () => {
    saveSnapshot();
    updatePanel();
  });
}

// In keyboard handler:
case 't': setTool(createTerritoryTool()); break;

// In toolbar click handler:
case 'territory': setTool(createTerritoryTool()); break;

// Prevent context menu on canvas:
canvas.addEventListener('contextmenu', e => e.preventDefault());

// Update render call to pass territories:
renderer.render(graph, faces, territories, snap, activeTool);

// Update snapshot to include territories:
function saveSnapshot() {
  undoStack.push(graph.clone(), territories.clone());
}
function restoreSnapshot(snapshot) {
  graph.vertices.clear();
  graph.edges.clear();
  for (const [id, v] of snapshot.graph.vertices) graph.vertices.set(id, { ...v });
  for (const [id, e] of snapshot.graph.edges) graph.edges.set(id, { vertices: [...e.vertices] });
  if (snapshot.territories) {
    territories.territories.clear();
    territories.continents.clear();
    const src = snapshot.territories;
    for (const [n, t] of src.territories) territories.territories.set(n, { ...t, labelPosition: { ...t.labelPosition } });
    for (const [n, c] of src.continents) territories.continents.set(n, { bonus: c.bonus, territories: [...c.territories] });
    territories.manualAdjacencies = src.manualAdjacencies.map(p => [...p]);
    territories.manualNonAdjacencies = src.manualNonAdjacencies.map(p => [...p]);
  }
  recomputeFaces();
}
```

- [ ] **Step 4: Test in browser**

1. Draw a closed shape (triangle/rectangle)
2. Press T, click inside the shape
3. Enter a name → territory appears with random color and label
4. Click again to edit name/color
5. Right-click to remove
6. Undo/Redo preserves territory state

- [ ] **Step 5: Commit**

```bash
git add editor/js/territories.js editor/js/tools/territory-tool.js editor/js/app.js
git commit -m "feat(editor): add territory tool with create, edit, delete, and undo support"
```

---

### Task 9: Right Panel UI (Territories, Continents, Adjacencies)

**Files:**
- Create: `editor/js/ui-panel.js`
- Modify: `editor/js/app.js`

- [ ] **Step 1: Implement panel update functions**

```js
// editor/js/ui-panel.js

export function updateTerritoryList(territories, faces, onSelect) {
  const container = document.getElementById('territory-list');
  container.innerHTML = '';

  if (territories.territories.size === 0) {
    container.innerHTML = '<div style="color:#666;font-size:11px;text-align:center;padding:8px">Use Territory tool (T) to confirm faces</div>';
    return;
  }

  for (const [name, t] of territories.territories) {
    const item = document.createElement('div');
    item.className = 'territory-item';
    item.innerHTML = `
      <span class="color-dot" style="background:${t.color}"></span>
      <span class="name">${name}</span>
    `;
    item.addEventListener('click', () => onSelect(name));
    container.appendChild(item);
  }
}

export function updateContinentList(territories, onChange) {
  const container = document.getElementById('continent-list');
  container.innerHTML = '';

  for (const [name, cont] of territories.continents) {
    const item = document.createElement('div');
    item.className = 'continent-item';
    item.innerHTML = `
      <div class="header">
        <input type="text" value="${name}" data-continent="${name}" class="continent-name">
        <div>
          Bonus: <input type="number" value="${cont.bonus}" min="0" max="20" class="bonus-input" data-continent="${name}">
          <button data-delete="${name}" style="width:auto;padding:2px 6px;font-size:10px;">✕</button>
        </div>
      </div>
      <div class="territories">${cont.territories.length > 0 ? cont.territories.join(', ') : '<em>No territories assigned</em>'}</div>
    `;
    container.appendChild(item);

    // Wire events
    item.querySelector('.continent-name').addEventListener('change', e => {
      const oldName = e.target.dataset.continent;
      const newName = e.target.value.trim();
      if (newName && newName !== oldName) {
        const data = territories.continents.get(oldName);
        territories.continents.delete(oldName);
        territories.continents.set(newName, data);
        onChange();
      }
    });

    item.querySelector('.bonus-input').addEventListener('change', e => {
      const contName = e.target.dataset.continent;
      const c = territories.continents.get(contName);
      if (c) c.bonus = parseInt(e.target.value) || 0;
      onChange();
    });

    item.querySelector('[data-delete]').addEventListener('click', e => {
      const contName = e.target.dataset.delete;
      territories.continents.delete(contName);
      onChange();
    });
  }
}

export function updateAdjacencyList(territories, faces, onChange) {
  const container = document.getElementById('adjacency-list');
  const adjacencies = territories.computeAdjacencies(faces);
  container.innerHTML = '';

  if (adjacencies.length === 0) {
    container.innerHTML = '<div style="color:#666;font-size:11px;text-align:center;padding:8px">No adjacencies yet</div>';
    return;
  }

  for (const [a, b] of adjacencies) {
    const item = document.createElement('div');
    item.style.cssText = 'font-size:11px;padding:2px 4px;display:flex;justify-content:space-between;align-items:center;';
    const isManual = territories.manualAdjacencies.some(
      p => (p[0] === a && p[1] === b) || (p[0] === b && p[1] === a)
    );
    item.innerHTML = `
      <span>${a} ↔ ${b} ${isManual ? '(manual)' : ''}</span>
      <button style="width:auto;padding:1px 4px;font-size:9px;" data-remove-adj="${a}|${b}">✕</button>
    `;
    item.querySelector('[data-remove-adj]').addEventListener('click', e => {
      const [ra, rb] = e.target.dataset.removeAdj.split('|');
      // Remove from manual adjacencies if it's manual, otherwise add to non-adjacencies
      const manIdx = territories.manualAdjacencies.findIndex(
        p => (p[0] === ra && p[1] === rb) || (p[0] === rb && p[1] === ra)
      );
      if (manIdx !== -1) {
        territories.manualAdjacencies.splice(manIdx, 1);
      } else {
        territories.manualNonAdjacencies.push([ra, rb]);
      }
      onChange();
    });
    container.appendChild(item);
  }
}

export function setupPanelEvents(territories, onChange) {
  // Add continent button
  document.getElementById('btn-add-continent').addEventListener('click', () => {
    const name = prompt('Continent name:');
    if (!name) return;
    const bonus = parseInt(prompt('Army bonus:', '2')) || 0;
    territories.addContinent(name, bonus);
    onChange();
  });

  // Add adjacency button
  document.getElementById('btn-add-adjacency').addEventListener('click', () => {
    const names = [...territories.territories.keys()];
    const a = prompt('First territory:\n\nAvailable: ' + names.join(', '));
    if (!a || !territories.territories.has(a)) { alert('Territory not found'); return; }
    const b = prompt('Second territory:');
    if (!b || !territories.territories.has(b)) { alert('Territory not found'); return; }
    territories.manualAdjacencies.push([a, b]);
    onChange();
  });
}
```

- [ ] **Step 2: Wire panel into app.js**

```js
import { updateTerritoryList, updateContinentList, updateAdjacencyList, setupPanelEvents } from './ui-panel.js';

function updatePanel() {
  updateTerritoryList(territories, faces, (name) => {
    // Select territory in panel — could highlight on canvas
    console.log('Selected territory:', name);
  });
  updateContinentList(territories, () => { saveSnapshot(); updatePanel(); });
  updateAdjacencyList(territories, faces, () => { saveSnapshot(); updatePanel(); });
}

setupPanelEvents(territories, () => { saveSnapshot(); updatePanel(); });

// Call updatePanel after face recomputation and territory changes
function recomputeFaces() {
  faces = findFaces(graph);
  updatePanel();
  updateStatus();
}
```

- [ ] **Step 3: Test in browser**

1. Create some territories → they appear in the right panel
2. Add a continent → appears with name + bonus input
3. Adjacencies auto-populate when territories share edges
4. Add manual adjacency via button
5. Remove adjacency via ✕ button

- [ ] **Step 4: Commit**

```bash
git add editor/js/ui-panel.js editor/js/app.js
git commit -m "feat(editor): add right panel with territory list, continents, and adjacency management"
```

---

### Task 10: Continent Assignment UI

**Files:**
- Modify: `editor/js/ui-panel.js`
- Modify: `editor/js/territories.js`

- [ ] **Step 1: Add territory-to-continent assignment**

Update `updateTerritoryList` in `ui-panel.js` to show a continent dropdown per territory:

```js
export function updateTerritoryList(territories, faces, onSelect) {
  const container = document.getElementById('territory-list');
  container.innerHTML = '';

  if (territories.territories.size === 0) {
    container.innerHTML = '<div style="color:#666;font-size:11px;text-align:center;padding:8px">Use Territory tool (T) to confirm faces</div>';
    return;
  }

  const continentNames = [...territories.continents.keys()];

  for (const [name, t] of territories.territories) {
    // Find which continent this territory belongs to
    let currentContinent = '';
    for (const [cname, cont] of territories.continents) {
      if (cont.territories.includes(name)) { currentContinent = cname; break; }
    }

    const item = document.createElement('div');
    item.className = 'territory-item';
    item.innerHTML = `
      <span class="color-dot" style="background:${t.color}"></span>
      <span class="name">${name}</span>
      <select class="continent-select" style="background:#0f3460;color:#ccc;border:1px solid #333;border-radius:3px;font-size:10px;padding:1px;">
        <option value="">—</option>
        ${continentNames.map(c => `<option value="${c}" ${c === currentContinent ? 'selected' : ''}>${c}</option>`).join('')}
      </select>
    `;

    item.querySelector('.name').addEventListener('click', () => onSelect(name));

    item.querySelector('.continent-select').addEventListener('change', (e) => {
      // Remove from all continents
      for (const [, cont] of territories.continents) {
        const idx = cont.territories.indexOf(name);
        if (idx !== -1) cont.territories.splice(idx, 1);
      }
      // Add to selected continent
      if (e.target.value) {
        const cont = territories.continents.get(e.target.value);
        if (cont) cont.territories.push(name);
      }
      onSelect(name); // triggers panel refresh
    });

    container.appendChild(item);
  }
}
```

- [ ] **Step 2: Test in browser**

1. Create territories and a continent
2. Each territory shows a dropdown to assign it to a continent
3. Assigning updates the continent's territory list below
4. Changing assignment removes from old continent

- [ ] **Step 3: Commit**

```bash
git add editor/js/ui-panel.js
git commit -m "feat(editor): add continent assignment dropdown to territory list"
```

---

### Task 11: Save/Load/Export (IO)

**Files:**
- Create: `editor/js/io.js`
- Modify: `editor/js/app.js`
- Modify: `editor/js/graph.js`

- [ ] **Step 1: Implement save, load, and export**

```js
// editor/js/io.js
import { PlanarGraph } from './graph.js';
import { TerritoryManager } from './territories.js';

/**
 * Save editor state to .risk.json format.
 */
export function saveEditorJson(graph, territories, mapWidth, mapHeight) {
  const data = {
    name: 'Untitled Map',
    canvasSize: [mapWidth, mapHeight],
    vertices: {},
    edges: {},
    territories: {},
    continents: {},
    manualAdjacencies: territories.manualAdjacencies,
    manualNonAdjacencies: territories.manualNonAdjacencies,
  };

  for (const [id, v] of graph.vertices) {
    data.vertices[id] = [Math.round(v.x * 10) / 10, Math.round(v.y * 10) / 10];
  }
  for (const [id, e] of graph.edges) {
    data.edges[id] = e.vertices;
  }
  for (const [name, t] of territories.territories) {
    data.territories[name] = {
      faceId: t.faceId,
      color: t.color,
      labelPosition: [Math.round(t.labelPosition.x), Math.round(t.labelPosition.y)],
    };
  }
  for (const [name, c] of territories.continents) {
    data.continents[name] = { bonus: c.bonus, territories: [...c.territories] };
  }

  return JSON.stringify(data, null, 2);
}

/**
 * Load editor state from .risk.json.
 * Returns { graph, territories, mapWidth, mapHeight }.
 */
export function loadEditorJson(json) {
  const data = JSON.parse(json);
  const graph = new PlanarGraph();

  // Find max IDs for counter reset
  let maxV = 0, maxE = 0;
  for (const id of Object.keys(data.vertices)) {
    const n = parseInt(id.slice(1));
    if (n >= maxV) maxV = n + 1;
  }
  for (const id of Object.keys(data.edges)) {
    const n = parseInt(id.slice(1));
    if (n >= maxE) maxE = n + 1;
  }
  PlanarGraph.resetIds(maxV, maxE);

  for (const [id, coords] of Object.entries(data.vertices)) {
    graph.vertices.set(id, { x: coords[0], y: coords[1] });
  }
  for (const [id, verts] of Object.entries(data.edges)) {
    graph.edges.set(id, { vertices: [...verts] });
  }

  const territories = new TerritoryManager();
  for (const [name, t] of Object.entries(data.territories || {})) {
    territories.addTerritory(name, t.faceId, t.color, {
      x: t.labelPosition[0],
      y: t.labelPosition[1],
    });
  }
  for (const [name, c] of Object.entries(data.continents || {})) {
    territories.addContinent(name, c.bonus);
    territories.continents.get(name).territories = [...c.territories];
  }
  territories.manualAdjacencies = (data.manualAdjacencies || []).map(p => [...p]);
  territories.manualNonAdjacencies = (data.manualNonAdjacencies || []).map(p => [...p]);

  return {
    graph,
    territories,
    mapWidth: data.canvasSize?.[0] || 1200,
    mapHeight: data.canvasSize?.[1] || 700,
  };
}

/**
 * Export game-ready JSON for the Flutter app.
 */
export function exportGameJson(graph, faces, territories, mapWidth, mapHeight) {
  const data = {
    name: 'Untitled Map',
    canvasSize: [mapWidth, mapHeight],
    territories: {},
    continents: [],
    adjacencies: territories.computeAdjacencies(faces),
  };

  for (const [name, t] of territories.territories) {
    // Find the face and resolve its points
    const face = faces.find(f => f.id === t.faceId);
    if (!face) continue;
    data.territories[name] = {
      path: face.points.map(p => [Math.round(p.x), Math.round(p.y)]),
      color: t.color,
      labelPosition: [Math.round(t.labelPosition.x), Math.round(t.labelPosition.y)],
    };
  }

  for (const [name, c] of territories.continents) {
    data.continents.push({
      name,
      bonus: c.bonus,
      territories: [...c.territories],
    });
  }

  return JSON.stringify(data, null, 2);
}

export function downloadJson(content, filename) {
  const blob = new Blob([content], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
```

- [ ] **Step 2: Wire IO into app.js**

```js
import { saveEditorJson, loadEditorJson, exportGameJson, downloadJson } from './io.js';

document.getElementById('btn-save').addEventListener('click', () => {
  const json = saveEditorJson(graph, territories, renderer.mapWidth, renderer.mapHeight);
  downloadJson(json, 'map.risk.json');
});

document.getElementById('btn-export').addEventListener('click', () => {
  const json = exportGameJson(graph, faces, territories, renderer.mapWidth, renderer.mapHeight);
  downloadJson(json, 'map.json');
});

document.getElementById('btn-load').addEventListener('click', () => {
  document.getElementById('file-load').click();
});

document.getElementById('file-load').addEventListener('change', (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    const result = loadEditorJson(reader.result);
    // Replace graph
    graph.vertices.clear();
    graph.edges.clear();
    for (const [id, v] of result.graph.vertices) graph.vertices.set(id, v);
    for (const [id, e] of result.graph.edges) graph.edges.set(id, e);
    // Replace territories
    territories.territories.clear();
    territories.continents.clear();
    for (const [n, t] of result.territories.territories) territories.territories.set(n, t);
    for (const [n, c] of result.territories.continents) territories.continents.set(n, c);
    territories.manualAdjacencies = result.territories.manualAdjacencies;
    territories.manualNonAdjacencies = result.territories.manualNonAdjacencies;
    // Update canvas size
    renderer.setMapSize(result.mapWidth, result.mapHeight);
    document.getElementById('canvas-width').value = result.mapWidth;
    document.getElementById('canvas-height').value = result.mapHeight;
    renderer.fitToView();
    recomputeFaces();
    saveSnapshot();
  };
  reader.readAsText(file);
  e.target.value = ''; // reset for re-loading same file
});

// Ctrl+S to save
document.addEventListener('keydown', e => {
  if (e.ctrlKey && e.key === 's') { e.preventDefault(); document.getElementById('btn-save').click(); }
  if (e.ctrlKey && e.key === 'e') { e.preventDefault(); document.getElementById('btn-export').click(); }
});
```

- [ ] **Step 3: Test full round-trip**

1. Draw shapes, confirm territories, add continents
2. Save → downloads `.risk.json`
3. Reload page, Load the file → state restored
4. Export → downloads game `.json` with resolved point lists
5. Verify exported JSON has correct `path`, `adjacencies`, `continents`

- [ ] **Step 4: Commit**

```bash
git add editor/js/io.js editor/js/app.js
git commit -m "feat(editor): add save/load (.risk.json) and game export (.json)"
```

---

### Task 12: Space-to-Pan Modifier + Cursor Updates

**Files:**
- Modify: `editor/js/app.js`

- [ ] **Step 1: Add space-to-pan modifier and cursor management**

```js
// In app.js, add space-as-modifier logic:

let spaceDown = false;
let savedTool = null;

document.addEventListener('keydown', e => {
  if (e.target.tagName === 'INPUT') return;

  if (e.key === ' ' && !spaceDown) {
    e.preventDefault();
    spaceDown = true;
    savedTool = activeTool;
    activeTool = new PanTool(renderer);
    updateCursor();
  }
});

document.addEventListener('keyup', e => {
  if (e.key === ' ' && spaceDown) {
    spaceDown = false;
    if (savedTool) {
      activeTool = savedTool;
      savedTool = null;
    }
    updateCursor();
  }
});

function updateCursor() {
  const container = document.getElementById('canvas-container');
  container.className = '';
  switch (activeTool.cursor) {
    case 'crosshair': container.classList.add('drawing'); break;
    case 'default': container.classList.add('selecting'); break;
    default: break; // grab is the CSS default
  }
}

// Call updateCursor whenever tool changes:
function setTool(tool) {
  activeTool = tool;
  document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`[data-tool="${tool.name}"]`)?.classList.add('active');
  updateCursor();
  updateStatus();
}
```

- [ ] **Step 2: Test**

- Hold Space in any tool → switches to pan temporarily
- Release Space → returns to previous tool
- Cursor changes appropriately per tool

- [ ] **Step 3: Commit**

```bash
git add editor/js/app.js
git commit -m "feat(editor): add space-to-pan modifier and dynamic cursor management"
```

---

### Task 13: Final Assembly + Polish

**Files:**
- Modify: `editor/js/app.js` — final assembly ensuring all pieces work together

- [ ] **Step 1: Create the final assembled app.js**

Write the complete `app.js` that integrates all modules. This replaces the incrementally modified version with a clean final assembly:

```js
// editor/js/app.js
import { Renderer } from './renderer.js';
import { PlanarGraph } from './graph.js';
import { findFaces } from './faces.js';
import { TerritoryManager } from './territories.js';
import { UndoStack } from './history.js';
import { PanTool } from './tools/pan-tool.js';
import { DrawTool } from './tools/draw-tool.js';
import { SelectTool } from './tools/select-tool.js';
import { TerritoryTool } from './tools/territory-tool.js';
import { saveEditorJson, loadEditorJson, exportGameJson, downloadJson } from './io.js';
import { updateTerritoryList, updateContinentList, updateAdjacencyList, setupPanelEvents } from './ui-panel.js';

// State
const canvas = document.getElementById('editor-canvas');
const renderer = new Renderer(canvas);
const graph = new PlanarGraph();
const territories = new TerritoryManager();
const undoStack = new UndoStack();
let faces = [];
let activeTool = new PanTool(renderer);
let spaceDown = false;
let savedTool = null;

// Save initial state
undoStack.push(graph.clone(), territories.clone());

// Tool factories
function createDrawTool() {
  return new DrawTool(renderer, graph, () => { recomputeFaces(); saveSnapshot(); });
}
function createSelectTool() {
  return new SelectTool(renderer, graph, () => { recomputeFaces(); saveSnapshot(); });
}
function createTerritoryTool() {
  return new TerritoryTool(renderer, graph, faces, territories, () => { saveSnapshot(); updatePanel(); });
}

function setTool(tool) {
  activeTool = tool;
  document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`[data-tool="${tool.name}"]`)?.classList.add('active');
  updateCursor();
  updateStatus();
}

function updateCursor() {
  const c = document.getElementById('canvas-container');
  c.className = '';
  if (activeTool.cursor === 'crosshair') c.classList.add('drawing');
  else if (activeTool.cursor === 'default') c.classList.add('selecting');
}

// State helpers
function recomputeFaces() { faces = findFaces(graph); updatePanel(); updateStatus(); }
function saveSnapshot() { undoStack.push(graph.clone(), territories.clone()); }

function restoreSnapshot(snapshot) {
  if (!snapshot) return;
  graph.vertices.clear();
  graph.edges.clear();
  for (const [id, v] of snapshot.graph.vertices) graph.vertices.set(id, { ...v });
  for (const [id, e] of snapshot.graph.edges) graph.edges.set(id, { vertices: [...e.vertices] });
  if (snapshot.territories) {
    territories.territories.clear();
    territories.continents.clear();
    const s = snapshot.territories;
    for (const [n, t] of s.territories) territories.territories.set(n, { ...t, labelPosition: { ...t.labelPosition } });
    for (const [n, c] of s.continents) territories.continents.set(n, { bonus: c.bonus, territories: [...c.territories] });
    territories.manualAdjacencies = s.manualAdjacencies.map(p => [...p]);
    territories.manualNonAdjacencies = s.manualNonAdjacencies.map(p => [...p]);
  }
  recomputeFaces();
}

// Panel
function updatePanel() {
  updateTerritoryList(territories, faces, () => { saveSnapshot(); updatePanel(); });
  updateContinentList(territories, () => { saveSnapshot(); updatePanel(); });
  updateAdjacencyList(territories, faces, () => { saveSnapshot(); updatePanel(); });
}
setupPanelEvents(territories, () => { saveSnapshot(); updatePanel(); });

function updateStatus() {
  document.getElementById('status-canvas').textContent =
    `Canvas: ${renderer.mapWidth} × ${renderer.mapHeight} | Zoom: ${Math.round(renderer.zoom * 100)}%`;
  document.getElementById('status-counts').textContent =
    `V: ${graph.vertices.size} | E: ${graph.edges.size} | F: ${faces.filter(f => !f.outer).length} | T: ${territories.territories.size}`;
  document.getElementById('status-tool').textContent =
    `Tool: ${activeTool.name} | Snap: ON`;
}

// Canvas events
canvas.addEventListener('mousedown', e => activeTool.onMouseDown(e));
canvas.addEventListener('mousemove', e => activeTool.onMouseMove(e));
canvas.addEventListener('mouseup', e => activeTool.onMouseUp(e));
canvas.addEventListener('dblclick', e => { if (activeTool.onDblClick) activeTool.onDblClick(e); });
canvas.addEventListener('contextmenu', e => e.preventDefault());
canvas.addEventListener('wheel', e => {
  e.preventDefault();
  const rect = canvas.getBoundingClientRect();
  renderer.zoomAt(e.clientX - rect.left, e.clientY - rect.top, e.deltaY);
}, { passive: false });

// Toolbar buttons
document.querySelectorAll('.tool-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    switch (btn.dataset.tool) {
      case 'draw': setTool(createDrawTool()); break;
      case 'select': setTool(createSelectTool()); break;
      case 'pan': setTool(new PanTool(renderer)); break;
      case 'territory': setTool(createTerritoryTool()); break;
    }
  });
});

// Keyboard
document.addEventListener('keydown', e => {
  if (e.target.tagName === 'INPUT') return;
  if (e.key === ' ' && !spaceDown) { e.preventDefault(); spaceDown = true; savedTool = activeTool; activeTool = new PanTool(renderer); updateCursor(); return; }
  if (e.ctrlKey && e.key === 'z') { e.preventDefault(); restoreSnapshot(undoStack.undo()); return; }
  if (e.ctrlKey && e.key === 'y') { e.preventDefault(); restoreSnapshot(undoStack.redo()); return; }
  if (e.ctrlKey && e.key === 's') { e.preventDefault(); document.getElementById('btn-save').click(); return; }
  if (e.ctrlKey && e.key === 'e') { e.preventDefault(); document.getElementById('btn-export').click(); return; }
  if (!e.ctrlKey) {
    switch (e.key) {
      case 'd': setTool(createDrawTool()); break;
      case 'v': setTool(createSelectTool()); break;
      case 't': setTool(createTerritoryTool()); break;
    }
  }
  activeTool.onKeyDown(e);
});
document.addEventListener('keyup', e => {
  if (e.key === ' ' && spaceDown) { spaceDown = false; if (savedTool) { activeTool = savedTool; savedTool = null; } updateCursor(); }
});

// Undo/Redo buttons
document.getElementById('btn-undo').addEventListener('click', () => restoreSnapshot(undoStack.undo()));
document.getElementById('btn-redo').addEventListener('click', () => restoreSnapshot(undoStack.redo()));

// IO
document.getElementById('btn-save').addEventListener('click', () => {
  downloadJson(saveEditorJson(graph, territories, renderer.mapWidth, renderer.mapHeight), 'map.risk.json');
});
document.getElementById('btn-export').addEventListener('click', () => {
  downloadJson(exportGameJson(graph, faces, territories, renderer.mapWidth, renderer.mapHeight), 'map.json');
});
document.getElementById('btn-load').addEventListener('click', () => document.getElementById('file-load').click());
document.getElementById('file-load').addEventListener('change', e => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    const r = loadEditorJson(reader.result);
    graph.vertices.clear(); graph.edges.clear();
    for (const [id, v] of r.graph.vertices) graph.vertices.set(id, v);
    for (const [id, e] of r.graph.edges) graph.edges.set(id, e);
    territories.territories.clear(); territories.continents.clear();
    for (const [n, t] of r.territories.territories) territories.territories.set(n, t);
    for (const [n, c] of r.territories.continents) territories.continents.set(n, c);
    territories.manualAdjacencies = r.territories.manualAdjacencies;
    territories.manualNonAdjacencies = r.territories.manualNonAdjacencies;
    renderer.setMapSize(r.mapWidth, r.mapHeight);
    document.getElementById('canvas-width').value = r.mapWidth;
    document.getElementById('canvas-height').value = r.mapHeight;
    renderer.fitToView();
    recomputeFaces();
    saveSnapshot();
  };
  reader.readAsText(file);
  e.target.value = '';
});

// Background image
document.getElementById('btn-load-image').addEventListener('click', () => document.getElementById('file-image').click());
document.getElementById('file-image').addEventListener('change', e => {
  const file = e.target.files[0];
  if (!file) return;
  const img = new Image();
  img.onload = () => renderer.setBackgroundImage(img);
  img.src = URL.createObjectURL(file);
});
document.getElementById('bg-opacity').addEventListener('input', e => {
  const val = parseInt(e.target.value);
  renderer.setBackgroundOpacity(val / 100);
  document.getElementById('bg-opacity-val').textContent = val + '%';
});
document.getElementById('canvas-width').addEventListener('change', e => {
  renderer.setMapSize(parseInt(e.target.value) || 1200, renderer.mapHeight);
  updateStatus();
});
document.getElementById('canvas-height').addEventListener('change', e => {
  renderer.setMapSize(renderer.mapWidth, parseInt(e.target.value) || 700);
  updateStatus();
});

// Render loop
function frame() {
  const snap = activeTool.getSnap?.() || null;
  renderer.render(graph, faces, territories, snap, activeTool);

  // Draw preview line
  if (activeTool.getPreviewLine) {
    const line = activeTool.getPreviewLine();
    if (line) {
      const ctx = renderer.ctx;
      ctx.save();
      ctx.translate(renderer.offsetX, renderer.offsetY);
      ctx.scale(renderer.zoom, renderer.zoom);
      ctx.beginPath();
      ctx.moveTo(line.from.x, line.from.y);
      ctx.lineTo(line.to.x, line.to.y);
      ctx.strokeStyle = '#e94560';
      ctx.lineWidth = 1.5 / renderer.zoom;
      ctx.setLineDash([6 / renderer.zoom, 4 / renderer.zoom]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();
    }
  }

  // Selection highlight
  if (activeTool.getSelection) {
    const sel = activeTool.getSelection();
    const ctx = renderer.ctx;
    ctx.save();
    ctx.translate(renderer.offsetX, renderer.offsetY);
    ctx.scale(renderer.zoom, renderer.zoom);
    if (sel.vertexId) {
      const v = graph.vertices.get(sel.vertexId);
      if (v) {
        ctx.beginPath();
        ctx.arc(v.x, v.y, 6 / renderer.zoom, 0, Math.PI * 2);
        ctx.strokeStyle = '#00e5ff';
        ctx.lineWidth = 2 / renderer.zoom;
        ctx.stroke();
      }
    }
    if (sel.edgeId) {
      const edge = graph.edges.get(sel.edgeId);
      if (edge) {
        const verts = edge.vertices.map(vid => graph.vertices.get(vid)).filter(Boolean);
        ctx.beginPath();
        ctx.moveTo(verts[0].x, verts[0].y);
        for (let i = 1; i < verts.length; i++) ctx.lineTo(verts[i].x, verts[i].y);
        ctx.strokeStyle = '#00e5ff';
        ctx.lineWidth = 3 / renderer.zoom;
        ctx.stroke();
      }
    }
    ctx.restore();
  }

  updateStatus();
  requestAnimationFrame(frame);
}

renderer.fitToView();
requestAnimationFrame(frame);
```

- [ ] **Step 2: Full end-to-end test**

Test the complete workflow:
1. Open `editor/index.html` in browser
2. Load a background image, adjust opacity
3. Draw continent outlines (D tool)
4. Draw internal borders snapping to existing edges
5. Confirm territories (T tool) with names and colors
6. Create continents, assign territories
7. Add manual adjacency
8. Save → reload → Load → verify state preserved
9. Export game JSON → verify format
10. Undo/Redo through all operations
11. Space-to-pan in any tool

- [ ] **Step 3: Commit**

```bash
git add editor/
git commit -m "feat(editor): complete risk map editor with draw, select, territory, pan tools and save/load/export"
```

---

## Summary

| Task | What it builds | Key files |
|------|---------------|-----------|
| 1 | HTML shell + canvas pan/zoom | index.html, style.css, renderer.js, pan-tool.js, app.js |
| 2 | Planar graph data structure | graph.js |
| 3 | Vertex + edge snapping | snap.js |
| 4 | Draw tool (polyline drawing) | draw-tool.js |
| 5 | Face detection algorithm | faces.js |
| 6 | Select tool (move, delete) | select-tool.js |
| 7 | Undo/redo system | history.js |
| 8 | Territory tool + manager | territories.js, territory-tool.js |
| 9 | Right panel UI | ui-panel.js |
| 10 | Continent assignment | ui-panel.js update |
| 11 | Save/load/export | io.js |
| 12 | Space-to-pan + cursors | app.js update |
| 13 | Final assembly + polish | app.js rewrite |
