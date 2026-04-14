// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0
//
// Tiny logging shim. The ivi-homescreen sources pull in spdlog via
// plugins/common/common.h; standalone builds under the Flutter Linux
// embedder don't have spdlog on the include path. If VP_USE_SPDLOG is
// defined (by the ivi CMake), use spdlog; otherwise fall back to glib
// g_log which both embedders already pull in through GStreamer.
#pragma once

#if defined(VP_USE_SPDLOG)
// Direct spdlog — works anywhere spdlog/spdlog.h is on the include path.
// Under ivi-homescreen that's provided transitively by the `flutter`
// INTERFACE target. Avoids a dep on ivi-homescreen-plugins'
// plugins/common/common.h (which pulls sdbus, uuidxx, etc. we don't
// need here).
//
// SPDLOG_ACTIVE_LEVEL must be set BEFORE including spdlog.h, otherwise
// SPDLOG_DEBUG / SPDLOG_TRACE macros compile out to no-ops (default is
// LEVEL_INFO). Match ivi-homescreen's own convention: TRACE in debug
// builds, OFF in release.
#if !defined(SPDLOG_ACTIVE_LEVEL)
#if !defined(NDEBUG)
#define SPDLOG_ACTIVE_LEVEL SPDLOG_LEVEL_TRACE
#else
#define SPDLOG_ACTIVE_LEVEL SPDLOG_LEVEL_INFO
#endif
#endif
#include <spdlog/spdlog.h>
#else

#include <glib.h>

#include <string>

// fmt-like formatting via fmtlib is not pulled in standalone; redirect
// spdlog's common macros to glib g_log with plain strings. We don't try
// to mimic {fmt} placeholders — the core sources that log at hot paths
// have been audited to either avoid formatting or to format into a
// std::string before calling.
//
// For lines in nv12.h / video_player.cc that use `spdlog::error("... {} ...")`
// patterns we provide a minimal `vp_fmt` helper (below) that substitutes
// `{}` / `{:X}` sequentially from the argument list using std::to_string.

namespace video_player_linux::log_detail {

// Substitute the next occurrence of "{...}" in `fmt` with `val`. Supports
// `{}`, `{:x}` (lowercase hex), `{:X}` (uppercase hex). Not general-purpose
// — just enough for this plugin's log sites.
inline std::string subst(std::string fmt, const std::string& val) {
  const auto pos = fmt.find('{');
  if (pos == std::string::npos) return fmt;
  const auto end = fmt.find('}', pos);
  if (end == std::string::npos) return fmt;
  return fmt.substr(0, pos) + val + fmt.substr(end + 1);
}

template <typename T>
inline std::string to_string_any(const T& v) {
  if constexpr (std::is_same_v<T, std::string>) {
    return v;
  } else if constexpr (std::is_convertible_v<T, std::string>) {
    return std::string(v);
  } else if constexpr (std::is_same_v<T, const char*> ||
                       std::is_same_v<T, char*>) {
    return std::string(v ? v : "");
  } else {
    return std::to_string(v);
  }
}

template <typename T>
inline std::string subst_any(std::string fmt, const T& v) {
  const auto pos = fmt.find('{');
  if (pos == std::string::npos) return fmt;
  const auto end = fmt.find('}', pos);
  if (end == std::string::npos) return fmt;
  const std::string spec = fmt.substr(pos + 1, end - pos - 1);
  std::string formatted;
  // Hex specs — only integer-ish T.
  if constexpr (std::is_integral_v<T>) {
    if (spec == ":x" || spec == ":X") {
      char buf[32];
      std::snprintf(buf, sizeof(buf),
                    spec == ":X" ? "%lX" : "%lx",
                    static_cast<unsigned long>(v));
      formatted = buf;
    } else {
      formatted = std::to_string(v);
    }
  } else {
    formatted = to_string_any(v);
  }
  return fmt.substr(0, pos) + formatted + fmt.substr(end + 1);
}

inline std::string fmt_fold(std::string s) {
  return s;
}

template <typename Arg, typename... Rest>
inline std::string fmt_fold(std::string s, Arg&& a, Rest&&... rest) {
  return fmt_fold(subst_any(std::move(s), a), std::forward<Rest>(rest)...);
}

}  // namespace video_player_linux::log_detail

#define VP_LOG_(level, ...) \
  g_log(G_LOG_DOMAIN, (level), "%s", \
        ::video_player_linux::log_detail::fmt_fold(__VA_ARGS__).c_str())

#define SPDLOG_TRACE(...) VP_LOG_(G_LOG_LEVEL_DEBUG, __VA_ARGS__)
#define SPDLOG_DEBUG(...) VP_LOG_(G_LOG_LEVEL_DEBUG, __VA_ARGS__)
#define SPDLOG_INFO(...) VP_LOG_(G_LOG_LEVEL_INFO, __VA_ARGS__)
#define SPDLOG_WARN(...) VP_LOG_(G_LOG_LEVEL_WARNING, __VA_ARGS__)
#define SPDLOG_ERROR(...) VP_LOG_(G_LOG_LEVEL_CRITICAL, __VA_ARGS__)

namespace spdlog {
template <typename... Args>
inline void trace(const std::string& fmt, Args&&... args) {
  SPDLOG_TRACE(fmt, std::forward<Args>(args)...);
}
template <typename... Args>
inline void debug(const std::string& fmt, Args&&... args) {
  SPDLOG_DEBUG(fmt, std::forward<Args>(args)...);
}
template <typename... Args>
inline void info(const std::string& fmt, Args&&... args) {
  SPDLOG_INFO(fmt, std::forward<Args>(args)...);
}
template <typename... Args>
inline void warn(const std::string& fmt, Args&&... args) {
  SPDLOG_WARN(fmt, std::forward<Args>(args)...);
}
template <typename... Args>
inline void error(const std::string& fmt, Args&&... args) {
  SPDLOG_ERROR(fmt, std::forward<Args>(args)...);
}
}  // namespace spdlog

#endif  // VP_USE_SPDLOG
