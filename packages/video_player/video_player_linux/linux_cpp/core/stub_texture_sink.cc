// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// Stub `MakeTextureSinkForEmbedder` used by CORE_ONLY builds (e.g. the
// package:hooks native-assets build, which has no flutter_linux on the
// include path). Returns a no-op sink. Any attempt to actually render
// video through this build is a configuration error — the build is only
// useful for exercising the FFI event plane.

#include "texture_sink.h"

namespace video_player_linux {

std::unique_ptr<TextureSink> MakeTextureSinkForEmbedder(void* /*registrar*/) {
  return MakeNullTextureSink(0);
}

}  // namespace video_player_linux
