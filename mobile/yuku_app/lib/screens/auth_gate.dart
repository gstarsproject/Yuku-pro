import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import 'app_shell.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<bool>? _session;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _session = _check();
  }

  Future<bool> _check() async {
    final token = await MavoApi.token();
    if (token == null || token.isEmpty) return false;
    try {
      await MavoApi.me();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _signedIn() => setState(() { _authenticated = true; });

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return const AppShell();
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: TextButton(onPressed: () => setState(() => _session = _check()), child: const Text('Coba lagi'))));
        }
        if (snapshot.data == true) return const AppShell();
        return AuthScreen(onAuthenticated: _signedIn);
      },
    );
  }
}
