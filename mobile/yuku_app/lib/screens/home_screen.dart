import 'package:flutter/material.dart';
import '../services/yuku_api.dart';
import '../theme/yuku_theme.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExplore;
  const HomeScreen({super.key, this.onExplore});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _services = YukuApi.services();

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: () async { setState(() => _services = YukuApi.services()); await _services; },
      child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 10), sliver: SliverToBoxAdapter(
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: MavoColors.navy, borderRadius: BorderRadius.circular(13)), alignment: Alignment.center,
              child: const Text('Y', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900))),
            const SizedBox(width: 11),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YUKU', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: MavoColors.navy, letterSpacing: 1.1)),
              Text('Connect. Experience. Get Things Done.', style: TextStyle(color: MavoColors.muted, fontSize: 9.5)),
            ])),
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: MavoColors.navy)),
            const CircleAvatar(radius: 17, backgroundColor: MavoColors.blueSoft, child: Icon(Icons.person_outline_rounded, color: MavoColors.blue, size: 20)),
          ]),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 18), sliver: SliverToBoxAdapter(
          child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: MavoColors.navy, borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Temukan yang kamu butuhkan di satu tempat.', style: TextStyle(color: Colors.white, fontSize: 22, height: 1.2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Cari orang, pengalaman, dan layanan terpercaya.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 17),
              TextField(controller: _search, textInputAction: TextInputAction.search, onSubmitted: (_) => widget.onExplore?.call(),
                decoration: InputDecoration(hintText: 'Cari teman atau jasa...', prefixIcon: const Icon(Icons.search_rounded, color: MavoColors.blue),
                  suffixIcon: IconButton(onPressed: widget.onExplore, icon: const Icon(Icons.arrow_forward_rounded, color: MavoColors.blue)),
                  filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
            ]),
          ),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), sliver: SliverToBoxAdapter(
          child: Row(children: [const Expanded(child: Text('Jelajahi kategori', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.navy))),
            TextButton(onPressed: widget.onExplore, child: const Text('Lihat semua'))]),
        )),
        SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(
          child: Row(children: const [
            Expanded(child: _CategoryCard(title: 'FRIEND', subtitle: 'Teman & aktivitas', icon: Icons.people_alt_rounded, color: MavoColors.blue, soft: MavoColors.blueSoft)),
            SizedBox(width: 10),
            Expanded(child: _CategoryCard(title: 'EXPERIENCE', subtitle: 'Tur & kegiatan', icon: Icons.explore_rounded, color: MavoColors.violet, soft: MavoColors.violetSoft)),
            SizedBox(width: 10),
            Expanded(child: _CategoryCard(title: 'PRO', subtitle: 'Jasa profesional', icon: Icons.workspace_premium_rounded, color: MavoColors.navy, soft: Color(0xFFE9EDF5))),
          ]),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 10), sliver: SliverToBoxAdapter(
          child: Row(children: [const Expanded(child: Text('Layanan pilihan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.navy))),
            TextButton(onPressed: widget.onExplore, child: const Text('Jelajahi'))]),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), sliver: SliverToBoxAdapter(
          child: FutureBuilder<List<Map<String, dynamic>>>(future: _services, builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            if (snapshot.hasError) return _InfoPanel(message: 'Layanan belum dapat dimuat. Coba lagi.', action: 'Coba lagi', onTap: () => setState(() => _services = YukuApi.services()));
            final items = snapshot.data ?? [];
            if (items.isEmpty) return const _InfoPanel(message: 'Belum ada layanan tersedia. Silakan jelajahi kembali nanti.');
            return Column(children: items.take(4).map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _ServiceTile(item: item, onTap: widget.onExplore))).toList());
          }),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), sliver: SliverToBoxAdapter(
          child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: MavoColors.blueSoft, borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [Icon(Icons.verified_user_outlined, color: MavoColors.blue, size: 25), SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Utamakan layanan terpercaya', style: TextStyle(fontWeight: FontWeight.w800, color: MavoColors.navy, fontSize: 13)),
                SizedBox(height: 4), Text('Periksa profil, status verifikasi, ulasan, dan ketentuan sebelum booking.', style: TextStyle(color: MavoColors.muted, fontSize: 11, height: 1.35)),
              ])),
            ]),
          ),
        )),
      ]),
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color, soft;
  const _CategoryCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.soft});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      CircleAvatar(radius: 22, backgroundColor: soft, child: Icon(icon, color: color, size: 22)),
      const SizedBox(height: 9), Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.muted, fontSize: 9)),
    ]),
  );
}

class _ServiceTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;
  const _ServiceTile({required this.item, this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(16),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: MavoColors.blueSoft, borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.miscellaneous_services_rounded, color: MavoColors.blue, size: 25)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((item['title'] ?? 'Layanan').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.navy, fontSize: 13)),
          const SizedBox(height: 4), Text((item['providerName'] ?? 'Provider').toString(), style: const TextStyle(color: MavoColors.muted, fontSize: 11)),
          const SizedBox(height: 5), Text('Harga: ' + (item['priceAmount'] ?? 0).toString() + ' · ' + (item['priceUnit'] ?? '').toString(), style: const TextStyle(color: MavoColors.blue, fontSize: 11, fontWeight: FontWeight.w800)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: MavoColors.muted),
      ]),
    )),
  );
}

class _InfoPanel extends StatelessWidget {
  final String message;
  final String? action;
  final VoidCallback? onTap;
  const _InfoPanel({required this.message, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      const Icon(Icons.storefront_outlined, size: 30, color: MavoColors.muted), const SizedBox(height: 9),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.muted, fontSize: 12, height: 1.4)),
      if (action != null) ...[const SizedBox(height: 10), TextButton(onPressed: onTap, child: Text(action!))],
    ]),
  );
}
