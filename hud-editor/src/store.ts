import { create } from 'zustand';
import {
  HudLayout,
  HudElement,
  GridElement,
  ElementType,
  HudTheme,
  HudFile,
  HUD_FILE_VERSION,
  LayoutMode,
} from './types';
import { generateId } from './utils/id';
import {
  findById,
  replaceById,
  removeById,
  insertIntoGrid,
  cloneElement,
} from './utils/tree';

export type { LayoutMode };

const ALL_MODES: LayoutMode[] = ['mobile-landscape', 'desktop-landscape'];

interface ContextMenuState {
  x: number;
  y: number;
  targetId: string;
}

type PerMode<T> = Record<LayoutMode, T>;

interface EditorState {
  // Active layout (mirror of layouts[layoutMode])
  layout: HudLayout;
  // All layouts (merged HUD file)
  layouts: PerMode<HudLayout>;
  layoutMode: LayoutMode;
  theme: HudTheme;

  // UI state
  selectedId: string | null;
  contextMenu: ContextMenuState | null;

  // Per-mode undo/redo
  history: PerMode<HudLayout[]>;
  historyIndex: PerMode<number>;

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
  setFile: (file: HudFile) => void;
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
    canvasSize: isDesktop ? [1200, 700] : [844, 390],
    root: {
      type: 'grid',
      id: 'root',
      rows: ['1fr'],
      cols: ['1fr'],
      children: [],
    },
  };
}

function createEmptyLayouts(): PerMode<HudLayout> {
  return {
    'mobile-landscape': createEmptyLayout('mobile-landscape'),
    'desktop-landscape': createEmptyLayout('desktop-landscape'),
  };
}

function initialHistory(layouts: PerMode<HudLayout>): PerMode<HudLayout[]> {
  return {
    'mobile-landscape': [structuredClone(layouts['mobile-landscape'])],
    'desktop-landscape': [structuredClone(layouts['desktop-landscape'])],
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

function applyEdit(state: EditorState, newLayout: HudLayout): Partial<EditorState> {
  const mode = state.layoutMode;
  const modeHistory = state.history[mode].slice(0, state.historyIndex[mode] + 1);
  modeHistory.push(structuredClone(newLayout));
  return {
    layout: newLayout,
    layouts: { ...state.layouts, [mode]: newLayout },
    history: { ...state.history, [mode]: modeHistory },
    historyIndex: { ...state.historyIndex, [mode]: modeHistory.length - 1 },
  };
}

function applySilentEdit(state: EditorState, newLayout: HudLayout): Partial<EditorState> {
  const mode = state.layoutMode;
  return {
    layout: newLayout,
    layouts: { ...state.layouts, [mode]: newLayout },
  };
}

const INITIAL_LAYOUTS = createEmptyLayouts();
const INITIAL_MODE: LayoutMode = 'mobile-landscape';

export const useEditorStore = create<EditorState>((set) => ({
  layout: INITIAL_LAYOUTS[INITIAL_MODE],
  layouts: INITIAL_LAYOUTS,
  layoutMode: INITIAL_MODE,
  theme: DEFAULT_THEME,
  selectedId: null,
  contextMenu: null,
  history: initialHistory(INITIAL_LAYOUTS),
  historyIndex: { 'mobile-landscape': 0, 'desktop-landscape': 0 },

  selectElement: (id) => set({ selectedId: id, contextMenu: null }),

  updateElement: (id, updates) =>
    set((state) => {
      const element = findById(state.layout.root, id);
      if (!element) return state;
      const updated = { ...element, ...updates } as HudElement;
      const root = replaceById(state.layout.root, id, updated) as GridElement;
      return applyEdit(state, { ...state.layout, root });
    }),

  updateElementSilent: (id, updates) =>
    set((state) => {
      const element = findById(state.layout.root, id);
      if (!element) return state;
      const updated = { ...element, ...updates } as HudElement;
      const root = replaceById(state.layout.root, id, updated) as GridElement;
      return applySilentEdit(state, { ...state.layout, root });
    }),

  pushCurrentToHistory: () =>
    set((state) => applyEdit(state, state.layout)),

  deleteElement: (id) =>
    set((state) => {
      if (id === 'root') return state;
      const root = removeById(state.layout.root, id) as GridElement;
      return {
        ...applyEdit(state, { ...state.layout, root }),
        selectedId: state.selectedId === id ? null : state.selectedId,
      };
    }),

  addElement: (parentGridId, type) =>
    set((state) => {
      const element = createDefaultElement(type);
      const root = insertIntoGrid(state.layout.root, parentGridId, element) as GridElement;
      return {
        ...applyEdit(state, { ...state.layout, root }),
        selectedId: element.id,
      };
    }),

  moveElement: (elementId, targetGridId) =>
    set((state) => {
      const element = findById(state.layout.root, elementId);
      if (!element) return state;
      let root = removeById(state.layout.root, elementId) as GridElement;
      root = insertIntoGrid(root, targetGridId, element) as GridElement;
      return applyEdit(state, { ...state.layout, root });
    }),

  splitCell: (id, direction) =>
    set((state) => {
      const element = findById(state.layout.root, id);
      if (!element) return state;

      let updated: HudElement;
      if (element.type === 'grid') {
        const g = element as GridElement;
        updated =
          direction === 'horizontal'
            ? { ...g, rows: [...(g.rows || ['1fr']), '1fr'] }
            : { ...g, cols: [...(g.cols || ['1fr']), '1fr'] };
      } else {
        const { row, col, rowSpan, colSpan, ...rest } = element as HudElement & {
          row?: number;
          col?: number;
          rowSpan?: number;
          colSpan?: number;
        };
        const inner = { ...rest, row: 0, col: 0 } as HudElement;
        updated = {
          id: generateId('grid'),
          type: 'grid',
          rows: direction === 'horizontal' ? ['1fr', '1fr'] : ['1fr'],
          cols: direction === 'horizontal' ? ['1fr'] : ['1fr', '1fr'],
          children: [inner],
          row,
          col,
          rowSpan,
          colSpan,
        } as GridElement;
      }

      const root = replaceById(state.layout.root, id, updated) as GridElement;
      return {
        ...applyEdit(state, { ...state.layout, root }),
        selectedId: state.selectedId === id ? updated.id : state.selectedId,
      };
    }),

  duplicateElement: (id) =>
    set((state) => {
      const element = findById(state.layout.root, id);
      if (!element || id === 'root') return state;
      const cloned = cloneElement(element, (oldId) => generateId(oldId.split('-')[0]));
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
      const newRoot = findAndInsertAfter(state.layout.root) as GridElement;
      return {
        ...applyEdit(state, { ...state.layout, root: newRoot }),
        selectedId: cloned.id,
      };
    }),

  mergeGrid: (gridId, direction) =>
    set((state) => {
      const grid = findById(state.layout.root, gridId);
      if (!grid || grid.type !== 'grid') return state;
      const g = grid as GridElement;
      const updated: GridElement =
        direction === 'horizontal'
          ? { ...g, rows: (g.rows || ['1fr']).length > 1 ? (g.rows || ['1fr']).slice(0, -1) : g.rows || ['1fr'] }
          : { ...g, cols: (g.cols || ['1fr']).length > 1 ? (g.cols || ['1fr']).slice(0, -1) : g.cols || ['1fr'] };
      const root = replaceById(state.layout.root, gridId, updated) as GridElement;
      return applyEdit(state, { ...state.layout, root });
    }),

  setContextMenu: (menu) => set({ contextMenu: menu }),

  setLayoutMode: (mode) =>
    set((state) => ({
      layoutMode: mode,
      layout: state.layouts[mode],
      selectedId: null,
      contextMenu: null,
    })),

  setLayout: (layout) =>
    set((state) => applyEdit(state, layout)),

  setFile: (file) =>
    set((state) => {
      const mode = state.layoutMode;
      const layouts: PerMode<HudLayout> = {
        'mobile-landscape':
          file.layouts['mobile-landscape'] ?? createEmptyLayout('mobile-landscape'),
        'desktop-landscape':
          file.layouts['desktop-landscape'] ?? createEmptyLayout('desktop-landscape'),
      };
      return {
        layouts,
        layout: layouts[mode],
        theme: file.theme ?? DEFAULT_THEME,
        selectedId: null,
        contextMenu: null,
        history: initialHistory(layouts),
        historyIndex: { 'mobile-landscape': 0, 'desktop-landscape': 0 },
      };
    }),

  undo: () =>
    set((state) => {
      const mode = state.layoutMode;
      const idx = state.historyIndex[mode];
      if (idx <= 0) return state;
      const newIdx = idx - 1;
      const snap = structuredClone(state.history[mode][newIdx]);
      return {
        layout: snap,
        layouts: { ...state.layouts, [mode]: snap },
        historyIndex: { ...state.historyIndex, [mode]: newIdx },
        selectedId: null,
      };
    }),

  redo: () =>
    set((state) => {
      const mode = state.layoutMode;
      const modeHistory = state.history[mode];
      const idx = state.historyIndex[mode];
      if (idx >= modeHistory.length - 1) return state;
      const newIdx = idx + 1;
      const snap = structuredClone(modeHistory[newIdx]);
      return {
        layout: snap,
        layouts: { ...state.layouts, [mode]: snap },
        historyIndex: { ...state.historyIndex, [mode]: newIdx },
        selectedId: null,
      };
    }),
}));

// Expose constants for callers that need all modes
export const LAYOUT_MODES = ALL_MODES;
