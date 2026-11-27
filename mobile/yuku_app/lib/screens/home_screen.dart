import 'package:flutter/material.dart';
import '../services/yuku_api.dart';
import '../theme/yuku_theme.dart';
import 'stories_screen.dart';
import 'creator_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFeed = 0;
  final GlobalKey<_PostsFeedState> _postsFeedKey = GlobalKey<_PostsFeedState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _postsFeedKey.currentState?.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            sliver: SliverToBoxAdapter(child: _PostsFeed(key: _postsFeedKey)),
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
      ),
    );
  }
}

class _PostsFeed extends StatefulWidget {
  const _PostsFeed({super.key});
  @override
  State<_PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<_PostsFeed> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = YukuApi.posts(); }

  Future<void> refresh() async {
    final request = YukuApi.posts();
    setState(() => _future = request);
    await request;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(children: [
          const Text("Feed belum dapat dimuat.", style: TextStyle(color: MavoColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => setState(() => _future = YukuApi.posts()), child: const Text("Coba lagi")),
        ]));
      }
      final posts = snapshot.data ?? [];
      if (posts.isEmpty) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Center(child: Text("Belum ada postingan. Jadilah yang pertama berbagi cerita!", textAlign: TextAlign.center, style: TextStyle(color: MavoColors.muted))));
      return Column(children: posts.map((post) => _PostCard(post: post, onChanged: refresh)).toList());
  );
}
class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final Future<void> Function() onChanged;
  const _PostCard({required this.post, required this.onChanged});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked;
  late int _likes;
  late int _comments;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post['likedByMe'] == true;
    _likes = (widget.post['likesCount'] as num?)?.toInt() ?? 0;
    _comments = (widget.post['commentsCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final previous = _liked;
    setState(() { _busy = true; _liked = !previous; _likes += _liked ? 1 : -1; });
    try {
      final result = await YukuApi.setPostLike(widget.post['id'].toString(), liked: _liked);
      if (!mounted) return;
      setState(() { _liked = result['likedByMe'] == true; _likes = (result['likesCount'] as num).toInt(); });
    } catch (e) {
      if (!mounted) return;
      setState(() { _liked = previous; _likes += previous ? 1 : -1; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _openComments() async {
    final count = await showModalBottomSheet<int>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _PostCommentsSheet(postId: widget.post['id'].toString()),
    );
    if (count != null && mounted) setState(() => _comments = count);
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.post['authorName'] ?? 'Pengguna MAVO').toString();
    final content = (widget.post['content'] ?? '').toString();
    final authorId = (widget.post['authorId'] ?? '').toString();
    final audience = switch ((widget.post['audience'] ?? 'PUBLIC').toString()) { 'FOLLOWERS' => 'Pengikut', 'PRIVATE' => 'Privat', _ => 'Publik' };
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: authorId.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CreatorProfileScreen(creatorName: name, creatorUserId: authorId),
            )),
            child: Row(children: [
              const CircleAvatar(radius: 19, backgroundColor: MavoColors.violetSoft, child: Icon(Icons.person_rounded, color: MavoColors.violet)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                Text(audience, style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
              ])),
            ]),
          )),
          const Icon(Icons.more_horiz, color: MavoColors.muted),
        ]),
        const SizedBox(height: 13),
        Text(content, style: const TextStyle(color: MavoColors.ink, fontSize: 13, height: 1.45)),
        const Divider(height: 22),
        Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact, onPressed: _busy ? null : _toggleLike,
            icon: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _liked ? MavoColors.coral : MavoColors.muted, size: 21),
          ),
          Text('$_likes', style: const TextStyle(color: MavoColors.muted, fontSize: 12)),
          const SizedBox(width: 16),
          IconButton(visualDensity: VisualDensity.compact, onPressed: _openComments, icon: const Icon(Icons.mode_comment_outlined, color: MavoColors.muted, size: 20)),
          Text('$_comments komentar', style: const TextStyle(color: MavoColors.muted, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  final String postId;
  const _PostCommentsSheet({required this.postId});
  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final _controller = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  bool _sending = false;
  @override
  void initState() { super.initState(); _future = YukuApi.postComments(widget.postId); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await YukuApi.addPostComment(widget.postId, value);
      _controller.clear();
      setState(() => _future = YukuApi.postComments(widget.postId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
    child: SizedBox(height: MediaQuery.of(context).size.height * .65, child: Column(children: [
      const Text('Komentar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
      const SizedBox(height: 12),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Komentar gagal dimuat: ${snapshot.error}'));
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Belum ada komentar. Mulai percakapan!'));
          return ListView.builder(itemCount: items.length, itemBuilder: (context, i) {
            final item = items[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: MavoColors.violetSoft, child: Icon(Icons.person, color: MavoColors.violet)),
              title: Text((item['authorName'] ?? 'Pengguna MAVO').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: Text((item['content'] ?? '').toString()),
            );
          });
        },
      )),
      Row(children: [
        Expanded(child: TextField(controller: _controller, maxLength: 1000, decoration: const InputDecoration(hintText: 'Tulis komentar...', counterText: ''))),
        IconButton(onPressed: _sending ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, color: MavoColors.violet)),
      ]),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () async {
        final latest = await YukuApi.postComments(widget.postId);
        if (context.mounted) Navigator.pop(context, latest.length);
      }, child: const Text('Selesai'))),
    ])),
  );
}

class _StoryItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isAdd;
  const _StoryItem({required this.label, required this.color, this.isAdd = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 67,
    child: InkWell(
      borderRadius: BorderRadius.circular(35),
      onTap: () {
        if (isAdd) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload story akan aktif setelah integrasi media.')),
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StoriesScreen(initialStory: label),
          ));
        }
      },
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
      Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? MavoColors.violet : MavoColors.muted)),
      const SizedBox(height: 6),
      Container(height: 3, width: selected ? 28 : 0, decoration: BoxDecoration(color: MavoColors.violet, borderRadius: BorderRadius.circular(3))),
    ]),
  );
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
