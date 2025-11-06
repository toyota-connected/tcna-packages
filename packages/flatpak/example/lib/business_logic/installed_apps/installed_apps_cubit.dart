import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/flatpak_repository.dart';
import '../../helpers/id_utils.dart';
import 'installed_apps_state.dart';

class InstalledAppsCubit extends Cubit<InstalledAppsState> {
  final FlatpakRepository repository;

  InstalledAppsCubit({required this.repository})
      : super(InstalledAppsInitial());

  Future<void> loadInstalledApps() async {
    emit(InstalledAppsLoading());

    final result = await repository.getApplicationsInstalled();

    result.fold(
          (failure) => emit(InstalledAppsError(failure.message)),
          (apps) {
        final installedIds = apps
            .map((app) => AppIdUtils.extractShortId(app.id))
            .toSet();
        emit(InstalledAppsLoaded(apps: apps, installedIds: installedIds));
      },
    );
  }

  Future<void> refreshInstalledApps() async {
    final result = await repository.getApplicationsInstalled();

    result.fold(
          (failure) {
      },
          (apps) {
        final installedIds = apps
            .map((app) => AppIdUtils.extractShortId(app.id))
            .toSet();
        emit(InstalledAppsLoaded(apps: apps, installedIds: installedIds));
      },
    );
  }

  bool isInstalled(String appId) {
    final currentState = state;
    if (currentState is InstalledAppsLoaded) {
      final shortId = AppIdUtils.extractShortId(appId);
      return currentState.installedIds.contains(shortId);
    }
    return false;
  }
}