# Catatan Progres MAVO

Terakhir diperbarui: 2026-11-27

## Konsep utama (dipertahankan)
MAVO adalah satu ekosistem Social Media + Live Streaming + Chat + Global Marketplace.
Pilar marketplace: MAVO FRIEND, EXPERIENCE, MAVO PRO.
Navigasi utama: Home, Explore, Create, Inbox, Profile.

## Tahap 1 — Social Media
- [x] Audit alur Create: sebelumnya hanya menampilkan snackbar draft, belum memanggil API.
- [x] Tambah endpoint API untuk membuat postingan teks dan membaca feed.
- [x] Tambah model Post dan migration SQL untuk PostgreSQL.
- [x] Hubungkan tombol Bagikan ke API dengan status loading dan pesan hasil.
- [x] Hubungkan Home ke feed postingan dari API.
- [x] Terapkan migration `20261127000100_add_posts` hanya ke database preview Neon `mavo-test` (Post + dua index; tercatat di `_prisma_migrations`).
- [ ] Uji create/read dan privasi Publik/Pengikut/Privat melalui Worker preview dan APK Android.
- [ ] Build APK dan uji di Android.

## Batasan saat ini
- Fitur postingan yang dibuat pada tahap ini hanya teks maksimal 2.000 karakter.
- Foto/video, like server-side, komentar, share, story, hashtag, dan trending belum diaktifkan.
- Worker preview belum dipastikan ter-deploy pada versi endpoint posting terbaru; pipeline validasi Worker lulus, tetapi deploy hanya berjalan pada push branch.
- CI Flutter terakhir: analisis lulus; 2 dari 6 widget test gagal karena test lama memakai `pumpAndSettle` pada layar dengan animasi berulang dan test profil kreator mengacu ke widget demo yang tidak lagi tampil di Home. Test sedang diperbarui.
- Jangan deploy ke produksi atau merge PR tanpa persetujuan.
- Database yang dituju untuk pengujian adalah branch Neon `mavo-test`, bukan database produksi.
