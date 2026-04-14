// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0

#ifndef PLUGINS_VIDEO_PLAYER_LINUX_INCLUDE_VIDEO_PLAYER_LINUX_VIDEO_PLAYER_PLUGIN_C_API_H_
#define PLUGINS_VIDEO_PLAYER_LINUX_INCLUDE_VIDEO_PLAYER_LINUX_VIDEO_PLAYER_PLUGIN_C_API_H_

#include "flutter_homescreen.h"

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void VideoPlayerLinuxPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrar* registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // PLUGINS_VIDEO_PLAYER_LINUX_INCLUDE_VIDEO_PLAYER_LINUX_VIDEO_PLAYER_PLUGIN_C_API_H_
