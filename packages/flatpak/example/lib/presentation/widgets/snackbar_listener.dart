import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/app_launch/app_launch_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';

class SnackbarListener extends StatelessWidget {
  final Widget child;

  const SnackbarListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Installation events
        BlocListener<InstallationCubit, InstallationState>(
          listener: (context, state) {
            if (state is InstallationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${state.operation} completed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is InstallationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${state.operation} failed: ${state.error}'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
                ),
              );
            }
          },
        ),

        // Launch events
        BlocListener<AppLaunchCubit, AppLaunchState>(
          listener: (context, state) {
            if (state is AppLaunchSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('App launched'),
                  duration: Duration(seconds: 1),
                ),
              );
            } else if (state is AppLaunchFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Launch failed: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: child,
    );
  }
}
