import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selected = 0;
  static const _tabs = ['Semua', 'Menunggu', 'Berjalan', 'Selesai'];
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = MavoApi.bookings();
  }

  void _reload() {
    setState(() => _future = MavoApi.bookings());
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'PENDING_PROVIDER': return 'Menunggu provider';
      case 'ACCEPTED': return 'Disetujui';
      case 'AWAITING_PAYMENT': return 'Menunggu pembayaran';
      case 'PAID': return 'Sudah dibayar';
      case 'IN_PROGRESS': return 'Sedang berjalan';
      case 'COMPLETED': return 'Selesai';
      case 'REJECTED': return 'Ditolak';
      case 'CANCELLED': return 'Dibatalkan';
      case 'DISPUTED': return 'Dalam sengketa';
      case 'REFUNDED': return 'Dikembalikan';
      default: return value;
    }
  }

  bool _matches(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? '';
    if (_selected == 0) return true;
    if (_selected == 1) {
      return ['PENDING_PROVIDER', 'ACCEPTED', 'AWAITING_PAYMENT'].contains(status);
    }
    if (_selected == 2) return ['PAID', 'IN_PROGRESS'].contains(status);
    return status == 'COMPLETED';
  }

  String _date(dynamic raw) {
    if (raw == null) return 'Jadwal belum tersedia';
    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return 'Jadwal belum tersedia';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} • $h:$min';
  }

  String _money(dynamic raw, dynamic currency) {
    final amount = int.tryParse(raw?.toString() ?? '') ?? 0;
    final digits = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return "${currency ?? 'IDR'} $digits";
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bookings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
          const SizedBox(height: 5),
          const Text('Pantau jadwal dan pesanan layananmu.', style: TextStyle(color: MavoColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: List.generate(_tabs.length, (i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_tabs[i]),
                selected: _selected == i,
                onSelected: (_) => setState(() => _selected = i),
                selectedColor: MavoColors.violetSoft,
                labelStyle: TextStyle(
                  color: _selected == i ? MavoColors.violet : MavoColors.muted,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide.none,
                showCheckmark: false,
              ),
            ))),
          ),
        ]),
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, size: 42, color: MavoColors.muted),
                  const SizedBox(height: 12),
                  const Text('Booking belum bisa dimuat', style: TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                  const SizedBox(height: 6),
                  Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.muted, fontSize: 12)),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
                ]),
              ));
            }
            final items = (snapshot.data ?? []).where(_matches).toList();
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(children: const [
                  SizedBox(height: 100),
                  Icon(Icons.calendar_month_rounded, color: MavoColors.violet, size: 54),
                  SizedBox(height: 16),
                  Center(child: Text('Belum ada booking', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.midnight))),
                  SizedBox(height: 7),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text('Pesanan layanan yang kamu buat atau terima akan tampil di sini.', textAlign: TextAlign.center, style: TextStyle(color: MavoColors.muted, height: 1.45, fontSize: 13)),
                  ),
                ]),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final service = Map<String, dynamic>.from(item['service'] as Map? ?? {});
                  final other = Map<String, dynamic>.from(item['otherParty'] as Map? ?? {});
                  final profile = Map<String, dynamic>.from(other['profile'] as Map? ?? {});
                  final status = item['status']?.toString() ?? '';
                  final isDone = status == 'COMPLETED';
                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: MavoColors.line),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(service['title']?.toString() ?? 'Layanan MAVO', style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight, fontSize: 15))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(color: isDone ? const Color(0xFFE7F7EE) : MavoColors.violetSoft, borderRadius: BorderRadius.circular(20)),
                          child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDone ? const Color(0xFF218653) : MavoColors.violet)),
                        ),
                      ]),
                      const SizedBox(height: 9),
                      Text('Dengan ${profile['displayName'] ?? 'Pengguna MAVO'}', style: const TextStyle(color: MavoColors.muted, fontSize: 12)),
                      const SizedBox(height: 7),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: MavoColors.muted),
                        const SizedBox(width: 7),
                        Text(_date(item['startsAt']), style: const TextStyle(color: MavoColors.muted, fontSize: 12)),
                      ]),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(_money(item['totalAmount'], item['currency']), style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                      ),
                    ]),
                  );
                },
              ),
            );
          },
        ),
      ),
    ]),
  );
}
