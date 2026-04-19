import { useEffect, useState, useCallback } from 'react';
import { DndContext, DragEndEvent, PointerSensor, useSensor, useSensors } from '@dnd-kit/core';
import { useEditorStore } from './store';
import { ElementType, HUD_FILE_VERSION } from './types';
import { saveFile } from './utils/json-io';
import { validateHudFile } from './utils/validate';
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
  const setFile = useEditorStore((s) => s.setFile);
  const [helpOpen, setHelpOpen] = useState(false);
  const toggleHelp = useCallback(() => setHelpOpen((v) => !v), []);
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
  );

  useEffect(() => {
    fetch('/api/hud')
      .then((r) => (r.ok ? r.json() : null))
      .then((data: unknown) => {
        if (!data) return;
        const result = validateHudFile(data);
        if (result.ok) {
          setFile(result.file);
        } else {
          console.warn('hud.json failed validation:\n', result.errors.join('\n'));
        }
      })
      .catch(() => {});
  }, [setFile]);

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
        const s = useEditorStore.getState();
        saveFile({ version: HUD_FILE_VERSION, theme: s.theme, layouts: s.layouts });
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
    <DndContext sensors={sensors} onDragEnd={handleDragEnd}>
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
