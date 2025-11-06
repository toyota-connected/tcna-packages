// data/data_sources/flatpak_event_data.dart
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/flatpak_event_model.dart';

abstract class FlatpakEventDataSource {
  Stream<FlatpakEventModel> get eventStream;
  void startListening();
  void stopListening();
  void dispose();
}

class FlatpakEventDataSourceImpl implements FlatpakEventDataSource {
  static const EventChannel _eventChannel =
  EventChannel('flutter.io/flatpakPlugin/flatpakEvents');

  final StreamController<FlatpakEventModel> _controller =
  StreamController<FlatpakEventModel>.broadcast();

  StreamSubscription? _subscription;
  bool _isListening = false;
  bool _isDisposed = false;

  @override
  Stream<FlatpakEventModel> get eventStream {
    if (_isDisposed) {
      throw StateError('EventDataSource has been disposed');
    }
    return _controller.stream;
  }

  @override
  void startListening() {
    if (_isListening || _isDisposed) {
      print('[FlatpakEventDataSource] Already listening or disposed');
      return;
    }

    print('[FlatpakEventDataSource] Starting to listen...');
    _isListening = true;

    _subscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
        print('[FlatpakEventDataSource] Received raw event: $event');

        if (event is Map) {
          try {
            final eventModel = FlatpakEventModel.fromJson(
              Map<String, dynamic>.from(event),
            );

            print('[FlatpakEventDataSource] Parsed event: ${eventModel.type}');

            if (!_controller.isClosed) {
              _controller.add(eventModel);
            }
          } catch (e) {
            print('[FlatpakEventDataSource] Error parsing event: $e');
            if (!_controller.isClosed) {
              _controller.addError(e);
            }
          }
        }
      },
      onError: (dynamic error) {
        print('[FlatpakEventDataSource] Event stream error: $error');
        if (!_controller.isClosed) {
          _controller.addError(error);
        }
      },
      onDone: () {
        print('[FlatpakEventDataSource] Event stream done');
        _isListening = false;
      },
      cancelOnError: false,
    );

    print('[FlatpakEventDataSource] Subscription established');
  }

  @override
  void stopListening() {
    print('[FlatpakEventDataSource] Stopping listening...');
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  @override
  void dispose() {
    print('[FlatpakEventDataSource] Disposing...');
    _isDisposed = true;
    stopListening();
    _controller.close();
  }
}