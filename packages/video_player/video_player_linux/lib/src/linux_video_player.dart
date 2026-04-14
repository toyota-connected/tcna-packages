// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'ffi/bindings.dart';
import 'ffi/event_decoder.dart';
import 'messages.g.dart';

/// Audio-only synthetic player IDs start at this value (matches the native
/// counter in `video_player.cc`). Players with IDs at or above this number
/// have no GL texture and must not be wrapped in a `Texture` widget.
const int kLinuxAudioOnlyIdBase = 0x7F000000;

/// A Linux-specific media event carrying album art / metadata payloads not
/// representable by the upstream `VideoEventType` enum. Subscribe via
/// [LinuxVideoPlayer.linuxEventsFor].
class LinuxMediaEvent {
  LinuxMediaEvent.albumArt({required this.mimeType, required this.bytes})
      : type = LinuxMediaEventType.albumArt,
        metadata = null;

  LinuxMediaEvent.metadata(this.metadata)
      : type = LinuxMediaEventType.metadata,
        mimeType = null,
        bytes = null;

  LinuxMediaEvent.audioInfo(this.metadata)
      : type = LinuxMediaEventType.audioInfo,
        mimeType = null,
        bytes = null;

  final LinuxMediaEventType type;
  final String? mimeType;
  final Uint8List? bytes;
  final Map<String, Object?>? metadata;
}

enum LinuxMediaEventType { albumArt, metadata, audioInfo }

/// Per-player event fanout. One `RawReceivePort` is bound to the native
/// side; decoded events are dispatched to two broadcast controllers so
/// both [LinuxVideoPlayer.videoEventsFor] and
/// [LinuxVideoPlayer.linuxEventsFor] can listen independently without
/// stealing each other's subscriptions (the regression fixed in
/// commit 17be666, preserved here).
class _PlayerPort {
  _PlayerPort(this.textureId) {
    _port = RawReceivePort(_onMessage);
    _bindings.ensureInitialized();
    _bindings.registerPort(textureId, _port.sendPort.nativePort);
  }

  final int textureId;
  final VideoPlayerLinuxBindings _bindings = VideoPlayerLinuxBindings.instance;
  late final RawReceivePort _port;

  final StreamController<VideoEvent> _videoEvents =
      StreamController<VideoEvent>.broadcast();
  final StreamController<LinuxMediaEvent> _linuxEvents =
      StreamController<LinuxMediaEvent>.broadcast();

  Stream<VideoEvent> get videoEvents => _videoEvents.stream;
  Stream<LinuxMediaEvent> get linuxEvents => _linuxEvents.stream;

  void close() {
    _bindings.unregisterPort(textureId);
    _port.close();
    _videoEvents.close();
    _linuxEvents.close();
  }

  void _onMessage(dynamic msg) {
    final VpEvent? event = decodeEvent(msg);
    if (event == null) return;
    switch (event) {
      case VpInitialized(:final durationMs,
            :final width,
            :final height,
            :final rotation):
        _videoEvents.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: Duration(milliseconds: durationMs),
          size: Size(width.toDouble(), height.toDouble()),
          rotationCorrection: rotation,
        ));
      case VpCompleted():
        _videoEvents.add(VideoEvent(eventType: VideoEventType.completed));
      case VpBufferingUpdate(:final rangesMs):
        final List<DurationRange> buffered = <DurationRange>[
          for (int i = 0; i + 1 < rangesMs.length; i += 2)
            DurationRange(
              Duration(milliseconds: rangesMs[i]),
              Duration(milliseconds: rangesMs[i + 1]),
            ),
        ];
        _videoEvents.add(VideoEvent(
          eventType: VideoEventType.bufferingUpdate,
          buffered: buffered,
        ));
      case VpBufferingStart():
        _videoEvents.add(VideoEvent(eventType: VideoEventType.bufferingStart));
      case VpBufferingEnd():
        _videoEvents.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
      case VpIsPlayingStateUpdate(:final isPlaying):
        _videoEvents.add(VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: isPlaying,
        ));
      case VpAlbumArt(:final mimeType, :final bytes):
        _linuxEvents.add(LinuxMediaEvent.albumArt(
          mimeType: mimeType,
          bytes: bytes,
        ));
      case VpMediaMetadata(
          :final title,
          :final artist,
          :final album,
          :final albumArtist,
          :final genre,
          :final trackNumber
        ):
        _linuxEvents.add(LinuxMediaEvent.metadata(<String, Object?>{
          'title': title,
          'artist': artist,
          'album': album,
          'albumArtist': albumArtist,
          'genre': genre,
          'trackNumber': trackNumber,
        }));
      case VpAudioInfo(:final codec, :final channels, :final sampleRate):
        _linuxEvents.add(LinuxMediaEvent.audioInfo(<String, Object?>{
          'codec': codec,
          'channels': channels,
          'sampleRate': sampleRate,
        }));
      case VpPositionUpdate():
        // Position updates are surfaced to consumers that poll
        // `getPosition()` today; not mapped onto the upstream VideoEvent
        // enum. Swallow for now — future work can emit a new event type.
        break;
    }
  }
}

/// A Linux implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [LinuxVideoPlayerApi] for control plane and a native
/// `Dart_Port` per player for zero-copy events.
class LinuxVideoPlayer extends VideoPlayerPlatform {
  final LinuxVideoPlayerApi _api = LinuxVideoPlayerApi();
  final Map<int, _PlayerPort> _ports = <int, _PlayerPort>{};
  // Tracks which texture ids correspond to audio-only players. The
  // synthetic-id range (>= kLinuxAudioOnlyIdBase) used by the ivi embedder
  // can't be used as the sole indicator on stock Flutter Linux, which hands
  // out pointer-sized texture ids that are also >= that constant. We resolve
  // the ambiguity by recording the `isAudioOnly` status reported by native
  // at create time.
  final Set<int> _audioOnlyIds = <int>{};

  @override
  Future<void> dispose(int textureId) {
    _audioOnlyIds.remove(textureId);
    _ports.remove(textureId)?.close();
    return _api.dispose(textureId);
  }

  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = LinuxVideoPlayer();
  }

  @override
  Future<void> init() => _api.initialize();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final DataSource dataSource = options.dataSource;
    // The pigeon contract uses empty-string-as-sentinel (not nullable) to
    // sidestep a bug in pigeon v22's GObject generator — see messages.dart.
    String asset = '';
    String uri = '';
    Map<String, String> httpHeaders = <String, String>{};
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset ?? '';
        if (dataSource.package != null) {
          throw UnimplementedError(
              'Loading an asset from a package is not supported on Linux');
        }
      case DataSourceType.network:
        uri = dataSource.uri ?? '';
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.file:
        uri = dataSource.uri ?? '';
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.contentUri:
        uri = dataSource.uri ?? '';
    }

    final int textureId = await _api.create(asset, uri, httpHeaders);
    // Set up the native port before returning; the native side starts
    // posting events as soon as the texture id is known and will silently
    // drop posts until the port is attached, so we want this wired before
    // the caller gets a chance to subscribe.
    _ports[textureId] = _PlayerPort(textureId);
    // Audio-only detection is resolved asynchronously: the GTK plugin's
    // `create` returns a texture id synchronously and inserts the
    // VideoPlayer into its map later (worker thread). Calling
    // `isAudioOnly` right here can land before the player exists and
    // fail player_not_found, so we retry with a short backoff.
    unawaited(_resolveAudioOnlyWhenReady(textureId));
    return textureId;
  }

  /// Calls `_api.isAudioOnly` with a small retry loop to ride out the
  /// async-create window on the GTK plugin. Errors quietly if the native
  /// side still says "player_not_found" after a handful of attempts —
  /// the texture simply stays treated as video (default), which renders
  /// a placeholder Texture widget, acceptable if the native side really
  /// never produced a player.
  Future<void> _resolveAudioOnlyWhenReady(int textureId) async {
    for (int attempt = 0; attempt < 10; ++attempt) {
      try {
        if (await _api.isAudioOnly(textureId)) {
          _audioOnlyIds.add(textureId);
        }
        return;
      } on PlatformException catch (e) {
        if (e.code != 'player_not_found') rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  @override
  Future<void> setLooping(int textureId, bool looping) =>
      _api.setLooping(textureId, looping);

  @override
  Future<void> play(int textureId) => _api.play(textureId);

  @override
  Future<void> pause(int textureId) => _api.pause(textureId);

  @override
  Future<void> setVolume(int textureId, double volume) =>
      _api.setVolume(textureId, volume);

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) {
    assert(speed > 0);
    return _api.setPlaybackSpeed(textureId, speed);
  }

  @override
  Future<void> seekTo(int textureId, Duration position) =>
      _api.seekTo(textureId, position.inMilliseconds);

  @override
  Future<Duration> getPosition(int textureId) async {
    final int position = await _api.getPosition(textureId);
    return Duration(milliseconds: position);
  }

  // ────────────────────────────────────────────────────────────────────
  // Phase 1 — audio control surface
  // ────────────────────────────────────────────────────────────────────

  Future<int> getAudioTrackCount(int textureId) =>
      _api.getAudioTrackCount(textureId);

  Future<void> setAudioTrack(int textureId, int trackIndex) =>
      _api.setAudioTrack(textureId, trackIndex);

  Future<void> setOutputChannels(int textureId, int channels) =>
      _api.setOutputChannels(textureId, channels);

  Future<void> setMute(int textureId, bool mute) =>
      _api.setMute(textureId, mute);

  Future<bool> isAudioOnly(int textureId) => _api.isAudioOnly(textureId);

  // ────────────────────────────────────────────────────────────────────
  // Phase 2 — quality & tuning
  // ────────────────────────────────────────────────────────────────────

  Future<void> setScaleMethod(int textureId, int method) =>
      _api.setScaleMethod(textureId, method);

  Future<void> setAVOffset(int textureId, int offsetMs) =>
      _api.setAVOffset(textureId, offsetMs);

  Future<void> setSubtitlesEnabled(int textureId, bool enabled) =>
      _api.setSubtitlesEnabled(textureId, enabled);

  Future<int> getSubtitleTrackCount(int textureId) =>
      _api.getSubtitleTrackCount(textureId);

  Future<void> setSubtitleTrack(int textureId, int trackIndex) =>
      _api.setSubtitleTrack(textureId, trackIndex);

  Future<void> setSubtitleUri(int textureId, String uri) =>
      _api.setSubtitleUri(textureId, uri);

  Future<void> setSubtitleFont(int textureId, String fontDesc) =>
      _api.setSubtitleFont(textureId, fontDesc);

  Future<void> setChannelMixPreset(int textureId, String preset) =>
      _api.setChannelMixPreset(textureId, preset);

  // ────────────────────────────────────────────────────────────────────
  // Phase 3 — premium features
  // ────────────────────────────────────────────────────────────────────

  Future<void> setEqualizer(int textureId, List<double> bands) {
    assert(bands.length == 10, 'Equalizer requires exactly 10 bands');
    return _api.setEqualizer(textureId, bands);
  }

  Future<void> setVideoBalance(int textureId,
          {required double brightness,
          required double contrast,
          required double saturation,
          required double hue}) =>
      _api.setVideoBalance(textureId, brightness, contrast, saturation, hue);

  Future<void> setAudioPassthrough(int textureId, bool enabled) =>
      _api.setAudioPassthrough(textureId, enabled);

  Future<void> setChannelMixMatrix(int textureId,
          {required int inChannels,
          required int outChannels,
          required List<double> matrix}) =>
      _api.setChannelMixMatrix(textureId, inChannels, outChannels, matrix);

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    final _PlayerPort? p = _ports[textureId];
    if (p == null) return const Stream<VideoEvent>.empty();
    return p.videoEvents;
  }

  /// Returns a stream of Linux-specific media events (album art, text
  /// metadata, audio stream info) for [textureId]. Shares the underlying
  /// native port with [videoEventsFor].
  Stream<LinuxMediaEvent> linuxEventsFor(int textureId) {
    final _PlayerPort? p = _ports[textureId];
    if (p == null) return const Stream<LinuxMediaEvent>.empty();
    return p.linuxEvents;
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    // Audio-only players don't have a backing texture; binding them to a
    // `Texture` widget would render an opaque black square. We track audio-
    // only ids explicitly (see createWithOptions) because stock Flutter
    // Linux hands out pointer-sized texture ids that also happen to sit
    // above kLinuxAudioOnlyIdBase.
    if (_audioOnlyIds.contains(options.playerId)) {
      return const SizedBox.shrink();
    }
    return Texture(textureId: options.playerId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) => Future<void>.value();

  /// Test-only: dispatches a raw tagged event (shape matches what the
  /// native side posts through `Dart_PostCObject_DL`) through the internal
  /// decoder and controllers for [textureId]. Returns `true` if a port
  /// was registered for the id.
  @visibleForTesting
  bool debugDispatchEvent(int textureId, Object? rawEvent) {
    final _PlayerPort? p = _ports[textureId];
    if (p == null) return false;
    p._onMessage(rawEvent);
    return true;
  }

  /// Test-only: ensures a port entry exists for [textureId] so events can
  /// be dispatched without going through [createWithOptions] / the FFI.
  @visibleForTesting
  void debugEnsurePort(int textureId) {
    _ports.putIfAbsent(textureId, () => _PlayerPort(textureId));
  }
}
