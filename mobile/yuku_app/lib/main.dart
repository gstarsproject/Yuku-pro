import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'theme/yuku_theme.dart';
import 'services/yuku_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await YukuApi.initialize();
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
