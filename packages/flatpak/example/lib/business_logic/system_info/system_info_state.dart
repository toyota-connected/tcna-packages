import 'package:equatable/equatable.dart';
import '../../data/models/installation_model.dart';

abstract class SystemInfoState extends Equatable {
  const SystemInfoState();

  @override
  List<Object?> get props => [];
}

class SystemInfoInitial extends SystemInfoState {
  const SystemInfoInitial();
}

class SystemInfoLoading extends SystemInfoState {
  const SystemInfoLoading();
}

class SystemInfoLoaded extends SystemInfoState {
  final String version;
  final String defaultArch;
  final List<String> supportedArches;
  final List<Installation> systemInstallations;
  final Installation? userInstallation;

  const SystemInfoLoaded({
    required this.version,
    required this.defaultArch,
    required this.supportedArches,
    required this.systemInstallations,
    this.userInstallation,
  });

  @override
  List<Object?> get props => [
    version,
    defaultArch,
    supportedArches,
    systemInstallations,
    userInstallation,
  ];

  SystemInfoLoaded copyWith({
    String? version,
    String? defaultArch,
    List<String>? supportedArches,
    List<Installation>? systemInstallations,
    Installation? userInstallation,
  }) {
    return SystemInfoLoaded(
      version: version ?? this.version,
      defaultArch: defaultArch ?? this.defaultArch,
      supportedArches: supportedArches ?? this.supportedArches,
      systemInstallations: systemInstallations ?? this.systemInstallations,
      userInstallation: userInstallation ?? this.userInstallation,
    );
  }
}

class SystemInfoError extends SystemInfoState {
  final String message;

  const SystemInfoError(this.message);

  @override
  List<Object?> get props => [message];
}