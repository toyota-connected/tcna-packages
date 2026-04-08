import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/app_launch/app_launch_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';
import 'storge_error.dart';
import 'package:flatpak_flutter_example/app_router.dart';

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
            final navContext = AppRouter.router.routerDelegate.navigatorKey.currentContext ?? context;
            if (state is InstallationSuccess) {
              ScaffoldMessenger.of(navContext).showSnackBar(
                SnackBar(
                  content: Text('${state.operation} completed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is InstallationFailure) {
              ScaffoldMessenger.of(navContext).showSnackBar(
                SnackBar(
                  content: Text('${state.operation} failed: ${state.error}'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
                ),
              );
            } else if (state is InstallationInsufficientSpace) {
              final availableGB = state.availableMb / 1024.0;
              final requiredGB = state.requiredMb / 1024.0;
              
              final mockTotalGB = availableGB + requiredGB + 20.0; // 20GB padding 
              final mockUsedGB = mockTotalGB - availableGB;

              showDialog(
                context: navContext,
                builder: (dialogContext) {
                  return StorageErrorDialog(
                    appName: state.appId,
                    usedGB: (state.requiredMb - state.availableMb) / 1024,
                    totalGB: mockTotalGB,
                    onDismiss: Navigator.of(navContext).pop,
                    onSettings: () {
                      // TODO: Handle settings navigation
                      Navigator.of(navContext).pop();
                    },
                  );
                }
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
