import { ContainerElement as ContainerType } from '../../types';

export default function ContainerElement({ element }: { element: ContainerType }) {
  return (
    <div className="el-container" style={{ background: element.style?.background ?? 'rgba(62,39,12,0.5)', border: `1px solid ${element.style?.border ?? 'rgba(255,193,7,0.3)'}`, borderRadius: element.style?.borderRadius ?? 6, padding: element.style?.padding ?? '8px', minHeight: 40 }} />
  );
}
