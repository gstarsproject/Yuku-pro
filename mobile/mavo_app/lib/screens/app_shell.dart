import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'inbox_screen.dart';

class AppShell extends StatefulWidget {
  final Future<void> Function()? onLogout;
  final Map<String, dynamic>? user;
  const AppShell({super.key, this.onLogout, this.user});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  String _explorePillar = '';
  int _homeRefreshKey = 0;

  void _handlePostPublished() {
    setState(() {
      _homeRefreshKey++;
      index = 0;
    });
  }

  List<Widget> get pages => [
    HomeScreen(
      key: ValueKey(_homeRefreshKey),
      user: widget.user,
      onOpenProfile: () => setState(() => index = 4),
      onOpenExplore: (pillar) => setState(() {
        _explorePillar = pillar;
        index = 1;
      }),
    ),
    ExploreScreen(initialPillar: _explorePillar),
    CreatePostScreen(onPublished: _handlePostPublished),
    const InboxScreen(),
    ProfileScreen(onLogout: widget.onLogout, user: widget.user),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Explore'),
        NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: 'Create'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Inbox'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    ),
  );
}
