import { useEditorStore } from '../store';

export default function Toolbar() {
  const layoutMode = useEditorStore((s) => s.layoutMode);
  const undo = useEditorStore((s) => s.undo);
  const redo = useEditorStore((s) => s.redo);

  return (
    <div className="toolbar">
      <strong>HUD Editor</strong>
      <span className="toolbar-divider" />
      <span className="toolbar-filename">{layoutMode}.hud.json</span>
      <span className="toolbar-divider" />
      <button className="toolbar-btn" onClick={undo}>↩ Undo</button>
      <button className="toolbar-btn" onClick={redo}>↪ Redo</button>
      <div className="toolbar-spacer" />
      <button className="toolbar-btn toolbar-save">💾 Save</button>
      <button className="toolbar-btn toolbar-export">📤 Export</button>
    </div>
  );
}
