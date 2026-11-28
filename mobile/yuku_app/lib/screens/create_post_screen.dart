import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/yuku_theme.dart';
import '../services/mavo_api.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _attachments = [];
  String _audience = 'Publik';
  bool _publishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 88);
      if (!mounted || files.isEmpty) return;
      final previousCount = _attachments.length;
      final remaining = 10 - previousCount;
      setState(() => _attachments.addAll(files.take(remaining)));
      if (files.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimal 10 media dalam satu postingan.')),
        );
      }
    } catch (e) {
      if (mounted) _showError('Tidak bisa membuka galeri: $e');
    }
  }

  Future<void> _pickVideo() async {
    if (_attachments.length >= 10) {
      _showError('Maksimal 10 media dalam satu postingan.');
      return;
    }
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null && mounted) setState(() => _attachments.add(file));
    } catch (e) {
      if (mounted) _showError('Tidak bisa memilih video: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _publishDraft() async {
    if (_controller.text.trim().isEmpty && _attachments.isEmpty) {
      _showError('Tulis sesuatu atau tambahkan foto/video sebelum membagikan.');
      return;
    }
    setState(() => _publishing = true);
    try {
      final audience = _audience == 'Pengikut'
          ? 'FOLLOWERS'
          : (_audience == 'Privat' ? 'PRIVATE' : 'PUBLIC');
      await MavoApi.createPost(
        content: _controller.text,
        audience: audience,
        files: List<XFile>.unmodifiable(_attachments),
      );
      if (!mounted) return;
      _controller.clear();
      setState(() => _attachments.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dibagikan ke MAVO.')),
      );
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  bool _isVideo(XFile file) {
    final type = file.mimeType?.toLowerCase() ?? '';
    final path = file.name.toLowerCase();
    return type.startsWith('video/') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Buat Postingan', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        TextButton(
          onPressed: _publishing ? null : _publishDraft,
          child: _publishing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Bagikan', style: TextStyle(fontWeight: FontWeight.w800)),
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
                    onChanged: _publishing ? null : (value) => setState(() => _audience = value ?? 'Publik'),
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
              enabled: !_publishing,
              decoration: const InputDecoration(
                hintText: 'Apa yang sedang kamu pikirkan?',
                filled: false,
                border: InputBorder.none,
                counterStyle: TextStyle(color: MavoColors.muted, fontSize: 10),
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final file = _attachments[index];
                    return Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 112,
                          height: 112,
                          child: _isVideo(file)
                              ? Container(
                                  color: MavoColors.midnight,
                                  child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 42)),
                                )
                              : Image.file(File(file.path), fit: BoxFit.cover),
                        ),
                      ),
                      if (!_publishing)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(backgroundColor: Colors.white),
                            onPressed: () => setState(() => _attachments.removeAt(index)),
                            icon: const Icon(Icons.close_rounded, size: 17),
                          ),
                        ),
                    ]);
                  },
                ),
              ),
            ],
            const Divider(height: 24),
            const Text('Tambahkan ke postingan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MavoColors.midnight)),
            const SizedBox(height: 12),
            Row(children: [
              _AttachAction(
                icon: Icons.photo_library_outlined,
                label: 'Foto',
                color: MavoColors.aqua,
                onTap: _publishing ? null : _pickImages,
              ),
              const SizedBox(width: 10),
              _AttachAction(
                icon: Icons.videocam_outlined,
                label: 'Video',
                color: MavoColors.coral,
                onTap: _publishing ? null : _pickVideo,
              ),
              const SizedBox(width: 10),
              _AttachAction(
                icon: Icons.location_on_outlined,
                label: 'Lokasi',
                color: MavoColors.violet,
                onTap: () => _showError('Tag lokasi belum tersedia.'),
              ),
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
}

class _AttachAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
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
