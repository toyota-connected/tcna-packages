import 'package:equatable/equatable.dart';
import '../../data/models/flatpak_event_model.dart';

abstract class EventListenerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartListening extends EventListenerEvent {}

class StopListening extends EventListenerEvent {}

class EventReceived extends EventListenerEvent {
  final FlatpakEvent event;
  EventReceived(this.event);
  @override
  List<Object?> get props => [event];
}
