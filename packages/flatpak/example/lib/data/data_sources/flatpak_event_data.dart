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

  @override
  Stream<FlatpakEventModel> get eventStream => _controller.stream;

  @override
  void startListening() {
    if (_isListening) return;

    _isListening = true;

    _subscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
        if (event is Map) {
          try {
            final eventModel = FlatpakEventModel.fromJson(
              Map<String, dynamic>.from(event),
            );

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
    );
  }

  @override
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  void dispose() {
    stopListening();
    _controller.close();
  }
}