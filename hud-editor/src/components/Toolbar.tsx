import { useEditorStore } from '../store';
import { saveFile, loadFile } from '../utils/json-io';
import { HUD_FILE_VERSION } from '../types';

interface ToolbarProps {
  onHelp: () => void;
}

export default function Toolbar({ onHelp }: ToolbarProps) {
  const layouts = useEditorStore((s) => s.layouts);
  const theme = useEditorStore((s) => s.theme);
  const setFile = useEditorStore((s) => s.setFile);
  const undo = useEditorStore((s) => s.undo);
  const redo = useEditorStore((s) => s.redo);

  const handleSave = () => saveFile({ version: HUD_FILE_VERSION, theme, layouts });

  const handleLoad = async () => {
    const loaded = await loadFile();
    if (loaded) setFile(loaded);
  };

  return (
    <div className="toolbar">
      <strong>HUD Editor</strong>
      <span className="toolbar-divider" />
      <span className="toolbar-filename">hud.json</span>
      <span className="toolbar-divider" />
      <button className="toolbar-btn" onClick={undo}>↩ Undo</button>
      <button className="toolbar-btn" onClick={redo}>↪ Redo</button>
      <span className="toolbar-divider" />
      <button className="toolbar-btn" onClick={handleLoad}>📂 Load</button>
      <div className="toolbar-spacer" />
      <button className="toolbar-btn toolbar-save" onClick={handleSave}>💾 Save</button>
      <button className="toolbar-btn toolbar-help" onClick={onHelp} title="Hilfe (F1)">?</button>
    </div>
  );
}
