import { ListElement as ListType } from '../../types';

export default function ListElement({ element }: { element: ListType }) {
  const items = Array.from({ length: element.maxItems ?? 4 }, (_, i) => `Log entry ${i + 1}`);
  return (
    <div className="el-list" style={{ fontSize: 10, color: '#ccc', overflow: 'hidden' }}>
      {items.map((item, i) => (
        <div key={i} style={{ padding: '1px 0', opacity: 0.5 + (i / items.length) * 0.5 }}>{item}</div>
      ))}
    </div>
  );
}
