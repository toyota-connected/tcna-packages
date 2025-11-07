// data/data_sources/flatpak_event_data.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/flatpak_event_model.dart';

abstract class FlatpakEventDataSource {
  Stream<FlatpakEventModel> get eventStream;
  void startListening();
  void stopListening();
  void dispose();
}

class FlatpakEventDataSourceImpl implements FlatpakEventDataSource {
  static const EventChannel _eventChannel = EventChannel(
    'flutter.io/flatpakPlugin/flatpakEvents',
  );

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
      debugPrint('[FlatpakEventDataSource] Already listening or disposed');
      return;
    }

    debugPrint('[FlatpakEventDataSource] Starting to listen...');
    _isListening = true;

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        debugPrint('[FlatpakEventDataSource] Received raw event: $event');

        if (event is Map) {
          try {
            final eventModel = FlatpakEventModel.fromJson(
              Map<String, dynamic>.from(event),
            );

            debugPrint(
              '[FlatpakEventDataSource] Parsed event: ${eventModel.type}',
            );

            if (!_controller.isClosed) {
              _controller.add(eventModel);
            }
          } catch (e) {
            debugPrint('[FlatpakEventDataSource] Error parsing event: $e');
            if (!_controller.isClosed) {
              _controller.addError(e);
            }
          }
        }
      },
      onError: (dynamic error) {
        debugPrint('[FlatpakEventDataSource] Event stream error: $error');
        if (!_controller.isClosed) {
          _controller.addError(error);
        }
      },
      onDone: () {
        debugPrint('[FlatpakEventDataSource] Event stream done');
        _isListening = false;
      },
      cancelOnError: false,
    );

    debugPrint('[FlatpakEventDataSource] Subscription established');
  }

  @override
  void stopListening() {
    debugPrint('[FlatpakEventDataSource] Stopping listening...');
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  @override
  void dispose() {
    debugPrint('[FlatpakEventDataSource] Disposing...');
    _isDisposed = true;
    stopListening();
    _controller.close();
  }
}
