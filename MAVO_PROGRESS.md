# Catatan Progres MAVO

Terakhir diperbarui: 2026-11-27

## Konsep utama (dipertahankan)
MAVO adalah satu ekosistem Social Media + Live Streaming + Chat + Global Marketplace.
Pilar marketplace: MAVO FRIEND, EXPERIENCE, MAVO PRO.
Navigasi utama: Home, Explore, Create, Inbox, Profile.
Brand: MAVO — CONNECT. SHARE. EXPLORE.
Arah produk tetap satu ekosistem; bukan marketplace saja.

## Tahap 1 — Social Media
- [x] Audit alur Create: sebelumnya hanya menampilkan snackbar draft, belum memanggil API.
- [x] Tambah endpoint API untuk membuat postingan teks dan membaca feed.
- [x] Tambah model Post di Prisma dan migration SQL `20261127000100_add_posts`.
- [x] Migration postingan tercatat pada database preview Neon `mavo-test`; database produksi tidak disentuh.
- [x] Hubungkan tombol Bagikan ke API dengan status loading dan pesan hasil.
- [x] Hubungkan Home ke feed postingan dari API.
- [x] Feed membatasi postingan PUBLIC untuk semua pengguna login, FOLLOWERS hanya untuk pengikut, dan PRIVATE hanya untuk pemilik.
- [x] Perbaiki widget test Inbox agar dirender di dalam Scaffold seperti struktur aplikasi sebenarnya.
- [x] GitHub CI pada commit `69b8aafca472b451ac48c369c3a612848ad2f308`: Backend CI PASS, Flutter Mobile CI PASS, Cloudflare Worker CI PASS.
- [x] APK preview Android berhasil dibangun. Artifact: `mavo-android-arm64-preview`, run `45972701723`, artifact `15185868757`.
- [x] Deployment Worker preview `mavo-api-preview` dan `mavo-preview` terdaftar di Cloudflare pada 2026-11-27 sekitar 09:12 UTC.
- [ ] Uji runtime health/database dan alur create/read serta privasi Publik/Pengikut/Privat secara end-to-end melalui APK Android.

## Batasan saat ini
- Fitur postingan pada tahap ini hanya teks maksimal 2.000 karakter.
- Foto/video, like server-side, komentar, share, story, hashtag, dan trending belum diaktifkan.
- CI PASS dan catatan deployment belum membuktikan alur posting end-to-end sudah berfungsi dari APK.
- Database pengujian adalah branch Neon `mavo-test`, bukan database produksi.
- Jangan deploy ke produksi atau merge PR tanpa persetujuan.
