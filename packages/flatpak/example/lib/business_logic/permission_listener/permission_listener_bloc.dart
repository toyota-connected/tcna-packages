import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/permissions/permission_types.dart';
import '../../../data/repositories/flatpak_repository.dart';
import '../../data/models/flatpak_permission_model.dart';
import 'permission_listener_event.dart';
import 'permission_listener_state.dart';

class PermissionListenerBloc
    extends Bloc<PermissionListenerEvent, PermissionListenerState> {
  final FlatpakRepository repository;
  StreamSubscription<PermissionEventModel>? _permissionSubscription;

  PermissionListenerBloc({required this.repository})
      : super(PermissionListenerIdle()) {
    on<StartPermissionListening>(_onStartListening);
    on<StopPermissionListening>(_onStopListening);
    on<PermissionEventReceived>(_onEventReceived);
    on<RespondToPermissionRequest>(_onRespondToRequest);
    on<CheckAppPermissions>(_onCheckPermissions);
    on<RevokeAppPermission>(_onRevokePermission);
    on<GrantAppPermission>(_onGrantPermission);
  }

  void _onStartListening(
      StartPermissionListening event,
      Emitter<PermissionListenerState> emit,
      ) async {
    debugPrint('[PermissionListenerBloc] StartPermissionListening called');

    if (_permissionSubscription != null) {
      debugPrint('[PermissionListenerBloc] Already listening');
      return;
    }

    emit(PermissionListenerListening());

    repository.startPermissionListening();
    _permissionSubscription = repository.permissionStream.listen(
          (permissionEvent) {
        debugPrint(
          '[PermissionListenerBloc] Received: ${permissionEvent.type}',
        );
        add(PermissionEventReceived(permissionEvent));
      },
      onError: (error) {
        debugPrint('[PermissionListenerBloc] Stream error: $error');
        emit(PermissionError(error.toString()));
      },
    );
  }

  void _onStopListening(
      StopPermissionListening event,
      Emitter<PermissionListenerState> emit,
      ) {
    debugPrint('[PermissionListenerBloc] StopPermissionListening called');
    _permissionSubscription?.cancel();
    _permissionSubscription = null;
    repository.stopPermissionListening();
    emit(PermissionListenerStopped());
  }

  void _onEventReceived(
      PermissionEventReceived event,
      Emitter<PermissionListenerState> emit,
      ) {
    debugPrint(
      '[PermissionListenerBloc] Event received: ${event.event.type}',
    );
    emit(PermissionRequestReceived(event.event));
  }

  void _onRespondToRequest(
      RespondToPermissionRequest event,
      Emitter<PermissionListenerState> emit,
      ) async {
    debugPrint(
      '[PermissionListenerBloc] Responding: ${event.permission.name} -> ${event.granted}',
    );
    final result = await repository.respondToPermissionRequest(
      requestId: event.requestId,
      permission: event.permission,
      granted: event.granted,
    );

    result.fold(
          (failure) {
        debugPrint('[PermissionListenerBloc] Error: ${failure.message}');
        emit(PermissionError(failure.message));
      },
          (_) {
        emit(PermissionResponseSent(
          requestId: event.requestId,
          permission: event.permission,
          granted: event.granted,
        ));
      },
    );
  }

  void _onCheckPermissions(
      CheckAppPermissions event,
      Emitter<PermissionListenerState> emit,
      ) async {
    debugPrint(
      '[PermissionListenerBloc] Checking permissions for ${event.appId}',
    );
    final result = await repository.checkPermissions(
      appId: event.appId,
      permissions: event.permissions,
    );

    result.fold(
          (failure) {
        debugPrint('[PermissionListenerBloc] Error: ${failure.message}');
        emit(PermissionError(failure.message));
      },
          (permissions) {
        emit(PermissionCheckComplete(
          appId: event.appId,
          permissions: permissions,
        ));
      },
    );
  }
  void _onRevokePermission(
      RevokeAppPermission event,
      Emitter<PermissionListenerState> emit,
      ) async {
    debugPrint(
      '[PermissionListenerBloc] Revoking ${event.permission.name} for ${event.appId}',
    );
    final result = await repository.revokePermission(
      appId: event.appId,
      permission: event.permission,
    );

    result.fold(
          (failure) {
        emit(PermissionError(failure.message));
      },
          (success) {
        if (success) {
          emit(PermissionOperationSuccess(
            'Permission ${event.permission.displayName} revoked',
          ));
        } else {
          emit(PermissionError('Failed to revoke permission'));
        }
      },
    );
  }
  void _onGrantPermission(
      GrantAppPermission event,
      Emitter<PermissionListenerState> emit,
      ) async {
    debugPrint(
      '[PermissionListenerBloc] Granting ${event.permission.name} for ${event.appId}',
    );
    final result = await repository.grantPermission(
      appId: event.appId,
      permission: event.permission,
    );

    result.fold(
          (failure) {
        emit(PermissionError(failure.message));
      },
          (success) {
        if (success) {
          emit(PermissionOperationSuccess(
            'Permission ${event.permission.displayName} granted',
          ));
        } else {
          emit(PermissionError('Failed to grant permission'));
        }
      },
    );
  }
  @override
  Future<void> close() {
    debugPrint('[PermissionListenerBloc] Closing...');
    _permissionSubscription?.cancel();
    repository.stopPermissionListening();
    return super.close();
  }
}