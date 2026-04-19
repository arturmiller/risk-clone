export type ElementType =
  | 'grid'
  | 'label'
  | 'button'
  | 'slider'
  | 'icon'
  | 'list'
  | 'cardhand'
  | 'container'
  | 'spacer';

/**
 * Unit convention:
 * - Single-value length fields (fontSize, borderRadius, padding, gap) accept
 *   either a number (interpreted as pixels) OR a CSS string ("6px", "2px 6px",
 *   "4px 8px 4px 8px"). Use strings when you need shorthand or non-pixel units.
 * - Compound fields (border) are always CSS strings: "1px solid #FFA000".
 * - Enumerated fields (textAlign, alignSelf, justifySelf) are literal unions.
 * - Color fields (color, background, border color component) may contain
 *   {theme-token} placeholders like "{text}" resolved at render time.
 */
export type Length = number | string;

export interface ElementStyle {
  fontSize?: Length;
  color?: string;
  background?: string;
  border?: string;
  borderRadius?: Length;
  padding?: Length;
  fontWeight?: string;
  textAlign?: 'left' | 'center' | 'right';
  opacity?: number;
  gap?: Length;
  alignSelf?: 'start' | 'center' | 'end' | 'stretch';
  justifySelf?: 'start' | 'center' | 'end' | 'stretch';
}

export interface HudElementBase {
  type: ElementType;
  id: string;
  description?: string;
  style?: ElementStyle;
  row?: number;
  col?: number;
  rowSpan?: number;
  colSpan?: number;
}

export interface GridElement extends HudElementBase {
  type: 'grid';
  rows?: string[];
  cols?: string[];
  children: HudElement[];
}

export interface LabelElement extends HudElementBase {
  type: 'label';
  /** Sample / fallback text shown in the editor preview. */
  text: string;
  /** Data path resolved at runtime (e.g. "players[0].name"). When set, `text` is only a sample. */
  binding?: string;
}

export interface ButtonElement extends HudElementBase {
  type: 'button';
  /** Sample / fallback text shown in the editor preview. */
  text: string;
  /** Data path resolved at runtime for the button's label. */
  binding?: string;
  /** Buttons sharing the same `group` are mutually exclusive (radio behavior). */
  group?: string;
  /** Initial / persistent selection state within the group. */
  selected?: boolean;
}

export interface SliderElement extends HudElementBase {
  type: 'slider';
  min?: number;
  max?: number;
  step?: number;
}

export interface IconElement extends HudElementBase {
  type: 'icon';
  name: string;
}

export interface ListElement extends HudElementBase {
  type: 'list';
  maxItems?: number;
  /** Data path resolved at runtime producing list items (e.g. "game.battleLog"). */
  itemBinding?: string;
}

export interface CardhandElement extends HudElementBase {
  type: 'cardhand';
}

export interface ContainerElement extends HudElementBase {
  type: 'container';
  children: HudElement[];
}

export interface SpacerElement extends HudElementBase {
  type: 'spacer';
}

export type HudElement =
  | GridElement
  | LabelElement
  | ButtonElement
  | SliderElement
  | IconElement
  | ListElement
  | CardhandElement
  | ContainerElement
  | SpacerElement;

export interface HudTheme {
  background: string;
  border: string;
  text: string;
  borderRadius: number;
}

export type LayoutMode = 'mobile-landscape' | 'desktop-landscape';

export interface HudLayout {
  canvasSize: [number, number];
  root: GridElement;
}

export const HUD_FILE_VERSION = 1;

export interface HudFile {
  version: number;
  theme: HudTheme;
  layouts: Record<LayoutMode, HudLayout>;
}
