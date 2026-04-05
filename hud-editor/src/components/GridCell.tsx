import { useDroppable } from '@dnd-kit/core';
import { GridElement, HudElement } from '../types';
import { useEditorStore } from '../store';
import ElementRenderer from './elements/ElementRenderer';

interface GridCellProps {
  element: HudElement;
  depth?: number;
}

function EmptyDropZone({ gridId }: { gridId: string }) {
  const { setNodeRef, isOver } = useDroppable({ id: `drop-${gridId}`, data: { gridId } });
  return (
    <div
      ref={setNodeRef}
      className="grid-empty-cell"
      style={{ background: isOver ? 'rgba(68, 136, 255, 0.15)' : undefined }}
    >
      <span>{isOver ? '⬇' : '+'}</span>
    </div>
  );
}

export default function GridCell({ element, depth = 0 }: GridCellProps) {
  const selectedId = useEditorStore((s) => s.selectedId);
  const selectElement = useEditorStore((s) => s.selectElement);
  const setContextMenu = useEditorStore((s) => s.setContextMenu);
  const isSelected = selectedId === element.id;

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    selectElement(element.id);
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    selectElement(element.id);
    setContextMenu({ x: e.clientX, y: e.clientY, targetId: element.id });
  };

  if (element.type === 'grid') {
    const grid = element as GridElement;
    return (
      <div
        className={`grid-cell grid-container ${isSelected ? 'selected' : ''}`}
        style={{
          display: 'grid',
          gridTemplateRows: (grid.rows || ['1fr']).join(' '),
          gridTemplateColumns: (grid.cols || ['1fr']).join(' '),
          gap: 1,
          minHeight: depth === 0 ? '100%' : 30,
          gridRow: element.row !== undefined ? element.row + 1 : undefined,
          gridColumn: element.col !== undefined ? element.col + 1 : undefined,
          gridRowEnd: element.rowSpan ? `span ${element.rowSpan}` : undefined,
          gridColumnEnd: element.colSpan ? `span ${element.colSpan}` : undefined,
        }}
        onClick={handleClick}
        onContextMenu={handleContextMenu}
      >
        {grid.children.map((child) => (
          <GridCell key={child.id} element={child} depth={depth + 1} />
        ))}
        <EmptyDropZone gridId={grid.id} />
      </div>
    );
  }

  return (
    <div
      className={`grid-cell leaf-cell ${isSelected ? 'selected' : ''}`}
      style={{
        gridRow: element.row !== undefined ? element.row + 1 : undefined,
        gridColumn: element.col !== undefined ? element.col + 1 : undefined,
      }}
      onClick={handleClick}
      onContextMenu={handleContextMenu}
    >
      <ElementRenderer element={element} />
    </div>
  );
}
