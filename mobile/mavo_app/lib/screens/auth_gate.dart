import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';
import 'app_shell.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  String? _restoreError;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    if (mounted) {
      setState(() {
        _checking = true;
        _restoreError = null;
      });
    }
    try {
      final user = await MAVOApi.currentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _checking = false;
        _restoreError = null;
      });
    } catch (_) {
      // A network/server error is not proof that the saved session is invalid.
      // Keep the secure token and let the user retry instead of forcing logout.
      if (!mounted) return;
      setState(() {
        _checking = false;
        _restoreError = 'Koneksi belum tersedia. Periksa internet lalu coba lagi.';
      });
    }
  }

  void _authenticated(Map<String, dynamic> user) {
    setState(() {
      _user = user;
      _restoreError = null;
    });
  }

  Future<void> _logout() async {
    await MAVOApi.logout();
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: MavoColors.background,
        body: Center(
          child: CircularProgressIndicator(color: MavoColors.violet),
        ),
      );
    }

    if (_restoreError != null) {
      return Scaffold(
        backgroundColor: MavoColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: MavoColors.violetSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: MavoColors.violet,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Belum bisa terhubung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MavoColors.midnight,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _restoreError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MavoColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _restore,
                        child: const Text('Coba lagi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_user == null) {
      return AuthScreen(onAuthenticated: _authenticated);
    }

    return AppShell(onLogout: _logout, user: _user);
  }
}
