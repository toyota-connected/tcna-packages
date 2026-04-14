// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// GTK (stock Flutter Linux) TextureSink implementation backed by an
// FlPixelBufferTexture subclass. Under GTK there is no GL context current
// on the GStreamer streaming thread, so the sink performs a CPU NV12→RGBA
// conversion into a buffer owned by an FlPixelBufferTexture subclass and
// calls fl_texture_registrar_mark_texture_frame_available(). Flutter's
// compositor pulls the RGBA buffer back via the overridden copy_pixels
// vfunc on the render thread.
#pragma once

#include <flutter_linux/flutter_linux.h>

extern "C" {
#include <gst/video/video.h>
}

#include <cstdint>
#include <memory>

#include "../core/texture_sink.h"

namespace video_player_linux {

class FlPixelBufferSink : public TextureSink {
 public:
  explicit FlPixelBufferSink(FlPluginRegistrar* registrar);
  ~FlPixelBufferSink() override;

  int64_t Register() override;
  void Resize(int width, int height) override;
  void AcceptFrame(const GstVideoFrame* frame) override;
  void Unregister() override;
  const char* PreferredFormat() const override { return "RGBA"; }

 private:
  FlPluginRegistrar* registrar_;
  FlTextureRegistrar* texture_registrar_{};
  // Our FlPixelBufferTexture GObject subclass. Owns the RGBA CPU buffer.
  FlTexture* texture_{nullptr};
  int64_t flutter_texture_id_{0};
  int width_{0};
  int height_{0};
};

}  // namespace video_player_linux
