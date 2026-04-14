// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// extern "C" entry points looked up by the Dart side via
// DynamicLibrary.process(). Same ABI under both embedders — the zero-copy
// event plane is intentionally embedder-agnostic.

#include <cstdint>

#include "event_port_registry.h"
#include "third_party/dart/dart_api_dl.h"

#if defined(_WIN32)
#define VP_EXPORT __declspec(dllexport)
#else
#define VP_EXPORT __attribute__((visibility("default")))
#endif

extern "C" {

VP_EXPORT intptr_t vp_init_api_dl(void* data) {
  return Dart_InitializeApiDL(data);
}

VP_EXPORT void vp_register_port(int64_t texture_id, int64_t dart_port) {
  video_player_linux::EventPortRegistry::Instance().Attach(
      texture_id, static_cast<Dart_Port_DL>(dart_port));
}

VP_EXPORT void vp_unregister_port(int64_t texture_id) {
  video_player_linux::EventPortRegistry::Instance().Detach(texture_id);
}

}  // extern "C"
