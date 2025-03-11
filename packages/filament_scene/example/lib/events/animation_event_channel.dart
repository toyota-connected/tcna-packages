import 'package:flutter/services.dart';
import 'dart:io';

class AnimationEventChannel {
  static const EventChannel _eventChannel =
      EventChannel('plugin.filament_view.animation_info');

  bool bWriteEventsToLog = false;

  // Example:
  /*
  Key: animation_event_data, Value: 1 // m_nCurrentPlayingIndex
  Key: animation_event_type, Value: 1 // AnimationEventType
  // what you would use to call functionality from the controller
  Key: global_guid, Value: 184ee0b0-a280-4976-8eae-0a33083b315b
  Key: animation_event_data, Value: 1 // m_nCurrentPlayingIndex
  Key: animation_event_type, Value: 0 // AnimationEventType
  // what you would use to call functionality from the controller
  Key: global_guid, Value: 184ee0b0-a280-4976-8eae-0a33083b315b
  */

  void initEventChannel() {
    try {
      // Listen for events from the native side
      _eventChannel.receiveBroadcastStream().listen(
        (event) {
          // Handle incoming event
          if (bWriteEventsToLog) stdout.write('Received event: $event\n');
        },
        onError: (error) {
          // Handle specific errors
          if (error is MissingPluginException) {
            stdout.write(
                'MissingPluginException: Make sure the plugin is registered on the native side.\nDetails: $error\n');
          } else {
            stdout.write('Other Error: $error\n');
          }
        },
      );
    } catch (e, stackTrace) {
      // Catch any synchronous exceptions
      if (e is MissingPluginException) {
        stdout.write(
            'Caught MissingPluginException during EventChannel initialization.\nDetails: $e\nStack Trace:\n$stackTrace\n');
      } else {
        stdout.write('Unexpected Error: $e\nStack Trace:\n$stackTrace\n');
      }
    }
  }
}
