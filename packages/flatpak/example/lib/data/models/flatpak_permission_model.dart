import 'package:equatable/equatable.dart';
import '../../core/permissions/permission_types.dart';

enum PermissionEventType {
  permissionRequest,
  permissionGranted,
  permissionDenied,
  permissionChanged,
  allPermissionsProcessed,
  permissionError,
}

class PermissionEvent extends Equatable {
  final PermissionEventType type;
  final String requestId;
  final String appId;
  final FlatpakPermission? permission;
  final int? progress;
  final int? total;
  final Map<FlatpakPermission, bool>? results;
  final DateTime timestamp;

  const PermissionEvent({
    required this.type,
    required this.requestId,
    required this.appId,
    this.permission,
    this.progress,
    this.total,
    this.results,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    type,
    requestId,
    appId,
    permission,
    progress,
    total,
    results,
    timestamp,
  ];
}

class PermissionEventModel extends PermissionEvent {
  const PermissionEventModel({
    required super.type,
    required super.requestId,
    required super.appId,
    super.permission,
    super.progress,
    super.total,
    super.results,
    required super.timestamp,
  });

  factory PermissionEventModel.fromJson(Map<String, dynamic> json) {
    final eventType = _parseEventType(json['type'] as String?);

    final requestId = json['request_id'] as String? ?? '';
    final appId = json['app_id'] as String? ?? '';

    FlatpakPermission? permission;
    if (json.containsKey('permission')) {
      try {
        permission = FlatpakPermission.values.firstWhere(
              (p) => p.name == json['permission'],
        );
      } catch (e) {
        // Unknown permission
      }
    }

    final progress = json['progress'] as int?;
    final total = json['total'] as int?;

    Map<FlatpakPermission, bool>? results;
    if (json.containsKey('results') && json['results'] is Map) {
      results = {};
      final resultsMap = json['results'] as Map<String, dynamic>;
      resultsMap.forEach((key, value) {
        try {
          final perm = FlatpakPermission.values.firstWhere(
                (p) => p.name == key,
          );
          results![perm] = value as bool;
        } catch (e) {
          // Skip unknown permissions
        }
      });
    }

    return PermissionEventModel(
      type: eventType,
      requestId: requestId,
      appId: appId,
      permission: permission,
      progress: progress,
      total: total,
      results: results,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMicrosecondsSinceEpoch(
          (json['timestamp'] as num).toInt())
          : DateTime.now(),
    );
  }

  static PermissionEventType _parseEventType(String? type) {
    switch (type) {
      case 'permission_dialog':
        return PermissionEventType.permissionRequest;
      case 'permission_granted':
        return PermissionEventType.permissionGranted;
      case 'permission_denied':
        return PermissionEventType.permissionDenied;
      case 'permission_changed':
        return PermissionEventType.permissionChanged;
      case 'all_permissions_processed':
        return PermissionEventType.allPermissionsProcessed;
      case 'permission_error':
        return PermissionEventType.permissionError;
      default:
        return PermissionEventType.permissionRequest;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _typeToString(type),
      'request_id': requestId,
      'app_id': appId,
      if (permission != null) 'permission': permission!.name,
      if (progress != null) 'progress': progress,
      if (total != null) 'total': total,
      if (results != null)
        'results': results!.map((key, value) => MapEntry(key.name, value)),
      'timestamp': timestamp.microsecondsSinceEpoch,
    };
  }

  static String _typeToString(PermissionEventType type) {
    switch (type) {
      case PermissionEventType.permissionRequest:
        return 'permission_dialog';
      case PermissionEventType.permissionGranted:
        return 'permission_granted';
      case PermissionEventType.permissionDenied:
        return 'permission_denied';
      case PermissionEventType.permissionChanged:
        return 'permission_changed';
      case PermissionEventType.allPermissionsProcessed:
        return 'all_permissions_processed';
      case PermissionEventType.permissionError:
        return 'permission_error';
    }
  }
}