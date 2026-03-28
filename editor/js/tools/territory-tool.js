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
      this._handleRightClick(e);
      return;
    }
    if (e.button !== 0) return;

    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);

    for (const face of this.faces) {
      if (face.outer) continue;
      if (pointInPolygon(mapPt, face.points)) {
        const existing = this.territories.getByFaceId(face.id);
        if (existing) {
          const newName = prompt('Territory name:', existing.name);
          if (newName && newName !== existing.name) {
            this.territories.renameTerritory(existing.name, newName);
          }
          const newColor = prompt('Color (hex):', existing.color);
          if (newColor) {
            this.territories.territories.get(newName || existing.name).color = newColor;
          }
        } else {
          const name = prompt('Territory name:');
          if (!name) return;
          const color = TerritoryManager.randomColor();
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
