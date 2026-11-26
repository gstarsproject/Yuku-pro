import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'theme/yuku_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YukuApp());
}

class YukuApp extends StatelessWidget {
  const YukuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAVO',
      debugShowCheckedModeBanner: false,
      theme: YukuTheme.light,
      home: const AppShell(),
    );
  }
}
