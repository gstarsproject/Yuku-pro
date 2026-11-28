import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';

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

  void _showPasswordResetInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa password?'),
        content: const Text(
          'Fitur reset password belum tersedia. Pengiriman kode verifikasi email akan diaktifkan setelah domain email resmi MAVO tersedia.',
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = _register
          ? await MAVOApi.register(
              email: _email.text.trim(),
              password: _password.text,
              displayName: _name.text.trim(),
            )
          : await MAVOApi.login(
              email: _email.text.trim(),
              password: _password.text,
            );
      if (mounted) widget.onAuthenticated(user);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _register;
    return Scaffold(
      backgroundColor: MavoColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: MavoColors.violet,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      isRegister ? 'Buat akun MAVO' : 'Selamat datang kembali',
                      style: const TextStyle(
                        color: MavoColors.midnight,
                        fontSize: 29,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isRegister
                          ? 'Satu akun untuk terhubung, berbagi, dan menemukan hal baru.'
                          : 'Masuk dan lanjutkan ceritamu bersama komunitas MAVO.',
                      style: const TextStyle(
                        color: MavoColors.muted,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (isRegister) ...[
                      _fieldLabel('Nama lengkap'),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: _decoration(
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) =>
                            (value == null || value.trim().length < 2)
                                ? 'Nama minimal 2 karakter'
                                : null,
                      ),
                      const SizedBox(height: 18),
                    ],
                    _fieldLabel('Email'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: _decoration(
                        hint: 'nama@email.com',
                        icon: Icons.mail_outline_rounded,
                      ),
                      validator: (value) =>
                          (value == null ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(value.trim()))
                              ? 'Masukkan alamat email yang valid'
                              : null,
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('Password'),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: isRegister
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: _decoration(
                        hint: isRegister
                            ? 'Minimal 10 karakter'
                            : 'Masukkan password',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: MavoColors.muted,
                            size: 21,
                          ),
                        ),
                      ),
                      validator: (value) => isRegister
                          ? ((value == null || value.length < 10)
                              ? 'Password minimal 10 karakter'
                              : null)
                          : ((value == null || value.isEmpty)
                              ? 'Masukkan password'
                              : null),
                    ),
                    if (!isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _showPasswordResetInfo,
                          child: const Text('Lupa password?'),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(top: 9),
                        child: Text(
                          'Gunakan minimal 10 karakter untuk menjaga keamanan akun.',
                          style: TextStyle(
                            color: MavoColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: MavoColors.violet,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: MavoColors.violet.withValues(alpha: 0.55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          elevation: 0,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isRegister ? 'Daftar sekarang' : 'Masuk',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isRegister
                              ? 'Sudah punya akun?'
                              : 'Belum punya akun?',
                          style: const TextStyle(
                            color: MavoColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _register = !_register;
                                    _error = null;
                                  }),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                          ),
                          child: Text(
                            isRegister ? 'Masuk' : 'Daftar',
                            style: const TextStyle(
                              color: MavoColors.violet,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),
                    const Text(
                      'MAVO  •  CONNECT. SHARE. EXPLORE.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MavoColors.muted,
                        letterSpacing: 1.1,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: MavoColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: MavoColors.muted, size: 21),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
        hintStyle: const TextStyle(
          color: Color(0xFF9AA6B5),
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: MavoColors.violet,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD92D20),
            width: 1.5,
          ),
        ),
      );
}
