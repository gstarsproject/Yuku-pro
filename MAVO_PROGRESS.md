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

## Follow list repair — 2026-11-27
- Added authenticated API `GET /api/v1/users/:id/relations?type=followers|following` to return real follower/following accounts from the Follow table.
- Added Flutter `YukuApi.userRelations` client method.
- Creator profile Pengikut and Mengikuti counters now open live lists; removed the hard-coded 1,280 follower demo count.
- Each listed account opens its real creator profile.
- Validation pending: GitHub Actions CI and two-account runtime test on Android preview. No production deployment; preview database remains the test database.


## Media Post/Story — tahap fondasi backend (2026-11-27)
- [x] Buat bucket privat Neon Object Storage mavo-media pada TEST branch mavo-test (region ap-southeast-1 / Singapore).
- [x] Tambah tabel MediaAsset, relasi ke Post/Story/User, indeks, dan kolom lokasi opsional (nama tempat + koordinat) di Prisma schema.
- [x] Buat migration 20261127120000_add_post_story_media.
- [x] Terapkan tabel dan kolom tersebut ke Neon TEST mavo-test; semua 8 perintah SQL selesai tanpa error. Produksi tidak disentuh.
- [x] Tambah Worker endpoint terautentikasi untuk meminta presigned upload URL dan presigned download URL 15 menit; pemeriksaan akses media menghormati owner, audience post/story, follow, dan expiry Story.
- [x] Tambah dukungan Worker untuk melampirkan metadata media dan label lokasi saat membuat Post/Story.
- [x] Tambah metode Flutter untuk meminta upload URL dan mengirim file langsung ke object storage, serta mengirim metadata media/lokasi saat membuat Post/Story.
- [x] Tambah dependency image_picker untuk pemilih galeri Android.
- [ ] Worker CI pertama gagal karena dua karakter literal backslash-n yang tersisip pada source. Sudah diperbaiki pada commit e58e315cfb5cf9b9e596f5063e1e17dc9e5f48de; validasi ulang belum terdeteksi.
- [ ] Flutter UI pemilihan foto/video dan input lokasi masih dalam pengerjaan; belum ada preview media di feed/story atau video player.
- [ ] Cloudflare Worker secrets AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ENDPOINT_URL_S3, AWS_REGION belum terpasang pada mavo-api-preview. Credential Neon TEST dibuat khusus scope storage:read/write dan expiry 2027-11-27; pemasangan secret melalui dashboard Cloudflare perlu dilakukan manual karena operasi penyalinan secret ditolak kontrol keamanan.
- [ ] Jangan deploy Worker/API media sampai secret storage terpasang dan CI lulus.
- Catatan keamanan: bucket privat; kredensial tidak boleh ditanam di APK, repository, atau source code. URL file yang diberikan ke aplikasi hanya berlaku 15 menit.

## Media UI Post dan Story — lanjutan (2026-11-27)
- [x] Composer Post: pilih beberapa foto dari galeri, pilih video (maks. 3 menit), hapus pilihan, dan isi label lokasi manual.
- [x] Composer Story: pilih foto/video dari galeri dan isi label lokasi manual; Story tetap mengikuti masa aktif 24 jam.
- [x] Upload file melalui API Worker dan simpan metadata media ke Post/Story (client sudah disiapkan).
- [x] Feed API dan Story API mengembalikan metadata media terkait.
- [x] Feed menampilkan foto dan pemutar video; viewer Story menampilkan foto/video dan label lokasi.
- [x] Tambah package image_picker dan video_player.
- [x] Verifikasi endpoint S3 Neon TEST: force_path_style=true, region ap-southeast-1, endpoint br-divine-shape-bi7a8pkw.storage.c-5.ap-southeast-1.aws.neon.tech.
- [ ] Worker preview belum dapat memproses upload sampai secret S3 diikat ke mavo-api-preview. Upaya memasang secret otomatis diblokir oleh kontrol keamanan; jangan menaruh credential pada repository atau aplikasi.
- [ ] Build Android terbaru masih berjalan; jangan kirim APK sampai Flutter analyze, tests, dan release build sukses.
- [ ] Location saat ini berupa label tempat yang diketik manual, belum GPS/geocoding. Ini disengaja agar lokasi tidak dibagikan otomatis.
- [ ] Perlu runtime test upload/download memakai dua akun dan uji visibilitas PUBLIC/FOLLOWERS/PRIVATE sebelum fitur dinyatakan selesai.
## Edit Profil — galeri foto (2026-11-27)
- [x] Form Edit Profil kini menyediakan pemilih foto profil langsung dari galeri Android, preview foto, edit nama tampilan, dan bio.
- [x] Foto diproses melalui upload privat Neon Object Storage (bukan URL gambar publik).
- [x] Worker PATCH profil menyimpan metadata MediaAsset pemilik dan mengikat objectKey ke Profile.avatarUrl; GET profil mengembalikan avatarMediaId.
- [x] Flutter mengambil URL sementara media privat untuk menampilkan foto profil.
- [ ] Validasi GitHub Actions Flutter/Worker dan build APK untuk batch berikutnya masih berjalan.
- [ ] Upload foto profil belum dapat diuji runtime sampai secret S3 tersedia pada Cloudflare Worker preview.
- Catatan: nama tampilan dan bio tetap dapat diedit tanpa memilih foto. Produksi tidak disentuh.

## Perbaikan Inbox Chat — 2026-11-27
- [x] Konfirmasi database TEST: dua akun aktif (Mavodev dan yuku) terdaftar sebagai peserta percakapan yang sama; percakapan berisi 4 pesan.
- [x] Jalankan query daftar percakapan yang sama dengan Worker untuk kedua userId; masing-masing akun memperoleh tepat satu baris percakapan dengan nama akun lawan.
- [x] Flutter Inbox diperbaiki: tombol refresh eksplisit, empty state kini bisa ditarik untuk refresh, dan refresh indicator menunggu request selesai.
- [x] Inbox otomatis meminta daftar terbaru setiap 12 detik agar pesan/percakapan dari HP kedua ikut muncul tanpa harus keluar-masuk menu.
- [ ] Build APK dan Flutter CI untuk commit perbaikan Inbox masih harus divalidasi sebelum instalasi.
- Catatan: belum ada bukti bahwa versi APK yang terpasang di dua HP memuat commit terbaru; jangan anggap perbaikan sudah teruji di perangkat sampai APK baru diuji.


## Roadmap penyelesaian bertahap — disetujui pengguna (2026-11-27)

Prinsip pengerjaan:
- Pertahankan ekosistem MAVO: Social Media, LIVE, Chat, dan marketplace FRIEND / EXPERIENCE / PRO.
- Kerjakan per tahap pada branch pengembangan dan database TEST; jangan menyentuh produksi.
- Jangan menghapus atau merusak fitur yang sudah ada.
- Setiap fitur harus melewati pemeriksaan kode, CI, dan pengujian runtime sebelum ditandai selesai.
- Simpan APK batch untuk pengujian gabungan; jangan meminta pengguna memasang APK untuk setiap perubahan kecil.
- Tidak merge PR atau deploy produksi tanpa persetujuan eksplisit pengguna.

Urutan tahap:
1. **Fondasi dan stabilisasi:** selesaikan Inbox dua akun, aturan akses chat saling-follow, profil dan galeri postingan nyata, Follow/Unfollow, Like/Komentar, Story, upload media, dan verifikasi runtime.
2. **Social Media:** edit/hapus postingan, share, hashtag, pencarian, trending, reaksi/balasan Story, serta galeri profil.
3. **Chat:** lampiran media, voice note, group chat, typing/presence, panggilan suara/video, dan push notification.
4. **MAVO LIVE:** streaming, live chat, gift, battle, multi-guest, riwayat dan pendapatan kreator.
5. **Marketplace:** onboarding penyedia, pengelolaan layanan, ketersediaan, booking, persetujuan, pembatalan, review dan dispute untuk FRIEND / EXPERIENCE / PRO.
6. **Wallet dan transaksi:** integrasi payment gateway sandbox, ledger, komisi per kategori, settlement setelah layanan, refund dan payout.
7. **Keamanan dan monetisasi:** verifikasi, report/block, moderasi, anti-spam, admin tools, AI rekomendasi/terjemahan, reward, iklan dan premium.
8. **Rilis:** pengujian end-to-end, keamanan, performa, backup, monitoring, dan persiapan produksi.

Status awal tahap 1:
- Inbox refresh otomatis dan manual sudah ada di source; menunggu APK terbaru dan pengujian dua perangkat.
- Aturan chat hanya jika kedua akun saling follow belum diterapkan.
- Profil masih memiliki placeholder untuk galeri postingan; tombol bagikan profil belum berfungsi.
- Tombol Pesan di profil kreator belum membuka percakapan.
- Upload media post/story dan foto profil belum dapat diuji sampai secret Object Storage dikonfigurasi manual di Cloudflare preview.
- Like/Komentar dan Story masih memerlukan pengujian runtime.
- Worker preview harus mengikuti source terbaru sebelum pengujian API; jangan deploy produksi.


## Pembaruan 2026-11-27 — Tahap 1: aturan chat saling mengikuti
- [x] Worker menolak pembuatan percakapan pribadi jika kedua pengguna belum saling Follow (HTTP 403).
- [x] Daftar Inbox hanya menampilkan percakapan dengan relasi Follow dua arah yang masih aktif.
- [x] Endpoint baca/kirim pesan dan tandai dibaca memeriksa ulang relasi Follow dua arah; chat lama tidak bisa dipakai setelah salah satu pihak Unfollow.
- [ ] Jalankan Worker CI dan verifikasi skenario dua akun: belum saling Follow ditolak, saling Follow diizinkan, salah satu Unfollow memblokir akses.
- [ ] Perbarui/deploy Worker preview hanya setelah validasi CI; produksi tidak disentuh.

- [x] Tombol Pesan di profil kreator kini membuka percakapan langsung melalui Inbox; server tetap menjadi pengaman utama dan menolak jika belum saling Follow.
- [ ] Uji navigasi tombol Pesan dan skenario mutual-follow di dua perangkat setelah APK batch terbaru tersedia.

## Tahap 1 — pembaruan profil dan chat (27 Nov 2026)
- [x] Filter chat pribadi dengan syarat saling Follow pada create/list/read/send.
- [x] Tombol Pesan profil kreator membuka alur chat.
- [x] Endpoint daftar postingan mendukung filter authorId dengan tetap menerapkan aturan visibilitas PUBLIC/FOLLOWERS/PRIVATE.
- [x] API Flutter mendukung pemanggilan postingan berdasarkan authorId.
- [x] Profil pribadi menampilkan daftar postingan dan jumlah like/komentar dari API.
- [ ] CI Worker dan Flutter untuk batch ini harus lulus.
- [ ] Uji dua akun di perangkat Android: profil, postingan privat/followers, tombol Pesan, saling Follow, Unfollow.
- [ ] Upload media belum dapat dinyatakan selesai sampai kredensial storage TEST dikonfigurasi dan tes berhasil.

- [x] Profil kreator mengganti panel konten demo dengan daftar postingan aktual dari API.
- [x] Daftar postingan kreator mengikuti filter visibilitas server: publik, followers yang sudah mengikuti, dan privat hanya pemilik.
- [ ] CI dan tes dua akun untuk profil kreator masih menunggu.

## Feed sosial — stabilisasi interaksi (27 Nov 2026)
- [x] Kartu postingan menyelaraskan ulang status Like dan jumlah Like/Komentar ketika data feed diperbarui setelah refresh.
- [x] Pull-to-refresh tetap menyelesaikan indikator meskipun request feed gagal; error ditampilkan oleh FutureBuilder dan pengguna tetap dapat mencoba lagi.
- [ ] Tunggu hasil Flutter CI dan uji runtime Like/Unlike serta komentar dua akun pada APK gabungan.
- [ ] Tab For You/Following/Live/Explore masih perlu dihubungkan ke sumber data/filter yang sesuai; saat ini jangan dianggap sebagai filter aktif.

## Feed tab dan refresh Story (27 Nov 2026)
- [x] API feed mendukung filter authorId, following-only, dan public-only dengan parameter query terikat.
- [x] Tab Following meminta postingan dari akun yang diikuti; visibilitas FOLLOWERS/PRIVATE tetap difilter oleh aturan server.
- [x] Tab Explore meminta postingan PUBLIC saja.
- [x] Tab Live menampilkan status belum tersedia secara jelas; tidak menampilkan konten feed palsu.
- [x] Refresh Story tidak lagi melempar error async tanpa penanganan; FutureBuilder menampilkan error dan tombol coba lagi tetap tersedia.
- [ ] Worker CI dan Flutter CI untuk batch ini harus lulus sebelum dianggap siap.
- [ ] Live streaming dan Story media tetap menunggu konfigurasi storage dan pengujian runtime.

- [x] Home Stories strip sekarang memuat Story aktif dari API, menampilkan nama kreator unik (bukan chip kategori contoh), dan menampilkan status kosong/error.
- [x] Future Story di Home disimpan agar tidak meminta ulang API pada setiap rebuild; pull-to-refresh memperbarui Story dan feed bersama.

- [x] Story chip Home membawa userId kreator; membuka StoriesScreen yang difilter hanya untuk kreator terpilih, bukan daftar semua Story.


## Audit lanjutan — pemeriksaan endpoint Worker dan model transaksi (27 Nov 2026)
- [x] Periksa route Like/Komentar: sesi wajib, postingan harus terlihat oleh pengguna, Like memakai unique constraint + ON CONFLICT, komentar dibatasi 1.000 karakter.
- [x] Periksa route Chat: sesi, participant membership, dan mutual-follow diperiksa sebelum membaca/mengirim pesan; Unfollow memblokir chat.
- [x] Periksa feed: query terparameterisasi dan filter PUBLIC/FOLLOWERS/PRIVATE diterapkan di server.
- [x] Periksa akses unduh media: URL sementara hanya dibuat setelah pemeriksaan owner/audience/follow dan expiry Story.
- [ ] Hardening request body: readRequestBody saat ini hanya memeriksa Content-Length; body tanpa header atau header tidak valid dapat melewati batas 8 KB. Perlu pembacaan stream dengan batas byte.
- [ ] Tambahkan rate limiting untuk register/login dan endpoint interaksi; belum ada binding limiter terkonfigurasi di Worker. Jangan menganggap proteksi brute-force sudah tersedia.
- [ ] Sembunyikan detail database dari endpoint health publik; /health/db saat ini mengembalikan nama database dan waktu server.
- [ ] Periksa CORS: saat ini Access-Control-Allow-Origin '*' digunakan. API menggunakan Bearer token, tetapi origin perlu dibatasi sesuai domain aplikasi sebelum rilis publik.
- [ ] Audit marketplace menemukan model Prisma Booking, Payment, LedgerEntry, CommissionRule, ProviderPayout, PaymentWebhookEvent, Review, dan Dispute sudah tersedia, tetapi Worker belum memiliki route booking/payment/ledger/commission/payout/dispute. Endpoint layanan hanya untuk discovery/detail. Karena itu transaksi marketplace belum dapat digunakan end-to-end.
- [ ] Belum ada integrasi payment gateway sandbox maupun verifikasi signature webhook yang bisa diaudit di Worker.
- [ ] Tidak ada perubahan kode, database, deploy, atau merge pada pemeriksaan ini; catatan ini hanya merekam hasil audit source di branch pengembangan.

## Pembaruan keamanan Worker — 2026-11-27 (commit fce05c2)
- [x] Batasi ukuran JSON request maksimal 8 KiB dengan memeriksa Content-Length bila tersedia sekaligus menghitung byte stream aktual; request yang melewati batas dibatalkan.
- [x] Validasi UTF-8 dan pastikan payload JSON berupa object, bukan array atau nilai primitif.
- [x] Sederhanakan `/health/db`: hanya mengembalikan status koneksi tanpa membocorkan nama database atau waktu server.
- [x] GitHub Actions run `46001395155`: validasi Worker, TypeScript, Wrangler dry-run, dan alternate hostname dry-run PASS.
- [x] Deploy `mavo-preview` dan alternate preview hostname PASS pada run `46001395155`; production tidak disentuh.
- [ ] Pemeriksaan lanjutan: pemetaan error body agar payload terlalu besar konsisten mendapat HTTP 413 dan JSON tidak valid mendapat HTTP 400 pada semua route yang menerima body.
- [ ] Rate limiting autentikasi/interaksi dan pembatasan CORS ke domain aplikasi masih menjadi pekerjaan keamanan sebelum rilis publik.
- [ ] Secret Object Storage tetap harus dikonfigurasi manual di Cloudflare; upload media belum dinyatakan berfungsi sampai uji runtime berhasil.
- Catatan: CI dan deploy preview sukses bukan pengganti pengujian end-to-end dari aplikasi Android.

## Pembaruan validasi request API — 2026-11-27 (commit fdf9d87)
- [x] Request JSON terlalu besar sekarang menghasilkan HTTP 413 dengan pesan yang konsisten.
- [x] JSON rusak, UTF-8 tidak valid, body kosong, dan payload non-object menghasilkan HTTP 400 dengan pesan yang aman.
- [x] Penanganan error request body dipasang pada route-route yang memiliki blok catch agar tidak tertelan sebagai error umum.
- [ ] Tetap perlu validasi runtime di preview untuk status 400/413; pemeriksaan TypeScript dan Wrangler CI menunggu hasil workflow.
- [ ] Rate limiting autentikasi dan pembatasan CORS belum diterapkan; jangan anggap API siap rilis publik.

### Hasil CI untuk commit fdf9d87
- [x] Cloudflare Worker CI run `46002417682`: dependency install, TypeScript typecheck, Wrangler dry-run, dan alternate hostname dry-run semuanya PASS.
- [ ] Job deploy preview pada run tersebut berstatus SKIPPED; karena itu perubahan request-error handling belum dinyatakan ter-deploy.
- [ ] Akses runtime endpoint preview melalui pemeriksa web tidak tersedia pada sesi ini; status HTTP 400/413 belum diuji langsung.
- [ ] Backend CI run `46002417782` menyelesaikan Prisma Client generation dan NestJS build; menunggu status akhir job.
- Catatan: tidak ada perubahan production.

### Status akhir CI commit fdf9d87
- [x] Backend CI run `46002417782`: Prisma Client generation dan NestJS build PASS.
- [x] Worker CI run `46002417682`: TypeScript typecheck dan kedua Wrangler dry-run PASS.
- [ ] Worker preview deploy job SKIPPED pada run ini. Perubahan belum diklaim aktif di preview.
- [ ] Runtime test 400/413 belum bisa dilakukan melalui pemeriksa endpoint yang tersedia di sesi ini.
- [ ] Flutter Mobile CI tidak menghasilkan job pada commit ini; tidak ada APK baru yang dibangun dari perubahan ini.

## Pembaruan 2026-11-27 — Rate limit autentikasi (implementasi, menunggu validasi)
- [x] Tambah Cloudflare Workers Rate Limiting binding pada konfigurasi preview utama dan alternate preview.
- [x] Batasi percobaan register/login hingga 30 request per IP per 60 detik.
- [x] Batasi percobaan per email hingga 5 request per 60 detik, dengan scope register/login terpisah.
- [x] API mengembalikan HTTP 429 saat batas terlampaui.
- [x] Counter IP dan email dipisahkan agar setiap request tidak menghitung counter IP dua kali.
- [ ] Validasi TypeScript dan Wrangler dry-run untuk konfigurasi rate limit masih menunggu hasil CI.
- [ ] Deployment preview yang terpantau saat pemeriksaan belum menampilkan binding AUTH_IP_LIMITER dan AUTH_ID_LIMITER; jangan anggap rate limit sudah aktif pada server sebelum deployment versi terbaru terverifikasi.
- Catatan: Cloudflare Rate Limiting API bersifat approximate per lokasi Cloudflare; bukan pembatas global yang strict. Pembatas IP dapat memengaruhi beberapa pengguna yang berbagi IP jaringan seluler.
- CORS masih menggunakan wildcard. Perlu menentukan domain web resmi sebelum mengubah allowlist; aplikasi Flutter native tidak bergantung pada CORS browser.
- Tidak ada perubahan pada production Worker atau database production.
## Pembaruan 2026-11-27 — Rate limit autentikasi aktif di preview
- [x] GitHub Actions dipicu ulang melalui commit cd4e38136ec75bd3d9526270fdf3b496b24a5284 pada branch feature/mavo-user-auth.
- [x] Cloudflare deployment terbaru mavo-preview pada 2026-11-27 12:58:01 UTC memiliki binding AUTH_IP_LIMITER dan AUTH_ID_LIMITER.
- [x] Cloudflare deployment terbaru mavo-api-preview pada 2026-11-27 12:58:06 UTC memiliki binding AUTH_IP_LIMITER dan AUTH_ID_LIMITER.
- [x] Kedua preview Worker kini memuat binding rate limiter; ini memverifikasi konfigurasi terpasang, bukan pengujian beban/429 end-to-end.
- [ ] Uji runtime respons 429 dengan aman dan verifikasi batas per-IP/per-email tanpa mengunci pengguna sungguhan.
- [ ] Rate limit belum diterapkan ke production.
## Pembaruan 2026-11-27 — Throttling aktivitas pengguna (menunggu deployment preview)
- [x] Tambah USER_ACTION_LIMITER dengan batas 30 request per menit per user dan per jenis aktivitas.
- [x] Terapkan throttling untuk update profil, follow/unfollow, pembuatan URL upload media, pembuatan post, pembuatan percakapan, pengiriman pesan, pembuatan story, like/comment, pencarian pengguna, akses URL media, dan penandaan notifikasi dibaca.
- [x] Tambah binding USER_ACTION_LIMITER pada kedua konfigurasi Worker preview.
- [ ] Menunggu GitHub Actions validate dan deployment preview untuk commit perubahan ini. Deployment Cloudflare yang diperiksa masih menunjukkan versi lama; binding USER_ACTION_LIMITER belum aktif.
- [ ] Verifikasi binding USER_ACTION_LIMITER pada kedua Worker setelah deployment.
- [ ] Uji runtime HTTP 429; belum ada klaim bahwa pembatasan aktivitas sudah aktif di server.
- Catatan: rate limit aktivitas bersifat per user dan per jenis aksi; pembatas Cloudflare bersifat approximate. Production tidak disentuh.