import { HudLayout } from '../types';

export async function saveLayout(layout: HudLayout): Promise<void> {
  const filename = `${layout.name}.hud.json`;
  const json = JSON.stringify(layout, null, 2);

  try {
    const response = await fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ filename, content: json }),
    });
    if (response.ok) return;
  } catch {
    // Proxy not running, fall through to download
  }

  const blob = new Blob([json], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export async function loadLayout(): Promise<HudLayout | null> {
  return new Promise((resolve) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json,.hud.json';
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return resolve(null);
      const text = await file.text();
      try {
        resolve(JSON.parse(text) as HudLayout);
      } catch {
        alert('Invalid JSON file');
        resolve(null);
      }
    };
    input.click();
  });
}
