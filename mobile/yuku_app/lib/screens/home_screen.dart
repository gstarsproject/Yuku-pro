import 'package:flutter/material.dart';
import '../services/yuku_api.dart';
import '../theme/yuku_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('YUKU', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: YukuColors.navy, letterSpacing: 1)),
                  Text('Yuk, Ketemu.', style: TextStyle(color: YukuColors.muted)),
                ])),
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
                CircleAvatar(backgroundColor: YukuColors.navy, child: const Icon(Icons.person, color: Colors.white)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            sliver: SliverToBoxAdapter(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari teman atau jasa...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.tune),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: YukuApi.health(),
                builder: (context, snapshot) {
                  final connected = snapshot.hasData && snapshot.data?['status'] == 'ok';
                  final failed = snapshot.hasError;
                  final color = connected ? const Color(0xFF168653) : (failed ? Colors.redAccent : YukuColors.muted);
                  final label = connected ? 'Server YUKU terhubung' : (failed ? 'Server belum terhubung' : 'Menghubungkan ke server...');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      Icon(Icons.circle, size: 9, color: color),
                      const SizedBox(width: 9),
                      Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    ]),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [YukuColors.navy, YukuColors.blue]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Temukan orang yang tepat.', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Booking teman, pengalaman, dan jasa profesional.', style: TextStyle(color: Colors.white70)),
                ]),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Jelajahi YUKU', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .92,
              children: const [
                _CategoryCard(icon: Icons.people_alt_outlined, title: 'Friend', subtitle: 'Teman aktivitas', color: Color(0xFFEAF1FF)),
                _CategoryCard(icon: Icons.explore_outlined, title: 'Experience', subtitle: 'Jelajah pengalaman', color: Color(0xFFF0EBFF)),
                _CategoryCard(icon: Icons.workspace_premium_outlined, title: 'Pro', subtitle: 'Jasa profesional', color: Color(0xFFE8F7F1)),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text('Pilihan untukmu', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [
                  Icon(Icons.verified_user_outlined, color: YukuColors.blue, size: 30),
                  SizedBox(width: 12),
                  Expanded(child: Text('Pilih provider terverifikasi dan baca detail layanan sebelum booking.', style: TextStyle(color: YukuColors.ink))),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _CategoryCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircleAvatar(radius: 23, backgroundColor: color, child: Icon(icon, color: YukuColors.navy)),
      const SizedBox(height: 9),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 3),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: YukuColors.muted)),
    ]),
  );
}
