// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// GTK (stock Flutter Linux) TextureSink: CPU NV12 → RGBA into an
// FlPixelBufferTexture subclass, then mark the texture frame available
// on the texture registrar. Flutter's compositor pulls the RGBA buffer
// via the overridden copy_pixels vfunc on the render thread.

#include "fl_pixel_buffer_sink.h"

#include <flutter_linux/flutter_linux.h>
#include <glib-object.h>

#include <cstdint>
#include <cstdlib>
#include <cstring>

extern "C" {
#include <gst/gst.h>
#include <gst/video/video.h>
}

#include "../core/log.h"

// ---------------------------------------------------------------------------
// VpPixelBufferTexture — FlPixelBufferTexture subclass that owns the RGBA
// CPU buffer produced by NV12ToRgbaBt601(). The C++ FlPixelBufferSink
// class below drives this GObject.
// ---------------------------------------------------------------------------

G_BEGIN_DECLS

#define VP_TYPE_PIXEL_BUFFER_TEXTURE (vp_pixel_buffer_texture_get_type())
G_DECLARE_FINAL_TYPE(VpPixelBufferTexture,
                     vp_pixel_buffer_texture,
                     VP,
                     PIXEL_BUFFER_TEXTURE,
                     FlPixelBufferTexture)

struct _VpPixelBufferTexture {
  FlPixelBufferTexture parent_instance;

  guint8* rgba_buf;  // malloc-owned
  gsize rgba_len;
  int width;
  int height;
  GMutex mutex;
};

static gboolean vp_pixel_buffer_texture_copy_pixels(FlPixelBufferTexture* tex,
                                                    const uint8_t** out_buf,
                                                    uint32_t* width,
                                                    uint32_t* height,
                                                    GError** error);

G_DEFINE_TYPE(VpPixelBufferTexture,
              vp_pixel_buffer_texture,
              fl_pixel_buffer_texture_get_type())

static void vp_pixel_buffer_texture_init(VpPixelBufferTexture* self) {
  self->rgba_buf = nullptr;
  self->rgba_len = 0;
  self->width = 0;
  self->height = 0;
  g_mutex_init(&self->mutex);
}

static void vp_pixel_buffer_texture_finalize(GObject* object) {
  VpPixelBufferTexture* self = VP_PIXEL_BUFFER_TEXTURE(object);
  if (self->rgba_buf) {
    std::free(self->rgba_buf);
    self->rgba_buf = nullptr;
  }
  g_mutex_clear(&self->mutex);
  G_OBJECT_CLASS(vp_pixel_buffer_texture_parent_class)->finalize(object);
}

static void vp_pixel_buffer_texture_class_init(
    VpPixelBufferTextureClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = vp_pixel_buffer_texture_finalize;
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels =
      vp_pixel_buffer_texture_copy_pixels;
}

static gboolean vp_pixel_buffer_texture_copy_pixels(FlPixelBufferTexture* tex,
                                                    const uint8_t** out_buf,
                                                    uint32_t* width,
                                                    uint32_t* height,
                                                    GError** /*error*/) {
  VpPixelBufferTexture* self = VP_PIXEL_BUFFER_TEXTURE(tex);
  g_mutex_lock(&self->mutex);
  *out_buf = self->rgba_buf;
  *width = static_cast<uint32_t>(self->width);
  *height = static_cast<uint32_t>(self->height);
  g_mutex_unlock(&self->mutex);
  return TRUE;
}

G_END_DECLS

// ---------------------------------------------------------------------------
// CPU NV12 → RGBA (BT.601). Straightforward reference loop. Upgrading to
// BT.709 and/or SIMD is a reasonable follow-up once the pipeline is wired.
// ---------------------------------------------------------------------------

namespace {

inline guint8 clamp_u8(int v) {
  if (v < 0) return 0;
  if (v > 255) return 255;
  return static_cast<guint8>(v);
}

void Nv12ToRgbaBt601(const GstVideoFrame* frame, guint8* out) {
  const int width = GST_VIDEO_FRAME_WIDTH(frame);
  const int height = GST_VIDEO_FRAME_HEIGHT(frame);
  const guint8* y_plane = static_cast<const guint8*>(
      GST_VIDEO_FRAME_PLANE_DATA(frame, 0));
  const guint8* uv_plane = static_cast<const guint8*>(
      GST_VIDEO_FRAME_PLANE_DATA(frame, 1));
  const int y_stride = GST_VIDEO_FRAME_PLANE_STRIDE(frame, 0);
  const int uv_stride = GST_VIDEO_FRAME_PLANE_STRIDE(frame, 1);

  for (int j = 0; j < height; ++j) {
    const guint8* y_row = y_plane + j * y_stride;
    const guint8* uv_row = uv_plane + (j / 2) * uv_stride;
    guint8* out_row = out + j * width * 4;
    for (int i = 0; i < width; ++i) {
      const int y = y_row[i];
      // UV is interleaved, 2x2 subsampled.
      const int uv_idx = (i / 2) * 2;
      const int u = uv_row[uv_idx + 0];
      const int v = uv_row[uv_idx + 1];
      const int c = y;
      const int d = u - 128;
      const int e = v - 128;
      // Fixed-point BT.601, matching:
      //   r = y + 1.402 * (v-128)
      //   g = y - 0.344 * (u-128) - 0.714 * (v-128)
      //   b = y + 1.772 * (u-128)
      // Scale coefficients by 1024 for integer math; round to nearest.
      const int r = (c * 1024 + 1436 * e + 512) >> 10;
      const int g = (c * 1024 - 352 * d - 731 * e + 512) >> 10;
      const int b = (c * 1024 + 1815 * d + 512) >> 10;
      out_row[i * 4 + 0] = clamp_u8(r);
      out_row[i * 4 + 1] = clamp_u8(g);
      out_row[i * 4 + 2] = clamp_u8(b);
      out_row[i * 4 + 3] = 0xFF;
    }
  }
}

}  // namespace

// ---------------------------------------------------------------------------
// FlPixelBufferSink
// ---------------------------------------------------------------------------

namespace video_player_linux {

FlPixelBufferSink::FlPixelBufferSink(FlPluginRegistrar* registrar)
    : registrar_(registrar) {
  if (registrar_) {
    texture_registrar_ = fl_plugin_registrar_get_texture_registrar(registrar_);
  }
}

FlPixelBufferSink::~FlPixelBufferSink() {
  if (texture_ != nullptr) {
    Unregister();
  }
}

int64_t FlPixelBufferSink::Register() {
  if (texture_registrar_ == nullptr || texture_ != nullptr) {
    // Already registered (or can't).
    return flutter_texture_id_;
  }

  VpPixelBufferTexture* subclass = VP_PIXEL_BUFFER_TEXTURE(
      g_object_new(VP_TYPE_PIXEL_BUFFER_TEXTURE, nullptr));
  if (subclass == nullptr) {
    return 0;
  }

  // 1x1 placeholder — real dimensions land via Resize() from the worker
  // thread once GstDiscoverer reports the actual stream size. Allocating
  // a minimal buffer here keeps copy_pixels safe even if Flutter tries
  // to render before the first real frame arrives.
  const gsize placeholder_len = 4u;
  g_mutex_lock(&subclass->mutex);
  subclass->rgba_buf =
      static_cast<guint8*>(std::malloc(placeholder_len));
  subclass->rgba_len = placeholder_len;
  subclass->width = 1;
  subclass->height = 1;
  if (subclass->rgba_buf != nullptr) {
    std::memset(subclass->rgba_buf, 0, placeholder_len);
  }
  g_mutex_unlock(&subclass->mutex);

  if (subclass->rgba_buf == nullptr) {
    g_object_unref(subclass);
    return 0;
  }

  texture_ = FL_TEXTURE(subclass);
  if (!fl_texture_registrar_register_texture(texture_registrar_, texture_)) {
    SPDLOG_ERROR("[FlPixelBufferSink] Failed to register texture");
    g_clear_object(&texture_);
    return 0;
  }
  flutter_texture_id_ = fl_texture_get_id(texture_);
  return flutter_texture_id_;
}

void FlPixelBufferSink::Resize(int width, int height) {
  if (width <= 0 || height <= 0 || texture_ == nullptr) {
    return;
  }
  // Safe to call from any thread: all subclass state is guarded by
  // subclass->mutex. Idempotent — same dimensions means no reallocation.
  width_ = width;
  height_ = height;
  const gsize new_len = static_cast<gsize>(width) *
                        static_cast<gsize>(height) * 4u;
  VpPixelBufferTexture* subclass = VP_PIXEL_BUFFER_TEXTURE(texture_);
  g_mutex_lock(&subclass->mutex);
  if (subclass->width != width || subclass->height != height ||
      subclass->rgba_len != new_len) {
    guint8* new_buf = static_cast<guint8*>(std::malloc(new_len));
    if (new_buf != nullptr) {
      std::memset(new_buf, 0, new_len);
      std::free(subclass->rgba_buf);
      subclass->rgba_buf = new_buf;
      subclass->rgba_len = new_len;
      subclass->width = width;
      subclass->height = height;
    }
  }
  g_mutex_unlock(&subclass->mutex);
}

void FlPixelBufferSink::AcceptFrame(const GstVideoFrame* frame) {
  if (!frame || !texture_ || width_ <= 0 || height_ <= 0) {
    return;
  }

  const GstVideoFormat fmt = GST_VIDEO_INFO_FORMAT(&frame->info);
  const int fw = GST_VIDEO_FRAME_WIDTH(frame);
  const int fh = GST_VIDEO_FRAME_HEIGHT(frame);

  VpPixelBufferTexture* subclass = VP_PIXEL_BUFFER_TEXTURE(texture_);
  g_mutex_lock(&subclass->mutex);
  if (subclass->rgba_buf == nullptr ||
      subclass->width != width_ || subclass->height != height_ ||
      fw != width_ || fh != height_) {
    g_mutex_unlock(&subclass->mutex);
    return;
  }

  if (fmt == GST_VIDEO_FORMAT_RGBA) {
    // Fast path: pipeline produced RGBA directly — straight copy, row by
    // row to honour the source stride.
    const guint8* src = static_cast<const guint8*>(
        GST_VIDEO_FRAME_PLANE_DATA(frame, 0));
    const int src_stride = GST_VIDEO_FRAME_PLANE_STRIDE(frame, 0);
    const int dst_stride = width_ * 4;
    for (int y = 0; y < height_; ++y) {
      std::memcpy(subclass->rgba_buf + y * dst_stride,
                  src + y * src_stride, dst_stride);
    }
  } else if (fmt == GST_VIDEO_FORMAT_NV12) {
    // Legacy path: CPU NV12→RGBA conversion, kept so environments where
    // the sink's preferred format is overridden (e.g. forcing NV12 for
    // profiling) still produce frames.
    Nv12ToRgbaBt601(frame, subclass->rgba_buf);
  }
  g_mutex_unlock(&subclass->mutex);

  fl_texture_registrar_mark_texture_frame_available(texture_registrar_,
                                                    texture_);
}

void FlPixelBufferSink::Unregister() {
  if (texture_ != nullptr && texture_registrar_ != nullptr) {
    fl_texture_registrar_unregister_texture(texture_registrar_, texture_);
  }
  g_clear_object(&texture_);
  flutter_texture_id_ = 0;
  width_ = 0;
  height_ = 0;
}

// Factory override for embedder_fl — this is the body the linker needs for
// `MakeTextureSinkForEmbedder` (declared in core/texture_sink.h).
// Each embedder build compiles exactly one of gpu_surface_sink.cc or
// fl_pixel_buffer_sink.cc, so there is never a duplicate definition.
std::unique_ptr<TextureSink> MakeTextureSinkForEmbedder(void* registrar) {
  return std::make_unique<FlPixelBufferSink>(
      static_cast<FlPluginRegistrar*>(registrar));
}

}  // namespace video_player_linux
