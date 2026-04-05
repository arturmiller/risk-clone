import { useRef, useState, useCallback } from 'react';
import { useEditorStore } from '../store';
import GridCell from './GridCell';

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
  const lastMouse = useRef({ x: 0, y: 0 });

  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? 0.9 : 1.1;
    setZoom((z) => Math.min(5, Math.max(0.2, z * delta)));
  }, []);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button === 1 || (e.button === 0 && e.altKey)) {
      e.preventDefault();
      setIsPanning(true);
      lastMouse.current = { x: e.clientX, y: e.clientY };
    }
  }, []);

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

  return (
    <div
      className="canvas"
      onClick={() => selectElement(null)}
      onWheel={handleWheel}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      style={{ cursor: isPanning ? 'grabbing' : undefined }}
    >
      <div
        className={`canvas-frame ${isMobile ? 'frame-mobile' : 'frame-desktop'}`}
        style={{
          width: frameWidth,
          height: frameHeight,
          transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
          transformOrigin: 'center center',
        }}
      >
        <GridCell element={layout.root} />
      </div>
      <div className="canvas-zoom-info">
        {Math.round(zoom * 100)}%
      </div>
    </div>
  );
}
