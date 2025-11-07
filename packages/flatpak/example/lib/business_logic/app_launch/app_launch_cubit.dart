import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/flatpak_repository.dart';
import '../../helpers/id_utils.dart';
import 'app_launch_state.dart';

class AppLaunchCubit extends Cubit<AppLaunchState> {
  final FlatpakRepository repository;
  final Set<String> _launchingApps = {};

  AppLaunchCubit({required this.repository}) : super(AppLaunchIdle());

  Future<void> launchApp(String appId) async {
    final shortId = AppIdUtils.extractShortId(appId);

    if (_launchingApps.contains(shortId)) {
      return;
    }

    _launchingApps.add(shortId);
    emit(AppLaunchInProgress(shortId));

    final result = await repository.launchApplication(appId);

    result.fold(
      (failure) {
        _launchingApps.remove(shortId);
        emit(AppLaunchFailure(appId: shortId, error: failure.message));
        // Reset after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (state is AppLaunchFailure) {
            emit(AppLaunchIdle());
          }
        });
      },
      (success) {
        _launchingApps.remove(shortId);
        if (success) {
          emit(AppLaunchSuccess(shortId));
          // Reset after delay
          Future.delayed(const Duration(seconds: 1), () {
            if (state is AppLaunchSuccess) {
              emit(AppLaunchIdle());
            }
          });
        } else {
          emit(AppLaunchFailure(appId: shortId, error: 'Launch failed'));
        }
      },
    );
  }

  bool isLaunching(String appId) {
    final shortId = AppIdUtils.extractShortId(appId);
    return _launchingApps.contains(shortId);
  }
}
