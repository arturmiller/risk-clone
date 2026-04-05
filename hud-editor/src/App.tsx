import { useEffect, useState, useCallback } from 'react';
import { DndContext, DragEndEvent } from '@dnd-kit/core';
import { useEditorStore } from './store';
import { ElementType, HudLayout } from './types';
import { saveLayout } from './utils/json-io';
import Toolbar from './components/Toolbar';
import ElementLibrary from './components/ElementLibrary';
import Canvas from './components/Canvas';
import PropertiesPanel from './components/PropertiesPanel';
import ChatPanel from './components/ChatPanel';
import ContextMenu from './components/ContextMenu';
import HelpDialog from './components/HelpDialog';

export default function App() {
  const addElement = useEditorStore((s) => s.addElement);
  const moveElement = useEditorStore((s) => s.moveElement);
  const setLayout = useEditorStore((s) => s.setLayout);
  const [helpOpen, setHelpOpen] = useState(false);
  const toggleHelp = useCallback(() => setHelpOpen((v) => !v), []);

  // Load default layout on startup
  useEffect(() => {
    fetch('/api/layout/mobile-landscape')
      .then((r) => r.ok ? r.json() : null)
      .then((data: HudLayout | null) => {
        if (data) setLayout(data);
      })
      .catch(() => {});
  }, [setLayout]);

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over) return;

    const dropData = over.data.current as { gridId: string } | undefined;
    if (!dropData?.gridId) return;

    const dragData = active.data.current as { type: ElementType; source: string } | undefined;
    if (dragData?.source === 'library') {
      addElement(dropData.gridId, dragData.type);
    } else if (dragData?.source === 'canvas') {
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
      if (e.key === 'F1') {
        e.preventDefault();
        setHelpOpen((v) => !v);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return (
    <DndContext onDragEnd={handleDragEnd}>
      <div className="app">
        <Toolbar onHelp={toggleHelp} />
        <div className="app-body">
          <ElementLibrary />
          <Canvas />
          <PropertiesPanel />
        </div>
        <ChatPanel />
      </div>
      <ContextMenu />
      <HelpDialog open={helpOpen} onClose={() => setHelpOpen(false)} />
    </DndContext>
  );
}
