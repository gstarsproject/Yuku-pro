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
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isProvider = false;

  @override
  void initState() { super.initState(); _load(); }

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
      final results = await Future.wait([MavoApi.providerServices(), MavoApi.categories()]);
      if (!mounted) return;
      setState(() {
        _provider = data;
        _services = results[0];
        _categories = results[1];
        _isProvider = true;
        _loading = false;
      });
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
      await MavoApi.becomeProvider(
        headline: headline,
        experienceYears: years,
        languages: _languages.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(10).toList(),
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftaran provider berhasil. Profil provider sudah aktif.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _createService() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori belum tersedia. Coba lagi nanti.')));
      return;
    }
    final title = TextEditingController();
    final description = TextEditingController();
    final price = TextEditingController();
    final duration = TextEditingController();
    final city = TextEditingController();
    final province = TextEditingController();
    String categoryId = _categories.first['id'].toString();
    String mode = 'BOTH';
    String unit = 'SESSION';
    bool submitting = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Tambah layanan'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, maxLength: 100, decoration: const InputDecoration(labelText: 'Nama layanan')),
            const SizedBox(height: 8),
            TextField(controller: description, maxLines: 3, maxLength: 5000, decoration: const InputDecoration(labelText: 'Deskripsi layanan')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: categoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) { if (v != null) setDialogState(() => categoryId = v); },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: mode,
              decoration: const InputDecoration(labelText: 'Mode layanan'),
              items: const [
                DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                DropdownMenuItem(value: 'OFFLINE', child: Text('Offline')),
                DropdownMenuItem(value: 'BOTH', child: Text('Online & Offline')),
              ],
              onChanged: (v) { if (v != null) setDialogState(() => mode = v); },
            ),
            const SizedBox(height: 8),
            TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (Rp)', hintText: 'Contoh: 150000')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: unit,
              decoration: const InputDecoration(labelText: 'Satuan harga'),
              items: const [
                DropdownMenuItem(value: 'HOUR', child: Text('Per jam')),
                DropdownMenuItem(value: 'SESSION', child: Text('Per sesi')),
                DropdownMenuItem(value: 'DAY', child: Text('Per hari')),
                DropdownMenuItem(value: 'FIXED', child: Text('Harga tetap')),
              ],
              onChanged: (v) { if (v != null) setDialogState(() => unit = v); },
            ),
            const SizedBox(height: 8),
            TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Durasi menit (opsional)')),
            const SizedBox(height: 8),
            TextField(controller: city, decoration: const InputDecoration(labelText: 'Kota (opsional)')),
            const SizedBox(height: 8),
            TextField(controller: province, decoration: const InputDecoration(labelText: 'Provinsi (opsional)')),
            const SizedBox(height: 6),
            const Text('Layanan disimpan sebagai draft. Publikasi membutuhkan verifikasi provider dan aturan komisi kategori yang aktif.', style: TextStyle(fontSize: 11, color: MavoColors.muted)),
          ])),
        ),
        actions: [
          TextButton(onPressed: submitting ? null : () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(
            onPressed: submitting ? null : () async {
              final amount = int.tryParse(price.text.trim());
              final mins = duration.text.trim().isEmpty ? null : int.tryParse(duration.text.trim());
              if (title.text.trim().length < 5 || description.text.trim().length < 20 || amount == null || amount < 1000 || (duration.text.trim().isNotEmpty && (mins == null || mins < 15 || mins > 1440))) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Periksa nama, deskripsi (min. 20 karakter), harga dan durasi.')));
                return;
              }
              setDialogState(() => submitting = true);
              try {
                await MavoApi.createProviderService(
                  categoryId: categoryId,
                  title: title.text,
                  description: description.text,
                  mode: mode,
                  priceAmount: amount,
                  priceUnit: unit,
                  durationMinutes: mins,
                  city: city.text,
                  province: province.text,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (e) {
                setDialogState(() => submitting = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
              }
            },
            child: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan draft'),
          ),
        ],
      )),
    );
    title.dispose(); description.dispose(); price.dispose(); duration.dispose(); city.dispose(); province.dispose();
    if (saved == true && mounted) {
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft layanan berhasil disimpan.')));
    }
  }

  Future<void> _togglePublish(Map<String, dynamic> service, bool value) async {
    try {
      await MavoApi.setProviderServicePublished(service['id'].toString(), value);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
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

  String _price(Map<String, dynamic> item) {
    final amount = int.tryParse(item['priceAmount']?.toString() ?? '') ?? 0;
    final formatted = amount.toString().replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (m) => '.');
    return 'Rp $formatted / ${item['priceUnit'] ?? 'SESSION'}';
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
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [MavoColors.midnight, MavoColors.violet])),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.storefront_rounded, color: Color(0xFFFFD77A), size: 30),
                SizedBox(height: 12),
                Text('Bangun layananmu di MAVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
                SizedBox(height: 6),
                Text('Kelola identitas provider, layanan, dan kesiapan menerima pesanan.', style: TextStyle(color: Colors.white70, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 18),
            if (_isProvider) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEAE8F2))),
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
                  Text('Total layanan: ${_services.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [
                const Expanded(child: Text('Layanan saya', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: MavoColors.midnight))),
                FilledButton.icon(onPressed: _createService, icon: const Icon(Icons.add, size: 18), label: const Text('Tambah')),
              ]),
              const SizedBox(height: 10),
              if (_services.isEmpty)
                Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Text('Belum ada layanan. Tambahkan layanan pertama sebagai draft.', style: TextStyle(color: MavoColors.muted)))
              else
                ..._services.map((service) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEAE8F2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(service['title']?.toString() ?? 'Layanan', style: const TextStyle(fontWeight: FontWeight.w800, color: MavoColors.midnight))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: service['isPublished'] == true ? const Color(0xFFE7F7EE) : MavoColors.violetSoft, borderRadius: BorderRadius.circular(20)), child: Text(service['isPublished'] == true ? 'Tayang' : 'Draft', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: service['isPublished'] == true ? const Color(0xFF218653) : MavoColors.violet))),
                    ]),
                    const SizedBox(height: 6),
                    Text('${service['categoryName'] ?? 'Kategori'} • ${_price(service)}', style: const TextStyle(color: MavoColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    if (_provider?['verificationStatus'] != 'VERIFIED')
                      const Text('Publikasi terkunci sampai provider terverifikasi.', style: TextStyle(color: MavoColors.muted, fontSize: 11))
                    else
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _togglePublish(service, service['isPublished'] != true), child: Text(service['isPublished'] == true ? 'Jadikan draft' : 'Publikasikan'))),
                  ]),
                )),
              const SizedBox(height: 10),
              const _StepTile(number: '1', title: 'Profil provider', detail: 'Identitas dan pengalaman tersimpan.'),
              const _StepTile(number: '2', title: 'Verifikasi provider', detail: 'Layanan hanya bisa tayang setelah pemeriksaan admin dan aturan komisi aktif.'),
              const _StepTile(number: '3', title: 'Booking dan jadwal', detail: 'Alur pengelolaan jadwal dan tindakan provider akan dilanjutkan.'),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Perbarui status')),
            ] else ...[
              const Text('Daftar sebagai provider', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: MavoColors.midnight)),
              const SizedBox(height: 6),
              const Text('Buat profil provider untuk mulai menawarkan layanan. Layanan yang dibuat akan tersimpan sebagai draft sampai verifikasi selesai.', style: TextStyle(color: MavoColors.muted, height: 1.45, fontSize: 12)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFEAE8F2))),
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
