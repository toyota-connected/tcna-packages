import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/flatpak_event_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import 'event_listener_event.dart';
import 'event_listener_state.dart';

class EventListenerBloc extends Bloc<EventListenerEvent, EventListenerState> {
  final FlatpakRepository repository;
  StreamSubscription<FlatpakEventModel>? _eventSubscription;

  EventListenerBloc({required this.repository}) : super(EventListenerIdle()) {
    debugPrint('[EventListenerBloc] Constructor called');

    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<EventReceived>(_onEventReceived);
  }

  void _onStartListening(
    StartListening event,
    Emitter<EventListenerState> emit,
  ) async {
    debugPrint('[EventListenerBloc] StartListening called');

    if (_eventSubscription != null) {
      debugPrint('[EventListenerBloc] Already listening, ignoring');
      return;
    }

    emit(EventListenerListening());
    debugPrint('[EventListenerBloc] Emitted EventListenerListening');

    repository.startEventListening();
    debugPrint('[EventListenerBloc] Called repository.startEventListening()');

    // Subscribe to the event stream
    _eventSubscription = repository.eventStream.listen(
      (flatpakEvent) {
        debugPrint(
          '[EventListenerBloc] Received event from stream: ${flatpakEvent.type}',
        );
        add(EventReceived(flatpakEvent));
      },
      onError: (error) {
        debugPrint('[EventListenerBloc] Stream error: $error');
      },
      onDone: () {
        debugPrint('[EventListenerBloc] Stream closed');
      },
    );

    debugPrint('[EventListenerBloc] Stream subscription established');
  }

  void _onStopListening(StopListening event, Emitter<EventListenerState> emit) {
    debugPrint('[EventListenerBloc] StopListening called');
    _eventSubscription?.cancel();
    _eventSubscription = null;
    repository.stopEventListening();
    emit(EventListenerStopped());
  }

  void _onEventReceived(EventReceived event, Emitter<EventListenerState> emit) {
    debugPrint(
      '[EventListenerBloc] EventReceived handler called: ${event.event.type}',
    );
    emit(EventListenerEventReceived(event.event));
  }

  @override
  Future<void> close() {
    debugPrint('[EventListenerBloc] Closing...');
    _eventSubscription?.cancel();
    repository.stopEventListening();
    return super.close();
  }
}
