'use client';

import { useEffect, useState } from 'react';

type Report = {
  id: string;
  reportType: string;
  postId: string | null;
  postContent: string | null;
  reason: string;
  details: string | null;
  status: string;
  createdAt: string;
  reporterName: string | null;
  targetName: string | null;
  targetEmail: string;
};

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || 'https://feature-mavo-user-auth-mavo-preview.gstars-business.workers.dev/api/v1').replace(/\/$/, '');
const labels: Record<string, string> = {
  SPAM: 'Spam',
  HARASSMENT: 'Pelecehan / perundungan',
  HATE: 'Ujaran kebencian',
  IMPERSONATION: 'Penyamaran identitas',
  INAPPROPRIATE: 'Konten tidak pantas',
  SCAM: 'Penipuan',
  OTHER: 'Lainnya',
};

export default function SafetyReportsPage() {
  const [token, setToken] = useState('');
  const [reports, setReports] = useState<Report[]>([]);
  const [filter, setFilter] = useState('OPEN');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function load(accessToken: string, status = filter) {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE}/admin/reports?status=${status}&limit=100`, {
        headers: { Authorization: `Bearer ${accessToken}` },
        cache: 'no-store',
      });
      const result = await response.json();
      if (!response.ok || !result.success) throw new Error(result.message || 'Gagal memuat laporan.');
      setReports(result.data || []);
      setError('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Gagal memuat laporan.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const saved = sessionStorage.getItem('MAVO_admin_token');
    if (saved) {
      setToken(saved);
      load(saved, 'OPEN');
    }
  }, []);

  async function updateStatus(id: string, status: string) {
    if (!token) return;
    try {
      const response = await fetch(`${API_BASE}/admin/reports/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ status }),
      });
      const result = await response.json();
      if (!response.ok || !result.success) throw new Error(result.message || 'Status gagal diperbarui.');
      await load(token, filter);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Status gagal diperbarui.');
    }
  }

  if (!token) {
    return <main className="login-wrap"><section className="login-card">
      <div className="brand login-brand">MAVO</div>
      <h1>Login admin diperlukan</h1>
      <p className="login-description">Masuk melalui halaman Overview, lalu buka kembali Safety Reports.</p>
      <a className="primary-button" href="/">Kembali ke login admin</a>
    </section></main>;
  }

  return <div className="shell">
    <aside className="sidebar">
      <div className="brand">MAVO</div>
      <div className="tagline">Yuk, Ketemu. · Admin</div>
      <nav className="nav">
        <a href="/">Overview</a>
        <a href="/users/">Users</a>
        <a href="/providers/">Providers</a>
        <a href="/bookings/">Bookings</a>
        <a href="/payments/">Payments</a>
        <a href="/disputes/">Disputes</a>
        <a className="active" href="/reports/">Safety reports</a>
        <a href="/admins/">Admin management</a>
        <a href="/audit/">Audit log</a>
      </nav>
    </aside>
    <main>
      <div className="top">
        <div><div className="eyebrow">TRUST & SAFETY</div><h1>Safety reports</h1></div>
        <button className="logout-button" onClick={() => { sessionStorage.removeItem('MAVO_admin_token'); window.location.href = '/'; }}>Keluar</button>
      </div>
      <section className="card">
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'space-between' }}>
          <div>
            <div className="eyebrow">TRUST & SAFETY</div>
            <h2>Daftar laporan akun & postingan</h2>
            <p>Periksa konteks laporan, lalu tandai sedang ditinjau, selesai, atau ditolak.</p>
          </div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <select aria-label="Filter status" value={filter} onChange={(e) => { setFilter(e.target.value); if (token) load(token, e.target.value); }}>
              <option value="OPEN">Baru / terbuka</option>
              <option value="REVIEWING">Sedang ditinjau</option>
              <option value="RESOLVED">Selesai</option>
              <option value="DISMISSED">Ditolak</option>
              <option value="ALL">Semua</option>
            </select>
            <button className="logout-button" onClick={() => load(token, filter)} disabled={loading}>Refresh</button>
          </div>
        </div>
        {error && <p className="error-message">{error}</p>}
        {loading && <p>Memuat laporan…</p>}
        {!loading && reports.length === 0 && <p>Belum ada laporan pada filter ini.</p>}
        <div style={{ display: 'grid', gap: 12, marginTop: 16 }}>
          {reports.map((report) => (
            <article key={report.id} style={{ border: '1px solid #e4eaf2', borderRadius: 14, padding: 16 }}>
              <div style={{ display: 'flex', gap: 12, justifyContent: 'space-between', flexWrap: 'wrap' }}>
                <div>
                  <strong>{labels[report.reason] || report.reason}</strong>
                  <p style={{ margin: '6px 0' }}>Jenis: <strong>{report.reportType === 'POST' ? 'Postingan' : 'Akun'}</strong></p>
                  <p style={{ margin: '6px 0' }}>Akun terkait: <strong>{report.targetName || 'Akun tidak bernama'}</strong> ({report.targetEmail})</p>
                  {report.reportType === 'POST' && <div style={{ marginTop: 10, padding: 12, borderRadius: 10, background: '#f5f8fc' }}><strong>Konten yang dilaporkan</strong><p style={{ margin: '6px 0 0', whiteSpace: 'pre-wrap' }}>{report.postContent || 'Postingan sudah tidak tersedia.'}</p></div>}
                  <p style={{ margin: '6px 0' }}>Pelapor: {report.reporterName || 'Pengguna MAVO'}</p>
                  <p style={{ margin: '6px 0', color: '#667085' }}>{new Date(report.createdAt).toLocaleString('id-ID')}</p>
                  {report.details && <p style={{ margin: '10px 0 0', whiteSpace: 'pre-wrap' }}>{report.details}</p>}
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                  <span>{report.status}</span>
                  {report.status === 'OPEN' && <button className="primary-button" onClick={() => updateStatus(report.id, 'REVIEWING')}>Tinjau</button>}
                  {report.status !== 'RESOLVED' && <button className="logout-button" onClick={() => updateStatus(report.id, 'RESOLVED')}>Selesai</button>}
                  {report.status !== 'DISMISSED' && <button className="logout-button" onClick={() => updateStatus(report.id, 'DISMISSED')}>Tolak</button>}
                </div>
              </div>
            </article>
          ))}
        </div>
      </section>
    </main>
  </div>;
}
