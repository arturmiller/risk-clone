import { IconElement as IconType } from '../../types';

export default function IconElement({ element }: { element: IconType }) {
  return (
    <span className="el-icon" style={{ fontSize: element.style?.fontSize ?? 18, color: element.style?.color ?? '#FFB300' }}>
      {element.name === 'star' ? '⭐' : element.name === 'shield' ? '🛡️' : element.name === 'flag' ? '🏴' : '●'}
    </span>
  );
}
