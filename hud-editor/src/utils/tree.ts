import { HudElement, GridElement } from '../types';

/** Find an element by ID in the tree. Returns the element or undefined. */
export function findById(root: HudElement, id: string): HudElement | undefined {
  if (root.id === id) return root;
  if ('children' in root && root.children) {
    for (const child of root.children) {
      const found = findById(child, id);
      if (found) return found;
    }
  }
  return undefined;
}

/** Find the parent grid of an element by ID. Returns [parent, childIndex] or undefined. */
export function findParent(
  root: HudElement,
  id: string,
): [GridElement, number] | undefined {
  if ('children' in root && root.children) {
    const grid = root as GridElement;
    for (let i = 0; i < grid.children.length; i++) {
      if (grid.children[i].id === id) return [grid, i];
      const found = findParent(grid.children[i], id);
      if (found) return found;
    }
  }
  return undefined;
}

/** Deep clone an element tree, replacing IDs with new ones via the replacer function. */
export function cloneElement(
  element: HudElement,
  newId: (oldId: string) => string,
): HudElement {
  const cloned = { ...element, id: newId(element.id) };
  if ('children' in cloned && cloned.children) {
    (cloned as GridElement).children = cloned.children.map((c) =>
      cloneElement(c, newId),
    );
  }
  return cloned;
}

/** Replace an element by ID in the tree (immutable — returns new tree). */
export function replaceById(
  root: HudElement,
  id: string,
  replacement: HudElement,
): HudElement {
  if (root.id === id) return replacement;
  if ('children' in root && root.children) {
    const grid = root as GridElement;
    return {
      ...grid,
      children: grid.children.map((c) => replaceById(c, id, replacement)),
    };
  }
  return root;
}

/** Remove an element by ID from the tree (immutable). */
export function removeById(root: HudElement, id: string): HudElement {
  if ('children' in root && root.children) {
    const grid = root as GridElement;
    return {
      ...grid,
      children: grid.children
        .filter((c) => c.id !== id)
        .map((c) => removeById(c, id)),
    };
  }
  return root;
}

/** Insert an element as child of target grid (immutable). */
export function insertIntoGrid(
  root: HudElement,
  gridId: string,
  element: HudElement,
): HudElement {
  if (root.id === gridId && root.type === 'grid') {
    const grid = root as GridElement;
    return { ...grid, children: [...grid.children, element] };
  }
  if ('children' in root && root.children) {
    const grid = root as GridElement;
    return {
      ...grid,
      children: grid.children.map((c) => insertIntoGrid(c, gridId, element)),
    };
  }
  return root;
}

/** Collect all element IDs in the tree. */
export function collectIds(root: HudElement): Set<string> {
  const ids = new Set<string>([root.id]);
  if ('children' in root && root.children) {
    for (const child of root.children) {
      for (const id of collectIds(child)) {
        ids.add(id);
      }
    }
  }
  return ids;
}
