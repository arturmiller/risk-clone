import { useEditorStore } from '../store';
import { findById } from '../utils/tree';
import { HudElement } from '../types';
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

export default function PropertiesPanel() {
  const selectedId = useEditorStore((s) => s.selectedId);
  const root = useEditorStore((s) => s.layout.root);
  const updateElement = useEditorStore((s) => s.updateElement);

  const element = selectedId ? findById(root, selectedId) : null;

  const update = (updates: Partial<HudElement>) => {
    if (selectedId) updateElement(selectedId, updates);
  };

  return (
    <div className="panel properties-panel">
      <h3>Eigenschaften</h3>
      {element ? (
        <div className="prop-editor">
          <div className="prop-header">{element.type}: {element.id}</div>

          <PropertyField label="ID" value={element.id} onChange={(v) => update({ id: v })} />
          <PropertyField label="Beschreibung" value={element.description} onChange={(v) => update({ description: v })} />

          {'text' in element && (
            <PropertyField label="Text" value={(element as any).text} onChange={(v) => update({ text: v } as any)} />
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

          <h3 style={{ marginTop: 16 }}>Style</h3>
          <PropertyField label="Font Size" value={element.style?.fontSize} onChange={(v) => update({ style: { ...element.style, fontSize: parseInt(v) || undefined } })} type="number" />
          <PropertyField label="Farbe" value={element.style?.color} onChange={(v) => update({ style: { ...element.style, color: v } })} />
          <PropertyField label="Background" value={element.style?.background} onChange={(v) => update({ style: { ...element.style, background: v } })} />
        </div>
      ) : (
        <p className="prop-empty">Kein Element ausgewählt</p>
      )}

      <h3 style={{ marginTop: 16 }}>Element-Baum</h3>
      <ElementTree />
    </div>
  );
}
