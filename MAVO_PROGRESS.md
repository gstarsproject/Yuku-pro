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
- [x] Pengujian pengguna melalui APK: postingan PRIVATE berhasil dibuat dan tetap tampil di Home akun pemilik.
- [x] Uji privasi PRIVATE lintas akun: postingan PRIVATE tidak muncul di Home akun kedua.
- [x] Tambah endpoint autentikasi GET/POST/DELETE untuk relasi Follow di Worker preview API; insert aman memakai ON CONFLICT, cegah follow diri sendiri, dan kembalikan status serta jumlah pengikut/mengikuti.
- [x] Tambah metode followStatus dan setFollow pada klien API Flutter.
- [x] Ganti tombol Follow demo pada CreatorProfileScreen menjadi pemanggilan API bila creatorUserId tersedia.
- [x] Sambungkan nama/identitas penulis postingan di Home ke CreatorProfileScreen dengan creatorUserId dari API feed; profil dapat dibuka untuk mengikuti penulis postingan.
- [x] Perbaiki matcher route Follow yang sempat gagal TypeScript; Worker CI dan Backend CI lulus pada commit `fe53f0ead914d43eba8606b3edd7972f3787899b`.
- [ ] Tunggu hasil GitHub CI Backend, Flutter, dan Worker untuk integrasi profil dari feed pada commit `6d2a2af98c008fe290b507f00bed935527a3dd88`.
- [x] Verifikasi database branch `mavo-test`: tabel `Follow` tersedia dengan kolom `id`, `followerId`, `followingId`, `createdAt`.
- [ ] Uji Unfollow lintas akun dan pastikan jumlah pengikut konsisten; pengujian hilangnya postingan setelah refresh menunggu APK terbaru.
- [x] Uji FOLLOWERS lintas akun: setelah akun kedua mengikuti akun pertama, postingan FOLLOWERS muncul di Home akun kedua.
- [x] Perbaiki widget test Inbox agar dirender di dalam Scaffold seperti struktur aplikasi sebenarnya.
- [x] GitHub CI pada commit `69b8aafca472b451ac48c369c3a612848ad2f308`: Backend CI PASS, Flutter Mobile CI PASS, Cloudflare Worker CI PASS.
- [x] APK preview Android berhasil dibangun. Artifact sebelumnya: `mavo-android-arm64-preview`, run `45972701723`, artifact `15185868757`.
- [x] Deployment Worker preview `mavo-api-preview` dan `mavo-preview` terdaftar di Cloudflare pada 2026-11-27 sekitar 09:12 UTC.
- [ ] Uji runtime health/database dan seluruh alur privasi secara end-to-end melalui APK Android.

## Pembaruan 2026-11-27 — Home refresh dan APK preview terbaru
- [x] Tambah pull-to-refresh pada Home menggunakan RefreshIndicator dan AlwaysScrollableScrollPhysics; refresh memanggil ulang endpoint feed.
- [x] Perbaiki error compile akibat const pada SliverPadding yang membungkus PostsFeed berkunci.
- [x] GitHub Actions pada commit `fefc76c3801a2b09c6922174f1258276718ac144`: Backend CI PASS, Cloudflare Worker CI PASS, Flutter Mobile CI PASS (run `45982722585`).
- [x] APK arm64 preview berhasil dibangun dan diunggah sebagai artifact `mavo-android-arm64-preview` (run `45982722585`, artifact `15189528598`, dibuat 2026-11-27 10:34 UTC).
- [ ] Uji di perangkat Samsung: akun kedua Unfollow akun pertama, kembali ke Home, tarik layar ke bawah, lalu pastikan postingan FOLLOWERS tidak lagi terlihat.

## Pembaruan 2026-11-27 — Like dan Komentar (implementasi awal)
- [x] Perbaikan CI Flutter: koma ekstra dan penutup callback builder feed diperbaiki; commit final `3f4dabcb925f6e3cbee91eeb3a450f0cd4fe82f0`.
- [x] Tambah model Prisma `PostLike` dan `PostComment` beserta relasi ke User dan Post.
- [x] Tambah migration SQL `20261127040000_add_post_likes_comments`.
- [x] Terapkan tabel dan indeks Like/Komentar pada Neon branch pengujian `mavo-test` (project `lucky-truth-84216061`, branch `br-divine-shape-bi7a8pkw`); produksi tidak disentuh.
- [x] Tambah Worker API untuk Like/Unlike, daftar komentar, dan kirim komentar; endpoint memeriksa sesi dan hak akses audience postingan.
- [x] Feed API mengembalikan `likesCount`, `commentsCount`, dan `likedByMe`.
- [x] Sambungkan tombol Like dan panel Komentar di Flutter ke API.
- [x] Worker preview berhasil typecheck dan dry-run; deploy preview `mavo-preview` dan `mavo-api-preview` selesai pada run `45985452828`.
- [x] Flutter Analyze PASS dan Flutter Tests PASS pada run `45986283361`, commit `3f4dabcb925f6e3cbee91eeb3a450f0cd4fe82f0`.
- [x] Build APK release Android arm64 kompatibel Samsung PASS; artifact `mavo-android-arm64-preview`, run `45986283361`, artifact `15191094300` (18,116,932 byte APK; ZIP artifact 8,756,503 byte).
- [ ] APK ini ditahan untuk sementara sesuai keputusan: kumpulkan beberapa fitur sebelum meminta pengguna instal APK gabungan berikutnya.
- [ ] Uji Like/Unlike dan kirim/baca komentar dari dua akun di APK gabungan berikutnya; pastikan hitungan konsisten setelah refresh.
- Catatan: fitur belum dinyatakan selesai sampai APK lolos CI dan diuji langsung di perangkat.
 
## Keputusan distribusi APK
- Pengguna meminta agar tidak perlu instal APK bergantian untuk setiap fitur. Karena itu, build preview per fitur disimpan sebagai artefak internal; pengguna akan diminta instal saat satu batch fitur lebih lengkap sudah siap.
- Perubahan backend dapat diperbarui tanpa instal ulang APK; perubahan Flutter memerlukan APK baru.


## Pembaruan 2026-11-27 — Story teks (implementasi awal)
- [x] Tambah model Prisma `Story` dengan audience PUBLIC/FOLLOWERS, masa aktif 24 jam, dan indeks expiry/pemilik.
- [x] Buat migration `20261127060000_add_stories`.
- [x] Terapkan tabel `Story` dan indeks pada Neon TEST branch `mavo-test`; tabel terverifikasi tersedia. Database produksi tidak disentuh.
- [x] Tambah Worker API GET/POST `/api/v1/stories`; hanya story yang belum kedaluwarsa ditampilkan, dengan pemeriksaan sesi dan audience (publik/pengikut).
- [x] Tambah metode API Flutter untuk membaca dan membuat story.
- [x] Ganti layar Stories demo menjadi daftar story nyata, viewer, dan form buat story teks maksimal 500 karakter; audience Publik/Pengikut.
- [x] Tombol Your Story dan kategori Story di Home membuka layar Stories.
- [x] Cloudflare Worker CI lulus pada commit perbaikan `7c02dbfccf233c6e021338706a30ab7a35087f69`.
- [ ] Backend CI dan Flutter CI pada commit `7c02dbfccf233c6e021338706a30ab7a35087f69` masih berjalan saat catatan ini diperbarui.
- [x] Perbaiki error analyzer Flutter: ganti `MavoColors.cloud` menjadi `MavoColors.background`; perbarui `DropdownButtonFormField.initialValue` dan rapikan blok kondisi. Commit `7c02dbfccf233c6e021338706a30ab7a35087f69`.
- [ ] Deploy Worker preview terbaru setelah CI lulus.
- [ ] Uji buat/baca story lintas dua akun, audience FOLLOWERS, dan expiry 24 jam pada APK gabungan.
- Catatan batasan: tahap Story ini berbasis teks; upload foto/video belum dibuat karena memerlukan alur penyimpanan media dan URL aman.

## Batasan saat ini
- Fitur postingan pada tahap ini hanya teks maksimal 2.000 karakter.
- Story teks sudah diimplementasikan (belum lolos CI/uji perangkat); upload foto/video, share, hashtag, dan trending belum diaktifkan.
- Like/Unlike dan komentar sudah diimplementasikan di backend/Flutter, tetapi belum diuji runtime pada perangkat karena APK ditahan untuk batch pengujian berikutnya.
- Follow/Unfollow dan filter FOLLOWERS sudah diimplementasikan; visibilitas setelah Follow sudah dikonfirmasi pengguna. Uji Unfollow + pull-to-refresh masih menunggu.
- CI PASS dan catatan deployment belum membuktikan semua alur end-to-end sudah berfungsi dari APK.
- Database pengujian adalah branch Neon `mavo-test`, bukan database produksi.
- Jangan deploy ke produksi atau merge PR tanpa persetujuan.


## Pembaruan 2026-11-27 — Chat pribadi dan Notifikasi (implementasi awal)
- [x] Tambah `Conversation.directKey` unik untuk memastikan satu percakapan langsung per pasangan pengguna.
- [x] Tambah model `ConversationParticipant` untuk membatasi akses percakapan hanya kepada anggota.
- [x] Tambah `Message.readAt` untuk status pesan dibaca.
- [x] Tambah model `Notification` dengan penerima, aktor, tipe, entitas, waktu, dan status dibaca.
- [x] Buat migration `20261127080000_add_direct_chat_notifications`.
- [x] Terapkan migration pada Neon TEST branch `mavo-test`; tabel `ConversationParticipant`, `Notification`, kolom `Conversation.directKey`, dan `Message.readAt` terverifikasi. Produksi tidak disentuh.
- [x] Tambah Worker API pencarian pengguna, buat/daftar percakapan 1:1, baca/kirim pesan, tandai percakapan dibaca, daftar notifikasi, dan tandai notifikasi dibaca.
- [x] Semua route chat memerlukan sesi login dan keanggotaan percakapan sebelum membaca/mengirim pesan.
- [x] Notifikasi in-app dibuat untuk pesan baru, follow baru, Like, dan komentar.
- [x] Tambah metode API Flutter untuk pencarian pengguna, percakapan, pesan, dan notifikasi.
- [x] Ganti Inbox demo menjadi daftar percakapan server, dialog Chat Baru, layar chat, dan layar notifikasi.
- [x] Backend CI PASS dan Cloudflare Worker CI PASS pada commit `9495f226bd16d3888b8743f52eb5002b097b5721`.
- [ ] Flutter Analyze, Flutter Tests, dan build APK pada commit `9495f226bd16d3888b8743f52eb5002b097b5721` masih berjalan saat catatan ini dibuat.
- [ ] Deploy Worker preview terbaru setelah seluruh CI lulus.
- [ ] Uji chat dua akun (buat percakapan, kirim/baca pesan, unread/read) dan notifikasi dua akun melalui APK batch.
- Catatan batasan: notifikasi saat ini adalah notifikasi dalam aplikasi (in-app), belum push notification OS; chat saat ini teks 1:1, belum grup, gambar, file, audio, atau panggilan.


## Pembaruan 2026-11-27 — Verifikasi batch Chat/Notifikasi dan CI
- [x] Flutter Analyze PASS pada commit `10ba8d04e127cf3679385584bad85f83a6ab7eaf` (run `45988986637`).
- [x] Flutter Tests PASS pada commit yang sama; tes Inbox dan Story telah diselaraskan dengan layar aktif.
- [x] Backend CI PASS dan Cloudflare Worker validation PASS pada commit tersebut.
- [ ] Build APK arm64 pada run `45988986637` masih berjalan; belum ada artefak baru yang bisa dibagikan.
- [ ] Deploy Worker preview otomatis perlu dijalankan pada event push; run sebelumnya dipicu oleh pull_request sehingga job deploy ter-skip. Commit ini menyentuh Worker dan akan memicu validasi serta deploy preview pada push branch fitur.
- [ ] Uji runtime Chat 1:1, notifikasi, Like/Komentar, Story, dan privasi feed memakai dua akun setelah APK gabungan siap.
- Database yang digunakan tetap Neon TEST `mavo-test`; tidak ada deploy produksi atau merge PR.


## Pembaruan 2026-11-27 — Deploy preview Chat/Notifikasi dan build APK batch
- [x] Cloudflare Worker validation PASS pada push commit `17d3e14dd802b0b2511bc6bd31752f5ed953dcae` (run `45989373429`).
- [x] Deploy `mavo-preview` dan alternate preview hostname PASS pada run `45989373429`; deployment hanya ke lingkungan preview.
- [x] Verifikasi konfigurasi Flutter: `YukuApi.baseUrl` mengarah ke `https://mavo-api-preview.gstars-business.workers.dev`, bukan production API.
- [x] Flutter Analyze PASS pada run `45989381702` (commit `17d3e14dd802b0b2511bc6bd31752f5ed953dcae`).
- [ ] Flutter Tests dan build APK pada run `45989381702` masih berjalan saat catatan ini diperbarui.
- [ ] Health endpoint preview belum dapat diverifikasi melalui pemeriksaan HTTP eksternal; jangan anggap deploy sukses sebagai bukti runtime end-to-end.
- [ ] Setelah artifact APK berhasil diunggah, jalankan uji runtime dua akun untuk Chat, Notifikasi, Like/Komentar, Story, Follow/Unfollow, dan audience feed.
- Database tetap Neon TEST `mavo-test`; produksi belum disentuh dan PR belum di-merge.
