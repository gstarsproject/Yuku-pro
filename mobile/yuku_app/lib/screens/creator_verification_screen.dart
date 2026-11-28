import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';

class CreatorVerificationScreen extends StatefulWidget {
  const CreatorVerificationScreen({super.key});
  @override
  State<CreatorVerificationScreen> createState() => _CreatorVerificationScreenState();
}

class _CreatorVerificationScreenState extends State<CreatorVerificationScreen> {
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _category = TextEditingController();
  final _reason = TextEditingController();
  Map<String, dynamic>? _request;
  final List<XFile> _documents = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _name.dispose(); _handle.dispose(); _category.dispose(); _reason.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final result = await MavoApi.creatorVerificationStatus();
      if (!mounted) return;
      setState(() { _request = result; _loading = false; _error = null; });
      if (result != null) {
        _name.text = result['creatorName']?.toString() ?? '';
        _handle.text = result['handle']?.toString() ?? '';
        _category.text = result['category']?.toString() ?? '';
        _reason.text = result['reason']?.toString() ?? '';
      }
    } catch (e) { if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); }); }
  }

  Future<void> _pickDocuments() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 2000);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        for (final file in picked) {
          if (_documents.length >= 3) break;
          if (!_documents.any((item) => item.name == file.name && item.path == file.path)) _documents.add(file);
        }
      });
      if (_documents.length >= 3 && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 3 bukti gambar.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak dapat memilih gambar: $e')));
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2 || _handle.text.trim().length < 2 || _category.text.trim().length < 2 || _reason.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua kolom. Alasan pengajuan minimal 20 karakter.'))); return;
    }
    if (_documents.isEmpty || _documents.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih 1–3 bukti gambar sebelum mengirim.'))); return;
    }
    setState(() => _submitting = true);
    try {
      final keys = <String>[];
      for (final file in _documents) {
        keys.add(await MavoApi.uploadCreatorVerificationDocument(file));
      }
      final result = await MavoApi.submitCreatorVerification(creatorName: _name.text, handle: _handle.text, category: _category.text, reason: _reason.text, documentKeys: keys);
      if (mounted) setState(() { _request = result; _submitting = false; });
    } catch (e) { if (mounted) { setState(() => _submitting = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }
  }

  String get _status => _request?['status']?.toString() ?? 'NOT_STARTED';
  @override
  Widget build(BuildContext context) {
    final pending = _status == 'PENDING';
    final verified = _status == 'VERIFIED';
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Verified', style: TextStyle(fontWeight: FontWeight.w900))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: MavoColors.violetSoft, borderRadius: BorderRadius.circular(18)), child: Row(children: [
          Icon(verified ? Icons.verified_rounded : Icons.verified_user_outlined, color: MavoColors.violet, size: 34), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(verified ? 'Creator terverifikasi' : pending ? 'Pengajuan sedang ditinjau' : _status == 'REJECTED' ? 'Pengajuan perlu diperbaiki' : 'Ajukan Creator Verified', style: const TextStyle(fontWeight: FontWeight.w900, color: MavoColors.midnight)),
            const SizedBox(height: 4), Text(verified ? 'Badge resmi aktif pada profil kamu.' : pending ? 'Tunggu hasil pemeriksaan tim MAVO.' : _status == 'REJECTED' ? (_request?['rejectionReason']?.toString() ?? 'Silakan perbaiki informasi lalu ajukan kembali.') : 'Bangun kepercayaan audiens dengan identitas kreator yang valid.', style: const TextStyle(fontSize: 12, color: MavoColors.muted)),
          ])),
        ])),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 20),
        _field(_name, 'Nama kreator'), _field(_handle, 'Username / @handle'), _field(_category, 'Kategori konten (mis. musik, travel, edukasi)'),
        _field(_reason, 'Alasan ingin diverifikasi', maxLines: 4, hint: 'Ceritakan aktivitas, audiens, dan identitas publik kreator kamu (minimal 20 karakter).'),
        const SizedBox(height: 8),
        if (!pending && !verified) ...[
          const SizedBox(height: 8),
          const Text('Bukti pendukung (wajib 1–3 gambar, JPG/PNG/WEBP, maks. 10 MB per gambar)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MavoColors.midnight)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _submitting || _documents.length >= 3 ? null : _pickDocuments, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Pilih bukti dari galeri')),
          if (_documents.isNotEmpty) Wrap(spacing: 8, runSpacing: 4, children: _documents.map((file) => InputChip(label: Text(file.name, overflow: TextOverflow.ellipsis), onDeleted: _submitting ? null : () => setState(() => _documents.remove(file)))).toList()),
          const SizedBox(height: 8),
          const Text('Gunakan screenshot akun media sosial, bukti aktivitas kreator, atau foto identitas yang relevan. Dokumen disimpan privat dan hanya dapat dibuka admin saat pemeriksaan.', style: TextStyle(fontSize: 11, color: MavoColors.muted, height: 1.4)),
          const SizedBox(height: 18),
        ],
        if (!pending && !verified) FilledButton(onPressed: _submitting ? null : _submit, style: FilledButton.styleFrom(backgroundColor: MavoColors.violet, padding: const EdgeInsets.symmetric(vertical: 14)), child: _submitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_status == 'REJECTED' ? 'Kirim ulang pengajuan' : 'Ajukan verifikasi')),
      ]),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1, String? hint}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: c, maxLines: maxLines, maxLength: maxLines == 1 ? 80 : 1000, decoration: InputDecoration(labelText: label, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)))));
}
