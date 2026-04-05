import { ButtonElement as ButtonType } from '../../types';

export default function ButtonElement({ element }: { element: ButtonType }) {
  return (
    <div className="el-button" style={{ background: element.style?.background ?? '#2d5a2d', color: element.style?.color ?? '#fff', borderRadius: element.style?.borderRadius ?? 4, padding: element.style?.padding ?? '4px 12px', fontSize: element.style?.fontSize ?? 11, textAlign: 'center' }}>
      {element.text}
    </div>
  );
}
