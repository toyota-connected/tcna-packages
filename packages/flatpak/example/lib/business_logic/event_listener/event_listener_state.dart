import 'package:equatable/equatable.dart';

import '../../data/models/flatpak_event_model.dart';

abstract class EventListenerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventListenerIdle extends EventListenerState {}

class EventListenerListening extends EventListenerState {}

class EventListenerStopped extends EventListenerState {}

class EventListenerEventReceived extends EventListenerState {
  final FlatpakEventModel event;
  EventListenerEventReceived(this.event);
  @override
  List<Object?> get props => [event];
}
