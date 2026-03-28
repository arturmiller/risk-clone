// editor/js/app.js
import { Renderer } from './renderer.js';
import { PlanarGraph } from './graph.js';
import { PanTool } from './tools/pan-tool.js';
import { DrawTool } from './tools/draw-tool.js';
import { SelectTool } from './tools/select-tool.js';
import { findFaces } from './faces.js';
import { UndoStack } from './history.js';

const canvas = document.getElementById('editor-canvas');
const renderer = new Renderer(canvas);
const graph = new PlanarGraph();

const undoStack = new UndoStack();
undoStack.push(graph.clone(), null);

function saveSnapshot() {
  undoStack.push(graph.clone(), null);
}

function restoreSnapshot(snapshot) {
  if (!snapshot) return;
  graph.vertices.clear();
  graph.edges.clear();
  for (const [id, v] of snapshot.graph.vertices) graph.vertices.set(id, { ...v });
  for (const [id, e] of snapshot.graph.edges) graph.edges.set(id, { vertices: [...e.vertices] });
  recomputeFaces();
}

let activeTool = new PanTool(renderer);
let snap = null;
let faces = [];

function recomputeFaces() {
  faces = findFaces(graph);
  updateStatus();
}

function createDrawTool() {
  return new DrawTool(renderer, graph, (vertices) => {
    recomputeFaces();
    saveSnapshot();
  });
}

function createSelectTool() { return new SelectTool(renderer, graph, () => { recomputeFaces(); saveSnapshot(); }); }

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
canvas.addEventListener('dblclick', e => { if (activeTool.onDblClick) activeTool.onDblClick(e); });
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
      case 'pan': setTool(new PanTool(renderer)); break;
      case 'select': setTool(createSelectTool()); break;
      // territory added in later tasks
    }
  });
});

// Keyboard shortcuts
document.addEventListener('keydown', e => {
  if (e.target.tagName === 'INPUT') return;
  if (e.ctrlKey && e.key === 'z') { e.preventDefault(); restoreSnapshot(undoStack.undo()); return; }
  if (e.ctrlKey && e.key === 'y') { e.preventDefault(); restoreSnapshot(undoStack.redo()); return; }
  if (!e.ctrlKey) {
    switch (e.key) {
      case 'd': setTool(createDrawTool()); break;
      case 'v': setTool(createSelectTool()); break;
      // t added in later tasks
    }
  }
  activeTool.onKeyDown(e);
});

// Undo/Redo buttons
document.getElementById('btn-undo').addEventListener('click', () => restoreSnapshot(undoStack.undo()));
document.getElementById('btn-redo').addEventListener('click', () => restoreSnapshot(undoStack.redo()));

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
    `V: ${graph.vertices.size} | E: ${graph.edges.size} | F: ${faces.filter(f => !f.outer).length} | T: 0`;
  document.getElementById('status-tool').textContent =
    `Tool: ${activeTool.name} | Snap: ON`;
}

// Render loop
function frame() {
  snap = activeTool.getSnap?.() || null;
  renderer.render(graph, faces, null, snap, activeTool);

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
