import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/event_listener/event_listener_bloc.dart';
import '../../business_logic/event_listener/event_listener_state.dart';
import '../../business_logic/installation/installation_cubit.dart';

class InstallationStatusListener extends StatelessWidget {
  final Widget child;

  const InstallationStatusListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventListenerBloc, EventListenerState>(
      listener: (context, state) {
        debugPrint('[InstallationStatusListener] Received state: $state');

        if (state is EventListenerEventReceived) {
          final event = state.event;
          debugPrint('[InstallationStatusListener] Event: ${event.type}');
          context.read<InstallationCubit>().handleEvent(event);
        }
      },
      child: child,
    );
  }
}