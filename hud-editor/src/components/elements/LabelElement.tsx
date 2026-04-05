import { LabelElement as LabelType } from '../../types';

export default function LabelElement({ element }: { element: LabelType }) {
  return (
    <span className="el-label" style={{ fontSize: element.style?.fontSize ?? 12, color: element.style?.color ?? '#FFB300', fontWeight: element.style?.fontWeight ?? 'normal' }}>
      {element.text}
    </span>
  );
}
