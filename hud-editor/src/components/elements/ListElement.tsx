import { ListElement as ListType } from '../../types';
import { applyStyle } from '../../utils/style';
import { useEditorStore } from '../../store';

export default function ListElement({ element }: { element: ListType }) {
  const items = Array.from({ length: element.maxItems ?? 4 }, (_, i) => `Log entry ${i + 1}`);
  const theme = useEditorStore((s) => s.theme);
  const s = applyStyle(element.style, theme);
  const isBound = !!element.itemBinding;
  return (
    <div
      className={`el-list${isBound ? ' el-list-bound' : ''}`}
      title={isBound ? `{${element.itemBinding}}` : undefined}
      style={{
        fontSize: element.style?.fontSize ?? 10,
        color: element.style?.color ?? '#ccc',
        overflow: 'hidden',
        ...s,
      }}
    >
      {items.map((item, i) => (
        <div
          key={i}
          style={{
            padding: '1px 0',
            opacity: 0.5 + (i / items.length) * 0.5,
            textDecoration: isBound ? 'underline dotted rgba(255,255,255,0.4)' : undefined,
            textUnderlineOffset: isBound ? 3 : undefined,
          }}
        >
          {item}
        </div>
      ))}
    </div>
  );
}
