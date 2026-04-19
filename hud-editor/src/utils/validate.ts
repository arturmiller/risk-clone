import { HudFile, ElementType, LayoutMode } from '../types';

const ELEMENT_TYPES: ElementType[] = [
  'grid',
  'label',
  'button',
  'slider',
  'icon',
  'list',
  'cardhand',
  'container',
  'spacer',
];
const REQUIRED_LAYOUT_MODES: LayoutMode[] = ['mobile-landscape', 'desktop-landscape'];

export type ValidationResult =
  | { ok: true; file: HudFile }
  | { ok: false; errors: string[] };

const TOP_LEVEL_KEYS = new Set(['version', 'theme', 'layouts']);
const THEME_KEYS = new Set(['background', 'border', 'text', 'borderRadius']);
const LAYOUT_KEYS = new Set(['canvasSize', 'root']);

export function validateHudFile(data: unknown): ValidationResult {
  const errors: string[] = [];

  if (!isObject(data)) {
    return { ok: false, errors: ['Root must be an object.'] };
  }

  const extraTop = Object.keys(data).filter((k) => !TOP_LEVEL_KEYS.has(k));
  if (extraTop.length) {
    errors.push(`Unknown top-level key(s): ${extraTop.join(', ')}. Expected only: version, theme, layouts.`);
  }

  if (typeof data.version !== 'number') {
    errors.push('Missing or invalid "version" (expected number).');
  }

  if (!isObject(data.theme)) {
    errors.push('Missing or invalid "theme" object.');
  } else {
    for (const key of ['background', 'border', 'text'] as const) {
      if (typeof data.theme[key] !== 'string') {
        errors.push(`theme.${key} must be a string.`);
      }
    }
    if (typeof data.theme.borderRadius !== 'number') {
      errors.push('theme.borderRadius must be a number.');
    }
    const extraTheme = Object.keys(data.theme).filter((k) => !THEME_KEYS.has(k));
    if (extraTheme.length) {
      errors.push(`Unknown key(s) in theme: ${extraTheme.join(', ')}.`);
    }
  }

  if (!isObject(data.layouts)) {
    errors.push('Missing or invalid "layouts" object.');
    return { ok: false, errors };
  }

  const extraLayouts = Object.keys(data.layouts).filter(
    (k) => !REQUIRED_LAYOUT_MODES.includes(k as LayoutMode),
  );
  if (extraLayouts.length) {
    errors.push(
      `Unknown layout key(s): ${extraLayouts.join(', ')}. Expected only: ${REQUIRED_LAYOUT_MODES.join(', ')}.`,
    );
  }

  for (const mode of REQUIRED_LAYOUT_MODES) {
    const layout = data.layouts[mode];
    if (!isObject(layout)) {
      errors.push(`Missing layout "${mode}".`);
      continue;
    }
    validateLayout(layout, `layouts["${mode}"]`, errors);
  }

  const ids = new Set<string>();
  for (const mode of REQUIRED_LAYOUT_MODES) {
    const layout = data.layouts[mode];
    if (isObject(layout) && isObject(layout.root)) {
      collectAndCheckIds(layout.root, `layouts["${mode}"].root`, ids, errors);
      ids.clear();
    }
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, file: data as unknown as HudFile };
}

function validateLayout(layout: Record<string, unknown>, path: string, errors: string[]): void {
  const extra = Object.keys(layout).filter((k) => !LAYOUT_KEYS.has(k));
  if (extra.length) {
    errors.push(`Unknown key(s) in ${path}: ${extra.join(', ')}. Expected only: canvasSize, root.`);
  }
  const cs = layout.canvasSize;
  if (!Array.isArray(cs) || cs.length !== 2 || typeof cs[0] !== 'number' || typeof cs[1] !== 'number') {
    errors.push(`${path}.canvasSize must be [width, height] (two numbers).`);
  }
  if (!isObject(layout.root)) {
    errors.push(`${path}.root must be an object.`);
    return;
  }
  const root = layout.root as Record<string, unknown>;
  if (root.type !== 'grid') {
    errors.push(`${path}.root.type must be "grid".`);
  }
  if (root.id !== 'root') {
    errors.push(`${path}.root.id must be "root" (got ${JSON.stringify(root.id)}).`);
  }
  validateElement(root, `${path}.root`, errors);
}

function validateElement(
  el: Record<string, unknown>,
  path: string,
  errors: string[],
): void {
  if (typeof el.type !== 'string' || !ELEMENT_TYPES.includes(el.type as ElementType)) {
    errors.push(`${path}.type is invalid (got ${JSON.stringify(el.type)}).`);
  }
  if (typeof el.id !== 'string' || el.id.length === 0) {
    errors.push(`${path}.id must be a non-empty string.`);
  }
  if (el.binding !== undefined && typeof el.binding !== 'string') {
    errors.push(`${path}.binding must be a string when present.`);
  }
  if (el.itemBinding !== undefined && typeof el.itemBinding !== 'string') {
    errors.push(`${path}.itemBinding must be a string when present.`);
  }
  if (el.type === 'button') {
    if (el.action !== undefined && typeof el.action !== 'string') {
      errors.push(`${path}.action must be a string when present.`);
    }
    if (el.selectedWhen !== undefined && typeof el.selectedWhen !== 'string') {
      errors.push(`${path}.selectedWhen must be a string when present.`);
    }
    if (el.selectedStyle !== undefined && (typeof el.selectedStyle !== 'object' || el.selectedStyle === null)) {
      errors.push(`${path}.selectedStyle must be an object when present.`);
    }
  }
  if (el.type === 'grid' || el.type === 'container') {
    const children = el.children;
    if (children !== undefined && !Array.isArray(children)) {
      errors.push(`${path}.children must be an array.`);
    } else if (Array.isArray(children)) {
      children.forEach((child, i) => {
        if (!isObject(child)) {
          errors.push(`${path}.children[${i}] must be an object.`);
        } else {
          validateElement(child, `${path}.children[${i}]`, errors);
        }
      });
    }
  }
}

function collectAndCheckIds(
  el: unknown,
  path: string,
  seen: Set<string>,
  errors: string[],
): void {
  if (!isObject(el)) return;
  if (typeof el.id === 'string') {
    if (seen.has(el.id)) {
      errors.push(`${path}: duplicate id "${el.id}" within the same layout.`);
    }
    seen.add(el.id);
  }
  const children = (el as { children?: unknown }).children;
  if (Array.isArray(children)) {
    children.forEach((c, i) => collectAndCheckIds(c, `${path}.children[${i}]`, seen, errors));
  }
}

function isObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

