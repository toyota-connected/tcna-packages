import 'package:equatable/equatable.dart';

enum InstallationStatus { idle, downloading, installing, completed, failed }

class InstallProgressModel extends Equatable {
  final String appId;
  final InstallationStatus status;
  final double progress;
  final String? message;
  final String? error;

  const InstallProgressModel({
    required this.appId,
    required this.status,
    this.progress = 0.0,
    this.message,
    this.error,
  });

  InstallProgressModel copyWith({
    String? appId,
    InstallationStatus? status,
    double? progress,
    String? message,
    String? error,
  }) {
    return InstallProgressModel(
      appId: appId ?? this.appId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [appId, status, progress, message, error];
}
