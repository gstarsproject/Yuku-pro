import 'package:flutter/material.dart';
import '../theme/mavo_theme.dart';
import '../services/mavo_api.dart';
import 'inbox_screen.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorName;
  final String bio;
  final String? creatorUserId;
  const CreatorProfileScreen({
    super.key,
    this.creatorName = 'Nadia Putri',
    this.bio = 'Creator · Travel, lifestyle, and new experiences. Sharing little moments from everywhere.',
    this.creatorUserId,
  });

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _following = false;
  int _followers = 0;
  int _followingCount = 0;
  bool _loadingFollow = false;
  bool _isBlocked = false;
  bool _blockedByUser = false;
  bool _loadingSafety = true;
  String? _followError;
  Map<String, dynamic> _profile = {};
  bool _profileLoading = true;
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
    _loadCreatorProfile();
    _loadBlockStatus();
    final id = widget.creatorUserId;
    _postsFuture = id == null || id.isEmpty ? Future.value([]) : MAVOApi.posts(authorId: id);
  }

  Future<void> _loadCreatorProfile() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty) { if (mounted) setState(() => _profileLoading = false); return; }
    try {
      final data = await MAVOApi.userProfile(id);
      if (mounted) setState(() { _profile = data; _profileLoading = false; });
    } catch (_) { if (mounted) setState(() => _profileLoading = false); }
  }

  Future<void> _loadFollowStatus() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty) return;
    try {
      final data = await MAVOApi.followStatus(id);
      if (!mounted) return;
      setState(() {
        _following = data['following'] == true;
        _followers = (data['followers'] as num?)?.toInt() ?? 0;
        _followingCount = (data['followingCount'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      if (mounted) setState(() => _followError = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadBlockStatus() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty) { if (mounted) setState(() => _loadingSafety = false); return; }
    try {
      final data = await MAVOApi.userBlockStatus(id);
      if (mounted) setState(() {
        _isBlocked = data['isBlocked'] == true;
        _blockedByUser = data['blockedByUser'] == true;
        _loadingSafety = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSafety = false);
    }
  }

  Future<void> _toggleBlock() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty || _loadingSafety || _blockedByUser) return;
    final action = _isBlocked ? 'membuka blokir' : 'memblokir';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isBlocked ? 'Buka blokir akun?' : 'Blokir akun ini?'),
        content: Text(_isBlocked
          ? 'Akun ini dapat kembali menemukan profil dan berinteraksi denganmu sesuai aturan MAVO.'
          : 'Akun ini tidak dapat berinteraksi denganmu. Kalian juga tidak bisa saling mengikuti atau mengirim pesan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_isBlocked ? 'Buka blokir' : 'Blokir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await MAVOApi.setUserBlocked(id, blocked: !_isBlocked);
      if (!mounted) return;
      setState(() { _isBlocked = !_isBlocked; _following = false; _followers = _followers; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isBlocked ? 'Akun berhasil diblokir.' : 'Blokir akun dibuka.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _reportCreator() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty) return;
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
        title: const Text('Laporkan akun'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Pilih alasan laporan. Tim MAVO akan meninjau laporan ini.'),
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
      await MAVOApi.reportUser(userId: id, reason: selected, details: details.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan terkirim. Terima kasih sudah membantu menjaga MAVO.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      details.dispose();
    }
  }

  Future<void> _showSafetyMenu() async {
    if (widget.creatorUserId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: Icon(_isBlocked ? Icons.lock_open_outlined : Icons.block_rounded, color: MavoColors.ink),
          title: Text(_isBlocked ? 'Buka blokir akun' : 'Blokir akun'),
          subtitle: Text(_isBlocked ? 'Izinkan akun ini berinteraksi kembali' : 'Batasi interaksi dengan akun ini'),
          onTap: _loadingSafety || _blockedByUser ? null : () { Navigator.pop(sheetContext); _toggleBlock(); },
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined, color: MavoColors.coral),
          title: const Text('Laporkan akun'),
          subtitle: const Text('Laporkan perilaku atau akun yang bermasalah'),
          onTap: () { Navigator.pop(sheetContext); _reportCreator(); },
        ),
        if (_blockedByUser) const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Akun ini membatasi interaksi denganmu.', style: TextStyle(color: MavoColors.muted)),
        ),
      ])),
    );
  }

  Future<void> _toggleFollow() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty || _loadingFollow) return;
    setState(() => _loadingFollow = true);
    try {
      final data = await MAVOApi.setFollow(id, follow: !_following);
      if (!mounted) return;
      setState(() {
        _following = data['following'] == true;
        _followers = (data['followers'] as num?)?.toInt() ?? _followers;
        _followingCount = (data['followingCount'] as num?)?.toInt() ?? _followingCount;
        _followError = null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loadingFollow = false);
    }
  }

  Future<void> _showRelations(String type) async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty) return;
    final title = type == 'followers' ? 'Pengikut' : 'Mengikuti';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * .72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: MAVOApi.userRelations(id, type: type),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Gagal memuat $title: ${snapshot.error}'));
                    final users = snapshot.data ?? [];
                    if (users.isEmpty) return Center(child: Text(type == 'followers' ? 'Belum ada pengikut.' : 'Belum mengikuti siapa pun.'));
                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final name = (user['displayName'] ?? 'Pengguna MAVO').toString();
                        final userId = (user['id'] ?? '').toString();
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: MavoColors.violetSoft,
                            child: Text(name.isEmpty ? 'M' : name.substring(0, 1).toUpperCase(), style: const TextStyle(color: MavoColors.violet, fontWeight: FontWeight.w800)),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(user['following'] == true ? 'Sudah kamu ikuti' : 'Belum kamu ikuti'),
                          onTap: userId.isEmpty ? null : () {
                            Navigator.pop(sheetContext);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CreatorProfileScreen(creatorName: name, creatorUserId: userId),
                            ));
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (_profile['displayName'] ?? widget.creatorName).toString();
    final displayBio = (_profile['bio'] ?? widget.bio).toString();
    final avatarUrl = (_profile['avatarUrl'] ?? '').toString();
    final verified = _profile['isVerified'] == true;
    return Scaffold(
    appBar: AppBar(
      title: const Text('Profil kreator', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [IconButton(onPressed: _showSafetyMenu, tooltip: 'Keamanan akun', icon: const Icon(Icons.more_horiz_rounded))],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Center(child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [MavoColors.violet, MavoColors.midnight]),
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            backgroundImage: avatarUrl.startsWith('https://') ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.startsWith('https://') ? null : Text(displayName.isEmpty ? 'M' : displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: MavoColors.violet)),
          ),
        )),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(displayName, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: MavoColors.midnight))),
          const SizedBox(width: 5),
          if (verified) const Icon(Icons.verified_rounded, color: MavoColors.violet, size: 18),
        ]),
        const SizedBox(height: 7),
        Text(displayBio, textAlign: TextAlign.center,
          style: const TextStyle(color: MavoColors.muted, fontSize: 12, height: 1.5)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Metric(value: _profileLoading ? '—' : (_profile['postsCount'] ?? 0).toString(), label: 'Postingan'),
          const SizedBox(width: 34),
          InkWell(onTap: widget.creatorUserId == null ? null : () => _showRelations('followers'), child: _Metric(value: _followers.toString(), label: 'Pengikut')),
          const SizedBox(width: 34),
          InkWell(onTap: widget.creatorUserId == null ? null : () => _showRelations('following'), child: _Metric(value: _followingCount.toString(), label: 'Mengikuti')),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: FilledButton.icon(
            onPressed: widget.creatorUserId == null || _loadingFollow || _isBlocked || _blockedByUser ? null : _toggleFollow,
            style: FilledButton.styleFrom(
              backgroundColor: _following ? MavoColors.violetSoft : MavoColors.violet,
              foregroundColor: _following ? MavoColors.violet : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: _loadingFollow ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_following ? Icons.check_rounded : Icons.person_add_alt_1_rounded),
            label: Text(widget.creatorUserId == null ? 'Profil demo' : (_isBlocked ? 'Diblokir' : (_blockedByUser ? 'Dibatasi' : (_following ? 'Mengikuti' : 'Ikuti')))),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: widget.creatorUserId == null || _isBlocked || _blockedByUser
                ? null
                : () => InboxScreen.openDirectChat(
                    context,
                    recipientId: widget.creatorUserId!,
                    name: displayName,
                  ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Pesan'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
          )),
        ]),
        if (_followError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_followError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 11))),
        const SizedBox(height: 24),
        const Divider(color: MavoColors.violetSoft),
        const SizedBox(height: 14),
        const Text('Postingan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MavoColors.midnight)),
        const SizedBox(height: 12),
        if (widget.creatorUserId == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Profil contoh', style: TextStyle(color: MavoColors.muted))),
          )
        else
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(18), child: Center(child: Text('Postingan gagal dimuat.', style: TextStyle(color: MavoColors.muted))));
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Column(children: [
                    Icon(Icons.photo_library_outlined, size: 38, color: MavoColors.violet),
                    SizedBox(height: 8),
                    Text('Belum ada postingan yang bisa dilihat.', textAlign: TextAlign.center,
                      style: TextStyle(color: MavoColors.muted)),
                  ])),
                );
              }
              return Column(children: posts.map((post) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MavoColors.violetSoft),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post['content']?.toString() ?? '', style: const TextStyle(color: MavoColors.midnight, height: 1.45)),
                  if ((post['locationName'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: MavoColors.muted),
                      const SizedBox(width: 4),
                      Text(post['locationName'].toString(), style: const TextStyle(fontSize: 11, color: MavoColors.muted)),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.favorite_border, size: 16, color: MavoColors.violet),
                    const SizedBox(width: 5),
                    Text('${post['likesCount'] ?? 0}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, size: 16, color: MavoColors.violet),
                    const SizedBox(width: 5),
                    Text('${post['commentsCount'] ?? 0}', style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(post['audience']?.toString() ?? 'PUBLIC', style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
                  ]),
                ]),
              )).toList());
            },
          ),
      ],
    ),
  );
  }
}

class _Metric extends StatelessWidget {
  final String value, label;
  const _Metric({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MavoColors.midnight)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
  ]);
}
