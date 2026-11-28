import 'package:flutter/material.dart';
import '../theme/yuku_theme.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorName;
  final String bio;
  const CreatorProfileScreen({
    super.key,
    this.creatorName = 'Nadia Putri',
    this.bio = 'Creator · Travel, lifestyle, and new experiences. Sharing little moments from everywhere.',
  });

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _following = false;
  int _followers = 1280;

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
        ]),
        const SizedBox(height: 7),
        Text(widget.bio, textAlign: TextAlign.center,
          style: const TextStyle(color: MavoColors.muted, fontSize: 12, height: 1.5)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Metric(value: '24', label: 'Postingan'),
          const SizedBox(width: 34),
          _Metric(value: _followers.toString(), label: 'Pengikut'),
          const SizedBox(width: 34),
          const _Metric(value: '356', label: 'Mengikuti'),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: FilledButton.icon(
            onPressed: () => setState(() {
              _following = !_following;
              _followers += _following ? 1 : -1;
            }),
            style: FilledButton.styleFrom(
              backgroundColor: _following ? MavoColors.violetSoft : MavoColors.violet,
              foregroundColor: _following ? MavoColors.violet : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: Icon(_following ? Icons.check_rounded : Icons.person_add_alt_1_rounded),
            label: Text(_following ? 'Mengikuti' : 'Ikuti'),
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
