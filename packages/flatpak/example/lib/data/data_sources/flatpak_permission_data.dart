import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/flatpak_permission_model.dart';
import '../../core/permissions/permission_types.dart';

class FlatpakPermissionDataSource {
  final MethodChannel _methodChannel;
  final EventChannel _permissionEventChannel;

  StreamController<PermissionEventModel>? _permissionStreamController;
  Stream<PermissionEventModel> get permissionStream =>
      _permissionStreamController!.stream;

  FlatpakPermissionDataSource({
    required MethodChannel methodChannel,
    required EventChannel permissionEventChannel,
  })  : _methodChannel = methodChannel,
        _permissionEventChannel = permissionEventChannel;

  void startListening() {
    if (_permissionStreamController != null) {
      debugPrint('[FlatpakPermissionData] Already listening');
      return;
    }

    _permissionStreamController =
    StreamController<PermissionEventModel>.broadcast();

    _permissionEventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
        debugPrint('[FlatpakPermissionData] Received event: $event');

        if (event is Map<Object?, Object?>) {
          final Map<String, dynamic> eventMap = event.cast<String, dynamic>();

          try {
            final permissionEvent = PermissionEventModel.fromJson(eventMap);
            _permissionStreamController!.add(permissionEvent);
          } catch (e) {
            debugPrint('[FlatpakPermissionData] Error parsing event: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('[FlatpakPermissionData] Stream error: $error');
      },
    );
  }

  void stopListening() {
    _permissionStreamController?.close();
    _permissionStreamController = null;
  }

  Future<void> respondToPermissionRequest({
    required String requestId,
    required FlatpakPermission permission,
    required bool granted,
  }) async {
    try {
      await _methodChannel.invokeMethod('permissionResponse', {
        'request_id': requestId,
        'permission': permission.name,
        'granted': granted,
      });
      debugPrint(
        '[FlatpakPermissionData] Response sent: ${permission.name} -> $granted',
      );
    } catch (e) {
      debugPrint('[FlatpakPermissionData] Error sending response: $e');
      rethrow;
    }
  }

  Future<Map<FlatpakPermission, bool>> checkPermissions({
    required String appId,
    required List<FlatpakPermission> permissions,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('checkPermissions', {
        'app_id': appId,
        'permissions': permissions.map((p) => p.name).toList(),
      });

      if (result is Map) {
        final Map<FlatpakPermission, bool> permissionMap = {};
        result.forEach((key, value) {
          try {
            final permission = FlatpakPermission.values.firstWhere(
                  (p) => p.name == key,
            );
            permissionMap[permission] = value as bool;
          } catch (e) {
            debugPrint('[FlatpakPermissionData] Unknown permission: $key');
          }
        });
        return permissionMap;
      }

      return {};
    } catch (e) {
      debugPrint('[FlatpakPermissionData] Error checking permissions: $e');
      return {};
    }
  }

  Future<bool> revokePermission({
    required String appId,
    required FlatpakPermission permission,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('revokePermission', {
        'app_id': appId,
        'permission': permission.name,
      });
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[FlatpakPermissionData] Error revoking permission: $e');
      return false;
    }
  }

  Future<bool> grantPermission({
    required String appId,
    required FlatpakPermission permission,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('grantPermission', {
        'app_id': appId,
        'permission': permission.name,
      });
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[FlatpakPermissionData] Error granting permission: $e');
      return false;
    }
  }
}