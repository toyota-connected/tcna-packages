import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../business_logic/event_listener/event_listener_bloc.dart';
import '../business_logic/event_listener/event_listener_state.dart';
import '../business_logic/installation/installation_cubit.dart';
import '../business_logic/installed_apps/installed_apps_cubit.dart';
import '../data/models/flatpak_event_model.dart';

class InstallationStatusListener extends StatelessWidget {
  final Widget child;

  const InstallationStatusListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventListenerBloc, EventListenerState>(
      listener: (context, state) {
        print('[InstallationStatusListener] Received state: $state');
        if (state is EventListenerEventReceived) {
          print('[InstallationStatusListener] Event: ${state.event.type}');
          context.read<InstallationCubit>().handleEvent(state.event);

          switch (state.event.type) {
            case FlatpakEventType.installComplete:
            case FlatpakEventType.uninstallComplete:
            case FlatpakEventType.updateComplete:
              context.read<InstalledAppsCubit>().refreshInstalledApps();
              break;
            default:
              break;
          }
        }
      },
      child: child,
    );
  }
}