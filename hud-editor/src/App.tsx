import { useEffect } from 'react';
import { DndContext, DragEndEvent } from '@dnd-kit/core';
import { useEditorStore } from './store';
import { ElementType } from './types';
import { saveLayout } from './utils/json-io';
import Toolbar from './components/Toolbar';
import ElementLibrary from './components/ElementLibrary';
import Canvas from './components/Canvas';
import PropertiesPanel from './components/PropertiesPanel';
import ChatPanel from './components/ChatPanel';
import ContextMenu from './components/ContextMenu';

export default function App() {
  const addElement = useEditorStore((s) => s.addElement);
  const moveElement = useEditorStore((s) => s.moveElement);

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over) return;

    const dropData = over.data.current as { gridId: string } | undefined;
    if (!dropData?.gridId) return;

    const dragData = active.data.current as { type: ElementType; source: string } | undefined;
    if (dragData?.source === 'library') {
      addElement(dropData.gridId, dragData.type);
    } else {
      moveElement(active.id as string, dropData.gridId);
    }
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const state = useEditorStore.getState();

      if (e.key === 'Delete' && state.selectedId) {
        e.preventDefault();
        state.deleteElement(state.selectedId);
      }
      if (e.ctrlKey && e.key === 'd' && state.selectedId) {
        e.preventDefault();
        state.duplicateElement(state.selectedId);
      }
      if (e.ctrlKey && e.key === 'z') {
        e.preventDefault();
        state.undo();
      }
      if (e.ctrlKey && e.key === 'y') {
        e.preventDefault();
        state.redo();
      }
      if (e.ctrlKey && e.key === 's') {
        e.preventDefault();
        saveLayout(useEditorStore.getState().layout);
      }
      if (e.key === 'Escape') {
        state.selectElement(null);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return (
    <DndContext onDragEnd={handleDragEnd}>
      <div className="app">
        <Toolbar />
        <div className="app-body">
          <ElementLibrary />
          <Canvas />
          <PropertiesPanel />
        </div>
        <ChatPanel />
      </div>
      <ContextMenu />
    </DndContext>
  );
}
