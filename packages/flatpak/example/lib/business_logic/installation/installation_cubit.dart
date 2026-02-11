import 'dart:async';

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

  // Track transaction ID for each app
  final Map<String, String> _appToTransactionId = {};
  final Map<String, StreamSubscription> _transactionSubscriptions = {};
  final Map<String, OperationTracker> _operationTrackers = {};

  InstallationCubit({
    required this.repository,
    required this.appStatusCubit,
  }) : super(InstallationIdle());

  Future<void> installApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_appToTransactionId.containsKey(shortId)) {
      debugPrint('[InstallationCubit] Operation already in progress for: $shortId');
      return;
    }

    debugPrint('[InstallationCubit] Starting installation: $shortId');

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
        debugPrint('[InstallationCubit] Installation failed: ${failure.message}');
        appStatusCubit.updateAppStatus(shortId, AppStatus.notInstalled);
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'install',
        ));
      },
          (transactionId) {
        debugPrint('[InstallationCubit] Transaction started: $transactionId');

        // Track this transaction
        _appToTransactionId[shortId] = transactionId;
        _operationTrackers[shortId] = OperationTracker(
          appId: shortId,
          operationType: 'install',
        );

        // Start listening to this transaction's events
        _listenToTransaction(shortId, transactionId);
      },
    );
  }

  Future<void> uninstallApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);
    if (_appToTransactionId.containsKey(shortId)) return;

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.installing,
      message: 'Uninstalling...',
    ));

    final result = await repository.uninstallApplication(appId);

    result.fold(
          (failure) {
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'uninstall',
        ));
      },
          (transactionId) {
        _appToTransactionId[shortId] = transactionId;
        _operationTrackers[shortId] = OperationTracker(
          appId: shortId,
          operationType: 'uninstall',
        );
        _listenToTransaction(shortId, transactionId);
      },
    );
  }

  Future<void> updateApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);
    if (_appToTransactionId.containsKey(shortId)) return;

    appStatusCubit.updateAppStatus(shortId, AppStatus.updating, progress: 0);

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.downloading,
      progress: 0,
      message: 'Starting update...',
    ));

    final result = await repository.updateApplication(appId);

    result.fold(
          (failure) {
        appStatusCubit.updateAppStatus(shortId, AppStatus.needsUpdate);
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'update',
        ));
      },
          (transactionId) {
        _appToTransactionId[shortId] = transactionId;
        _operationTrackers[shortId] = OperationTracker(
          appId: shortId,
          operationType: 'update',
        );
        _listenToTransaction(shortId, transactionId);
      },
    );
  }

  void _listenToTransaction(String appId, String transactionId) {
    debugPrint('[InstallationCubit] Listening to transaction: $transactionId for $appId');

    // Start event listening for this transaction
    repository.startEventListening(transactionId);

    // Subscribe to the transaction's event stream
    final subscription = repository.getTransactionStream(transactionId).listen(
          (event) {
        debugPrint('[InstallationCubit] Event for $appId: ${event.type}');
        _handleTransactionEvent(appId, event);
      },
      onError: (error) {
        debugPrint('[InstallationCubit] Error for $appId: $error');
        _cleanup(appId);
        emit(InstallationFailure(
          appId: appId,
          error: error.toString(),
          operation: _operationTrackers[appId]?.operationType ?? 'unknown',
        ));
      },
      onDone: () {
        debugPrint('[InstallationCubit] Stream done for $appId');
      },
    );

    _transactionSubscriptions[appId] = subscription;
  }

  void _handleTransactionEvent(String appId, FlatpakEventModel event) {
    final tracker = _operationTrackers[appId];
    if (tracker == null) return;

    switch (event.type) {
      case FlatpakEventType.transactionReady:
        if (event.totalOperations != null) {
          tracker.totalOperations = event.totalOperations!;
          tracker.operations = event.operations ?? [];
        }
        break;

      case FlatpakEventType.installProgress:
      case FlatpakEventType.updateProgress:
      case FlatpakEventType.aggregatedProgress:
        double progress = event.progress ?? 0.0;
        if (progress > 1.0) progress /= 100.0;

        tracker.currentProgress = progress;
        if (event.completedOperations != null) {
          tracker.completedOperations = event.completedOperations!;
        }

        final appStatus = tracker.operationType == 'update'
            ? AppStatus.updating
            : AppStatus.installing;

        appStatusCubit.updateAppStatus(appId, appStatus, progress: progress);

        emit(InstallationInProgress(
          appId: appId,
          status: InstallationStatus.downloading,
          progress: progress,
          message: event.message ?? 'Processing...',
        ));
        break;

      case FlatpakEventType.operationComplete:
        tracker.completedOperations++;
        break;

      case FlatpakEventType.installComplete:
        appStatusCubit.markInstalled(appId);
        _completeOperation(appId, 'install');
        break;

      case FlatpakEventType.uninstallComplete:
        appStatusCubit.markUninstalled(appId);
        _completeOperation(appId, 'uninstall');
        break;

      case FlatpakEventType.updateComplete:
        appStatusCubit.markUpdated(appId);
        _completeOperation(appId, 'update');
        break;

      case FlatpakEventType.installFailed:
      case FlatpakEventType.uninstallFailed:
      case FlatpakEventType.updateFailed:
        final error = event.error ?? event.message ?? 'Unknown error';
        _failOperation(appId, tracker.operationType, error);
        break;

      default:
        break;
    }
  }
  void _completeOperation(String appId, String operation) {
    debugPrint('[InstallationCubit] Operation complete: $appId');

    emit(InstallationSuccess(appId: appId, operation: operation));

    Future.delayed(const Duration(seconds: 1), () {
      if (!isClosed) {
        emit(InstallationIdle());
      }
    });

    _cleanup(appId);
  }

  void _failOperation(String appId, String operation, String error) {
    debugPrint('[InstallationCubit] Operation failed: $appId - $error');

    emit(InstallationFailure(
      appId: appId,
      error: error,
      operation: operation,
    ));

    _cleanup(appId);

    Future.delayed(const Duration(seconds: 3), () {
      if (!isClosed && state is InstallationFailure) {
        final failureState = state as InstallationFailure;
        if (failureState.appId == appId) {
          emit(InstallationIdle());
        }
      }
    });
  }

  void _cleanup(String appId) {
    final transactionId = _appToTransactionId[appId];
    if (transactionId != null) {
      repository.stopEventListening(transactionId);
    }

    _transactionSubscriptions[appId]?.cancel();
    _transactionSubscriptions.remove(appId);
    _appToTransactionId.remove(appId);
    _operationTrackers.remove(appId);
  }

  bool isOperationInProgress(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _appToTransactionId.containsKey(shortId);
  }

  String? getOperationType(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _operationTrackers[shortId]?.operationType;
  }

  @override
  Future<void> close() {
    for (final appId in List<String>.from(_appToTransactionId.keys)) {
      _cleanup(appId);
    }
    return super.close();
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