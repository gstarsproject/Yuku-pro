import 'package:flutter/material.dart';
import 'screens/auth_gate.dart';
import 'theme/mavo_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MAVOApp());
}

class MAVOApp extends StatelessWidget {
  const MAVOApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MAVO',
    debugShowCheckedModeBanner: false,
    theme: MAVOTheme.light,
    home: const AuthGate(),
  );
}
