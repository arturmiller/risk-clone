import { useRef, useState, useCallback } from 'react';
import { useEditorStore } from '../store';
import GridCell from './GridCell';

type CanvasTool = 'pointer' | 'hand';

export default function Canvas() {
  const layout = useEditorStore((s) => s.layout);
  const layoutMode = useEditorStore((s) => s.layoutMode);
  const selectElement = useEditorStore((s) => s.selectElement);

  const isMobile = layoutMode === 'mobile-landscape';
  const frameWidth = isMobile ? 844 : 800;
  const frameHeight = isMobile ? 390 : 500;

  const [zoom, setZoom] = useState(1);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [isPanning, setIsPanning] = useState(false);
  const [tool, setTool] = useState<CanvasTool>('pointer');
  const [preview, setPreview] = useState(false);
  const lastMouse = useRef({ x: 0, y: 0 });

  const zoomIn = useCallback(() => {
    setZoom((z) => Math.min(5, z * 1.25));
  }, []);

  const zoomOut = useCallback(() => {
    setZoom((z) => Math.max(0.2, z * 0.8));
  }, []);

  const resetView = useCallback(() => {
    setZoom(1);
    setPan({ x: 0, y: 0 });
  }, []);

  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? 0.9 : 1.1;
    setZoom((z) => Math.min(5, Math.max(0.2, z * delta)));
  }, []);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button === 1) {
      e.preventDefault();
      setIsPanning(true);
      lastMouse.current = { x: e.clientX, y: e.clientY };
      return;
    }
    if (e.button === 0 && (tool === 'hand' || e.altKey || preview)) {
      e.preventDefault();
      setIsPanning(true);
      lastMouse.current = { x: e.clientX, y: e.clientY };
    }
  }, [tool, preview]);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isPanning) return;
    const dx = e.clientX - lastMouse.current.x;
    const dy = e.clientY - lastMouse.current.y;
    lastMouse.current = { x: e.clientX, y: e.clientY };
    setPan((p) => ({ x: p.x + dx, y: p.y + dy }));
  }, [isPanning]);

  const handleMouseUp = useCallback(() => {
    setIsPanning(false);
  }, []);

  const handleCanvasClick = useCallback(() => {
    if (tool === 'pointer' && !preview) selectElement(null);
  }, [tool, preview, selectElement]);

  const cursor = isPanning
    ? 'grabbing'
    : (tool === 'hand' || preview)
      ? 'grab'
      : undefined;

  return (
    <div
      className="canvas"
      onClick={handleCanvasClick}
      onWheel={handleWheel}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      style={{ cursor }}
    >
      <div
        className={`canvas-frame ${isMobile ? 'frame-mobile' : 'frame-desktop'} ${preview ? 'preview-mode' : ''}`}
        style={{
          width: frameWidth,
          height: frameHeight,
          transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
          transformOrigin: 'center center',
          pointerEvents: (tool === 'hand' || preview) ? 'none' : undefined,
        }}
      >
        {preview && (
          <div className="preview-map-bg">
            <span className="preview-map-label">🗺️ Karte</span>
          </div>
        )}
        <GridCell element={layout.root} />
      </div>
      <div className="canvas-controls">
        {!preview && (
          <>
            <button
              className={`canvas-ctrl-btn ${tool === 'pointer' ? 'active' : ''}`}
              onClick={() => setTool('pointer')}
              title="Pointer"
            >
              ↖
            </button>
            <button
              className={`canvas-ctrl-btn ${tool === 'hand' ? 'active' : ''}`}
              onClick={() => setTool('hand')}
              title="Hand"
            >
              ✋
            </button>
            <div className="canvas-ctrl-divider" />
          </>
        )}
        <button className="canvas-ctrl-btn" onClick={zoomIn} title="Zoom in">+</button>
        <button className="canvas-ctrl-btn" onClick={zoomOut} title="Zoom out">−</button>
        <button className="canvas-ctrl-btn" onClick={resetView} title="Reset view">⊡</button>
        <span className="canvas-ctrl-zoom">{Math.round(zoom * 100)}%</span>
        <div className="canvas-ctrl-divider" />
        <button
          className={`canvas-ctrl-btn ${preview ? 'active' : ''}`}
          onClick={() => setPreview((v) => !v)}
          title="Preview"
        >
          👁
        </button>
      </div>
    </div>
  );
}
