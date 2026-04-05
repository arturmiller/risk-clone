import { useEffect } from 'react';
import { useEditorStore } from '../store';

export default function ContextMenu() {
  const contextMenu = useEditorStore((s) => s.contextMenu);
  const setContextMenu = useEditorStore((s) => s.setContextMenu);
  const deleteElement = useEditorStore((s) => s.deleteElement);
  const duplicateElement = useEditorStore((s) => s.duplicateElement);
  const splitCell = useEditorStore((s) => s.splitCell);
  const mergeGrid = useEditorStore((s) => s.mergeGrid);

  useEffect(() => {
    const close = () => setContextMenu(null);
    window.addEventListener('click', close);
    return () => window.removeEventListener('click', close);
  }, [setContextMenu]);

  if (!contextMenu) return null;

  const { x, y, targetId } = contextMenu;
  const isRoot = targetId === 'root';

  return (
    <div className="context-menu" style={{ left: x, top: y }} onClick={(e) => e.stopPropagation()}>
      <button onClick={() => { duplicateElement(targetId); setContextMenu(null); }} disabled={isRoot}>📋 Duplizieren</button>
      <button onClick={() => { splitCell(targetId, 'horizontal'); setContextMenu(null); }}>⊞ Split horizontal</button>
      <button onClick={() => { splitCell(targetId, 'vertical'); setContextMenu(null); }}>⊞ Split vertikal</button>
      <button onClick={() => { mergeGrid(targetId, 'horizontal'); setContextMenu(null); }}>⊟ Merge horizontal</button>
      <button onClick={() => { mergeGrid(targetId, 'vertical'); setContextMenu(null); }}>⊟ Merge vertikal</button>
      <div className="context-menu-divider" />
      <button className="context-menu-danger" onClick={() => { deleteElement(targetId); setContextMenu(null); }} disabled={isRoot}>🗑️ Löschen</button>
    </div>
  );
}
