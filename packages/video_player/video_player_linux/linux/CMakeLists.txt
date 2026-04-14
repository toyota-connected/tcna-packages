# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2020-2026 Toyota Connected North America
#
# Flutter Linux plugin discovery shim. Flutter's build system expects a
# target named `${PLUGIN_NAME}` here. We delegate to the package-root
# CMakeLists.txt (which holds the real sources) and then alias its
# output as the expected plugin target.

cmake_minimum_required(VERSION 3.13)
set(PROJECT_NAME "video_player_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "video_player_linux_plugin")
set(VIDEO_PLAYER_EMBEDDER "fl" CACHE STRING "" FORCE)

# Build the real library from the package root.
add_subdirectory(
    "${CMAKE_CURRENT_LIST_DIR}/.."
    "${CMAKE_CURRENT_BINARY_DIR}/video_player_linux_root"
)

# Flutter expects the plugin target name; expose ours under that alias.
add_library(${PLUGIN_NAME} ALIAS video_player_linux)

# Tell Flutter to bundle the .so into the app.
set(${PROJECT_NAME}_bundled_libraries
    "$<TARGET_FILE:video_player_linux>"
    PARENT_SCOPE
)
