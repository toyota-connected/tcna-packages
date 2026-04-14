// Copyright 2020-2026 Toyota Connected North America
// SPDX-License-Identifier: Apache-2.0

import 'dart:ffi';

/// dart:ffi bindings for the zero-copy event plane exposed by the
/// `video_player_linux` native plugin. The plugin shared library is
/// already loaded into the process by whichever Flutter embedder is
/// running (GTK or ivi-homescreen), so we resolve symbols via
/// `DynamicLibrary.process()` rather than constructing a new handle.
///
/// In unit-test contexts the plugin `.so` is not loaded — symbol lookup
/// will fail and every binding becomes a no-op. This lets the Dart side
/// exercise its Pigeon control-plane logic without the native library.
/// Tests that need to drive events should use [setOverride] to inject a
/// fake, or just push events directly into the controllers.
class VideoPlayerLinuxBindings {
  VideoPlayerLinuxBindings._();

  static VideoPlayerLinuxBindings _instance = VideoPlayerLinuxBindings._();
  static VideoPlayerLinuxBindings get instance => _instance;

  /// Replace the singleton for testing. Pass `null` to restore the
  /// default implementation that resolves symbols from the process.
  static void setOverride(VideoPlayerLinuxBindings? bindings) {
    _instance = bindings ?? VideoPlayerLinuxBindings._();
  }

  // Lazily resolved. If the plugin .so isn't loaded, `_resolve()` sets
  // these to null and every Send* operation becomes a no-op.
  int Function(Pointer<Void>)? _initApiDl;
  void Function(int, int)? _registerPort;
  void Function(int)? _unregisterPort;
  bool _resolved = false;
  bool _dlInitialized = false;

  void _resolve() {
    if (_resolved) return;
    _resolved = true;
    try {
      final DynamicLibrary lib = DynamicLibrary.process();
      _initApiDl = lib.lookupFunction<IntPtr Function(Pointer<Void>),
          int Function(Pointer<Void>)>('vp_init_api_dl');
      _registerPort = lib.lookupFunction<Void Function(Int64, Int64),
          void Function(int, int)>('vp_register_port');
      _unregisterPort = lib.lookupFunction<Void Function(Int64),
          void Function(int)>('vp_unregister_port');
    } on ArgumentError {
      // Plugin .so not loaded (unit-test mode, or plugin not registered).
      _initApiDl = null;
      _registerPort = null;
      _unregisterPort = null;
    }
  }

  /// Initializes the Dart_Api_DL on the native side. Safe to call
  /// repeatedly; only the first successful call does work. No-op if the
  /// native library isn't available.
  void ensureInitialized() {
    if (_dlInitialized) return;
    _resolve();
    final int Function(Pointer<Void>)? fn = _initApiDl;
    if (fn == null) return;
    final int rc = fn(NativeApi.initializeApiDLData);
    if (rc != 0) {
      throw StateError(
          'vp_init_api_dl failed (rc=$rc) — native / Dart SDK version mismatch?');
    }
    _dlInitialized = true;
  }

  /// Hands a Dart native port to the native side, keyed by texture id.
  /// The native player posts `Dart_CObject` events straight into this port
  /// from the GStreamer streaming thread. No-op if the native library
  /// isn't available (tests).
  void registerPort(int textureId, int nativePort) {
    _resolve();
    _registerPort?.call(textureId, nativePort);
  }

  void unregisterPort(int textureId) {
    _resolve();
    _unregisterPort?.call(textureId);
  }
}
