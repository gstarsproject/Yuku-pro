import 'package:flutter/material.dart';
import '../services/MAVO_api.dart';
import 'app_shell.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  Map<String, dynamic>? _user;
  @override
  void initState() { super.initState(); _restore(); }
  Future<void> _restore() async {
    try { _user = await MAVOApi.currentUser(); } catch (_) { _user = null; }
    if (mounted) setState(() => _checking = false);
  }
  void _authenticated(Map<String, dynamic> user) => setState(() => _user = user);
  Future<void> _logout() async {
    await MAVOApi.logout();
    if (mounted) setState(() => _user = null);
  }
  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return AuthScreen(onAuthenticated: _authenticated);
    return AppShell(onLogout: _logout, user: _user);
  }
}
