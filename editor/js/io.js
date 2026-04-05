// editor/js/io.js
import { PlanarGraph } from './graph.js';
import { TerritoryManager } from './territories.js';

export function saveEditorJson(graph, territories, mapWidth, mapHeight) {
  const data = {
    name: 'Untitled Map',
    canvasSize: [mapWidth, mapHeight],
    vertices: {},
    edges: {},
    territories: {},
    continents: {},
    manualAdjacencies: territories.manualAdjacencies,
    manualNonAdjacencies: territories.manualNonAdjacencies,
  };

  for (const [id, v] of graph.vertices) {
    data.vertices[id] = [Math.round(v.x * 10) / 10, Math.round(v.y * 10) / 10];
  }
  for (const [id, e] of graph.edges) {
    data.edges[id] = e.vertices;
  }
  for (const [name, t] of territories.territories) {
    data.territories[name] = {
      faceId: t.faceId,
      color: t.color,
      labelPosition: [Math.round(t.labelPosition.x), Math.round(t.labelPosition.y)],
    };
  }
  for (const [name, c] of territories.continents) {
    data.continents[name] = { bonus: c.bonus, territories: [...c.territories] };
  }

  return JSON.stringify(data, null, 2);
}

export function loadEditorJson(json) {
  const data = JSON.parse(json);
  const graph = new PlanarGraph();

  let maxV = 0, maxE = 0;
  for (const id of Object.keys(data.vertices)) {
    const n = parseInt(id.slice(1));
    if (n >= maxV) maxV = n + 1;
  }
  for (const id of Object.keys(data.edges)) {
    const n = parseInt(id.slice(1));
    if (n >= maxE) maxE = n + 1;
  }
  PlanarGraph.resetIds(maxV, maxE);

  for (const [id, coords] of Object.entries(data.vertices)) {
    graph.vertices.set(id, { x: coords[0], y: coords[1] });
  }
  for (const [id, verts] of Object.entries(data.edges)) {
    graph.edges.set(id, { vertices: [...verts] });
  }

  const territories = new TerritoryManager();
  for (const [name, t] of Object.entries(data.territories || {})) {
    territories.addTerritory(name, t.faceId, t.color, { x: t.labelPosition[0], y: t.labelPosition[1] });
  }
  for (const [name, c] of Object.entries(data.continents || {})) {
    territories.addContinent(name, c.bonus);
    territories.continents.get(name).territories = [...c.territories];
  }
  territories.manualAdjacencies = (data.manualAdjacencies || []).map(p => [...p]);
  territories.manualNonAdjacencies = (data.manualNonAdjacencies || []).map(p => [...p]);

  return { graph, territories, mapWidth: data.canvasSize?.[0] || 1200, mapHeight: data.canvasSize?.[1] || 700 };
}

export function exportGameJson(graph, faces, territories, mapWidth, mapHeight) {
  const data = {
    name: 'Untitled Map',
    canvasSize: [mapWidth, mapHeight],
    territories: {},
    continents: [],
    adjacencies: territories.computeAdjacencies(faces),
  };

  for (const [name, t] of territories.territories) {
    const face = faces.find(f => f.id === t.faceId);
    if (!face) continue;
    data.territories[name] = {
      path: face.points.map(p => [Math.round(p.x), Math.round(p.y)]),
      color: t.color,
      labelPosition: [Math.round(t.labelPosition.x), Math.round(t.labelPosition.y)],
    };
  }

  for (const [name, c] of territories.continents) {
    data.continents.push({ name, bonus: c.bonus, territories: [...c.territories] });
  }

  return JSON.stringify(data, null, 2);
}

export function downloadJson(content, filename) {
  const blob = new Blob([content], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
