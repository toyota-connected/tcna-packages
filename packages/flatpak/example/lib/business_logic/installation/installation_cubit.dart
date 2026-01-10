import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/flatpak_event_model.dart';
import '../../data/models/install_progress_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import '../../helpers/id_utils.dart';
import 'installation_state.dart';
import '../app_status/app_status_cubit.dart';
import '../app_status/app_status_state.dart';

class InstallationCubit extends Cubit<InstallationState> {
  final FlatpakRepository repository;
  final AppStatusCubit appStatusCubit;

  // Tracks active operations
  final Map<String, String> _ongoingOperations = {};

  // Tracks detailed progress
  final Map<String, OperationTracker> _operationTrackers = {};
  String? _lastRequestedAppId;

  InstallationCubit({
    required this.repository,
    required this.appStatusCubit,
  }) : super(InstallationIdle());

  Future<void> installApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) {
      debugPrint('[InstallationCubit] Operation already in progress for: $shortId');
      return;
    }

    _startOperation(shortId, 'install');
    debugPrint('[InstallationCubit] Starting installation: $shortId');

    // UI update
    appStatusCubit.updateAppStatus(shortId, AppStatus.installing, progress: 0.0);
    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.downloading,
      progress: 0.0,
      message: 'Starting installation...',
    ));

    final result = await repository.installApplication(appId);

    result.fold(
          (failure) {
        debugPrint('[InstallationCubit] Installation failed start: ${failure.message}');
        _failOperation(shortId, 'install', failure.message);
        // Revert status
        appStatusCubit.updateAppStatus(shortId, AppStatus.notInstalled);
      },
          (success) {
        debugPrint('[InstallationCubit] Install API initiated: $success');
        if (_ongoingOperations.containsKey(shortId)) {
          debugPrint('[InstallationCubit] Force-completing installation for $shortId based on API result.');

          _cleanup(shortId);
          appStatusCubit.markInstalled(shortId);

          emit(InstallationSuccess(appId: shortId, operation: 'install'));

          Future.delayed(const Duration(seconds: 1), () {
            emit(InstallationIdle());
          });
        }
      },
    );
  }

  Future<void> uninstallApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) return;

    _startOperation(shortId, 'uninstall');

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.installing,
      message: 'Uninstalling...',
    ));

    final result = await repository.uninstallApplication(appId);

    result.fold(
          (failure) {
        _failOperation(shortId, 'uninstall', failure.message);
      },
          (success) {
        debugPrint('[InstallationCubit] Uninstall API returned. Forcing completion for $shortId');
        appStatusCubit.markUninstalled(shortId);
        _cleanup(shortId);
        emit(InstallationSuccess(appId: shortId, operation: 'uninstall'));
        Future.delayed(const Duration(milliseconds: 500), () {
          emit(InstallationIdle());
        });
      },
    );
  }

  Future<void> updateApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);
    if (_ongoingOperations.containsKey(shortId)) return;
    _startOperation(shortId, 'update');

    appStatusCubit.updateAppStatus(shortId, AppStatus.updating, progress: 0);

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.downloading,
      progress: 0,
      message: 'Starting update...',
    ));

    try {
      debugPrint('[InstallationCubit] Starting update: $shortId');
      await repository.updateApplication(appId);
      debugPrint('[InstallationCubit] Update API returned. Forcing completion.');
      await appStatusCubit.markUpdated(shortId);
      _cleanup(shortId);
      emit(InstallationSuccess(
          appId: shortId,
          operation: 'update'
      ));
      Future.delayed(const Duration(seconds: 1), () {
        emit(InstallationIdle());
      });

    } catch (e) {
      debugPrint('[InstallationCubit] Update Error: $e');

      _cleanup(shortId);

      appStatusCubit.updateAppStatus(shortId, AppStatus.needsUpdate);

      emit(InstallationFailure(
          appId: shortId,
          error: e.toString(),
          operation: 'update'
      ));
    }
  }
  void _startOperation(String appId, String type) {
    _ongoingOperations[appId] = type;
    _lastRequestedAppId = appId;
    _operationTrackers[appId] = OperationTracker(
      appId: appId,
      operationType: type,
    );
  }

  void _failOperation(String appId, String operation, String error) {
    debugPrint('[InstallationCubit] $operation failed for $appId: $error');
    _cleanup(appId);

    emit(InstallationFailure(
      appId: appId,
      error: error,
      operation: operation,
    ));
    Future.delayed(const Duration(seconds: 3), () {
      if (state is InstallationFailure && (state as InstallationFailure).appId == appId) {
        emit(InstallationIdle());
      }
    });
  }

  void _cleanup(String appId) {
    _ongoingOperations.remove(appId);
    _operationTrackers.remove(appId);
    if (_lastRequestedAppId == appId) {
      _lastRequestedAppId = null;
    }
  }

  void handleEvent(FlatpakEventModel event) {
    if (event.type == FlatpakEventType.unknown) return;

    String? targetAppId;
    if (event.appId != null) {
      targetAppId = AppIdUtils.extractShortId(event.appId!);
    } else {
      if (_lastRequestedAppId != null && _ongoingOperations.containsKey(_lastRequestedAppId)) {
        targetAppId = _lastRequestedAppId;
      }
    }

    if (targetAppId == null || !_ongoingOperations.containsKey(targetAppId)) {
      return;
    }

    final operation = _ongoingOperations[targetAppId]!;
    final tracker = _operationTrackers[targetAppId];

    switch (event.type) {
      case FlatpakEventType.transactionReady:
        if (tracker != null && event.totalOperations != null) {
          tracker.totalOperations = event.totalOperations!;
          tracker.operations = event.operations ?? [];
          debugPrint('[InstallationCubit] [$targetAppId] Transaction ready: ${tracker.totalOperations} ops');
        }
        break;

      case FlatpakEventType.installProgress:
      case FlatpakEventType.updateProgress:
      case FlatpakEventType.aggregatedProgress:
        double progress = event.progress ?? 0.0;
        if (progress > 1.0) progress /= 100.0;

        if (tracker != null) {
          if (event.type == FlatpakEventType.aggregatedProgress) {
            tracker.currentProgress = progress;
            if (event.completedOperations != null) {
              tracker.completedOperations = event.completedOperations!;
            }
          } else {
            tracker.currentProgress = progress;
          }
        }

        final displayProgress = progress;
        final appStatus = operation == 'update' ? AppStatus.updating : AppStatus.installing;

        appStatusCubit.updateAppStatus(targetAppId, appStatus, progress: displayProgress);

        emit(InstallationInProgress(
          appId: targetAppId,
          status: InstallationStatus.downloading,
          progress: displayProgress,
          message: event.message ?? _getMessageForRef(event.currentRef) ?? 'Processing...',
        ));
        break;

      case FlatpakEventType.operationComplete:
        if (tracker != null) {
          tracker.completedOperations++;
          debugPrint('[InstallationCubit] [$targetAppId] Op Complete: ${tracker.completedOperations}/${tracker.totalOperations}');
        }
        break;

      case FlatpakEventType.installComplete:
      case FlatpakEventType.uninstallComplete:
      case FlatpakEventType.updateComplete:
        debugPrint('[InstallationCubit] [$targetAppId] ===== COMPLETE =====');

        _cleanup(targetAppId);

        if (event.type == FlatpakEventType.installComplete) {
          appStatusCubit.markInstalled(targetAppId);
        } else if (event.type == FlatpakEventType.uninstallComplete) {
          appStatusCubit.markUninstalled(targetAppId);
        } else if (event.type == FlatpakEventType.updateComplete) {
          appStatusCubit.markUpdated(targetAppId);
        }

        emit(InstallationSuccess(appId: targetAppId, operation: operation));

        Future.delayed(const Duration(seconds: 1), () {
          emit(InstallationIdle());
        });
        break;

      case FlatpakEventType.installFailed:
      case FlatpakEventType.uninstallFailed:
      case FlatpakEventType.updateFailed:
        _failOperation(targetAppId, operation, event.error ?? event.message ?? 'Unknown error');

        if (operation == 'install') {
          appStatusCubit.updateAppStatus(targetAppId, AppStatus.notInstalled);
        } else {
          appStatusCubit.refresh();
        }
        break;

      default:
        break;
    }
  }

  String? _getMessageForRef(String? ref) {
    if (ref == null) return null;
    if (ref.contains('runtime/')) return 'Installing dependencies...';
    if (ref.contains('app/')) return 'Installing application...';
    return null;
  }

  String? getOperationType(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _ongoingOperations[shortId];
  }

  bool isOperationInProgress(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _ongoingOperations.containsKey(shortId);
  }
}

class OperationTracker {
  final String appId;
  final String operationType;
  int totalOperations = 1;
  int completedOperations = 0;
  double currentProgress = 0.0;
  List<OperationInfo> operations = [];

  OperationTracker({required this.appId, required this.operationType});

  double get overallProgress {
    if (totalOperations == 0) return 0.0;
    final val = (completedOperations + currentProgress) / totalOperations;
    return val.clamp(0.0, 1.0);
  }
}