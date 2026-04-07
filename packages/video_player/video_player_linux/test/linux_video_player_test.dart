// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player_linux/video_player_linux.dart';

import 'test_api.g.dart';
import 'linux_video_player_test.mocks.dart';

@GenerateMocks(<Type>[TestHostVideoPlayerApi])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registration', () async {
    LinuxVideoPlayer.registerWith();
    expect(VideoPlayerPlatform.instance, isA<LinuxVideoPlayer>());
  });

  final LinuxVideoPlayer player = LinuxVideoPlayer();
  late MockTestHostVideoPlayerApi mockApi;

  setUp(() {
    mockApi = MockTestHostVideoPlayerApi();
    TestHostVideoPlayerApi.setup(mockApi);

    when(mockApi.create(any, any, any)).thenReturn(3);
    when(mockApi.getPosition(any)).thenReturn(234);
  });

  group('$LinuxVideoPlayer', () {
    test('init', () async {
      await player.init();
      verify(mockApi.initialize());
    });

    test('dispose', () async {
      await player.dispose(1);
      verify(mockApi.dispose(1));
    });

    test('create with asset', () async {
      final int? textureId =
          await player.createWithOptions(VideoCreationOptions(
        dataSource: DataSource(
          sourceType: DataSourceType.asset,
          asset: 'someAsset',
        ),
        viewType: VideoViewType.textureView,
      ));
      verify(mockApi.create('someAsset', null, <String, String>{}));
      expect(textureId, 3);
    });

    test('create with asset from package', () async {
      await expectLater(
          () => player.createWithOptions(VideoCreationOptions(
                dataSource: DataSource(
                  sourceType: DataSourceType.asset,
                  asset: 'someAsset',
                  package: 'somePackage',
                ),
                viewType: VideoViewType.textureView,
              )),
          throwsA(isA<UnimplementedError>()));
    });

    test('create with network', () async {
      final int? textureId =
          await player.createWithOptions(VideoCreationOptions(
        dataSource: DataSource(
          sourceType: DataSourceType.network,
          uri: 'someUri',
        ),
        viewType: VideoViewType.textureView,
      ));
      verify(mockApi.create(null, 'someUri', <String, String>{}));
      expect(textureId, 3);
    });

    test('create with network (some headers)', () async {
      final int? textureId =
          await player.createWithOptions(VideoCreationOptions(
        dataSource: DataSource(
          sourceType: DataSourceType.network,
          uri: 'someUri',
          httpHeaders: <String, String>{'Authorization': 'Bearer token'},
        ),
        viewType: VideoViewType.textureView,
      ));
      verify(mockApi.create(
          null, 'someUri', <String, String>{'Authorization': 'Bearer token'}));
      expect(textureId, 3);
    });

    test('create with file', () async {
      final int? textureId =
          await player.createWithOptions(VideoCreationOptions(
        dataSource: DataSource(
          sourceType: DataSourceType.file,
          uri: 'someUri',
        ),
        viewType: VideoViewType.textureView,
      ));
      verify(mockApi.create(null, 'someUri', <String, String>{}));
      expect(textureId, 3);
    });

    test('create with file (some headers)', () async {
      final int? textureId =
          await player.createWithOptions(VideoCreationOptions(
        dataSource: DataSource(
          sourceType: DataSourceType.file,
          uri: 'someUri',
          httpHeaders: <String, String>{'Authorization': 'Bearer token'},
        ),
        viewType: VideoViewType.textureView,
      ));
      verify(mockApi.create(
          null, 'someUri', <String, String>{'Authorization': 'Bearer token'}));
      expect(textureId, 3);
    });
    test('setLooping', () async {
      await player.setLooping(1, true);
      verify(mockApi.setLooping(1, true));
    });

    test('play', () async {
      await player.play(1);
      verify(mockApi.play(1));
    });

    test('pause', () async {
      await player.pause(1);
      verify(mockApi.pause(1));
    });

    test('setVolume', () async {
      await player.setVolume(1, 0.7);
      verify(mockApi.setVolume(1, 0.7));
    });

    test('setPlaybackSpeed', () async {
      await player.setPlaybackSpeed(1, 1.5);
      verify(mockApi.setPlaybackSpeed(1, 1.5));
    });

    test('seekTo', () async {
      await player.seekTo(1, const Duration(milliseconds: 12345));
      verify(mockApi.seekTo(1, 12345));
    });

    test('getPosition', () async {
      final Duration position = await player.getPosition(1);
      verify(mockApi.getPosition(1));
      expect(position, const Duration(milliseconds: 234));
    });

    test('videoEventsFor', () async {
      const String mockChannel = 'flutter.io/videoPlayer/videoEvents123';
      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
          .defaultBinaryMessenger
          .setMockMessageHandler(
        mockChannel,
        (ByteData? message) async {
          final MethodCall methodCall =
              const StandardMethodCodec().decodeMethodCall(message);
          if (methodCall.method == 'listen') {
            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'initialized',
                      'duration': 98765,
                      'width': 1920,
                      'height': 1080,
                    }),
                    (ByteData? data) {});

            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'initialized',
                      'duration': 98765,
                      'width': 1920,
                      'height': 1080,
                      'rotationCorrection': 180,
                    }),
                    (ByteData? data) {});

            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'completed',
                    }),
                    (ByteData? data) {});

            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingUpdate',
                      'values': <List<dynamic>>[
                        <int>[0, 1234],
                        <int>[1235, 4000],
                      ],
                    }),
                    (ByteData? data) {});

            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingStart',
                    }),
                    (ByteData? data) {});

            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingEnd',
                    }),
                    (ByteData? data) {});

            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'isPlayingStateUpdate',
                      'isPlaying': true,
                    }),
                    (ByteData? data) {});

            await _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
                .defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'isPlayingStateUpdate',
                      'isPlaying': false,
                    }),
                    (ByteData? data) {});

            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else if (methodCall.method == 'cancel') {
            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      expect(
          player.videoEventsFor(123),
          emitsInOrder(<dynamic>[
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 98765),
              size: const Size(1920, 1080),
              rotationCorrection: 0,
            ),
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 98765),
              size: const Size(1920, 1080),
              rotationCorrection: 180,
            ),
            VideoEvent(eventType: VideoEventType.completed),
            VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                buffered: <DurationRange>[
                  DurationRange(
                    Duration.zero,
                    const Duration(milliseconds: 1234),
                  ),
                  DurationRange(
                    const Duration(milliseconds: 1235),
                    const Duration(milliseconds: 4000),
                  ),
                ]),
            VideoEvent(eventType: VideoEventType.bufferingStart),
            VideoEvent(eventType: VideoEventType.bufferingEnd),
            VideoEvent(
              eventType: VideoEventType.isPlayingStateUpdate,
              isPlaying: true,
            ),
            VideoEvent(
              eventType: VideoEventType.isPlayingStateUpdate,
              isPlaying: false,
            ),
          ]));
    });

    // ──────────────────────────────────────────────────────────────────
    // Phase 1 — audio control surface
    // ──────────────────────────────────────────────────────────────────

    test('getAudioTrackCount forwards to api', () async {
      when(mockApi.getAudioTrackCount(7)).thenReturn(3);
      expect(await player.getAudioTrackCount(7), 3);
      verify(mockApi.getAudioTrackCount(7));
    });

    test('setAudioTrack forwards to api', () async {
      await player.setAudioTrack(7, 1);
      verify(mockApi.setAudioTrack(7, 1));
    });

    test('setOutputChannels forwards to api', () async {
      await player.setOutputChannels(7, 6);
      verify(mockApi.setOutputChannels(7, 6));
    });

    test('setMute forwards to api', () async {
      await player.setMute(7, true);
      verify(mockApi.setMute(7, true));
    });

    test('isAudioOnly forwards to api', () async {
      when(mockApi.isAudioOnly(7)).thenReturn(true);
      expect(await player.isAudioOnly(7), isTrue);
      verify(mockApi.isAudioOnly(7));
    });

    // ──────────────────────────────────────────────────────────────────
    // Phase 2 — quality & tuning
    // ──────────────────────────────────────────────────────────────────

    test('setScaleMethod forwards to api', () async {
      await player.setScaleMethod(7, 4);
      verify(mockApi.setScaleMethod(7, 4));
    });

    test('setAVOffset forwards to api', () async {
      await player.setAVOffset(7, -50);
      verify(mockApi.setAVOffset(7, -50));
    });

    test('setSubtitlesEnabled forwards to api', () async {
      await player.setSubtitlesEnabled(7, true);
      verify(mockApi.setSubtitlesEnabled(7, true));
    });

    test('getSubtitleTrackCount forwards to api', () async {
      when(mockApi.getSubtitleTrackCount(7)).thenReturn(2);
      expect(await player.getSubtitleTrackCount(7), 2);
      verify(mockApi.getSubtitleTrackCount(7));
    });

    test('setSubtitleTrack forwards to api', () async {
      await player.setSubtitleTrack(7, 1);
      verify(mockApi.setSubtitleTrack(7, 1));
    });

    test('setSubtitleUri forwards to api', () async {
      await player.setSubtitleUri(7, 'file:///srt');
      verify(mockApi.setSubtitleUri(7, 'file:///srt'));
    });

    test('setSubtitleFont forwards to api', () async {
      await player.setSubtitleFont(7, 'Sans Bold 18');
      verify(mockApi.setSubtitleFont(7, 'Sans Bold 18'));
    });

    test('setChannelMixPreset forwards to api', () async {
      await player.setChannelMixPreset(7, 'driver');
      verify(mockApi.setChannelMixPreset(7, 'driver'));
    });

    // ──────────────────────────────────────────────────────────────────
    // Phase 3 — premium features
    // ──────────────────────────────────────────────────────────────────

    test('setEqualizer forwards 10 bands', () async {
      final bands = List<double>.generate(10, (i) => i.toDouble() - 4);
      await player.setEqualizer(7, bands);
      verify(mockApi.setEqualizer(7, bands));
    });

    test('setVideoBalance forwards all four params', () async {
      await player.setVideoBalance(7,
          brightness: 0.1, contrast: 1.2, saturation: 0.9, hue: 0.0);
      verify(mockApi.setVideoBalance(7, 0.1, 1.2, 0.9, 0.0));
    });

    test('setAudioPassthrough forwards', () async {
      await player.setAudioPassthrough(7, true);
      verify(mockApi.setAudioPassthrough(7, true));
    });

    test('setChannelMixMatrix forwards dimensions and matrix', () async {
      final matrix = <double>[
        1,
        0,
        0.707,
        0.707,
        0.707,
        0,
        0,
        1,
        0.707,
        0.707,
        0,
        0.707
      ];
      await player.setChannelMixMatrix(7,
          inChannels: 6, outChannels: 2, matrix: matrix);
      verify(mockApi.setChannelMixMatrix(7, 6, 2, matrix));
    });

    test('buildViewWithOptions returns SizedBox.shrink for audio-only IDs', () {
      final widget = player.buildViewWithOptions(
          VideoViewOptions(playerId: kLinuxAudioOnlyIdBase + 5));
      expect(widget, isA<SizedBox>());
    });
  });
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
T? _ambiguate<T>(T? value) => value;
