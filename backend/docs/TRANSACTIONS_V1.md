# YUKU Transactions v1 — keputusan bisnis

- Komisi berbeda per kategori; `CommissionRule.rateBps` memakai basis points (1000 = 10%).
- Pencairan provider setelah layanan selesai. Penyelesaian booking membuat payout berstatus READY; transfer dana aktual masih membutuhkan integrasi disbursement gateway.
- Booking: INSTANT langsung menunggu pembayaran; REQUEST menunggu persetujuan provider, lalu menunggu pembayaran.
- Total customer = harga jasa + komisi platform + biaya perjalanan yang disepakati.
- Semua nominal rupiah disimpan sebagai integer, bukan float.

## Endpoints awal
- POST /bookings
- POST /bookings/:id/accept
- POST /bookings/:id/reject
- POST /bookings/:id/start
- POST /bookings/:id/complete
- POST /payments/checkout
- POST /payments/webhook/midtrans

## Contoh komisi awal development (belum tarif final)
- FRIEND: 10%
- EXPERIENCE: 12%
- PRO: 8%

Angka ini hanya seed untuk pengujian. Admin bisnis harus menyetujui tarif final sebelum pilot.

## Wajib sebelum produksi
1. Implementasikan JWT dan role guards; hapus header demo identity.
2. Verifikasi webhook dan rekonsiliasi status transaksi ke gateway.
3. Tambahkan idempotency key pada booking/checkout/refund.
4. Tambahkan disbursement resmi dan verifikasi rekening/KYC provider.
5. Tambahkan constraint anti-overlap jadwal di PostgreSQL.
6. Implementasikan refund, cancellation, dispute, expiry, notifikasi, audit log, dan laporan.
7. Review hukum, pajak, privasi, perlindungan konsumen, dan aturan pembayaran Indonesia.

Kode ini starter sandbox, bukan integrasi produksi yang sudah diuji.
