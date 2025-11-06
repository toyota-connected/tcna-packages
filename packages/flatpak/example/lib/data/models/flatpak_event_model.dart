import 'package:equatable/equatable.dart';

enum FlatpakEventType {
  installProgress,
  installComplete,
  installFailed,
  uninstallComplete,
  uninstallFailed,
  updateProgress,
  updateComplete,
  updateFailed,
  error,
  unknown,
}

class FlatpakEvent extends Equatable {
  final FlatpakEventType type;
  final String? appId;
  final double? progress;
  final String? message;
  final String? error;
  final DateTime timestamp;

  const FlatpakEvent({
    required this.type,
    this.appId,
    this.progress,
    this.message,
    this.error,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [type, appId, progress, timestamp];
}

class FlatpakEventModel extends FlatpakEvent {
  const FlatpakEventModel({
    required super.type,
    super.appId,
    super.progress,
    super.message,
    super.error,
    required super.timestamp,
  });

  factory FlatpakEventModel.fromJson(Map<String, dynamic> json) {
    final eventType = _parseEventType(json['type'] as String?);

    String? appId;
    if (json.containsKey('app_id')) {
      appId = json['app_id'] as String?;
    } else if (json.containsKey('appId')) {
      appId = json['appId'] as String?;
    } else if (json.containsKey('operation_ref')) {
      final ref = json['operation_ref'] as String?;
      if (ref != null && ref.startsWith('app/')) {
        final parts = ref.split('/');
        if (parts.length >= 2) {
          appId = parts[1]; // Get com.google.Chrome
        }
      }
    } else if (json.containsKey('ref')) {
      final ref = json['ref'] as String?;
      if (ref != null && ref.startsWith('app/')) {
        final parts = ref.split('/');
        if (parts.length >= 2) {
          appId = parts[1];
        }
      }
    }

    double? progress;
    if (json.containsKey('progress')) {
      final progressValue = json['progress'];
      if (progressValue is int) {
        progress = progressValue.toDouble();
      } else if (progressValue is double) {
        progress = progressValue;
      }
    }

    String? message;
    if (json.containsKey('message')) {
      message = json['message'] as String?;
    } else if (json.containsKey('status')) {
      message = json['status'] as String?;
    } else if (json.containsKey('error_message')) {
      message = json['error_message'] as String?;
    }

    String? error;
    if (json.containsKey('error')) {
      error = json['error'] as String?;
    } else if (json.containsKey('error_message')) {
      error = json['error_message'] as String?;
    }

    return FlatpakEventModel(
      type: eventType,
      appId: appId,
      progress: progress,
      message: message,
      error: error,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  static FlatpakEventType _parseEventType(String? type) {
    switch (type) {
    // Progress events
      case 'progress':
        return FlatpakEventType.installProgress;

    // Installation events
      case 'installation_started':
      case 'install_progress':
        return FlatpakEventType.installProgress;
      case 'install_complete':
      case 'operation_complete':
        return FlatpakEventType.installComplete;
      case 'install_failed':
      case 'operation_error':
        return FlatpakEventType.installFailed;

    // Uninstall events
      case 'uninstall_complete':
        return FlatpakEventType.uninstallComplete;
      case 'uninstall_failed':
        return FlatpakEventType.uninstallFailed;

    // Update events
      case 'update_started':
      case 'update_progress':
        return FlatpakEventType.updateProgress;
      case 'update_complete':
        return FlatpakEventType.updateComplete;
      case 'update_failed':
        return FlatpakEventType.updateFailed;

      case 'error':
        return FlatpakEventType.error;

      case 'connection_established':
      case 'operation_started':
      case 'transaction_ready':
        return FlatpakEventType.unknown;

      default:
        return FlatpakEventType.unknown;
    }
  }
}