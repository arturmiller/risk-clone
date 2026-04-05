import { useEditorStore } from '../store';
import GridCell from './GridCell';

export default function Canvas() {
  const layout = useEditorStore((s) => s.layout);
  const layoutMode = useEditorStore((s) => s.layoutMode);
  const selectElement = useEditorStore((s) => s.selectElement);

  const isMobile = layoutMode === 'mobile-portrait';
  const frameWidth = isMobile ? 390 : 800;
  const frameHeight = isMobile ? 844 : 500;
  const scale = 0.65;

  return (
    <div className="canvas" onClick={() => selectElement(null)}>
      <div
        className={`canvas-frame ${isMobile ? 'frame-mobile' : 'frame-desktop'}`}
        style={{
          width: frameWidth * scale,
          height: frameHeight * scale,
        }}
      >
        <div
          className="canvas-content"
          style={{
            width: frameWidth,
            height: frameHeight,
            transform: `scale(${scale})`,
            transformOrigin: 'top left',
          }}
        >
          <GridCell element={layout.root} />
        </div>
      </div>
    </div>
  );
}
