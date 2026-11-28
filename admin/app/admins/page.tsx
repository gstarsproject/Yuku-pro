'use client';

import { FormEvent, useEffect, useState } from 'react';

type AdminUser = {
  id: string;
  email: string;
  role: 'ADMIN' | 'SUPERADMIN';
  status: string;
  displayName: string | null;
  createdAt: string;
};

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || 'https://feature-mavo-user-auth-mavo-preview.gstars-business.workers.dev/api/v1').replace(/\/$/, '');

export default function AdminsPage() {
  const [token, setToken] = useState('');
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [email, setEmail] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  async function load(accessToken: string) {
    const response = await fetch(`${API_BASE}/admin/users`, {
      headers: { Authorization: `Bearer ${accessToken}` },
      cache: 'no-store',
    });
    const result = await response.json();
    if (!response.ok || !result.success) throw new Error(result.message || 'Gagal memuat akun admin.');
    setAdmins(result.data || []);
  }

  useEffect(() => {
    const saved = sessionStorage.getItem('MAVO_admin_token');
    if (saved) {
      setToken(saved);
      load(saved).catch((err: Error) => setError(err.message));
    } else {
      setError('Login admin diperlukan. Kembali ke halaman Overview.');
    }
  }, []);

  async function createAdmin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;
    setLoading(true);
    setError('');
    setMessage('');
    try {
      const response = await fetch(`${API_BASE}/admin/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ email, displayName, password }),
      });
      const result = await response.json();
      if (!response.ok || !result.success) throw new Error(result.message || 'Gagal membuat Admin.');
      setMessage(`Akun Admin ${email} berhasil dibuat.`);
      setEmail('');
      setDisplayName('');
      setPassword('');
      await load(token);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Gagal membuat Admin.');
    } finally {
      setLoading(false);
    }
  }

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
        <a className="active" href="/admins/">Admin management</a>
        <a href="/audit/">Audit log</a>
      </nav>
    </aside>
    <main>
      <div className="top">
        <div><div className="eyebrow">ACCESS CONTROL</div><h1>Admin management</h1></div>
        <a className="logout-button" href="/">Kembali</a>
      </div>
      {error && <p className="error-message">{error}</p>}
      {message && <p>{message}</p>}
      <section className="card">
        <h2>Buat akun Admin operasional</h2>
        <p>Hanya SUPERADMIN yang dapat membuat akun Admin. Password minimal 16 karakter.</p>
        <form onSubmit={createAdmin} style={{ display: 'grid', gap: 12, maxWidth: 520 }}>
          <label htmlFor="admin-name">Nama Admin</label>
          <input id="admin-name" value={displayName} onChange={e => setDisplayName(e.target.value)} minLength={2} maxLength={60} required />
          <label htmlFor="admin-email">Email Admin</label>
          <input id="admin-email" type="email" value={email} onChange={e => setEmail(e.target.value)} required />
          <label htmlFor="admin-password">Password sementara</label>
          <input id="admin-password" type="password" value={password} onChange={e => setPassword(e.target.value)} minLength={16} maxLength={128} required />
          <button className="primary-button" type="submit" disabled={loading}>{loading ? 'Menyimpan…' : 'Buat akun Admin'}</button>
        </form>
      </section>
      <section className="card" style={{ marginTop: 20 }}>
        <h2>Daftar administrator</h2>
        <button className="logout-button" onClick={() => load(token).catch((err: Error) => setError(err.message))}>Refresh</button>
        <div style={{ display: 'grid', gap: 10, marginTop: 14 }}>
          {admins.map(admin => <article key={admin.id} style={{ border: '1px solid #e4eaf2', borderRadius: 12, padding: 14 }}>
            <strong>{admin.displayName || 'Tanpa nama'}</strong>
            <p style={{ margin: '5px 0' }}>{admin.email}</p>
            <p style={{ margin: 0 }}>{admin.role} · {admin.status}</p>
          </article>)}
          {admins.length === 0 && <p>Belum ada data administrator atau akses tidak tersedia.</p>}
        </div>
      </section>
    </main>
  </div>;
}
