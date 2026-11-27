import 'package:flutter/material.dart';
import '../services/yuku_api.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';
import 'stories_screen.dart';
import 'story_composer_screen.dart';
import 'creator_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFeed = 0;

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
                const StoryStrip(),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                _FeedTab(label: 'For You', selected: _selectedFeed == 0, onTap: () => setState(() => _selectedFeed = 0)),
                const SizedBox(width: 18),
                _FeedTab(label: 'Following', selected: _selectedFeed == 1, onTap: () => setState(() => _selectedFeed = 1)),
                const SizedBox(width: 18),
                _FeedTab(label: 'Live', selected: _selectedFeed == 2, onTap: () => setState(() => _selectedFeed = 2)),
                const SizedBox(width: 18),
                _FeedTab(label: 'Explore', selected: _selectedFeed == 3, onTap: () => setState(() => _selectedFeed = 3)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: _selectedFeed == 2
                ? const _FeedNotice(message: 'Siaran Live akan tampil di sini saat fitur Live aktif.')
                : _selectedFeed == 3
                  ? const _FeedNotice(message: 'Jelajahi kreator dan konten MAVO.')
                  : _PostsFeed(followingOnly: _selectedFeed == 1),
            ),
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


class _FeedNotice extends StatelessWidget {
  final String message;
  const _FeedNotice({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.muted))),
  );
}

class _PostsFeed extends StatefulWidget {
  final bool followingOnly;
  const _PostsFeed({required this.followingOnly});
  @override
  State<_PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<_PostsFeed> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = MavoApi.posts(followingOnly: widget.followingOnly); }
  @override
  void didUpdateWidget(covariant _PostsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.followingOnly != widget.followingOnly) {
      _future = MavoApi.posts(followingOnly: widget.followingOnly);
    }
  }
  void _reload() => setState(() => _future = MavoApi.posts(followingOnly: widget.followingOnly));

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return _FeedNotice(message: 'Feed belum bisa dimuat. Periksa koneksi lalu coba lagi.\n\n' + snapshot.error.toString().replaceFirst('Exception: ', ''));
      }
      final posts = snapshot.data ?? const <Map<String, dynamic>>[];
      if (posts.isEmpty) return const _FeedNotice(message: 'Belum ada postingan. Jadilah yang pertama berbagi cerita di MAVO.');
      return Column(children: [
        for (final post in posts) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PostCard(post: post),
        ),
        TextButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Muat ulang feed')),
      ]);
    },
  );
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});
  @override
  Widget build(BuildContext context) {
    final author = post['authorName']?.toString() ?? 'Pengguna MAVO';
    final content = post['content']?.toString() ?? '';
    final likes = post['likesCount'] ?? 0;
    final comments = post['commentsCount'] ?? 0;
    final created = post['createdAt']?.toString() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEBF3)),
        boxShadow: [BoxShadow(color: MavoColors.midnight.withValues(alpha: .035), blurRadius: 14, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(radius: 19, backgroundColor: MavoColors.violetSoft, child: Icon(Icons.person_rounded, color: MavoColors.violet)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(author, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight, fontSize: 13)),
            Text(created.isEmpty ? 'MAVO' : created.replaceFirst('T', ' ').split('.').first,
              style: const TextStyle(color: MavoColors.muted, fontSize: 10)),
          ])),
          const Icon(Icons.more_horiz, color: MavoColors.muted),
        ]),
        if (content.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 13),
          child: Text(content, style: const TextStyle(color: MavoColors.ink, fontSize: 13, height: 1.45)),
        ),
        const Divider(height: 25),
        Row(children: [
          const Icon(Icons.favorite_border_rounded, color: MavoColors.muted, size: 19),
          const SizedBox(width: 5),
          Text('$likes', style: const TextStyle(color: MavoColors.muted, fontSize: 11)),
          const SizedBox(width: 18),
          const Icon(Icons.mode_comment_outlined, color: MavoColors.muted, size: 18),
          const SizedBox(width: 5),
          Text('$comments', style: const TextStyle(color: MavoColors.muted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class StoryStrip extends StatefulWidget {
  const StoryStrip({super.key});
  @override
  State<StoryStrip> createState() => _StoryStripState();
}

class _StoryStripState extends State<StoryStrip> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = MavoApi.stories(); }

  Future<void> _refresh() async { setState(() => _future = MavoApi.stories()); }

  Future<void> _compose() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const StoryComposerScreen()));
    if (created == true && mounted) await _refresh();
  }

  Future<void> _open(int index, List<Map<String, dynamic>> stories) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoriesScreen(stories: stories, initialIndex: index)));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 94,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final stories = snapshot.data ?? const <Map<String, dynamic>>[];
        if (snapshot.hasError) {
          return Row(children: [
            _StoryBubble(label: 'Buat Story', onTap: _compose, color: MavoColors.violet, isAdd: true),
            const SizedBox(width: 10),
            const Expanded(child: Center(child: Text('Story belum dapat dimuat', style: TextStyle(color: MavoColors.muted, fontSize: 11)))),
            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: MavoColors.violet)),
          ]);
        }
        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _StoryBubble(label: 'Cerita kamu', onTap: _compose, color: MavoColors.violet, isAdd: true),
            if (snapshot.connectionState == ConnectionState.waiting && stories.isEmpty)
              const SizedBox(width: 100, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
            else
              ...List.generate(stories.length, (i) {
                final story = stories[i];
                final media = (story['media'] as List<dynamic>? ?? const []);
                final mediaId = media.isNotEmpty ? (media.first as Map)['id']?.toString() : null;
                return _StoryBubble(
                  label: story['authorName']?.toString() ?? 'MAVO user',
                  color: const Color(0xFFFF6D8B),
                  mediaId: mediaId,
                  onTap: () => _open(i, stories),
                );
              }),
          ],
        );
      },
    ),
  );
}

class _StoryBubble extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isAdd;
  final String? mediaId;
  const _StoryBubble({required this.label, required this.onTap, required this.color, this.isAdd = false, this.mediaId});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(35),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2.2)),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(alpha: .13),
            child: isAdd
              ? Icon(Icons.add_rounded, color: color, size: 27)
              : (mediaId == null
                ? Icon(Icons.person_rounded, color: color, size: 27)
                : FutureBuilder<String>(
                    future: MavoApi.mediaUrl(mediaId!),
                    builder: (context, snapshot) => snapshot.hasData
                      ? ClipOval(child: Image.network(snapshot.data!, width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.person, color: color)))
                      : Icon(Icons.person_rounded, color: color, size: 27),
                  )),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: MavoColors.ink)),
      ]),
    ),
  );
}

class _FeedTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FeedTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w900 : FontWeight.w600, color: selected ? MavoColors.violet : MavoColors.muted)),
      const SizedBox(height: 6),
      Container(height: 3, width: selected ? 28 : 0, decoration: BoxDecoration(color: MavoColors.violet, borderRadius: BorderRadius.circular(3))),
    ]),
  );
}


class _PostsFeed extends StatefulWidget {
  final bool following;
  final bool liveOnly;
  const _PostsFeed({required this.following, required this.liveOnly});
  @override
  State<_PostsFeed> createState() => _PostsFeedState();
}
class _PostsFeedState extends State<_PostsFeed> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = MavoApi.posts(following: widget.following); }
  @override
  void didUpdateWidget(covariant _PostsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.following != widget.following || oldWidget.liveOnly != widget.liveOnly) {
      _future = MavoApi.posts(following: widget.following);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.liveOnly) return const Padding(padding: EdgeInsets.symmetric(vertical: 34), child: Center(child: Column(children: [
      Icon(Icons.wifi_tethering_rounded, size: 38, color: MavoColors.violet), SizedBox(height: 8),
      Text('Live streaming MAVO', style: TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
      SizedBox(height: 4), Text('Siaran langsung akan tampil di sini.', style: TextStyle(fontSize: 11, color: MavoColors.muted)),
    ])));
    return FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        const Text('Postingan belum dapat dimuat.', style: TextStyle(color: MavoColors.muted)),
        TextButton(onPressed: () => setState(() => _future = MavoApi.posts(following: widget.following)), child: const Text('Coba lagi')),
      ]));
      final posts = snapshot.data ?? const <Map<String, dynamic>>[];
      if (posts.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Center(child: Text(
        widget.following ? 'Belum ada postingan dari akun yang kamu ikuti.' : 'Belum ada postingan. Jadilah yang pertama berbagi!',
        textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.muted, fontSize: 12))));
      return Column(children: posts.map((post) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ApiPostCard(post: post))).toList());
    });
  }
}
class _ApiPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _ApiPostCard({required this.post});
  @override
  Widget build(BuildContext context) {
    final author = post['authorName']?.toString() ?? 'MAVO User';
    final content = post['content']?.toString() ?? '';
    final likes = post['likesCount'] ?? 0, comments = post['commentsCount'] ?? 0;
    final media = post['media'] is List ? post['media'] as List : const [];
    return Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEDEBF3)),
      boxShadow: [BoxShadow(color: MavoColors.midnight.withValues(alpha: .04), blurRadius: 16, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const CircleAvatar(radius: 19, backgroundColor: MavoColors.violetSoft, child: Icon(Icons.person_rounded, color: MavoColors.violet)),
          const SizedBox(width: 10), Expanded(child: Text(author, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight, fontSize: 13))),
          const Icon(Icons.more_horiz_rounded, color: MavoColors.muted)]),
        if (content.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 13), child: Text(content, style: const TextStyle(fontSize: 13, height: 1.45, color: MavoColors.ink))),
        if (media.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Row(children: [
          const Icon(Icons.perm_media_outlined, color: MavoColors.violet, size: 17), const SizedBox(width: 6),
          Text('${media.length} media', style: const TextStyle(fontSize: 11, color: MavoColors.muted))])),
        const Divider(height: 22),
        Row(children: [const Icon(Icons.favorite_border_rounded, size: 18, color: MavoColors.muted), const SizedBox(width: 5),
          Text('$likes', style: const TextStyle(fontSize: 11, color: MavoColors.muted)), const SizedBox(width: 18),
          const Icon(Icons.mode_comment_outlined, size: 18, color: MavoColors.muted), const SizedBox(width: 5),
          Text('$comments', style: const TextStyle(fontSize: 11, color: MavoColors.muted))]),
      ]));
  }
}

class _CommunityPost extends StatefulWidget {
  const _CommunityPost();

  @override
  State<_CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<_CommunityPost> {
  bool _liked = false;
  int _likes = 128;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFEDEBF3)), boxShadow: [BoxShadow(color: MavoColors.midnight.withValues(alpha: .045), blurRadius: 18, offset: const Offset(0, 6))]),
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
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CreatorProfileScreen(creatorName: 'MAVO Community', bio: 'Official MAVO community · Connect, share, and explore together.'),
            )),
            icon: const Icon(Icons.person_outline_rounded, color: MavoColors.violet),
            tooltip: 'Lihat profil kreator',
          ),
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
        child: Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() {
              _liked = !_liked;
              _likes += _liked ? 1 : -1;
            }),
            icon: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _liked ? MavoColors.coral : MavoColors.muted, size: 21),
          ),
          Text('$_likes', style: const TextStyle(color: MavoColors.muted, fontSize: 11)),
          const SizedBox(width: 14),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Komentar akan tersedia setelah fitur komunitas aktif.')),
            ),
            icon: const Icon(Icons.mode_comment_outlined, color: MavoColors.muted, size: 20),
          ),
          const Text('Comment', style: TextStyle(color: MavoColors.muted, fontSize: 11)),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur berbagi akan segera tersedia.')),
            ),
            icon: const Icon(Icons.share_outlined, color: MavoColors.muted, size: 20),
          ),
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
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEDEBF3)), boxShadow: [BoxShadow(color: MavoColors.midnight.withValues(alpha: .03), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(children: [
      CircleAvatar(radius: 20, backgroundColor: soft, child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 8),
      Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 3),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: MavoColors.muted)),
    ]),
  );
}
