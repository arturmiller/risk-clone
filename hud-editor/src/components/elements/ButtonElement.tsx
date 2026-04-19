import { ButtonElement as ButtonType } from '../../types';
import { applyStyle } from '../../utils/style';
import { useEditorStore } from '../../store';

export default function ButtonElement({ element }: { element: ButtonType }) {
  const theme = useEditorStore((s) => s.theme);
  const s = applyStyle(element.style, theme);
  const isSelected = element.selected === true;
  const isBound = !!element.binding;
  return (
    <div
      className={`el-button${isSelected ? ' el-button-selected' : ''}${isBound ? ' el-button-bound' : ''}`}
      title={isBound ? `{${element.binding}}` : undefined}
      style={{
        background: element.style?.background ?? '#2d5a2d',
        color: element.style?.color ?? '#fff',
        borderRadius: element.style?.borderRadius ?? 4,
        padding: element.style?.padding ?? '4px 12px',
        fontSize: element.style?.fontSize ?? 11,
        textAlign: 'center',
        ...s,
        outline: isSelected ? `2px solid ${theme.text}` : undefined,
        outlineOffset: isSelected ? 1 : undefined,
        textDecoration: isBound ? 'underline dotted rgba(255,255,255,0.4)' : s.textDecoration,
        textUnderlineOffset: isBound ? 3 : undefined,
      }}
    >
      {element.text}
    </div>
  );
}
