import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/flatpak_event_model.dart';

abstract class FlatpakEventDataSource {
  Stream<FlatpakEventModel> getTransactionStream(String transactionId);
  void startListening(String transactionId);
  void stopListening(String transactionId);
  void dispose();
}

class FlatpakEventDataSourceImpl implements FlatpakEventDataSource {
  final Map<String, EventChannel> _eventChannels = {};
  final Map<String, StreamController<FlatpakEventModel>> _controllers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  bool _isDisposed = false;

  @override
  Stream<FlatpakEventModel> getTransactionStream(String transactionId) {
    if (_isDisposed) {
      throw StateError('EventDataSource has been disposed');
    }

    if (!_controllers.containsKey(transactionId)) {
      _controllers[transactionId] = StreamController<FlatpakEventModel>.broadcast(
        onCancel: () {
          debugPrint('[FlatpakEventDataSource] Stream cancelled for $transactionId');
        },
      );
    }

    return _controllers[transactionId]!.stream;
  }

  @override
  void startListening(String transactionId) {
    if (_isDisposed || _subscriptions.containsKey(transactionId)) {
      return;
    }

    debugPrint('[FlatpakEventDataSource] Starting to listen to $transactionId');

    final channelName = 'flutter.io/flatpakPlugin/flatpakEvents/$transactionId';
    _eventChannels[transactionId] = EventChannel(channelName);

    if (!_controllers.containsKey(transactionId)) {
      _controllers[transactionId] = StreamController<FlatpakEventModel>.broadcast();
    }

    final controller = _controllers[transactionId]!;

    _subscriptions[transactionId] = _eventChannels[transactionId]!
        .receiveBroadcastStream()
        .listen(
          (dynamic event) {
        if (event is Map) {
          try {
            final eventModel = FlatpakEventModel.fromMap(
              Map<String, dynamic>.from(event),
            );

            debugPrint('[FlatpakEventDataSource] Event for $transactionId: ${eventModel.type}');

            if (!controller.isClosed) {
              controller.add(eventModel);
            }
          } catch (e) {
            debugPrint('[FlatpakEventDataSource] Error parsing event: $e');
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        }
      },
      onError: (dynamic error) {
        debugPrint('[FlatpakEventDataSource] Error for $transactionId: $error');
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
      onDone: () {
        debugPrint('[FlatpakEventDataSource] Done for $transactionId');
        stopListening(transactionId);
      },
      cancelOnError: false,
    );
  }

  @override
  void stopListening(String transactionId) {
    debugPrint('[FlatpakEventDataSource] Stopping $transactionId');

    _subscriptions[transactionId]?.cancel();
    _subscriptions.remove(transactionId);

    _controllers[transactionId]?.close();
    _controllers.remove(transactionId);

    _eventChannels.remove(transactionId);
  }

  @override
  void dispose() {
    debugPrint('[FlatpakEventDataSource] Disposing...');
    _isDisposed = true;

    final transactionIds = List<String>.from(_subscriptions.keys);
    for (final transactionId in transactionIds) {
      stopListening(transactionId);
    }
  }
}