import 'package:flutter/material.dart';

import 'library.dart';
import 'player_screen.dart';

void main() {
  runApp(const PlayerApp());
}

class PlayerApp extends StatelessWidget {
  const PlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  MediaItem? _nowPlaying;

  void _playItem(MediaItem item) {
    setState(() {
      _nowPlaying = item;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.play_circle_filled,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.video_library_outlined),
                selectedIcon: Icon(Icons.video_library),
                label: Text('Library'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.play_circle_outline),
                selectedIcon: Icon(Icons.play_circle),
                label: Text('Player'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                LibraryScreen(onPlay: _playItem),
                PlayerScreen(item: _nowPlaying),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
