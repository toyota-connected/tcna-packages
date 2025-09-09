import 'package:filament_scene/engine.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/services.dart';
import 'package:fluorite_examples_demo/main.dart';
import 'dart:io';
import 'package:filament_scene/generated/messages.g.dart';

typedef UpdateCallback = void Function(FilamentViewApi api, double deltaTime);
typedef TriggerEventFunction = void Function(String eventName);

void noopUpdate(FilamentViewApi api, double deltaTime) {}

class FrameEventChannel {
  static const EventChannel _eventChannel = EventChannel('plugin.filament_view.frame_view');
  static const MethodChannel _eventBus = MethodChannel('plugin.filament_view.event_bus');
  late FilamentViewApi filamentViewApi;

  bool bWriteEventsToLog = false;

  static FrameEventChannel? _instance;

  FrameEventChannel._internal() {
    _eventBus.setMethodCallHandler(_handleNativeCall);
  }

  factory FrameEventChannel() {
    // ignore: dead_null_aware_expression
    return _instance ??= FrameEventChannel._internal();
  }

  static Future<int> _handleNativeCall(MethodCall call) async {
    // print("FrameEventChannel: Handling native call");
    String method = call.method;
    final JsonObject args = (call.arguments as Map<dynamic, dynamic>).map<String, dynamic>((
      key,
      value,
    ) {
      return MapEntry(key.toString(), value);
    });

    // print('FrameEventChannel: Received method call: $method with args: $args');

    // Handle method calls from the native side
    if (method.startsWith("call_")) {
      method = method.substring(5);
    } else {
      throw MissingPluginException('No handler for method: ${call.method}');
    }

    switch (method) {
      case 'preRenderFrame':
        await _instance!._onPreRenderFrame(args);
        break;
      default:
        throw MissingPluginException('No handler for method: ${call.method}');
    }

    // print("FrameEventChannel: Callback completed for method: $method");
    return 0;
  }

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
            final method = event['method'];

            // Log extracted values
            if (method == 'preRenderFrame') {
              await _onPreRenderFrame(event as JsonObject);
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

  Future<void> _onPreRenderFrame(JsonObject event) async {
    // Handle preRenderFrame event
    final deltaTime = event['deltaTime'];

    //
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

    // Sends "done" signal to native
    return;
  }
}
