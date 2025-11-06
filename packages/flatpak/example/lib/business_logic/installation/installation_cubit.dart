import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/flatpak_event_model.dart';
import '../../data/models/install_progress_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import '../../helpers/id_utils.dart';
import 'installation_state.dart';

class InstallationCubit extends Cubit<InstallationState> {
  final FlatpakRepository repository;

  final Map<String, String> _ongoingOperations = {};

  String? _currentOperationAppId;

  InstallationCubit({required this.repository}) : super(InstallationIdle());

  Future<void> installApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) {
      return;
    }

    _ongoingOperations[shortId] = 'install';
    _currentOperationAppId = shortId;

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.downloading,
      progress: 0.0,
      message: 'Starting installation...',
    ));

    final result = await repository.installApplication(appId);

    result.fold(
          (failure) {
        _ongoingOperations.remove(shortId);
        _currentOperationAppId = null;
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'install',
        ));
      },
          (success) {
        print('[InstallationCubit] Install API call completed: $success');
      },
    );
  }

  Future<void> uninstallApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) {
      return;
    }

    _ongoingOperations[shortId] = 'uninstall';
    _currentOperationAppId = shortId;

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.installing,
      message: 'Uninstalling...',
    ));

    final result = await repository.uninstallApplication(appId);

    result.fold(
          (failure) {
        _ongoingOperations.remove(shortId);
        _currentOperationAppId = null;
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'uninstall',
        ));
      },
          (success) {},
    );
  }

  Future<void> updateApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) {
      return;
    }

    _ongoingOperations[shortId] = 'update';
    _currentOperationAppId = shortId;

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.downloading,
      progress: 0.0,
      message: 'Updating...',
    ));

    final result = await repository.updateApplication(appId);

    result.fold(
          (failure) {
        _ongoingOperations.remove(shortId);
        _currentOperationAppId = null;
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'update',
        ));
      },
          (success) {},
    );
  }

  void handleEvent(FlatpakEvent event) {
    print('[InstallationCubit] handleEvent: type=${event.type}, appId=${event.appId}, progress=${event.progress}');

    if (event.type == FlatpakEventType.unknown) {
      return;
    }

    final String? targetAppId;
    if (event.appId != null) {
      targetAppId = AppIdUtils.extractShortId(event.appId!);
    } else if (_currentOperationAppId != null) {
      targetAppId = _currentOperationAppId;
      print('[InstallationCubit] Using current operation appId: $targetAppId');
    } else {
      print('[InstallationCubit] No appId in event and no current operation');
      return;
    }

    final operation = _ongoingOperations[targetAppId];

    if (operation == null) {
      print('[InstallationCubit] No ongoing operation for: $targetAppId');
      return;
    }

    print('[InstallationCubit] Processing event for $targetAppId: $operation');

    switch (event.type) {
      case FlatpakEventType.installProgress:
      case FlatpakEventType.updateProgress:
        double normalizedProgress = event.progress ?? 0.0;
        if (normalizedProgress > 1.0) {
          normalizedProgress = normalizedProgress / 100.0;
        }

        print('[InstallationCubit] Progress: ${normalizedProgress * 100}%');
        emit(InstallationInProgress(
          appId: targetAppId,
          status: InstallationStatus.downloading,
          progress: normalizedProgress,
          message: event.message ?? 'Downloading...',
        ));
        break;

      case FlatpakEventType.installComplete:
      case FlatpakEventType.uninstallComplete:
      case FlatpakEventType.updateComplete:
        print('[InstallationCubit] Operation complete for: $targetAppId');
        _ongoingOperations.remove(targetAppId);
        _currentOperationAppId = null;
        emit(InstallationSuccess(appId: targetAppId, operation: operation));
        Future.delayed(const Duration(seconds: 2), () {
          if (state is InstallationSuccess) {
            emit(InstallationIdle());
          }
        });
        break;

      case FlatpakEventType.installFailed:
      case FlatpakEventType.uninstallFailed:
      case FlatpakEventType.updateFailed:
        print('[InstallationCubit] Operation failed for: $targetAppId');
        _ongoingOperations.remove(targetAppId);
        _currentOperationAppId = null;
        emit(InstallationFailure(
          appId: targetAppId,
          error: event.error ?? event.message ?? 'Operation failed',
          operation: operation,
        ));
        break;

      default:
        break;
    }
  }

  bool isOperationInProgress(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _ongoingOperations.containsKey(shortId);
  }

  String? getOperationType(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _ongoingOperations[shortId];
  }

  @override
  Future<void> close() {
    print('[InstallationCubit] Closing...');
    _currentOperationAppId = null;
    return super.close();
  }
}