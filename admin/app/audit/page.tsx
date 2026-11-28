'use client';

import { useEffect, useState } from 'react';

type AuditEntry = {
  id: string;
  action: string;
  targetType: string;
  targetId: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: string;
  actorEmail: string;
};

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || 'https://feature-mavo-user-auth-mavo-preview.gstars-business.workers.dev/api/v1').replace(/\/$/, '');

export default function AuditPage() {
  const [token, setToken] = useState('');
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function load(accessToken: string) {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE}/admin/audit-logs?limit=150`, {
        headers: { Authorization: `Bearer ${accessToken}` },
        cache: 'no-store',
      });
      const result = await response.json();
      if (!response.ok || !result.success) throw new Error(result.message || 'Gagal memuat Audit Log.');
      setEntries(result.data || []);
      setError('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Gagal memuat Audit Log.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const saved = sessionStorage.getItem('MAVO_admin_token');
    if (saved) {
      setToken(saved);
      load(saved);
    } else {
      setError('Login Superadmin diperlukan. Kembali ke halaman Overview.');
    }
  }, []);

  return <div className="shell">
    <aside className="sidebar">
      <div className="brand">MAVO</div>
      <div className="tagline">Yuk, Ketemu. · Control</div>
      <nav className="nav">
        <a href="/">Overview</a>
        <a href="/users/">Users</a>
        <a href="/providers/">Providers</a>
        <a href="/bookings/">Bookings</a>
        <a href="/payments/">Payments</a>
        <a href="/disputes/">Disputes</a>
        <a href="/reports/">Safety reports</a>
        <a href="/admins/">Admin management</a>
        <a className="active" href="/audit/">Audit log</a>
      </nav>
    </aside>
    <main>
      <div className="top">
        <div><div className="eyebrow">SECURITY & ACCOUNTABILITY</div><h1>Audit log</h1></div>
        <button className="logout-button" onClick={() => load(token)} disabled={loading}>Refresh</button>
      </div>
      {error && <p className="error-message">{error}</p>}
      {loading && <p>Memuat catatan aktivitas…</p>}
      <section className="card">
        <p>Catatan login administrator, pembuatan akun Admin, bootstrap Superadmin, dan perubahan status laporan.</p>
        <div style={{ display: 'grid', gap: 10 }}>
          {entries.map(entry => <article key={entry.id} style={{ border: '1px solid #e4eaf2', borderRadius: 12, padding: 14 }}>
            <strong>{entry.action}</strong>
            <p style={{ margin: '5px 0' }}>Pelaku: {entry.actorEmail}</p>
            <p style={{ margin: '5px 0' }}>Target: {entry.targetType} {entry.targetId || ''}</p>
            <p style={{ margin: '5px 0', color: '#667085' }}>{new Date(entry.createdAt).toLocaleString('id-ID')}</p>
            {entry.metadata && <pre style={{ whiteSpace: 'pre-wrap', overflowWrap: 'anywhere', margin: 0 }}>{JSON.stringify(entry.metadata, null, 2)}</pre>}
          </article>)}
          {!loading && entries.length === 0 && <p>Belum ada catatan aktivitas.</p>}
        </div>
      </section>
    </main>
  </div>;
}
