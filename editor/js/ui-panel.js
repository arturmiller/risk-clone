// editor/js/ui-panel.js

export function updateTerritoryList(territories, faces, onSelect) {
  const container = document.getElementById('territory-list');
  container.innerHTML = '';

  if (territories.territories.size === 0) {
    container.innerHTML = '<div style="color:#666;font-size:11px;text-align:center;padding:8px">Use Territory tool (T) to confirm faces</div>';
    return;
  }

  for (const [name, t] of territories.territories) {
    const item = document.createElement('div');
    item.className = 'territory-item';
    item.innerHTML = `
      <span class="color-dot" style="background:${t.color}"></span>
      <span class="name">${name}</span>
    `;
    item.addEventListener('click', () => onSelect(name));
    container.appendChild(item);
  }
}

export function updateContinentList(territories, onChange) {
  const container = document.getElementById('continent-list');
  container.innerHTML = '';

  for (const [name, cont] of territories.continents) {
    const item = document.createElement('div');
    item.className = 'continent-item';
    item.innerHTML = `
      <div class="header">
        <input type="text" value="${name}" data-continent="${name}" class="continent-name">
        <div>
          Bonus: <input type="number" value="${cont.bonus}" min="0" max="20" class="bonus-input" data-continent="${name}">
          <button data-delete="${name}" style="width:auto;padding:2px 6px;font-size:10px;">&#10005;</button>
        </div>
      </div>
      <div class="territories">${cont.territories.length > 0 ? cont.territories.join(', ') : '<em>No territories assigned</em>'}</div>
    `;
    container.appendChild(item);

    item.querySelector('.continent-name').addEventListener('change', e => {
      const oldName = e.target.dataset.continent;
      const newName = e.target.value.trim();
      if (newName && newName !== oldName) {
        const data = territories.continents.get(oldName);
        territories.continents.delete(oldName);
        territories.continents.set(newName, data);
        onChange();
      }
    });

    item.querySelector('.bonus-input').addEventListener('change', e => {
      const contName = e.target.dataset.continent;
      const c = territories.continents.get(contName);
      if (c) c.bonus = parseInt(e.target.value) || 0;
      onChange();
    });

    item.querySelector('[data-delete]').addEventListener('click', e => {
      const contName = e.target.dataset.delete;
      territories.continents.delete(contName);
      onChange();
    });
  }
}

export function updateAdjacencyList(territories, faces, onChange) {
  const container = document.getElementById('adjacency-list');
  const adjacencies = territories.computeAdjacencies(faces);
  container.innerHTML = '';

  if (adjacencies.length === 0) {
    container.innerHTML = '<div style="color:#666;font-size:11px;text-align:center;padding:8px">No adjacencies yet</div>';
    return;
  }

  for (const [a, b] of adjacencies) {
    const item = document.createElement('div');
    item.style.cssText = 'font-size:11px;padding:2px 4px;display:flex;justify-content:space-between;align-items:center;';
    const isManual = territories.manualAdjacencies.some(
      p => (p[0] === a && p[1] === b) || (p[0] === b && p[1] === a)
    );
    item.innerHTML = `
      <span>${a} &#8596; ${b} ${isManual ? '(manual)' : ''}</span>
      <button style="width:auto;padding:1px 4px;font-size:9px;" data-remove-adj="${a}|${b}">&#10005;</button>
    `;
    item.querySelector('[data-remove-adj]').addEventListener('click', e => {
      const [ra, rb] = e.target.dataset.removeAdj.split('|');
      const manIdx = territories.manualAdjacencies.findIndex(
        p => (p[0] === ra && p[1] === rb) || (p[0] === rb && p[1] === ra)
      );
      if (manIdx !== -1) {
        territories.manualAdjacencies.splice(manIdx, 1);
      } else {
        territories.manualNonAdjacencies.push([ra, rb]);
      }
      onChange();
    });
    container.appendChild(item);
  }
}

export function setupPanelEvents(territories, onChange) {
  document.getElementById('btn-add-continent').addEventListener('click', () => {
    const name = prompt('Continent name:');
    if (!name) return;
    const bonus = parseInt(prompt('Army bonus:', '2')) || 0;
    territories.addContinent(name, bonus);
    onChange();
  });

  document.getElementById('btn-add-adjacency').addEventListener('click', () => {
    const names = [...territories.territories.keys()];
    const a = prompt('First territory:\n\nAvailable: ' + names.join(', '));
    if (!a || !territories.territories.has(a)) { alert('Territory not found'); return; }
    const b = prompt('Second territory:');
    if (!b || !territories.territories.has(b)) { alert('Territory not found'); return; }
    territories.manualAdjacencies.push([a, b]);
    onChange();
  });
}
