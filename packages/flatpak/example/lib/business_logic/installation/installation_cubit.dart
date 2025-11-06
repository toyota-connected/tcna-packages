import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/flatpak_event_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import '../../helpers/id_utils.dart';
import 'installation_state.dart';
import '../../../data/models/install_progress_model.dart';

class InstallationCubit extends Cubit<InstallationState> {
  final FlatpakRepository repository;

  // Track ongoing operations by short ID
  final Map<String, String> _ongoingOperations = {};

  InstallationCubit({required this.repository}) : super(InstallationIdle());

  Future<void> installApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) {
      return;
    }

    _ongoingOperations[shortId] = 'install';

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
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'install',
        ));
      },
          (success) {
        // Wait for event from event channel for completion
      },
    );
  }

  Future<void> uninstallApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) {
      return;
    }

    _ongoingOperations[shortId] = 'uninstall';

    emit(InstallationInProgress(
      appId: shortId,
      status: InstallationStatus.installing,
      message: 'Uninstalling...',
    ));

    final result = await repository.uninstallApplication(appId);

    result.fold(
          (failure) {
        _ongoingOperations.remove(shortId);
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'uninstall',
        ));
      },
          (success) {
      },
    );
  }

  Future<void> updateApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_ongoingOperations.containsKey(shortId)) {
      return;
    }

    _ongoingOperations[shortId] = 'update';

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
        emit(InstallationFailure(
          appId: shortId,
          error: failure.message,
          operation: 'update',
        ));
      },
          (success) {
      },
    );
  }

  void handleEvent(FlatpakEvent event) {
    if (event.appId == null) return;

    final shortId = AppIdUtils.extractShortId(event.appId!);
    final operation = _ongoingOperations[shortId];

    if (operation == null) return;

    switch (event.type) {
      case FlatpakEventType.installProgress:
      case FlatpakEventType.updateProgress:
        emit(InstallationInProgress(
          appId: shortId,
          status: InstallationStatus.downloading,
          progress: event.progress ?? 0.0,
          message: event.message,
        ));
        break;

      case FlatpakEventType.installComplete:
      case FlatpakEventType.uninstallComplete:
      case FlatpakEventType.updateComplete:
        _ongoingOperations.remove(shortId);
        emit(InstallationSuccess(appId: shortId, operation: operation));
        // Reset to idle after short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (state is InstallationSuccess) {
            emit(InstallationIdle());
          }
        });
        break;

      case FlatpakEventType.installFailed:
      case FlatpakEventType.uninstallFailed:
      case FlatpakEventType.updateFailed:
        _ongoingOperations.remove(shortId);
        emit(InstallationFailure(
          appId: shortId,
          error: event.error ?? 'Operation failed',
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
}