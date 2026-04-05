import { useDraggable } from '@dnd-kit/core';
import { ElementType } from '../types';
import { useEditorStore } from '../store';

const ELEMENT_TYPES: { type: ElementType; label: string; icon: string }[] = [
  { type: 'label', label: 'Label', icon: '📝' },
  { type: 'button', label: 'Button', icon: '🔘' },
  { type: 'slider', label: 'Slider', icon: '🎚️' },
  { type: 'icon', label: 'Icon', icon: '⭐' },
  { type: 'list', label: 'Liste/Log', icon: '📋' },
  { type: 'cardhand', label: 'Kartenhand', icon: '🃏' },
  { type: 'container', label: 'Container', icon: '📦' },
  { type: 'spacer', label: 'Spacer', icon: '↔️' },
  { type: 'grid', label: 'Sub-Grid', icon: '⊞' },
];

function DraggableItem({ type, label, icon }: { type: ElementType; label: string; icon: string }) {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `library-${type}`,
    data: { type, source: 'library' },
  });

  return (
    <div
      ref={setNodeRef}
      className="library-item"
      style={{ opacity: isDragging ? 0.5 : 1 }}
      {...listeners}
      {...attributes}
    >
      <span>{icon}</span> {label}
    </div>
  );
}

export default function ElementLibrary() {
  const layoutMode = useEditorStore((s) => s.layoutMode);
  const setLayoutMode = useEditorStore((s) => s.setLayoutMode);

  return (
    <div className="panel element-library">
      <h3>Elemente</h3>
      <div className="library-list">
        {ELEMENT_TYPES.map((et) => (
          <DraggableItem key={et.type} {...et} />
        ))}
      </div>
      <h3 style={{ marginTop: 16 }}>Layout</h3>
      <div className="library-list">
        <button
          className={`layout-btn ${layoutMode === 'mobile-landscape' ? 'active' : ''}`}
          onClick={() => setLayoutMode('mobile-landscape')}
        >
          📱 Mobile Landscape
        </button>
        <button
          className={`layout-btn ${layoutMode === 'desktop-landscape' ? 'active' : ''}`}
          onClick={() => setLayoutMode('desktop-landscape')}
        >
          🖥️ Desktop Landscape
        </button>
      </div>
    </div>
  );
}
