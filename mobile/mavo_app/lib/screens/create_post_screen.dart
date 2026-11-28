import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/mavo_theme.dart';
import '../services/mavo_api.dart';

class CreatePostScreen extends StatefulWidget {
  final VoidCallback? onPublished;
  const CreatePostScreen({super.key, this.onPublished});

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
      final uploaded = <Map<String,dynamic>>[];
      for (final item in _media) {
        final ext = item.name.toLowerCase().split('.').last;
        final isVideo = ['mp4','mov'].contains(ext);
        final mime = switch (ext) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          'gif' => 'image/gif',
          'mov' => 'video/quicktime',
          _ => 'video/mp4',
        };
        uploaded.add(await MAVOApi.uploadMediaFile(file: File(item.path), mediaType: isVideo ? 'VIDEO' : 'IMAGE', contentType: mime));
      }
      await MAVOApi.createPost(content: _controller.text, audience: audience, media: uploaded, locationName: _locationController.text);
      if (!mounted) return;
      _controller.clear();
      _locationController.clear();
      _media.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dibagikan!')),
      );
      widget.onPublished?.call();
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
            if (_media.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: _media.map((item) => Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: ['mp4','mov'].contains(item.name.toLowerCase().split('.').last)
                  ? Container(width: 88, height: 88, color: MavoColors.violetSoft, child: const Icon(Icons.play_circle_fill_rounded, size: 34, color: MavoColors.violet))
                  : Image.file(File(item.path), width: 88, height: 88, fit: BoxFit.cover)),
                Positioned(right: 0, top: 0, child: InkWell(onTap: () => setState(() => _media.remove(item)), child: const CircleAvatar(radius: 11, backgroundColor: Colors.black87, child: Icon(Icons.close, size: 13, color: Colors.white)))),
              ])).toList()),
            ],
            if (_locationController.text.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Lokasi: ${_locationController.text}', style: const TextStyle(color: MavoColors.violet, fontSize: 12))),
            const Divider(height: 24),
            const Text('Tambahkan ke postingan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MavoColors.midnight)),
            const SizedBox(height: 12),
            Row(children: [
              _AttachAction(icon: Icons.photo_library_outlined, label: 'Foto', color: MavoColors.violet, onTap: _pickImages),
              const SizedBox(width: 10),
              _AttachAction(icon: Icons.videocam_outlined, label: 'Video', color: MavoColors.coral, onTap: _pickVideo),
              const SizedBox(width: 10),
              _AttachAction(icon: Icons.location_on_outlined, label: 'Lokasi', color: MavoColors.midnight, onTap: _editLocation),
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

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 88);
    if (!mounted || picked.isEmpty) return;
    setState(() {
      _media.addAll(picked.where((x) => !['mp4','mov'].contains(x.name.toLowerCase().split('.').last)));
      if (_media.length > 10) _media.removeRange(10, _media.length);
    });
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 3));
    if (!mounted || picked == null) return;
    setState(() {
      _media.removeWhere((x) => ['mp4','mov'].contains(x.name.toLowerCase().split('.').last));
      if (_media.length < 10) _media.add(picked);
    });
  }

  Future<void> _editLocation() async {
    final controller = TextEditingController(text: _locationController.text);
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Tambahkan lokasi'),
      content: TextField(controller:controller,maxLength:200,decoration:const InputDecoration(hintText:'Contoh: Bogor, Jawa Barat')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(context,controller.text.trim()),child:const Text('Simpan'))],
    ));
    controller.dispose();
    if (value != null && mounted) setState(()=>_locationController.text=value);
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
