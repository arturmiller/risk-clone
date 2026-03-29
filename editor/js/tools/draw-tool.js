// editor/js/tools/draw-tool.js
import { findSnap } from '../snap.js';

export class DrawTool {
  constructor(renderer, graph, onComplete) {
    this.renderer = renderer;
    this.graph = graph;
    this.onComplete = onComplete;
    this.currentVertices = [];
    this.previewPoint = null;
    this.snapResult = null;
    this.graphSnapshotBeforeDraw = null;
  }

  get name() { return 'draw'; }
  get cursor() { return 'crosshair'; }

  onMouseDown(e) {
    if (e.button !== 0) return;
    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);

    if (this.currentVertices.length === 0) {
      this.graphSnapshotBeforeDraw = {
        vertices: new Map([...this.graph.vertices].map(([id, v]) => [id, {...v}])),
        edges: new Map([...this.graph.edges].map(([id, e]) => [id, {vertices: [...e.vertices]}])),
      };
    }

    let vid;
    const snap = findSnap(this.graph, mapPt, 8, this.renderer);

    if (snap?.type === 'vertex') {
      vid = snap.vertexId;
      if (this.currentVertices.length >= 2 && vid === this.currentVertices[0]) {
        // Add the closing edge from last vertex back to start
        const prev = this.currentVertices[this.currentVertices.length - 1];
        if (prev !== vid) {
          this.graph.addEdge([prev, vid]);
        }
        this.currentVertices.push(vid);
        this._finishPolyline();
        return;
      }
    } else if (snap?.type === 'edge') {
      const result = this.graph.splitEdge(snap.edgeId, snap.segmentIndex, snap.x, snap.y);
      if (result) vid = result.vertexId;
    }

    if (!vid) {
      vid = this.graph.addVertex(mapPt.x, mapPt.y);
    }

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
    this.graphSnapshotBeforeDraw = null;
    if (this.onComplete) this.onComplete(this.currentVertices);
    this.currentVertices = [];
  }

  _cancel() {
    if (this.graphSnapshotBeforeDraw) {
      this.graph.vertices.clear();
      this.graph.edges.clear();
      for (const [id, v] of this.graphSnapshotBeforeDraw.vertices) this.graph.vertices.set(id, {...v});
      for (const [id, e] of this.graphSnapshotBeforeDraw.edges) this.graph.edges.set(id, {vertices: [...e.vertices]});
      this.graphSnapshotBeforeDraw = null;
    }
    this.currentVertices = [];
  }

  getSnap() {
    return this.snapResult ? { x: this.snapResult.x, y: this.snapResult.y } : null;
  }

  getPreviewLine() {
    if (this.currentVertices.length === 0 || !this.previewPoint) return null;
    const lastVid = this.currentVertices[this.currentVertices.length - 1];
    const lastV = this.graph.vertices.get(lastVid);
    if (!lastV) return null;
    const target = this.snapResult || this.previewPoint;
    return { from: lastV, to: { x: target.x, y: target.y } };
  }
}
