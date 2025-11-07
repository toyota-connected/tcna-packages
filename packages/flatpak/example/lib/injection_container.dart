import 'package:flatpak_flutter_example/business_logic/system_info/system_info_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:flatpak_flutter/src/messages.g.dart';

import '../../data/repositories/flatpak_repository_impl.dart';

import 'business_logic/app_launch/app_launch_cubit.dart';
import 'business_logic/discovery/dicovery_cubit.dart';
import 'business_logic/event_listener/event_listener_bloc.dart';
import 'business_logic/installation/installation_cubit.dart';
import 'business_logic/installed_apps/installed_apps_cubit.dart';
import 'data/data_sources/flatpak_event_data.dart';
import 'data/data_sources/flatpak_local_data.dart';
import 'data/repositories/flatpak_repository.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerLazySingleton<FlatpakApi>(() => FlatpakApi());

  sl.registerLazySingleton<FlatpakLocalDataSource>(
        () => FlatpakLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<FlatpakEventDataSource>(
        () => FlatpakEventDataSourceImpl(),
  );

  sl.registerLazySingleton<FlatpakRepository>(
        () => FlatpakRepositoryImpl(
      localDataSource: sl(),
      eventDataSource: sl(),
    ),
  );

  sl.registerFactory(
        () => EventListenerBloc(repository: sl()),
  );

  sl.registerFactory(
        () => InstallationCubit(repository: sl()),
  );

  sl.registerFactory(
        () => InstalledAppsCubit(repository: sl()),
  );

  sl.registerFactory(
        () => DiscoveryCubit(flatpakRepository: sl()),
  );

  sl.registerFactory(
        () => AppLaunchCubit(repository: sl()),
  );
  sl.registerFactory(
        () => SystemInfoCubit(flatpakRepository: sl()),
  );
}