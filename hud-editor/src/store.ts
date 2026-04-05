import { create } from 'zustand';
import {
  HudLayout,
  HudElement,
  GridElement,
  ElementType,
  HudTheme,
} from './types';
import { generateId } from './utils/id';
import {
  findById,
  replaceById,
  removeById,
  insertIntoGrid,
  cloneElement,
} from './utils/tree';

export type LayoutMode = 'mobile-landscape' | 'desktop-landscape';

interface ContextMenuState {
  x: number;
  y: number;
  targetId: string;
}

interface EditorState {
  // Layout data
  layout: HudLayout;
  layoutMode: LayoutMode;

  // UI state
  selectedId: string | null;
  contextMenu: ContextMenuState | null;

  // Undo/Redo
  history: HudLayout[];
  historyIndex: number;

  // Actions
  selectElement: (id: string | null) => void;
  updateElement: (id: string, updates: Partial<HudElement>) => void;
  updateElementSilent: (id: string, updates: Partial<HudElement>) => void;
  pushCurrentToHistory: () => void;
  deleteElement: (id: string) => void;
  addElement: (parentGridId: string, type: ElementType) => void;
  moveElement: (elementId: string, targetGridId: string) => void;
  splitCell: (gridId: string, direction: 'horizontal' | 'vertical') => void;
  duplicateElement: (id: string) => void;
  mergeGrid: (gridId: string, direction: 'horizontal' | 'vertical') => void;
  setContextMenu: (menu: ContextMenuState | null) => void;
  setLayoutMode: (mode: LayoutMode) => void;
  setLayout: (layout: HudLayout) => void;
  undo: () => void;
  redo: () => void;
}

const DEFAULT_THEME: HudTheme = {
  background: 'rgba(62,39,12,0.9)',
  border: 'rgba(255,193,7,0.3)',
  text: '#FFB300',
  borderRadius: 10,
};

function createEmptyLayout(mode: LayoutMode): HudLayout {
  const isDesktop = mode === 'desktop-landscape';
  return {
    name: mode,
    canvasSize: isDesktop ? [1200, 700] : [844, 390],
    root: {
      type: 'grid',
      id: 'root',
      rows: ['1fr'],
      cols: ['1fr'],
      children: [],
    },
    theme: DEFAULT_THEME,
  };
}

function createDefaultElement(type: ElementType): HudElement {
  const id = generateId(type);
  const base = { id, type } as HudElement;
  switch (type) {
    case 'grid':
      return { ...base, type: 'grid', rows: ['1fr'], cols: ['1fr'], children: [] } as GridElement;
    case 'label':
      return { ...base, type: 'label', text: 'Label' };
    case 'button':
      return { ...base, type: 'button', text: 'Button' };
    case 'slider':
      return { ...base, type: 'slider', min: 0, max: 100, step: 1 };
    case 'icon':
      return { ...base, type: 'icon', name: 'star' };
    case 'list':
      return { ...base, type: 'list', maxItems: 4 };
    case 'cardhand':
      return { ...base, type: 'cardhand' };
    case 'container':
      return { ...base, type: 'container', children: [] };
    case 'spacer':
      return { ...base, type: 'spacer' };
    default:
      return base;
  }
}

function pushHistory(state: EditorState): Partial<EditorState> {
  const newHistory = state.history.slice(0, state.historyIndex + 1);
  newHistory.push(structuredClone(state.layout));
  return { history: newHistory, historyIndex: newHistory.length - 1 };
}

export const useEditorStore = create<EditorState>((set, get) => ({
  layout: createEmptyLayout('mobile-landscape'),
  layoutMode: 'mobile-landscape',
  selectedId: null,
  contextMenu: null,
  history: [structuredClone(createEmptyLayout('mobile-landscape'))],
  historyIndex: 0,

  selectElement: (id) => set({ selectedId: id, contextMenu: null }),

  updateElement: (id, updates) =>
    set((state) => {
      const element = findById(state.layout.root, id);
      if (!element) return state;
      const updated = { ...element, ...updates } as HudElement;
      const root = replaceById(state.layout.root, id, updated) as GridElement;
      const layout = { ...state.layout, root };
      return { layout, ...pushHistory({ ...state, layout }) };
    }),

  updateElementSilent: (id, updates) =>
    set((state) => {
      const element = findById(state.layout.root, id);
      if (!element) return state;
      const updated = { ...element, ...updates } as HudElement;
      const root = replaceById(state.layout.root, id, updated) as GridElement;
      return { layout: { ...state.layout, root } };
    }),

  pushCurrentToHistory: () =>
    set((state) => pushHistory(state)),

  deleteElement: (id) =>
    set((state) => {
      if (id === 'root') return state;
      const root = removeById(state.layout.root, id) as GridElement;
      const layout = { ...state.layout, root };
      return {
        layout,
        selectedId: state.selectedId === id ? null : state.selectedId,
        ...pushHistory({ ...state, layout }),
      };
    }),

  addElement: (parentGridId, type) =>
    set((state) => {
      const element = createDefaultElement(type);
      const root = insertIntoGrid(state.layout.root, parentGridId, element) as GridElement;
      const layout = { ...state.layout, root };
      return { layout, selectedId: element.id, ...pushHistory({ ...state, layout }) };
    }),

  moveElement: (elementId, targetGridId) =>
    set((state) => {
      const element = findById(state.layout.root, elementId);
      if (!element) return state;
      let root = removeById(state.layout.root, elementId) as GridElement;
      root = insertIntoGrid(root, targetGridId, element) as GridElement;
      const layout = { ...state.layout, root };
      return { layout, ...pushHistory({ ...state, layout }) };
    }),

  splitCell: (gridId, direction) =>
    set((state) => {
      const grid = findById(state.layout.root, gridId);
      if (!grid || grid.type !== 'grid') return state;
      const g = grid as GridElement;
      const updated: GridElement =
        direction === 'horizontal'
          ? { ...g, cols: [...(g.cols || ['1fr']), '1fr'] }
          : { ...g, rows: [...(g.rows || ['1fr']), '1fr'] };
      const root = replaceById(state.layout.root, gridId, updated) as GridElement;
      const layout = { ...state.layout, root };
      return { layout, ...pushHistory({ ...state, layout }) };
    }),

  duplicateElement: (id) =>
    set((state) => {
      const element = findById(state.layout.root, id);
      if (!element || id === 'root') return state;
      const cloned = cloneElement(element, (oldId) => generateId(oldId.split('-')[0]));
      const root = state.layout.root;
      const findAndInsertAfter = (node: HudElement): HudElement => {
        if ('children' in node && node.children) {
          const g = node as GridElement;
          const idx = g.children.findIndex((c) => c.id === id);
          if (idx !== -1) {
            const newChildren = [...g.children];
            newChildren.splice(idx + 1, 0, cloned);
            return { ...g, children: newChildren };
          }
          return { ...g, children: g.children.map(findAndInsertAfter) };
        }
        return node;
      };
      const newRoot = findAndInsertAfter(root) as GridElement;
      const layout = { ...state.layout, root: newRoot };
      return { layout, selectedId: cloned.id, ...pushHistory({ ...state, layout }) };
    }),

  mergeGrid: (gridId, direction) =>
    set((state) => {
      const grid = findById(state.layout.root, gridId);
      if (!grid || grid.type !== 'grid') return state;
      const g = grid as GridElement;
      const updated: GridElement =
        direction === 'horizontal'
          ? { ...g, cols: (g.cols || ['1fr']).length > 1 ? (g.cols || ['1fr']).slice(0, -1) : g.cols || ['1fr'] }
          : { ...g, rows: (g.rows || ['1fr']).length > 1 ? (g.rows || ['1fr']).slice(0, -1) : g.rows || ['1fr'] };
      const root = replaceById(state.layout.root, gridId, updated) as GridElement;
      const layout = { ...state.layout, root };
      return { layout, ...pushHistory({ ...state, layout }) };
    }),

  setContextMenu: (menu) => set({ contextMenu: menu }),

  setLayoutMode: (mode) =>
    set((state) => {
      return {
        layoutMode: mode,
        layout: createEmptyLayout(mode),
        selectedId: null,
        history: [structuredClone(createEmptyLayout(mode))],
        historyIndex: 0,
      };
    }),

  setLayout: (layout) =>
    set((state) => ({
      layout,
      selectedId: null,
      ...pushHistory({ ...state, layout }),
    })),

  undo: () =>
    set((state) => {
      if (state.historyIndex <= 0) return state;
      const newIndex = state.historyIndex - 1;
      return {
        layout: structuredClone(state.history[newIndex]),
        historyIndex: newIndex,
        selectedId: null,
      };
    }),

  redo: () =>
    set((state) => {
      if (state.historyIndex >= state.history.length - 1) return state;
      const newIndex = state.historyIndex + 1;
      return {
        layout: structuredClone(state.history[newIndex]),
        historyIndex: newIndex,
        selectedId: null,
      };
    }),
}));
