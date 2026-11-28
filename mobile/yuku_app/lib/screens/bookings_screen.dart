import 'package:flutter/material.dart';
import '../services/yuku_api.dart';
import '../theme/yuku_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int selected = 0;
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> bookings = const [];
  static const tabs = ['Semua', 'Menunggu', 'Berjalan', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!YukuApi.isSignedIn) {
      if (mounted) setState(() { bookings = []; loading = false; error = null; });
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final result = await YukuApi.myBookings();
      if (mounted) setState(() { bookings = result; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  bool _matches(Map<String, dynamic> item) {
    if (selected == 0) return true;
    final status = (item['status'] ?? '').toString().toUpperCase();
    if (selected == 1) return ['PENDING_PROVIDER', 'AWAITING_PAYMENT', 'PAID', 'AWAITING_CONFIRMATION'].contains(status);
    if (selected == 2) return status == 'IN_PROGRESS';
    return status == 'COMPLETED';
  }

  String _statusLabel(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING_PROVIDER': return 'Menunggu provider';
      case 'AWAITING_PAYMENT': return 'Menunggu pembayaran';
      case 'PAID': return 'Sudah dibayar';
      case 'IN_PROGRESS': return 'Sedang berlangsung';
      case 'AWAITING_CONFIRMATION': return 'Menunggu konfirmasi';
      case 'COMPLETED': return 'Selesai';
      case 'CANCELLED': return 'Dibatalkan';
      case 'REJECTED': return 'Ditolak';
      default: return value.isEmpty ? 'Status tidak diketahui' : value;
    }
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Jadwal belum tersedia';
    final local = parsed.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year} • ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final visible = bookings.where(_matches).toList();
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bookings', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: MavoColors.navy)),
            const SizedBox(height: 5),
            const Text('Pantau jadwal dan pesanan layananmu.', style: TextStyle(color: MavoColors.muted, fontSize: 13)),
            const SizedBox(height: 18),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
              children: List.generate(tabs.length, (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(tabs[i]), selected: selected == i,
                  onSelected: (_) => setState(() => selected = i),
                  selectedColor: MavoColors.blueSoft,
                  labelStyle: TextStyle(color: selected == i ? MavoColors.blue : MavoColors.muted, fontWeight: FontWeight.w700),
                  side: BorderSide.none, showCheckmark: false),
              )),
            )),
          ]),
        ),
        Expanded(child: RefreshIndicator(
          onRefresh: _load,
          child: Builder(builder: (context) {
            if (loading) return ListView(children: [const SizedBox(height: 140), Center(child: CircularProgressIndicator())]);
            if (error != null) return ListView(padding: const EdgeInsets.all(24), children: [
              const SizedBox(height: 70), const Icon(Icons.cloud_off_outlined, size: 46, color: MavoColors.muted),
              const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 14), Center(child: OutlinedButton(onPressed: _load, child: const Text('Coba lagi'))),
            ]);
            if (!YukuApi.isSignedIn) return ListView(padding: const EdgeInsets.all(28), children: const [
              SizedBox(height: 70), Icon(Icons.lock_outline_rounded, size: 46, color: MavoColors.violet),
              SizedBox(height: 14), Text('Masuk untuk melihat booking', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: MavoColors.navy)),
              SizedBox(height: 7), Text('Booking akan tampil otomatis setelah kamu masuk ke akun MAVO.', textAlign: TextAlign.center, style: TextStyle(color: MavoColors.muted, height: 1.45)),
            ]);
            if (visible.isEmpty) return ListView(padding: const EdgeInsets.all(28), children: [
              const SizedBox(height: 65), const Icon(Icons.calendar_month_rounded, size: 54, color: MavoColors.blue),
              const SizedBox(height: 16), Text(selected == 0 ? 'Belum ada booking' : 'Tidak ada booking di kategori ini',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.navy)),
              const SizedBox(height: 7), const Text('Pesanan layananmu akan tampil di sini, mulai dari permintaan hingga layanan selesai.',
                textAlign: TextAlign.center, style: TextStyle(color: MavoColors.muted, height: 1.45, fontSize: 13)),
            ]);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = visible[index];
                final service = item['service'] is Map ? item['service'] as Map : const {};
                final status = (item['status'] ?? '').toString();
                final isDone = status.toUpperCase() == 'COMPLETED';
                final amount = item['totalAmount'] ?? item['amount'] ?? item['priceAmount'];
                final currency = item['currency'] ?? item['payment']?['currency'] ?? 'IDR';
                return Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(service['title']?.toString() ?? 'Layanan MAVO', style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.navy, fontSize: 15))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: isDone ? const Color(0xFFE5F6EE) : MavoColors.blueSoft, borderRadius: BorderRadius.circular(20)),
                      child: Text(_statusLabel(status), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: MavoColors.blue))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [const Icon(Icons.schedule_rounded, size: 15, color: MavoColors.muted), const SizedBox(width: 6), Text(_date(item['startsAt']), style: const TextStyle(fontSize: 12, color: MavoColors.muted))]),
                  if (amount != null) ...[
                    const SizedBox(height: 8),
                    Text('$currency $amount', style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.ink)),
                  ],
                  if (item['id'] != null) ...[
                    const SizedBox(height: 7),
                    Text('ID: ${item['id']}', style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
                  ],
                ])));
              },
            );
          }),
        )),
      ]),
    );
  }
}
