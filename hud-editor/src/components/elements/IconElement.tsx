import { IconElement as IconType } from '../../types';
import { applyStyle } from '../../utils/style';
import { useEditorStore } from '../../store';

const ICON_MAP: Record<string, string> = {
  star: '⭐',
  shield: '🛡️',
  flag: '🏴',
  person: '👤',
  smart_toy: '🤖',
  style: '🂠',
  settings: '⚙️',
  close: '✕',
  check: '✓',
  arrow_right: '➜',
  arrow_left: '⬅',
  info: 'ℹ️',
  warning: '⚠️',
};

export default function IconElement({ element }: { element: IconType }) {
  const theme = useEditorStore((s) => s.theme);
  const s = applyStyle(element.style, theme);
  const glyph = ICON_MAP[element.name] ?? '●';
  return (
    <span
      className="el-icon"
      style={{
        fontSize: element.style?.fontSize ?? 18,
        color: element.style?.color ?? '#FFB300',
        ...s,
      }}
    >
      {glyph}
    </span>
  );
}
