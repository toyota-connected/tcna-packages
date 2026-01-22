enum FlatpakEventType {
  unknown,
  installProgress,
  installComplete,
  installFailed,
  uninstallProgress,
  uninstallComplete,
  uninstallFailed,
  updateProgress,
  updateComplete,
  updateFailed,
  transactionReady, // Lists all operations that will be performed
  operationStarted, // Individual operation (app/runtime) started
  operationComplete, // Individual operation completed
  operationSummary, // FINAL summary - all operations done
  aggregatedProgress, // Overall progress across all operations
}

class FlatpakEventModel {
  final FlatpakEventType type;
  final String? appId;
  final String? ref;
  final double? progress;
  final String? message;
  final String? error;
  final bool? isEstimating;
  final int? bytes;
  final int? startTime;
  final double? speedBps;
  final int? totalOperations;
  final int? completedOperations;
  final String? currentRef;
  final String? operationType;
  final bool? isMainApp;
  final bool? success;
  final List<OperationInfo>? operations;

  FlatpakEventModel({
    required this.type,
    this.appId,
    this.ref,
    this.progress,
    this.message,
    this.error,
    this.isEstimating,
    this.bytes,
    this.startTime,
    this.speedBps,
    this.totalOperations,
    this.completedOperations,
    this.currentRef,
    this.operationType,
    this.isMainApp,
    this.success,
    this.operations,
  });

  factory FlatpakEventModel.fromMap(Map<dynamic, dynamic> map) {
    bool? toBool(dynamic v) => v is bool ? v : (v is int ? v != 0 : null);

    String? extractAppId(String? ref) {
      if (ref == null) return null;
      final parts = ref.split('/');
      return (parts.length > 1) ? parts[1] : null;
    }

    final typeStr = map['type'] as String?;
    FlatpakEventType eventType = FlatpakEventType.unknown;

    // Parse event type
    if (typeStr != null) {
      switch (typeStr) {
        case 'progress':
          eventType = FlatpakEventType.installProgress;
          break;

        case 'aggregated_progress':
          eventType = FlatpakEventType.aggregatedProgress;
          break;

        case 'operation_complete':
          eventType = FlatpakEventType.operationComplete;
          break;

        case 'operation_summary':
          final opType = map['operation_type'] as String?;
          final success = map['success'] as bool? ?? false;

          if (opType == 'install') {
            eventType = success
                ? FlatpakEventType.installComplete
                : FlatpakEventType.installFailed;
          } else if (opType == 'update') {
            eventType = success
                ? FlatpakEventType.updateComplete
                : FlatpakEventType.updateFailed;
          } else if (opType == 'uninstall') {
            eventType = success
                ? FlatpakEventType.uninstallComplete
                : FlatpakEventType.uninstallFailed;
          }
          break;

        case 'operation_started':
          eventType = FlatpakEventType.operationStarted;
          break;

        case 'operation_error':
          final opType = map['operation_type'] as String?;
          if (opType == 'install') {
            eventType = FlatpakEventType.installFailed;
          } else if (opType == 'update') {
            eventType = FlatpakEventType.updateFailed;
          } else {
            eventType = FlatpakEventType.uninstallFailed;
          }
          break;

        case 'transaction_ready':
          eventType = FlatpakEventType.transactionReady;
          break;

        default:
          eventType = FlatpakEventType.unknown;
      }
    }

    final rawAppId = map['app_id'] as String?;
    final rawRef = map['operation_ref'] as String? ?? map['ref'] as String?;
    final appId = rawAppId ?? extractAppId(rawRef);

    double? progress = (map['progress'] as num?)?.toDouble();
    if (progress != null && progress > 1.0) progress /= 100.0;

    List<OperationInfo>? ops;
    if (map['operations'] != null) {
      final opsList = map['operations'] as List<dynamic>?;
      ops = opsList
          ?.map((o) => OperationInfo.fromMap(o as Map<dynamic, dynamic>))
          .toList();
    }

    return FlatpakEventModel(
      type: eventType,
      appId: appId,
      ref: rawRef,
      progress: progress,
      message: map['status'] as String? ?? map['error_message'] as String?,
      error: map['error_message'] as String?,
      isEstimating: toBool(map['is_estimating']),
      bytes: map['bytes'] as int?,
      startTime: map['start_time'] as int?,
      speedBps: (map['speed_bps'] as num?)?.toDouble(),
      totalOperations: map['total_operations'] as int?,
      completedOperations: map['completed_operations'] as int?,
      currentRef: map['current_ref'] as String?,
      operationType: map['operation_type'] as String?,
      isMainApp: toBool(map['is_main_app']),
      success: toBool(map['success']),
      operations: ops,
    );
  }

  @override
  String toString() {
    return 'FlatpakEvent{type: $type, appId: $appId, ref: $ref, '
        'progress: $progress, totalOps: $totalOperations, '
        'completedOps: $completedOperations, isMainApp: $isMainApp}';
  }
}

class OperationInfo {
  final String ref;
  final String type;
  final String kind;
  final bool isMainApp;

  OperationInfo({
    required this.ref,
    required this.type,
    required this.kind,
    required this.isMainApp,
  });

  factory OperationInfo.fromMap(Map<dynamic, dynamic> map) {
    return OperationInfo(
      ref: map['ref'] as String? ?? '',
      type: map['type'] as String? ?? 'unknown',
      kind: map['kind'] as String? ?? 'unknown',
      isMainApp: map['is_main_app'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'OperationInfo{ref: $ref, type: $type, kind: $kind, isMainApp: $isMainApp}';
  }
}
