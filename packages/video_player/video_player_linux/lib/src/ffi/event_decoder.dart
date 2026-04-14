// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

/// Tag values — must stay in sync with `linux_cpp/core/event_port.h`.
class EventTag {
  static const int initialized = 0;
  static const int completed = 1;
  static const int bufferingUpdate = 2;
  static const int bufferingStart = 3;
  static const int bufferingEnd = 4;
  static const int isPlayingStateUpdate = 5;
  static const int albumArt = 6;
  static const int mediaMetadata = 7;
  static const int audioInfo = 8;
  static const int positionUpdate = 9;
}

/// A decoded event from the native port. Thin struct — callers project it
/// onto [VideoEvent] / [LinuxMediaEvent] shapes.
sealed class VpEvent {
  const VpEvent();
}

class VpInitialized extends VpEvent {
  const VpInitialized({
    required this.durationMs,
    required this.width,
    required this.height,
    required this.rotation,
  });
  final int durationMs;
  final int width;
  final int height;
  final int rotation;
}

class VpCompleted extends VpEvent {
  const VpCompleted();
}

class VpBufferingUpdate extends VpEvent {
  const VpBufferingUpdate(this.rangesMs);
  // Flat array [start0, end0, start1, end1, ...] in milliseconds.
  final Int32List rangesMs;
}

class VpBufferingStart extends VpEvent {
  const VpBufferingStart();
}

class VpBufferingEnd extends VpEvent {
  const VpBufferingEnd();
}

class VpIsPlayingStateUpdate extends VpEvent {
  const VpIsPlayingStateUpdate(this.isPlaying);
  final bool isPlaying;
}

class VpAlbumArt extends VpEvent {
  const VpAlbumArt({required this.mimeType, required this.bytes});
  final String mimeType;
  // Zero-copy view into the native buffer; lifetime is managed by the
  // native finalizer registered at post time. Hold the reference only
  // as long as needed; copy if you intend to retain across GC cycles.
  final Uint8List bytes;
}

class VpMediaMetadata extends VpEvent {
  const VpMediaMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtist,
    required this.genre,
    required this.trackNumber,
  });
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final int trackNumber;
}

class VpAudioInfo extends VpEvent {
  const VpAudioInfo({
    required this.codec,
    required this.channels,
    required this.sampleRate,
  });
  final String codec;
  final int channels;
  final int sampleRate;
}

class VpPositionUpdate extends VpEvent {
  const VpPositionUpdate(this.positionMs);
  final int positionMs;
}

/// Decodes a raw `Dart_CObject_kArray` posted by the native side into a
/// strongly-typed [VpEvent]. Unknown tags are surfaced as `null` so the
/// caller can drop them forward-compatibly (a newer native plugin may
/// post tags the Dart side doesn't yet recognize).
VpEvent? decodeEvent(Object? raw) {
  if (raw is! List) return null;
  if (raw.isEmpty) return null;
  final Object? tagObj = raw[0];
  if (tagObj is! int) return null;
  switch (tagObj) {
    case EventTag.initialized:
      return VpInitialized(
        durationMs: raw[1] as int,
        width: raw[2] as int,
        height: raw[3] as int,
        rotation: raw[4] as int,
      );
    case EventTag.completed:
      return const VpCompleted();
    case EventTag.bufferingUpdate:
      final Object? data = raw[1];
      // Int32 typed data arrives as Int32List directly.
      if (data is Int32List) {
        return VpBufferingUpdate(data);
      }
      // Fallback for older dart runtimes that surface it as List<int>.
      if (data is List) {
        return VpBufferingUpdate(Int32List.fromList(data.cast<int>()));
      }
      return VpBufferingUpdate(Int32List(0));
    case EventTag.bufferingStart:
      return const VpBufferingStart();
    case EventTag.bufferingEnd:
      return const VpBufferingEnd();
    case EventTag.isPlayingStateUpdate:
      return VpIsPlayingStateUpdate(raw[1] as bool);
    case EventTag.albumArt:
      final Object? data = raw[2];
      final Uint8List bytes = data is Uint8List
          ? data
          : (data is List ? Uint8List.fromList(data.cast<int>()) : Uint8List(0));
      return VpAlbumArt(
        mimeType: raw[1] as String,
        bytes: bytes,
      );
    case EventTag.mediaMetadata:
      return VpMediaMetadata(
        title: raw[1] as String,
        artist: raw[2] as String,
        album: raw[3] as String,
        albumArtist: raw[4] as String,
        genre: raw[5] as String,
        trackNumber: raw[6] as int,
      );
    case EventTag.audioInfo:
      return VpAudioInfo(
        codec: raw[1] as String,
        channels: raw[2] as int,
        sampleRate: raw[3] as int,
      );
    case EventTag.positionUpdate:
      return VpPositionUpdate(raw[1] as int);
    default:
      return null;
  }
}
