# Status Proyek MAVO

| Modul | Status paket saat ini |
|---|---|
| Brand guideline dan screen specification | Dokumen awal tersedia |
| Flutter Android/iOS | Starter UI tersedia; belum seluruh layar dan alur terhubung |
| NestJS backend | Starter modular tersedia |
| PostgreSQL + Prisma | Skema awal tersedia; perlu validasi migrasi |
| Admin dashboard | Starter dashboard tersedia |
| Kategori dan seed | Dasar tersedia |
| Booking Instant + Request | Implementasi awal tersedia; perlu hardening anti double-booking |
| Pembayaran Midtrans | Sandbox/starter; belum diverifikasi di akun gateway |
| Komisi kategori | Aturan awal tersedia; tarif final perlu persetujuan bisnis |
| Payout/disbursement | Model/kerangka awal; transfer aktual belum terintegrasi |
| Chat dan notifikasi | Belum lengkap |
| KYC, refund, dispute | Belum lengkap |
| Keamanan dan audit | Belum lolos audit produksi |
| Testing end-to-end | Belum dilakukan di perangkat dan server target |

## Urutan pengerjaan
1. Instalasi dan validasi build backend/database/admin/mobile.
2. Selesaikan autentikasi, role guard, dan onboarding provider.
3. Finalisasi booking + kalender dengan pencegahan bentrok jadwal.
4. Finalisasi payment gateway dan webhook.
5. Ledger, komisi, payout/disbursement, refund, dispute.
6. Chat, notifikasi, review, dan admin operations.
7. QA, keamanan, privasi, legal, dan persiapan publikasi.
