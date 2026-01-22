import 'package:equatable/equatable.dart';
import '../../../core/permissions/permission_types.dart';
import '../../../core/permissions/permission_status.dart';
import '../../data/models/flatpak_permission_model.dart';

abstract class PermissionListenerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PermissionListenerIdle extends PermissionListenerState {}

class PermissionListenerListening extends PermissionListenerState {}

class PermissionListenerStopped extends PermissionListenerState {}

class PermissionRequestReceived extends PermissionListenerState {
  final PermissionEvent event;

  PermissionRequestReceived(this.event);

  @override
  List<Object?> get props => [event];
}

class PermissionResponseSent extends PermissionListenerState {
  final String requestId;
  final FlatpakPermission permission;
  final bool granted;

  PermissionResponseSent({
    required this.requestId,
    required this.permission,
    required this.granted,
  });

  @override
  List<Object?> get props => [requestId, permission, granted];
}

class PermissionCheckComplete extends PermissionListenerState {
  final String appId;
  final Map<FlatpakPermission, PermissionStatus> permissions;

  PermissionCheckComplete({
    required this.appId,
    required this.permissions,
  });

  @override
  List<Object?> get props => [appId, permissions];
}

class PermissionOperationSuccess extends PermissionListenerState {
  final String message;

  PermissionOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PermissionError extends PermissionListenerState {
  final String message;

  PermissionError(this.message);

  @override
  List<Object?> get props => [message];
}