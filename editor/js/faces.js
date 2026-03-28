// editor/js/faces.js

let nextFaceId = 0;

export function findFaces(graph) {
  nextFaceId = 0;
  const faces = [];

  const halfEdges = [];
  for (const [eid, edge] of graph.edges) {
    const verts = edge.vertices;
    const first = verts[0];
    const last = verts[verts.length - 1];
    if (first === last) continue;

    const vFirst = graph.vertices.get(first);
    const vLast = graph.vertices.get(last);
    if (!vFirst || !vLast) continue;

    const vSecond = graph.vertices.get(verts[1]);
    const vSecondLast = graph.vertices.get(verts[verts.length - 2]);

    // Forward half-edge: first→last, angle based on first segment
    halfEdges.push({
      from: first, to: last, edgeId: eid, forward: true,
      angle: Math.atan2(vSecond.y - vFirst.y, vSecond.x - vFirst.x),
    });
    // Backward half-edge: last→first, angle based on last segment
    halfEdges.push({
      from: last, to: first, edgeId: eid, forward: false,
      angle: Math.atan2(vSecondLast.y - vLast.y, vSecondLast.x - vLast.x),
    });
  }

  const byVertex = new Map();
  for (const he of halfEdges) {
    if (!byVertex.has(he.from)) byVertex.set(he.from, []);
    byVertex.get(he.from).push(he);
  }
  for (const [, list] of byVertex) {
    list.sort((a, b) => a.angle - b.angle);
  }

  const nextMap = new Map();
  const heKey = (he) => `${he.edgeId}:${he.forward}`;

  for (const he of halfEdges) {
    const siblings = byVertex.get(he.to);
    if (!siblings || siblings.length === 0) continue;

    let idx = -1;
    for (let i = 0; i < siblings.length; i++) {
      if (siblings[i].edgeId === he.edgeId && siblings[i].forward !== he.forward) {
        idx = i;
        break;
      }
    }

    if (idx === -1) continue;

    const nextIdx = (idx - 1 + siblings.length) % siblings.length;
    nextMap.set(heKey(he), siblings[nextIdx]);
  }

  const visited = new Set();

  for (const he of halfEdges) {
    const key = heKey(he);
    if (visited.has(key)) continue;

    const cycle = [];
    let current = he;
    let steps = 0;
    const maxSteps = halfEdges.length + 1;

    while (steps < maxSteps) {
      const k = heKey(current);
      if (visited.has(k)) break;
      visited.add(k);
      cycle.push({ edgeId: current.edgeId, forward: current.forward });

      const next = nextMap.get(k);
      if (!next) break;
      if (heKey(next) === heKey(he)) break;
      current = next;
      steps++;
    }

    if (cycle.length >= 3) {
      const points = resolvePoints(graph, cycle);
      const area = signedArea(points);
      faces.push({
        id: 'f' + (nextFaceId++),
        edgeRefs: cycle,
        points,
        outer: area > 0,
      });
    }
  }

  return faces;
}

function resolvePoints(graph, edgeRefs) {
  const points = [];
  for (const ref of edgeRefs) {
    const edge = graph.edges.get(ref.edgeId);
    if (!edge) continue;
    const verts = ref.forward ? edge.vertices : [...edge.vertices].reverse();
    const start = points.length === 0 ? 0 : 1;
    for (let i = start; i < verts.length; i++) {
      const v = graph.vertices.get(verts[i]);
      if (v) points.push({ x: v.x, y: v.y });
    }
  }
  return points;
}

function signedArea(points) {
  let area = 0;
  for (let i = 0; i < points.length; i++) {
    const j = (i + 1) % points.length;
    area += points[i].x * points[j].y;
    area -= points[j].x * points[i].y;
  }
  return area / 2;
}
