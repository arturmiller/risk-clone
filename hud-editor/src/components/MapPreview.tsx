import { useEffect, useRef, useState } from 'react';

interface Territory {
  path: number[][];
  color?: string;
}

interface MapData {
  canvasSize: [number, number];
  territories: Record<string, Territory>;
}

export default function MapPreview({ width, height }: { width: number; height: number }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [mapData, setMapData] = useState<MapData | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch('/map/original.json')
      .then((r) => {
        if (r.ok) return r.json();
        throw new Error(`${r.status}`);
      })
      .then((data) => setMapData(data))
      .catch((e) => setError(e.message));
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !mapData) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const [mapW, mapH] = mapData.canvasSize;

    const scaleX = width / mapW;
    const scaleY = height / mapH;

    ctx.clearRect(0, 0, width, height);

    // Ocean background
    ctx.fillStyle = '#1a2a3a';
    ctx.fillRect(0, 0, width, height);

    // Draw territories
    const entries = Object.entries(mapData.territories);
    for (const [, territory] of entries) {
      if (!territory.path || territory.path.length < 3) continue;

      ctx.beginPath();
      ctx.moveTo(territory.path[0][0] * scaleX, territory.path[0][1] * scaleY);
      for (let i = 1; i < territory.path.length; i++) {
        ctx.lineTo(territory.path[i][0] * scaleX, territory.path[i][1] * scaleY);
      }
      ctx.closePath();

      ctx.globalAlpha = 0.7;
      ctx.fillStyle = territory.color || '#CFD8DC';
      ctx.fill();

      ctx.globalAlpha = 0.9;
      ctx.strokeStyle = '#546E7A';
      ctx.lineWidth = 1;
      ctx.stroke();
    }

    ctx.globalAlpha = 1;
  }, [mapData, width, height]);

  if (error) {
    return (
      <div style={{
        position: 'absolute', inset: 0, zIndex: 0,
        background: '#1a2a3a',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: '#666', fontSize: 12,
      }}>
        Karte nicht geladen: {error}
      </div>
    );
  }

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: `${width}px`,
        height: `${height}px`,
        zIndex: 0,
      }}
    />
  );
}
