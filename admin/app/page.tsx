const metrics = [
  { label: 'Total pengguna', value: '—', hint: 'Data akan tampil setelah API dan autentikasi terhubung' },
  { label: 'Provider aktif', value: '—', hint: 'Provider yang lolos verifikasi' },
  { label: 'Booking hari ini', value: '—', hint: 'Transaksi booking aktual' },
  { label: 'Sengketa terbuka', value: '—', hint: 'Perlu ditangani tim operasional' },
];

export default function DashboardPage() {
  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">YUKU</div>
        <div className="tagline">Yuk, Ketemu. · Admin</div>
        <nav className="nav">
          <a className="active" href="/">Overview</a>
          <a href="/users">Users</a>
          <a href="/providers">Providers</a>
          <a href="/bookings">Bookings</a>
          <a href="/payments">Payments</a>
          <a href="/disputes">Disputes</a>
        </nav>
      </aside>
      <main>
        <div className="top">
          <div><div className="eyebrow">YUKU OPERATIONS</div><h1>Business overview</h1></div>
          <span className="pill">Development foundation</span>
        </div>
        <section className="grid">
          {metrics.map((item) => (
            <article className="card" key={item.label}>
              <div className="eyebrow">{item.label}</div>
              <div className="metric">{item.value}</div>
              <p className="note">{item.hint}</p>
            </article>
          ))}
        </section>
        <section className="card" style={{ marginTop: 20 }}>
          <h2>Project status</h2>
          <p>Dashboard shell siap. Hubungkan admin authentication, role-based access, audit logs, dan endpoint analitik sebelum digunakan oleh staf.</p>
          <p className="note">Angka tidak ditampilkan sebagai data palsu. Kartu metrik akan dihubungkan ke API setelah modul backend selesai.</p>
        </section>
      </main>
    </div>
  );
}
