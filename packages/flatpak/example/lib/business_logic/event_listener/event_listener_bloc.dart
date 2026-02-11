// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../data/models/flatpak_event_model.dart';
// import '../../data/repositories/flatpak_repository.dart';
// import 'event_listener_event.dart';
// import 'event_listener_state.dart';
//
// class EventListenerBloc extends Bloc<EventListenerEvent, EventListenerState> {
//   final FlatpakRepository repository;
//   StreamSubscription<FlatpakEventModel>? _eventSubscription;
//
//   EventListenerBloc({required this.repository}) : super(EventListenerIdle()) {
//     debugPrint('[EventListenerBloc] Constructor called');
//
//     on<StartListening>(_onStartListening);
//     on<StopListening>(_onStopListening);
//     on<EventReceived>(_onEventReceived);
//   }
//
//   void _onStartListening(StartListening _, Emitter<EventListenerState> emit) {
//     if (_eventSubscription != null) return;
//
//     emit(EventListenerListening());
//     repository.startEventListening();
//     _listenToStream();
//   }
//   void _onStopListening(StopListening event, Emitter<EventListenerState> emit) {
//     debugPrint('[EventListenerBloc] StopListening called');
//     _eventSubscription?.cancel();
//     _eventSubscription = null;
//     repository.stopEventListening();
//     emit(EventListenerStopped());
//   }
//
//   void _onEventReceived(EventReceived event, Emitter<EventListenerState> emit) {
//     debugPrint(
//       '[EventListenerBloc] EventReceived handler called: ${event.event.type}',
//     );
//     emit(EventListenerEventReceived(event.event));
//   }
//
//   void _listenToStream() {
//     _eventSubscription = repository.eventStream.listen(
//           (e) => add(EventReceived(e)),
//       onError: (err, st) {
//         debugPrint('[EventListenerBloc] stream error: $err');
//         _eventSubscription?.cancel();
//         _eventSubscription = null;
//         // try again after a short delay
//         Future.delayed(const Duration(seconds: 2), () {
//           if (!isClosed) add(StartListening());
//         });
//       },
//       onDone: () {
//         debugPrint('[EventListenerBloc] stream closed');
//         _eventSubscription = null;
//       },
//     );
//   }
//
//   @override
//   Future<void> close() {
//     debugPrint('[EventListenerBloc] Closing...');
//     _eventSubscription?.cancel();
//     repository.stopEventListening();
//     return super.close();
//   }
// }
