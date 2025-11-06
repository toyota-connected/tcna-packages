import 'package:equatable/equatable.dart';

abstract class AppLaunchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppLaunchIdle extends AppLaunchState {}

class AppLaunchInProgress extends AppLaunchState {
  final String appId;
  AppLaunchInProgress(this.appId);
  @override
  List<Object?> get props => [appId];
}

class AppLaunchSuccess extends AppLaunchState {
  final String appId;
  AppLaunchSuccess(this.appId);
  @override
  List<Object?> get props => [appId];
}

class AppLaunchFailure extends AppLaunchState {
  final String appId;
  final String error;
  AppLaunchFailure({required this.appId, required this.error});
  @override
  List<Object?> get props => [appId, error];
}