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

  screenToMap(sx, sy) {
    return {
      x: (sx - this.offsetX) / this.zoom,
      y: (sy - this.offsetY) / this.zoom,
    };
  }

  mapToScreen(mx, my) {
    return {
      x: mx * this.zoom + this.offsetX,
      y: my * this.zoom + this.offsetY,
    };
  }

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
          ctx.fillStyle = territory.color + '66';
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
