import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/app_status/app_status_cubit.dart';
import '../../business_logic/app_status/app_status_state.dart';
import '../../business_logic/event_listener/event_listener_bloc.dart';
import '../../business_logic/event_listener/event_listener_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';
import '../../data/models/flatpak_event_model.dart';
import '../../data/models/install_progress_model.dart';

class AppStatusCoordinator extends StatefulWidget {
  final Widget child;

  const AppStatusCoordinator({super.key, required this.child});

  @override
  State<AppStatusCoordinator> createState() => _AppStatusCoordinatorState();
}

class _AppStatusCoordinatorState extends State<AppStatusCoordinator> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EventListenerBloc, EventListenerState>(
          listener: (context, state) {
            if (state is EventListenerEventReceived) {
              _handleFlatpakEvent(context, state.event);
            }
          },
        ),

        BlocListener<InstallationCubit, InstallationState>(
          listener: (context, state) {
            _handleInstallationState(context, state);
          },
        ),
      ],
      child: widget.child,
    );
  }

  void _handleFlatpakEvent(BuildContext context, FlatpakEventModel event) {
    final appStatusCubit = context.read<AppStatusCubit>();

    debugPrint('[AppStatusCoordinator] Flatpak event: ${event.type} for ${event.appId}');

    switch (event.type) {
      case FlatpakEventType.installProgress:
        if (event.appId != null) {
          appStatusCubit.updateAppStatus(
            event.appId!,
            AppStatus.installing,
            progress: event.progress,
          );
        }
        break;

      case FlatpakEventType.installComplete:
        if (event.appId != null) {
          appStatusCubit.markInstalled(event.appId!);
          // Refresh to get latest state
          Future.delayed(const Duration(milliseconds: 500), () {
            appStatusCubit.refresh();
          });
        }
        break;

      case FlatpakEventType.uninstallComplete:
        if (event.appId != null) {
          appStatusCubit.markUninstalled(event.appId!);
        }
        break;

      case FlatpakEventType.updateProgress:
        if (event.appId != null) {
          appStatusCubit.updateAppStatus(
            event.appId!,
            AppStatus.updating,
            progress: event.progress,
          );
        }
        break;

      case FlatpakEventType.updateComplete:
        if (event.appId != null) {
          appStatusCubit.markUpdated(event.appId!);
          Future.delayed(const Duration(milliseconds: 500), () {
            appStatusCubit.refresh();
          });
        }
        break;

      case FlatpakEventType.installFailed:
      case FlatpakEventType.updateFailed:
      case FlatpakEventType.uninstallFailed:
      // Reset to previous state on failure
        Future.delayed(const Duration(milliseconds: 500), () {
          appStatusCubit.refresh();
        });
        break;

      default:
        break;
    }
  }

  void _handleInstallationState(BuildContext context, InstallationState state) {
    final appStatusCubit = context.read<AppStatusCubit>();

    if (state is InstallationInProgress) {
      final status = state.status == InstallationStatus.downloading
          ? (state.appId!.contains('update') ? AppStatus.updating : AppStatus.installing)
          : AppStatus.installing;

      appStatusCubit.updateAppStatus(
        state.appId!,
        status,
        progress: state.progress,
      );
    } else if (state is InstallationSuccess) {
      Future.delayed(const Duration(milliseconds: 300), () {
        appStatusCubit.refresh();
      });
    } else if (state is InstallationFailure) {
      Future.delayed(const Duration(milliseconds: 300), () {
        appStatusCubit.refresh();
      });
    }
  }
}