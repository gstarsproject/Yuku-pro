import 'package:flutter/material.dart';
import '../theme/yuku_theme.dart';

class StoriesScreen extends StatefulWidget {
  final String initialStory;
  const StoriesScreen({super.key, this.initialStory = 'Discover'});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  late int _index;
  final List<_StoryData> _stories = const [
    _StoryData('Discover', 'Jelajahi hal baru setiap hari.', Color(0xFFFF5C7A), Icons.explore_rounded),
    _StoryData('Travel', 'Temukan tempat yang belum pernah kamu kunjungi.', Color(0xFF27C7D9), Icons.flight_takeoff_rounded),
    _StoryData('Lifestyle', 'Bagikan momen terbaik versi kamu.', Color(0xFFFFB84D), Icons.wb_sunny_rounded),
    _StoryData('Creators', 'Karya hebat dimulai dari satu cerita.', Color(0xFF8A6BFF), Icons.auto_awesome_rounded),
    _StoryData('Community', 'Terhubung dengan komunitas MAVO.', Color(0xFFEF70B5), Icons.people_alt_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _index = _stories.indexWhere((s) => s.name == widget.initialStory);
    if (_index < 0) _index = 0;
  }

  void _next() {
    if (_index < _stories.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.pop(context);
    }
  }

  void _previous() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_index];
    return Scaffold(
      backgroundColor: MavoColors.midnight,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(children: List.generate(_stories.length, (i) => Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= _index ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(children: [
              CircleAvatar(backgroundColor: story.color.withOpacity(.2), child: Icon(story.icon, color: story.color)),
              const SizedBox(width: 10),
              Expanded(child: Text(story.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
            ]),
          ),
          Expanded(
            child: GestureDetector(
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;
                if (details.localPosition.dx < width * .35) {
                  _previous();
                } else {
                  _next();
                }
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [story.color, MavoColors.midnight],
                  ),
                ),
                child: Stack(children: [
                  Positioned(right: -35, top: 40, child: Icon(story.icon, size: 230, color: Colors.white.withOpacity(.10))),
                  Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(story.icon, size: 66, color: Colors.white),
                      const SizedBox(height: 22),
                      Text(story.name.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(story.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                      const SizedBox(height: 30),
                      const Text('MAVO · CONNECT. SHARE. EXPLORE.', style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.1)),
                    ]),
                  )),
                  Positioned(left: 0, right: 0, bottom: 0, child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload story akan aktif setelah integrasi media.'))),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                        child: const Text('Bagikan cerita'),
                      )),
                      const SizedBox(width: 10),
                      IconButton(onPressed: _next, icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
                    ]),
                  )),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StoryData {
  final String name, description;
  final Color color;
  final IconData icon;
  const _StoryData(this.name, this.description, this.color, this.icon);
}
