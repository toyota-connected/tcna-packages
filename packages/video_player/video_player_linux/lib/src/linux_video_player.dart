// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

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

/// An Linux implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [LinuxVideoPlayerApi].
class LinuxVideoPlayer extends VideoPlayerPlatform {
  final LinuxVideoPlayerApi _api = LinuxVideoPlayerApi();

  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = LinuxVideoPlayer();
  }

  @override
  Future<void> init() => _api.initialize();

  @override
  Future<void> dispose(int textureId) => _api.dispose(textureId);

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final DataSource dataSource = options.dataSource;
    String? asset;
    String? uri;
    Map<String, String> httpHeaders = <String, String>{};
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        if (dataSource.package != null) {
          throw UnimplementedError(
              'Loading an asset from a package is not supported on Linux');
        }
      case DataSourceType.network:
        uri = dataSource.uri;
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.file:
        uri = dataSource.uri;
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.contentUri:
        uri = dataSource.uri;
    }

    final int textureId = await _api.create(asset, uri, httpHeaders);
    return textureId;
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
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: map['duration'] as int),
            size: Size((map['width'] as num?)?.toDouble() ?? 0.0,
                (map['height'] as num?)?.toDouble() ?? 0.0),
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
          );
        case 'completed':
          return VideoEvent(eventType: VideoEventType.completed);
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List<dynamic>;
          return VideoEvent(
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
            eventType: VideoEventType.bufferingUpdate,
          );
        case 'bufferingStart':
          return VideoEvent(eventType: VideoEventType.bufferingStart);
        case 'bufferingEnd':
          return VideoEvent(eventType: VideoEventType.bufferingEnd);
        case 'isPlayingStateUpdate':
          return VideoEvent(
            eventType: VideoEventType.isPlayingStateUpdate,
            isPlaying: map['isPlaying'] as bool,
          );
        // Linux-specific events: surfaced as `unknown` to upstream consumers
        // and as `LinuxMediaEvent` via [linuxEventsFor].
        case 'albumArt':
        case 'mediaMetadata':
        case 'audioInfo':
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  /// Returns a stream of Linux-specific media events (album art, text
  /// metadata, audio stream info) for [textureId]. Shares the underlying
  /// event channel with [videoEventsFor].
  Stream<LinuxMediaEvent> linuxEventsFor(int textureId) {
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map<LinuxMediaEvent?>((dynamic event) {
          final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
          switch (map['event']) {
            case 'albumArt':
              final Object? data = map['data'];
              return LinuxMediaEvent.albumArt(
                mimeType: (map['mimeType'] as String?) ?? 'image/jpeg',
                bytes: data is Uint8List
                    ? data
                    : data is List
                        ? Uint8List.fromList(data.cast<int>())
                        : Uint8List(0),
              );
            case 'mediaMetadata':
              return LinuxMediaEvent.metadata(<String, Object?>{
                'title': map['title'],
                'artist': map['artist'],
                'album': map['album'],
                'albumArtist': map['albumArtist'],
                'genre': map['genre'],
                'trackNumber': map['trackNumber'],
              });
            case 'audioInfo':
              return LinuxMediaEvent.audioInfo(<String, Object?>{
                'codec': map['codec'],
                'channels': map['channels'],
                'sampleRate': map['sampleRate'],
              });
            default:
              return null;
          }
        })
        .where((LinuxMediaEvent? e) => e != null)
        .cast<LinuxMediaEvent>();
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    // Audio-only players don't have a backing GL texture; binding them to a
    // `Texture` widget would render an opaque black square.
    if (options.playerId >= kLinuxAudioOnlyIdBase) {
      return const SizedBox.shrink();
    }
    return Texture(textureId: options.playerId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) => Future<void>.value();

  EventChannel _eventChannelFor(int textureId) =>
      EventChannel('flutter.io/videoPlayer/videoEvents$textureId');

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List<dynamic>;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }
}
