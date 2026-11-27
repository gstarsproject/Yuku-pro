import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = MavoApi.conversations();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = MavoApi.conversations());

  Future<void> _newChat() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _UserSearchDialog(),
    );
    if (!mounted || selected == null) return;
    try {
      final id = await MavoApi.createConversation(selected['id'].toString());
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ChatScreen(conversationId: id, title: selected['displayName']?.toString() ?? 'Chat'),
      ));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Row(children: [
          const Expanded(child: Text('Pesan', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: MavoColors.ink))),
          IconButton(onPressed: _newChat, icon: const Icon(Icons.edit_square, color: MavoColors.violet), tooltip: 'Chat baru'),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded, color: MavoColors.violet)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: TextField(controller: _search, onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Cari percakapan', prefixIcon: Icon(Icons.search_rounded), contentPadding: EdgeInsets.symmetric(vertical: 13))),
      ),
      const SizedBox(height: 14),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: Row(children: [
          Text('Semua pesan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: MavoColors.ink)),
          Spacer(),
          Text('Tersinkronisasi', style: TextStyle(color: MavoColors.muted, fontSize: 11)),
        ]),
      ),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _MessageState(text: 'Percakapan gagal dimuat.\n${snapshot.error.toString().replaceFirst('Exception: ', '')}', onRetry: _reload);
          final q = _search.text.trim().toLowerCase();
          final rows = (snapshot.data ?? []).where((c) =>
            (c['displayName']?.toString().toLowerCase() ?? '').contains(q) ||
            (c['lastMessage']?.toString().toLowerCase() ?? '').contains(q)).toList();
          if (rows.isEmpty) return _MessageState(text: q.isEmpty ? 'Belum ada percakapan.\nMulai chat dengan pengguna yang saling mengikuti.' : 'Percakapan tidak ditemukan.', onRetry: _newChat, actionLabel: 'Chat baru');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final c = rows[index];
              final name = c['displayName']?.toString() ?? 'Pengguna MAVO';
              final unread = (c['unreadCount'] as num?)?.toInt() ?? 0;
              final preview = c['lastMessage']?.toString() ?? 'Mulai percakapan';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                tileColor: Colors.white,
                leading: CircleAvatar(radius: 25, backgroundColor: MavoColors.violetSoft,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: MavoColors.violet, fontWeight: FontWeight.w900))),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.ink)),
                subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: MavoColors.muted))),
                trailing: unread > 0 ? CircleAvatar(radius: 11, backgroundColor: MavoColors.violet,
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10))) : null,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                    _ChatScreen(conversationId: c['id'].toString(), title: name)));
                  _reload();
                },
              );
            },
          );
        },
      )),
    ]),
  );
}

class _MessageState extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  final String actionLabel;
  const _MessageState({required this.text, required this.onRetry, this.actionLabel = 'Coba lagi'});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.forum_outlined, size: 42, color: MavoColors.violet),
      const SizedBox(height: 12),
      Text(text, textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.muted)),
      const SizedBox(height: 12),
      TextButton(onPressed: onRetry, child: Text(actionLabel)),
    ]),
  ));
}

class _UserSearchDialog extends StatefulWidget {
  const _UserSearchDialog();
  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final TextEditingController _query = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _query.dispose(); super.dispose(); }

  Future<void> _search(String value) async {
    if (value.trim().length < 2) { setState(() { _users = []; _error = null; }); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await MavoApi.searchUsers(value);
      if (mounted) setState(() => _users = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Chat baru'),
    content: SizedBox(width: double.maxFinite, height: 360, child: Column(children: [
      TextField(controller: _query, autofocus: true, onChanged: _search,
        decoration: const InputDecoration(hintText: 'Cari nama pengguna', prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 10),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      Expanded(child: _users.isEmpty
        ? const Center(child: Text('Ketik minimal 2 huruf untuk mencari pengguna.', textAlign: TextAlign.center))
        : ListView.builder(itemCount: _users.length, itemBuilder: (_, i) {
            final user = _users[i];
            final name = user['displayName']?.toString() ?? 'Pengguna';
            return ListTile(
              leading: CircleAvatar(backgroundColor: MavoColors.violetSoft, child: Text(name.isEmpty ? '?' : name[0].toUpperCase())),
              title: Text(name),
              onTap: () => Navigator.pop(context, user),
            );
          })),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
  );
}

class _ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  const _ChatScreen({required this.conversationId, required this.title});
  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final items = await MavoApi.messages(widget.conversationId);
      await MavoApi.markConversationRead(widget.conversationId);
      if (!mounted) return;
      setState(() { _messages = items; _error = null; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final value = _input.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await MavoApi.sendMessage(widget.conversationId, value);
      if (!mounted) return;
      setState(() { _messages.add(sent); _input.clear(); _error = null; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)), actions: [
      IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
    ]),
    body: Column(children: [
      if (_error != null) Material(color: MavoColors.violetSoft, child: Padding(
        padding: const EdgeInsets.all(9), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.violet, fontSize: 11)))),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _messages.isEmpty
        ? const Center(child: Text('Belum ada pesan. Mulai percakapan!', style: TextStyle(color: MavoColors.muted)))
        : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (_, i) {
            final m = _messages[i];
            final mine = m['senderId'] != null && m['senderId'] == _myUserId;
            final body = m['body']?.toString() ?? '';
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
              margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(color: mine ? MavoColors.violet : Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text(body, style: TextStyle(color: mine ? Colors.white : MavoColors.ink, fontSize: 13)),
            ));
          })),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(children: [
        Expanded(child: TextField(controller: _input, enabled: !_sending, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
          decoration: const InputDecoration(hintText: 'Tulis pesan...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
        const SizedBox(width: 7),
        IconButton.filled(onPressed: _sending ? null : _send, style: IconButton.styleFrom(backgroundColor: MavoColors.violet, foregroundColor: Colors.white), icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded)),
      ]))),
    ]),
  );

  String? get _myUserId => null;
}
