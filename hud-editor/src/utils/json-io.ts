import { HudFile } from '../types';
import { validateHudFile } from './validate';

export async function saveFile(file: HudFile): Promise<void> {
  const json = JSON.stringify(file, null, 2);

  try {
    const response = await fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content: json }),
    });
    if (response.ok) return;
  } catch {
    // Proxy not running, fall through to download
  }

  const blob = new Blob([json], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'hud.json';
  a.click();
  URL.revokeObjectURL(url);
}

export async function loadFile(): Promise<HudFile | null> {
  return new Promise((resolve) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return resolve(null);
      const text = await file.text();
      let parsed: unknown;
      try {
        parsed = JSON.parse(text);
      } catch {
        alert('Invalid JSON file');
        return resolve(null);
      }
      const result = validateHudFile(parsed);
      if (!result.ok) {
        alert(`Invalid HUD file:\n\n- ${result.errors.slice(0, 10).join('\n- ')}${result.errors.length > 10 ? `\n… (+${result.errors.length - 10} more)` : ''}`);
        return resolve(null);
      }
      resolve(result.file);
    };
    input.click();
  });
}
