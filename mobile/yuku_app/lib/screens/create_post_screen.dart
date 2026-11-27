import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/yuku_theme.dart';
import '../services/yuku_api.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _media = [];
  String _audience = 'Publik';
  bool _isPublishing = false;

  @override
  void dispose() {
    _controller.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _publishDraft() async {
    if (_controller.text.trim().isEmpty && _media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis sesuatu dulu sebelum membagikan.')),
      );
      return;
    }
    setState(() => _isPublishing = true);
    try {
      final audience = switch (_audience) {
        'Pengikut' => 'FOLLOWERS',
        'Privat' => 'PRIVATE',
        _ => 'PUBLIC',
      };
      await YukuApi.createPost(content: _controller.text, audience: audience);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dibagikan!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Buat Postingan', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        TextButton(
          onPressed: _isPublishing ? null : _publishDraft,
          child: _isPublishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Bagikan', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: MavoColors.violetSoft,
                child: Icon(Icons.person_rounded, color: MavoColors.violet),
              ),
              const SizedBox(width: 11),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Profil kamu', style: TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                SizedBox(height: 5),
                Text('Bagikan momen dan ceritamu', style: TextStyle(fontSize: 11, color: MavoColors.muted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: MavoColors.violetSoft, borderRadius: BorderRadius.circular(20)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _audience,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'Publik', child: Text('Publik')),
                      DropdownMenuItem(value: 'Pengikut', child: Text('Pengikut')),
                      DropdownMenuItem(value: 'Privat', child: Text('Privat')),
                    ],
                    onChanged: (value) => setState(() => _audience = value ?? 'Publik'),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              minLines: 7,
              maxLines: 12,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Apa yang sedang kamu pikirkan?',
                filled: false,
                border: InputBorder.none,
                counterStyle: TextStyle(color: MavoColors.muted, fontSize: 10),
              ),
            ),
            const Divider(height: 24),
            const Text('Tambahkan ke postingan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MavoColors.midnight)),
            const SizedBox(height: 12),
            Row(children: [
              _AttachAction(icon: Icons.photo_library_outlined, label: 'Foto', color: MavoColors.aqua, onTap: _pickImages),
              const SizedBox(width: 10),
              _AttachAction(icon: Icons.videocam_outlined, label: 'Video', color: MavoColors.coral, onTap: _pickVideo),
              const SizedBox(width: 10),
              _AttachAction(icon: Icons.location_on_outlined, label: 'Lokasi', color: MavoColors.violet, onTap: _editLocation),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: MavoColors.violetSoft, borderRadius: BorderRadius.circular(16)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_outline_rounded, color: MavoColors.violet),
            SizedBox(width: 10),
            Expanded(child: Text('Tips: Ceritakan pengalamanmu, gunakan tagar yang relevan, dan tetap jaga keamanan informasi pribadi.', style: TextStyle(color: MavoColors.midnight, fontSize: 12, height: 1.4))),
          ]),
        ),
      ],
    ),
  );

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature akan aktif setelah fitur media terhubung.')),
    );
  }
}

class _AttachAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}
