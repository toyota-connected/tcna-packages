// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// Abstract interface between the embedder-agnostic core (video_player.cc)
// and whichever Flutter embedder glue layer is linked: GTK (FlTextureGL /
// FlPixelBufferTexture) or ivi-homescreen (FlutterDesktopGpuSurfaceDescriptor).
// The *sink* owns the entire texture/render pipeline: under stock Flutter
// Linux (GTK) we cannot run the NV12 shader on the GStreamer streaming
// thread because no GL context is current there, so the GTK sink does CPU
// conversion into a pixel-buffer texture. The ivi sink still runs its own
// NV12 shader; the core only hands it borrowed GstVideoFrame pointers.
//
// `Register()` and `Resize()` are deliberately split so the plugin glue
// can hand Dart a texture id synchronously from the platform thread while
// a worker thread discovers media info and constructs the VideoPlayer
// (which then calls Resize() once the real dimensions are known). This
// keeps the pigeon `create` handler non-blocking — tab switches and
// other platform-thread work don't stall behind GstDiscoverer.
#pragma once

#include <cstdint>
#include <memory>

extern "C" {
#include <gst/gst.h>
#include <gst/video/video.h>
}

namespace video_player_linux {

class TextureSink {
 public:
  virtual ~TextureSink() = default;

  // Register the texture with the embedder and return the Flutter-side
  // texture id, or 0 on failure. Must be called on the platform thread
  // before the texture is handed to Dart. Idempotent calls return the
  // same id.
  virtual int64_t Register() = 0;

  // Set / update frame dimensions. Reallocates the backing buffer as
  // needed. Safe to call from any thread and idempotent — passing the
  // same dimensions as the previous call is cheap.
  virtual void Resize(int width, int height) = 0;

  // Called from the GStreamer streaming thread each time a decoded frame
  // is available. `frame` is borrowed — do not hold past this call.
  virtual void AcceptFrame(const GstVideoFrame* frame) = 0;

  // Release embedder-held texture resources. Called from Dispose() on
  // the Flutter platform thread.
  virtual void Unregister() = 0;

  // GStreamer pixel format the sink wants the pipeline to deliver.
  // Default is "NV12" (ivi sink's shader input); the GTK sink overrides
  // to "RGBA" because openh264dec's caps negotiation is buggy with NV12.
  virtual const char* PreferredFormat() const { return "NV12"; }
};

// Glue-supplied factory. `registrar` is whatever the embedder handed the
// plugin at register time (`FlPluginRegistrar*` on GTK,
// `flutter::PluginRegistrarDesktop*` on ivi-homescreen). For audio-only
// players the core calls MakeNullTextureSink() directly.
std::unique_ptr<TextureSink> MakeTextureSinkForEmbedder(void* registrar);

// No-op sink for audio-only players. The Dart side skips the Texture
// widget for synthetic ids (>= 0x7F000000), so no frames ever arrive;
// the sink just remembers the id and reports it from Register().
std::unique_ptr<TextureSink> MakeNullTextureSink(int64_t synthetic_id);

}  // namespace video_player_linux
