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
