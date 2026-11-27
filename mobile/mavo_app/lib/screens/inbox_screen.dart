import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  static Future<void> openDirectChat(
    BuildContext context, {
    required String recipientId,
    required String name,
  }) async {
    try {
      final conversation = await MAVOApi.createConversation(recipientId);
      if (!context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ChatScreen(
          conversationId: conversation['id'].toString(),
          peerId: recipientId,
          name: name,
        ),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<Map<String, dynamic>>> _future = MAVOApi.conversations();
  final TextEditingController _search = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Keep the inbox in sync when the other device sends a new message.
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    final next = MAVOApi.conversations();
    if (mounted) setState(() => _future = next);
    try { await next; } catch (_) { /* FutureBuilder displays the error. */ }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _newChat() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _NewChatDialog(),
    );
    if (selected == null || !mounted) return;
    try {
      final conversation = await MAVOApi.createConversation(selected['id'].toString());
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ChatScreen(
          conversationId: conversation['id'].toString(),
          peerId: selected['id'].toString(),
          name: selected['displayName']?.toString() ?? 'Pengguna MAVO',
        ),
      ));
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
        child: Row(children: [
          const Expanded(child: Text('Pesan', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: MavoColors.ink))),
          IconButton(onPressed: _refresh, tooltip: 'Muat ulang pesan', icon: const Icon(Icons.refresh_rounded, color: MavoColors.violet)),
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _NotificationsScreen())),
            icon: const Icon(Icons.notifications_none_rounded, color: MavoColors.violet)),
          IconButton(onPressed: _newChat, icon: const Icon(Icons.edit_square, color: MavoColors.violet)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: TextField(controller: _search, onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Cari percakapan', prefixIcon: Icon(Icons.search_rounded))),
      ),
      const SizedBox(height: 12),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Pesan belum dapat dimuat', style: TextStyle(color: MavoColors.muted)),
            TextButton(onPressed: _refresh, child: const Text('Coba lagi')),
          ]));
          final items = (snapshot.data ?? []).where((item) =>
            (item['displayName']?.toString() ?? '').toLowerCase().contains(_search.text.toLowerCase())).toList();
          if (items.isEmpty) return RefreshIndicator(onRefresh: _refresh, child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: 220, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 42, color: MavoColors.muted),
              const SizedBox(height: 10),
              const Text('Belum ada percakapan', style: TextStyle(color: MavoColors.muted)),
              TextButton.icon(onPressed: _newChat, icon: const Icon(Icons.add), label: const Text('Mulai chat')),
              TextButton(onPressed: _refresh, child: const Text('Perbarui daftar')),
            ])))]));
          return RefreshIndicator(onRefresh: _refresh, child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final item = items[index];
              final unread = (item['unreadCount'] as num?)?.toInt() ?? 0;
              final name = item['displayName']?.toString() ?? 'Pengguna MAVO';
              return ListTile(
                leading: CircleAvatar(backgroundColor: MavoColors.violetSoft,
                  child: Text(name.isEmpty ? 'M' : name[0].toUpperCase(), style: const TextStyle(color: MavoColors.violet, fontWeight: FontWeight.w800))),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.ink)),
                subtitle: Text(item['lastMessage']?.toString() ?? 'Mulai percakapan', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: unread > 0 ? MavoColors.ink : MavoColors.muted, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal)),
                trailing: unread > 0 ? CircleAvatar(radius: 11, backgroundColor: MavoColors.violet,
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10))) : null,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ChatScreen(
                    conversationId: item['id'].toString(), peerId: item['userId'].toString(), name: name)));
                  _refresh();
                },
              );
            },
          ));
        },
      )),
    ]),
  );
}

class _NewChatDialog extends StatefulWidget {
  const _NewChatDialog();
  @override
  State<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<_NewChatDialog> {
  final TextEditingController _query = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String value) async {
    if (value.trim().length < 2) { setState(() { _users = []; _error = null; }); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await MAVOApi.searchUsers(value);
      if (mounted) setState(() => _users = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _query.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Chat baru'),
    content: SizedBox(width: 360, height: 330, child: Column(children: [
      TextField(controller: _query, autofocus: true, onChanged: _search,
        decoration: const InputDecoration(hintText: 'Cari nama pengguna', prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 10),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      Expanded(child: _users.isEmpty
        ? Center(child: Text(_query.text.length < 2 ? 'Ketik minimal 2 karakter' : 'Pengguna tidak ditemukan',
            style: const TextStyle(color: MavoColors.muted)))
        : ListView.builder(itemCount: _users.length, itemBuilder: (_, i) {
            final user = _users[i];
            final name = user['displayName']?.toString() ?? 'Pengguna';
            return ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(name), onTap: () => Navigator.pop(context, user));
          })),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
  );
}

class _ChatScreen extends StatefulWidget {
  final String conversationId, peerId, name;
  const _ChatScreen({required this.conversationId, required this.peerId, required this.name});
  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _message = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String? _myId;
  bool _loading = true, _sending = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final me = await MAVOApi.currentUser();
      await MAVOApi.markConversationRead(widget.conversationId);
      final messages = await MAVOApi.conversationMessages(widget.conversationId);
      if (mounted) setState(() { _myId = me?['id']?.toString(); _messages = messages; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _send() async {
    final value = _message.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await MAVOApi.sendMessage(widget.conversationId, value);
      _message.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() { _message.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w800))),
    body: Column(children: [
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: TextButton(onPressed: _load, child: const Text('Muat ulang pesan')))
        : RefreshIndicator(onRefresh: _load, child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16),
          itemCount: _messages.length, itemBuilder: (_, index) {
            final message = _messages[index];
            final mine = message['senderId']?.toString() == _myId;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: mine ? MavoColors.violet : Colors.white,
                  borderRadius: BorderRadius.circular(16)),
                child: Text(message['body']?.toString() ?? '', style: TextStyle(color: mine ? Colors.white : MavoColors.ink))));
          },
        ))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          Expanded(child: TextField(controller: _message, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
            decoration: const InputDecoration(hintText: 'Tulis pesan...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _sending ? null : _send,
            style: IconButton.styleFrom(backgroundColor: MavoColors.violet, foregroundColor: Colors.white),
            icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded)),
        ]))),
    ]),
  );
}

class _NotificationsScreen extends StatefulWidget {
  const _NotificationsScreen();
  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future = MAVOApi.notifications();
  Future<void> _refresh() async => setState(() => _future = MAVOApi.notifications());

  Future<void> _markAll() async {
    await MAVOApi.markNotificationsRead();
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifikasi'), actions: [TextButton(onPressed: _markAll, child: const Text('Tandai dibaca'))]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: TextButton(onPressed: _refresh, child: const Text('Coba lagi')));
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const Center(child: Text('Belum ada notifikasi', style: TextStyle(color: MavoColors.muted)));
      return RefreshIndicator(onRefresh: _refresh, child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(), itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = items[index];
          final read = item['readAt'] != null;
          return ListTile(leading: CircleAvatar(backgroundColor: MavoColors.violetSoft,
              child: Icon(item['type'] == 'MESSAGE' ? Icons.chat_bubble_outline : Icons.notifications_none, color: MavoColors.violet)),
            title: Text(item['message']?.toString() ?? 'Aktivitas baru',
              style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w800, color: MavoColors.ink)),
            subtitle: Text(item['actorName']?.toString() ?? 'MAVO', style: const TextStyle(color: MavoColors.muted)),
            trailing: read ? null : const Icon(Icons.circle, size: 9, color: MavoColors.violet));
        },
      ));
    }),
  );
}
