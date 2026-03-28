// editor/js/graph.js
let nextVertexId = 0;
let nextEdgeId = 0;

export class PlanarGraph {
  constructor() {
    this.vertices = new Map();
    this.edges = new Map();
  }

  addVertex(x, y) {
    const id = 'v' + (nextVertexId++);
    this.vertices.set(id, { x, y });
    return id;
  }

  removeVertex(id) {
    const toRemove = [];
    for (const [eid, edge] of this.edges) {
      if (edge.vertices.includes(id)) toRemove.push(eid);
    }
    for (const eid of toRemove) this.edges.delete(eid);
    this.vertices.delete(id);
    return toRemove;
  }

  moveVertex(id, x, y) {
    const v = this.vertices.get(id);
    if (v) { v.x = x; v.y = y; }
  }

  addEdge(vertexIds) {
    if (vertexIds.length < 2) return null;
    for (const vid of vertexIds) {
      if (!this.vertices.has(vid)) return null;
    }
    const id = 'e' + (nextEdgeId++);
    this.edges.set(id, { vertices: [...vertexIds] });
    return id;
  }

  removeEdge(id) {
    const edge = this.edges.get(id);
    this.edges.delete(id);
    return edge;
  }

  splitEdge(edgeId, segmentIndex, x, y) {
    const edge = this.edges.get(edgeId);
    if (!edge) return null;
    const vid = this.addVertex(x, y);
    const verts = edge.vertices;
    const leftVerts = verts.slice(0, segmentIndex + 1).concat(vid);
    const rightVerts = [vid].concat(verts.slice(segmentIndex + 1));
    this.edges.delete(edgeId);
    const eid1 = this.addEdge(leftVerts);
    const eid2 = this.addEdge(rightVerts);
    return { vertexId: vid, newEdgeIds: [eid1, eid2], oldEdge: edge };
  }

  edgesOf(vertexId) {
    const result = [];
    for (const [eid, edge] of this.edges) {
      if (edge.vertices.includes(vertexId)) result.push(eid);
    }
    return result;
  }

  adjacentEndpoints(vertexId) {
    const neighbors = [];
    for (const [eid, edge] of this.edges) {
      const verts = edge.vertices;
      const first = verts[0];
      const last = verts[verts.length - 1];
      if (first === vertexId) neighbors.push({ edgeId: eid, to: last, forward: true });
      if (last === vertexId) neighbors.push({ edgeId: eid, to: first, forward: false });
    }
    return neighbors;
  }

  clone() {
    const g = new PlanarGraph();
    for (const [id, v] of this.vertices) g.vertices.set(id, { ...v });
    for (const [id, e] of this.edges) g.edges.set(id, { vertices: [...e.vertices] });
    return g;
  }

  static resetIds(vMax, eMax) {
    nextVertexId = vMax;
    nextEdgeId = eMax;
  }
}
