import { useEffect } from 'react';

interface HelpDialogProps {
  open: boolean;
  onClose: () => void;
}

export default function HelpDialog({ open, onClose }: HelpDialogProps) {
  useEffect(() => {
    if (!open) return;
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' || e.key === 'F1') onClose();
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="help-overlay" onClick={onClose}>
      <div className="help-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="help-header">
          <h2>Hilfe — HUD Editor</h2>
          <button className="help-close" onClick={onClose}>✕</button>
        </div>
        <div className="help-body">

          <section>
            <h3>Navigation</h3>
            <table>
              <tbody>
                <tr><td className="help-key">Mausrad</td><td>Zoom rein/raus</td></tr>
                <tr><td className="help-key">Mittelklick + Drag</td><td>Ansicht verschieben</td></tr>
                <tr><td className="help-key">Alt + Linksklick + Drag</td><td>Ansicht verschieben</td></tr>
                <tr><td className="help-key">✋ Hand-Modus</td><td>Linksklick verschiebt die Ansicht</td></tr>
                <tr><td className="help-key">↖ Pointer-Modus</td><td>Normales Auswählen und Bearbeiten</td></tr>
                <tr><td className="help-key">⊡ Button</td><td>Ansicht zurücksetzen (100%, zentriert)</td></tr>
              </tbody>
            </table>
          </section>

          <section>
            <h3>Elemente</h3>
            <table>
              <tbody>
                <tr><td className="help-key">Drag aus Library</td><td>Neues Element in eine Grid-Zelle ziehen</td></tr>
                <tr><td className="help-key">Klick auf Element</td><td>Element auswählen (Eigenschaften rechts)</td></tr>
                <tr><td className="help-key">Rechtsklick</td><td>Kontextmenü (Split, Merge, Duplizieren, Löschen)</td></tr>
                <tr><td className="help-key">Element-Baum</td><td>Im rechten Panel auf einen Eintrag klicken</td></tr>
              </tbody>
            </table>
          </section>

          <section>
            <h3>Grid bearbeiten</h3>
            <table>
              <tbody>
                <tr><td className="help-key">Rechtsklick → Split</td><td>Grid-Zelle horizontal/vertikal teilen</td></tr>
                <tr><td className="help-key">Rechtsklick → Merge</td><td>Letzte Spalte/Zeile eines Grids entfernen</td></tr>
                <tr><td className="help-key">Grid-Grenze ziehen</td><td>Proportionen der Spalten/Zeilen anpassen</td></tr>
                <tr><td className="help-key">Rows/Cols im Panel</td><td>Grid-Tracks direkt eingeben (z.B. "1fr, auto, 40px")</td></tr>
              </tbody>
            </table>
          </section>

          <section>
            <h3>Tastenkürzel</h3>
            <table>
              <tbody>
                <tr><td className="help-key">Delete</td><td>Ausgewähltes Element löschen</td></tr>
                <tr><td className="help-key">Ctrl+D</td><td>Element duplizieren</td></tr>
                <tr><td className="help-key">Ctrl+Z</td><td>Rückgängig</td></tr>
                <tr><td className="help-key">Ctrl+Y</td><td>Wiederholen</td></tr>
                <tr><td className="help-key">Ctrl+S</td><td>Layout speichern</td></tr>
                <tr><td className="help-key">Escape</td><td>Auswahl aufheben</td></tr>
                <tr><td className="help-key">F1</td><td>Hilfe ein-/ausblenden</td></tr>
              </tbody>
            </table>
          </section>

          <section>
            <h3>Claude Chat</h3>
            <p>Im Chat unten kannst du Claude bitten, UI-Elemente zu erstellen oder zu ändern. Beispiele:</p>
            <ul>
              <li>"Erstelle eine PlayerInfoBar oben mit beiden Spielern"</li>
              <li>"Mach die ActionBar dreispaltig mit Attack, Blitz und End-Button"</li>
              <li>"Füge ein Label mit dem Text 'RISK' in die Mitte der oberen Leiste"</li>
              <li>"Ändere die Hintergrundfarbe der ActionBar zu dunkelbraun"</li>
            </ul>
            <p style={{ marginTop: 8, color: '#888' }}>Der Chat benötigt den Proxy: <code>npm run proxy</code></p>
          </section>

          <section>
            <h3>Speichern &amp; Laden</h3>
            <table>
              <tbody>
                <tr><td className="help-key">💾 Save</td><td>Speichert als .hud.json in den hud/ Ordner (oder Download)</td></tr>
                <tr><td className="help-key">📂 Load</td><td>Lädt eine .hud.json Datei vom Computer</td></tr>
              </tbody>
            </table>
            <p style={{ marginTop: 8, color: '#888' }}>Beschreibungen pro Element helfen Claude CLI später bei der Datenbindung.</p>
          </section>

        </div>
      </div>
    </div>
  );
}
