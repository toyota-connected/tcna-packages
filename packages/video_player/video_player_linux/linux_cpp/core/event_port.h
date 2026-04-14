// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// Per-player native port used to post events into the Dart isolate without
// going through an EventChannel / StandardMessageCodec. One Dart_Port is
// registered per texture id from Dart at create() time; the native player
// posts tagged Dart_CObject arrays directly (Dart_PostCObject_DL is
// thread-safe and can be called from the GStreamer streaming thread).
#pragma once

#include <atomic>
#include <cstdint>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "third_party/dart/dart_api_dl.h"

namespace video_player_linux {

// Event tag values — must stay in sync with lib/src/ffi/event_decoder.dart.
enum EventTag : int32_t {
  kInitialized = 0,
  kCompleted = 1,
  kBufferingUpdate = 2,
  kBufferingStart = 3,
  kBufferingEnd = 4,
  kIsPlayingStateUpdate = 5,
  kAlbumArt = 6,
  kMediaMetadata = 7,
  kAudioInfo = 8,
  kPositionUpdate = 9,
};

class EventPort {
 public:
  EventPort() = default;
  ~EventPort() = default;

  EventPort(const EventPort&) = delete;
  EventPort& operator=(const EventPort&) = delete;

  // Attach / detach a Dart port. Dart calls vp_register_port at create()
  // and vp_unregister_port at dispose(); the ffi_exports glue routes those
  // calls here.
  //
  // Attach replays any cached `initialized` event that was posted before
  // Dart registered its port. Under ivi-homescreen's synchronous Create
  // flow the pipeline's PAUSED transition (which triggers SendInitialized)
  // can race ahead of the Dart-side vp_register_port call, so without a
  // replay the very first `initialized` event is silently dropped and
  // `VideoPlayerController.initialize()` hangs forever.
  void Attach(Dart_Port_DL port);
  void Detach() { port_.store(0); }
  bool IsAttached() const { return port_.load() != 0; }

  // Event senders. All are thread-safe; if no port is attached (player
  // disposed while a late bus message races) the call is a silent no-op.

  void SendInitialized(int32_t duration_ms,
                       int32_t width,
                       int32_t height,
                       int32_t rotation);
  void SendCompleted();
  // `ranges_ms` is a flat array of [start0, end0, start1, end1, ...].
  void SendBufferingUpdate(const std::vector<int32_t>& ranges_ms);
  void SendBufferingStart();
  void SendBufferingEnd();
  void SendIsPlayingStateUpdate(bool is_playing);
  // Album art bytes are handed off zero-copy via Dart_CObject_kExternalTypedData;
  // the caller relinquishes ownership of `data` — the finalizer frees it
  // with `free()`, so `data` must come from malloc/realloc (not `new[]` /
  // GstBuffer-mapped memory). Copy to a heap buffer before calling if
  // necessary.
  void SendAlbumArt(const std::string& mime_type,
                    uint8_t* data,
                    size_t length);
  void SendMediaMetadata(const std::string& title,
                         const std::string& artist,
                         const std::string& album,
                         const std::string& album_artist,
                         const std::string& genre,
                         int32_t track_number);
  void SendAudioInfo(const std::string& codec,
                     int32_t channels,
                     int32_t sample_rate);
  void SendPositionUpdate(int64_t position_ms);

 private:
  std::atomic<Dart_Port_DL> port_{0};

  // Cached `initialized` payload. Populated by SendInitialized when no
  // Dart port is yet attached; replayed by Attach() once the port lands.
  struct InitializedPayload {
    int32_t duration_ms;
    int32_t width;
    int32_t height;
    int32_t rotation;
  };
  std::mutex pending_mu_;
  std::optional<InitializedPayload> pending_initialized_;
};

}  // namespace video_player_linux
