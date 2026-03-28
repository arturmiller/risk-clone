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
