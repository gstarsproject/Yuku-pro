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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [MavoColors.violet, MavoColors.coral, Color(0xFFFFC45C)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('M', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MAVO', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: MavoColors.midnight, letterSpacing: 1.1)),
                  Text('Connect. Share. Explore.', style: TextStyle(color: MavoColors.muted, fontSize: 11, fontWeight: FontWeight.w500)),
                ])),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded, color: MavoColors.midnight, size: 27),
                ),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: MavoColors.violetSoft,
                  child: Icon(Icons.person_rounded, color: MavoColors.violet),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            sliver: SliverToBoxAdapter(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari orang, video, pengalaman...',
                  prefixIcon: const Icon(Icons.search_rounded, color: MavoColors.violet),
                  suffixIcon: const Icon(Icons.tune_rounded, color: MavoColors.muted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: YukuApi.health(),
                builder: (context, snapshot) {
                  final connected = snapshot.hasData && snapshot.data?['status'] == 'ok';
                  final failed = snapshot.hasError;
                  final color = connected ? const Color(0xFF15966B) : (failed ? Colors.redAccent : MavoColors.muted);
                  final label = connected ? 'MAVO online' : (failed ? 'Koneksi server bermasalah' : 'Menghubungkan...');
                  return Row(children: [
                    Icon(Icons.circle, size: 7, color: color),
                    const SizedBox(width: 7),
                    Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 8),
            sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Stories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 94,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _StoryItem(label: 'Your story', color: MavoColors.violet, isAdd: true),
                      _StoryItem(label: 'Discover', color: MavoColors.coral),
                      _StoryItem(label: 'Travel', color: MavoColors.aqua),
                      _StoryItem(label: 'Lifestyle', color: Color(0xFFFFB84D)),
                      _StoryItem(label: 'Creators', color: Color(0xFF8A6BFF)),
                      _StoryItem(label: 'Community', color: Color(0xFFEF70B5)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                _FeedTab(label: 'For You', selected: true),
                const SizedBox(width: 18),
                const _FeedTab(label: 'Following'),
                const SizedBox(width: 18),
                const _FeedTab(label: 'Live'),
                const SizedBox(width: 18),
                const _FeedTab(label: 'Explore'),
              ]),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(child: _CommunityPost()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                const Expanded(child: Text('Explore MAVO', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.midnight))),
                Text('See all', style: TextStyle(color: MavoColors.violet, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
            sliver: SliverToBoxAdapter(
              child: Row(children: const [
                Expanded(child: _PillarCard(icon: Icons.people_alt_rounded, title: 'FRIEND', subtitle: 'Meet people', color: MavoColors.violet, soft: MavoColors.violetSoft)),
                SizedBox(width: 9),
                Expanded(child: _PillarCard(icon: Icons.explore_rounded, title: 'EXPERIENCE', subtitle: 'Discover more', color: MavoColors.coral, soft: MavoColors.coralSoft)),
                SizedBox(width: 9),
                Expanded(child: _PillarCard(icon: Icons.work_rounded, title: 'PRO', subtitle: 'Find services', color: MavoColors.aqua, soft: Color(0xFFE8FAFC))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isAdd;
  const _StoryItem({required this.label, required this.color, this.isAdd = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 67,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.2),
        ),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: color.withValues(alpha: .13),
          child: isAdd
              ? Icon(Icons.add_rounded, color: color, size: 27)
              : Icon(Icons.person_rounded, color: color, size: 27),
        ),
      ),
      const SizedBox(height: 5),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: MavoColors.ink)),
    ]),
  );
}

class _FeedTab extends StatelessWidget {
  final String label;
  final bool selected;
  const _FeedTab({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? MavoColors.violet : MavoColors.muted)),
    const SizedBox(height: 6),
    Container(height: 3, width: selected ? 28 : 0, decoration: BoxDecoration(color: MavoColors.violet, borderRadius: BorderRadius.circular(3))),
  ]);
}

class _CommunityPost extends StatelessWidget {
  const _CommunityPost();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Row(children: [
          const CircleAvatar(radius: 19, backgroundColor: MavoColors.violetSoft, child: Icon(Icons.auto_awesome_rounded, color: MavoColors.violet)),
          const SizedBox(width: 9),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MAVO Community', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MavoColors.midnight)),
            Text('Discover something new · 2h', style: TextStyle(fontSize: 10, color: MavoColors.muted)),
          ])),
          const Icon(Icons.more_horiz_rounded, color: MavoColors.muted),
        ]),
      ),
      Container(
        height: 190,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MavoColors.midnight, MavoColors.violet, MavoColors.coral],
          ),
        ),
        child: Stack(children: [
          Positioned(right: -22, top: -38, child: Icon(Icons.public_rounded, size: 210, color: Colors.white.withValues(alpha: .08))),
          const Positioned(left: 18, top: 22, child: Text('YOUR WORLD,\nYOUR WAY.', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: .5))),
          Positioned(left: 20, bottom: 20, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
            child: const Text('CONNECT  •  SHARE  •  EXPLORE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          )),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Text('Temukan teman baru, pengalaman seru, dan layanan yang kamu butuhkan dalam satu tempat.', style: TextStyle(color: MavoColors.ink, fontSize: 12, height: 1.4)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
        child: Row(children: const [
          Icon(Icons.favorite_border_rounded, color: MavoColors.coral, size: 21),
          SizedBox(width: 5),
          Text('Like', style: TextStyle(color: MavoColors.muted, fontSize: 11)),
          SizedBox(width: 18),
          Icon(Icons.mode_comment_outlined, color: MavoColors.muted, size: 20),
          SizedBox(width: 5),
          Text('Comment', style: TextStyle(color: MavoColors.muted, fontSize: 11)),
          Spacer(),
          Icon(Icons.share_outlined, color: MavoColors.muted, size: 20),
        ]),
      ),
    ]),
  );
}

class _PillarCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color soft;
  const _PillarCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.soft});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      CircleAvatar(radius: 20, backgroundColor: soft, child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 8),
      Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 3),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: MavoColors.muted)),
    ]),
  );
}
