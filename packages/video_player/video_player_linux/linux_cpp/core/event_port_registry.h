// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// Thread-safe texture_id → EventPort* registry, shared between the FFI
// layer (Dart calling vp_register_port / vp_unregister_port) and the
// player implementation (which owns its EventPort as a member and
// registers it under its texture id at construction).
//
// Race handling: with the async-create flow the GTK plugin returns a
// texture id to Dart immediately and constructs the VideoPlayer
// (which owns the EventPort) on a worker thread. Dart typically calls
// vp_register_port (to hand its RawReceivePort's native port to native)
// before the VideoPlayer finishes being built. The registry buffers
// pending Dart ports in `pending_dart_port_` and flushes them onto the
// EventPort as soon as Register() lands.
#pragma once

#include <cstdint>
#include <mutex>
#include <unordered_map>

#include "event_port.h"

namespace video_player_linux {

class EventPortRegistry {
 public:
  static EventPortRegistry& Instance();

  // Called by VideoPlayer's ctor (on any thread). Any buffered Dart
  // port is attached immediately.
  void Register(int64_t texture_id, EventPort* port);
  void Unregister(int64_t texture_id);

  // Called from FFI (the Dart side's vp_register_port / vp_unregister_port
  // thunks). If the EventPort isn't registered yet, the dart port is
  // buffered in `pending_dart_port_` and flushed later by Register().
  void Attach(int64_t texture_id, Dart_Port_DL dart_port);
  void Detach(int64_t texture_id);

 private:
  EventPortRegistry() = default;
  std::mutex mu_;
  std::unordered_map<int64_t, EventPort*> map_;
  std::unordered_map<int64_t, Dart_Port_DL> pending_dart_port_;
};

}  // namespace video_player_linux
