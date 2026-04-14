# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2020-2026 Toyota Connected North America
#
# Real build for video_player_linux. Driven by hook/build.dart (via
# package:hooks / code_assets) for Flutter/Dart users, or invoked
# directly by ivi-homescreen's CMake for that build. The Flutter Linux
# (GTK) plugin shim at linux/CMakeLists.txt is a thin wrapper that
# add_subdirectory()s this file and forces VIDEO_PLAYER_EMBEDDER=fl.

cmake_minimum_required(VERSION 3.22)
project(video_player_linux
    LANGUAGES C CXX
    VERSION 2.5.0
    DESCRIPTION "video_player backend for Linux (GTK + ivi-homescreen)"
)

# ── Build options ─────────────────────────────────────────────────────────
set(VIDEO_PLAYER_EMBEDDER "fl" CACHE STRING
    "Target Flutter embedder: fl (stock Flutter Linux / GTK) | ivi (ivi-homescreen)")
set_property(CACHE VIDEO_PLAYER_EMBEDDER PROPERTY STRINGS fl ivi)

option(VIDEO_PLAYER_HOOK_BUILD
    "Set by hook/build.dart — stages the .so for code_assets (skips lib/ copy)"
    OFF)

option(VIDEO_PLAYER_CORE_ONLY
    "Build only the embedder-agnostic core (FFI + event port). No plugin glue."
    OFF)

set(ENABLE_SANITIZER "none" CACHE STRING "Sanitizer: none|asan|ubsan")
set_property(CACHE ENABLE_SANITIZER PROPERTY STRINGS none asan ubsan)

# ── Compiler settings ─────────────────────────────────────────────────────
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "" FORCE)
endif()

# ── Sanitizer flags ───────────────────────────────────────────────────────
if(NOT ENABLE_SANITIZER STREQUAL "none")
    if(ENABLE_SANITIZER STREQUAL "asan")
        add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
        add_link_options(-fsanitize=address)
    elseif(ENABLE_SANITIZER STREQUAL "ubsan")
        add_compile_options(-fsanitize=undefined -fno-omit-frame-pointer)
        add_link_options(-fsanitize=undefined)
    endif()
endif()

# ── Dependencies ──────────────────────────────────────────────────────────
find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTREAMER REQUIRED IMPORTED_TARGET
    gstreamer-1.0
    gstreamer-video-1.0
    gstreamer-pbutils-1.0
    gstreamer-tag-1.0
    gstreamer-audio-1.0
)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0 gobject-2.0)
pkg_check_modules(UDEV REQUIRED IMPORTED_TARGET libudev)

# GLES is only needed by the ivi sink (it runs the NV12 shader). The GTK
# sink does CPU conversion — no GL needed on the streaming thread.
if(NOT VIDEO_PLAYER_CORE_ONLY AND VIDEO_PLAYER_EMBEDDER STREQUAL "ivi")
    pkg_check_modules(GLES REQUIRED IMPORTED_TARGET glesv2)
endif()

# flutter_linux headers + library come from the Flutter tool via an
# INTERFACE target named `flutter`, set up by the app's
# linux/flutter/CMakeLists.txt. We don't use pkg-config for it. The
# hook build (VIDEO_PLAYER_HOOK_BUILD=ON) does NOT have this target —
# which is why it forces VIDEO_PLAYER_CORE_ONLY=ON and skips the glue
# layers entirely.
if(NOT VIDEO_PLAYER_CORE_ONLY AND VIDEO_PLAYER_EMBEDDER STREQUAL "fl")
    if(NOT TARGET flutter)
        message(FATAL_ERROR
            "Target `flutter` not found. video_player_linux for embedder=fl "
            "must be built through Flutter's plugin pipeline (it provides "
            "the flutter INTERFACE target). For pure-Dart/FFI consumers, "
            "use -DVIDEO_PLAYER_CORE_ONLY=ON.")
    endif()
endif()

# ── Sources ───────────────────────────────────────────────────────────────
set(CORE_SRC
    linux_cpp/core/event_port.cc
    linux_cpp/core/event_port_registry.cc
    linux_cpp/core/ffi_exports.cc
    linux_cpp/core/null_texture_sink.cc
    linux_cpp/core/video_player.cc
    linux_cpp/core/third_party/dart/dart_api_dl.c
)

set(GLUE_SRC "")
if(NOT VIDEO_PLAYER_CORE_ONLY)
    if(VIDEO_PLAYER_EMBEDDER STREQUAL "fl")
        set(GLUE_SRC
            linux_cpp/embedder_fl/fl_pixel_buffer_sink.cc
            linux_cpp/embedder_fl/video_player_linux_plugin.cc
            linux_cpp/embedder_fl/messages.g.cc
        )
    elseif(VIDEO_PLAYER_EMBEDDER STREQUAL "ivi")
        set(GLUE_SRC
            linux_cpp/embedder_ivi/gpu_surface_sink.cc
            linux_cpp/embedder_ivi/video_player_plugin.cc
            linux_cpp/embedder_ivi/video_player_plugin_c_api.cc
            linux_cpp/embedder_ivi/messages.g.cc
        )
    else()
        message(FATAL_ERROR "Unknown VIDEO_PLAYER_EMBEDDER=${VIDEO_PLAYER_EMBEDDER}")
    endif()
else()
    # CORE_ONLY mode — core still needs *some* sink to satisfy the symbol
    # MakeTextureSinkForEmbedder(void*). Provide a stub that returns null.
    set(GLUE_SRC linux_cpp/core/stub_texture_sink.cc)
endif()

# ── Target shape per embedder ─────────────────────────────────────────────
# fl : SHARED library bundled by Flutter's linux/ plugin pipeline.
# ivi: STATIC library named `plugin_video_player_linux`, matching the
#      ivi-homescreen-plugins convention. Linked into the final
#      homescreen executable by ivi's generated_plugin_registrant.cc.
if(VIDEO_PLAYER_EMBEDDER STREQUAL "ivi" AND NOT VIDEO_PLAYER_CORE_ONLY)
    set(_vpl_target plugin_video_player_linux)
    add_library(${_vpl_target} STATIC ${CORE_SRC} ${GLUE_SRC})
else()
    set(_vpl_target video_player_linux)
    add_library(${_vpl_target} SHARED ${CORE_SRC} ${GLUE_SRC})
endif()

target_compile_definitions(${_vpl_target} PRIVATE FLUTTER_PLUGIN_IMPL)

# core/log.h routes SPDLOG_* macros through spdlog when VP_USE_SPDLOG is
# defined, otherwise falls back to glib g_log. Under ivi-homescreen the
# spdlog include path is always available (pulled in transitively by
# plugin_common + homescreen headers), so wire it up so core logs land
# on the same channel as the ivi glue's logs (visible as `[D]` / `[E]`
# in homescreen's stderr). Under fl/GTK we stay on glib g_log.
if(VIDEO_PLAYER_EMBEDDER STREQUAL "ivi" AND NOT VIDEO_PLAYER_CORE_ONLY)
    target_compile_definitions(${_vpl_target} PRIVATE VP_USE_SPDLOG)
endif()

target_compile_options(${_vpl_target} PRIVATE
    -Wall
    -Wextra
    -Wno-unused-parameter
    -fvisibility=hidden
    $<$<NOT:$<CONFIG:Debug>>:-O2>
)

target_include_directories(${_vpl_target}
    PUBLIC
        # Public plugin header — Flutter's generated_plugin_registrant.cc
        # includes <video_player_linux/video_player_linux_plugin.h>
        $<$<STREQUAL:${VIDEO_PLAYER_EMBEDDER},fl>:${CMAKE_CURRENT_SOURCE_DIR}/linux_cpp/embedder_fl/include>
        $<$<STREQUAL:${VIDEO_PLAYER_EMBEDDER},ivi>:${CMAKE_CURRENT_SOURCE_DIR}/linux_cpp/embedder_ivi/include>
    PRIVATE
        linux_cpp/core
        linux_cpp/core/third_party/dart
        linux_cpp/embedder_fl
        linux_cpp/embedder_ivi
        linux_cpp
)

target_link_libraries(${_vpl_target} PRIVATE
    PkgConfig::GSTREAMER
    PkgConfig::GLIB
    PkgConfig::UDEV
)

if(NOT VIDEO_PLAYER_CORE_ONLY AND VIDEO_PLAYER_EMBEDDER STREQUAL "ivi")
    # When statically linked into an executable, our FFI symbols
    # (vp_init_api_dl / vp_register_port / vp_unregister_port) are
    # unreferenced from any C++ code — nothing in the executable calls
    # them directly; only Dart resolves them at runtime via
    # DynamicLibrary.process().lookupFunction(). Two things can go wrong:
    #
    #   1. --gc-sections (or plain archive-ordering rules) omits the .a
    #      archive members that define them entirely.
    #   2. Even if kept, they don't land in the dynamic symbol table,
    #      so Dart's lookup fails with "undefined symbol" at runtime.
    #
    # Fix both: `-u <name>` forces the linker to pull the defining
    # archive member in as if `<name>` had an undefined reference, and
    # `--export-dynamic-symbol=<name>` adds it to the dynamic table so
    # dlsym/lookupFunction can find it. Propagate to consumers via PUBLIC
    # so this applies at the final executable link (homescreen) without
    # needing changes to ivi-homescreen's own CMake.
    target_link_options(${_vpl_target} PUBLIC
        "-Wl,-u,vp_init_api_dl"
        "-Wl,-u,vp_register_port"
        "-Wl,-u,vp_unregister_port"
        "-Wl,--export-dynamic-symbol=vp_init_api_dl"
        "-Wl,--export-dynamic-symbol=vp_register_port"
        "-Wl,--export-dynamic-symbol=vp_unregister_port"
    )
endif()

if(NOT VIDEO_PLAYER_CORE_ONLY)
    if(VIDEO_PLAYER_EMBEDDER STREQUAL "ivi")
        # ivi-homescreen-plugins' parent build provides these targets
        # (platform_homescreen, flutter, plugin_common_glib). They carry
        # the include paths for <flutter/plugin_registrar_homescreen.h>,
        # <flutter_homescreen.h>, and ivi's EGL context management.
        #
        # plugin_common_glib comes from `plugins/common/` in the
        # ivi-homescreen-plugins tree. The new HomescreenPlugins.cmake
        # only add_subdirectory()s per-plugin dirs listed in
        # HOMESCREEN_PLUGINS_STATIC, so the common/ subdir isn't pulled
        # in automatically — we add it here if the target doesn't yet
        # exist and VIDEO_PLAYER_LINUX_PLUGINS_COMMON_DIR points at it.
        if(NOT TARGET plugin_common_glib)
            set(VIDEO_PLAYER_LINUX_PLUGINS_COMMON_DIR
                "${CMAKE_CURRENT_LIST_DIR}/../../../../ivi-homescreen-plugins/plugins/common"
                CACHE PATH
                "Path to ivi-homescreen-plugins' plugins/common/ dir (provides plugin_common_glib)"
            )
            if(EXISTS "${VIDEO_PLAYER_LINUX_PLUGINS_COMMON_DIR}/CMakeLists.txt")
                add_subdirectory(
                    "${VIDEO_PLAYER_LINUX_PLUGINS_COMMON_DIR}"
                    "${CMAKE_BINARY_DIR}/plugins_common_build"
                )
            else()
                message(FATAL_ERROR
                    "plugin_common_glib target not found and "
                    "VIDEO_PLAYER_LINUX_PLUGINS_COMMON_DIR "
                    "(${VIDEO_PLAYER_LINUX_PLUGINS_COMMON_DIR}) does not "
                    "contain a CMakeLists.txt. Either build ivi-homescreen "
                    "with the common plugin already loaded, or pass "
                    "-DVIDEO_PLAYER_LINUX_PLUGINS_COMMON_DIR=... .")
            endif()
        endif()
        target_link_libraries(${_vpl_target} PUBLIC
            platform_homescreen
            flutter
            plugin_common_glib
        )
        target_link_libraries(${_vpl_target} PRIVATE PkgConfig::GLES)
    elseif(VIDEO_PLAYER_EMBEDDER STREQUAL "fl")
        target_link_libraries(${_vpl_target} PRIVATE flutter)
    endif()
endif()

# Core-only (hook) builds land as libvideo_player_linux_core.so to avoid
# colliding with the full plugin .so produced by Flutter's linux/CMakeLists.txt
# pipeline — both get bundled in the app's lib/ directory, and the last
# install wins. DynamicLibrary.process() resolves FFI symbols against any
# loaded .so, so symbol lookup works regardless of which one has them.
if(VIDEO_PLAYER_CORE_ONLY)
    set_target_properties(${_vpl_target} PROPERTIES
        OUTPUT_NAME "video_player_linux_core"
        PREFIX "lib"
    )
elseif(VIDEO_PLAYER_EMBEDDER STREQUAL "fl")
    set_target_properties(${_vpl_target} PROPERTIES
        OUTPUT_NAME "video_player_linux"
        PREFIX "lib"
    )
endif()
# For ivi, the OUTPUT_NAME stays as the target name (plugin_video_player_linux),
# matching ivi-homescreen-plugins' expected archive name.

# When building in-tree (not via hooks), stage the .so into linux/ so the
# Flutter plugin's bundling logic can find it. When building via hooks,
# it ends up in the hook output directory and is bundled as a CodeAsset.
if(NOT VIDEO_PLAYER_HOOK_BUILD AND VIDEO_PLAYER_EMBEDDER STREQUAL "fl")
    set_target_properties(${_vpl_target} PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    )
endif()

# ── Flutter plugin boilerplate ────────────────────────────────────────────
# The linux/ shim reads these to wire the plugin into Flutter's bundle.
# Mirrors the pattern used by other flutter/packages Linux plugins.
# Not used by the ivi build (ivi links the static plugin directly).
if(VIDEO_PLAYER_EMBEDDER STREQUAL "fl")
    set(video_player_linux_bundled_libraries
        $<TARGET_FILE:${_vpl_target}>
        CACHE INTERNAL "List of additional libraries to be bundled by Flutter"
    )
endif()
