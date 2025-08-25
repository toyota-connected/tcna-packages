import 'package:filament_scene/engine.dart';
import 'package:flutter/services.dart';
import 'package:fluorite_examples_demo/main.dart';
import 'dart:io';
import 'package:filament_scene/generated/messages.g.dart';

typedef UpdateCallback = void Function(FilamentViewApi api, double deltaTime);
typedef TriggerEventFunction = void Function(String eventName);

void noopUpdate(FilamentViewApi api, double deltaTime) {}

class FrameEventChannel {
  static const EventChannel _eventChannel = EventChannel('plugin.filament_view.frame_view');

  bool bWriteEventsToLog = false;

  late FilamentViewApi filamentViewApi;
  void setController(FilamentViewApi api) {
    filamentViewApi = api;
  }

  final List<UpdateCallback> _callbacks = List<UpdateCallback>.empty(growable: true);
  void addCallback(UpdateCallback callback) {
    _callbacks.add(callback);
  }

  void removeCallback(UpdateCallback callback) {
    _callbacks.remove(callback);
  }

  // Frames from Native to here, currently run in order of
  // - updateFrame - Called regardless if a frame is going to be drawn or not
  // - preRenderFrame - Called before native <features>, but we know we're going to draw a frame
  // - renderFrame - Called after native <features>, right before drawing a frame
  // - postRenderFrame - Called after we've drawn natively, right after drawing a frame.
  void initEventChannel() {
    try {
      // Listen for events from the native side
      _eventChannel.receiveBroadcastStream().listen(
        (event) async {
          // Handle incoming event
          // print('Received event: $event\n');
          // const double deltaTime = 0.016;

          if (event is Map) {
            final deltaTime = event['deltaTime'];
            final method = event['method'];

            // Log extracted values
            if (method == 'preRenderFrame') {
              final scriptTimeStart = DateTime.now().microsecondsSinceEpoch;

              for (final onUpdate in _callbacks) {
                onUpdate(filamentViewApi, deltaTime);
              }

              await filamentViewApi.drainFrameTasks();

              // TODO(kerberjg): this is temporary, should be dictated by the native core
              final scriptFrameTime = DateTime.now().microsecondsSinceEpoch - scriptTimeStart;

              frameProfilingDataNotifier.value = FrameProfilingData(
                deltaTime: deltaTime,
                cpuFrameTime: event['cpuFt'] ?? 0.0,
                gpuFrameTime: event['gpuFt'] ?? 0.0,
                scriptFrameTime: scriptFrameTime / 1000.0, // Convert to milliseconds
                fps: event['fps'] ?? 60.0,
              );

              // Send "done_updateScripts" event to native
              // _eventChannel.binaryMessenger.send(
              //   'plugin.filament_view.frame_view',
              //   const StandardMessageCodec().encodeMessage(<String, dynamic>{
              //     'method': 'done_updateScripts',
              //   }),
              // );
            }
          }
        },
        onError: (error) {
          // Handle specific errors
          if (error is MissingPluginException) {
            stdout.write(
              'MissingPluginException: Make sure the plugin is registered on the native side.\nDetails: $error\n',
            );
          } else {
            stdout.write('Other Error: $error\n');
          }
        },
      );
    } catch (e, stackTrace) {
      // Catch any synchronous exceptions
      if (e is MissingPluginException) {
        stdout.write(
          'Caught MissingPluginException during EventChannel initialization.\nDetails: $e\nStack Trace:\n$stackTrace\n',
        );
      } else {
        stdout.write('Unexpected Error: $e\nStack Trace:\n$stackTrace\n');
      }
    }
  }
}
