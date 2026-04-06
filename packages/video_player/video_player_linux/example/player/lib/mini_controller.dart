// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(stuartmorgan): Consider extracting this to a shared local (path-based)
// package for use in all implementation packages.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_linux/video_player_linux.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

VideoPlayerPlatform? _cachedPlatform;

VideoPlayerPlatform get _platform {
  if (_cachedPlatform == null) {
    _cachedPlatform = VideoPlayerPlatform.instance;
    _cachedPlatform!.init();
  }
  return _cachedPlatform!;
}

/// The duration, current position, buffering state, error state and settings
/// of a [MiniController].
@immutable
class VideoPlayerValue {
  /// Constructs a video with the given values. Only [duration] is required. The
  /// rest will initialize with default values when unset.
  const VideoPlayerValue({
    required this.duration,
    this.size = Size.zero,
    this.position = Duration.zero,
    this.buffered = const <DurationRange>[],
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.playbackSpeed = 1.0,
    this.errorDescription,
  });

  /// Returns an instance for a video that hasn't been loaded.
  const VideoPlayerValue.uninitialized()
      : this(duration: Duration.zero, isInitialized: false);

  /// Returns an instance with the given [errorDescription].
  const VideoPlayerValue.erroneous(String errorDescription)
      : this(
            duration: Duration.zero,
            isInitialized: false,
            errorDescription: errorDescription);

  /// The total duration of the video.
  ///
  /// The duration is [Duration.zero] if the video hasn't been initialized.
  final Duration duration;

  /// The current playback position.
  final Duration position;

  /// The currently buffered ranges.
  final List<DurationRange> buffered;

  /// True if the video is playing. False if it's paused.
  final bool isPlaying;

  /// True if the video is currently buffering.
  final bool isBuffering;

  /// The current speed of the playback.
  final double playbackSpeed;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is `null`.
  final String? errorDescription;

  /// The [size] of the currently loaded video.
  final Size size;

  /// Indicates whether or not the video has been loaded and is ready to play.
  final bool isInitialized;

  /// Indicates whether or not the video is in an error state. If this is true
  /// [errorDescription] should have information about the problem.
  bool get hasError => errorDescription != null;

  /// Returns [size.width] / [size.height].
  ///
  /// Will return `1.0` if:
  /// * [isInitialized] is `false`
  /// * [size.width], or [size.height] is equal to `0.0`
  /// * aspect ratio would be less than or equal to `0.0`
  double get aspectRatio {
    if (!isInitialized || size.width == 0 || size.height == 0) {
      return 1.0;
    }
    final double aspectRatio = size.width / size.height;
    if (aspectRatio <= 0) {
      return 1.0;
    }
    return aspectRatio;
  }

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWidth].
  VideoPlayerValue copyWith({
    Duration? duration,
    Size? size,
    Duration? position,
    List<DurationRange>? buffered,
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    double? playbackSpeed,
    String? errorDescription,
  }) {
    return VideoPlayerValue(
      duration: duration ?? this.duration,
      size: size ?? this.size,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPlayerValue &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          position == other.position &&
          listEquals(buffered, other.buffered) &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          playbackSpeed == other.playbackSpeed &&
          errorDescription == other.errorDescription &&
          size == other.size &&
          isInitialized == other.isInitialized;

  @override
  int get hashCode => Object.hash(
        duration,
        position,
        buffered,
        isPlaying,
        isBuffering,
        playbackSpeed,
        errorDescription,
        size,
        isInitialized,
      );
}

/// A very minimal version of `VideoPlayerController` for running the example
/// without relying on `video_player`.
class MiniController extends ValueNotifier<VideoPlayerValue> {
  /// Constructs a [MiniController] playing a video from an asset.
  ///
  /// The name of the asset is given by the [dataSource] argument and must not be
  /// null. The [package] argument must be non-null when the asset comes from a
  /// package and null otherwise.
  MiniController.asset(this.dataSource, {this.package})
      : dataSourceType = DataSourceType.asset,
        super(const VideoPlayerValue(duration: Duration.zero));

  /// Constructs a [MiniController] playing a video from obtained from
  /// the network.
  MiniController.network(this.dataSource)
      : dataSourceType = DataSourceType.network,
        package = null,
        super(const VideoPlayerValue(duration: Duration.zero));

  /// Constructs a [MiniController] playing a video from obtained from a file.
  MiniController.file(File file)
      : dataSource = Uri.file(file.absolute.path).toString(),
        dataSourceType = DataSourceType.file,
        package = null,
        super(const VideoPlayerValue(duration: Duration.zero));

  /// The URI to the video file. This will be in different formats depending on
  /// the [DataSourceType] of the original video.
  final String dataSource;

  /// Describes the type of data source this [MiniController]
  /// is constructed with.
  final DataSourceType dataSourceType;

  /// Only set for [asset] videos. The package that the asset was loaded from.
  final String? package;

  bool _isDisposed = false;
  Duration? _seekTarget;
  Timer? _timer;
  Completer<void>? _creatingCompleter;
  StreamSubscription<dynamic>? _eventSubscription;
  StreamSubscription<LinuxMediaEvent>? _linuxEventSubscription;

  // Phase 1 — audio-only mode + album art / metadata state.
  bool _isAudioOnly = false;
  bool get isAudioOnly => _isAudioOnly;

  Uint8List? _albumArt;
  Uint8List? get albumArt => _albumArt;

  String? _title;
  String? _artist;
  String? _album;
  String? get title => _title;
  String? get artist => _artist;
  String? get album => _album;

  String? _audioCodec;
  int? _audioChannels;
  int? _audioSampleRate;
  String? get audioCodec => _audioCodec;
  int? get audioChannels => _audioChannels;
  int? get audioSampleRate => _audioSampleRate;

  int _audioTrackCount = 0;
  int get audioTrackCount => _audioTrackCount;

  bool _muted = false;
  bool get muted => _muted;

  /// The id of a texture that hasn't been initialized.
  @visibleForTesting
  static const int kUninitializedTextureId = -1;
  int _textureId = kUninitializedTextureId;

  /// This is just exposed for testing. It shouldn't be used by anyone depending
  /// on the plugin.
  @visibleForTesting
  int get textureId => _textureId;

  /// Attempts to open the given [dataSource] and load metadata about the video.
  Future<void> initialize() async {
    _creatingCompleter = Completer<void>();

    late DataSource dataSourceDescription;
    switch (dataSourceType) {
      case DataSourceType.asset:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.asset,
          asset: dataSource,
          package: package,
        );
      case DataSourceType.network:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.network,
          uri: dataSource,
        );
      case DataSourceType.file:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.file,
          uri: dataSource,
        );
      case DataSourceType.contentUri:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.contentUri,
          uri: dataSource,
        );
    }

    try {
      _textureId = (await _platform.createWithOptions(VideoCreationOptions(
              dataSource: dataSourceDescription,
              viewType: VideoViewType.textureView))) ??
          kUninitializedTextureId;
    } catch (e) {
      _creatingCompleter!.complete(null);
      rethrow;
    }
    _creatingCompleter!.complete(null);

    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(VideoEvent event) {
      switch (event.eventType) {
        case VideoEventType.initialized:
          // Audio-only media reports a zero-sized texture (no GL backing).
          _isAudioOnly = event.size == Size.zero;
          value = value.copyWith(
            duration: event.duration,
            size: event.size,
            isInitialized: event.duration != null,
          );
          notifyListeners();
          initializingCompleter.complete(null);
          _platform.setVolume(_textureId, 1.0);
          _platform.setLooping(_textureId, true);
          _applyPlayPause();
          // Cache audio track count and try sidecar art if no embedded art
          // arrived in the seeded mediaMetadata event.
          final platform = _platform;
          if (platform is LinuxVideoPlayer) {
            platform.getAudioTrackCount(_textureId).then((int n) {
              _audioTrackCount = n;
              if (!_isDisposed) notifyListeners();
            }).catchError((_) {});
            if (_isAudioOnly && _albumArt == null) {
              _findSidecarArt().then((Uint8List? bytes) {
                if (bytes != null && !_isDisposed && _albumArt == null) {
                  _albumArt = bytes;
                  notifyListeners();
                }
              });
            }
          }
        case VideoEventType.completed:
          value = value.copyWith(
            position: value.duration,
            isPlaying: false,
          );
          _timer?.cancel();
          _platform.pause(_textureId);
        case VideoEventType.bufferingUpdate:
          value = value.copyWith(buffered: event.buffered);
        case VideoEventType.bufferingStart:
          value = value.copyWith(isBuffering: true);
        case VideoEventType.bufferingEnd:
          value = value.copyWith(isBuffering: false);
        case VideoEventType.isPlayingStateUpdate:
          value = value.copyWith(isPlaying: event.isPlaying);
        case VideoEventType.unknown:
          break;
      }
    }

    void errorListener(Object obj) {
      final PlatformException e = obj as PlatformException;
      value = VideoPlayerValue.erroneous(e.message ?? e.code);
      _timer?.cancel();
      if (!initializingCompleter.isCompleted) {
        initializingCompleter.completeError(obj);
      }
    }

    // Subscribe to events BEFORE telling the native side to start the
    // pipeline. Otherwise the 'initialized' event can fire on the very
    // first PLAYING transition (immediately after play() returns) before
    // we attach the listener — and broadcast streams don't replay past
    // events. The result is initialize() hanging on the first track at
    // app startup.
    _eventSubscription = _platform
        .videoEventsFor(_textureId)
        .listen(eventListener, onError: errorListener);

    // Subscribe to Linux-specific media events (album art, metadata, audio
    // info) that aren't representable on the upstream VideoEvent enum.
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      _linuxEventSubscription =
          platform.linuxEventsFor(_textureId).listen((LinuxMediaEvent e) {
        switch (e.type) {
          case LinuxMediaEventType.albumArt:
            if (e.bytes != null && e.bytes!.isNotEmpty) {
              _albumArt = e.bytes;
              notifyListeners();
            }
          case LinuxMediaEventType.metadata:
            final m = e.metadata!;
            _title = (m['title'] as String?)?.isNotEmpty == true
                ? m['title'] as String
                : _title;
            _artist = (m['artist'] as String?)?.isNotEmpty == true
                ? m['artist'] as String
                : _artist;
            _album = (m['album'] as String?)?.isNotEmpty == true
                ? m['album'] as String
                : _album;
            notifyListeners();
          case LinuxMediaEventType.audioInfo:
            final m = e.metadata!;
            _audioCodec = (m['codec'] as String?)?.isNotEmpty == true
                ? m['codec'] as String
                : _audioCodec;
            _audioChannels = m['channels'] as int? ?? _audioChannels;
            _audioSampleRate = m['sampleRate'] as int? ?? _audioSampleRate;
            notifyListeners();
        }
      });
    }

    // Yield to the event loop so the EventChannel "listen" platform
    // message has a chance to flush to native before we dispatch play().
    // EventChannel listens and Pigeon method calls travel on different
    // channel transports and are not strictly ordered relative to each
    // other, so without this yield the native side can occasionally
    // process play() first, reach PLAYING, fire the 'initialized' event
    // while event_sink_ is still null, and lose it. The C++ stream
    // handler does have a replay path for that case but it depends on
    // is_initialized_ already being true when OnListen runs — which
    // isn't guaranteed if OnListen lands between play() dispatch and the
    // pipeline actually reaching PLAYING.
    await Future<void>.delayed(Duration.zero);
    if (_isDisposed) return;

    // Now that the listeners are attached, kick the pipeline into PLAYING
    // so the native side will fire the 'initialized' event we're waiting
    // on.
    _platform.play(_textureId);

    return initializingCompleter.future;
  }

  /// Looks for a sidecar cover art file in the same directory as the
  /// currently-loaded media. Only useful for `file://` sources.
  Future<Uint8List?> _findSidecarArt() async {
    if (dataSourceType != DataSourceType.file &&
        dataSourceType != DataSourceType.network) {
      return null;
    }
    final Uri? uri = Uri.tryParse(dataSource);
    if (uri == null || uri.scheme != 'file') return null;
    final String filePath = uri.toFilePath();
    final int slash = filePath.lastIndexOf(Platform.pathSeparator);
    final String dir = slash > 0 ? filePath.substring(0, slash) : '.';
    const List<String> names = <String>[
      'cover.jpg',
      'cover.png',
      'folder.jpg',
      'folder.png',
      'album.jpg',
      'album.png',
      'front.jpg',
      'front.png',
      'artwork.jpg',
      'artwork.png',
    ];
    for (final String n in names) {
      final File f = File('$dir${Platform.pathSeparator}$n');
      if (await f.exists()) return f.readAsBytes();
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────────────
  // Phase 1 — audio control surface
  // ────────────────────────────────────────────────────────────────────

  Future<void> setAudioTrack(int trackIndex) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer)
      await platform.setAudioTrack(_textureId, trackIndex);
  }

  Future<void> setOutputChannels(int channels) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer)
      await platform.setOutputChannels(_textureId, channels);
  }

  Future<void> setMute(bool mute) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setMute(_textureId, mute);
      _muted = mute;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Phase 2 — quality & tuning
  // ────────────────────────────────────────────────────────────────────

  Future<void> setScaleMethod(int method) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setScaleMethod(_textureId, method);
    }
  }

  Future<void> setAVOffset(int offsetMs) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setAVOffset(_textureId, offsetMs);
    }
  }

  Future<void> setSubtitlesEnabled(bool enabled) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setSubtitlesEnabled(_textureId, enabled);
    }
  }

  Future<int> subtitleTrackCount() async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      return platform.getSubtitleTrackCount(_textureId);
    }
    return 0;
  }

  Future<void> setSubtitleTrack(int index) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setSubtitleTrack(_textureId, index);
    }
  }

  Future<void> setSubtitleUri(String uri) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setSubtitleUri(_textureId, uri);
    }
  }

  Future<void> setSubtitleFont(String fontDesc) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setSubtitleFont(_textureId, fontDesc);
    }
  }

  Future<void> setChannelMixPreset(String preset) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setChannelMixPreset(_textureId, preset);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Phase 3 — premium features
  // ────────────────────────────────────────────────────────────────────

  /// 10-band equalizer state. Persisted in-controller so the settings UI can
  /// re-render the sliders without re-querying the native side. The bands
  /// are always cached; whether they're applied to the audio path depends
  /// on [equalizerEnabled].
  List<double> equalizerBands = List<double>.filled(10, 0.0);
  bool equalizerEnabled = false;

  /// Updates the cached band values and (if EQ is enabled) pushes them to
  /// the native pipeline.
  Future<void> setEqualizer(List<double> bands) async {
    assert(bands.length == 10);
    equalizerBands = List<double>.from(bands);
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setEqualizer(
        _textureId,
        equalizerEnabled ? equalizerBands : List<double>.filled(10, 0.0),
      );
    }
    notifyListeners();
  }

  /// Toggles the equalizer on or off without losing the cached band
  /// values. When turned off, a flat (all-zero) matrix is sent to the
  /// native side; when turned on, the cached band values are re-applied.
  Future<void> setEqualizerEnabled(bool enabled) async {
    equalizerEnabled = enabled;
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setEqualizer(
        _textureId,
        enabled ? equalizerBands : List<double>.filled(10, 0.0),
      );
    }
    notifyListeners();
  }

  // Video balance state.
  double videoBrightness = 0.0;
  double videoContrast = 1.0;
  double videoSaturation = 1.0;
  double videoHue = 0.0;

  Future<void> setVideoBalance({
    double? brightness,
    double? contrast,
    double? saturation,
    double? hue,
  }) async {
    videoBrightness = brightness ?? videoBrightness;
    videoContrast = contrast ?? videoContrast;
    videoSaturation = saturation ?? videoSaturation;
    videoHue = hue ?? videoHue;
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setVideoBalance(
        _textureId,
        brightness: videoBrightness,
        contrast: videoContrast,
        saturation: videoSaturation,
        hue: videoHue,
      );
    }
    notifyListeners();
  }

  bool _passthrough = false;
  bool get passthrough => _passthrough;
  Future<void> setAudioPassthrough(bool enabled) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setAudioPassthrough(_textureId, enabled);
      _passthrough = enabled;
      notifyListeners();
    }
  }

  Future<void> setChannelMixMatrix({
    required int inChannels,
    required int outChannels,
    required List<double> matrix,
  }) async {
    final platform = _platform;
    if (platform is LinuxVideoPlayer) {
      await platform.setChannelMixMatrix(_textureId,
          inChannels: inChannels, outChannels: outChannels, matrix: matrix);
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    if (_creatingCompleter != null) {
      await _creatingCompleter!.future;
      await _eventSubscription?.cancel();
      await _linuxEventSubscription?.cancel();
      if (_textureId != kUninitializedTextureId) {
        await _platform.dispose(_textureId);
      }
    }
    super.dispose();
  }

  /// Starts playing the video.
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    await _applyPlayPause();
  }

  /// Pauses the video.
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    await _applyPlayPause();
  }

  Future<void> _applyPlayPause() async {
    _timer?.cancel();
    if (_textureId == kUninitializedTextureId) return;
    if (value.isPlaying) {
      await _platform.play(_textureId);

      _timer = Timer.periodic(
        const Duration(milliseconds: 500),
        (Timer timer) async {
          if (_isDisposed) {
            timer.cancel();
            return;
          }
          final Duration? newPosition = await position;
          if (newPosition == null || _isDisposed) {
            return;
          }
          // After a seek, ignore polled positions that haven't caught up
          // to the seek target yet (the pipeline reports stale values
          // during the flush).
          final target = _seekTarget;
          if (target != null) {
            if ((newPosition - target).abs() < const Duration(seconds: 2)) {
              _seekTarget = null;
            } else {
              return;
            }
          }
          _updatePosition(newPosition);
        },
      );
      await _applyPlaybackSpeed();
    } else {
      await _platform.pause(_textureId);
    }
  }

  Future<void> _applyPlaybackSpeed() async {
    if (value.isPlaying) {
      await _platform.setPlaybackSpeed(
        _textureId,
        value.playbackSpeed,
      );
    }
  }

  /// The position in the current video.
  Future<Duration?> get position async {
    return _platform.getPosition(_textureId);
  }

  /// Sets the video's current timestamp to be at [position].
  Future<void> seekTo(Duration position) async {
    if (position > value.duration) {
      position = value.duration;
    } else if (position < Duration.zero) {
      position = Duration.zero;
    }
    _seekTarget = position;
    _updatePosition(position);
    await _platform.seekTo(_textureId, position);
  }

  /// Sets the playback speed.
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
    await _applyPlaybackSpeed();
  }

  /// Sets the volume (0.0 silent, 1.0 full).
  Future<void> setVolume(double volume) async {
    await _platform.setVolume(_textureId, volume);
  }

  /// Enables or disables looping.
  Future<void> setLooping(bool looping) async {
    await _platform.setLooping(_textureId, looping);
  }

  void _updatePosition(Duration position) {
    value = value.copyWith(position: position);
  }
}

/// Widget that displays the video controlled by [controller].
class VideoPlayer extends StatefulWidget {
  /// Uses the given [controller] for all video rendered in this widget.
  const VideoPlayer(this.controller, {super.key});

  /// The [MiniController] responsible for the video being rendered in
  /// this widget.
  final MiniController controller;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  _VideoPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  late VoidCallback _listener;

  late int _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return (_textureId == MiniController.kUninitializedTextureId ||
            !widget.controller.value.isInitialized)
        ? Container()
        : RepaintBoundary(
            child: _platform
                .buildViewWithOptions(VideoViewOptions(playerId: _textureId)),
          );
  }
}

class _VideoScrubber extends StatefulWidget {
  const _VideoScrubber({
    required this.child,
    required this.controller,
  });

  final Widget child;
  final MiniController controller;

  @override
  _VideoScrubberState createState() => _VideoScrubberState();
}

class _VideoScrubberState extends State<_VideoScrubber> {
  MiniController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final RenderBox box = context.findRenderObject()! as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: widget.child,
      onTapDown: (TapDownDetails details) {
        if (controller.value.isInitialized) {
          seekToRelativePosition(details.globalPosition);
        }
      },
    );
  }
}

/// Displays the play/buffering status of the video controlled by [controller].
class VideoProgressIndicator extends StatefulWidget {
  /// Construct an instance that displays the play/buffering status of the video
  /// controlled by [controller].
  const VideoProgressIndicator(this.controller, {super.key});

  /// The [MiniController] that actually associates a video with this
  /// widget.
  final MiniController controller;

  @override
  State<VideoProgressIndicator> createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  _VideoProgressIndicatorState() {
    listener = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  late VoidCallback listener;

  MiniController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    const Color playedColor = Color.fromRGBO(255, 0, 0, 0.7);
    const Color bufferedColor = Color.fromRGBO(50, 50, 200, 0.2);
    const Color backgroundColor = Color.fromRGBO(200, 200, 200, 0.5);

    Widget progressIndicator;
    if (controller.value.isInitialized) {
      final int duration = controller.value.duration.inMilliseconds;
      final int position = controller.value.position.inMilliseconds;

      int maxBuffering = 0;
      for (final DurationRange range in controller.value.buffered) {
        final int end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          LinearProgressIndicator(
            value: maxBuffering / duration,
            valueColor: const AlwaysStoppedAnimation<Color>(bufferedColor),
            backgroundColor: backgroundColor,
          ),
          LinearProgressIndicator(
            value: position / duration,
            valueColor: const AlwaysStoppedAnimation<Color>(playedColor),
            backgroundColor: Colors.transparent,
          ),
        ],
      );
    } else {
      progressIndicator = const LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(playedColor),
        backgroundColor: backgroundColor,
      );
    }
    return _VideoScrubber(
      controller: controller,
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: progressIndicator,
      ),
    );
  }
}
