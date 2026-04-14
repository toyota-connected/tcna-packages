/*
 * Copyright 2020-2026 Toyota Connected North America
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "event_port.h"
#include "texture_sink.h"

extern "C" {
#include <gst/gst.h>
#include <gst/video/video.h>
#include <libudev.h>
}

namespace video_player_linux {

/// Media stream information populated by `GstDiscoverer` before player
/// construction. Carries everything required to decide between A/V and
/// audio-only modes and to seed the initial Flutter event payloads.
struct MediaInfo {
  int width = 0;
  int height = 0;
  gint64 duration = 0;
  bool has_video = false;
  bool has_audio = false;
  gint n_audio_streams = 0;
  std::string audio_codec;
  int audio_channels = 0;
  int audio_sample_rate = 0;

  // Embedded album art (typically front cover) extracted from tags.
  std::vector<uint8_t> album_art;
  std::string album_art_mime;

  // Text metadata extracted from tags.
  std::string title;
  std::string artist;
  std::string album;
  std::string album_artist;
  std::string genre;
  int track_number = 0;
};

class VideoPlayer {
 public:
  // `sink` must already have been `Register()`ed by the caller on the
  // platform thread; its texture id is passed in as `texture_id`. The
  // ctor itself can run on a worker thread — the async-create flow in
  // the GTK plugin does exactly that so the pigeon `create` handler
  // returns a texture id to Dart without blocking the UI on
  // GstDiscoverer + pipeline construction.
  VideoPlayer(std::unique_ptr<TextureSink> sink,
              int64_t texture_id,
              std::string uri,
              std::map<std::string, std::string> http_headers,
              const MediaInfo& info);
  ~VideoPlayer();

  // Begin pre-roll. Must be called after the player is inserted into
  // the plugin's lookup map (otherwise bus events triggered by the
  // PAUSED transition can fire callbacks that look up the player and
  // get player_not_found under the async-create flow).
  void Start();

  void Dispose();
  void SetLooping(bool isLooping);
  void SetVolume(double volume);
  void SetPlaybackSpeed(double playbackSpeed);
  void Play();
  void Pause();
  int64_t GetPosition();
  void SendBufferingUpdate();
  void SeekTo(int64_t seek);
  int64_t GetTextureId() const { return m_texture_id; };
  bool IsValid();
  bool IsAudioOnly() const { return !has_video_; }

  // Phase 1 — audio control surface
  int GetAudioTrackCount();
  void SetAudioTrack(int index);
  void SetOutputChannels(int channels);
  void SetMute(bool mute);

  // Phase 2 — quality & tuning
  void SetScaleMethod(int method);
  void SetAVOffset(int64_t offset_ms);
  void SetSubtitlesEnabled(bool enabled);
  int GetSubtitleTrackCount();
  void SetSubtitleTrack(int index);
  void SetSubtitleUri(const std::string& uri);
  void SetSubtitleFont(const std::string& font_desc);
  void SetChannelMixPreset(const std::string& preset);

  // Phase 3 — premium features
  void SetEqualizer(const std::vector<double>& bands);
  void SetVideoBalance(double brightness,
                       double contrast,
                       double saturation,
                       double hue);
  void SetAudioPassthrough(bool enabled);
  void SetChannelMixMatrix(int in_channels,
                           int out_channels,
                           const std::vector<double>& matrix);

  // Access the per-player EventPort. The glue layer / FFI bridge doesn't
  // call this directly — it looks the port up through EventPortRegistry
  // keyed on the texture id — but it's handy for unit tests.
  EventPort& event_port() { return event_port_; }

 private:
  std::unique_ptr<TextureSink> sink_;
  EventPort event_port_;

  std::string uri_;
  std::map<std::string, std::string> http_headers_;
  int width_{};
  int height_{};
  gint64 duration_{};
  bool has_video_{true};

  // Initial album art / metadata captured at discovery time. Forwarded to
  // Dart via the native event port as soon as the pipeline starts rolling.
  std::vector<uint8_t> initial_album_art_;
  std::string initial_album_art_mime_;
  std::string title_;
  std::string artist_;
  std::string album_;
  std::string album_artist_;
  std::string genre_;
  int track_number_{0};
  std::string audio_codec_;
  int audio_channels_{0};
  int audio_sample_rate_{0};

  int64_t m_texture_id{};
  std::atomic<bool> m_valid = true;

  GMainContext* context_;

  // Gst members
  GstElement* playbin_{};
  GstElement* pipeline_{};
  GstElement* sink_gst_{};  // video fakesink — renamed from `sink_` to avoid
                            // colliding with the new TextureSink member.
  GstElement* video_convert_{};
  GstElement* video_scale_{};
  GstVideoInfo info_{};
  std::atomic<gint64> position_{0};
  // `rate_` starts at a sentinel (-2.0) so the first ApplyPlaybackSpeed
  // call always sends a real seek to the pipeline — otherwise a fresh
  // playbin can inherit a stray segment rate from a previous instance and
  // play the first second or two too fast before correcting itself.
  // Both fields are touched from the GLib main loop, the GStreamer
  // streaming thread (audio recovery / upgrade idle callbacks) and the
  // Flutter platform thread (Pigeon dispatchers), so they're atomic.
  std::atomic<double> rate_{-2.0};
  std::atomic<double> pending_rate_{1.0};
  GstBus* bus_{};

  // Custom audio sink bin elements (audioconvert → audioresample →
  // capsfilter → real sink). Owned by the bin once added.
  GstElement* audio_bin_{};
  GstElement* audio_convert_{};
  GstElement* audio_resample_{};
  GstElement* audio_scaletempo_{};  // time-stretch for playback rate changes
  GstElement* audio_capsfilter_{};
  GstElement* equalizer_{};     // optional, inserted on first SetEqualizer
  GstElement* videobalance_{};  // optional, inserted on first SetVideoBalance
  int output_channels_{2};

  gulong handoff_handler_id_{};
  gulong on_bus_msg_id_{};
  gulong source_setup_id_{};

  std::atomic<GstState> target_state_{GST_STATE_PAUSED};

  gint n_video_{};
  gint current_video_{};
  std::atomic<bool> is_looping_{};
  std::atomic<bool> is_buffering_{};
  gboolean is_live_{};
  double volume_ = 0.0;

  std::mutex gst_mutex_;

  std::atomic<bool> audio_recovery_{false};
  std::atomic<bool> audio_upgraded_{false};
  std::atomic<bool> is_initialized_{false};
  std::atomic<bool> sent_initialized_{false};
  void SetBuffering(bool buffering);

  // udev monitor for audio device hotplug
  struct udev* udev_{};
  struct udev_monitor* udev_mon_{};
  GIOChannel* udev_channel_{};
  guint udev_watch_id_{};
  // GSource id for the pending OnAudioUpgrade idle callback (if any).
  // Tracked so it can be cancelled in StopAudioMonitor / Dispose to
  // prevent the callback from firing after `this` has been destroyed.
  guint audio_upgrade_idle_id_{};
  void StartAudioMonitor();
  void StopAudioMonitor();
  static gboolean OnUdevEvent(GIOChannel* channel,
                              GIOCondition cond,
                              gpointer user_data);

  void ApplyPlaybackSpeed();
  void OnPlaybackEnded();
  static gboolean OnAudioRecovery(gpointer user_data);
  static gboolean OnAudioUpgrade(gpointer user_data);
  static void OnMediaInitialized();
  void OnMediaStateChange(GstState state);
  void OnMediaError(GstMessage* msg);
  void OnMediaDurationChange();
  void SendInitialized();
  void SendMediaMetadata();
  void SendAlbumArt(const std::vector<uint8_t>& bytes, const std::string& mime);
  void SendAudioInfo();

  // Build the audio sink bin (audioconvert → audioresample → capsfilter →
  // real sink). Returns nullptr on failure.
  GstElement* BuildAudioSinkBin();

  // Bus tag handling: extract embedded GST_TAG_IMAGE on the fly.
  void HandleAlbumArt(GstSample* sample);

  static void OnTag(const GstTagList* list,
                    const gchar* tag,
                    gpointer user_data);

  // Connected to playbin's `source-setup` signal so souphttpsrc / rtspsrc
  // properties (timeout, user-agent, proxy, latency, …) can be configured
  // before the source is linked.
  static void OnSourceSetup(GstElement* playbin,
                            GstElement* source,
                            gpointer user_data);

  // A mutex is used to synchronize access to texture-related state.
  std::mutex buffer_mutex_;

  /**
   * @brief Callback called when fakesink receives new frame data
   * @param[in] fakesink No use
   * @param[in] buffer Pointer to New frame data
   * @param[in] pad No use
   * @param[in,out] user_data Pointer to User data
   * @return void
   * @relation
   * flutter
   */
  static void handoff_handler(GstElement* fakesink,
                              GstBuffer* buffer,
                              GstPad* pad,
                              void* user_data);

  static gboolean OnBusMessage(GstBus* bus, GstMessage* msg, void* user_data);

  /**
   * @brief Prepare
   * @param[in,out] user_data Pointer to User data
   * @return void
   * @relation
   * flutter
   */
  static void prepare(VideoPlayer* user_data);
};
}  // namespace video_player_linux
