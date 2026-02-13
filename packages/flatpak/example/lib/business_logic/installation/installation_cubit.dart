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
  final Map<String, StreamSubscription> _transactionSubscriptions = {};
  final Map<String, OperationTracker> _operationTrackers = {};

  InstallationCubit({
    required this.repository,
    required this.appStatusCubit,
  }) : super(InstallationIdle());

  Future<void> installApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_operationTrackers.containsKey(shortId)) {
      debugPrint('[InstallationCubit] Already installing $shortId');
      return;
    }

    _operationTrackers[shortId] = OperationTracker(
      appId: shortId,
      operationType: 'install',
    );
    debugPrint('[InstallationCubit] Starting install for $shortId');

    debugPrint('[InstallationCubit] Setting up event channel for $shortId');
    final setupResult = await repository.setupEventChannel(appId);
    await setupResult.fold(
          (failure) async {
        debugPrint('[InstallationCubit] Failed to setup channel: ${failure.message}');
        _cleanup(shortId);
        emit(InstallationFailure(
          appId: shortId,
          error: 'Failed to setup event channel: ${failure.message}',
          operation: 'install',
        ));
        return;
      },
          (_) async {
        debugPrint('[InstallationCubit] Event channel setup complete');
      },
    );

    debugPrint('[InstallationCubit] Starting Flutter event listener for $shortId');
    await _listenToTransaction(shortId);

    await Future.delayed(const Duration(milliseconds: 150));
    appStatusCubit.updateAppStatus(shortId, AppStatus.installing, progress: 0.0);
    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.downloading,
      progress: 0.0,
      message: 'Starting installation...',
    ));

    debugPrint('[InstallationCubit] Calling install API for $shortId');
    final result = await repository.installApplication(appId);
    result.fold(
          (failure) {
        debugPrint('[InstallationCubit] Failed to start install: ${failure.message}');
        _cleanup(shortId);
        appStatusCubit.updateAppStatus(shortId, AppStatus.notInstalled);
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'install',
        ));
      },
          (success) {
        debugPrint('[InstallationCubit] Install initiated for $shortId');
      },
    );
  }

  Future<void> uninstallApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_operationTrackers.containsKey(shortId)) return;

    _operationTrackers[shortId] = OperationTracker(
      appId: shortId,
      operationType: 'uninstall',
    );

    await repository.setupEventChannel(appId);
    await _listenToTransaction(shortId);
    await Future.delayed(const Duration(milliseconds: 150));

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.installing,
      message: 'Uninstalling...',
    ));

    await _listenToTransaction(shortId);

    final result = await repository.uninstallApplication(appId);

    result.fold(
          (failure) {
        _cleanup(shortId);
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'uninstall',
        ));
      },
          (success) {
        debugPrint('[InstallationCubit] Uninstall initiated');
      },
    );
  }

  Future<void> updateApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_operationTrackers.containsKey(shortId)) return;

    _operationTrackers[shortId] = OperationTracker(
      appId: shortId,
      operationType: 'update',
    );

    await repository.setupEventChannel(appId);
    await _listenToTransaction(shortId);
    await Future.delayed(const Duration(milliseconds: 150));

    appStatusCubit.updateAppStatus(shortId, AppStatus.updating, progress: 0);

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.downloading,
      progress: 0,
      message: 'Starting update...',
    ));

    _listenToTransaction(shortId);

    final result = await repository.updateApplication(appId);

    result.fold(
          (failure) {
        _cleanup(shortId);
        appStatusCubit.updateAppStatus(shortId, AppStatus.needsUpdate);
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'update',
        ));
      },
          (success) {
        debugPrint('[InstallationCubit] Update initiated');
      },
    );
  }

  Future<void> _listenToTransaction(String appId) async{
    debugPrint('[InstallationCubit] Listening to transaction stream for $appId');

    await Future.delayed(const Duration(milliseconds: 50));
    repository.startEventListening(appId);

    final subscription = repository.getTransactionStream(appId).listen(
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
    repository.stopEventListening(appId);

    _transactionSubscriptions[appId]?.cancel();
    _transactionSubscriptions.remove(appId);
    _operationTrackers.remove(appId);
  }

  bool isOperationInProgress(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _operationTrackers.containsKey(shortId);
  }

  String? getOperationType(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _operationTrackers[shortId]?.operationType;
  }

  @override
  Future<void> close() {
    for (final appId in List<String>.from(_operationTrackers.keys)) {
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

  OperationTracker({
    required this.appId,
    required this.operationType,
  });

  double get overallProgress {
    if (totalOperations == 0) return 0.0;
    return ((completedOperations + currentProgress) / totalOperations).clamp(0.0, 1.0);
  }
}