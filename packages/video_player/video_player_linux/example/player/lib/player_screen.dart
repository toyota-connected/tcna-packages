// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Cinematic player chrome for the video_player_linux example app.
//
// Layout: pure black canvas, two auto-hiding overlay bars (top + bottom),
// no Material surface containers. Gold accent (#C4A26E) marks active
// transport state and progress. Transport bar layout:
//
//   [▶/⏸] [⏪10] [10⏩]   0:32 / 9:56   ──── progress ────   🔁 CC ⚙
//
// Stream info pills (codec · channels · sample-rate) sit above the
// progress bar in tabular monospace. The settings drawer slides in from
// the right.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'library.dart';
import 'mini_controller.dart';
import 'settings_panel.dart';

const Color _kAccent = Color(0xFFC4A26E);
const Color _kCanvas = Color(0xFF000000);
const Color _kOverlay = Color(0xCC0A0A0C);
const Color _kMuted = Color(0x99FFFFFF);
const Color _kFaint = Color(0x44FFFFFF);

enum FpsWindow {
  oneSecond(Duration(seconds: 1), '1 s'),
  fiveSeconds(Duration(seconds: 5), '5 s'),
  tenSeconds(Duration(seconds: 10), '10 s');

  const FpsWindow(this.duration, this.label);
  final Duration duration;
  final String label;
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, this.item});

  final MediaItem? item;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  MiniController? _controller;
  String? _loadedUrl;
  bool _isLooping = true;
  double _volume = 1.0;
  double _volumeBeforeMute = 1.0;

  // Overlay (chrome) auto-hide.
  late final AnimationController _chromeAnim;
  Timer? _chromeTimer;
  static const _chromeTimeout = Duration(milliseconds: 3500);

  // Settings drawer.
  bool _showSettings = false;
  SettingsTab _settingsInitialTab = SettingsTab.audio;

  // Optional debug overlays (kept for keyboard shortcuts).
  bool _showTimecode = false;
  FpsWindow? _fpsWindow;
  Ticker? _fpsTicker;
  final List<int> _frameTimestamps = [];
  double _currentFps = 0;

  @override
  void initState() {
    super.initState();
    _chromeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _restartChromeTimer();
  }

  @override
  void didUpdateWidget(PlayerScreen old) {
    super.didUpdateWidget(old);
    final item = widget.item;
    if (item != null && item.url != _loadedUrl) {
      _loadVideo(item);
    }
  }

  Future<void> _loadVideo(MediaItem item) async {
    final old = _controller;
    _controller = null;
    _loadedUrl = item.url;
    if (old != null) {
      old.pause();
      await old.dispose();
    }

    final MiniController ctrl;
    if (item.source == MediaSource.asset) {
      ctrl = MiniController.asset(item.url);
    } else {
      ctrl = MiniController.network(item.url);
    }

    setState(() => _controller = ctrl);

    try {
      await ctrl.initialize();
    } catch (e) {
      debugPrint('[Player] initialize failed: $e');
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;
    setState(() {});
    // Always start a fresh track at 1.0× — defends against the previous
    // controller's rate carrying over visually if the listener fires
    // before the new player has fully attached.
    ctrl.setPlaybackSpeed(1.0);
    ctrl.play();
    _showChrome();
  }

  @override
  void dispose() {
    _stopFpsTicker();
    _chromeTimer?.cancel();
    _chromeAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ─────────────────────────── Chrome auto-hide ──────────────────────────

  void _showChrome() {
    _chromeAnim.forward();
    _restartChromeTimer();
  }

  void _hideChrome() {
    _chromeTimer?.cancel();
    if (!_showSettings) _chromeAnim.reverse();
  }

  void _restartChromeTimer() {
    _chromeTimer?.cancel();
    _chromeTimer = Timer(_chromeTimeout, _hideChrome);
  }

  void _pokeChrome() {
    if (_chromeAnim.value < 1.0) {
      _showChrome();
    } else {
      _restartChromeTimer();
    }
  }

  // ─────────────────────────── FPS / Timecode ───────────────────────────

  void _cycleFpsWindow() {
    setState(() {
      if (_fpsWindow == null) {
        _fpsWindow = FpsWindow.oneSecond;
      } else {
        final next = _fpsWindow!.index + 1;
        _fpsWindow =
            next < FpsWindow.values.length ? FpsWindow.values[next] : null;
      }
    });
    if (_fpsWindow != null) {
      _startFpsTicker();
    } else {
      _stopFpsTicker();
    }
  }

  void _startFpsTicker() {
    if (_fpsTicker != null) return;
    _frameTimestamps.clear();
    _currentFps = 0;
    _fpsTicker = createTicker(_onFpsTick)..start();
  }

  void _stopFpsTicker() {
    _fpsTicker?.stop();
    _fpsTicker?.dispose();
    _fpsTicker = null;
    _frameTimestamps.clear();
    _currentFps = 0;
  }

  void _onFpsTick(Duration elapsed) {
    final now = elapsed.inMicroseconds;
    _frameTimestamps.add(now);
    final window = _fpsWindow;
    if (window == null) return;
    final cutoff = now - window.duration.inMicroseconds;
    while (_frameTimestamps.isNotEmpty && _frameTimestamps.first < cutoff) {
      _frameTimestamps.removeAt(0);
    }
    _currentFps =
        _frameTimestamps.length / window.duration.inSeconds.toDouble();
  }

  // ─────────────────────────── Keyboard ───────────────────────────

  static const _volumeStep = 0.05;
  static const _seekStep = Duration(seconds: 10);

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return KeyEventResult.ignored;
    }
    _pokeChrome();
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      ctrl.seekTo(ctrl.value.position - _seekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      ctrl.seekTo(ctrl.value.position + _seekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() => _volume = (_volume + _volumeStep).clamp(0.0, 1.0));
      ctrl.setVolume(_volume);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _volume = (_volume - _volumeStep).clamp(0.0, 1.0));
      ctrl.setVolume(_volume);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyT) {
      setState(() => _showTimecode = !_showTimecode);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      _cycleFpsWindow();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_showSettings) {
        setState(() => _showSettings = false);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ─────────────────────────── Build ───────────────────────────

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '${d.inMinutes}:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || widget.item == null) {
      return _EmptyState();
    }

    final ctrl = _controller!;

    // The settings drawer is structurally independent of the video's
    // per-frame state (it only reads stable fields and calls setters).
    // Keeping it INSIDE the ValueListenableBuilder's subtree means it
    // got reconstructed on every 500 ms position-poll `notifyListeners`,
    // which was the visible flicker on its buttons/borders. Hoisting it
    // to a sibling of the ValueListenableBuilder in the outer Stack
    // limits its rebuilds to `setState` from this State (toggle
    // show/hide, tab change) — exactly the reactive scope it needs.
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: MouseRegion(
        onHover: (_) => _pokeChrome(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: ctrl,
              builder: (context, val, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Canvas
                    const ColoredBox(color: _kCanvas),

                    // Video / audio surface
                    Center(
                      child: val.isInitialized
                          ? (ctrl.isAudioOnly
                              ? _AudioPlayerView(
                                  controller: ctrl,
                                  item: widget.item!,
                                )
                              : AspectRatio(
                                  aspectRatio: val.aspectRatio,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => val.isPlaying
                                        ? ctrl.pause()
                                        : ctrl.play(),
                                    child: VideoPlayer(ctrl),
                                  ),
                                ))
                          : val.hasError
                              ? _ErrorDisplay(message: val.errorDescription!)
                              : const _LoadingSpinner(),
                    ),

                    // Buffering indicator (centered)
                    if (val.isInitialized && val.isBuffering)
                      const Center(child: _LoadingSpinner()),

                    // Center play indicator when paused (video only)
                    if (val.isInitialized &&
                        !val.isPlaying &&
                        !ctrl.isAudioOnly)
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(20),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      ),

                    // Debug overlays — both are video-only concepts.
                    if (_showTimecode && !ctrl.isAudioOnly)
                      _TimecodeOverlay(position: val.position),
                    if (_fpsWindow != null && !ctrl.isAudioOnly)
                      _FpsOverlay(fps: _currentFps, window: _fpsWindow!),

                    // Top bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _ChromeFader(
                        animation: _chromeAnim,
                        child: _TopBar(
                          item: widget.item!,
                          controller: ctrl,
                          fpsWindow: _fpsWindow,
                          // FPS is a video-only concept — hide for audio.
                          onCycleFps:
                              ctrl.isAudioOnly ? null : _cycleFpsWindow,
                        ),
                      ),
                    ),

                    // Bottom bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _ChromeFader(
                        animation: _chromeAnim,
                        fromTop: false,
                        child: _BottomBar(
                          controller: ctrl,
                          isLooping: _isLooping,
                          volume: _volume,
                          onPokeChrome: _pokeChrome,
                          onToggleLoop: () {
                            setState(() => _isLooping = !_isLooping);
                            ctrl.setLooping(_isLooping);
                          },
                          onToggleMute: () {
                            if (_volume > 0) {
                              _volumeBeforeMute = _volume;
                              setState(() => _volume = 0);
                            } else {
                              setState(() => _volume = _volumeBeforeMute);
                            }
                            ctrl.setVolume(_volume);
                          },
                          onVolume: (v) {
                            setState(() => _volume = v);
                            ctrl.setVolume(v);
                          },
                          onCC: ctrl.isAudioOnly
                              ? null
                              : () => setState(() {
                                    _settingsInitialTab = SettingsTab.subtitles;
                                    _showSettings = true;
                                    _showChrome();
                                  }),
                          onSettings: () => setState(() {
                            _settingsInitialTab = SettingsTab.audio;
                            _showSettings = true;
                            _showChrome();
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Settings drawer — sibling of the ValueListenableBuilder,
            // NOT a descendant. Rebuilds only when this State calls
            // setState (user toggles panel / initial tab).
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: 0,
              right: _showSettings ? 0 : -SettingsPanel.width,
              width: SettingsPanel.width,
              child: SettingsPanel(
                controller: ctrl,
                initialTab: _settingsInitialTab,
                onClose: () {
                  setState(() => _showSettings = false);
                  _restartChromeTimer();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Chrome fader ───────────────────────────

class _ChromeFader extends StatelessWidget {
  const _ChromeFader({
    required this.animation,
    required this.child,
    this.fromTop = true,
  });

  final Animation<double> animation;
  final Widget child;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        return IgnorePointer(
          ignoring: animation.value < 0.05,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, fromTop ? -0.4 : 0.4),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: c,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────── Top bar ───────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.item,
    required this.controller,
    required this.fpsWindow,
    required this.onCycleFps,
  });

  final MediaItem item;
  final MiniController controller;
  final FpsWindow? fpsWindow;
  final VoidCallback? onCycleFps;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Color(0x00000000)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      item.source == MediaSource.asset
                          ? Icons.folder_outlined
                          : Icons.cloud_outlined,
                      size: 12,
                      color: _kMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onCycleFps != null) ...[
            const SizedBox(width: 16),
            _IconButton(
              icon: Icons.speed_outlined,
              tooltip: fpsWindow == null
                  ? 'Show FPS'
                  : 'FPS avg ${fpsWindow!.label} (cycle)',
              active: fpsWindow != null,
              onTap: onCycleFps,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── Bottom bar ───────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.isLooping,
    required this.volume,
    required this.onPokeChrome,
    required this.onToggleLoop,
    required this.onToggleMute,
    required this.onVolume,
    required this.onCC,
    required this.onSettings,
  });

  final MiniController controller;
  final bool isLooping;
  final double volume;
  final VoidCallback onPokeChrome;
  final VoidCallback onToggleLoop;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onVolume;
  final VoidCallback? onCC;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final val = controller.value;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onPokeChrome(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xEE000000), Color(0x00000000)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stream info pills row
            _StreamPills(controller: controller),
            const SizedBox(height: 8),
            // Progress bar
            _CinemaProgressBar(controller: controller),
            const SizedBox(height: 8),
            // Time + right cluster + transport.
            // Transport is center-positioned in a Stack so narrow windows
            // that overflow the right cluster can't horizontally shift
            // the transport cluster frame-to-frame (visible flicker).
            SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      // Time
                      SizedBox(
                        width: 110,
                        child: Text(
                          '${_PlayerScreenState._formatDuration(val.position)}  /  ${_PlayerScreenState._formatDuration(val.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontFeatures: [FontFeature.tabularFigures()],
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Right cluster
                      _IconButton(
                        icon: Icons.replay_circle_filled_outlined,
                        tooltip: isLooping ? 'Loop on' : 'Loop off',
                        active: isLooping,
                        onTap: onToggleLoop,
                      ),
                      _IconButton(
                        icon: volume == 0
                            ? Icons.volume_off_rounded
                            : volume < 0.5
                                ? Icons.volume_down_rounded
                                : Icons.volume_up_rounded,
                        tooltip: volume == 0 ? 'Unmute' : 'Mute',
                        onTap: onToggleMute,
                      ),
                      SizedBox(
                        width: 90,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            activeTrackColor: Colors.white70,
                            inactiveTrackColor: _kFaint,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white24,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                          ),
                          child: Slider(value: volume, onChanged: onVolume),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!controller.isAudioOnly &&
                          val.duration > Duration.zero)
                        _SpeedChip(
                          speed: val.playbackSpeed,
                          onChanged: (s) => controller.setPlaybackSpeed(s),
                        ),
                      const SizedBox(width: 4),
                      _IconButton(
                        icon: Icons.closed_caption_outlined,
                        tooltip: 'Subtitles',
                        onTap: onCC,
                      ),
                      _IconButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Settings',
                        onTap: onSettings,
                      ),
                    ],
                  ),
                  // Transport cluster — absolutely centered, rendered on
                  // top of the Row so it stays put regardless of left/right
                  // cluster widths.
                  _TransportCluster(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportCluster extends StatefulWidget {
  const _TransportCluster({required this.controller});
  final MiniController controller;

  @override
  State<_TransportCluster> createState() => _TransportClusterState();
}

class _TransportClusterState extends State<_TransportCluster> {
  // _TransportCluster's appearance only depends on these two flags.
  // Subscribing to the controller directly and only calling setState
  // when THESE values change means the cluster (and its pause-button
  // BoxShadow halo) doesn't re-rasterise on every 500ms position tick.
  // The parent `ValueListenableBuilder` still rebuilds on position
  // ticks but it recreates this StatefulWidget's outer Widget instance,
  // not this State — and our `didUpdateWidget` ignores that churn.
  late bool _isInitialized = widget.controller.value.isInitialized;
  late bool _isPlaying = widget.controller.value.isPlaying;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(_TransportCluster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTick);
    super.dispose();
  }

  void _onControllerTick() {
    final v = widget.controller.value;
    if (v.isInitialized != _isInitialized || v.isPlaying != _isPlaying) {
      setState(() {
        _isInitialized = v.isInitialized;
        _isPlaying = v.isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    // `val` only used for {isInitialized, isPlaying}; the seek closures
    // read controller.value.position lazily at call time so this build
    // isn't bound to position.
    final isInitialized = _isInitialized;
    final isPlaying = _isPlaying;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconButton(
          icon: Icons.replay_10,
          tooltip: 'Back 10s',
          size: 26,
          onTap: isInitialized
              ? () => controller.seekTo(
                  controller.value.position - const Duration(seconds: 10))
              : null,
        ),
        const SizedBox(width: 8),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: isInitialized
              ? () => controller.value.isPlaying
                  ? controller.pause()
                  : controller.play()
              : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.forward_10,
          tooltip: 'Forward 10s',
          size: 26,
          onTap: isInitialized
              ? () => controller.seekTo(
                  controller.value.position + const Duration(seconds: 10))
              : null,
        ),
      ],
    );
  }
}

// ─────────────────────────── Stream info pills ───────────────────────────

class _StreamPills extends StatelessWidget {
  const _StreamPills({required this.controller});
  final MiniController controller;

  @override
  Widget build(BuildContext context) {
    final val = controller.value;
    final pills = <String>[];
    if (val.isInitialized && !controller.isAudioOnly && val.size != Size.zero) {
      pills.add('${val.size.width.toInt()}×${val.size.height.toInt()}');
    }
    if (controller.audioCodec != null && controller.audioCodec!.isNotEmpty) {
      pills.add(controller.audioCodec!);
    }
    if (controller.audioChannels != null) {
      pills.add(_channelsLabel(controller.audioChannels!));
    }
    if (controller.audioSampleRate != null) {
      pills.add(
          '${(controller.audioSampleRate! / 1000).toStringAsFixed(1)} kHz');
    }
    if (pills.isEmpty) return const SizedBox(height: 18);
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < pills.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                    Text('·', style: TextStyle(color: _kMuted, fontSize: 11)),
              ),
            Text(
              pills[i],
              style: const TextStyle(
                color: _kMuted,
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 0.6,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _channelsLabel(int n) {
    switch (n) {
      case 1:
        return 'Mono';
      case 2:
        return 'Stereo';
      case 6:
        return '5.1';
      case 8:
        return '7.1';
      default:
        return '$n ch';
    }
  }
}

// ─────────────────────────── Progress bar ───────────────────────────

class _CinemaProgressBar extends StatefulWidget {
  const _CinemaProgressBar({required this.controller});
  final MiniController controller;
  @override
  State<_CinemaProgressBar> createState() => _CinemaProgressBarState();
}

class _CinemaProgressBarState extends State<_CinemaProgressBar> {
  bool _dragging = false;
  double _dragValue = 0;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final val = widget.controller.value;
    if (!val.isInitialized) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: _kFaint,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    final duration = val.duration.inMilliseconds.toDouble();
    final position = val.position.inMilliseconds.toDouble();
    double maxBuffered = 0;
    for (final r in val.buffered) {
      final e = r.end.inMilliseconds.toDouble();
      if (e > maxBuffered) maxBuffered = e;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: _hovering || _dragging ? 6 : 4,
          activeTrackColor: _kAccent,
          inactiveTrackColor: _kFaint,
          secondaryActiveTrackColor: Colors.white24,
          thumbColor: _kAccent,
          overlayColor: _kAccent.withValues(alpha: 0.25),
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: _hovering || _dragging ? 8 : 0,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          trackShape: const RoundedRectSliderTrackShape(),
        ),
        child: Slider(
          value: _dragging
              ? _dragValue
              : (duration > 0 ? position.clamp(0, duration) : 0),
          secondaryTrackValue:
              duration > 0 ? maxBuffered.clamp(0, duration) : 0,
          min: 0,
          max: duration > 0 ? duration : 1,
          onChangeStart: (v) => setState(() {
            _dragging = true;
            _dragValue = v;
          }),
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            widget.controller.seekTo(Duration(milliseconds: v.toInt()));
            setState(() => _dragging = false);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────── Speed chip ───────────────────────────

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.speed, this.onChanged});
  final double speed;
  final ValueChanged<double>? onChanged;
  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: speed,
      tooltip: 'Playback speed',
      color: _kOverlay,
      onSelected: onChanged,
      enabled: onChanged != null,
      itemBuilder: (_) => [
        for (final s in _speeds)
          PopupMenuItem(
            value: s,
            child: Text(
              '${s}x',
              style: TextStyle(
                color: s == speed ? _kAccent : Colors.white,
                fontWeight: s == speed ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kFaint),
        ),
        child: Text(
          '${speed}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Icon button ───────────────────────────

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.onTap,
    this.size = 22,
  });
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? _kFaint
        : active
            ? _kAccent
            : Colors.white;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}

// ─────────────────────────── Audio-only view ───────────────────────────

class _AudioPlayerView extends StatelessWidget {
  const _AudioPlayerView({required this.controller, required this.item});

  final MiniController controller;
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final art = controller.albumArt;
        final title = controller.title ?? item.name;
        return Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: 0.18),
                      blurRadius: 60,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 50,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: art != null
                      ? Image.memory(art,
                          fit: BoxFit.cover, gaplessPlayback: true)
                      : _GeneratedArt(
                          title: title,
                          artist: controller.artist,
                        ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              if (controller.artist != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.artist!,
                  style: const TextStyle(color: _kAccent, fontSize: 14),
                ),
              ],
              if (controller.album != null) ...[
                const SizedBox(height: 4),
                Text(
                  controller.album!,
                  style: const TextStyle(color: _kMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GeneratedArt extends StatelessWidget {
  const _GeneratedArt({required this.title, this.artist});
  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final hash = (title + (artist ?? '')).hashCode;
    final hue = (hash % 360).abs().toDouble();
    final c1 = HSLColor.fromAHSL(1, hue, 0.3, 0.15).toColor();
    final c2 = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.4, 0.25).toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 96,
          color: HSLColor.fromAHSL(0.35, hue, 0.5, 0.6).toColor(),
        ),
      ),
    );
  }
}

// ─────────────────────────── Empty / loading / error ───────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCanvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_outlined, size: 80, color: _kFaint),
            const SizedBox(height: 16),
            const Text(
              'Select something to play',
              style:
                  TextStyle(color: _kMuted, fontSize: 14, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSpinner extends StatelessWidget {
  const _LoadingSpinner();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(_kAccent),
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  const _ErrorDisplay({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFE57373), size: 56),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(color: Color(0xFFE57373), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────── Debug overlays ───────────────────────────

class _TimecodeOverlay extends StatelessWidget {
  const _TimecodeOverlay({required this.position});
  final Duration position;

  String _toSmpte(Duration d) {
    final total = d.inMilliseconds;
    final h = (total ~/ 3600000).toString().padLeft(2, '0');
    final m = ((total ~/ 60000) % 60).toString().padLeft(2, '0');
    final s = ((total ~/ 1000) % 60).toString().padLeft(2, '0');
    final f = ((total % 1000) * 30 ~/ 1000).toString().padLeft(2, '0');
    return '$h:$m:$s:$f';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: 80,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kOverlay,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kFaint),
          ),
          child: Text(
            _toSmpte(position),
            style: const TextStyle(
              color: _kAccent,
              fontSize: 13,
              fontFamily: 'monospace',
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _FpsOverlay extends StatelessWidget {
  const _FpsOverlay({required this.fps, required this.window});
  final double fps;
  final FpsWindow window;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: 120,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kOverlay,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kFaint),
          ),
          child: Text(
            '${fps.toStringAsFixed(1)} FPS · ${window.label}',
            style: const TextStyle(
              color: _kAccent,
              fontSize: 11,
              fontFamily: 'monospace',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
