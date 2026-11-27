import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';

class StoriesScreen extends StatefulWidget {
  final String initialStory;
  final String? initialUserId;
  const StoriesScreen({super.key, this.initialStory = 'Discover', this.initialUserId});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  late Future<List<Map<String, dynamic>>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = MAVOApi.stories();
  }

  Future<void> _refresh() async {
    final request = MAVOApi.stories();
    setState(() => _storiesFuture = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder displays the error and keeps retry available.
    }
  }

  Future<void> _composeStory() async {
    final controller = TextEditingController();
    final locationController = TextEditingController();
    final picker = ImagePicker();
    final media = <XFile>[];
    String audience = 'PUBLIC';
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Buat Story', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 500,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(hintText: 'Apa cerita kamu hari ini?', border: OutlineInputBorder()),
            ),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(onPressed: () async {
                final files = await picker.pickMultiImage(imageQuality: 88);
                if (files.isNotEmpty) setSheetState(() { media.addAll(files); if (media.length > 10) media.removeRange(10, media.length); });
              }, icon: const Icon(Icons.photo_library_outlined), label: const Text('Foto')),
              OutlinedButton.icon(onPressed: () async {
                final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 3));
                if (file != null) setSheetState(() { media.removeWhere((x) => ['mp4','mov'].contains(x.name.toLowerCase().split('.').last)); if (media.length < 10) media.add(file); });
              }, icon: const Icon(Icons.videocam_outlined), label: const Text('Video')),
              OutlinedButton.icon(onPressed: () async {
                final loc = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('Lokasi Story'), content: TextField(controller: locationController, maxLength: 200, decoration: const InputDecoration(hintText: 'Contoh: Bogor, Jawa Barat')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, locationController.text.trim()), child: const Text('Simpan'))]));
                if (loc != null) setSheetState(() {});
              }, icon: const Icon(Icons.location_on_outlined), label: const Text('Lokasi')),
            ]),
            if (media.isNotEmpty) Text('${media.length} file dipilih', style: const TextStyle(color: MavoColors.violet, fontSize: 12)),
            if (locationController.text.isNotEmpty) Text('Lokasi: ${locationController.text}', style: const TextStyle(color: MavoColors.violet, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: audience,
              decoration: const InputDecoration(labelText: 'Siapa yang bisa melihat?'),
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('Publik')),
                DropdownMenuItem(value: 'FOLLOWERS', child: Text('Pengikut')),
              ],
              onChanged: (value) => setSheetState(() => audience = value ?? 'PUBLIC'),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isEmpty && media.isEmpty) return;
                try {
                  final uploaded = <Map<String,dynamic>>[];
                  for (final item in media) {
                    final ext = item.name.toLowerCase().split('.').last;
                    final isVideo = ['mp4','mov'].contains(ext);
                    final mime = switch (ext) { 'jpg' || 'jpeg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp', 'gif' => 'image/gif', 'mov' => 'video/quicktime', _ => 'video/mp4' };
                    uploaded.add(await MAVOApi.uploadMediaFile(file: File(item.path), mediaType: isVideo ? 'VIDEO' : 'IMAGE', contentType: mime));
                  }
                  await MAVOApi.createStory(content: content, audience: audience, media: uploaded, locationName: locationController.text);
                  if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                } catch (e) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                }
              },
              child: const Text('Bagikan Story'),
            )),
          ]),
        ),
      ),
    );
    controller.dispose();
    locationController.dispose();
    if (created == true && mounted) {
      await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story berhasil dibagikan. Berlaku selama 24 jam.')));
    }
  }

  void _viewStory(Map<String, dynamic> story) {
    final name = (story['authorName'] ?? 'Pengguna MAVO').toString();
    final content = (story['content'] ?? '').toString();
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 390),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MavoColors.violet, MavoColors.midnight, MavoColors.coral],
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
            ]),
            Center(child: Text(content, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.45, fontWeight: FontWeight.w700))),
            if ((story['locationName'] ?? '').toString().isNotEmpty) Text('📍 ${story['locationName']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (story['media'] is List) ...(story['media'] as List).whereType<Map<String,dynamic>>().take(3).map((item) => _StoryMedia(mediaId: item['id'].toString(), mediaType: item['mediaType'].toString())),
            const Text('MAVO · STORY 24 JAM', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.1)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MavoColors.background,
    appBar: AppBar(
      title: const Text('MAVO Stories', style: TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: MavoColors.background,
      foregroundColor: MavoColors.midnight,
      actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _composeStory,
      backgroundColor: MavoColors.violet,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Buat Story'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _storiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Story belum dapat dimuat.'),
          TextButton(onPressed: _refresh, child: const Text('Coba lagi')),
          ]));
        }
        final allStories = snapshot.data ?? <Map<String, dynamic>>[];
        final stories = widget.initialUserId == null || widget.initialUserId!.isEmpty
            ? allStories
            : allStories.where((story) => (story['userId'] ?? story['authorId'] ?? '').toString() == widget.initialUserId).toList();
        if (stories.isEmpty) return Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome_rounded, size: 54, color: MavoColors.violet),
            const SizedBox(height: 14),
            Text(widget.initialUserId == null ? 'Belum ada Story' : 'Belum ada Story dari ${widget.initialStory}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
            const SizedBox(height: 6),
            const Text('Bagikan momen singkatmu. Story akan hilang otomatis setelah 24 jam.', textAlign: TextAlign.center, style: TextStyle(color: MavoColors.muted)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _composeStory, icon: const Icon(Icons.add), label: const Text('Buat Story')),
          ]),
        ));
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final story = stories[index];
              final name = (story['authorName'] ?? 'Pengguna MAVO').toString();
              final content = (story['content'] ?? '').toString();
              final audience = story['audience'] == 'FOLLOWERS' ? 'Pengikut' : 'Publik';
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => _viewStory(story),
                  leading: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: MavoColors.violet, width: 2)),
                    child: const CircleAvatar(backgroundColor: MavoColors.violetSoft, child: Icon(Icons.auto_awesome, color: MavoColors.violet)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                  subtitle: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(audience, style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}


class _StoryMedia extends StatelessWidget {
  final String mediaId; final String mediaType;
  const _StoryMedia({required this.mediaId, required this.mediaType});
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: MAVOApi.mediaDownloadUrl(mediaId),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox(height: 70, child: Center(child: CircularProgressIndicator(color: Colors.white)));
      if (mediaType == 'VIDEO') return _StoryVideo(url: snapshot.data!);
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(snapshot.data!, height: 180, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white)));
    },
  );
}
class _StoryVideo extends StatefulWidget {
  final String url; const _StoryVideo({required this.url});
  @override State<_StoryVideo> createState() => _StoryVideoState();
}
class _StoryVideoState extends State<_StoryVideo> {
  late final VideoPlayerController _controller;
  @override void initState() { super.initState(); _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) { if (mounted) setState(() {}); }); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: Colors.white)));
    return AspectRatio(aspectRatio: _controller.value.aspectRatio, child: Stack(alignment: Alignment.center, children: [VideoPlayer(_controller), IconButton(onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()), iconSize: 48, color: Colors.white, icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle))]));
  }
}