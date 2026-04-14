// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// ivi-homescreen TextureSink implementation backed by a
// FlutterDesktopGpuSurfaceDescriptor / flutter::GpuSurfaceTexture pair.
// Owns its own NV12 shader; runs the shader directly on the GStreamer
// streaming thread inside AcceptFrame().

#include "gpu_surface_sink.h"

#include <cstddef>
#include <cstdlib>
#include <mutex>

extern "C" {
#include <gst/video/video.h>
}

namespace video_player_linux {

// Serialize GL context use across all GpuSurfaceSink instances. ivi's
// EGL context can only be current on one thread at a time — parallel
// streams sharing the registrar's resource context must not overlap.
static std::mutex& texture_context_mutex() {
  static std::mutex m;
  return m;
}

GpuSurfaceSink::GpuSurfaceSink(flutter::PluginRegistrarDesktop* registrar)
    : registrar_(registrar) {}

GpuSurfaceSink::~GpuSurfaceSink() {
  if (flutter_texture_id_ != 0 || shader_) {
    Unregister();
  }
}

int64_t GpuSurfaceSink::Register() {
  std::lock_guard<std::mutex> lk(mu_);
  if (flutter_texture_id_ != 0) {
    // Idempotent: already registered.
    return flutter_texture_id_;
  }

  // ivi-homescreen's FlutterDesktopTextureRegistrarRegisterExternalTexture
  // snapshots `*descriptor->handle` (the GL texture id) and descriptor's
  // width/height at register time and uses THAT id as the Flutter texture
  // id for the lifetime of the registration. If we registered with a 1x1
  // placeholder first and then rebuilt the shader at real dimensions, the
  // embedder would keep rendering the dead placeholder's gl id — visible
  // as audio-only-no-video. So the caller (plugin Create) must call
  // Resize() with the real stream dimensions BEFORE Register(), and we
  // build the shader here at those dimensions.
  const int w = pending_width_ > 0 ? pending_width_ : 1;
  const int h = pending_height_ > 0 ? pending_height_ : 1;
  const bool double_buf = std::getenv("VIDEO_PLAYER_DOUBLE_BUFFER") != nullptr;
  {
    std::lock_guard<std::mutex> ctx_lock(texture_context_mutex());
    registrar_->texture_registrar()->TextureMakeCurrent();
    shader_ = std::make_unique<nv12::Shader>(w, h, double_buf);
    gl_texture_id_ = shader_->textureId;
    registrar_->texture_registrar()->TextureClearCurrent();
  }

  descriptor_.struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
  descriptor_.handle = &gl_texture_id_;
  descriptor_.width = static_cast<size_t>(w);
  descriptor_.height = static_cast<size_t>(h);
  descriptor_.visible_width = static_cast<size_t>(w);
  descriptor_.visible_height = static_cast<size_t>(h);
  descriptor_.format = kFlutterDesktopPixelFormatRGBA8888;
  descriptor_.release_callback = [](void* /* release_context */) {};
  descriptor_.release_context = this;

  // NOTE: do NOT acquire mu_ inside this callback. ivi's
  // FlutterDesktopTextureRegistrarRegisterExternalTexture invokes this
  // synchronously from inside RegisterTexture() below — taking mu_ here
  // would self-deadlock on the non-recursive mutex we already hold.
  // descriptor_ is a fixed struct member; its address is stable for the
  // sink's lifetime, so returning &descriptor_ without a lock is safe.
  // Field updates in Resize() may race with ivi's field reads on the
  // render thread, but the worst case is a single frame with torn
  // dimensions — no deadlock, no crash.
  gpu_surface_texture_ = std::make_unique<flutter::GpuSurfaceTexture>(
      kFlutterDesktopGpuSurfaceTypeGlTexture2D,
      [this](size_t /* width */, size_t /* height */)
          -> const FlutterDesktopGpuSurfaceDescriptor* {
        return &descriptor_;
      });

  flutter::TextureVariant texture_variant = *gpu_surface_texture_;
  flutter_texture_id_ =
      registrar_->texture_registrar()->RegisterTexture(&texture_variant);
  if (flutter_texture_id_ == 0) {
    flutter_texture_id_ = static_cast<int64_t>(shader_->textureId);
  }
  return flutter_texture_id_;
}

void GpuSurfaceSink::Resize(int width, int height) {
  if (width <= 0 || height <= 0) {
    return;
  }
  std::lock_guard<std::mutex> lk(mu_);

  // Pre-registration path: just record the dimensions. Register() will
  // pick them up and build the shader. This is how the ivi plugin Create
  // handler hands us real dimensions from GstDiscoverer before asking
  // for a Flutter texture id.
  if (flutter_texture_id_ == 0) {
    pending_width_ = width;
    pending_height_ = height;
    return;
  }

  // Post-registration path: if VideoPlayer ctor calls Resize() again
  // with the same dimensions we already registered, there's nothing to
  // do. If it differs we can't re-register with ivi (the Flutter texture
  // id was burned in at Register time), so we keep the existing id and
  // just swap the shader in-place.
  if (shader_ && static_cast<int>(descriptor_.width) == width &&
      static_cast<int>(descriptor_.height) == height) {
    return;
  }
  const bool double_buf = std::getenv("VIDEO_PLAYER_DOUBLE_BUFFER") != nullptr;
  {
    std::lock_guard<std::mutex> ctx_lock(texture_context_mutex());
    registrar_->texture_registrar()->TextureMakeCurrent();
    shader_ = std::make_unique<nv12::Shader>(width, height, double_buf);
    gl_texture_id_ = shader_->textureId;
    registrar_->texture_registrar()->TextureClearCurrent();
  }
  descriptor_.width = static_cast<size_t>(width);
  descriptor_.height = static_cast<size_t>(height);
  descriptor_.visible_width = static_cast<size_t>(width);
  descriptor_.visible_height = static_cast<size_t>(height);
}

void GpuSurfaceSink::AcceptFrame(const GstVideoFrame* frame) {
  if (!frame || frame->info.finfo == nullptr) {
    return;
  }
  std::lock_guard<std::mutex> lk(mu_);
  if (!shader_) {
    return;
  }

  // Upload + convert + blit happen on ivi's shared GL resource context,
  // which can only be current on one thread at a time.
  {
    std::lock_guard<std::mutex> ctx_lock(texture_context_mutex());
    registrar_->texture_registrar()->TextureMakeCurrent();

    glBindVertexArray(shader_->vertex_arr_id_);

    if (const guint n_planes = GST_VIDEO_INFO_N_PLANES(&frame->info);
        n_planes == 2) {
      // NV12 path
      shader_->load_pixels(GST_VIDEO_FRAME_PLANE_DATA(frame, 0),
                           GST_VIDEO_FRAME_PLANE_DATA(frame, 1),
                           GST_VIDEO_FRAME_COMP_PSTRIDE(frame, 0),
                           GST_VIDEO_FRAME_PLANE_STRIDE(frame, 0),
                           GST_VIDEO_FRAME_COMP_PSTRIDE(frame, 1),
                           GST_VIDEO_FRAME_PLANE_STRIDE(frame, 1));
    } else {
      // RGB fallback
      shader_->load_rgb_pixels(GST_VIDEO_FRAME_PLANE_DATA(frame, 0));
    }

    glBindFramebuffer(GL_FRAMEBUFFER, shader_->render_target());
    shader_->draw_core();
    if (shader_->double_buffer) {
      shader_->blit_to_front();
    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindVertexArray(0);

    registrar_->texture_registrar()->TextureClearCurrent();
  }

  if (flutter_texture_id_ != 0) {
    registrar_->texture_registrar()->MarkTextureFrameAvailable(
        flutter_texture_id_);
  }
}

void GpuSurfaceSink::Unregister() {
  std::lock_guard<std::mutex> lk(mu_);
  if (flutter_texture_id_ != 0) {
    registrar_->texture_registrar()->UnregisterTexture(flutter_texture_id_);
    flutter_texture_id_ = 0;
  }
  gpu_surface_texture_.reset();
  // Shader destruction makes GL delete calls — context must be current.
  if (shader_) {
    std::lock_guard<std::mutex> ctx_lock(texture_context_mutex());
    registrar_->texture_registrar()->TextureMakeCurrent();
    shader_.reset();
    registrar_->texture_registrar()->TextureClearCurrent();
  }
  descriptor_ = FlutterDesktopGpuSurfaceDescriptor{};
  gl_texture_id_ = 0;
}

std::unique_ptr<TextureSink> MakeTextureSinkForEmbedder(void* registrar) {
  return std::make_unique<GpuSurfaceSink>(
      static_cast<flutter::PluginRegistrarDesktop*>(registrar));
}

}  // namespace video_player_linux
