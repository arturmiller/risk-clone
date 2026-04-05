export default function CardhandElement() {
  return (
    <div className="el-cardhand" style={{ display: 'flex', gap: 4 }}>
      {['🂡', '🂢', '🂣'].map((card, i) => (
        <div key={i} style={{ background: '#1a1a3e', border: '1px solid #444', borderRadius: 3, padding: '4px 8px', fontSize: 14 }}>{card}</div>
      ))}
    </div>
  );
}
