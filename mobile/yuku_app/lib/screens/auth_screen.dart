import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/yuku_theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_register) {
        await MavoApi.register(_name.text, _email.text, _password.text);
      } else {
        await MavoApi.login(_email.text, _password.text);
      }
      if (mounted) widget.onAuthenticated();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MavoColors.background,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 66, height: 66, alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [MavoColors.violet, MavoColors.coral])),
                child: const Text('M', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 22),
              const Text('Selamat datang di MAVO', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: MavoColors.midnight)),
              const SizedBox(height: 7),
              Text(_register ? 'Buat akun untuk mulai berbagi cerita.' : 'Masuk untuk melihat dan membagikan Stories.',
                style: const TextStyle(color: MavoColors.muted, fontSize: 13)),
              const SizedBox(height: 28),
              if (_register) ...[
                TextField(controller: _name, textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nama tampilan', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
              ],
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 12),
              TextField(controller: _password, obscureText: _obscure, onSubmitted: (_) => _submit(),
                decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
              if (_register) ...[
                const SizedBox(height: 7),
                const Text('Password minimal 10 karakter.', style: TextStyle(color: MavoColors.muted, fontSize: 11)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: MavoColors.violet, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_register ? 'Buat Akun' : 'Masuk', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }),
                child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar')),
            ]),
          ),
        ),
      ),
    ),
  );
}
