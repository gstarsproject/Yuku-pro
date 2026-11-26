import 'package:flutter/material.dart';
import '../theme/yuku_theme.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    _PlaceholderScreen(title: 'Explore', subtitle: 'Cari Friend, Experience, dan layanan Pro.'),
    _PlaceholderScreen(title: 'Booking', subtitle: 'Kelola permintaan dan jadwal booking.'),
    _PlaceholderScreen(title: 'Chat', subtitle: 'Percakapan dengan provider akan muncul di sini.'),
    _PlaceholderScreen(title: 'Profil', subtitle: 'Kelola akun dan pengaturan YUKU.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Booking'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PlaceholderScreen({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('YUKU')),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center),
      ]),
    )),
  );
}
