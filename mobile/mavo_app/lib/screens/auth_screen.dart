import 'package:flutter/material.dart';
import '../services/MAVO_api.dart';
import '../theme/MAVO_theme.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String? _error;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  void _showPasswordResetInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa Password?'),
        content: const Text(
          'Fitur reset password sedang disiapkan. Pengiriman kode verifikasi email akan diaktifkan setelah domain email resmi MAVO tersedia. Akun dan password kamu tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final user = _register
        ? await MAVOApi.register(email: _email.text, password: _password.text, displayName: _name.text)
        : await MAVOApi.login(email: _email.text, password: _password.text);
      if (mounted) widget.onAuthenticated(user);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  width: 74, height: 74, alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [MavoColors.midnight, MavoColors.violet])),
                  child: const Text('M', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 24),
                Text(_register ? 'Bergabung dengan MAVO' : 'Selamat datang kembali',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: MavoColors.midnight)),
                const SizedBox(height: 8),
                Text(_register ? 'Buat akun untuk mulai terhubung, berbagi, dan menjelajah.' : 'Masuk untuk melanjutkan perjalananmu di MAVO.',
                  style: const TextStyle(color: MavoColors.muted, height: 1.5)),
                const SizedBox(height: 28),
                if (_register) ...[
                  TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Nama minimal 2 karakter' : null),
                  const SizedBox(height: 14),
                ],
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => (v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) ? 'Masukkan email yang valid' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _password, obscureText: _obscure,
                  decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
                  validator: (v) => _register
                    ? ((v == null || v.length < 10) ? 'Password minimal 10 karakter' : null)
                    : ((v == null || v.isEmpty) ? 'Masukkan password' : null)),
                if (!_register)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _showPasswordResetInfo,
                      child: const Text('Lupa password?'),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 22),
                SizedBox(height: 52, child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_register ? 'Buat Akun' : 'Masuk', style: const TextStyle(fontWeight: FontWeight.w800)),
                )),
                const SizedBox(height: 16),
                TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }),
                  child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar sekarang')),
                const SizedBox(height: 28),
                const Text('CONNECT. SHARE. EXPLORE.', textAlign: TextAlign.center,
                  style: TextStyle(letterSpacing: 2, fontSize: 10, color: MavoColors.muted, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}
