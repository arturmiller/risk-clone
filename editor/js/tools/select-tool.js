// editor/js/tools/select-tool.js
import { findSnap } from '../snap.js';

export class SelectTool {
  constructor(renderer, graph, onChange) {
    this.renderer = renderer;
    this.graph = graph;
    this.onChange = onChange;
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

  getSelection() {
    return { vertexId: this.selectedVertex, edgeId: this.selectedEdge };
  }
}
