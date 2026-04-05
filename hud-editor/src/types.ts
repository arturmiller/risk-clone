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

export interface ElementStyle {
  fontSize?: number;
  color?: string;
  background?: string;
  border?: string;
  borderRadius?: number;
  padding?: string;
  fontWeight?: string;
  textAlign?: string;
  opacity?: number;
  position?: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right';
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
  text: string;
}

export interface ButtonElement extends HudElementBase {
  type: 'button';
  text: string;
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

export interface HudLayout {
  name: string;
  canvasSize: [number, number];
  root: GridElement;
  theme: HudTheme;
}
