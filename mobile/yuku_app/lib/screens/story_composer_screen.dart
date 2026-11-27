import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';

class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({super.key});
  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> {
  final _picker = ImagePicker();
  final _caption = TextEditingController();
  XFile? _file;
  String _audience = 'PUBLIC';
  bool _busy = false;
  String? _error;

  @override
  void dispose() { _caption.dispose(); super.dispose(); }

  Future<void> _pick(bool video) async {
    try {
      final file = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
      if (file != null && mounted) setState(() { _file = file; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = 'Tidak dapat membuka galeri: $e');
    }
  }

  Future<void> _publish() async {
    if (_file == null || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await MavoApi.createStory(file: _file!, content: _caption.text, audience: _audience);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MavoColors.background,
    appBar: AppBar(title: const Text('Buat Story', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        height: 390, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: MavoColors.midnight, borderRadius: BorderRadius.circular(22)),
        child: _file == null
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 54),
              const SizedBox(height: 12),
              const Text('Pilih foto atau video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Wrap(spacing: 10, children: [
                OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.photo), label: const Text('Foto')),
                OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.videocam), label: const Text('Video')),
              ]),
            ])
          : Stack(fit: StackFit.expand, children: [
              if (_file!.mimeType?.startsWith('video/') == true || _file!.path.toLowerCase().endsWith('.mp4') || _file!.path.toLowerCase().endsWith('.mov'))
                const Center(child: Icon(Icons.play_circle_fill, size: 74, color: Colors.white))
              else Image.file(File(_file!.path), fit: BoxFit.cover),
              Positioned(right: 10, top: 10, child: IconButton.filledTonal(
                onPressed: () => setState(() => _file = null),
                icon: const Icon(Icons.close), style: IconButton.styleFrom(backgroundColor: Colors.white),
              )),
            ]),
      ),
      const SizedBox(height: 16),
      TextField(controller: _caption, maxLength: 500, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Tulis cerita (opsional)', hintText: 'Apa yang ingin kamu bagikan?')),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _audience,
        decoration: const InputDecoration(labelText: 'Siapa yang bisa melihat?'),
        items: const [
          DropdownMenuItem(value: 'PUBLIC', child: Text('Publik')),
          DropdownMenuItem(value: 'FOLLOWERS', child: Text('Pengikut')),
        ],
        onChanged: (value) => setState(() => _audience = value ?? 'PUBLIC'),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
      ],
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _file == null || _busy ? null : _publish,
        icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
        label: Text(_busy ? 'Mengunggah...' : 'Bagikan Story'),
        style: FilledButton.styleFrom(backgroundColor: MavoColors.violet, padding: const EdgeInsets.symmetric(vertical: 15)),
      ),
      const SizedBox(height: 8),
      const Text('Story akan otomatis hilang setelah 24 jam.', textAlign: TextAlign.center,
        style: TextStyle(color: MavoColors.muted, fontSize: 11)),
    ]),
  );
}
