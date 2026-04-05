import { useDraggable, useDroppable } from '@dnd-kit/core';
import { useCallback } from 'react';
import { GridElement, HudElement } from '../types';
import { useEditorStore } from '../store';
import ElementRenderer from './elements/ElementRenderer';

function ResizeHandle({
  gridId,
  direction,
  index,
  tracks,
}: {
  gridId: string;
  direction: 'col' | 'row';
  index: number;
  tracks: string[];
}) {
  const updateElementSilent = useEditorStore((s) => s.updateElementSilent);
  const pushCurrentToHistory = useEditorStore((s) => s.pushCurrentToHistory);

  const handleMouseDown = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      const startPos = direction === 'col' ? e.clientX : e.clientY;
      const parent = (e.target as HTMLElement).closest('.grid-container') as HTMLElement;
      if (!parent) return;

      const totalSize = direction === 'col' ? parent.offsetWidth : parent.offsetHeight;

      const handleMouseMove = (moveEvent: MouseEvent) => {
        const delta = direction === 'col'
          ? moveEvent.clientX - startPos
          : moveEvent.clientY - startPos;
        const frDelta = (delta / totalSize) * tracks.length;

        const newTracks = [...tracks];
        const prevFr = parseFloat(newTracks[index]) || 1;
        const nextFr = parseFloat(newTracks[index + 1]) || 1;
        const newPrev = Math.max(0.1, prevFr + frDelta);
        const newNext = Math.max(0.1, nextFr - frDelta);
        newTracks[index] = `${newPrev.toFixed(2)}fr`;
        newTracks[index + 1] = `${newNext.toFixed(2)}fr`;

        const update = direction === 'col' ? { cols: newTracks } : { rows: newTracks };
        updateElementSilent(gridId, update as any);
      };

      const handleMouseUp = () => {
        window.removeEventListener('mousemove', handleMouseMove);
        window.removeEventListener('mouseup', handleMouseUp);
        pushCurrentToHistory();
      };

      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
    },
    [gridId, direction, index, tracks, updateElementSilent, pushCurrentToHistory],
  );

  const isCol = direction === 'col';
  return (
    <div
      className={`resize-handle resize-handle-${direction}`}
      style={{
        position: 'absolute',
        cursor: isCol ? 'col-resize' : 'row-resize',
        zIndex: 10,
      }}
      onMouseDown={handleMouseDown}
    />
  );
}

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
        {(grid.cols || ['1fr']).length > 1 &&
          (grid.cols || ['1fr']).slice(0, -1).map((_, i) => (
            <ResizeHandle
              key={`col-${i}`}
              gridId={grid.id}
              direction="col"
              index={i}
              tracks={grid.cols || ['1fr']}
            />
          ))}
        {(grid.rows || ['1fr']).length > 1 &&
          (grid.rows || ['1fr']).slice(0, -1).map((_, i) => (
            <ResizeHandle
              key={`row-${i}`}
              gridId={grid.id}
              direction="row"
              index={i}
              tracks={grid.rows || ['1fr']}
            />
          ))}
      </div>
    );
  }

  return (
    <DraggableLeafCell
      element={element}
      isSelected={isSelected}
      onClick={handleClick}
      onContextMenu={handleContextMenu}
    />
  );
}

function DraggableLeafCell({
  element,
  isSelected,
  onClick,
  onContextMenu,
}: {
  element: HudElement;
  isSelected: boolean;
  onClick: (e: React.MouseEvent) => void;
  onContextMenu: (e: React.MouseEvent) => void;
}) {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: element.id,
    data: { type: element.type, source: 'canvas' },
  });

  return (
    <div
      ref={setNodeRef}
      className={`grid-cell leaf-cell ${isSelected ? 'selected' : ''} ${isDragging ? 'dragging' : ''}`}
      style={{
        gridRow: element.row !== undefined ? element.row + 1 : undefined,
        gridColumn: element.col !== undefined ? element.col + 1 : undefined,
        opacity: isDragging ? 0.4 : 1,
      }}
      onClick={onClick}
      onContextMenu={onContextMenu}
      {...listeners}
      {...attributes}
    >
      <ElementRenderer element={element} />
    </div>
  );
}
