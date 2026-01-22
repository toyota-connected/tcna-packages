import 'package:equatable/equatable.dart';
import '../../../core/permissions/permission_types.dart';
import '../../data/models/flatpak_permission_model.dart';

abstract class PermissionListenerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartPermissionListening extends PermissionListenerEvent {}

class StopPermissionListening extends PermissionListenerEvent {}

class PermissionEventReceived extends PermissionListenerEvent {
  final PermissionEvent event;

  PermissionEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}

class RespondToPermissionRequest extends PermissionListenerEvent {
  final String requestId;
  final FlatpakPermission permission;
  final bool granted;

  RespondToPermissionRequest({
    required this.requestId,
    required this.permission,
    required this.granted,
  });

  @override
  List<Object?> get props => [requestId, permission, granted];
}

class CheckAppPermissions extends PermissionListenerEvent {
  final String appId;
  final List<FlatpakPermission> permissions;

  CheckAppPermissions({
    required this.appId,
    required this.permissions,
  });

  @override
  List<Object?> get props => [appId, permissions];
}

class RevokeAppPermission extends PermissionListenerEvent {
  final String appId;
  final FlatpakPermission permission;

  RevokeAppPermission({
    required this.appId,
    required this.permission,
  });

  @override
  List<Object?> get props => [appId, permission];
}

class GrantAppPermission extends PermissionListenerEvent {
  final String appId;
  final FlatpakPermission permission;

  GrantAppPermission({
    required this.appId,
    required this.permission,
  });

  @override
  List<Object?> get props => [appId, permission];
}