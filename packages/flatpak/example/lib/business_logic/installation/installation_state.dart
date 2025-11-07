import 'package:equatable/equatable.dart';
import '../../../data/models/install_progress_model.dart';

abstract class InstallationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InstallationIdle extends InstallationState {}

class InstallationInProgress extends InstallationState {
  final String? appId;
  final InstallationStatus status;
  final double progress;
  final String? message;

  InstallationInProgress({
    required this.appId,
    required this.status,
    this.progress = 0.0,
    this.message,
  });

  @override
  List<Object?> get props => [appId, status, progress, message];
}

class InstallationSuccess extends InstallationState {
  final String? appId;
  final String operation;

  InstallationSuccess({required this.appId, required this.operation});

  @override
  List<Object?> get props => [appId, operation];
}

class InstallationFailure extends InstallationState {
  final String? appId;
  final String error;
  final String operation;

  InstallationFailure({
    required this.appId,
    required this.error,
    required this.operation,
  });

  @override
  List<Object?> get props => [appId, error, operation];
}
