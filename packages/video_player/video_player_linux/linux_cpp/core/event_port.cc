// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0

#include "event_port.h"

#include <cstdlib>
#include <cstring>
#include <vector>

namespace video_player_linux {

namespace {

// Helpers for constructing Dart_CObject values on the stack. Each event is
// a Dart_CObject_kArray whose first element is an int32 tag.

inline Dart_CObject MakeInt32(int32_t v) {
  Dart_CObject o{};
  o.type = Dart_CObject_kInt32;
  o.value.as_int32 = v;
  return o;
}

inline Dart_CObject MakeInt64(int64_t v) {
  Dart_CObject o{};
  o.type = Dart_CObject_kInt64;
  o.value.as_int64 = v;
  return o;
}

inline Dart_CObject MakeBool(bool v) {
  Dart_CObject o{};
  o.type = Dart_CObject_kBool;
  o.value.as_bool = v;
  return o;
}

inline Dart_CObject MakeString(const char* s) {
  Dart_CObject o{};
  o.type = Dart_CObject_kString;
  o.value.as_string = const_cast<char*>(s);
  return o;
}

// Post a top-level array. `elements` are pointers into a local array of
// Dart_CObject values; Dart_PostCObject_DL serializes and copies before
// returning (except for kExternalTypedData, whose `data`/`peer` persist
// until the finalizer fires).
inline bool PostArray(Dart_Port_DL port,
                      Dart_CObject** elements,
                      intptr_t count) {
  Dart_CObject root{};
  root.type = Dart_CObject_kArray;
  root.value.as_array.length = count;
  root.value.as_array.values = elements;
  return Dart_PostCObject_DL(port, &root);
}

// Finalizer for album-art zero-copy payloads. `peer` is a heap-allocated
// uint8_t* whose address is whatever we passed as peer at post time. We
// store a small struct so the finalizer can free both the envelope and
// the data.
struct ExternalPayload {
  uint8_t* data;
};

void ExternalFinalizer(void* /*isolate_callback_data*/, void* peer) {
  auto* p = static_cast<ExternalPayload*>(peer);
  std::free(p->data);
  delete p;
}

}  // namespace

void EventPort::Attach(Dart_Port_DL port) {
  port_.store(port);
  // Replay a deferred `initialized` event (see header comment).
  std::optional<InitializedPayload> replay;
  {
    std::lock_guard<std::mutex> lk(pending_mu_);
    replay = pending_initialized_;
    pending_initialized_.reset();
  }
  if (replay && port != 0) {
    Dart_CObject tag = MakeInt32(kInitialized);
    Dart_CObject dur = MakeInt32(replay->duration_ms);
    Dart_CObject w = MakeInt32(replay->width);
    Dart_CObject h = MakeInt32(replay->height);
    Dart_CObject r = MakeInt32(replay->rotation);
    Dart_CObject* elements[] = {&tag, &dur, &w, &h, &r};
    PostArray(port, elements, 5);
  }
}

void EventPort::SendInitialized(int32_t duration_ms,
                                int32_t width,
                                int32_t height,
                                int32_t rotation) {
  const Dart_Port_DL port = port_.load();
  if (port == 0) {
    // Dart port not attached yet. Cache so Attach() can replay.
    std::lock_guard<std::mutex> lk(pending_mu_);
    pending_initialized_ = InitializedPayload{duration_ms, width, height,
                                              rotation};
    return;
  }
  Dart_CObject tag = MakeInt32(kInitialized);
  Dart_CObject dur = MakeInt32(duration_ms);
  Dart_CObject w = MakeInt32(width);
  Dart_CObject h = MakeInt32(height);
  Dart_CObject r = MakeInt32(rotation);
  Dart_CObject* elements[] = {&tag, &dur, &w, &h, &r};
  PostArray(port, elements, 5);
}

void EventPort::SendCompleted() {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kCompleted);
  Dart_CObject* elements[] = {&tag};
  PostArray(port, elements, 1);
}

void EventPort::SendBufferingUpdate(const std::vector<int32_t>& ranges_ms) {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kBufferingUpdate);
  Dart_CObject data{};
  data.type = Dart_CObject_kTypedData;
  data.value.as_typed_data.type = Dart_TypedData_kInt32;
  data.value.as_typed_data.length =
      static_cast<intptr_t>(ranges_ms.size() * sizeof(int32_t));
  data.value.as_typed_data.values =
      reinterpret_cast<const uint8_t*>(ranges_ms.data());
  Dart_CObject* elements[] = {&tag, &data};
  PostArray(port, elements, 2);
}

void EventPort::SendBufferingStart() {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kBufferingStart);
  Dart_CObject* elements[] = {&tag};
  PostArray(port, elements, 1);
}

void EventPort::SendBufferingEnd() {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kBufferingEnd);
  Dart_CObject* elements[] = {&tag};
  PostArray(port, elements, 1);
}

void EventPort::SendIsPlayingStateUpdate(bool is_playing) {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kIsPlayingStateUpdate);
  Dart_CObject v = MakeBool(is_playing);
  Dart_CObject* elements[] = {&tag, &v};
  PostArray(port, elements, 2);
}

void EventPort::SendAlbumArt(const std::string& mime_type,
                             uint8_t* data,
                             size_t length) {
  const Dart_Port_DL port = port_.load();
  if (port == 0) {
    // Not attached — caller gave us ownership; release.
    std::free(data);
    return;
  }
  auto* peer = new ExternalPayload{data};

  Dart_CObject tag = MakeInt32(kAlbumArt);
  Dart_CObject mime = MakeString(mime_type.c_str());
  Dart_CObject bytes{};
  bytes.type = Dart_CObject_kExternalTypedData;
  bytes.value.as_external_typed_data.type = Dart_TypedData_kUint8;
  bytes.value.as_external_typed_data.length = static_cast<intptr_t>(length);
  bytes.value.as_external_typed_data.data = data;
  bytes.value.as_external_typed_data.peer = peer;
  bytes.value.as_external_typed_data.callback = &ExternalFinalizer;
  Dart_CObject* elements[] = {&tag, &mime, &bytes};

  if (!PostArray(port, elements, 3)) {
    // Post failed (port closed mid-call); the finalizer will NOT run. Release.
    std::free(data);
    delete peer;
  }
}

void EventPort::SendMediaMetadata(const std::string& title,
                                  const std::string& artist,
                                  const std::string& album,
                                  const std::string& album_artist,
                                  const std::string& genre,
                                  int32_t track_number) {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kMediaMetadata);
  Dart_CObject t = MakeString(title.c_str());
  Dart_CObject a = MakeString(artist.c_str());
  Dart_CObject al = MakeString(album.c_str());
  Dart_CObject aa = MakeString(album_artist.c_str());
  Dart_CObject g = MakeString(genre.c_str());
  Dart_CObject tn = MakeInt32(track_number);
  Dart_CObject* elements[] = {&tag, &t, &a, &al, &aa, &g, &tn};
  PostArray(port, elements, 7);
}

void EventPort::SendAudioInfo(const std::string& codec,
                              int32_t channels,
                              int32_t sample_rate) {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kAudioInfo);
  Dart_CObject c = MakeString(codec.c_str());
  Dart_CObject ch = MakeInt32(channels);
  Dart_CObject sr = MakeInt32(sample_rate);
  Dart_CObject* elements[] = {&tag, &c, &ch, &sr};
  PostArray(port, elements, 4);
}

void EventPort::SendPositionUpdate(int64_t position_ms) {
  const Dart_Port_DL port = port_.load();
  if (port == 0) return;
  Dart_CObject tag = MakeInt32(kPositionUpdate);
  Dart_CObject p = MakeInt64(position_ms);
  Dart_CObject* elements[] = {&tag, &p};
  PostArray(port, elements, 2);
}

}  // namespace video_player_linux
