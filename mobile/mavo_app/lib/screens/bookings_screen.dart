import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  Map<String, dynamic>? _user;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _future = MAVOApi.bookings();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await MAVOApi.currentUser();
      if (mounted) setState(() { _user = user; _loadingUser = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _refresh() async {
    final next = MAVOApi.bookings();
    setState(() => _future = next);
    await next;
  }

  Future<void> _action(String id, String action) async {
    try {
      await MAVOApi.bookingAction(id, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_actionMessage(action))));
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _actionMessage(String action) => switch (action) {
    'accept' => 'Permintaan booking diterima.',
    'reject' => 'Permintaan booking ditolak.',
    'start' => 'Layanan ditandai sedang berjalan.',
    'complete' => 'Layanan menunggu konfirmasi pelanggan.',
    'confirm' => 'Booking selesai. Payout masuk antrean pencairan.',
    _ => 'Status booking diperbarui.',
  };

  String _status(String value) => switch (value) {
    'PENDING_PROVIDER' => 'Menunggu provider',
    'AWAITING_PAYMENT' => 'Menunggu pembayaran',
    'PAID' => 'Sudah dibayar',
    'IN_PROGRESS' => 'Sedang berjalan',
    'AWAITING_CONFIRMATION' => 'Menunggu konfirmasi',
    'COMPLETED' => 'Selesai',
    'REJECTED' => 'Ditolak',
    'CANCELLED' => 'Dibatalkan',
    'DISPUTED' => 'Dalam sengketa',
    _ => value.replaceAll('_', ' '),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking Saya', style: TextStyle(fontWeight: FontWeight.w900))),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _loadingUser) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
              const SizedBox(height: 120),
              const Icon(Icons.cloud_off_rounded, size: 42, color: MAVOColors.muted),
              const SizedBox(height: 12),
              const Center(child: Text('Booking belum bisa dimuat.')),
              Center(child: TextButton(onPressed: _refresh, child: const Text('Coba lagi'))),
            ]);
          }
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
              SizedBox(height: 130),
              Icon(Icons.calendar_month_outlined, size: 52, color: MAVOColors.blue),
              SizedBox(height: 14),
              Center(child: Text('Belum ada booking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
              SizedBox(height: 6),
              Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 36), child: Text(
                'Pesanan layanan FRIEND, EXPERIENCE, dan PRO akan tampil di sini.',
                textAlign: TextAlign.center, style: TextStyle(color: MAVOColors.muted),
              ))),
            ]);
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id'].toString();
              final status = item['status']?.toString() ?? '';
              final isProvider = item['providerId'] == _user?['id'];
              final actions = <Widget>[];
              if (isProvider && status == 'PENDING_PROVIDER') {
                actions.add(OutlinedButton(onPressed: () => _action(id, 'reject'), child: const Text('Tolak')));
                actions.add(FilledButton(onPressed: () => _action(id, 'accept'), child: const Text('Terima')));
              } else if (isProvider && status == 'PAID') {
                actions.add(FilledButton(onPressed: () => _action(id, 'start'), child: const Text('Mulai layanan')));
              } else if (isProvider && status == 'IN_PROGRESS') {
                actions.add(FilledButton(onPressed: () => _action(id, 'complete'), child: const Text('Ajukan selesai')));
              } else if (!isProvider && status == 'AWAITING_CONFIRMATION') {
                actions.add(FilledButton(onPressed: () => _action(id, 'confirm'), child: const Text('Konfirmasi selesai')));
              }
              final amount = (item['totalAmount'] as num?)?.toInt() ?? 0;
              final start = DateTime.tryParse(item['startsAt']?.toString() ?? '')?.toLocal();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEF8))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(item['serviceTitle']?.toString() ?? 'Layanan MAVO',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: MAVOColors.navy, fontSize: 15))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: MAVOColors.blueSoft, borderRadius: BorderRadius.circular(20)),
                      child: Text(_status(status), style: const TextStyle(color: MAVOColors.blue, fontSize: 10, fontWeight: FontWeight.w800))),
                  ]),
                  const SizedBox(height: 8),
                  Text(start == null ? 'Jadwal belum tersedia' : '\${start.day}/\${start.month}/\${start.year} · \${start.hour.toString().padLeft(2,'0')}:\${start.minute.toString().padLeft(2,'0')}',
                    style: const TextStyle(color: MAVOColors.muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('Total: \${item['currency'] ?? 'IDR'} \${amount.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: MAVOColors.navy)),
                  if (item['paymentStatus'] != null) Text('Pembayaran: \${item['paymentStatus']}', style: const TextStyle(color: MAVOColors.muted, fontSize: 11)),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.end, children: actions),
                  ],
                ]),
              );
            },
          );
        },
      ),
    ),
  );
}
