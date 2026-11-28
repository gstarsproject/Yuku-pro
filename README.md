# MAVO— All-in-One Project v1

Ini adalah satu paket utama untuk pengembangan YUKU. Gunakan folder `MAVO/` sebagai
satu-satunya root proyek di laptop.

## Keputusan produk yang sudah ditetapkan
- Marketplace jasa nasional Indonesia.
- Aplikasi Flutter untuk Android dan iOS.
- Backend NestJS + Prisma, database PostgreSQL.
- Admin dashboard Next.js.
- Arsitektur modular monolith.
- Booking: INSTANT dan REQUEST.
- Komisi: dapat diatur per kategori jasa.
- Pencairan provider: setelah layanan selesai; perlu konfirmasi customer/penanganan sengketa.
- Pembayaran: gateway; integrasi yang ada masih sandbox/starter.

## Isi utama
- `mobile/yuku_app/` — Flutter starter.
- `backend/` — NestJS API, booking, pembayaran Midtrans sandbox, Prisma.
- `admin/` — Next.js admin starter.
- `database/` — skema dan seed awal.
- `docs/` — brand, spesifikasi layar, API, keamanan, dan keputusan transaksi.
- `openapi/` — kontrak API awal.
- `reference/transaction-pack-v1/` — paket kode tambahan yang disimpan sebagai referensi.

## Penting: jangan campur dua skema database
Folder `reference/transaction-pack-v1/` berisi eksperimen implementasi transaksi dengan
model Prisma yang berbeda. Folder itu disimpan agar tidak hilang, tetapi **bukan kode
yang langsung ditimpa ke backend utama**. Source of truth untuk proyek yang dijalankan
adalah `backend/prisma/schema.prisma` dan kode di `backend/src/`.

## Menjalankan di Windows
Persyaratan: Git, VS Code, Node.js LTS, Flutter SDK, Android Studio, Docker Desktop.

1. Buka PowerShell pada folder `MAVO/`.
2. Jalankan database:
   ```powershell
   docker compose up -d db
   ```
3. Backend:
   ```powershell
   cd backend
   Copy-Item .env.example .env
   npm install
   npx prisma generate
   npx prisma migrate dev --name init
   npm run start:dev
   ```
4. Admin (terminal baru):
   ```powershell
   cd admin
   Copy-Item .env.example .env.local
   npm install
   npm run dev
   ```
5. Mobile (terminal baru):
   ```powershell
   cd mobile/MAVO_app
   flutter pub get
   flutter run
   ```

Periksa README lama dan `docs/` untuk konfigurasi rinci. Jika ada error, kirim screenshot
atau salin pesan error lengkap agar bisa diperbaiki berdasarkan kondisi laptop.

## Status jujur
Paket ini adalah fondasi pengembangan yang telah digabung, bukan aplikasi siap produksi.
Belum boleh menerima pembayaran sungguhan sebelum autentikasi/otorisasi, validasi webhook,
penguncian jadwal, refund/dispute, KYC, disbursement resmi, audit, keamanan, dan testing
end-to-end selesai. Kredensial gateway asli tidak disertakan.
