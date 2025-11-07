import 'package:equatable/equatable.dart';
import '../../data/models/application_model.dart';

abstract class InstalledAppsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InstalledAppsInitial extends InstalledAppsState {}

class InstalledAppsLoading extends InstalledAppsState {}

class InstalledAppsLoaded extends InstalledAppsState {
  final List<Application> apps;
  final Set<String> installedIds;

  InstalledAppsLoaded({required this.apps, required this.installedIds});

  @override
  List<Object?> get props => [apps, installedIds];
}

class InstalledAppsError extends InstalledAppsState {
  final String message;
  InstalledAppsError(this.message);
  @override
  List<Object?> get props => [message];
}
