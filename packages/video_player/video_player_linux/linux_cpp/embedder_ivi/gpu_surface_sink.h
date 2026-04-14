// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// ivi-homescreen TextureSink implementation backed by a
// FlutterDesktopGpuSurfaceDescriptor / flutter::GpuSurfaceTexture pair.
// This sink owns its NV12 shader: ivi-homescreen's compositor keeps an
// EGL context current on the streaming thread, so the shader can run
// directly inside AcceptFrame().
#pragma once

#include <memory>
#include <mutex>

#include <GLES3/gl3.h>

#include <flutter/plugin_registrar_homescreen.h>
#include <flutter/texture_registrar.h>

#include "../core/nv12.h"
#include "../core/texture_sink.h"

namespace video_player_linux {

class GpuSurfaceSink : public TextureSink {
 public:
  explicit GpuSurfaceSink(flutter::PluginRegistrarDesktop* registrar);
  ~GpuSurfaceSink() override;

  // TextureSink
  int64_t Register() override;
  void Resize(int width, int height) override;
  void AcceptFrame(const GstVideoFrame* frame) override;
  void Unregister() override;

 private:
  flutter::PluginRegistrarDesktop* registrar_;
  std::unique_ptr<nv12::Shader> shader_;
  std::unique_ptr<flutter::GpuSurfaceTexture> gpu_surface_texture_;
  FlutterDesktopGpuSurfaceDescriptor descriptor_{};
  GLuint gl_texture_id_{0};
  int64_t flutter_texture_id_{0};
  // Pending dimensions captured by Resize() before Register() runs.
  // ivi-homescreen's RegisterExternalTexture snapshots the GL texture id
  // and the descriptor's width/height at register time — registering
  // with a 1x1 placeholder would pin the embedder to that id forever,
  // so we defer shader creation until the real dimensions arrive.
  int pending_width_{0};
  int pending_height_{0};
  std::mutex mu_;
};

// Factory override for embedder_ivi — this is the body the linker needs for
// `MakeTextureSinkForEmbedder` (declared in core/texture_sink.h).
std::unique_ptr<TextureSink> MakeTextureSinkForEmbedder(void* registrar);

}  // namespace video_player_linux
