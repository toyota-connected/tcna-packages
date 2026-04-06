import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'library.dart';
import 'mini_controller.dart';
import 'settings_panel.dart';

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
  bool _showTrackInfo = false;
  bool _showTimecode = false;
  bool _showSettings = false;
  SettingsTab _settingsInitialTab = SettingsTab.audio;
  double _volume = 1.0;
  double _volumeBeforeMute = 1.0;

  late final AnimationController _trayAnim;
  Timer? _trayTimer;
  static const _trayTimeout = Duration(seconds: 5);

  // FPS measurement
  FpsWindow? _fpsWindow;
  Ticker? _fpsTicker;
  final List<int> _frameTimestamps = []; // elapsed microseconds
  double _currentFps = 0;

  @override
  void initState() {
    super.initState();
    _trayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // start revealed
    );
  }

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
    // Remove timestamps older than the window
    while (_frameTimestamps.isNotEmpty && _frameTimestamps.first < cutoff) {
      _frameTimestamps.removeAt(0);
    }
    _currentFps =
        _frameTimestamps.length / window.duration.inSeconds.toDouble();
  }

  // Keyboard controls
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
    if (key == LogicalKeyboardKey.keyI) {
      setState(() => _showTrackInfo = !_showTrackInfo);
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
    return KeyEventResult.ignored;
  }

  void _showTray() {
    _trayAnim.forward();
    _restartTrayTimer();
  }

  void _hideTray() {
    _trayTimer?.cancel();
    _trayAnim.reverse();
  }

  void _restartTrayTimer() {
    _trayTimer?.cancel();
    _trayTimer = Timer(_trayTimeout, _hideTray);
  }

  /// Call from any control interaction to keep the tray visible.
  void _pokeTray() {
    if (_trayAnim.value < 1.0) {
      _showTray();
    } else {
      _restartTrayTimer();
    }
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
    ctrl.play();
    _showTray();
  }

  @override
  void dispose() {
    _stopFpsTicker();
    _trayTimer?.cancel();
    _trayAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || widget.item == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline,
                size: 80,
                color: Theme.of(context).colorScheme.surfaceContainerHighest),
            const SizedBox(height: 16),
            Text(
              'Select a video from the Library',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final ctrl = _controller!;
    final cs = Theme.of(context).colorScheme;

    // ValueListenableBuilder rebuilds only the video-value-dependent
    // subtree on each 500ms position poll, avoiding a full
    // _PlayerScreenState rebuild.
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: ctrl,
        builder: (context, val, _) {
          return Stack(
            children: [
              // Video area — fills entire space
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: val.isInitialized
                        ? ctrl.isAudioOnly
                            ? _AudioPlayerView(
                                controller: ctrl,
                                item: widget.item!,
                              )
                            : AspectRatio(
                            aspectRatio: val.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(ctrl),
                                // Play/pause overlay
                                _PlayPauseOverlay(controller: ctrl),
                                // Buffering indicator
                                if (val.isBuffering)
                                  const CircularProgressIndicator(
                                    color: Colors.white70,
                                  ),
                                // Track info overlay
                                if (_showTrackInfo)
                                  _TrackInfoOverlay(
                                    item: widget.item!,
                                    value: val,
                                    looping: _isLooping,
                                  ),
                                // SMPTE timecode overlay
                                if (_showTimecode)
                                  _TimecodeOverlay(position: val.position),
                                // FPS overlay
                                if (_fpsWindow != null)
                                  _FpsOverlay(
                                    fps: _currentFps,
                                    window: _fpsWindow!,
                                  ),
                              ],
                            ),
                          )
                        : val.hasError
                            ? _ErrorDisplay(message: val.errorDescription!)
                            : const CircularProgressIndicator(),
                  ),
                ),
              ),

              // Settings panel — right slide-out drawer
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                right: _showSettings ? 0 : -SettingsPanel.width,
                width: SettingsPanel.width,
                child: SettingsPanel(
                  controller: ctrl,
                  initialTab: _settingsInitialTab,
                  onClose: () => setState(() => _showSettings = false),
                ),
              ),

              // Transport tray — slides up from bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TransportTray(
                  animation: _trayAnim,
                  onGripTap: _showTray,
                  onInteraction: _pokeTray,
                  grip: _TrayGrip(cs: cs),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      border: Border(
                        top: BorderSide(color: cs.outlineVariant, width: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        _ProgressBar(controller: ctrl),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              // Time display
                              Text(
                                '${_formatDuration(val.position)} / ${_formatDuration(val.duration)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  fontFeatures: [
                                    const FontFeature.tabularFigures()
                                  ],
                                ),
                              ),

                              const SizedBox(width: 24),

                              // Playback controls
                              IconButton(
                                icon: const Icon(Icons.replay_10),
                                tooltip: 'Rewind 10s',
                                onPressed: val.isInitialized
                                    ? () => ctrl.seekTo(val.position -
                                        const Duration(seconds: 10))
                                    : null,
                              ),
                              IconButton.filled(
                                icon: Icon(
                                  val.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 32,
                                ),
                                tooltip: val.isPlaying ? 'Pause' : 'Play',
                                onPressed: val.isInitialized
                                    ? () => val.isPlaying
                                        ? ctrl.pause()
                                        : ctrl.play()
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10),
                                tooltip: 'Forward 10s',
                                onPressed: val.isInitialized
                                    ? () => ctrl.seekTo(val.position +
                                        const Duration(seconds: 10))
                                    : null,
                              ),

                              const SizedBox(width: 16),

                              // Loop toggle
                              IconButton(
                                icon: Icon(
                                  Icons.loop,
                                  color: _isLooping ? cs.primary : null,
                                ),
                                tooltip:
                                    _isLooping ? 'Looping on' : 'Looping off',
                                onPressed: val.isInitialized
                                    ? () {
                                        setState(
                                            () => _isLooping = !_isLooping);
                                        ctrl.setLooping(_isLooping);
                                      }
                                    : null,
                              ),

                              // Track info overlay toggle
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline,
                                  color: _showTrackInfo ? cs.primary : null,
                                ),
                                tooltip: _showTrackInfo
                                    ? 'Hide track info'
                                    : 'Show track info',
                                onPressed: val.isInitialized
                                    ? () => setState(
                                        () => _showTrackInfo = !_showTrackInfo)
                                    : null,
                              ),

                              // SMPTE timecode toggle
                              IconButton(
                                icon: Icon(
                                  Icons.timer_outlined,
                                  color: _showTimecode ? cs.primary : null,
                                ),
                                tooltip: _showTimecode
                                    ? 'Hide timecode'
                                    : 'Show timecode',
                                onPressed: val.isInitialized
                                    ? () => setState(
                                        () => _showTimecode = !_showTimecode)
                                    : null,
                              ),

                              // FPS counter cycle
                              _FpsButton(
                                window: _fpsWindow,
                                cs: cs,
                                onPressed:
                                    val.isInitialized ? _cycleFpsWindow : null,
                              ),

                              // CC (subtitles) — opens settings on subs tab
                              IconButton(
                                icon: const Icon(Icons.closed_caption_outlined),
                                tooltip: 'Subtitles',
                                onPressed: val.isInitialized && !ctrl.isAudioOnly
                                    ? () => setState(() {
                                          _settingsInitialTab =
                                              SettingsTab.subtitles;
                                          _showSettings = true;
                                        })
                                    : null,
                              ),

                              // Settings gear
                              IconButton(
                                icon: const Icon(Icons.settings_outlined),
                                tooltip: 'Settings',
                                onPressed: val.isInitialized
                                    ? () => setState(() {
                                          _settingsInitialTab =
                                              SettingsTab.audio;
                                          _showSettings = true;
                                        })
                                    : null,
                              ),

                              const Spacer(),

                              // Mute button
                              IconButton(
                                icon: Icon(
                                  _volume == 0
                                      ? Icons.volume_off
                                      : _volume < 0.5
                                          ? Icons.volume_down
                                          : Icons.volume_up,
                                ),
                                tooltip: _volume == 0 ? 'Unmute' : 'Mute',
                                onPressed: val.isInitialized
                                    ? () {
                                        if (_volume > 0) {
                                          _volumeBeforeMute = _volume;
                                          setState(() => _volume = 0);
                                        } else {
                                          setState(() =>
                                              _volume = _volumeBeforeMute);
                                        }
                                        ctrl.setVolume(_volume);
                                      }
                                    : null,
                              ),
                              // Volume slider
                              SizedBox(
                                width: 120,
                                child: Slider(
                                  value: _volume,
                                  onChanged: val.isInitialized
                                      ? (v) {
                                          setState(() => _volume = v);
                                          ctrl.setVolume(v);
                                        }
                                      : null,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Playback speed
                              _SpeedSelector(
                                speed: val.playbackSpeed,
                                onChanged: val.isInitialized
                                    ? (s) => ctrl.setPlaybackSpeed(s)
                                    : null,
                              ),
                            ],
                          ),
                        ),

                        // Now playing info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            border: Border(
                              top: BorderSide(
                                  color: cs.outlineVariant, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.item!.source == MediaSource.asset
                                    ? Icons.folder
                                    : Icons.cloud,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${widget.item!.name}  -  ${widget.item!.url}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ),
                              if (val.isInitialized)
                                Text(
                                  '${val.size.width.toInt()}x${val.size.height.toInt()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Grip handle shown at the top of the transport tray.
class _TrayGrip extends StatelessWidget {
  const _TrayGrip({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Wraps the transport controls with a slide animation and a draggable grip.
///
/// The [grip] is always visible at the bottom of the screen. The [child]
/// (the actual controls) slides up/down driven by [animation].
class _TransportTray extends StatelessWidget {
  const _TransportTray({
    required this.animation,
    required this.onGripTap,
    required this.onInteraction,
    required this.grip,
    required this.child,
  });

  final AnimationController animation;
  final VoidCallback onGripTap;
  final VoidCallback onInteraction;
  final Widget grip;
  final Widget child;

  static const double _gripHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grip — always visible, tappable and draggable
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onGripTap,
              onVerticalDragUpdate: (details) {
                // Dragging up → reveal, dragging down → hide
                if (details.primaryDelta != null) {
                  if (details.primaryDelta! < -2) {
                    onGripTap();
                  }
                }
              },
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 300) {
                  // Fling downward → hide
                  animation.reverse();
                } else if (velocity < -300) {
                  // Fling upward → show
                  onGripTap();
                }
              },
              child: Container(
                height: _gripHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(child: grip),
              ),
            ),
            // Controls panel — clips and slides
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: animation.value,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => onInteraction(),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  const _PlayPauseOverlay({required this.controller});

  final MiniController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 300),
        child: controller.value.isPlaying
            ? const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              )
            : Container(
                color: Colors.black38,
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              ),
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
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.controller});

  final MiniController controller;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final val = widget.controller.value;
    if (!val.isInitialized) {
      return const LinearProgressIndicator(value: 0);
    }

    final duration = val.duration.inMilliseconds.toDouble();
    final position = val.position.inMilliseconds.toDouble();

    // Buffered ranges
    double maxBuffered = 0;
    for (final range in val.buffered) {
      final end = range.end.inMilliseconds.toDouble();
      if (end > maxBuffered) maxBuffered = end;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Buffering bar behind slider
        SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: duration > 0 ? maxBuffered / duration : 0,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.4),
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: Slider(
            value: _dragging
                ? _dragValue
                : (duration > 0 ? position.clamp(0, duration) : 0),
            min: 0,
            max: duration > 0 ? duration : 1,
            onChangeStart: (v) {
              setState(() {
                _dragging = true;
                _dragValue = v;
              });
            },
            onChanged: (v) {
              setState(() => _dragValue = v);
            },
            onChangeEnd: (v) {
              widget.controller.seekTo(Duration(milliseconds: v.toInt()));
              setState(() => _dragging = false);
            },
          ),
        ),
      ],
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  const _SpeedSelector({required this.speed, this.onChanged});

  final double speed;
  final ValueChanged<double>? onChanged;

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: speed,
      tooltip: 'Playback speed',
      onSelected: onChanged,
      enabled: onChanged != null,
      itemBuilder: (_) => [
        for (final s in _speeds)
          PopupMenuItem(
            value: s,
            child: Text(
              '${s}x',
              style: TextStyle(
                fontWeight: s == speed ? FontWeight.bold : null,
              ),
            ),
          ),
      ],
      child: Chip(
        avatar: const Icon(Icons.speed, size: 18),
        label: Text('${speed}x'),
      ),
    );
  }
}

class _TrackInfoOverlay extends StatelessWidget {
  const _TrackInfoOverlay({
    required this.item,
    required this.value,
    required this.looping,
  });

  final MediaItem item;
  final VideoPlayerValue value;
  final bool looping;

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final w = value.size.width.toInt();
    final h = value.size.height.toInt();

    return Positioned(
      left: 12,
      top: 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Resolution: ${w}x$h'),
                Text('Duration: ${_formatDuration(value.duration)}'),
                Text('Position: ${_formatDuration(value.position)}'),
                Text('Speed: ${value.playbackSpeed}x'),
                Text('Looping: ${looping ? "on" : "off"}'),
                Text(
                    'Source: ${item.source == MediaSource.asset ? "local asset" : "network"}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimecodeOverlay extends StatelessWidget {
  const _TimecodeOverlay({required this.position});

  final Duration position;

  /// Format duration as SMPTE timecode HH:MM:SS:FF (assuming 30 fps).
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
      right: 12,
      bottom: 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _toSmpte(position),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'monospace',
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _FpsButton extends StatelessWidget {
  const _FpsButton({
    required this.window,
    required this.cs,
    required this.onPressed,
  });

  final FpsWindow? window;
  final ColorScheme cs;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final active = window != null;
    return Tooltip(
      message:
          active ? 'FPS avg ${window!.label} (click to cycle)' : 'Show FPS',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.speed_outlined,
                size: 20,
                color: active ? cs.primary : null,
              ),
              if (active) ...[
                const SizedBox(width: 4),
                Text(
                  window!.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Audio-only fallback shown in place of the video texture when the loaded
/// media has no video stream. Displays album art (embedded → sidecar →
/// generated placeholder) and basic text metadata.
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: art != null
                    ? Image.memory(art, fit: BoxFit.cover, gaplessPlayback: true)
                    : _GeneratedArt(
                        title: title,
                        artist: controller.artist,
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (controller.artist != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.artist!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (controller.album != null) ...[
              const SizedBox(height: 4),
              Text(
                controller.album!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Deterministic gradient + music note used as the ultimate album-art
/// fallback. Hue is hashed from title+artist so each track has a unique but
/// consistent placeholder.
class _GeneratedArt extends StatelessWidget {
  const _GeneratedArt({required this.title, this.artist});

  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final int hash = (title + (artist ?? '')).hashCode;
    final double hue = (hash % 360).abs().toDouble();
    final Color c1 = HSLColor.fromAHSL(1, hue, 0.3, 0.15).toColor();
    final Color c2 =
        HSLColor.fromAHSL(1, (hue + 40) % 360, 0.4, 0.25).toColor();
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
          size: 80,
          color: HSLColor.fromAHSL(0.3, hue, 0.5, 0.6).toColor(),
        ),
      ),
    );
  }
}

class _FpsOverlay extends StatelessWidget {
  const _FpsOverlay({
    required this.fps,
    required this.window,
  });

  final double fps;
  final FpsWindow window;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      top: 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${fps.toStringAsFixed(1)} FPS (${window.label})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'monospace',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
