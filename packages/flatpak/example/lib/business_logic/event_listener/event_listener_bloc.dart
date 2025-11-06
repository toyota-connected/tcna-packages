import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/flatpak_event_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import 'event_listener_event.dart';
import 'event_listener_state.dart';

class EventListenerBloc extends Bloc<EventListenerEvent, EventListenerState> {
  final FlatpakRepository repository;
  StreamSubscription<FlatpakEventModel>? _eventSubscription;

  EventListenerBloc({required this.repository}) : super(EventListenerIdle()) {
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<EventReceived>(_onEventReceived);
  }

  void _onStartListening(
      StartListening event,
      Emitter<EventListenerState> emit,
      ) async {
    if (_eventSubscription != null) return;

    emit(EventListenerListening());

    // Start listening on the data source
    repository.startEventListening();

    // Subscribe to the event stream
    _eventSubscription = repository.eventStream.listen(
          (flatpakEvent) {
        add(EventReceived(flatpakEvent));
      },
      onError: (error) {
        print('[EventListenerBloc] Error: $error');
        // Optionally emit an error state
      },
      onDone: () {
        print('[EventListenerBloc] Stream closed');
      },
    );
  }

  void _onStopListening(
      StopListening event,
      Emitter<EventListenerState> emit,
      ) {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    repository.stopEventListening();
    emit(EventListenerStopped());
  }

  void _onEventReceived(
      EventReceived event,
      Emitter<EventListenerState> emit,
      ) {
    emit(EventListenerEventReceived(event.event));
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    repository.stopEventListening();
    return super.close();
  }
}