import 'package:flutter/material.dart';
import '../theme/yuku_theme.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _search = TextEditingController();
  final List<_Conversation> _conversations = [
    _Conversation('Nadia Putri', 'Hai! Kapan kita mulai?', '10:42', 2, true, const Color(0xFFFF8BA7)),
    _Conversation('Rizky Mahendra', 'Makasih banyak ya 🙌', '09:18', 0, true, const Color(0xFF6C9BFF)),
    _Conversation('MAVO Creators', 'Dina: Ada event baru minggu ini', 'Kemarin', 5, false, const Color(0xFF9B7BFF), group: true),
    _Conversation('Kevin Tan', 'Voice message · 0:18', 'Kemarin', 0, false, const Color(0xFF55BFAF)),
    _Conversation('Sarah Amelia', 'Sampai ketemu di sana!', 'Sen', 0, false, const Color(0xFFFFB45C)),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _conversations.where((c) =>
      c.name.toLowerCase().contains(_search.text.toLowerCase())).toList();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(children: [
              const Expanded(child: Text('Pesan', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: MavoColors.ink))),
              IconButton(onPressed: () => _showInfo(context), icon: const Icon(Icons.edit_square, color: MavoColors.violet)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cari percakapan',
                prefixIcon: Icon(Icons.search_rounded),
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 94,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              children: [
                _StoryAvatar(name: 'Catatan', color: MavoColors.violet, add: true),
                _StoryAvatar(name: 'Nadia', color: const Color(0xFFFF8BA7), online: true),
                _StoryAvatar(name: 'Rizky', color: const Color(0xFF6C9BFF), online: true),
                _StoryAvatar(name: 'Kevin', color: const Color(0xFF55BFAF)),
                _StoryAvatar(name: 'Sarah', color: const Color(0xFFFFB45C)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(children: [
              Text('Semua pesan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: MavoColors.ink)),
              Spacer(),
              Text('Terbaru', style: TextStyle(color: MavoColors.muted, fontSize: 12)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: MavoColors.muted),
            ]),
          ),
          Expanded(
            child: filtered.isEmpty
              ? const Center(child: Text('Percakapan tidak ditemukan', style: TextStyle(color: MavoColors.muted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 3),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      leading: _Avatar(name: c.name, color: c.color, group: c.group, online: c.online),
                      title: Row(children: [
                        Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.ink))),
                        Text(c.time, style: TextStyle(fontSize: 11, color: c.unread > 0 ? MavoColors.violet : MavoColors.muted)),
                      ]),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(children: [
                          Expanded(child: Text(c.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.unread > 0 ? MavoColors.ink : MavoColors.muted, fontWeight: c.unread > 0 ? FontWeight.w600 : FontWeight.w400))),
                          if (c.unread > 0) Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: MavoColors.violet, shape: BoxShape.circle),
                            child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ]),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ChatScreen(conversation: c))),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text('Pratinjau chat · pesan belum tersinkronisasi', style: TextStyle(fontSize: 10, color: MavoColors.muted.withOpacity(.8))),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat baru akan aktif setelah layanan pesan MAVO terhubung.')),
    );
  }
}

class _Conversation {
  final String name, preview, time;
  final int unread;
  final bool online, group;
  final Color color;
  const _Conversation(this.name, this.preview, this.time, this.unread, this.online, this.color, {this.group = false});
}

class _StoryAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final bool online, add;
  const _StoryAvatar({required this.name, required this.color, this.online = false, this.add = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 69,
    child: Column(children: [
      Stack(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: add ? MavoColors.violet.withOpacity(.25) : color, width: 2)),
          child: CircleAvatar(radius: 25, backgroundColor: color.withOpacity(.13), child: add ? const Icon(Icons.add_rounded, color: MavoColors.violet) : Text(name.substring(0, 1), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18))),
        ),
        if (online) Positioned(right: 1, bottom: 2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF36C98F), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
      ]),
      const SizedBox(height: 5),
      Text(name, style: const TextStyle(fontSize: 11, color: MavoColors.muted)),
    ]),
  );
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final bool group, online;
  const _Avatar({required this.name, required this.color, this.group = false, this.online = false});

  @override
  Widget build(BuildContext context) => Stack(children: [
    CircleAvatar(radius: 26, backgroundColor: color.withOpacity(.15), child: group ? Icon(Icons.groups_rounded, color: color) : Text(name.substring(0, 1), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 19))),
    if (online) Positioned(right: 0, bottom: 0, child: Container(width: 13, height: 13, decoration: BoxDecoration(color: const Color(0xFF36C98F), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
  ]);
}

class _ChatScreen extends StatefulWidget {
  final _Conversation conversation;
  const _ChatScreen({required this.conversation});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _message = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage('Hai! Senang bisa terhubung di MAVO 😊', false),
    _ChatMessage('Hai juga! Apa kabar?', true),
    _ChatMessage(widgetPreview, false),
  ];

  static const String widgetPreview = 'Lagi eksplor fitur baru MAVO nih.';

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    final value = _message.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(value, true));
      _message.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 0,
      title: Row(children: [
        _Avatar(name: widget.conversation.name, color: widget.conversation.color, group: widget.conversation.group, online: widget.conversation.online),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.conversation.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Text(widget.conversation.online ? 'Online' : 'Aktif baru-baru ini', style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
        ])),
      ]),
      actions: [
        IconButton(onPressed: () => _unavailable(context), icon: const Icon(Icons.call_outlined)),
        IconButton(onPressed: () => _unavailable(context), icon: const Icon(Icons.videocam_outlined)),
      ],
    ),
    body: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), color: MavoColors.violetSoft, child: const Text('Mode pratinjau — pesan hanya tersimpan di layar ini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: MavoColors.violet))),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final m = _messages[index];
          return Align(
            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: m.mine ? MavoColors.violet : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(17), topRight: const Radius.circular(17),
                  bottomLeft: Radius.circular(m.mine ? 17 : 4), bottomRight: Radius.circular(m.mine ? 4 : 17),
                ),
              ),
              child: Text(m.text, style: TextStyle(color: m.mine ? Colors.white : MavoColors.ink, fontSize: 13)),
            ),
          );
        },
      )),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          IconButton(onPressed: () => _unavailable(context), icon: const Icon(Icons.add_circle_outline_rounded, color: MavoColors.violet)),
          Expanded(child: TextField(
            controller: _message,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(hintText: 'Tulis pesan...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          )),
          const SizedBox(width: 7),
          IconButton.filled(onPressed: _send, style: IconButton.styleFrom(backgroundColor: MavoColors.violet, foregroundColor: Colors.white), icon: const Icon(Icons.send_rounded)),
        ]),
      )),
    ]),
  );

  void _unavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini akan aktif setelah integrasi layanan chat.')));
  }
}

class _ChatMessage {
  final String text;
  final bool mine;
  const _ChatMessage(this.text, this.mine);
}
