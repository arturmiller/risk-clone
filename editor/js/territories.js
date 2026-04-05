// editor/js/territories.js
export class TerritoryManager {
  constructor() {
    this.territories = new Map();
    this.continents = new Map();
    this.manualAdjacencies = [];
    this.manualNonAdjacencies = [];
  }

  addTerritory(name, faceId, color, labelPosition) {
    this.territories.set(name, { faceId, color, labelPosition });
  }

  removeTerritory(name) {
    this.territories.delete(name);
    for (const [, cont] of this.continents) {
      const idx = cont.territories.indexOf(name);
      if (idx !== -1) cont.territories.splice(idx, 1);
    }
  }

  renameTerritory(oldName, newName) {
    const t = this.territories.get(oldName);
    if (!t) return;
    this.territories.delete(oldName);
    this.territories.set(newName, t);
    for (const [, cont] of this.continents) {
      const idx = cont.territories.indexOf(oldName);
      if (idx !== -1) cont.territories[idx] = newName;
    }
    const updateAdj = (list) => {
      for (const pair of list) {
        if (pair[0] === oldName) pair[0] = newName;
        if (pair[1] === oldName) pair[1] = newName;
      }
    };
    updateAdj(this.manualAdjacencies);
    updateAdj(this.manualNonAdjacencies);
  }

  getByFaceId(faceId) {
    for (const [name, t] of this.territories) {
      if (t.faceId === faceId) return { name, ...t };
    }
    return null;
  }

  addContinent(name, bonus) {
    this.continents.set(name, { bonus, territories: [] });
  }

  removeContinent(name) {
    this.continents.delete(name);
  }

  computeAdjacencies(faces) {
    const auto = new Set();
    const faceByEdge = new Map();
    for (const face of faces) {
      if (face.outer) continue;
      for (const ref of face.edgeRefs) {
        if (!faceByEdge.has(ref.edgeId)) faceByEdge.set(ref.edgeId, []);
        faceByEdge.get(ref.edgeId).push(face.id);
      }
    }
    for (const [, faceIds] of faceByEdge) {
      if (faceIds.length !== 2) continue;
      const t1 = this.getByFaceId(faceIds[0]);
      const t2 = this.getByFaceId(faceIds[1]);
      if (t1 && t2 && t1.name !== t2.name) {
        const key = [t1.name, t2.name].sort().join('|');
        auto.add(key);
      }
    }
    for (const [a, b] of this.manualAdjacencies) {
      auto.add([a, b].sort().join('|'));
    }
    for (const [a, b] of this.manualNonAdjacencies) {
      auto.delete([a, b].sort().join('|'));
    }
    return [...auto].map(k => k.split('|'));
  }

  clone() {
    const tm = new TerritoryManager();
    for (const [n, t] of this.territories) {
      tm.territories.set(n, { ...t, labelPosition: { ...t.labelPosition } });
    }
    for (const [n, c] of this.continents) {
      tm.continents.set(n, { bonus: c.bonus, territories: [...c.territories] });
    }
    tm.manualAdjacencies = this.manualAdjacencies.map(p => [...p]);
    tm.manualNonAdjacencies = this.manualNonAdjacencies.map(p => [...p]);
    return tm;
  }

  static randomColor() {
    const colors = [
      '#E53935', '#1E88E5', '#43A047', '#FDD835',
      '#8E24AA', '#FF7043', '#00ACC1', '#3949AB',
      '#7CB342', '#F4511E', '#6D4C41', '#546E7A',
    ];
    return colors[Math.floor(Math.random() * colors.length)];
  }
}
