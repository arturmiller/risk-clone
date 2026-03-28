// editor/js/snap.js

export function findSnap(graph, mapPoint, threshold, renderer) {
  const mapThreshold = threshold / renderer.zoom;
  let bestDist = mapThreshold;
  let best = null;

  for (const [vid, v] of graph.vertices) {
    const d = Math.hypot(v.x - mapPoint.x, v.y - mapPoint.y);
    if (d < bestDist) {
      bestDist = d;
      best = { type: 'vertex', x: v.x, y: v.y, vertexId: vid };
    }
  }

  if (best) return best;

  for (const [eid, edge] of graph.edges) {
    const verts = edge.vertices;
    for (let i = 0; i < verts.length - 1; i++) {
      const a = graph.vertices.get(verts[i]);
      const b = graph.vertices.get(verts[i + 1]);
      if (!a || !b) continue;
      const closest = closestPointOnSegment(mapPoint, a, b);
      const d = Math.hypot(closest.x - mapPoint.x, closest.y - mapPoint.y);
      if (d < bestDist) {
        bestDist = d;
        best = { type: 'edge', x: closest.x, y: closest.y, edgeId: eid, segmentIndex: i };
      }
    }
  }

  return best;
}

function closestPointOnSegment(p, a, b) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lenSq = dx * dx + dy * dy;
  if (lenSq === 0) return { x: a.x, y: a.y };
  let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));
  return { x: a.x + t * dx, y: a.y + t * dy };
}

export function pointInPolygon(point, polygon) {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].x, yi = polygon[i].y;
    const xj = polygon[j].x, yj = polygon[j].y;
    if (((yi > point.y) !== (yj > point.y)) &&
        (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}
