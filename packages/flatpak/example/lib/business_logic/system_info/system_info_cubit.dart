import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/installation_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import 'system_info_state.dart';

class SystemInfoCubit extends Cubit<SystemInfoState> {
  final FlatpakRepository flatpakRepository;

  SystemInfoCubit({required this.flatpakRepository}) : super(const SystemInfoInitial());

  Future<void> loadSystemInfo() async {
    emit(const SystemInfoLoading());

    try {
      final results = await Future.wait([
        flatpakRepository.getVersion(),
        flatpakRepository.getDefaultArch(),
        flatpakRepository.getSupportedArches(),
        flatpakRepository.getSystemInstallations(),
        flatpakRepository.getUserInstallation(),
      ]);

      final versionResult = results[0];
      final archResult = results[1];
      final archesResult = results[2];
      final installationsResult = results[3];
      final userInstallationResult = results[4];

      String version = '';
      String defaultArch = '';
      List<String> supportedArches = [];
      List<Installation> systemInstallations = [];
      Installation? userInstallation;

      versionResult.fold(
            (failure) => print('[SystemInfoCubit] Failed to get version: ${failure.message}'),
            (v) => version = v as String,
      );

      archResult.fold(
            (failure) => print('[SystemInfoCubit] Failed to get arch: ${failure.message}'),
            (a) => defaultArch = a as String,
      );

      archesResult.fold(
            (failure) => print('[SystemInfoCubit] Failed to get arches: ${failure.message}'),
            (a) => supportedArches = a as List<String>,
      );

      installationsResult.fold(
            (failure) => print('[SystemInfoCubit] Failed to get installations: ${failure.message}'),
            (i) => systemInstallations = i as List<Installation>,
      );

      userInstallationResult.fold(
            (failure) => print('[SystemInfoCubit] Failed to get user installation: ${failure.message}'),
            (i) => userInstallation = i as Installation,
      );

      emit(SystemInfoLoaded(
        version: version,
        defaultArch: defaultArch,
        supportedArches: supportedArches,
        systemInstallations: systemInstallations,
        userInstallation: userInstallation,
      ));

      print('[SystemInfoCubit] System info loaded successfully');
    } catch (e) {
      emit(SystemInfoError('Failed to load system info: $e'));
      print('[SystemInfoCubit] Error: $e');
    }
  }

  Future<void> refresh() async {
    await loadSystemInfo();
  }
}