import 'dart:async';

import 'package:flutter/material.dart';

import 'library.dart';
import 'mini_controller.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, this.item});

  final MediaItem? item;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  MiniController? _controller;
  String? _loadedUrl;
  bool _isLooping = true;
  double _volume = 1.0;
  double _volumeBeforeMute = 1.0;

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

    ctrl.addListener(() {
      if (mounted) setState(() {});
    });

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
  }

  @override
  void dispose() {
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
    final val = ctrl.value;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Video area
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: val.isInitialized
                  ? AspectRatio(
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
                        ],
                      ),
                    )
                  : val.hasError
                      ? _ErrorDisplay(message: val.errorDescription!)
                      : const CircularProgressIndicator(),
            ),
          ),
        ),

        // Controls panel
        Container(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Time display
                    Text(
                      '${_formatDuration(val.position)} / ${_formatDuration(val.duration)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Playback controls
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      tooltip: 'Rewind 10s',
                      onPressed: val.isInitialized
                          ? () => ctrl.seekTo(
                              val.position - const Duration(seconds: 10))
                          : null,
                    ),
                    IconButton.filled(
                      icon: Icon(
                        val.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                      tooltip: val.isPlaying ? 'Pause' : 'Play',
                      onPressed: val.isInitialized
                          ? () => val.isPlaying ? ctrl.pause() : ctrl.play()
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      tooltip: 'Forward 10s',
                      onPressed: val.isInitialized
                          ? () => ctrl.seekTo(
                              val.position + const Duration(seconds: 10))
                          : null,
                    ),

                    const SizedBox(width: 16),

                    // Loop toggle
                    IconButton(
                      icon: Icon(
                        Icons.loop,
                        color: _isLooping ? cs.primary : null,
                      ),
                      tooltip: _isLooping ? 'Looping on' : 'Looping off',
                      onPressed: val.isInitialized
                          ? () {
                              setState(() => _isLooping = !_isLooping);
                              ctrl.setLooping(_isLooping);
                            }
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
                                setState(() => _volume = _volumeBeforeMute);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(color: cs.outlineVariant, width: 0.5),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    if (val.isInitialized)
                      Text(
                        '${val.size.width.toInt()}x${val.size.height.toInt()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
