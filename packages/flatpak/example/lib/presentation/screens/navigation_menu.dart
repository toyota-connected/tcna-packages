import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide NavigationBar;
import 'package:go_router/go_router.dart';

import '../widgets/navigation_bar.dart';

class NavigationShell extends StatefulWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<NavigationItem> _navItems = const [
    NavigationItem(icon: Icons.home_rounded, label: 'Home'),
    NavigationItem(icon: Icons.explore_rounded, label: 'Discover'),
    NavigationItem(icon: Icons.grid_view_rounded, label: 'Installed'),
    NavigationItem(icon: Icons.search_rounded, label: 'Search'),
    NavigationItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  final List<String> _routes = [
    '/home',
    '/discover',
    '/installed',
    '/search',
    '/settings',
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final newIndex = _routes.indexOf(location);
    if (newIndex != -1 && newIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = newIndex;
        });
      });
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 104),
            child: widget.child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTap,
              items: _navItems,
            ),
          ),
        ],
      ),
    );
  }
}