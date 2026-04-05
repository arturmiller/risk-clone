import { SliderElement as SliderType } from '../../types';

export default function SliderElement({ element }: { element: SliderType }) {
  return (
    <div className="el-slider">
      <input type="range" min={element.min ?? 0} max={element.max ?? 100} step={element.step ?? 1} style={{ width: '100%', pointerEvents: 'none' }} />
    </div>
  );
}
