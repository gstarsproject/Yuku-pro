'use client';

import { useEffect, useState } from 'react';

type RequestItem = {
  id: string; creatorName: string; handle: string; category: string; reason: string;
  documentKeys: string[]; submittedAt: string; user: { id: string; email: string | null; displayName: string | null };
};
const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\\/$/, '') || '';

export default function CreatorVerificationPage() {
  const [token, setToken] = useState('');
  const [items, setItems] = useState<RequestItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState('');

  async function load(accessToken: string) {
    if (!API_BASE) throw new Error('NEXT_PUBLIC_API_BASE_URL belum dikonfigurasi.');
    const response = await fetch(`${API_BASE}/admin/creators/pending`, { headers: { Authorization: `Bearer ${accessToken}` }, cache: 'no-store' });
    const body = await response.json();
    if (!response.ok || body.success !== true) throw new Error(body.message || 'Gagal memuat antrean verifikasi.');
    setItems(body.data || []);
  }

  useEffect(() => {
    const saved = sessionStorage.getItem('yuku_admin_token') || '';
    setToken(saved);
    if (!saved) { setError('Sesi admin tidak ditemukan. Login melalui dashboard terlebih dahulu.'); setLoading(false); return; }
    load(saved).catch((e: Error) => setError(e.message)).finally(() => setLoading(false));
  }, []);

  async function review(id: string, status: 'VERIFIED' | 'REJECTED') {
    const rejectionReason = status === 'REJECTED' ? window.prompt('Alasan penolakan untuk kreator:') : null;
    if (status === 'REJECTED' && !rejectionReason?.trim()) return;
    if (!token) return;
    setBusy(id); setError('');
    try {
      const response = await fetch(`${API_BASE}/admin/creators/${id}/review`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ status, rejectionReason }),
      });
      const body = await response.json();
      if (!response.ok || body.success !== true) throw new Error(body.message || 'Gagal menyimpan keputusan.');
      await load(token);
    } catch (e) { setError(e instanceof Error ? e.message : 'Terjadi kesalahan.'); }
    finally { setBusy(''); }
  }

  return <div className="shell"><aside className="sidebar"><div className="brand">MAVO</div><div className="tagline">Creator operations</div><nav className="nav"><a href="/">Overview</a><a className="active" href="/creators/">Creator Verified</a></nav></aside>
    <main><div className="top"><div><div className="eyebrow">CREATOR ECONOMY</div><h1>Creator Verified</h1><p>Periksa identitas dan informasi kreator sebelum memberi badge resmi.</p></div><a href="/">Kembali ke dashboard</a></div>
      {error && <p className="error-message">{error}</p>}
      {loading ? <p>Memuat pengajuan…</p> : items.length === 0 ? <section className="card"><h2>Belum ada pengajuan</h2><p>Pengajuan baru akan muncul di halaman ini.</p></section> : <section className="grid" style={{ gridTemplateColumns: '1fr' }}>
        {items.map((item) => <article className="card" key={item.id} style={{ padding: 22 }}>
          <div className="eyebrow">Diajukan {new Date(item.submittedAt).toLocaleString('id-ID')}</div>
          <h2>{item.creatorName} · @{item.handle}</h2>
          <p><strong>Kategori:</strong> {item.category}</p><p><strong>Akun MAVO:</strong> {item.user.displayName || item.user.email || item.user.id}</p>
          <p><strong>Alasan pengajuan:</strong><br />{item.reason}</p>
          <p><strong>Dokumen:</strong> {item.documentKeys.length ? item.documentKeys.join(', ') : 'Belum ada dokumen terlampir.'}</p>
          <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
            <button className="primary-button" disabled={busy === item.id} onClick={() => review(item.id, 'VERIFIED')}>{busy === item.id ? 'Memproses…' : 'Setujui & beri badge'}</button>
            <button className="logout-button" disabled={busy === item.id} onClick={() => review(item.id, 'REJECTED')}>Tolak</button>
          </div>
        </article>)}
      </section>}
    </main></div>;
}
