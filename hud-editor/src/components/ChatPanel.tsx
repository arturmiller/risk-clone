import { useState, useRef, useEffect } from 'react';
import { useEditorStore } from '../store';
import { HudLayout } from '../types';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

export default function ChatPanel() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const layout = useEditorStore((s) => s.layout);
  const setLayout = useEditorStore((s) => s.setLayout);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = async () => {
    if (!input.trim() || loading) return;

    const userMessage = input.trim();
    setInput('');
    setMessages((prev) => [...prev, { role: 'user', content: userMessage }]);
    setLoading(true);

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: userMessage, layout }),
      });

      if (!response.ok) throw new Error('Chat request failed');

      const data = await response.json();
      setMessages((prev) => [...prev, { role: 'assistant', content: data.message }]);

      if (data.layout) {
        setLayout(data.layout as HudLayout);
      }
    } catch (err) {
      setMessages((prev) => [
        ...prev,
        { role: 'assistant', content: `Fehler: ${err instanceof Error ? err.message : 'Unbekannter Fehler'}. Läuft der Proxy? (npm run proxy)` },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="panel chat-panel">
      <div className="chat-header">
        <span>💬 <strong>Claude Chat</strong></span>
        <span className="chat-hint">— UI-Elemente generieren und ändern</span>
      </div>
      <div className="chat-messages">
        {messages.map((msg, i) => (
          <div key={i} className={`chat-msg chat-msg-${msg.role}`}>
            <span className="chat-msg-role">{msg.role === 'user' ? 'Du' : 'Claude'}:</span>
            <div className="chat-msg-content">{msg.content}</div>
          </div>
        ))}
        {loading && (
          <div className="chat-msg chat-msg-assistant">
            <span className="chat-msg-role">Claude:</span>
            <div className="chat-msg-content chat-loading">Denkt nach...</div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>
      <div className="chat-input-row">
        <input
          className="chat-input"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Nachricht eingeben..."
          disabled={loading}
        />
        <button className="chat-send" onClick={sendMessage} disabled={loading}>
          Senden
        </button>
      </div>
    </div>
  );
}
