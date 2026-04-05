import express from 'express';
import { execFile } from 'child_process';
import { readFile, writeFile, mkdir } from 'fs/promises';
import { join } from 'path';

const app = express();
app.use(express.json({ limit: '5mb' }));

const HUD_DIR = join(import.meta.dirname, '..', '..', 'hud');

const SYSTEM_PROMPT = `Du bist ein HUD-Layout-Editor-Assistent für ein Risk-Spiel.
Du bekommst das aktuelle Layout als JSON und eine User-Anweisung.

Antworte IMMER in diesem Format:
---message---
[Deine Erklärung was du geändert hast, auf Deutsch]
---json---
[Das komplette modifizierte JSON]

Regeln:
- Behalte alle bestehenden IDs bei
- Vergib eindeutige IDs für neue Elemente (format: type-N, z.B. label-1, button-2)
- Nutze beschreibende 'description'-Felder auf Deutsch
- Halte die Grid-Struktur valide (rows/cols/children müssen konsistent sein)
- Das Root-Element muss immer type "grid" mit id "root" sein
- Gültige Element-Typen: grid, label, button, slider, icon, list, cardhand, container, spacer
- Grid rows/cols nutzen CSS Grid Syntax: "40px", "1fr", "auto"
- Kinder-Elemente haben row/col für die Position im Eltern-Grid`;

app.post('/api/chat', async (req, res) => {
  const { message, layout } = req.body;

  const prompt = `Aktuelles Layout:\n\`\`\`json\n${JSON.stringify(layout, null, 2)}\n\`\`\`\n\nAnweisung: ${message}`;

  try {
    const result = await new Promise<string>((resolve, reject) => {
      execFile(
        'claude',
        ['--print', '--system-prompt', SYSTEM_PROMPT, prompt],
        { maxBuffer: 10 * 1024 * 1024, timeout: 120000 },
        (error, stdout, stderr) => {
          if (error) reject(new Error(stderr || error.message));
          else resolve(stdout);
        },
      );
    });

    const messagePart = result.split('---json---')[0]?.replace('---message---', '').trim() || result;
    const jsonPart = result.split('---json---')[1]?.trim();

    let parsedLayout = null;
    if (jsonPart) {
      const jsonStr = jsonPart.replace(/^```json?\n?/m, '').replace(/\n?```$/m, '').trim();
      try {
        parsedLayout = JSON.parse(jsonStr);
      } catch (e) {
        console.error('Failed to parse Claude JSON response:', e);
      }
    }

    res.json({ message: messagePart, layout: parsedLayout });
  } catch (error) {
    console.error('Claude CLI error:', error);
    res.status(500).json({
      message: `Claude CLI Fehler: ${error instanceof Error ? error.message : 'Unbekannt'}`,
      layout: null,
    });
  }
});

app.post('/api/save', async (req, res) => {
  const { filename, content } = req.body;
  if (typeof filename !== 'string' || !/^[a-z0-9-]+\.hud\.json$/.test(filename)) {
    res.status(400).json({ error: 'Invalid filename. Must match <name>.hud.json' });
    return;
  }
  try {
    await mkdir(HUD_DIR, { recursive: true });
    await writeFile(join(HUD_DIR, filename), content, 'utf-8');
    res.json({ ok: true, path: join(HUD_DIR, filename) });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

app.get('/api/layout/:name', async (req, res) => {
  const { name } = req.params;
  if (!/^[a-z0-9-]+$/.test(name)) {
    res.status(400).json({ error: 'Invalid layout name' });
    return;
  }
  try {
    const content = await readFile(join(HUD_DIR, `${name}.hud.json`), 'utf-8');
    res.json(JSON.parse(content));
  } catch {
    res.status(404).json({ error: 'Layout not found' });
  }
});

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`HUD Editor Proxy running on http://localhost:${PORT}`);
  console.log(`Saving layouts to ${HUD_DIR}`);
});
