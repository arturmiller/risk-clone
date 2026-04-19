import { useEditorStore } from '../store';
import { findById } from '../utils/tree';
import { HudElement, ElementStyle, Length } from '../types';
import ElementTree from './ElementTree';

function PropertyField({
  label,
  value,
  onChange,
  type = 'text',
}: {
  label: string;
  value: string | number | undefined;
  onChange: (val: string) => void;
  type?: string;
}) {
  return (
    <div className="prop-field">
      <label className="prop-label">{label}</label>
      <input
        className="prop-input"
        type={type}
        value={value ?? ''}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
}

function SelectField({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string | undefined;
  options: readonly string[];
  onChange: (val: string) => void;
}) {
  return (
    <div className="prop-field">
      <label className="prop-label">{label}</label>
      <select
        className="prop-input"
        value={value ?? ''}
        onChange={(e) => onChange(e.target.value)}
      >
        <option value=""></option>
        {options.map((o) => (
          <option key={o} value={o}>{o}</option>
        ))}
      </select>
    </div>
  );
}

const ALIGN_OPTIONS = ['start', 'center', 'end', 'stretch'] as const;
const TEXT_ALIGN_OPTIONS = ['left', 'center', 'right'] as const;

export default function PropertiesPanel() {
  const selectedId = useEditorStore((s) => s.selectedId);
  const root = useEditorStore((s) => s.layout.root);
  const updateElement = useEditorStore((s) => s.updateElement);

  const element = selectedId ? findById(root, selectedId) : null;

  const update = (updates: Partial<HudElement>) => {
    if (selectedId) updateElement(selectedId, updates);
  };

  const updateStyle = (patch: Partial<ElementStyle>) => {
    if (!element) return;
    const merged = { ...element.style, ...patch };
    // Drop keys with empty string / undefined so they don't serialize as empties
    for (const k of Object.keys(patch) as (keyof ElementStyle)[]) {
      if (patch[k] === undefined || patch[k] === '') delete merged[k];
    }
    update({ style: merged });
  };

  const parseNum = (v: string) => (v === '' ? undefined : Number(v));
  const parseInt0 = (v: string) => (v === '' ? undefined : parseInt(v) || 0);
  /** Numbers (px) stay numbers; anything else stays as a literal CSS string. */
  const parseLen = (v: string): Length | undefined => {
    if (v === '') return undefined;
    const n = Number(v);
    return Number.isFinite(n) && String(n) === v.trim() ? n : v;
  };

  return (
    <div className="panel properties-panel">
      <h3>Eigenschaften</h3>
      {element ? (
        <div className="prop-editor">
          <div className="prop-header">{element.type}: {element.id}</div>

          <div className="prop-field">
            <label className="prop-label">ID</label>
            <input className="prop-input" value={element.id} readOnly style={{ opacity: 0.6 }} />
          </div>
          <PropertyField label="Beschreibung" value={element.description} onChange={(v) => update({ description: v })} />

          {'text' in element && (
            <PropertyField label="Text" value={(element as any).text} onChange={(v) => update({ text: v } as any)} />
          )}

          {(element.type === 'label' || element.type === 'button') && (
            <PropertyField label="Binding (z.B. 'players[0].name')" value={(element as any).binding} onChange={(v) => update({ binding: v || undefined } as any)} />
          )}

          {element.type === 'list' && (
            <PropertyField label="Item Binding (z.B. 'game.battleLog')" value={(element as any).itemBinding} onChange={(v) => update({ itemBinding: v || undefined } as any)} />
          )}

          {element.type === 'button' && (
            <>
              <PropertyField label="Radio Group" value={(element as any).group} onChange={(v) => update({ group: v || undefined } as any)} />
              <div className="prop-field">
                <label className="prop-label">Selected</label>
                <input
                  className="prop-input"
                  type="checkbox"
                  checked={(element as any).selected === true}
                  onChange={(e) => update({ selected: e.target.checked || undefined } as any)}
                  style={{ width: 'auto' }}
                />
              </div>
              <PropertyField label="Action" value={(element as any).action} onChange={(v) => update({ action: v || undefined } as any)} />
              <PropertyField label="Selected When" value={(element as any).selectedWhen} onChange={(v) => update({ selectedWhen: v || undefined } as any)} />
              {/* TODO: Add a raw-JSON editor for `selectedStyle` in a follow-up. For now the
                  field is preserved round-trip via hand-edited JSON. */}
            </>
          )}

          {'name' in element && element.type === 'icon' && (
            <PropertyField label="Icon Name" value={(element as any).name} onChange={(v) => update({ name: v } as any)} />
          )}

          {'maxItems' in element && (
            <PropertyField label="Max Items" value={(element as any).maxItems} onChange={(v) => update({ maxItems: parseInt(v) || 4 } as any)} type="number" />
          )}

          {element.type === 'grid' && (
            <>
              <PropertyField label="Rows" value={(element as any).rows?.join(', ')} onChange={(v) => update({ rows: v.split(',').map((s: string) => s.trim()) } as any)} />
              <PropertyField label="Cols" value={(element as any).cols?.join(', ')} onChange={(v) => update({ cols: v.split(',').map((s: string) => s.trim()) } as any)} />
            </>
          )}

          <h3 style={{ marginTop: 16 }}>Platzierung</h3>
          <PropertyField label="Row" value={element.row} onChange={(v) => update({ row: parseInt0(v) })} type="number" />
          <PropertyField label="Col" value={element.col} onChange={(v) => update({ col: parseInt0(v) })} type="number" />
          <PropertyField label="Row Span" value={element.rowSpan} onChange={(v) => update({ rowSpan: parseInt0(v) })} type="number" />
          <PropertyField label="Col Span" value={element.colSpan} onChange={(v) => update({ colSpan: parseInt0(v) })} type="number" />
          <SelectField label="Align Self" value={element.style?.alignSelf} options={ALIGN_OPTIONS} onChange={(v) => updateStyle({ alignSelf: (v || undefined) as ElementStyle['alignSelf'] })} />
          <SelectField label="Justify Self" value={element.style?.justifySelf} options={ALIGN_OPTIONS} onChange={(v) => updateStyle({ justifySelf: (v || undefined) as ElementStyle['justifySelf'] })} />

          <h3 style={{ marginTop: 16 }}>Style</h3>
          <PropertyField label="Font Size (Zahl = px, oder CSS-Wert)" value={element.style?.fontSize} onChange={(v) => updateStyle({ fontSize: parseLen(v) })} />
          <PropertyField label="Font Weight" value={element.style?.fontWeight} onChange={(v) => updateStyle({ fontWeight: v || undefined })} />
          <PropertyField label="Farbe" value={element.style?.color} onChange={(v) => updateStyle({ color: v || undefined })} />
          <PropertyField label="Background" value={element.style?.background} onChange={(v) => updateStyle({ background: v || undefined })} />
          <PropertyField label="Border (z.B. '1px solid #FFA000')" value={element.style?.border} onChange={(v) => updateStyle({ border: v || undefined })} />
          <PropertyField label="Border Radius (Zahl = px, oder CSS)" value={element.style?.borderRadius} onChange={(v) => updateStyle({ borderRadius: parseLen(v) })} />
          <PropertyField label="Padding (Zahl = px, oder z.B. '4px 8px')" value={element.style?.padding} onChange={(v) => updateStyle({ padding: parseLen(v) })} />
          <SelectField label="Text Align" value={element.style?.textAlign} options={TEXT_ALIGN_OPTIONS} onChange={(v) => updateStyle({ textAlign: (v || undefined) as ElementStyle['textAlign'] })} />
          {element.type === 'grid' && (
            <PropertyField label="Gap (Zahl = px, oder CSS)" value={element.style?.gap} onChange={(v) => updateStyle({ gap: parseLen(v) })} />
          )}
          <PropertyField label="Opacity" value={element.style?.opacity} onChange={(v) => updateStyle({ opacity: parseNum(v) })} type="number" />
        </div>
      ) : (
        <p className="prop-empty">Kein Element ausgewählt</p>
      )}

      <h3 style={{ marginTop: 16 }}>Element-Baum</h3>
      <ElementTree />
    </div>
  );
}
