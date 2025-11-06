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
    return FlatpakEventModel(
      type: _parseEventType(json['type'] as String?),
      appId: json['appId'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      message: json['message'] as String?,
      error: json['error'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  static FlatpakEventType _parseEventType(String? type) {
    switch (type) {
      case 'install_progress':
        return FlatpakEventType.installProgress;
      case 'install_complete':
        return FlatpakEventType.installComplete;
      case 'install_failed':
        return FlatpakEventType.installFailed;
      case 'uninstall_complete':
        return FlatpakEventType.uninstallComplete;
      case 'uninstall_failed':
        return FlatpakEventType.uninstallFailed;
      case 'update_progress':
        return FlatpakEventType.updateProgress;
      case 'update_complete':
        return FlatpakEventType.updateComplete;
      case 'update_failed':
        return FlatpakEventType.updateFailed;
      case 'error':
        return FlatpakEventType.error;
      default:
        return FlatpakEventType.unknown;
    }
  }
}