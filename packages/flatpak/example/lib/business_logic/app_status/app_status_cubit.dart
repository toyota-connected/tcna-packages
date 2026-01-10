import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/flatpak_repository.dart';
import '../../data/models/application_model.dart';
import '../../helpers/id_utils.dart';
import 'app_status_state.dart';

class AppStatusCubit extends Cubit<AppStatusState> {
  final FlatpakRepository repository;

  final Map<String, AppStatusInfo> _transientStates = {};

  // STATIC TRUST LISTS
  static final Set<String> _temporarilyInstalled = {};
  static final Set<String> _temporarilyUpdated = {};
  static final Set<String> _temporarilyUninstalled = {};

  AppStatusCubit({required this.repository}) : super(AppStatusInitial());

  Future<void> loadAppStatus() async {
    debugPrint('[AppStatusCubit] Loading app status from system...');
    if (state is AppStatusInitial) {
      emit(AppStatusLoading());
    }

    try {
      final installedResult = await repository.getApplicationsInstalled();
      final installed = installedResult.fold(
            (f) => <Application>[],
            (apps) => apps,
      );

      final updatesResult = await repository.getApplicationsUpdate();
      final updates = updatesResult.fold(
            (f) => <Application>[],
            (apps) => apps,
      );

      final systemInstalledIds = installed
          .map((app) => AppIdUtils.extractShortId(app.id))
          .toSet();

      // Filter out apps we simply KNOW are uninstalled
      systemInstalledIds.removeWhere((id) => _temporarilyUninstalled.contains(id));

      _temporarilyInstalled.removeWhere((id) => systemInstalledIds.contains(id));

      final effectiveInstalledIds = {...systemInstalledIds, ..._temporarilyInstalled, ..._temporarilyUpdated};

      var updatableIds = updates
          .map((app) => AppIdUtils.extractShortId(app.id))
          .toSet();

      // If system says "Needs Update" but we just updated it, ignore the system
      updatableIds.removeWhere((id) => _temporarilyUpdated.contains(id));
      updatableIds.removeWhere((id) => _temporarilyUninstalled.contains(id));

      debugPrint('[AppStatusCubit] Effective Installed: ${effectiveInstalledIds.length}, Updates: ${updatableIds.length}');

      final statusMap = <String, AppStatusInfo>{};

      for (final id in effectiveInstalledIds) {
        final transientState = _transientStates[id];

        if (transientState != null &&
            (transientState.status == AppStatus.installing ||
                transientState.status == AppStatus.updating ||
                transientState.status == AppStatus.launching)) {
          statusMap[id] = transientState;
        } else {
          final status = updatableIds.contains(id)
              ? AppStatus.needsUpdate
              : AppStatus.installed;
          statusMap[id] = AppStatusInfo(appId: id, status: status);
        }
      }

      emit(AppStatusLoaded(
        installedIds: effectiveInstalledIds,
        updatableIds: updatableIds,
        statusMap: statusMap,
      ));
    } catch (e) {
      debugPrint('[AppStatusCubit] Error: $e');
      emit(AppStatusError(e.toString()));
    }
  }

  Future<void> refresh() async => await loadAppStatus();

  void updateAppStatus(String appId, AppStatus status, {double? progress}) {
    final shortId = AppIdUtils.extractShortId(appId);
    final currentState = state;

    if (status == AppStatus.installing ||
        status == AppStatus.updating ||
        status == AppStatus.launching) {
      _transientStates[shortId] = AppStatusInfo(
        appId: shortId,
        status: status,
        progress: progress,
      );
    } else {
      _transientStates.remove(shortId);
    }

    if (currentState is AppStatusLoaded) {
      final statusMap = Map<String, AppStatusInfo>.from(currentState.statusMap);
      statusMap[shortId] = AppStatusInfo(
        appId: shortId,
        status: status,
        progress: progress,
      );
      emit(currentState.copyWith(statusMap: statusMap));
    }
  }

  Future<void> markInstalled(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    _transientStates.remove(shortId);
    _temporarilyUninstalled.remove(shortId);
    _temporarilyInstalled.add(shortId);

    Timer(const Duration(seconds: 60), () {
      if (_temporarilyInstalled.contains(shortId)) {
        _temporarilyInstalled.remove(shortId);
        loadAppStatus();
      }
    });
    await refresh();
  }

  Future<void> markUpdated(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    _transientStates.remove(shortId);
    _temporarilyUninstalled.remove(shortId);
    _temporarilyUpdated.add(shortId);

    final currentState = state;
    if (currentState is AppStatusLoaded) {
      final newInstalled = Set<String>.from(currentState.installedIds)..add(shortId);
      final newUpdates = Set<String>.from(currentState.updatableIds)..remove(shortId);

      emit(currentState.copyWith(
        installedIds: newInstalled,
        updatableIds: newUpdates,
      ));
    }

    Timer(const Duration(seconds: 60), () {
      if (_temporarilyUpdated.contains(shortId)) {
        _temporarilyUpdated.remove(shortId);
        loadAppStatus();
      }
    });

    await refresh();
  }

  Future<void> markUninstalled(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);
    debugPrint('[AppStatusCubit] Manually marking $shortId as uninstalled');

    _transientStates.remove(shortId);
    _temporarilyInstalled.remove(shortId);
    _temporarilyUpdated.remove(shortId);

    _temporarilyUninstalled.add(shortId);

    final currentState = state;
    if (currentState is AppStatusLoaded) {
      final newInstalled = Set<String>.from(currentState.installedIds)..remove(shortId);
      final newUpdates = Set<String>.from(currentState.updatableIds)..remove(shortId);
      final newMap = Map<String, AppStatusInfo>.from(currentState.statusMap)..remove(shortId);

      emit(currentState.copyWith(
        installedIds: newInstalled,
        updatableIds: newUpdates,
        statusMap: newMap,
      ));
    }

    Timer(const Duration(seconds: 60), () {
      if (_temporarilyUninstalled.contains(shortId)) {
        _temporarilyUninstalled.remove(shortId);
      }
    });
  }

  AppStatus getAppStatus(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    final currentState = state;

    if (currentState is AppStatusLoaded) {
      if (_transientStates.containsKey(shortId)) {
        return _transientStates[shortId]!.status;
      }

      // Check our manual overrides first
      if (_temporarilyUninstalled.contains(shortId)) {
        return AppStatus.notInstalled;
      }

      if (currentState.installedIds.contains(shortId)) {
        return currentState.updatableIds.contains(shortId)
            ? AppStatus.needsUpdate
            : AppStatus.installed;
      }
    }
    return AppStatus.notInstalled;
  }

  double? getProgress(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _transientStates[shortId]?.progress;
  }

  bool isInstalled(String appId) {
    final status = getAppStatus(appId);
    return status == AppStatus.installed || status == AppStatus.needsUpdate;
  }

  bool needsUpdate(String appId) {
    return getAppStatus(appId) == AppStatus.needsUpdate;
  }
}