'use client';

import { FormEvent, useEffect, useState } from 'react';

type Overview = {
  totalUsers: number;
  activeProviders: number;
  bookingsToday: number;
  openDisputes: number;
};

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || 'https://feature-mavo-user-auth-mavo-preview.gstars-business.workers.dev/api/v1').replace(/\/$/, '');

export default function DashboardPage() {
  const [token, setToken] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [overview, setOverview] = useState<Overview | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function loadOverview(accessToken: string) {
    if (!API_BASE) {
      setError('Alamat API backend belum dikonfigurasi di Cloudflare Pages.');
      return;
    }
    const response = await fetch(`${API_BASE}/admin/overview`, {
      headers: { Authorization: `Bearer ${accessToken}` },
      cache: 'no-store',
    });
    if (response.status === 401) {
      sessionStorage.removeItem('MAVO_admin_token');
      setToken('');
      setOverview(null);
      setError('Sesi berakhir. Silakan login kembali.');
      return;
    }
    if (!response.ok) throw new Error('Gagal mengambil data dashboard dari server.');
    const result = await response.json();
    if (!result.success || !result.data) throw new Error(result.message || 'Respons dashboard tidak valid.');
    setOverview(result.data);
    setError('');
  }

  useEffect(() => {
    const saved = sessionStorage.getItem('MAVO_admin_token');
    if (saved) {
      setToken(saved);
      loadOverview(saved).catch((err: Error) => setError(err.message));
    }
  }, []);

  async function handleLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError('');
    try {
      if (!API_BASE) throw new Error('NEXT_PUBLIC_API_BASE_URL belum diatur di Cloudflare Pages.');
      const response = await fetch(`${API_BASE}/admin/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || 'Email atau password tidak valid.');
      if (!result.success || !result.data?.accessToken) throw new Error(result.message || 'Login admin gagal.');
      sessionStorage.setItem('MAVO_admin_token', result.data.accessToken);
      setToken(result.data.accessToken);
      setPassword('');
      await loadOverview(result.data.accessToken);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login gagal. Coba lagi.');
    } finally {
      setLoading(false);
    }
  }

  function logout() {
    if (token) void fetch(`${API_BASE}/auth/logout`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } }).catch(() => undefined);
    sessionStorage.removeItem('MAVO_admin_token');
    setToken('');
    setOverview(null);
    setPassword('');
    setError('');
  }

  if (!token || !overview) {
    return (
      <main className="login-wrap">
        <form className="login-card" onSubmit={handleLogin}>
          <div className="brand login-brand">MAVO</div>
          <p className="login-kicker">MAVO OPERATIONS</p>
          <h1>Admin Sign In</h1>
          <p className="login-description">Masuk ke panel pengelolaan marketplace MAVO.</p>
          <label htmlFor="email">Email admin</label>
          <input id="email" type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} required />
          <label htmlFor="password">Password</label>
          <input id="password" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required />
          {error && <p className="error-message">{error}</p>}
          <button className="primary-button" type="submit" disabled={loading}>{loading ? 'Memproses…' : 'Masuk ke Dashboard'}</button>
          <p className="login-footnote">Akses khusus administrator resmi MAVO.</p>
        </form>
      </main>
    );
  }

  const metrics = [
    { label: 'Total pengguna', value: overview.totalUsers },
    { label: 'Provider aktif', value: overview.activeProviders },
    { label: 'Booking hari ini', value: overview.bookingsToday },
    { label: 'Sengketa terbuka', value: overview.openDisputes },
  ];

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">MAVO</div>
        <div className="tagline">Yuk, Ketemu. · Admin</div>
        <nav className="nav">
          <a className="active" href="/">Overview</a>
          <a href="/users/">Users</a>
          <a href="/providers/">Providers</a>
          <a href="/bookings/">Bookings</a>
          <a href="/payments/">Payments</a>
          <a href="/disputes/">Disputes</a>
        </nav>
      </aside>
      <main>
        <div className="top">
          <div><div className="eyebrow">MAVO OPERATIONS</div><h1>Business overview</h1></div>
          <button className="logout-button" onClick={logout}>Keluar</button>
        </div>
        <section className="grid">
          {metrics.map((item) => (
            <article className="card" key={item.label}>
              <div className="eyebrow">{item.label}</div>
              <div className="metric">{item.value.toLocaleString('id-ID')}</div>
            </article>
          ))}
        </section>
        <section className="card" style={{ marginTop: 20 }}>
          <h2>Status dashboard</h2>
          <p>Data ditarik langsung dari API MAVO. Waktu pembaruan: {new Date().toLocaleString('id-ID')}.</p>
          {error && <p className="error-message">{error}</p>}
        </section>
      </main>
    </div>
  );
}
