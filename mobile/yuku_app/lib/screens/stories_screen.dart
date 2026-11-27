import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';

class StoriesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  const StoriesScreen({super.key, required this.stories, this.initialIndex = 0});
  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  late int _index;
  @override
  void initState() { super.initState(); _index = widget.stories.isEmpty ? 0 : widget.initialIndex.clamp(0, widget.stories.length - 1); }

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0) return;
    if (next >= widget.stories.length) { Navigator.pop(context); return; }
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const Scaffold(body: Center(child: Text('Belum ada Story.')));
    final story = widget.stories[_index];
    final media = (story['media'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final first = media.isEmpty ? null : media.first;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: List.generate(widget.stories.length, (i) => Expanded(
            child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: i <= _index ? Colors.white : Colors.white30, borderRadius: BorderRadius.circular(4))),
          ))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(children: [
            const CircleAvatar(backgroundColor: MavoColors.violet, child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(story['authorName']?.toString() ?? 'MAVO user', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text(_timeLabel(story['createdAt']), style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ])),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
          ]),
        ),
        Expanded(child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _move(d.localPosition.dx < MediaQuery.of(context).size.width * .35 ? -1 : 1),
          child: Stack(fit: StackFit.expand, children: [
            if (first != null)
              _StoryMedia(media: first)
            else
              Container(color: MavoColors.midnight, alignment: Alignment.center,
                padding: const EdgeInsets.all(28),
                child: Text(story['content']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
            if (first != null && (story['content']?.toString().isNotEmpty ?? false))
              Positioned(left: 18, right: 18, bottom: 28,
                child: Text(story['content'].toString(), textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black87, blurRadius: 8)]))),
          ]),
        )),
      ])),
    );
  }

  String _timeLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    final mins = DateTime.now().difference(date.toLocal()).inMinutes;
    if (mins < 1) return 'Baru saja';
    if (mins < 60) return '$mins menit lalu';
    return '${mins ~/ 60} jam lalu';
  }
}

class _StoryMedia extends StatefulWidget {
  final Map<String, dynamic> media;
  const _StoryMedia({required this.media});
  @override
  State<_StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends State<_StoryMedia> {
  VideoPlayerController? _video;
  String? _url;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final url = await MavoApi.mediaUrl(widget.media['id'].toString());
      if (!mounted) return;
      setState(() => _url = url);
      if (widget.media['mediaType'] == 'VIDEO') {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await controller.initialize();
        await controller.setLooping(true);
        await controller.play();
        if (mounted) setState(() => _video = controller); else controller.dispose();
      }
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
  }

  @override
  void dispose() { _video?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('Media gagal dimuat', style: const TextStyle(color: Colors.white)));
    if (_url == null) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (widget.media['mediaType'] == 'VIDEO') {
      if (_video == null || !_video!.value.isInitialized) return const Center(child: CircularProgressIndicator(color: Colors.white));
      return Center(child: AspectRatio(aspectRatio: _video!.value.aspectRatio, child: VideoPlayer(_video!)));
    }
    return Image.network(_url!, fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 48)));
  }
}
