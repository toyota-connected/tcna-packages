// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// GTK (stock Flutter Linux) plugin entry point. Pattern-matches the layout
// produced by `flutter create --platforms=linux --template=plugin`: a
// GObject final type plus a register-with-registrar function that the
// generated plugin registrant calls into.
//
// Pigeon dispatch is wired here: each LinuxVideoPlayerApi method maps to
// a static handler that looks up the VideoPlayer keyed by texture id and
// forwards to the appropriate method. The design mirrors the ivi-homescreen
// embedder glue (linux_cpp/embedder_ivi/video_player_plugin.cc); only the
// dispatch style differs (pigeon GObject vtable vs. C++ virtual methods).

// FLUTTER_PLUGIN_IMPL is set via target_compile_definitions in CMake.

#include "video_player_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <glib-object.h>

extern "C" {
#include <gst/gst.h>
#include <gst/pbutils/pbutils.h>
#include <gst/tag/tag.h>
}

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstring>
#include <exception>
#include <filesystem>
#include <map>
#include <memory>
#include <mutex>
#include <thread>
#include <string>
#include <vector>

#include "../core/texture_sink.h"
#include "../core/video_player.h"
#include "messages.g.h"

// ---------------------------------------------------------------------------
// GObject boilerplate
// ---------------------------------------------------------------------------

namespace {

// C++ state bag held behind the GObject via g_object_set_data. Keeping the
// C++ state off the GObject struct itself (which must be POD-compatible
// per GObject rules) avoids any constructor/destructor pitfalls.
struct PluginState {
  FlPluginRegistrar* registrar{nullptr};
  std::map<int64_t, std::unique_ptr<video_player_linux::VideoPlayer>> players;
  std::mutex mu;
};

constexpr const char* kPluginStateKey = "vp-linux-plugin-state";

// --------------------------------------------------------------------------
// URI / header helpers — mirror the ivi implementation.
// --------------------------------------------------------------------------

bool is_allowed_uri_scheme(const std::string& uri) {
  static constexpr std::array<const char*, 4> kAllowedSchemes = {
      "file://", "http://", "https://", "rtsp://"};
  return std::any_of(kAllowedSchemes.begin(), kAllowedSchemes.end(),
                     [&uri](const char* scheme) {
                       return uri.compare(0, strlen(scheme), scheme) == 0;
                     });
}

bool has_header_injection(const std::string& value) {
  return value.find('\r') != std::string::npos ||
         value.find('\n') != std::string::npos ||
         value.find('\0') != std::string::npos;
}

// Returns the absolute path to the Flutter assets directory. Stock Flutter
// Linux doesn't expose an accessor for this on FlPluginRegistrar, so we fall
// back to FlDartProject's default resolution (data/flutter_assets relative
// to the running executable).
std::string resolve_assets_path() {
  FlDartProject* project = fl_dart_project_new();
  const gchar* path = fl_dart_project_get_assets_path(project);
  std::string result = path ? path : "";
  g_object_unref(project);
  return result;
}

// Convert the pigeon-supplied FlValue* map of HTTP headers into a plain
// std::map<std::string,std::string>. Non-string keys/values are skipped.
// Returns false if any entry contains a header-injection control byte.
bool fl_value_to_header_map(FlValue* headers,
                            std::map<std::string, std::string>& out) {
  if (!headers || fl_value_get_type(headers) != FL_VALUE_TYPE_MAP) {
    return true;  // empty/null is fine
  }
  const size_t n = fl_value_get_length(headers);
  for (size_t i = 0; i < n; ++i) {
    FlValue* k = fl_value_get_map_key(headers, i);
    FlValue* v = fl_value_get_map_value(headers, i);
    if (!k || !v) continue;
    if (fl_value_get_type(k) != FL_VALUE_TYPE_STRING ||
        fl_value_get_type(v) != FL_VALUE_TYPE_STRING) {
      continue;
    }
    std::string key = fl_value_get_string(k);
    std::string value = fl_value_get_string(v);
    if (has_header_injection(key) || has_header_injection(value)) {
      return false;
    }
    out[std::move(key)] = std::move(value);
  }
  return true;
}

// Convert an FlValue list of numbers into a std::vector<double>. Non-numeric
// entries become 0.0 — consistent with EncodableListToDoubles in the ivi
// embedder glue.
std::vector<double> fl_value_to_doubles(FlValue* list) {
  std::vector<double> out;
  if (!list || fl_value_get_type(list) != FL_VALUE_TYPE_LIST) {
    return out;
  }
  const size_t n = fl_value_get_length(list);
  out.reserve(n);
  for (size_t i = 0; i < n; ++i) {
    FlValue* v = fl_value_get_list_value(list, i);
    if (!v) {
      out.push_back(0.0);
      continue;
    }
    switch (fl_value_get_type(v)) {
      case FL_VALUE_TYPE_FLOAT:
        out.push_back(fl_value_get_float(v));
        break;
      case FL_VALUE_TYPE_INT:
        out.push_back(static_cast<double>(fl_value_get_int(v)));
        break;
      default:
        out.push_back(0.0);
        break;
    }
  }
  return out;
}

// ────────────────────────────────────────────────────────────────────────────
// discover_media_info — ported verbatim from the ivi embedder glue. Relies
// only on GStreamer/GObject primitives, so it's embedder-agnostic. Spdlog
// calls are replaced with g_warning / g_debug (no spdlog in this embedder).
// ────────────────────────────────────────────────────────────────────────────

bool discover_media_info(const char* url, video_player_linux::MediaInfo& info) {
  GError* err = nullptr;
  // Discovery runs synchronously on the Flutter platform thread (pigeon
  // gobject handler). 10 s is far too long — a broken URL stalls the UI.
  // 3 s is enough for local files and healthy network sources; fail-fast
  // otherwise.
  GstDiscoverer* discoverer = gst_discoverer_new(3 * GST_SECOND, &err);
  if (!discoverer) {
    g_warning("[VideoPlayer] Failed to create discoverer: %s",
              err ? err->message : "unknown");
    g_clear_error(&err);
    return false;
  }

  GstDiscovererInfo* disc_info =
      gst_discoverer_discover_uri(discoverer, url, &err);
  if (!disc_info ||
      gst_discoverer_info_get_result(disc_info) != GST_DISCOVERER_OK) {
    g_warning("[VideoPlayer] Discovery failed for %s: %s", url,
              err ? err->message : "unknown");
    g_clear_error(&err);
    if (disc_info) {
      gst_discoverer_info_unref(disc_info);
    }
    g_object_unref(discoverer);
    return false;
  }

  info.duration =
      static_cast<gint64>(gst_discoverer_info_get_duration(disc_info));

  if (GList* video_streams = gst_discoverer_info_get_video_streams(disc_info)) {
    auto* stream_info =
        static_cast<GstDiscovererStreamInfo*>(video_streams->data);
    if (GST_IS_DISCOVERER_VIDEO_INFO(stream_info)) {
      auto* vinfo = GST_DISCOVERER_VIDEO_INFO(stream_info);
      info.width = static_cast<int>(gst_discoverer_video_info_get_width(vinfo));
      info.height =
          static_cast<int>(gst_discoverer_video_info_get_height(vinfo));
      info.has_video = true;
    }
    gst_discoverer_stream_info_list_free(video_streams);
  }

  if (GList* audio_streams = gst_discoverer_info_get_audio_streams(disc_info)) {
    info.has_audio = true;
    info.n_audio_streams = static_cast<gint>(g_list_length(audio_streams));
    auto* stream_info =
        static_cast<GstDiscovererStreamInfo*>(audio_streams->data);
    if (GST_IS_DISCOVERER_AUDIO_INFO(stream_info)) {
      auto* ainfo = GST_DISCOVERER_AUDIO_INFO(stream_info);
      info.audio_channels =
          static_cast<int>(gst_discoverer_audio_info_get_channels(ainfo));
      info.audio_sample_rate =
          static_cast<int>(gst_discoverer_audio_info_get_sample_rate(ainfo));
    }
    gst_discoverer_stream_info_list_free(audio_streams);
  }

  if (!info.has_video && !info.has_audio) {
    g_warning("[VideoPlayer] No playable streams in %s", url);
    gst_discoverer_info_unref(disc_info);
    g_object_unref(discoverer);
    return false;
  }

  if (const GstTagList* tags = gst_discoverer_info_get_tags(disc_info)) {
    GstSample* image_sample = nullptr;
    if (gst_tag_list_get_sample(tags, GST_TAG_IMAGE, &image_sample) ||
        gst_tag_list_get_sample(tags, GST_TAG_PREVIEW_IMAGE, &image_sample)) {
      GstBuffer* buf = gst_sample_get_buffer(image_sample);
      GstCaps* caps = gst_sample_get_caps(image_sample);
      GstMapInfo map;
      if (buf && gst_buffer_map(buf, &map, GST_MAP_READ)) {
        constexpr size_t kMaxAlbumArtBytes =
            static_cast<size_t>(10) * 1024 * 1024;
        if (map.size > 0 && map.size <= kMaxAlbumArtBytes) {
          info.album_art.assign(map.data, map.data + map.size);
          if (caps) {
            if (const gchar* name =
                    gst_structure_get_name(gst_caps_get_structure(caps, 0))) {
              info.album_art_mime = name;
            }
          }
        } else if (map.size > kMaxAlbumArtBytes) {
          g_warning(
              "[VideoPlayer] Embedded album art is %zu bytes (>%zu MB cap); "
              "ignoring.",
              map.size,
              kMaxAlbumArtBytes / (static_cast<size_t>(1024) * 1024));
        }
        gst_buffer_unmap(buf, &map);
      }
      gst_sample_unref(image_sample);
    }

    auto take_string = [&](const char* tag, std::string& dst) {
      gchar* val = nullptr;
      if (gst_tag_list_get_string(tags, tag, &val) && val) {
        dst = val;
        g_free(val);
      }
    };
    take_string(GST_TAG_TITLE, info.title);
    take_string(GST_TAG_ARTIST, info.artist);
    take_string(GST_TAG_ALBUM, info.album);
    take_string(GST_TAG_ALBUM_ARTIST, info.album_artist);
    take_string(GST_TAG_GENRE, info.genre);
    take_string(GST_TAG_AUDIO_CODEC, info.audio_codec);
    guint track_num = 0;
    if (gst_tag_list_get_uint(tags, GST_TAG_TRACK_NUMBER, &track_num)) {
      info.track_number = static_cast<int>(track_num);
    }
  }

  g_debug(
      "[VideoPlayer] Discovered: video=%d (%dx%d), audio=%d (%dch/%dHz), "
      "duration=%" G_GINT64_FORMAT "ns, art=%zuB",
      info.has_video, info.width, info.height, info.has_audio,
      info.audio_channels, info.audio_sample_rate, info.duration,
      info.album_art.size());

  gst_discoverer_info_unref(disc_info);
  g_object_unref(discoverer);
  return true;
}

// ────────────────────────────────────────────────────────────────────────────
// Dispatch helpers
// ────────────────────────────────────────────────────────────────────────────

// Look up a live player under the state mutex. Returns nullptr on miss.
// NOTE: returns a raw pointer. The caller holds the unique_ptr in the map,
// so as long as we don't drop the mutex before finishing the call we're
// safe — and every handler below does finish synchronously.
video_player_linux::VideoPlayer* find_player(PluginState* state,
                                             int64_t texture_id) {
  auto it = state->players.find(texture_id);
  if (it == state->players.end()) return nullptr;
  return it->second.get();
}

}  // namespace

// ───────────────────────────────────────────────────────────────────────────
// Pigeon vtable handlers. All functions take `gpointer user_data` which is
// the PluginState* we registered in register_with_registrar. Each handler
// locks the state mutex for its lookup, then calls into VideoPlayer under
// the lock (consistent with the ivi embedder, which takes an implicit lock
// via the plugin's single-threaded flutter::MethodChannel dispatch model).
// ───────────────────────────────────────────────────────────────────────────

static video_player_linuxLinuxVideoPlayerApiInitializeResponse*
handle_initialize(gpointer user_data) {
  auto* state = static_cast<PluginState*>(user_data);
  std::lock_guard<std::mutex> lk(state->mu);
  for (auto& [_, player] : state->players) {
    if (player) player->Dispose();
  }
  state->players.clear();
  return video_player_linux_linux_video_player_api_initialize_response_new();
}

static video_player_linuxLinuxVideoPlayerApiCreateResponse* handle_create(
    const gchar* asset,
    const gchar* uri,
    FlValue* http_headers,
    gpointer user_data) {
  auto* state = static_cast<PluginState*>(user_data);

  std::string asset_to_load;
  std::map<std::string, std::string> headers;

  if (asset && *asset) {
    std::filesystem::path path;
    if (asset[0] == '/') {
      path = asset;
    } else {
      std::string assets_dir = resolve_assets_path();
      if (!assets_dir.empty()) {
        path = std::filesystem::absolute(assets_dir);
        path /= asset;
      } else {
        path = std::filesystem::absolute(asset);
      }
    }
    path = std::filesystem::absolute(path);
    std::error_code ec;
    if (!std::filesystem::exists(path, ec)) {
      g_warning("[VideoPlayer] Asset Path does not exist: %s",
                path.c_str());
      return video_player_linux_linux_video_player_api_create_response_new_error(
          "asset_load_failed", "Asset Path does not exist.", nullptr);
    }
    asset_to_load = "file://";
    asset_to_load += path.c_str();
  } else if (uri && *uri) {
    std::string u = uri;
    if (!is_allowed_uri_scheme(u)) {
      g_warning("[VideoPlayer] Unsupported URI scheme: %s", u.c_str());
      return video_player_linux_linux_video_player_api_create_response_new_error(
          "uri_load_failed",
          "URI scheme not allowed. Supported: file, http, https, rtsp",
          nullptr);
    }
    asset_to_load = std::move(u);
    if (!fl_value_to_header_map(http_headers, headers)) {
      g_warning("[VideoPlayer] Rejected HTTP header with control characters");
      return video_player_linux_linux_video_player_api_create_response_new_error(
          "invalid_headers", "HTTP header contains invalid characters",
          nullptr);
    }
  } else {
    return video_player_linux_linux_video_player_api_create_response_new_error(
        "not_implemented", "Set either an asset or a uri", nullptr);
  }

  // Async-create path: pre-register the texture synchronously on the
  // platform thread so we can return a valid texture id to Dart, then
  // spawn a worker thread that does the slow work (GstDiscoverer,
  // pipeline construction, pipewire audio-sink probing). This keeps
  // the pigeon `create` handler off the critical path — tab switches
  // no longer freeze the UI while the next tab's pipeline is built.
  //
  // The "preliminary" texture is 1x1 placeholder RGBA; the VideoPlayer
  // ctor calls sink_->Resize() once discovery lands the real size.
  // `EventPortRegistry` buffers the Dart port that arrives between
  // create() returning and the VideoPlayer ctor running, so the event
  // plane is still wired even with the race.
  std::unique_ptr<video_player_linux::TextureSink> sink_placeholder =
      video_player_linux::MakeTextureSinkForEmbedder(state->registrar);
  const int64_t texture_id = sink_placeholder->Register();
  if (texture_id == 0) {
    return video_player_linux_linux_video_player_api_create_response_new_error(
        "texture_register_failed",
        "Failed to register placeholder texture with Flutter", nullptr);
  }

  // Hand ownership of the heavy work to a detached worker thread.
  std::thread(
      [state, texture_id, sink = std::move(sink_placeholder),
       asset_to_load = std::move(asset_to_load),
       headers = std::move(headers)]() mutable {
        video_player_linux::MediaInfo info;
        if (!discover_media_info(asset_to_load.c_str(), info)) {
          g_warning("[VideoPlayer] Discovery failed for %s",
                    asset_to_load.c_str());
          sink->Unregister();
          return;
        }
        if (info.has_video && (info.width <= 0 || info.height <= 0 ||
                               info.width > 16384 || info.height > 16384)) {
          g_warning("[VideoPlayer] Invalid video dimensions: %dx%d",
                    info.width, info.height);
          sink->Unregister();
          return;
        }
        // For audio-only the placeholder FlPixelBufferTexture is kept
        // (Dart's `buildViewWithOptions` skips the Texture widget for
        // audio-only ids, so the registered texture is harmless), which
        // means the texture id we already handed to Dart stays valid.
        std::unique_ptr<video_player_linux::VideoPlayer> player;
        try {
          player = std::make_unique<video_player_linux::VideoPlayer>(
              std::move(sink), texture_id, std::move(asset_to_load),
              std::move(headers), info);
        } catch (std::exception& e) {
          g_warning("[VideoPlayer] Construction failed: %s", e.what());
          return;
        }
        // Capture a bare pointer under the mutex so we can Start() the
        // pipeline *after* the player is visible in state->players.
        // Any bus-message-driven SendInitialized → Dart → setLooping/play
        // callback chain will then find the player in the map.
        video_player_linux::VideoPlayer* ptr = player.get();
        {
          std::lock_guard<std::mutex> lk(state->mu);
          state->players.insert(std::make_pair(texture_id, std::move(player)));
        }
        ptr->Start();
      })
      .detach();

  return video_player_linux_linux_video_player_api_create_response_new(
      texture_id);
}

static video_player_linuxLinuxVideoPlayerApiDisposeResponse* handle_dispose(
    int64_t texture_id,
    gpointer user_data) {
  auto* state = static_cast<PluginState*>(user_data);
  std::unique_ptr<video_player_linux::VideoPlayer> player;
  {
    std::lock_guard<std::mutex> lk(state->mu);
    auto it = state->players.find(texture_id);
    if (it == state->players.end()) {
      return video_player_linux_linux_video_player_api_dispose_response_new_error(
          "player_not_found", "This player ID was not found", nullptr);
    }
    player = std::move(it->second);
    state->players.erase(it);
  }
  // GStreamer pipeline teardown (set_state(NULL), pipewire audio sink
  // destruction) is synchronous and can take hundreds of ms or longer
  // under load. Running it here would block the Flutter platform thread —
  // in the tab-switch case that pushed the whole UI into a visible freeze
  // while the next tab's `create` was queued behind the mutex. Detach the
  // teardown to a worker thread and reply to Dart immediately; the
  // player is already out of `state->players` so no further pigeon calls
  // can land on it.
  std::thread([p = std::move(player)]() mutable {
    if (p && p->IsValid()) {
      p->Dispose();
    }
    p.reset();
  }).detach();
  return video_player_linux_linux_video_player_api_dispose_response_new();
}

// Shared macro for simple lookup-and-forward handlers. `RESP_NS` is the
// per-method response-constructor infix (e.g. `set_looping`); the handler
// returns the matching `*_response_new()` on success or `*_error()` on miss.
#define VPL_LOOKUP_OR_ERROR(RESP_NS)                                  \
  auto* state = static_cast<PluginState*>(user_data);                 \
  std::lock_guard<std::mutex> lk(state->mu);                          \
  auto* player = find_player(state, texture_id);                      \
  if (!player) {                                                      \
    return video_player_linux_linux_video_player_api_##RESP_NS        \
        ##_response_new_error("player_not_found",                     \
                              "This player ID was not found", nullptr); \
  }

static video_player_linuxLinuxVideoPlayerApiSetLoopingResponse*
handle_set_looping(int64_t texture_id,
                   gboolean is_looping,
                   gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_looping);
  if (player->IsValid()) player->SetLooping(is_looping == TRUE);
  return video_player_linux_linux_video_player_api_set_looping_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetVolumeResponse*
handle_set_volume(int64_t texture_id, double volume, gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_volume);
  if (player->IsValid()) player->SetVolume(volume);
  return video_player_linux_linux_video_player_api_set_volume_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetPlaybackSpeedResponse*
handle_set_playback_speed(int64_t texture_id,
                          double speed,
                          gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_playback_speed);
  if (player->IsValid()) player->SetPlaybackSpeed(speed);
  return video_player_linux_linux_video_player_api_set_playback_speed_response_new();
}

static video_player_linuxLinuxVideoPlayerApiPlayResponse* handle_play(
    int64_t texture_id,
    gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(play);
  if (player->IsValid()) player->Play();
  return video_player_linux_linux_video_player_api_play_response_new();
}

static video_player_linuxLinuxVideoPlayerApiGetPositionResponse*
handle_get_position(int64_t texture_id, gpointer user_data) {
  auto* state = static_cast<PluginState*>(user_data);
  std::lock_guard<std::mutex> lk(state->mu);
  auto* player = find_player(state, texture_id);
  int64_t position = 0;
  if (player && player->IsValid()) {
    position = player->GetPosition();
  }
  return video_player_linux_linux_video_player_api_get_position_response_new(
      position);
}

static video_player_linuxLinuxVideoPlayerApiSeekToResponse* handle_seek_to(
    int64_t texture_id,
    int64_t position,
    gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(seek_to);
  if (player->IsValid()) player->SeekTo(position);
  return video_player_linux_linux_video_player_api_seek_to_response_new();
}

static video_player_linuxLinuxVideoPlayerApiPauseResponse* handle_pause(
    int64_t texture_id,
    gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(pause);
  if (player->IsValid()) player->Pause();
  return video_player_linux_linux_video_player_api_pause_response_new();
}

// ────────────────────────────────────────────────────────────────────────────
// Phase 1 — audio control surface
// ────────────────────────────────────────────────────────────────────────────

static video_player_linuxLinuxVideoPlayerApiGetAudioTrackCountResponse*
handle_get_audio_track_count(int64_t texture_id, gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(get_audio_track_count);
  return video_player_linux_linux_video_player_api_get_audio_track_count_response_new(
      static_cast<int64_t>(player->GetAudioTrackCount()));
}

static video_player_linuxLinuxVideoPlayerApiSetAudioTrackResponse*
handle_set_audio_track(int64_t texture_id,
                       int64_t track_index,
                       gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_audio_track);
  player->SetAudioTrack(static_cast<int>(track_index));
  return video_player_linux_linux_video_player_api_set_audio_track_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetOutputChannelsResponse*
handle_set_output_channels(int64_t texture_id,
                           int64_t channels,
                           gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_output_channels);
  player->SetOutputChannels(static_cast<int>(channels));
  return video_player_linux_linux_video_player_api_set_output_channels_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetMuteResponse* handle_set_mute(
    int64_t texture_id,
    gboolean mute,
    gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_mute);
  player->SetMute(mute == TRUE);
  return video_player_linux_linux_video_player_api_set_mute_response_new();
}

static video_player_linuxLinuxVideoPlayerApiIsAudioOnlyResponse*
handle_is_audio_only(int64_t texture_id, gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(is_audio_only);
  return video_player_linux_linux_video_player_api_is_audio_only_response_new(
      player->IsAudioOnly() ? TRUE : FALSE);
}

// ────────────────────────────────────────────────────────────────────────────
// Phase 2 — quality & tuning
// ────────────────────────────────────────────────────────────────────────────

static video_player_linuxLinuxVideoPlayerApiSetScaleMethodResponse*
handle_set_scale_method(int64_t texture_id,
                        int64_t method,
                        gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_scale_method);
  player->SetScaleMethod(static_cast<int>(method));
  return video_player_linux_linux_video_player_api_set_scale_method_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetAVOffsetResponse*
handle_set_a_v_offset(int64_t texture_id,
                      int64_t offset_ms,
                      gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_a_v_offset);
  player->SetAVOffset(offset_ms);
  return video_player_linux_linux_video_player_api_set_a_v_offset_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetSubtitlesEnabledResponse*
handle_set_subtitles_enabled(int64_t texture_id,
                             gboolean enabled,
                             gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_subtitles_enabled);
  player->SetSubtitlesEnabled(enabled == TRUE);
  return video_player_linux_linux_video_player_api_set_subtitles_enabled_response_new();
}

static video_player_linuxLinuxVideoPlayerApiGetSubtitleTrackCountResponse*
handle_get_subtitle_track_count(int64_t texture_id, gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(get_subtitle_track_count);
  return video_player_linux_linux_video_player_api_get_subtitle_track_count_response_new(
      static_cast<int64_t>(player->GetSubtitleTrackCount()));
}

static video_player_linuxLinuxVideoPlayerApiSetSubtitleTrackResponse*
handle_set_subtitle_track(int64_t texture_id,
                          int64_t track_index,
                          gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_subtitle_track);
  player->SetSubtitleTrack(static_cast<int>(track_index));
  return video_player_linux_linux_video_player_api_set_subtitle_track_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetSubtitleUriResponse*
handle_set_subtitle_uri(int64_t texture_id,
                        const gchar* uri,
                        gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_subtitle_uri);
  std::string u = uri ? uri : "";
  if (!u.empty() && !is_allowed_uri_scheme(u)) {
    return video_player_linux_linux_video_player_api_set_subtitle_uri_response_new_error(
        "invalid_subtitle_uri",
        "Subtitle URI scheme not allowed. Supported: file, http, https, rtsp",
        nullptr);
  }
  player->SetSubtitleUri(u);
  return video_player_linux_linux_video_player_api_set_subtitle_uri_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetSubtitleFontResponse*
handle_set_subtitle_font(int64_t texture_id,
                         const gchar* font_desc,
                         gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_subtitle_font);
  player->SetSubtitleFont(font_desc ? font_desc : "");
  return video_player_linux_linux_video_player_api_set_subtitle_font_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetChannelMixPresetResponse*
handle_set_channel_mix_preset(int64_t texture_id,
                              const gchar* preset,
                              gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_channel_mix_preset);
  player->SetChannelMixPreset(preset ? preset : "");
  return video_player_linux_linux_video_player_api_set_channel_mix_preset_response_new();
}

// ────────────────────────────────────────────────────────────────────────────
// Phase 3 — premium features
// ────────────────────────────────────────────────────────────────────────────

static video_player_linuxLinuxVideoPlayerApiSetEqualizerResponse*
handle_set_equalizer(int64_t texture_id,
                     FlValue* bands,
                     gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_equalizer);
  player->SetEqualizer(fl_value_to_doubles(bands));
  return video_player_linux_linux_video_player_api_set_equalizer_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetVideoBalanceResponse*
handle_set_video_balance(int64_t texture_id,
                         double brightness,
                         double contrast,
                         double saturation,
                         double hue,
                         gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_video_balance);
  player->SetVideoBalance(brightness, contrast, saturation, hue);
  return video_player_linux_linux_video_player_api_set_video_balance_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetAudioPassthroughResponse*
handle_set_audio_passthrough(int64_t texture_id,
                             gboolean enabled,
                             gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_audio_passthrough);
  player->SetAudioPassthrough(enabled == TRUE);
  return video_player_linux_linux_video_player_api_set_audio_passthrough_response_new();
}

static video_player_linuxLinuxVideoPlayerApiSetChannelMixMatrixResponse*
handle_set_channel_mix_matrix(int64_t texture_id,
                              int64_t in_channels,
                              int64_t out_channels,
                              FlValue* matrix,
                              gpointer user_data) {
  VPL_LOOKUP_OR_ERROR(set_channel_mix_matrix);
  player->SetChannelMixMatrix(static_cast<int>(in_channels),
                              static_cast<int>(out_channels),
                              fl_value_to_doubles(matrix));
  return video_player_linux_linux_video_player_api_set_channel_mix_matrix_response_new();
}

#undef VPL_LOOKUP_OR_ERROR

// ───────────────────────────────────────────────────────────────────────────
// GObject type + registration
// ───────────────────────────────────────────────────────────────────────────

struct _VideoPlayerLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(VideoPlayerLinuxPlugin,
              video_player_linux_plugin,
              G_TYPE_OBJECT)

static void video_player_linux_plugin_dispose(GObject* object) {
  // All cleanup of PluginState happens in the destroy_notify we registered
  // via g_object_set_data_full (below). Doing it here too causes a
  // use-after-free — the destroy_notify runs during dispose, after this
  // callback returns, and would touch a state we already deleted.
  G_OBJECT_CLASS(video_player_linux_plugin_parent_class)->dispose(object);
}

static void video_player_linux_plugin_class_init(
    VideoPlayerLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = video_player_linux_plugin_dispose;
}

static void video_player_linux_plugin_init(VideoPlayerLinuxPlugin* /*self*/) {}

void video_player_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  // Ensure GStreamer is initialised exactly once. Safe to call repeatedly;
  // gst_init is idempotent on subsequent calls.
  gst_init(nullptr, nullptr);

  VideoPlayerLinuxPlugin* plugin = VIDEO_PLAYER_LINUX_PLUGIN(
      g_object_new(video_player_linux_plugin_get_type(), nullptr));

  auto* state = new PluginState();
  state->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  g_object_set_data_full(G_OBJECT(plugin), kPluginStateKey, state,
                         [](gpointer data) {
                           auto* s = static_cast<PluginState*>(data);
                           if (!s) return;
                           {
                             std::lock_guard<std::mutex> lk(s->mu);
                             s->players.clear();
                           }
                           if (s->registrar) {
                             g_object_unref(s->registrar);
                             s->registrar = nullptr;
                           }
                           delete s;
                         });

  static const video_player_linuxLinuxVideoPlayerApiVTable kVTable = {
      &handle_initialize,
      &handle_create,
      &handle_dispose,
      &handle_set_looping,
      &handle_set_volume,
      &handle_set_playback_speed,
      &handle_play,
      &handle_get_position,
      &handle_seek_to,
      &handle_pause,
      &handle_get_audio_track_count,
      &handle_set_audio_track,
      &handle_set_output_channels,
      &handle_set_mute,
      &handle_is_audio_only,
      &handle_set_scale_method,
      &handle_set_a_v_offset,
      &handle_set_subtitles_enabled,
      &handle_get_subtitle_track_count,
      &handle_set_subtitle_track,
      &handle_set_subtitle_uri,
      &handle_set_subtitle_font,
      &handle_set_channel_mix_preset,
      &handle_set_equalizer,
      &handle_set_video_balance,
      &handle_set_audio_passthrough,
      &handle_set_channel_mix_matrix,
  };
  video_player_linux_linux_video_player_api_set_method_handlers(
      fl_plugin_registrar_get_messenger(state->registrar),
      /*suffix=*/nullptr, &kVTable, state,
      /*user_data_free_func=*/nullptr);

  // Intentionally do NOT unref `plugin` here. The pigeon vtable retains a
  // bare pointer to `state`, which is owned by the GObject via the
  // destroy_notify registered above; unref'ing the plugin would destroy
  // state, leaving the dispatchers with a dangling user_data. This matches
  // the pattern used by other Flutter Linux plugins (url_launcher_linux,
  // file_selector_linux): one plugin instance lives for the app lifetime.
  (void)plugin;
}
