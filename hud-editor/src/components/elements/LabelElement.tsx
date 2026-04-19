import { LabelElement as LabelType } from '../../types';
import { applyStyle } from '../../utils/style';
import { useEditorStore } from '../../store';

export default function LabelElement({ element }: { element: LabelType }) {
  const theme = useEditorStore((s) => s.theme);
  const s = applyStyle(element.style, theme);
  const isBound = !!element.binding;
  return (
    <span
      className={`el-label${isBound ? ' el-label-bound' : ''}`}
      title={isBound ? `{${element.binding}}` : undefined}
      style={{
        fontSize: element.style?.fontSize ?? 12,
        color: element.style?.color ?? '#FFB300',
        fontWeight: element.style?.fontWeight ?? 'normal',
        width: '100%',
        display: 'inline-block',
        ...s,
        textDecoration: isBound ? 'underline dotted rgba(255,255,255,0.4)' : s.textDecoration,
        textUnderlineOffset: isBound ? 3 : undefined,
      }}
    >
      {element.text}
    </span>
  );
}
