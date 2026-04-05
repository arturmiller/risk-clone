import { DndContext, DragEndEvent } from '@dnd-kit/core';
import { useEditorStore } from './store';
import { ElementType } from './types';
import Toolbar from './components/Toolbar';
import ElementLibrary from './components/ElementLibrary';
import Canvas from './components/Canvas';
import PropertiesPanel from './components/PropertiesPanel';
import ChatPanel from './components/ChatPanel';

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
    </DndContext>
  );
}
