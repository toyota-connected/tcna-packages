import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeReadiness {
  static const MethodChannel _readinessChecker =
      MethodChannel('plugin.filament_view.readiness_checker');
  static const EventChannel _readinessChannel =
      EventChannel('plugin.filament_view.readiness');

  /// Adds a one-time callback to be called when the native side is ready.
  /// If a the native side is already ready, a check is scheduled immediately,
  /// and retried  until the callback is called.
  void addCallback(Function callback, [int maxRetries = 60 * 30, Duration retryInterval = const Duration(milliseconds: 16)]) {
    int attempt = 0;

    // print('Ready?');

    unawaited(() async {
      for (attempt = 1; attempt <= maxRetries; attempt++) {
        // print('Checking native readiness, attempt $attempt...');
        try {
          final bool nativeReady = await isNativeReady();

          if (nativeReady) {
            // print('yippee?');
            callback();
            // print('yippee!');
            return;
          }
        } catch (e) {
          //print('Error checking readine/ss: $e');
        }

        await Future.delayed(retryInterval);
      }
    }());
  }

  Future<bool> isNativeReady() async {
    try {
      final bool ready =
          await _readinessChecker.invokeMethod<bool>('isReady') ?? false;
      return ready;
    } catch (e) {
      //print('Error checking native readiness: $e');
      return false;
    }
  }

  Stream<String> get readinessStream => _readinessChannel
      .receiveBroadcastStream()
      .map((event) => event as String);
}
