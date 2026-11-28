import 'package:flutter/material.dart';
import '../theme/yuku_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selected = 0;
  static const _tabs = ['Semua', 'Menunggu', 'Berjalan', 'Selesai'];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
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
      Expanded(child: Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 76, height: 76,
            decoration: const BoxDecoration(color: MavoColors.violetSoft, shape: BoxShape.circle),
            child: const Icon(Icons.calendar_month_rounded, color: MavoColors.violet, size: 36),
          ),
          const SizedBox(height: 18),
          const Text('Belum ada booking', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
          const SizedBox(height: 7),
          const Text(
            'Pesanan layanan yang kamu buat akan tampil di sini, mulai dari permintaan hingga layanan selesai.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MavoColors.muted, height: 1.45, fontSize: 13),
          ),
        ]),
      ))),
    ]),
  );
}
