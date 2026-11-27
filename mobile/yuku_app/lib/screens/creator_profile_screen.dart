import 'package:flutter/material.dart';
import '../theme/yuku_theme.dart';
import '../services/yuku_api.dart';

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
  String? _followError;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty) return;
    try {
      final data = await YukuApi.followStatus(id);
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

  Future<void> _toggleFollow() async {
    final id = widget.creatorUserId;
    if (id == null || id.isEmpty || _loadingFollow) return;
    setState(() => _loadingFollow = true);
    try {
      final data = await YukuApi.setFollow(id, follow: !_following);
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
                  future: YukuApi.userRelations(id, type: type),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Profil kreator', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu laporan dan blokir akan tersedia setelah layanan keamanan aktif.')),
      ), icon: const Icon(Icons.more_horiz_rounded))],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Center(child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [MavoColors.violet, MavoColors.coral, Color(0xFFFFC45C)]),
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            child: Text(widget.creatorName.isEmpty ? 'M' : widget.creatorName.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: MavoColors.violet)),
          ),
        )),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(widget.creatorName, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: MavoColors.midnight))),
          const SizedBox(width: 5),
          const Icon(Icons.verified_rounded, color: MavoColors.violet, size: 18),
        ]),
        const SizedBox(height: 7),
        Text(widget.bio, textAlign: TextAlign.center,
          style: const TextStyle(color: MavoColors.muted, fontSize: 12, height: 1.5)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Metric(value: '24', label: 'Postingan'),
          const SizedBox(width: 34),
          InkWell(onTap: widget.creatorUserId == null ? null : () => _showRelations('followers'), child: _Metric(value: _followers.toString(), label: 'Pengikut')),
          const SizedBox(width: 34),
          InkWell(onTap: widget.creatorUserId == null ? null : () => _showRelations('following'), child: _Metric(value: _followingCount.toString(), label: 'Mengikuti')),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: FilledButton.icon(
            onPressed: widget.creatorUserId == null || _loadingFollow ? null : _toggleFollow,
            style: FilledButton.styleFrom(
              backgroundColor: _following ? MavoColors.violetSoft : MavoColors.violet,
              foregroundColor: _following ? MavoColors.violet : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: _loadingFollow ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_following ? Icons.check_rounded : Icons.person_add_alt_1_rounded),
            label: Text(widget.creatorUserId == null ? 'Profil demo' : (_following ? 'Mengikuti' : 'Ikuti')),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Percakapan akan aktif setelah layanan chat terhubung.')),
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
        Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [MavoColors.midnight, MavoColors.violet, MavoColors.coral]),
          ),
          child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.photo_library_outlined, size: 38, color: Colors.white),
            SizedBox(height: 9),
            Text('Creator moments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 4),
            Text('Konten demo MAVO', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        ),
      ],
    ),
  );
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
