import 'package:flutter/material.dart';
import '../theme/yuku_theme.dart';
import '../services/yuku_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;
  String _name = 'Nama Pengguna';
  String _bio = 'Mulai ceritakan perjalananmu bersama MAVO.';

  Future<void> _authenticate() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    bool register = false;
    bool busy = false;
    String? error;
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, refresh) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 22),
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(register ? 'Buat akun MAVO' : 'Masuk ke MAVO', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: MavoColors.navy)),
            const SizedBox(height: 6),
            const Text('Gunakan akunmu untuk mengelola booking dan layanan.', style: TextStyle(color: MavoColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            if (register) ...[
              TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama tampilan')),
              const SizedBox(height: 10),
            ],
            TextField(controller: email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password (minimal 10 karakter)')),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: MavoColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : () async {
                if (email.text.trim().isEmpty || password.text.length < 10 || (register && name.text.trim().length < 2)) {
                  refresh(() => error = 'Lengkapi data. Password minimal 8 karakter.');
                  return;
                }
                refresh(() { busy = true; error = null; });
                try {
                  if (register) {
                    await YukuApi.register(email: email.text, password: password.text, displayName: name.text);
                  } else {
                    await YukuApi.login(email: email.text, password: password.text);
                  }
                  if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                } catch (e) {
                  refresh(() { busy = false; error = e.toString().replaceFirst('Exception: ', ''); });
                }
              },
              child: Text(busy ? 'Memproses...' : (register ? 'Buat akun' : 'Masuk')),
            ),
            TextButton(
              onPressed: busy ? null : () => refresh(() { register = !register; error = null; }),
              child: Text(register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
            ),
          ],
        )),
      )),
    );
    email.dispose();
    password.dispose();
    name.dispose();
    if (success == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil masuk ke MAVO.')));
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final bioController = TextEditingController(text: _bio);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profil'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, maxLength: 40, decoration: const InputDecoration(labelText: 'Nama')),
          const SizedBox(height: 8),
          TextField(controller: bioController, maxLength: 120, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _name = nameController.text.trim().isEmpty ? 'Nama Pengguna' : nameController.text.trim();
        _bio = bioController.text.trim();
      });
    }
    nameController.dispose();
    bioController.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.menu_rounded)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [MavoColors.violet, MavoColors.coral, Color(0xFFFFC45C)]),
            ),
            child: const CircleAvatar(
              radius: 39,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 42, color: MavoColors.violet),
            ),
          ),
          const SizedBox(width: 22),
          const Expanded(child: _ProfileStat(value: '0', label: 'Postingan')),
          const Expanded(child: _ProfileStat(value: '0', label: 'Pengikut')),
          const Expanded(child: _ProfileStat(value: '0', label: 'Mengikuti')),
        ]),
        const SizedBox(height: 16),
        Text(YukuApi.currentUser?['displayName']?.toString() ?? _name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MavoColors.midnight)),
        const SizedBox(height: 5),
        Text(YukuApi.isSignedIn ? (YukuApi.currentUser?['email']?.toString() ?? 'Akun MAVO') : 'Belum masuk', style: const TextStyle(fontSize: 11, color: MavoColors.muted)),
        const SizedBox(height: 10),
        if (!YukuApi.isSignedIn)
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _authenticate, icon: const Icon(Icons.login_rounded), label: const Text('Masuk / Daftar')))
        else
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => YukuApi.signOut()), icon: const Icon(Icons.logout_rounded), label: const Text('Keluar dari akun'))),
        const SizedBox(height: 5),
        Text(_bio, style: const TextStyle(fontSize: 12, color: MavoColors.muted, height: 1.4)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _editProfile, child: const Text('Edit Profil'))),
          const SizedBox(width: 9),
          Expanded(child: OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur bagikan profil akan segera tersedia.')),
          ), child: const Text('Bagikan Profil'))),
        ]),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [MavoColors.midnight, MavoColors.violet]),
          ),
          child: const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD77A), size: 25),
            SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bangun identitas MAVO kamu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              SizedBox(height: 4),
              Text('Lengkapi profil agar komunitas lebih mudah mengenalmu.', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ])),
            Icon(Icons.chevron_right_rounded, color: Colors.white),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          _ProfileTab(icon: Icons.grid_on_rounded, selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
          _ProfileTab(icon: Icons.video_library_outlined, selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
          _ProfileTab(icon: Icons.person_pin_outlined, selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
        ]),
        const SizedBox(height: 26),
        Icon(_tab == 0 ? Icons.photo_library_outlined : (_tab == 1 ? Icons.video_library_outlined : Icons.people_outline_rounded),
          size: 42, color: MavoColors.violet.withValues(alpha: .65)),
        const SizedBox(height: 10),
        Text(
          _tab == 0 ? 'Belum ada postingan' : (_tab == 1 ? 'Belum ada video' : 'Belum ada konten bertanda'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight),
        ),
        const SizedBox(height: 5),
        const Text('Konten yang kamu bagikan akan tampil di sini.', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: MavoColors.muted)),
      ],
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MavoColors.midnight)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(fontSize: 10, color: MavoColors.muted)),
  ]);
}

class _ProfileTab extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ProfileTab({required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? MavoColors.violet : Colors.transparent, width: 2))),
        child: Icon(icon, color: selected ? MavoColors.violet : MavoColors.muted),
      ),
    ),
  );
}
