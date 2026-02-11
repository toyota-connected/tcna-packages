import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/app_status/app_status_cubit.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';

class AppStatusCoordinator extends StatefulWidget {
  final Widget child;

  const AppStatusCoordinator({super.key, required this.child});

  @override
  State<AppStatusCoordinator> createState() => _AppStatusCoordinatorState();
}

class _AppStatusCoordinatorState extends State<AppStatusCoordinator> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<InstallationCubit, InstallationState>(
      listener: (context, state) {
        _handleInstallationState(context, state);
      },
      child: widget.child,
    );
  }

  void _handleInstallationState(BuildContext context, InstallationState state) {
    final appStatusCubit = context.read<AppStatusCubit>();

    if (state is InstallationSuccess) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          appStatusCubit.refresh();
        }
      });
    } else if (state is InstallationFailure) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          appStatusCubit.refresh();
        }
      });
    }
  }
}