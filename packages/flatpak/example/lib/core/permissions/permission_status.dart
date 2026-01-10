enum PermissionStatus {
  /// Permission is granted
  granted,

  /// Permission is denied
  denied,

  /// Permission needs to be asked (first time or set to "ask")
  shouldAsk,

  /// Permission is not applicable for this app
  notApplicable,

  /// Permission status is unknown or being checked
  unknown,
}

extension PermissionStatusExtension on PermissionStatus {
  bool get isGranted => this == PermissionStatus.granted;
  bool get isDenied => this == PermissionStatus.denied;
  bool get shouldAsk => this == PermissionStatus.shouldAsk;
  bool get isNotApplicable => this == PermissionStatus.notApplicable;

  String get displayText {
    switch (this) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.shouldAsk:
        return 'Not Set';
      case PermissionStatus.notApplicable:
        return 'N/A';
      case PermissionStatus.unknown:
        return 'Unknown';
    }
  }
}