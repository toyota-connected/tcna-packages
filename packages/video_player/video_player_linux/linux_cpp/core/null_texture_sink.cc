// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0

#include "texture_sink.h"

namespace video_player_linux {

namespace {
class NullTextureSink : public TextureSink {
 public:
  explicit NullTextureSink(int64_t id) : id_(id) {}
  int64_t Register() override { return id_; }
  void Resize(int /*w*/, int /*h*/) override {}
  void AcceptFrame(const GstVideoFrame* /*frame*/) override {}
  void Unregister() override {}

 private:
  int64_t id_;
};
}  // namespace

std::unique_ptr<TextureSink> MakeNullTextureSink(int64_t synthetic_id) {
  return std::make_unique<NullTextureSink>(synthetic_id);
}

}  // namespace video_player_linux
