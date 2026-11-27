import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';

class ProfileScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;
  final Map<String, dynamic>? user;
  const ProfileScreen({super.key, this.onLogout, this.user});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _profile = {};
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    final id = widget.user?['id']?.toString() ?? '';
    _postsFuture = id.isEmpty ? Future.value([]) : MAVOApi.posts(authorId: id);
  }

  Future<void> _loadProfile() async {
    final id = widget.user?['id']?.toString() ?? '';
    if (id.isEmpty) { if (mounted) setState(() { _loading = false; _error = 'Akun tidak ditemukan.'; }); return; }
    try {
      final data = await MAVOApi.userProfile(id);
      if (mounted) setState(() { _profile = data; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: (_profile['displayName'] ?? widget.user?['displayName'] ?? '').toString());
    final bio = TextEditingController(text: (_profile['bio'] ?? '').toString());
    final picker = ImagePicker();
    XFile? selectedPhoto;
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Edit profil'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () async {
            final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
            if (photo != null) setDialogState(() => selectedPhoto = photo);
          },
          child: CircleAvatar(radius: 42, backgroundColor: MavoColors.violet.withValues(alpha: .12),
            backgroundImage: selectedPhoto != null ? FileImage(File(selectedPhoto!.path)) : ((_profile['avatarUrl'] ?? '').toString().startsWith('https://') ? NetworkImage(_profile['avatarUrl'].toString()) : null) as ImageProvider?,
            child: selectedPhoto == null && !(_profile['avatarUrl'] ?? '').toString().startsWith('https://') ? const Icon(Icons.add_a_photo_outlined, size: 30, color: MavoColors.violet) : null),
        ),
        const SizedBox(height: 6),
        TextButton.icon(onPressed: () async { final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200); if (photo != null) setDialogState(() => selectedPhoto = photo); }, icon: const Icon(Icons.photo_library_outlined), label: const Text('Ganti foto profil')),
        TextField(controller: name, maxLength: 40, decoration: const InputDecoration(labelText: 'Nama tampilan')),
        TextField(controller: bio, maxLength: 1000, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Simpan')),
      ],
    )));
    if (saved == true) {
      try {
        Map<String,dynamic>? avatarMedia;
        if (selectedPhoto != null) {
          final ext = selectedPhoto!.name.toLowerCase().split('.').last;
          final mime = switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', 'gif' => 'image/gif', _ => 'image/jpeg' };
          avatarMedia = await MAVOApi.uploadMediaFile(file: File(selectedPhoto!.path), mediaType: 'IMAGE', contentType: mime);
        }
        final result = await MAVOApi.updateProfile(displayName: name.text, bio: bio.text, avatarMedia: avatarMedia);
        if (mounted) setState(() => _profile = {..._profile, ...result});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
    name.dispose(); bio.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final avatarUrl = (_profile['avatarUrl'] ?? '').toString();
    final name = (_profile['displayName'] ?? widget.user?['displayName'] ?? 'Nama Pengguna').toString();
    final bio = (_profile['bio'] ?? 'Mulai ceritakan perjalananmu bersama MAVO.').toString();
    final verified = _profile['isVerified'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(tooltip: 'Keluar', onPressed: widget.onLogout, icon: const Icon(Icons.logout_rounded))]),
      body: RefreshIndicator(onRefresh: _loadProfile, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [MavoColors.violet, MavoColors.midnight])),
              child: CircleAvatar(radius: 42, backgroundColor: Colors.white,
                backgroundImage: avatarUrl.startsWith('https://') ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.startsWith('https://') ? null : const Icon(Icons.person_rounded, size: 42, color: MavoColors.violet))),
            const SizedBox(width: 18),
            Expanded(child: _ProfileStat(value: _loading ? '—' : (_profile['postsCount'] ?? 0).toString(), label: 'Postingan')),
            Expanded(child: _ProfileStat(value: _loading ? '—' : (_profile['followers'] ?? 0).toString(), label: 'Pengikut')),
            Expanded(child: _ProfileStat(value: _loading ? '—' : (_profile['followingCount'] ?? 0).toString(), label: 'Mengikuti')),
          ]),
          const SizedBox(height: 16),
          Row(children: [Flexible(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MavoColors.midnight))),
            if (verified) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified_rounded, color: MavoColors.violet, size: 19))]),
          const SizedBox(height: 5),
          Text(bio, style: const TextStyle(fontSize: 12, color: MavoColors.muted, height: 1.4)),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _editProfile, child: const Text('Edit Profil'))),
            const SizedBox(width: 9),
            Expanded(child: OutlinedButton(onPressed: () async {
              final shareText = 'Kenali saya di MAVO!\n$name\n$bio';
              await Clipboard.setData(ClipboardData(text: shareText));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Info profil disalin. Kamu bisa membagikannya lewat aplikasi lain.')));
            }, child: const Text('Salin Profil'))),
          ]),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [MavoColors.midnight, MavoColors.violet])),
            child: const Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD77A), size: 25), SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bangun identitas MAVO kamu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(height: 4), Text('Lengkapi profil agar komunitas lebih mudah mengenalmu.', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ])), Icon(Icons.chevron_right_rounded, color: Colors.white)])),
          const SizedBox(height: 20),
          Row(children: [
            _ProfileTab(icon: Icons.grid_on_rounded, selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
            _ProfileTab(icon: Icons.video_library_outlined, selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
            _ProfileTab(icon: Icons.person_pin_outlined, selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
          ]),
          const SizedBox(height: 26),
          if (_tab == 0)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Postingan gagal dimuat: ${snapshot.error}', style: const TextStyle(color: MavoColors.muted)));
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(28), child: Column(children: [
                    Icon(Icons.photo_library_outlined, size: 42, color: MavoColors.violet),
                    SizedBox(height: 10),
                    Text('Belum ada postingan', style: TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                    SizedBox(height: 5),
                    Text('Postingan yang kamu bagikan akan tampil di sini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: MavoColors.muted)),
                  ]));
                }
                return Column(children: posts.map((post) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(padding: const EdgeInsets.all(14), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['content']?.toString() ?? '', style: const TextStyle(color: MavoColors.ink)),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.favorite_border, size: 16, color: MavoColors.violet),
                        const SizedBox(width: 4),
                        Text('${post['likesCount'] ?? 0}'),
                        const SizedBox(width: 14),
                        const Icon(Icons.chat_bubble_outline, size: 16, color: MavoColors.violet),
                        const SizedBox(width: 4),
                        Text('${post['commentsCount'] ?? 0}'),
                        const Spacer(),
                        Text(post['audience']?.toString() ?? 'PUBLIC', style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
                      ]),
                    ],
                  )),
                )).toList());
              },
            )
          else
            Padding(padding: const EdgeInsets.all(28), child: Column(children: [
              Icon(_tab == 1 ? Icons.video_library_outlined : Icons.person_pin_outlined, size: 42, color: MavoColors.violet.withValues(alpha: .65)),
              const SizedBox(height: 10),
              Text(_tab == 1 ? 'Belum ada video' : 'Belum ada konten bertanda', textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
            ])),
        ],
      )),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MavoColors.midnight)),
    const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
  ]);
}
class _ProfileTab extends StatelessWidget {
  final IconData icon; final bool selected; final VoidCallback onTap;
  const _ProfileTab({required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? MavoColors.violet : Colors.transparent, width: 2))),
    child: Icon(icon, color: selected ? MavoColors.violet : MavoColors.muted))));
}
