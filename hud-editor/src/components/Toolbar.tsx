import { useEditorStore } from '../store';
import { saveLayout, loadLayout } from '../utils/json-io';

export default function Toolbar() {
  const layout = useEditorStore((s) => s.layout);
  const layoutMode = useEditorStore((s) => s.layoutMode);
  const setLayout = useEditorStore((s) => s.setLayout);
  const undo = useEditorStore((s) => s.undo);
  const redo = useEditorStore((s) => s.redo);

  const handleSave = () => saveLayout(layout);

  const handleLoad = async () => {
    const loaded = await loadLayout();
    if (loaded) setLayout(loaded);
  };

  return (
    <div className="toolbar">
      <strong>HUD Editor</strong>
      <span className="toolbar-divider" />
      <span className="toolbar-filename">{layoutMode}.hud.json</span>
      <span className="toolbar-divider" />
      <button className="toolbar-btn" onClick={undo}>↩ Undo</button>
      <button className="toolbar-btn" onClick={redo}>↪ Redo</button>
      <span className="toolbar-divider" />
      <button className="toolbar-btn" onClick={handleLoad}>📂 Load</button>
      <div className="toolbar-spacer" />
      <button className="toolbar-btn toolbar-save" onClick={handleSave}>💾 Save</button>
    </div>
  );
}
