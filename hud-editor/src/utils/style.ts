import type { CSSProperties } from 'react';
import { ElementStyle, HudTheme } from '../types';

const TOKEN_RE = /\{([a-zA-Z0-9_.-]+)\}/g;

/**
 * Resolve `{tokenName}` references against the theme. A string like
 * `"1px solid {border}"` becomes `"1px solid rgba(255,193,7,0.3)"`.
 * Unknown tokens are left as-is so the failure is visible.
 */
export function resolveTokens(v: string | undefined, theme: HudTheme): string | undefined {
  if (typeof v !== 'string') return v;
  return v.replace(TOKEN_RE, (_match, key) => {
    switch (key) {
      case 'text': return theme.text;
      case 'background': return theme.background;
      case 'border': return theme.border;
      case 'borderRadius': return String(theme.borderRadius);
      default: return `{${key}}`;
    }
  });
}

export function applyStyle(
  style: ElementStyle | undefined,
  theme?: HudTheme,
): CSSProperties {
  if (!style) return {};
  const out: CSSProperties = {};
  const r = (v: string | undefined) => (theme ? resolveTokens(v, theme) : v);
  if (style.fontSize !== undefined) out.fontSize = style.fontSize;
  if (style.color !== undefined) out.color = r(style.color);
  if (style.background !== undefined) out.background = r(style.background);
  if (style.border !== undefined) out.border = r(style.border);
  if (style.borderRadius !== undefined) out.borderRadius = style.borderRadius;
  if (style.padding !== undefined) out.padding = style.padding;
  if (style.fontWeight !== undefined) out.fontWeight = style.fontWeight;
  if (style.textAlign !== undefined) out.textAlign = style.textAlign;
  if (style.opacity !== undefined) out.opacity = style.opacity;
  if (style.gap !== undefined) out.gap = style.gap;
  if (style.alignSelf !== undefined) out.alignSelf = style.alignSelf;
  if (style.justifySelf !== undefined) out.justifySelf = style.justifySelf;
  return out;
}
