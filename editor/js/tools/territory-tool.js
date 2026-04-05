// editor/js/tools/territory-tool.js
import { pointInPolygon } from '../snap.js';
import { TerritoryManager } from '../territories.js';

export class TerritoryTool {
  constructor(renderer, graph, getFaces, territories, onChange) {
    this.renderer = renderer;
    this.graph = graph;
    this.getFaces = getFaces;
    this.territories = territories;
    this.onChange = onChange;
    this._dialog = null;
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

    const allFaces = this.getFaces();
    const innerFaces = allFaces.filter(f => !f.outer);
    console.log(`[TerritoryTool] Click at (${Math.round(mapPt.x)}, ${Math.round(mapPt.y)}). Faces: ${allFaces.length} total, ${innerFaces.length} inner`);
    for (const face of innerFaces) {
      const hit = pointInPolygon(mapPt, face.points);
      const terr = this.territories.getByFaceId(face.id);
      console.log(`  ${face.id}: hit=${hit}, territory=${terr?.name || 'none'}, points=${face.points.length}`);
    }

    for (const face of this.getFaces()) {
      if (face.outer) continue;
      if (pointInPolygon(mapPt, face.points)) {
        const existing = this.territories.getByFaceId(face.id);
        if (existing) {
          this._showDialog(existing.name, existing.color, (name, color) => {
            if (name !== existing.name) {
              this.territories.renameTerritory(existing.name, name);
            }
            this.territories.territories.get(name).color = color;
            if (this.onChange) this.onChange();
          });
        } else {
          const defaultColor = TerritoryManager.randomColor();
          this._showDialog('', defaultColor, (name, color) => {
            const cx = face.points.reduce((s, p) => s + p.x, 0) / face.points.length;
            const cy = face.points.reduce((s, p) => s + p.y, 0) / face.points.length;
            this.territories.addTerritory(name, face.id, color, { x: cx, y: cy });
            if (this.onChange) this.onChange();
          });
        }
        return;
      }
    }
  }

  _handleRightClick(e) {
    e.preventDefault();
    const rect = this.renderer.canvas.getBoundingClientRect();
    const mapPt = this.renderer.screenToMap(e.clientX - rect.left, e.clientY - rect.top);

    for (const face of this.getFaces()) {
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

  _showDialog(currentName, currentColor, onConfirm) {
    this._closeDialog();
    const overlay = document.createElement('div');
    overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.5);z-index:1000;display:flex;align-items:center;justify-content:center;';
    const dialog = document.createElement('div');
    dialog.style.cssText = 'background:#1a1a2e;border:1px solid #444;border-radius:8px;padding:20px;min-width:280px;color:#ccc;font-family:sans-serif;';
    dialog.innerHTML = `
      <h3 style="margin:0 0 16px;color:#eee;font-size:14px;">${currentName ? 'Edit Territory' : 'New Territory'}</h3>
      <div style="margin-bottom:12px;">
        <label style="display:block;font-size:12px;margin-bottom:4px;">Name</label>
        <input type="text" class="td-name" value="${currentName}" style="width:100%;box-sizing:border-box;padding:6px 8px;background:#0f3460;color:#eee;border:1px solid #555;border-radius:4px;font-size:13px;">
      </div>
      <div style="margin-bottom:16px;">
        <label style="display:block;font-size:12px;margin-bottom:4px;">Color</label>
        <div style="display:flex;align-items:center;gap:8px;">
          <input type="color" class="td-color" value="${currentColor}" style="width:48px;height:32px;border:1px solid #555;border-radius:4px;background:none;cursor:pointer;padding:0;">
          <span class="td-color-hex" style="font-size:12px;color:#999;">${currentColor}</span>
        </div>
      </div>
      <div style="display:flex;gap:8px;justify-content:flex-end;">
        <button class="td-cancel" style="padding:6px 14px;background:#333;color:#ccc;border:1px solid #555;border-radius:4px;cursor:pointer;">Cancel</button>
        <button class="td-ok" style="padding:6px 14px;background:#1E88E5;color:#fff;border:none;border-radius:4px;cursor:pointer;">OK</button>
      </div>
    `;
    overlay.appendChild(dialog);
    document.body.appendChild(overlay);
    this._dialog = overlay;

    const nameInput = dialog.querySelector('.td-name');
    const colorInput = dialog.querySelector('.td-color');
    const colorHex = dialog.querySelector('.td-color-hex');

    nameInput.focus();
    nameInput.select();

    colorInput.addEventListener('input', () => {
      colorHex.textContent = colorInput.value;
    });

    const close = () => { this._closeDialog(); };

    dialog.querySelector('.td-cancel').addEventListener('click', close);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) close(); });

    const confirm = () => {
      const name = nameInput.value.trim();
      if (!name) { nameInput.focus(); return; }
      const color = colorInput.value;
      close();
      onConfirm(name, color);
    };

    dialog.querySelector('.td-ok').addEventListener('click', confirm);
    nameInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') confirm();
      if (e.key === 'Escape') close();
    });
  }

  _closeDialog() {
    if (this._dialog) {
      this._dialog.remove();
      this._dialog = null;
    }
  }

  onMouseMove() {}
  onMouseUp() {}
  onKeyDown() {}
  onKeyUp() {}
  getSnap() { return null; }
}
