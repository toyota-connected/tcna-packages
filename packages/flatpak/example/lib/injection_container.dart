import 'package:flatpak_flutter_example/business_logic/app_status/app_status_cubit.dart';
import 'package:flatpak_flutter_example/business_logic/system_info/system_info_cubit.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:flatpak_flutter/src/messages.g.dart';

import '../../data/repositories/flatpak_repository_impl.dart';

import 'business_logic/app_launch/app_launch_cubit.dart';
import 'business_logic/discovery/discovery_cubit.dart';
import 'business_logic/event_listener/event_listener_bloc.dart';
import 'business_logic/permission_listener/permission_listener_bloc.dart';
import 'business_logic/installation/installation_cubit.dart';
import 'data/data_sources/flatpak_event_data.dart';
import 'data/data_sources/flatpak_local_data.dart';
import 'data/data_sources/flatpak_permission_data.dart';
import 'data/repositories/flatpak_repository.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  const methodChannel = MethodChannel('flatpak_flutter');
  sl.registerLazySingleton<MethodChannel>(() => methodChannel);

  sl.registerLazySingleton<FlatpakApi>(() => FlatpakApi());

  const eventChannel = EventChannel('flutter.io/flatpakPlugin/flatpakEvents');
  const permissionEventChannel = EventChannel('flutter.io/flatpakPlugin/accessEvents');

  // Data Sources
  sl.registerLazySingleton<FlatpakLocalDataSource>(
        () => FlatpakLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<FlatpakEventDataSource>(
        () => FlatpakEventDataSourceImpl(),
  );

  sl.registerLazySingleton<FlatpakPermissionDataSource>(
        () => FlatpakPermissionDataSource(
      methodChannel: methodChannel,
      permissionEventChannel: permissionEventChannel,
    ),
  );

  // Repository
  sl.registerLazySingleton<FlatpakRepository>(
        () => FlatpakRepositoryImpl(
      localDataSource: sl(),
      eventDataSource: sl(),
      permissionDataSource: sl(),
    ),
  );

  // Permission listener
  sl.registerLazySingleton<PermissionListenerBloc>(
        () => PermissionListenerBloc(repository: sl()),
  );

  sl.registerLazySingleton<AppStatusCubit>(
        () => AppStatusCubit(repository: sl()),
  );

  // Installation cubit
  sl.registerLazySingleton<InstallationCubit>(
        () => InstallationCubit(
      repository: sl(),
      appStatusCubit: sl(),
    ),
  );

  // Discovery cubit
  sl.registerLazySingleton<DiscoveryCubit>(
        () => DiscoveryCubit(flatpakRepository: sl()),
  );

  // App launch cubit
  sl.registerLazySingleton<AppLaunchCubit>(
        () => AppLaunchCubit(repository: sl()),
  );

  // System info cubit
  sl.registerLazySingleton<SystemInfoCubit>(
        () => SystemInfoCubit(flatpakRepository: sl()),
  );
}

/// Clean up all singleton instances
Future<void> resetDependencies() async {
  await sl.reset();
}