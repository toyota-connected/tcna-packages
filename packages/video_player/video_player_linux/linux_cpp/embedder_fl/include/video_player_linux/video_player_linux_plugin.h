// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0

#ifndef FLUTTER_PLUGIN_VIDEO_PLAYER_LINUX_PLUGIN_H_
#define FLUTTER_PLUGIN_VIDEO_PLAYER_LINUX_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

G_DECLARE_FINAL_TYPE(VideoPlayerLinuxPlugin,
                     video_player_linux_plugin,
                     VIDEO,
                     PLAYER_LINUX_PLUGIN,
                     GObject)

FLUTTER_PLUGIN_EXPORT void video_player_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_VIDEO_PLAYER_LINUX_PLUGIN_H_
