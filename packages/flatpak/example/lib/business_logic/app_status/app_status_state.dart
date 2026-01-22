enum AppStatus {
  notInstalled,
  installed,
  needsUpdate,
  installing,
  updating,
  launching,
}

class AppStatusInfo {
  final String appId;
  final AppStatus status;
  final double? progress;
  final String? operation;

  AppStatusInfo({
    required this.appId,
    required this.status,
    this.progress,
    this.operation,
  });

  AppStatusInfo copyWith({
    AppStatus? status,
    double? progress,
    String? operation,
  }) {
    return AppStatusInfo(
      appId: appId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      operation: operation ?? this.operation,
    );
  }
}

abstract class AppStatusState {}

class AppStatusInitial extends AppStatusState {}

class AppStatusLoading extends AppStatusState {}

class AppStatusLoaded extends AppStatusState {
  final Set<String> installedIds;
  final Set<String> updatableIds;
  final Map<String, AppStatusInfo> statusMap;

  AppStatusLoaded({
    required this.installedIds,
    required this.updatableIds,
    required this.statusMap,
  });

  AppStatusLoaded copyWith({
    Set<String>? installedIds,
    Set<String>? updatableIds,
    Map<String, AppStatusInfo>? statusMap,
  }) {
    return AppStatusLoaded(
      installedIds: installedIds ?? this.installedIds,
      updatableIds: updatableIds ?? this.updatableIds,
      statusMap: statusMap ?? this.statusMap,
    );
  }
}

class AppStatusError extends AppStatusState {
  final String message;
  AppStatusError(this.message);
}
