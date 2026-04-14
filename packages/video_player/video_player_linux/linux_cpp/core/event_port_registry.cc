// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0

#include "event_port_registry.h"

namespace video_player_linux {

EventPortRegistry& EventPortRegistry::Instance() {
  static EventPortRegistry instance;
  return instance;
}

void EventPortRegistry::Register(int64_t texture_id, EventPort* port) {
  std::lock_guard<std::mutex> lk(mu_);
  map_[texture_id] = port;
  // Flush any pending Dart port that arrived before the EventPort existed.
  if (port) {
    if (auto it = pending_dart_port_.find(texture_id);
        it != pending_dart_port_.end()) {
      port->Attach(it->second);
      pending_dart_port_.erase(it);
    }
  }
}

void EventPortRegistry::Unregister(int64_t texture_id) {
  std::lock_guard<std::mutex> lk(mu_);
  map_.erase(texture_id);
  pending_dart_port_.erase(texture_id);
}

void EventPortRegistry::Attach(int64_t texture_id, Dart_Port_DL dart_port) {
  std::lock_guard<std::mutex> lk(mu_);
  auto it = map_.find(texture_id);
  if (it != map_.end() && it->second) {
    it->second->Attach(dart_port);
  } else {
    // VideoPlayer for this texture hasn't registered yet (async-create
    // is still constructing it on a worker thread). Buffer the Dart
    // port; Register() will flush it when the EventPort lands.
    pending_dart_port_[texture_id] = dart_port;
  }
}

void EventPortRegistry::Detach(int64_t texture_id) {
  std::lock_guard<std::mutex> lk(mu_);
  auto it = map_.find(texture_id);
  if (it != map_.end() && it->second) {
    it->second->Detach();
  }
  // Also clear any buffered-but-unflushed Dart port so a racy
  // dispose-before-construct doesn't leave a dangling entry.
  pending_dart_port_.erase(texture_id);
}

}  // namespace video_player_linux
