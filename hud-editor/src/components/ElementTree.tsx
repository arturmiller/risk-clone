import { HudElement, GridElement } from '../types';
import { useEditorStore } from '../store';

function TreeNode({ element, depth }: { element: HudElement; depth: number }) {
  const selectedId = useEditorStore((s) => s.selectedId);
  const selectElement = useEditorStore((s) => s.selectElement);
  const isSelected = selectedId === element.id;

  const icon =
    element.type === 'grid' ? '⊞' :
    element.type === 'label' ? '📝' :
    element.type === 'button' ? '🔘' :
    element.type === 'slider' ? '🎚️' :
    element.type === 'icon' ? '⭐' :
    element.type === 'list' ? '📋' :
    element.type === 'cardhand' ? '🃏' :
    element.type === 'container' ? '📦' : '↔️';

  return (
    <>
      <div
        className={`tree-node ${isSelected ? 'tree-node-selected' : ''}`}
        style={{ paddingLeft: depth * 16 }}
        onClick={() => selectElement(element.id)}
      >
        {icon} {element.id}
      </div>
      {'children' in element &&
        (element as GridElement).children.map((child) => (
          <TreeNode key={child.id} element={child} depth={depth + 1} />
        ))}
    </>
  );
}

export default function ElementTree() {
  const root = useEditorStore((s) => s.layout.root);
  return (
    <div className="element-tree">
      <TreeNode element={root} depth={0} />
    </div>
  );
}
