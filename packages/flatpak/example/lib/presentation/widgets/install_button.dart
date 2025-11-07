import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';
import '../../business_logic/installed_apps/installed_apps_cubit.dart';
import '../../business_logic/installed_apps/installed_apps_state.dart';
import '../../data/models/application_model.dart';

class InstallButton extends StatelessWidget {
  final Application app;

  const InstallButton({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstalledAppsCubit, InstalledAppsState>(
      builder: (context, installedState) {
        final isInstalled =
            installedState is InstalledAppsLoaded &&
            installedState.installedIds.contains(app.shortId);

        return BlocBuilder<InstallationCubit, InstallationState>(
          builder: (context, installState) {
            final installCubit = context.read<InstallationCubit>();
            final isInProgress = installCubit.isOperationInProgress(app.id);

            if (isInProgress && installState is InstallationInProgress) {
              if (installState.appId == app.shortId) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: installState.progress > 0
                          ? installState.progress
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      installState.message ?? 'Installing...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(installState.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }
            }

            if (isInstalled) {
              return ElevatedButton.icon(
                onPressed: () {
                  context.read<InstallationCubit>().uninstallApp(app.id);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Uninstall'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              );
            }

            return ElevatedButton.icon(
              onPressed: () {
                context.read<InstallationCubit>().installApp(app.id);
              },
              icon: const Icon(Icons.download),
              label: const Text('Install'),
            );
          },
        );
      },
    );
  }
}
