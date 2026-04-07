// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  dartTestOut: 'test/test_api.g.dart',
  cppHeaderOut: 'linux_cpp/messages.h',
  cppSourceOut: 'linux_cpp/messages.cpp',
  cppOptions: CppOptions(
    namespace: 'video_player_linux',
  ),
  copyrightHeader: 'pigeons/copyright.txt',
))
@HostApi(dartHostTestHandler: 'TestHostVideoPlayerApi')
abstract class LinuxVideoPlayerApi {
  // ──────────────────────────────────────────────────────────────────────
  // Existing methods
  // ──────────────────────────────────────────────────────────────────────

  /// Initializes the video player.
  void initialize();

  /// Creates a new instance of the video player.
  /// Returns the textureId of the created player.
  int create(String? asset, String? uri, Map<String?, String?> httpHeaders);

  /// Disposes the video player with the given textureId.
  void dispose(int textureId);

  /// Sets the looping state of the video player with the given textureId.
  void setLooping(int textureId, bool isLooping);

  /// Sets the volume of the video player with the given textureId.
  void setVolume(int textureId, double volume);

  /// Sets the playback speed of the video player with the given textureId.
  void setPlaybackSpeed(int textureId, double speed);

  /// Starts playing the video in the video player with the given textureId.
  void play(int textureId);

  /// Gets the current position of the video player with the given textureId.
  /// Returns the position in milliseconds.
  int getPosition(int textureId);

  /// Seeks to the given position in the video player with the given textureId.
  /// The position is in milliseconds.
  void seekTo(int textureId, int position);

  /// Pauses the video in the video player with the given textureId.
  void pause(int textureId);

  // ──────────────────────────────────────────────────────────────────────
  // Phase 1 — Foundation
  // ──────────────────────────────────────────────────────────────────────

  /// Returns the number of audio tracks in the current media.
  int getAudioTrackCount(int textureId);

  /// Switches to the audio track at [trackIndex].
  void setAudioTrack(int textureId, int trackIndex);

  /// Sets the output channel count (1=mono, 2=stereo, 6=5.1, 8=7.1).
  void setOutputChannels(int textureId, int channels);

  /// Toggles native mute (preserves volume level for unmute).
  void setMute(int textureId, bool mute);

  /// Returns true if the media has no video stream.
  bool isAudioOnly(int textureId);

  // ──────────────────────────────────────────────────────────────────────
  // Phase 2 — Quality & Tuning
  // ──────────────────────────────────────────────────────────────────────

  /// Sets the video scaling algorithm (0=nearest, 1=bilinear, 4=lanczos).
  void setScaleMethod(int textureId, int method);

  /// Sets the A/V sync offset in milliseconds. Positive delays audio.
  void setAVOffset(int textureId, int offsetMs);

  /// Enables or disables subtitle rendering.
  void setSubtitlesEnabled(int textureId, bool enabled);

  /// Returns the number of subtitle tracks in the current media.
  int getSubtitleTrackCount(int textureId);

  /// Switches to the subtitle track at [trackIndex].
  void setSubtitleTrack(int textureId, int trackIndex);

  /// Sets an external subtitle file URI (.srt, .sub, .vtt). Pass an empty
  /// string to clear.
  void setSubtitleUri(int textureId, String uri);

  /// Sets the subtitle font (Pango format, e.g., "Sans Bold 18").
  void setSubtitleFont(int textureId, String fontDesc);

  /// Sets a named channel mix preset
  /// ("stereo" | "driver" | "night" | "rear" | "surround").
  void setChannelMixPreset(int textureId, String preset);

  // ──────────────────────────────────────────────────────────────────────
  // Phase 3 — Premium Features
  // ──────────────────────────────────────────────────────────────────────

  /// Sets the 10-band equalizer. [bands] must have 10 elements,
  /// each clamped to -24.0..+12.0 dB.
  void setEqualizer(int textureId, List<double> bands);

  /// Sets video brightness, contrast, saturation, hue (each -1.0..+1.0
  /// except contrast/saturation which are 0..2 with 1 = identity).
  void setVideoBalance(int textureId, double brightness, double contrast,
      double saturation, double hue);

  /// Enables/disables encoded audio passthrough (AC3/DTS over HDMI).
  void setAudioPassthrough(int textureId, bool enabled);

  /// Sets a custom downmix matrix (row-major, [outChannels] × [inChannels]).
  void setChannelMixMatrix(
      int textureId, int inChannels, int outChannels, List<double> matrix);
}
