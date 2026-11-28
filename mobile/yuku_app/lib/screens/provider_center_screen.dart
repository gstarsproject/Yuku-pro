import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';

class ProviderCenterScreen extends StatefulWidget {
  const ProviderCenterScreen({super.key});

  @override
  State<ProviderCenterScreen> createState() => _ProviderCenterScreenState();
}

class _ProviderCenterScreenState extends State<ProviderCenterScreen> {
  final _headline = TextEditingController();
  final _experience = TextEditingController(text: '0');
  final _languages = TextEditingController(text: 'Bahasa Indonesia');
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _provider;
  bool _isProvider = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _headline.dispose();
    _experience.dispose();
    _languages.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await MavoApi.providerMe();
      if (!mounted) return;
      setState(() { _provider = data; _isProvider = true; _loading = false; });
      _headline.text = data['headline']?.toString() ?? '';
      _experience.text = (data['experienceYears'] ?? 0).toString();
      final langs = data['languages'];
      if (langs is List && langs.isNotEmpty) _languages.text = langs.join(', ');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      setState(() {
        _loading = false;
        _isProvider = false;
        _error = message.contains('belum menjadi provider') ? null : message.replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    final years = int.tryParse(_experience.text.trim());
    final headline = _headline.text.trim();
    if (headline.length < 5 || years == null || years < 0 || years > 60) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi headline minimal 5 karakter dan pengalaman 0–60 tahun.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await MavoApi.becomeProvider(
        headline: headline,
        experienceYears: years,
        languages: _languages.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(10).toList(),
      );
      if (!mounted) return;
      setState(() { _provider = data; _isProvider = true; _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftaran provider berhasil. Silakan login ulang untuk memperbarui sesi akun.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  String _verificationLabel(String? status) {
    switch (status) {
      case 'VERIFIED': return 'Terverifikasi';
      case 'PENDING': return 'Sedang ditinjau';
      case 'REJECTED': return 'Perlu perbaikan';
      default: return 'Belum diverifikasi';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MavoColors.background,
    appBar: AppBar(title: const Text('Provider Center', style: TextStyle(fontWeight: FontWeight.w900))),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
        ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: MavoColors.muted),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: MavoColors.muted)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
          ])))
        : ListView(padding: const EdgeInsets.all(18), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [MavoColors.midnight, MavoColors.violet]),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.storefront_rounded, color: Color(0xFFFFD77A), size: 30),
                SizedBox(height: 12),
                Text('Bangun layananmu di MAVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
                SizedBox(height: 6),
                Text('Kelola identitas provider dan siapkan layanan untuk pelanggan.', style: TextStyle(color: Colors.white70, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 18),
            if (_isProvider) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MavoColors.line)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Status provider', style: TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.verified_user_outlined, color: MavoColors.violet),
                    const SizedBox(width: 8),
                    Text(_verificationLabel(_provider?['verificationStatus']?.toString()), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Text(_provider?['headline']?.toString() ?? '', style: const TextStyle(color: MavoColors.muted)),
                  const SizedBox(height: 12),
                  Text('Layanan: ${_provider?['serviceCount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 12),
              const Text('Langkah berikutnya', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: MavoColors.midnight)),
              const SizedBox(height: 8),
              const _StepTile(number: '1', title: 'Lengkapi profil provider', detail: 'Identitas dan pengalaman sudah tersimpan.'),
              const _StepTile(number: '2', title: 'Verifikasi provider', detail: 'Menunggu alur pemeriksaan dokumen dan persetujuan admin.'),
              const _StepTile(number: '3', title: 'Kelola layanan dan jadwal', detail: 'Modul pengelolaan layanan sedang disiapkan.'),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Perbarui status')),
            ] else ...[
              const Text('Daftar sebagai provider', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: MavoColors.midnight)),
              const SizedBox(height: 6),
              const Text('Buat profil provider untuk mulai menawarkan layanan. Pendaftaran belum otomatis membuat layanan tampil di Explore.', style: TextStyle(color: MavoColors.muted, height: 1.45, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(controller: _headline, maxLength: 120, decoration: const InputDecoration(labelText: 'Headline / keahlian', hintText: 'Contoh: Fotografer dan editor video')),
              const SizedBox(height: 10),
              TextField(controller: _experience, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pengalaman (tahun)')),
              const SizedBox(height: 10),
              TextField(controller: _languages, decoration: const InputDecoration(labelText: 'Bahasa', hintText: 'Pisahkan dengan koma')),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: MavoColors.violet, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Daftar sebagai Provider'),
              ),
            ],
          ]),
  );
}

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String detail;
  const _StepTile({required this.number, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: MavoColors.line)),
      child: Row(children: [
        CircleAvatar(radius: 14, backgroundColor: MavoColors.violetSoft, child: Text(number, style: const TextStyle(color: MavoColors.violet, fontWeight: FontWeight.w800))),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: MavoColors.muted, fontSize: 11)),
        ])),
      ]),
    ),
  );
}
