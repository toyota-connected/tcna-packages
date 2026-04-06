import 'dart:async';

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
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC4A26E),
          brightness: Brightness.dark,
          primary: const Color(0xFFC4A26E),
          surface: const Color(0xFF0A0A0C),
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  MediaItem? _nowPlaying;

  late final AnimationController _paneAnim;
  Timer? _paneTimer;
  static const _paneTimeout = Duration(seconds: 10);

  // Pointer activity tracking for the library button
  bool _pointerActive = false;
  Timer? _activityTimer;
  static const _activityTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _paneAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // start revealed
    );
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    _paneTimer?.cancel();
    _paneAnim.dispose();
    super.dispose();
  }

  void _onPointerActivity() {
    if (!_pointerActive) {
      setState(() => _pointerActive = true);
    }
    _activityTimer?.cancel();
    _activityTimer = Timer(_activityTimeout, () {
      if (mounted) setState(() => _pointerActive = false);
    });
  }

  void _showPane() {
    _paneAnim.forward();
    // Only auto-hide after a video has been played at least once.
    if (_nowPlaying != null) {
      _restartPaneTimer();
    }
  }

  void _hidePane() {
    _paneTimer?.cancel();
    _paneAnim.reverse();
  }

  void _restartPaneTimer() {
    _paneTimer?.cancel();
    _paneTimer = Timer(_paneTimeout, _hidePane);
  }

  void _pokePane() {
    if (_paneAnim.value < 1.0) {
      _showPane();
    } else {
      _restartPaneTimer();
    }
  }

  void _playItem(MediaItem item) {
    setState(() => _nowPlaying = item);
    _hidePane();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onPointerActivity(),
        onPointerMove: (_) => _onPointerActivity(),
        onPointerHover: (_) => _onPointerActivity(),
        child: Stack(
          children: [
            // Player — always fills the entire area
            Positioned.fill(
              child: PlayerScreen(item: _nowPlaying),
            ),

            // Left pane — slides in from the left, retracts fully
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _LeftPaneTray(
                animation: _paneAnim,
                onInteraction: _pokePane,
                child: _LeftPaneContent(
                  onPlay: _playItem,
                  onInteraction: _pokePane,
                ),
              ),
            ),

            // Left-edge swipe zone to open library pane
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  if (details.primaryDelta != null &&
                      details.primaryDelta! > 2) {
                    _showPane();
                  }
                },
              ),
            ),

            // Library button — transparent, lights up on hover/touch
            Positioned(
              left: 8,
              top: 8,
              child: AnimatedBuilder(
                animation: _paneAnim,
                builder: (context, child) {
                  // Hide button when pane is fully open
                  return Opacity(
                    opacity: 1.0 - _paneAnim.value,
                    child: IgnorePointer(
                      ignoring: _paneAnim.value > 0.5,
                      child: child,
                    ),
                  );
                },
                child: _LibraryToggleButton(
                  onPressed: _showPane,
                  visible: _pointerActive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sliding tray that holds the left pane content, retracting fully to
/// the left.
class _LeftPaneTray extends StatelessWidget {
  const _LeftPaneTray({
    required this.animation,
    required this.onInteraction,
    required this.child,
  });

  final AnimationController animation;
  final VoidCallback onInteraction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ClipRect(
          child: Align(
            alignment: Alignment.centerRight,
            widthFactor: animation.value,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => onInteraction(),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Transparent button that lights up on mouse hover or touch.
/// Fades to invisible after pointer inactivity.
class _LibraryToggleButton extends StatefulWidget {
  const _LibraryToggleButton({
    required this.onPressed,
    required this.visible,
  });

  final VoidCallback onPressed;
  final bool visible;

  @override
  State<_LibraryToggleButton> createState() => _LibraryToggleButtonState();
}

class _LibraryToggleButtonState extends State<_LibraryToggleButton> {
  bool _hovering = false;
  bool _pressing = false;

  double get _bgOpacity {
    if (_pressing) return 0.5;
    if (_hovering) return 0.3;
    return 0.0;
  }

  double get _iconOpacity {
    if (!widget.visible) return 0.0;
    if (_hovering || _pressing) return 0.9;
    return 0.4;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) {
          setState(() => _pressing = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressing = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: _bgOpacity),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedOpacity(
            opacity: _iconOpacity,
            duration: const Duration(milliseconds: 500),
            child: const Icon(
              Icons.video_library,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Library content that lives inside the left pane tray.
class _LeftPaneContent extends StatelessWidget {
  const _LeftPaneContent({
    required this.onPlay,
    required this.onInteraction,
  });

  final void Function(MediaItem item) onPlay;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0C),
        border: Border(
          right: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
      ),
      child: LibraryScreen(onPlay: onPlay),
    );
  }
}
