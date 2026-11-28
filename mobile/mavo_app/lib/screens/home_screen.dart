import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';
import 'stories_screen.dart';
import 'creator_profile_screen.dart';
import 'inbox_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  final ValueChanged<String>? onOpenExplore;
  const HomeScreen({super.key, this.onOpenProfile, this.onOpenExplore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFeed = 0;
  late Future<List<Map<String, dynamic>>> _storiesFuture;
  final GlobalKey<_PostsFeedState> _postsFeedKey = GlobalKey<_PostsFeedState>();

  @override
  void initState() {
    super.initState();
    _storiesFuture = MAVOApi.stories();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final storiesRequest = MAVOApi.stories();
          setState(() => _storiesFuture = storiesRequest);
          await Future.wait([
            _postsFeedKey.currentState?.refresh() ?? Future<void>.value(),
            storiesRequest.then<void>((_) {}, onError: (_) {}),
          ]);
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
                    color: MavoColors.violet,
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
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  tooltip: 'Notifikasi',
                  icon: const Icon(Icons.notifications_none_rounded, color: MavoColors.midnight, size: 27),
                ),
                InkWell(
                  onTap: widget.onOpenProfile,
                  borderRadius: BorderRadius.circular(24),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: MavoColors.violetSoft,
                    child: Icon(Icons.person_rounded, color: MavoColors.violet),
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            sliver: SliverToBoxAdapter(
              child: TextField(
                readOnly: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _PeopleSearchScreen())),
                decoration: InputDecoration(
                  hintText: 'Cari orang di MAVO...',
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
                future: MAVOApi.health(),
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
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _storiesFuture,
                  builder: (context, snapshot) {
                    final stories = snapshot.data ?? const <Map<String, dynamic>>[];
                    final seen = <String>{};
                    final visibleStories = stories.where((story) {
                      final id = (story['authorId'] ?? story['userId'] ?? '').toString();
                      if (id.isEmpty || seen.contains(id)) return false;
                      seen.add(id);
                      return true;
                    }).take(12).toList();
                    return SizedBox(
                      height: 94,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          const _StoryItem(label: 'Story kamu', color: MavoColors.violet, isAdd: true),
                          if (snapshot.connectionState == ConnectionState.waiting && stories.isEmpty)
                            const SizedBox(width: 65, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
                          ...visibleStories.asMap().entries.map((entry) {
                            final story = entry.value;
                            final name = (story['authorName'] ?? 'Creator').toString();
                            final colors = [MavoColors.violet, MavoColors.midnight, MavoColors.coral, MavoColors.violet];
                            return _StoryItem(label: name, color: colors[entry.key % colors.length], creatorId: (story['userId'] ?? story['authorId'] ?? '').toString());
                          }),
                          if (snapshot.hasError)
                            const SizedBox(width: 105, child: Center(child: Text('Story gagal dimuat', style: TextStyle(fontSize: 10, color: MavoColors.muted)))),
                          if (snapshot.hasData && stories.isEmpty)
                            const SizedBox(width: 125, child: Center(child: Text('Belum ada Story', style: TextStyle(fontSize: 10, color: MavoColors.muted)))),
                        ],
                      ),
                    );
                  },
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
            sliver: SliverToBoxAdapter(child: _PostsFeed(key: _postsFeedKey, feedMode: _selectedFeed)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                const Expanded(child: Text('Explore MAVO', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MavoColors.midnight))),
                TextButton(
                  onPressed: () => widget.onOpenExplore?.call(''),
                  child: const Text('Lihat semua'),
                ),
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
                Expanded(child: _PillarCard(icon: Icons.work_rounded, title: 'PRO', subtitle: 'Find services', color: MavoColors.midnight, soft: MavoColors.violetSoft)),
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
  final int feedMode;
  const _PostsFeed({super.key, required this.feedMode});
  @override
  State<_PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<_PostsFeed> {
  late Future<List<Map<String, dynamic>>> _future;

  Future<List<Map<String, dynamic>>> _loadPosts() {
    if (widget.feedMode == 1) return MAVOApi.posts(followingOnly: true);
    if (widget.feedMode == 3) return MAVOApi.posts(publicOnly: true);
    return MAVOApi.posts();
  }

  @override
  void initState() { super.initState(); _future = _loadPosts(); }

  @override
  void didUpdateWidget(covariant _PostsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedMode != widget.feedMode) _future = _loadPosts();
  }

  Future<void> refresh() async {
    if (widget.feedMode == 2) return;
    final request = _loadPosts();
    setState(() => _future = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder renders the request error; keep pull-to-refresh usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.feedMode == 2) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Column(children: [
          Icon(Icons.live_tv_rounded, size: 38, color: MavoColors.violet),
          SizedBox(height: 10),
          Text('MAVO LIVE segera hadir', style: TextStyle(color: MavoColors.midnight, fontWeight: FontWeight.w800)),
          SizedBox(height: 5),
          Text('Fitur siaran langsung belum dibuka. Tab ini belum menampilkan siaran aktif.', textAlign: TextAlign.center, style: TextStyle(color: MavoColors.muted, fontSize: 12)),
        ]),
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(children: [
          const Text("Feed belum dapat dimuat.", style: TextStyle(color: MavoColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => setState(() => _future = MAVOApi.posts()), child: const Text("Coba lagi")),
        ]));
      }
      final posts = snapshot.data ?? [];
      if (posts.isEmpty) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Center(child: Text("Belum ada postingan. Jadilah yang pertama berbagi cerita!", textAlign: TextAlign.center, style: TextStyle(color: MavoColors.muted))));
      return Column(children: posts.map((post) => _PostCard(post: post, onChanged: refresh)).toList());
    },
  );
  }
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
      final result = await MAVOApi.setPostLike(widget.post['id'].toString(), liked: _liked);
      if (!mounted) return;
      setState(() { _liked = result['likedByMe'] == true; _likes = (result['likesCount'] as num).toInt(); });
    } catch (e) {
      if (!mounted) return;
      setState(() { _liked = previous; _likes += previous ? 1 : -1; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _reportPost() async {
    const reasons = <String, String>{
      'SPAM': 'Spam atau penipuan',
      'HARASSMENT': 'Pelecehan atau perundungan',
      'HATE': 'Ujaran kebencian',
      'IMPERSONATION': 'Menyamar sebagai orang lain',
      'INAPPROPRIATE': 'Konten tidak pantas',
      'SCAM': 'Penipuan atau aktivitas mencurigakan',
      'OTHER': 'Alasan lainnya',
    };
    String selected = 'SPAM';
    final details = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Laporkan postingan'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Pilih alasan laporan. Tim MAVO akan meninjau konten ini.'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            items: reasons.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
            onChanged: (value) { if (value != null) setDialogState(() => selected = value); },
          ),
          const SizedBox(height: 10),
          TextField(controller: details, maxLength: 1000, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Detail tambahan (opsional)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Kirim laporan')),
        ],
      )),
    );
    if (confirmed != true || !mounted) { details.dispose(); return; }
    try {
      await MAVOApi.reportPost(postId: widget.post['id'].toString(), reason: selected, details: details.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan postingan terkirim. Terima kasih sudah membantu menjaga MAVO.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      details.dispose();
    }
  }

  Future<void> _openComments() async {
    final count = await showModalBottomSheet<int>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _PostCommentsSheet(postId: widget.post['id'].toString()),
    );
    if (count != null && mounted) setState(() => _comments = count);
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post['id'] != widget.post['id'] ||
        oldWidget.post['likedByMe'] != widget.post['likedByMe'] ||
        oldWidget.post['likesCount'] != widget.post['likesCount'] ||
        oldWidget.post['commentsCount'] != widget.post['commentsCount']) {
      _liked = widget.post['likedByMe'] == true;
      _likes = (widget.post['likesCount'] as num?)?.toInt() ?? 0;
      _comments = (widget.post['commentsCount'] as num?)?.toInt() ?? 0;
    }
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
          PopupMenuButton<String>(
            tooltip: 'Opsi postingan',
            icon: const Icon(Icons.more_horiz, color: MavoColors.muted),
            onSelected: (value) { if (value == 'report') _reportPost(); },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'report', child: Row(children: [
                Icon(Icons.flag_outlined, size: 18), SizedBox(width: 10), Text('Laporkan postingan'),
              ])),
            ],
          ),
        ]),
        const SizedBox(height: 13),
        if (content.isNotEmpty) Text(content, style: const TextStyle(color: MavoColors.ink, fontSize: 13, height: 1.45)),
        if ((widget.post['locationName'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.location_on_outlined, size: 15, color: MavoColors.violet), const SizedBox(width: 4), Text(widget.post['locationName'].toString(), style: const TextStyle(fontSize: 11, color: MavoColors.violet))])),
        if (widget.post['media'] is List && (widget.post['media'] as List).isNotEmpty) ...[
          const SizedBox(height: 10),
          Column(children: (widget.post['media'] as List).whereType<Map<String,dynamic>>().map((item) => _MavoPostMedia(mediaId: item['id'].toString(), mediaType: item['mediaType'].toString())).toList()),
        ],
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
  void initState() { super.initState(); _future = MAVOApi.postComments(widget.postId); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await MAVOApi.addPostComment(widget.postId, value);
      _controller.clear();
      setState(() => _future = MAVOApi.postComments(widget.postId));
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
        final latest = await MAVOApi.postComments(widget.postId);
        if (context.mounted) Navigator.pop(context, latest.length);
      }, child: const Text('Selesai'))),
    ])),
  );
}

class _StoryItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isAdd;
  final String? creatorId;
  const _StoryItem({required this.label, required this.color, this.isAdd = false, this.creatorId});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 67,
    child: InkWell(
      borderRadius: BorderRadius.circular(35),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StoriesScreen(initialStory: label, initialUserId: creatorId),
        ));
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


class _MavoPostMedia extends StatelessWidget {
  final String mediaId;
  final String mediaType;
  const _MavoPostMedia({required this.mediaId, required this.mediaType});
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: MAVOApi.mediaDownloadUrl(mediaId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError || !snapshot.hasData) return const SizedBox(height: 80, child: Center(child: Icon(Icons.broken_image_outlined, color: MavoColors.muted)));
      final url = snapshot.data!;
      if (mediaType == 'VIDEO') return _MavoNetworkVideo(url: url);
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 80, child: Center(child: Icon(Icons.broken_image_outlined)))));
    },
  );
}

class _MavoNetworkVideo extends StatefulWidget {
  final String url;
  const _MavoNetworkVideo({required this.url});
  @override
  State<_MavoNetworkVideo> createState() => _MavoNetworkVideoState();
}
class _MavoNetworkVideoState extends State<_MavoNetworkVideo> {
  late final VideoPlayerController _controller;
  @override
  void initState() { super.initState(); _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) { if (mounted) setState(() {}); }); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: Stack(alignment: Alignment.center, children: [VideoPlayer(_controller), IconButton(onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()), iconSize: 48, color: Colors.white, icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill))])));
  }
}

class _PeopleSearchScreen extends StatefulWidget {
  const _PeopleSearchScreen();
  @override
  State<_PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<_PeopleSearchScreen> {
  final _controller = TextEditingController();
  Future<List<Map<String, dynamic>>>? _results;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan minimal 2 karakter.')));
      return;
    }
    setState(() {
      _searched = true;
      _results = MAVOApi.searchUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cari orang')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Nama atau username',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.arrow_forward_rounded)),
          ),
        ),
      ),
      Expanded(
        child: !_searched
          ? const Center(child: Text('Cari dan temukan orang di komunitas MAVO.'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
                final users = snapshot.data ?? [];
                if (users.isEmpty) return const Center(child: Text('Pengguna tidak ditemukan.'));
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final id = (user['id'] ?? '').toString();
                    final name = (user['displayName'] ?? user['name'] ?? 'Pengguna MAVO').toString();
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: MavoColors.violetSoft, child: Icon(Icons.person_rounded, color: MavoColors.violet)),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text((user['username'] ?? '').toString()),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: id.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CreatorProfileScreen(creatorName: name, creatorUserId: id),
                      )),
                    );
                  },
                );
              },
            ),
      ),
    ]),
  );
}
